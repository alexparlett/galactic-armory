#include "/include/empire_lib.as"
#include "/include/map_util.as"

import void StandardTakeover(Planet@ plt, Empire@ owner, float makeStructures) from "BasicEffects";
import void doJump(Object@ jumpShip, Object@ jumpTo) from "JumpDrive";

float resAddAmount, resRemAmount;
float RS_orbitRadiusFactor = 400.f, V_orbitRadiusFactor = 200.f;
uint techSingle;
string@[] old; 
string@[] newBlue;
Object@ spawnTarg; 
Empire@ spawnEmp;


void selectOwner(string@ arg1, float arg2) {
	Object@ obj = getObjectByID(int(round(s_to_f(arg1))));
	Empire@ emp = getEmpire(int(round(arg2)));
	
	obj.setOwner(emp);
}

void destroyObject(string@ arg1) {
	Object@ obj = getObjectByID(int(round(s_to_f(arg1))));
	
	obj.destroy();
}

void colonizeObject(string@ arg1, float arg2) {
	Object@ obj = getObjectByID(int(round(s_to_f(arg1))));
	Empire@ emp = getEmpire(int(round(arg2)));
	
	
	StandardTakeover(obj.toPlanet(), emp, 6.f);
}

void setGalaxyVisible(float arg2) {
	Empire@ emp = getEmpire(int(round(arg2)));
	
	uint cnt = getEmpireCount();
	for(uint i = 0; i < cnt; i++) {
		emp.addVisibility(getEmpire(i));
	}
}

void teleportObject(string@ arg1, float arg2) {
	Object@ obj = getObjectByID(int(round(s_to_f(arg1))));
	Object@ dest = getObjectByID(int(round(arg2)));
	
	doJump(obj, dest);
}

void setResAddAmount(string@ arg1) {
	resAddAmount = s_to_f(arg1);
}

void setResRemAmount(string@ arg1) {
	resRemAmount = s_to_f(arg1);
}

void addRes(string@ arg1, float arg2) {
	Empire@ emp = getEmpire(int(round(arg2)));
	
	emp.addStat(arg1, resAddAmount);
}

void remRes(string@ arg1, float arg2) {
	Empire@ emp = getEmpire(int(round(arg2)));
	
	emp.subStat(arg1, resRemAmount);
}

void levelTechTo(string@ arg1, float arg2) {
	Empire@ emp = getEmpire(int(round(arg2)));
	
	ResearchWeb web;
	web.prepare(emp);
	
	if(!web.isTechVisible(arg1)) {
		web.markAsVisible(arg1);
	}
	
	levelTo(web, arg1, techSingle);
}

void levelUpTech(string@ arg1, float arg2) {
	Empire@ emp = getEmpire(int(round(arg2)));
	
	ResearchWeb web;
	web.prepare(emp);
	
	if(!web.isTechVisible(arg1)) {
		web.markAsVisible(arg1);
	}
		
	const WebItem@ item = web.getItem(arg1);
	
	if(item !is null)
		levelTech(web, item);
}

void levelAllTechs(string@ arg1, float arg2) {
	Empire@ emp = getEmpire(int(round(arg2)));
	float techAll = s_to_f(arg1);
	
	ResearchWeb web;
	web.prepare(emp);
	
	markAllVisible(web);
	
	levelAllTo(web, techAll);
}

void setSingleTech(string@ arg1) {
	techSingle = uint(s_to_i(arg1));
}

void importBlueprints(float arg2) {
	Empire@ emp = getEmpire(int(round(arg2)));
	Empire@ cur = getActiveEmpire();
	
	if(cur is emp)
		return;
		
	uint curCnt = cur.getShipLayoutCnt();
	old.resize(curCnt);
	for(uint i = 0; i < curCnt; i++) {
		const HullLayout@ lay = cur.getShipLayout(i);
		
		if(lay.get_obsolete())
			continue;
		
		cur.toggleObsolete(lay.getName());
		
		@old[i] = lay.getName();
	}
	
	uint newCnt = emp.getShipLayoutCnt();
	newBlue.resize(newCnt);
	for(uint j = 0; j < newCnt; j++) {
		const HullLayout@ layout = emp.getShipLayout(j);
		
		if(layout.get_obsolete())
			continue;
		
		if(!cur.hasForeignHull(layout))
			cur.acquireForeignHull(layout);
		else
			cur.toggleObsolete(layout.getName());
			
		@newBlue[j] = layout.getName();
	}
}

void restoreBluerints() {
	Empire@ emp = getActiveEmpire();
	
	for(uint i = 0; i < newBlue.length(); i++) {
		if(@newBlue[i] is null)
			continue;
			
		emp.toggleObsolete(newBlue[i]);
	}
	newBlue.resize(0);	
	
	for(uint j = 0; j < old.length(); j++) {
		if(@old[j] is null)
			continue;
	
		emp.toggleObsolete(old[j]);
	}
	old.resize(0);	
}

void setSpawnTarget(string@ arg1, float arg2) {
	@spawnTarg = getObjectByID(int(round(arg2)));
	@spawnEmp = getEmpire(s_to_i(arg1));
}

void spawnShips(string@ arg1, float arg2) {
	const HullLayout@ lay = spawnEmp.getShipLayout(arg1);
	
	if(lay !is null) {
		System@ sys = spawnTarg.getCurrentSystem();
		vector loc = spawnTarg.getPosition();
		
		for(float i = 0; i < arg2; i++) {
			HulledObj@ hull = spawnShip(spawnEmp, lay, sys, loc);
			Object@ newObj = hull.toObject();
			
			doJump(newObj, spawnTarg);
		}
	}	
}

void addPlanetCond(string@ arg1, float arg2) {
	Object@ obj = getObjectByID(int(round(arg2)));
	
	obj.toPlanet().addCondition(arg1);
}

void remPlanetCond(string@ arg1, float arg2) {
	Object@ obj = getObjectByID(int(round(arg2)));
	
	if(obj.toPlanet().hasCondition(arg1))
		obj.toPlanet().removeCondition(arg1);		
}

void eradicateLife(float arg2) {
	Object@ obj = getObjectByID(int(round(arg2)));
	
	while(obj.toPlanet().getStructureCount() > 0)
		obj.toPlanet().removeAllStructures();
}

void spawnRingWorld(string@ arg1, float arg2) {
	Object@ obj = getObjectByID(int(round(arg2)));
	Empire@ emp = getEmpire(s_to_i(arg1));
	
	System@ sys;
	if(obj.toSystem() is null)
		@sys = obj.getParent().toSystem();
	else
		@sys = obj.toSystem();
		
	if(@sys != null && @sys.toObject() != @getGalaxy().toObject()) {
		// Build a new ringworld
		Orbit_Desc orbDesc;
		Planet_Desc plDesc;
		plDesc.setPlanetType( getPlanetTypeID("ringworld") );
		plDesc.RandomConditions = false;
		plDesc.PlanetRadius = sys.toObject().radius * 0.25f;

		orbDesc.IsStatic = true;
		orbDesc.Offset = vector(0,0,0);
		plDesc.setOrbit(orbDesc);
		
		Planet@ pl = sys.makePlanet(plDesc);
		
		pl.addCondition("ringworld_special");
		
		pl.setStructureSpace(100.f);
		
		Object@ planet = pl.toObject();
		
		State@ ore = planet.getState("Ore");
		ore.max = 50000.f;
		ore.val = ore.max;
		
		planet.getState("Damage").max = 100000000000.f;
		
		StandardTakeover(planet, emp, 25.f);
	}	
}

void spawnPlanet(string@ arg1,float arg2) {
	Object@ obj = getObjectByID(int(round(arg2)));
	int count = max(10,s_to_i(arg1));
	
	System@ sys;
	if(obj.toSystem() is null)
		@sys = obj.getParent().toSystem();
	else
		@sys = obj.toSystem();
		
	if(@sys != null && @sys.toObject() != @getGalaxy().toObject()) {
		float orbitRadiusFact;
		if(getGameSetting("REAL_SYS_BOOL", 1) == 1)
			orbitRadiusFact = RS_orbitRadiusFactor;
		else
			orbitRadiusFact = V_orbitRadiusFactor;
			
		float orbit = randomf(1.3f, 2.1f) * orbitRadiusFact;
		makePlanets(sys, orbit, count);
	}	
}

void spawnAsteroids(string@ arg1, float arg2) {
	Object@ obj = getObjectByID(int(round(arg2)));
	uint count = s_to_i(arg1);
	
	System@ sys;
	if(obj.toSystem() is null)
		@sys = obj.getParent().toSystem();
	else
		@sys = obj.toSystem();
		
	if(@sys != null && @sys.toObject() != @getGalaxy().toObject() && count > 0)
		makeRandomAsteroid(sys, count);
}

void damageObject(string@ arg1, float arg2) {
	Object@ obj = getObjectByID(int(round(arg2)));
	float amount = s_to_f(arg1);
	
	obj.damage(obj, 1 * amount);
}

void onMessage(Empire@ emp, uint msg, string@ arg1, float arg2) {
	switch (msg) {
		case 1: selectOwner(arg1,arg2); break;
		case 2: destroyObject(arg1); break;
		case 3: colonizeObject(arg1,arg2); break;
		case 4: setGalaxyVisible(arg2); break;
		case 5: teleportObject(arg1,arg2); break;
		case 6: addRes(arg1,arg2); break;
		case 7: remRes(arg1,arg2); break;
		case 8: setResAddAmount(arg1); break;
		case 9: setResRemAmount(arg1); break;
		case 10: levelTechTo(arg1,arg2); break;
		case 11: levelUpTech(arg1,arg2); break;
		case 12: levelAllTechs(arg1,arg2); break;
		case 13: setSingleTech(arg1); break;
		case 14: importBlueprints(arg2); break;
		case 15: restoreBluerints(); break;
		case 16: setSpawnTarget(arg1,arg2); break;
		case 17: spawnShips(arg1,arg2); break;
		case 18: addPlanetCond(arg1,arg2); break;
		case 19: remPlanetCond(arg1,arg2); break;
		case 20: eradicateLife(arg2); break;
		case 21: spawnRingWorld(arg1,arg2); break;
		case 22: spawnPlanet(arg1,arg2); break;
		case 23: spawnAsteroids(arg1,arg2); break;
		case 24: damageObject(arg1,arg2); break;
	}
}
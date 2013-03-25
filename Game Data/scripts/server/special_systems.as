#include "/include/map_util.as"

import float range(float low, float high, float pct) from "map_generation";

/* {{{ Delegation */
funcdef System@ SpecialSystem (Galaxy@ Glx, vector position);
SpecialSystem@[] specialSystems;

void initSpecialSystems() {
	specialSystems.resize(6);
	@specialSystems[0] = ImperialSeat;
	@specialSystems[1] = RemnantGates;
	@specialSystems[2] = ResearchOutpost;
	@specialSystems[3] = SpatialGen;
	@specialSystems[4] = IonCanon;
	@specialSystems[5] = ZeroPoint;

	print("Special Systems Initialized");
	
}

System@ makeSpecialSystem(Galaxy@ Glx, vector position) {
	if (specialSystems.length() == 0)
		return null;

	int ind = rand(specialSystems.length() - 1);
	SpecialSystem@ func = specialSystems[ind];
	specialSystems.erase(ind);

	return func(Glx, position);
}
/* }}} */

/* {{{ */
/* {{{ Single Creation Systems */
/* {{{ */

/* {{{ Remnant Imperial Seat */
System@ ImperialSeat(Galaxy@ Glx, vector pos) {
	// Create the main system
	System@ sys = makeSystem(Glx, pos, 16.f * orbitRadiusFactor);

	// Add the tag
	sys.addTag("ImperialSeat");

	// Planets and defenses implemented in remnant_ai.as by
	// checking for "ImperialSeat" tag.
	return sys;
}
/* }}} */
/* {{{ Remnant Gate System */
System@ RemnantGates(Galaxy@ Glx, vector pos) {
	// Create the main system
	System@ sys = makeSystem(Glx, pos, 24.f * orbitRadiusFactor);

	// Add the tag
	sys.addTag("GateSystem");

	// Gates and defenses implemented in remnant_ai.as by
	// checking for "GateSystem" tag.
	return sys;
}
/* }}} */
/* {{{ Remnant Research Outpost */
System@ ResearchOutpost(Galaxy@ Glx, vector pos) {
	// Create the main system
	System@ sys = makeSystem(Glx, pos, 24.f * orbitRadiusFactor);

	// Add the tag
	sys.addTag("ResearchOutpost");
	

	// Planets and defenses implemented in remnant_ai.as by
	// checking for "ImperialSeat" tag.
	return sys;
}
/* }}} */
/* {{{ Remnant Spatial Distortian Generator */
System@ SpatialGen(Galaxy@ Glx, vector pos) {
	//Create the main system
	System@ sys = makeSystem(Glx, pos, 16.f * orbitRadiusFactor);
	
	// Add the tag
	sys.addTag("SpatialGen");
	
	// Canon and Defenses implemented in remnant_ai.as by
	//check for tag.
	
	return sys;
}
/* }}} */
/* {{{ Remnant Ion Canon */
System@ IonCanon(Galaxy@ Glx, vector pos) {
	//Create the main system
	System@ sys = makeSystem(Glx, pos, 16.f * orbitRadiusFactor);
	
	// Add the tag
	sys.addTag("IonCanon");
	
	// Canon and Defenses implemented in remnant_ai.as by
	//check for tag.
	
	return sys;
}
/* }}} */
/* {{{ Remnant Zero Point Genertor*/
System@ ZeroPoint(Galaxy@ Glx, vector pos) {
	//Create the main system
	System@ sys = makeSystem(Glx, pos, 24.f * orbitRadiusFactor);
	
	// Add the tag
	sys.addTag("ZeroPoint");
	
	// Canon and Defenses implemented in remnant_ai.as by
	//check for tag.
	
	return sys;
}
/* }}} */

/* {{{ */
/* {{{ Map Generation Systems */
/* {{{ */

/* {{{ Remnant Jump Gate System */
vector[] gatePositions;
uint[] gates;
System@ makeGateSystem(Galaxy@ Glx, vector pos) {
	const float minDist = 0.5f;	 //was 0.25f
	const float maxRad = (sqrt(getGameSetting("SYSTEM_COUNT",150)) * getGameSetting("MAP_SYSTEM_SPACING", 3000.f) * orbitRadiusFactor) / 70.f;
	const float minRad = 250.f;
	const float radius = range(minRad, maxRad, pow(randomf(1.f),0.85f)); 
	const float glxRadius = Glx.toObject().radius;	

	System@ sys = null;
	
	if(gates.length() > 0) {
		int redos = 50;
		int pass = 4;
		do {
			float fuzz = 1.f / float(5 - pass);
			float minGateDist = 1.f * glxRadius;			
		
			uint count = gates.length();
			for(uint i = 0; i < count; ++i) {
				float otherDist = gatePositions[i].getDistanceFrom(pos);
				minGateDist = min(minGateDist, otherDist);				
			}
			
			if(minGateDist >  minDist * glxRadius * fuzz) {
				// Create the main system
				@sys = makeSystem(Glx, pos, 16.f * orbitRadiusFactor);
				break;
			}
			else {
				// Create a new location
				pos = makeRandomVector(radius);
				continue;
			}
			
			if (pass >= 0 && redos == 1) {
				redos = 25;
				pass -= 1;
			}			
		} while(redos-- > 0);
	} else {
		@sys = makeSystem(Glx, pos, 16.f * orbitRadiusFactor);	
	}
	
	if(sys is null)
		return null;
	
	uint n = gates.length();
	gatePositions.resize(n+1);
	gates.resize(n+1);
	gates[n] = sys.toObject().uid;
	gatePositions[n] = pos;

	// Add the tag
	sys.addTag("JumpSystem");

	// Gates and defenses implemented in remnant_ai.as by
	// checking for "JumpSystem" tag.
	return sys;
}
/* }}} */

/* {{{ Unstable Star */
System@ makeUnstableStar(Galaxy@ Glx, vector pos) {
	// Create the system
	System@ sys = makeSystem(Glx, pos, 15 * orbitRadiusFactor);

	// Create the star
	starDesc.StarColor = Color(0xffff3333);
	starDesc.Brightness = 5;
	Star@ star = makeStar(sys, 1.5f);
	starDesc.StarColor = Color(0);
	
	Effect starEffect("SelfHealing");
	starEffect.set("Rate", 100000000.f);		
	star.toObject().addTimedEffect(starEffect, pow(10, 35), 0.f, star.toObject(), null, null, TEF_None);	

	Object@ obj = star.toObject();

	State@ h3 = obj.getState(strH3);
	h3.max = starDesc.Temperature * randomf(100000,200000);
	h3.val = h3.max * (0.5f + (randomf(0.5f)));		

	State@ damage = star.toObject().getState(strDmg);
	damage.max = rand(5.00f,100.00f) * 1000.f * 1000.f;
	
	// Add the tag
	sys.addTag("UnstableStar");

	// Create the planets
	uint cnt = rand(1,2) + rand(1,2);
	float orbit = orbitRadiusFactor * 5.f;	
	makePlanets(sys, orbit, cnt);
	
	return sys;
}
/* }}} */
/* {{{ Neutron Star */
System@ makeNeutronStar(Galaxy@ Glx, vector pos) {
	// Create the system
	System@ sys = makeSystem(Glx, pos, 15.f * orbitRadiusFactor);

	// Create the star
	starDesc.Temperature = randomf(2000,10000);	
	starDesc.StarColor = Color(0xFFA55FA1);
	starDesc.Brightness = 14;
	Star@ star = makeStar(sys, 0.5f);
	starDesc.StarColor = Color(0);
	
	Effect starEffect("SelfHealing");
	starEffect.set("Rate", 100000000.f);		
	star.toObject().addTimedEffect(starEffect, pow(10, 35), 0.f, star.toObject(), null, null, TEF_None);		

	State@ damage = star.toObject().getState(strDmg);
	damage.max = rand(1,20) * 1000000.f * 1000000.f;

	// Add the tag
	sys.addTag("NeutronStar");

	// Create the planets
	uint cnt = rand(1,2) + rand(1,2);
	float orbit = orbitRadiusFactor * 5.f;	
	makePlanets(sys, orbit, cnt);
	
	SysObjList list;
	list.prepare(sys);
	
	uint pcnt = list.childCount;
	
	for(uint i = 0; i < pcnt; ++i) {
		Object@ child = list.getChild(i);
		if(child.toPlanet() !is null) {
			Planet@ pl = child;
			pl.addCondition("neutrino_bombardment");
		}
	}
	return sys;
}
/* }}} */

/* {{{ */
/* {{{ Unused */
/* {{{ */

/* {{{ Ion Storm */
System@ IonStorm(Galaxy@ Glx, vector pos) {
	// Create the system
	System@ sys = makeSystem(Glx, pos, orbitRadiusFactor);

	// Create the star
	starDesc.StarColor = Color(0xff6666ff);
	Star@ star = makeStar(sys, 1.5f);
	starDesc.StarColor = Color(0);

	// Add the tag
	sys.addTag("IonStorm");

	// Add the effect
	Effect eff("DealDamage");
	eff.set("Period", 60.f);
	eff.set("DamageFactor", 0.2f);
	sys.addEffect(eff);

	// Create the planets
	makePlanets(sys, orbitRadiusFactor, rand(2, 3) + rand(2, 4));

	return sys;
}
/* }}} */
/* {{{ Charged Particle Field */
System@ ParticleField(Galaxy@ Glx, vector pos) {
	// Create the system
	System@ sys = makeSystem(Glx, pos, orbitRadiusFactor);

	// Create the star
	starDesc.StarColor = Color(0xff66ff66);
	Star@ star = makeStar(sys, 1.5f);
	starDesc.StarColor = Color(0);

	// Add the tag
	sys.addTag("ChargedParticles");

	// Add the effect
	Effect eff("ReplenishChargeFuel");
	sys.addEffect(eff);

	// Create the planets
	makePlanets(sys, orbitRadiusFactor, rand(1, 3) + rand(1, 3));

	return sys;
}
/* }}} */
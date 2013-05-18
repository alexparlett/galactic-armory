// map_generation
// ==============
// Maps can refer to the functions in this file in order to let the game / mod decide 
// how to build their systems, leaving maps to do positioning.
// Modded by mickleroi http://forums.blind-mind.com/index.php?topic=2406.0

// {{{ Constants
// Strings
//string@ strOre = "Ore", strDmg = "Damage", strMoonEx = "moon", strRingEx = "natural_ring", strComet = "comet", strAsteroid = "asteroid", strHydrogen = "hydrogen";
//string@ strOrbPitch = "orb_disc_pitch", strOrbEcc = "orb_eccentricity", strOrbDays = "orb_days_per_year", strOrbRad = "orb_radius", strOrbMass = "orb_mass";
//string@ strOrbPosInYear = "orb_year_pos", strOrbYaw = "orb_disc_yaw", strMass = "mass";
//string@ strRadius = "radius";
//string@ strLivable = "Livable";

// Settings
float RS_galacticScale = 1.f;
float RS_minPlanetRadius = 6.f, RS_maxPlanetRadius = 12.f;//50=sf=30, 40=sf=24, 60=sf=36
float RS_minDwarfPlanetRadius = 2.f, RS_maxDwarfPlanetRadius = 6.f;
float RS_orbitRadiusFactor = 800.f;
float RS_tempFalloffRadius  = RS_orbitRadiusFactor * 20.f;
uint RS_maxStructSpaceHome = 34;
uint RS_maxStructSpaceRock = 34;
uint RS_maxStructSpaceRockDwarf = 12;
uint RS_maxNumberMoonsGas = 40;
uint RS_maxNumberMoonsOther = 5;
float RS_starSizeFactor = 45.f;// = RS_maxPlanetRadius / sqrt(sqrt(sqrt(300) / 0.65
const float RS_starMassFactor = 1.f /30000.f;// 19800.f;
bool RS_makeOddities = true;
bool RS_prepped = false;
bool RS_balancedStart = false;
bool RS_specialSystems = true;
bool RS_tempFalloff = true;
int RS_specialNum = 40;
float RS_allyDist = 0.1f;
float RS_playerDist = 0.4f;

void RS_setMakeOddities(bool make) { RS_makeOddities = make; }
bool RS_getMakeOddities() { return RS_makeOddities; }
float RS_getOrbitRadiusFactor() { return RS_orbitRadiusFactor; }

// Mathematical
//const float Pi    = 3.14159265f;
//const float twoPi = 6.28318531f;

// Descriptors
//Oddity_Desc comet_desc, asteroid_desc;
//Planet_Desc plDesc;
//System_Desc sysDesc;
//Star_Desc starDesc;
//Orbit_Desc orbDesc;

// }}}
// {{{ Helper utilities
// Prepares global for use
void RS_initMapGeneration() {
	if (!RS_prepped) {
		comet_desc.id = strComet;
		asteroid_desc.id = strAsteroid;
		RS_balancedStart = getGameSetting("MAP_BALANCED_START",0) != 0.f;

		RS_allyDist = getGameSetting("MAP_ALLY_DIST", 0.15f);
		RS_playerDist = getGameSetting("MAP_PLAYER_DIST", 0.45f);
		RS_tempFalloff = getGameSetting("MAP_TEMP_FALLOFF", 1.f) > 0.5f;
		
		RS_specialSystems = getGameSetting("MAP_SPECIAL_SYSTEMS",1) > 0.5f;
		float specialDens = getGameSetting("MAP_SPECIAL_SYSTEM_DENSITY", 0.025f);
		
		if(RS_specialSystems)
		{
			if (specialDens <= 0)
				RS_specialSystems = false;
			else
				RS_specialNum = int(round(1.f/specialDens));
				
			initSpecialSystems();
		}

		initPlanetTypes();
		
		RS_prepped = true;
	}
}

//Turns pct into low at <=0, high at >=1, and a linear interpolation in between
float RS_range(float low, float high, float pct) {
	return low + (clamp(0.f, 1.f, pct) * (high-low));
}

// Returns the percentage that x is between low and high
float RS_pctBetween(float x, float low, float hi) {
	if(x <= low)
		return 0.f;
	else if(x >= hi)
		return 1.f;
	return (x - low)/(hi - low);
}

// Adds a structure to a planet by name
void RS_addStruct(uint count, string@ name, Planet@ pl) {
	const subSystemDef@ struct = getSubSystemDefByName(name);
	if(struct is null)
		return;
	for(uint i = 0; i < count; ++i)
		pl.addStructure(struct);
}

// Get a random planet from a system
//set_int disregardPlanets;
Planet@ RS_getRandomPlanet(System@ sys) {
	Empire@ space = getEmpireByID(-1);
	SysObjList objects;
	objects.prepare(sys);

	Planet@[] planets;
	int planetCount = 0;

	for (uint i = 0; i < objects.childCount; ++i) {
		Object@ obj = objects.getChild(i);
		Planet@ pl = obj;

		if (@pl != null) {
			if (obj.getOwner() is space && !disregardPlanets.exists(obj.uid)) {
				planets.resize(planetCount+1);
				@planets[planetCount] = pl;
				++planetCount;
			}
		}
		else if (@obj.toStar() == null)
			break;
	}

	objects.prepare(null);

	if (planetCount == 0)
		return null;
	else
		return planets[rand(planetCount - 1)];
}
// }}}
// {{{ Planet Generation
Planet@ RS_makeRandomPlanet(System@ sys, uint plNum, uint plCount) {
	// Make a planet in the system 
	return RS_makeStandardPlanet(sys, plNum, plCount);
}

// {{{ Homeworld Generation
int[] RS_playerTeams;
vector[] RS_playerPositions;
Planet@ RS_setupStandardHomeworld(System@ sys, Empire@ emp) {
	if(!emp.isValid() || emp.ID < 0)
		return null;
	
	Empire@ space = getEmpireByID(-1);
	Planet@ planet = null;
	
	int team = int(emp.getStat("Team"));
	int redos = 50;
	int pass = 4;
	do {
		Planet@ newPlanet = RS_getRandomPlanet(sys);
		bool livable = sys.toObject().getStat(space, strLivable) > 0.5f; //0.1
		
		if (pass > 0 && livable) {
			// Player distance
			float glxRadius = getGalaxy().toObject().radius;
			float minPlayerDist = 1.f * glxRadius * 2.f;
			float maxAllyDist = 0.f;
			float fuzz = 1.f / float(5 - pass);
			vector pos = sys.toObject().getPosition();

			uint playerCnt = RS_playerTeams.length();
			for (uint i = 0; i < playerCnt; ++i) {
				int otherTeam = RS_playerTeams[i];
				float otherDist = RS_playerPositions[i].getDistanceFrom(pos);

				if (otherTeam == team && team != 0)
					maxAllyDist = max(maxAllyDist, otherDist);
				else
					minPlayerDist = min(minPlayerDist, otherDist);
			}

			livable = (minPlayerDist > RS_playerDist * glxRadius * 2.f * fuzz)
					&& (maxAllyDist < RS_allyDist * glxRadius * 2.f * fuzz);
		}

		if(livable && !(newPlanet is null)) {
			@planet = @newPlanet;
			break;
		}
		System@ newSys = getRandomSystem();
		if(newSys is null)
			continue;
		@sys = @newSys;
		@planet = @newPlanet;

		if (pass >= 0 && redos == 1) {
			if (pass == 1)
				warning("Couldn't find a fitting system for "+emp.getName()+" in the first passes.");
			redos = 25;
			pass -= 1;
		}
	} while(redos-- > 0);
	
	// Record this player's position
	uint n = RS_playerTeams.length();
	RS_playerTeams.resize(n+1);
	RS_playerPositions.resize(n+1);
	RS_playerTeams[n] = team;
	RS_playerPositions[n] = sys.toObject().getPosition();
	
	updateLoadScreen(emp.getName()+" born.");
	
	if(sys.hasTag("JumpSystem") && RS_balancedStart)
		sys.removeTag("JumpSystem");
	
	Orbit_Desc orbDesc;
	
	sys.toObject().setStat(space, strLivable, 0.f);
	Planet_Desc plDesc;
	plDesc.PlanetRadius = RS_minPlanetRadius + ((RS_maxPlanetRadius - RS_minPlanetRadius) / randomf(9.f,11.f));
	plDesc.RandomConditions = false;
	string@ name = "";

	orbDesc.Eccentricity = randomf(0.85f, 1.15f);
	if (planet is null) {
		// Just creating a new planet, this may cause colliding planet syndrome
		orbDesc.Radius = randomf(2.f, 6.f) * RS_orbitRadiusFactor;
	}
	else {
		// We are swapping a random planet from the system with our own
		orbDesc.Radius = planet.getOrbitRadius();

		Object@ plObj = planet.toObject();
		disregardPlanets.insert(plObj.uid);
		name += plObj.getName();

		// Destroy the planet without showing an explosion
		planet.eradicate();
	}

	
	//Uncomment to force the homeworld to a specific type
	//plDesc.setPlanetType( getPlanetTypeID( "rock5" ));
	plDesc.setPlanetType(getPlanetTypeID("rock"+rand(1, 16)));
	
	if(RS_makeOddities) {
		int belts = 0;
		while (belts < 6) {
			RS_makeRandomAsteroid(sys, rand(20,50));
			++belts;
		}
	}	
	
	//Setup orbit information based on the star
	SysObjList children; children.prepare(sys);
	if(children.childCount > 0) {
		Object@ child = children.getChild(0);
		Star@ star = @child;
		if(@star != null) {
			if(orbDesc.Radius < child.radius * 1.5f)
				orbDesc.Radius = max(child.radius * randomf(1.5f,2.2f), 2.f * RS_orbitRadiusFactor);
			//Set planet orbit information for this star
			orbDesc.MassRadius = child.radius;
			orbDesc.Mass = child.radius * RS_starMassFactor;
		}
	}
	children.prepare(null);

	plDesc.setOrbit(orbDesc);
	Planet@ pl = sys.makePlanet(plDesc);
	Object@ obj = pl.toObject();
	obj.setOwner(emp);

	if (name != "")
		obj.setName(name);
		
	//Homeworlds can take 1B damage before being completely destroyed
	obj.getState("Damage").max = 1000000000.f * randomf(50.f, 100.f);

	Effect starEffect("SelfHealing");
	starEffect.set("Rate", 5000000.f);	
	pl.toObject().addTimedEffect(starEffect, pow(10, 35), 0.f, pl.toObject(), null, null, TEF_None);
	
	Effect planetEffect("PlanetRegen");
	pl.toObject().addTimedEffect(planetEffect, pow(10, 35), 0.f, pl.toObject(), null, null, TEF_None);

	State@ ore = obj.getState("Ore");
	ore.max = 50000000.f;
	ore.val = 50000000.f;

	// Add moons
	uint moons = 0;
	while(randomf(1.f) < 0.65f && moons < RS_maxNumberMoonsOther) {
		moons++;
		pl.addExtension(strMoonEx);
	}
	
	// Add ring
	if(randomf(1.f) < 0.35f) {
		pl.addExtension(strRingEx);
	}
	
	//Calculate habitable moons
	uint moonhab = 0;
	while(randomf(1.f) < 0.20f && (moonhab < moons)) {
		moonhab++;
	}
	
	//Calculate space on moons
	uint moonspc = 0;
	uint rndm = 0;
	uint iterat = 0;

	if (pl.getPhysicalType().beginsWith("rock")) 
		{
		while(iterat < moonhab) {
			rndm = rand(2, 5);
			moonspc = (moonspc + rndm);
			iterat++;
		}
		pl.setStructureSpace(RS_maxStructSpaceHome + moonspc);
	}
	
	float slots = pl.getMaxStructureCount();
	
	State@ terSlots = obj.getState(strTerraform);
	if(slots >= 30) {
		terSlots.max = rand(2, 6);
		terSlots.val = terSlots.max;
	}
	else if(slots >= 20) {
		terSlots.max = rand(6, 10);
		terSlots.val = terSlots.max;
	}
	else {
		terSlots.max = rand(10, 14);
		terSlots.val = terSlots.max;
	}	
	
	string@ strFarm = "Farm";
	if(emp.hasTraitTag("no_food"))
		if(emp.hasTraitTag("consume_metals"))
			strFarm = "MetalMine";
		else
			strFarm = "City";

	string@ strGoods = "GoodsFactory";
	if(emp.hasTraitTag("forever_indifferent"))
		strGoods = "MetalMine";
		
	string@ strSpacePort = "SpacePort";
	if(emp.hasTraitTag("nobank"))
		strSpacePort = "ShipYard";
		
	//Setup starting structures
	addStruct(1, "GalacticCapital", pl);
	pl.addCondition("homeworld");

	if (!emp.hasTraitTag("empty_homeworld")) {
		addStruct(1, "MetalMine", pl);
		addStruct(2, "City", pl);
		addStruct(3, "MetalMine", pl);
		addStruct(3, "ElectronicFact", pl);
		addStruct(3, "AdvPartFact", pl);
		addStruct(2, "City", pl);
		addStruct(2, "SciLab", pl);
		addStruct(2, "City", pl);
		addStruct(2, strFarm, pl);
		addStruct(3, strSpacePort, pl);
		addStruct(1, "ShipYard", pl);
		addStruct(1, "FuelDepot", pl);		

		if (emp.hasTraitTag("larger_homeworld")) {
			pl.setStructureSpace(RS_maxStructSpaceHome + moonspc + 10);

			addStruct(3, "City", pl);
			addStruct(1, strGoods, pl);
			addStruct(4, "MetalMine", pl);
			addStruct(3, "ElectronicFact", pl);
			addStruct(3, "AdvPartFact", pl);

			@ore = obj.getState("Ore");
			ore.val = ore.val / 2.f;
		}
	}
	
	if (emp.hasTraitTag("mined_homeworld")) {
		@ore = obj.getState("Ore");
		emp.addStat("Metals", ore.val * 0.05f);
		ore.val = 0.f;
	}
	
	//Start the planet with 92% of max population
	pl.modPopulation(pl.getMaxPopulation() * 0.92f);
	
	//Start the planet with 75% stores of economic resources
	State@ s_m = obj.getState("Metals"); s_m.val = s_m.max * 0.75f;
	State@ s_e = obj.getState("Electronics"); s_e.val = s_e.max * 0.75f;
	State@ s_a = obj.getState("AdvParts"); s_a.val = s_a.max * 0.75f;
	
	//pl.addExtension(strRingEx);
	
	if (emp.hasTraitTag("second_planet"))
		RS_createSecondaryPlanet(sys, emp);
	
	return pl;
}

void RS_createSecondaryPlanet(System@ sys, Empire@ emp) {
	// Find the first planet in the system
	SysObjList objs;
	Planet@ planet = null;
	objs.prepare(sys);
	float pRad = 0.0f;
	float newslots = 0.f, oldslots = 0.f;	

	Orbit_Desc orbDesc;
	for (uint i = 0; i < objs.childCount; ++i) {
		Object@ child = objs.getChild(i);
		Star@ star = child;
		Planet@ pl = child;

		if (star !is null) {
			if(orbDesc.Radius < child.radius * 1.5f)
				orbDesc.Radius = max(child.radius * randomf(1.5f,2.2f), 2.f * RS_orbitRadiusFactor);
			//Set planet orbit information for this star
			orbDesc.MassRadius = child.radius;
			orbDesc.Mass = child.radius * RS_starMassFactor;
		}
		else if (pl !is null) {
			if (!child.getOwner().isValid() && !disregardPlanets.exists(child.uid)) {
				newslots = pl.getMaxStructureCount();
				if(newslots > oldslots) {
					oldslots = newslots;
					@planet = pl;
					pRad = child.radius;
				}
			}
		}
	}

	// Create a new planet if we didn't find any
	if (planet is null) {
		Planet_Desc plDesc;
		pRad = 4;
//		pRad = randomf(RS_minPlanetRadius, RS_maxPlanetRadius);
		plDesc.PlanetRadius = pRad;
		plDesc.RandomConditions = false;

		orbDesc.IsStatic = false;
		orbDesc.Radius = randomf(2.f, 5.f) * RS_orbitRadiusFactor;
		plDesc.setOrbit(orbDesc);

		Planet@ planet = sys.makePlanet(plDesc);
	}

	disregardPlanets.insert(planet.toObject().uid);
	
	// Add moons
	uint moons = 0;	
	uint moonhab = 0;
	if (planet.getPhysicalType().beginsWith("gas")) 
	{
		moons = 1;
		moonhab = 1;
		while(randomf(1.f) < 0.80f && moons < RS_maxNumberMoonsGas) {
			moons++;
			planet.addExtension(strMoonEx);
		}
	}	
	else{
		while(randomf(1.f) < 0.65f && moons < RS_maxNumberMoonsOther){
			moons++;
			planet.addExtension(strMoonEx);
		}
	}
	
	// Add ring
	if(randomf(1.f) < 0.35f) {
		planet.addExtension(strRingEx);
	}
	
	//Calculate habitable moons
	while(randomf(1.f) < 0.20f && (moonhab < moons)) {
		moonhab++;
	}
	
	//Calculate space on moons
	uint moonspc = 0;
	uint rndm = 0;
	uint iterat = 0;

	if (planet.getPhysicalType().beginsWith("gas")) 
		{
		//gas giants always have habitable moons
		if(moonhab < 1){
			moonhab = rand(1, min(3, moons));
		}
		while(iterat < moonhab) {
			rndm = rand(5, 15);
			moonspc = (moonspc + rndm);
			iterat++;
		}
	}
	else if (planet.getPhysicalType().beginsWith("lava") ||
			 planet.getPhysicalType().beginsWith("ice")) 
		{
		while(iterat < moonhab) {
			rndm = rand(1, 3);
			moonspc = (moonspc + rndm);
			iterat++;
		}
	}
	else if (planet.getPhysicalType().beginsWith("desert") ||
			 planet.getPhysicalType().beginsWith("rock")) 
		{
		while(iterat < moonhab) {
			rndm = rand(2, 5);
			moonspc = (moonspc + rndm);
			iterat++;
		}
	}

	//Set structure limit
	uint strucsp = 1;
	//uint strucsp = (RS_pctBetween(pRad, RS_minPlanetRadius, RS_maxPlanetRadius) * 0.5f + 0.5f) * RS_maxStructSpace;

	if (planet.getPhysicalType().beginsWith("gas")) 
	{
		//gas giants only have habitable moons
		strucsp = moonspc;
	}
	else if (planet.getPhysicalType().beginsWith("lava")) 
	{
		strucsp = rand(4, 7) + moonspc;
	}
	else if (planet.getPhysicalType().beginsWith("ice")) 
	{
		strucsp = rand(5, 9) + moonspc;
	}
	else if (planet.getPhysicalType().beginsWith("desert")) 
	{
		strucsp = rand(6, 11) + moonspc;
	}
	else if (planet.getPhysicalType().beginsWith("rock")) 
	{
		//random amount of strucspace between 0 and RS_maxStructSpaceRock
		//lower amount more likely
		while(randomf(1.f) < 0.2f && strucsp < RS_maxStructSpaceRock) {
			strucsp++;
		}
		strucsp = (strucsp + moonspc + pRad);
	}
	
	if(strucsp < 1)
		strucsp = 5;
	planet.setStructureSpace(strucsp);

	// Set correct data on planet
	Object@ obj = planet;
	obj.setOwner(emp);
	
	float slots = planet.getMaxStructureCount();
	
	State@ terSlots = obj.getState(strTerraform);
	if(slots >= 30) {
		terSlots.max = rand(2, 6);
		terSlots.val = terSlots.max;
	}
	else if(slots >= 20) {
		terSlots.max = rand(6, 10);
		terSlots.val = terSlots.max;
	}
	else {
		terSlots.max = rand(10, 14);
		terSlots.val = terSlots.max;
	}	
	while (planet.getConditionCount() > 0) {
		const PlanetCondition@ cond = planet.getCondition(0);
		planet.removeCondition(cond.get_id());
	}

	State@ ore = obj.getState("Ore");
	ore.max = 50000000.f;
	ore.val = 50000000.f;
	
	if (planet.getPhysicalType().beginsWith("gas")) 
	{
		State@ h3 = obj.getState(strH3);
		h3.max = 50000000.f;
		h3.val = 50000000.f;			
	}		

	obj.getState("Damage").max = 1000000000.f * randomf(50.f, 100.f);	

	Effect starEffect("SelfHealing");
	starEffect.set("Rate", 5000000.f);	
	planet.toObject().addTimedEffect(starEffect, pow(10, 35), 0.f, planet.toObject(), null, null, TEF_None);	

	Effect planetEffect("PlanetRegen");
	planet.toObject().addTimedEffect(planetEffect, pow(10, 35), 0.f, planet.toObject(), null, null, TEF_None);
	
	// Which farm to use?
	string@ strFarm = "Farm";
	if (emp.hasTraitTag("no_food"))
		if (emp.hasTraitTag("consume_metals"))
			strFarm = "MetalMine";
		else
			strFarm = "City";

	addStruct(1, "Capital", planet);
	addStruct(1, "MetalMine", planet);
	addStruct(2, "City", planet);
	addStruct(2, "MetalMine", planet);
	addStruct(2, "ElectronicFact", planet);
	addStruct(3, "AdvPartFact", planet);
	addStruct(2, "City", planet);
	if(!emp.hasTraitTag("nobank"))
		addStruct(1, "SpacePort", planet);
	else
		addStruct(1, "ShipYard", planet);
	addStruct(1, strFarm, planet);

	planet.modPopulation(planet.getMaxPopulation() * 0.92f);
	State@ s_m = obj.getState("Metals"); s_m.val = s_m.max * 0.75f;
	State@ s_e = obj.getState("Electronics"); s_e.val = s_e.max * 0.75f;
	State@ s_a = obj.getState("AdvParts"); s_a.val = s_a.max * 0.75f;
}
// }}}
// {{{ Standard Planet
Planet@ RS_makeStandardPlanet(System@ sys, uint plNum, uint plCount) {
	// Planet radius
	float pRad = randomf(RS_minPlanetRadius, RS_maxPlanetRadius);
	plDesc.PlanetRadius = pRad;
	plDesc.RandomConditions = false;

	// Calculate planetary temperature
	if (RS_tempFalloff) {
		int type = -1;
		float temp = (sqrt(starDesc.Temperature * starDesc.Radius)) / sqr(orbDesc.Radius / RS_tempFalloffRadius);
		float tp = randomf(1.f);

		if (tp < 0.25f){
			type = getRandomType(GasTypes);
			plDesc.PlanetRadius += pRad*4.f;
			}
		else if (temp > 24000.f){
			type = getRandomType(LavaTypes);
			}
		else if (temp > 14000.f){
			type = getRandomType(WarmTypes);
			}
		else if (temp > 10000.f){
			type = getRandomType(NormalTypes);
			}
		else{
			type = getRandomType(ColdTypes);
			}
		plDesc.setPlanetType(type);
	}
	float pVol = pRad * pRad * pRad * 4.189f;
	// Planet orbit
	plDesc.setOrbit(orbDesc);
	
	// Create planet
	Planet@ pl = sys.makePlanet(plDesc);
	Object@ planet = pl.toObject();
	
	// Add random conditions
	if (randomf(1.f) < 0.6f)
		pl.addPositiveCondition();
	else
		pl.addNegativeCondition();

	if (randomf(1.f) < 0.5f) {
		if (randomf(1.f) < 0.6f)
			pl.addPositiveCondition();
		else
			pl.addNegativeCondition();
	}
	
	if (randomf(1.f) < 0.5f) {
		if (randomf(1.f) < 0.6f)
			pl.addPositiveCondition();
		else
			pl.addNegativeCondition();
	}	

	// Give the planet ore
	State@ ore = planet.getState(strOre);
	ore.max = pVol * 6000.f;
	ore.val = ore.max * (0.5f + randomf(0.5f));
	
	if (pl.getPhysicalType().beginsWith("gas")) 
	{
		State@ h3 = planet.getState(strH3);
		h3.max = starDesc.Temperature * randomf(100000,200000);
		h3.val = h3.max * (0.5f + (randomf(0.5f)));				
	}		
	
	planet.getState(strDmg).max = pVol * 507171.875f;  //radius 40 planets have same hp as radius 19 planets in vanilla

	Effect starEffect("SelfHealing");
	starEffect.set("Rate", 5000000.f);	
	pl.toObject().addTimedEffect(starEffect, pow(10, 35), 0.f, pl.toObject(), null, null, TEF_None);

	Effect planetEffect("PlanetRegen");
	pl.toObject().addTimedEffect(planetEffect, pow(10, 35), 0.f, pl.toObject(), null, null, TEF_None);	

	// Add moons
	uint moons = 0;	
	uint moonhab = 0;
	if (pl.getPhysicalType().beginsWith("gas")) 
	{
		moons = 1;
		moonhab = 1;
		while(randomf(1.f) < 0.80f && moons < RS_maxNumberMoonsGas) {
			moons++;
			pl.addExtension(strMoonEx);
		}
	}	
	else{
		while(randomf(1.f) < 0.65f && moons < RS_maxNumberMoonsOther){
			moons++;
			pl.addExtension(strMoonEx);
		}
	}

	// Add ring
	if(randomf(1.f) < 0.35f) {
		pl.addExtension(strRingEx);
	}

	//Calculate habitable moons
	while(randomf(1.f) < 0.20f && (moonhab < moons)) {
		moonhab++;
	}

	//Calculate space on moons
	uint moonspc = 0;
	uint rndm = 0;
	uint iterat = 0;

	if (pl.getPhysicalType().beginsWith("gas")) 
		{
		//gas giants always have habitable moons
		if(moonhab < 1){
			moonhab = rand(1, min(3, moons));
		}
		while(iterat < moonhab) {
			rndm = rand(5, 15);
			moonspc = (moonspc + rndm);
			iterat++;
		}
	}
	else if (pl.getPhysicalType().beginsWith("lava") ||
			 pl.getPhysicalType().beginsWith("ice")) 
		{
		while(iterat < moonhab) {
			rndm = rand(1, 3);
			moonspc = (moonspc + rndm);
			iterat++;
		}
	}
	else if (pl.getPhysicalType().beginsWith("desert") ||
			 pl.getPhysicalType().beginsWith("rock")) 
		{
		while(iterat < moonhab) {
			rndm = rand(2, 5);
			moonspc = (moonspc + rndm);
			iterat++;
		}
	}

	//Set structure limit
	uint strucsp = 1;
	//uint strucsp = (RS_pctBetween(pRad, RS_minPlanetRadius, RS_maxPlanetRadius) * 0.5f + 0.5f) * RS_maxStructSpace;

	if (pl.getPhysicalType().beginsWith("gas")) 
	{
		//gas giants only have habitable moons
		strucsp = moonspc;
	}
	else if (pl.getPhysicalType().beginsWith("lava")) 
	{
		strucsp = rand(4, 7) + moonspc;
	}
	else if (pl.getPhysicalType().beginsWith("ice")) 
	{
		//strucsp = (strucsp / 2);
		//strucsp = (strucsp + moonspc);
		strucsp = rand(5, 9) + moonspc;
	}
	else if (pl.getPhysicalType().beginsWith("desert")) 
	{
		//strucsp = (strucsp + moonspc);
		strucsp = rand(6, 11) + moonspc;
	}
	else if (pl.getPhysicalType().beginsWith("rock")) 
	{
		//random amount of strucspace between 0 and RS_maxStructSpaceRock
		//lower amount more likely
		while(randomf(1.f) < 0.2f && strucsp < RS_maxStructSpaceRock) {
			strucsp++;
		}
		strucsp = (strucsp + moonspc + pRad);
	}
	
	if(strucsp <= 1)
		strucsp = 5;
	pl.setStructureSpace(strucsp);
	
	float oceanic = strucsp / 2;
	if(pl.hasCondition("oceanic"))
		pl.setStructureSpace(oceanic);	
		
	float slots = pl.getMaxStructureCount();
	
	State@ terSlots = planet.getState(strTerraform);
	if(slots >= 30) {
		terSlots.max = rand(2, 6);
		terSlots.val = terSlots.max;
	}
	else if(slots >= 20) {
		terSlots.max = rand(6, 10);
		terSlots.val = terSlots.max;
	}
	else {
		terSlots.max = rand(10, 14);
		terSlots.val = terSlots.max;
	}

	return pl;
}
// }}}
// {{{ Planet Generation Dwarf Planets
Planet@ RS_makeRandomDwarfPlanet(System@ sys, uint dplNum, uint dplCount) {
	// Make a planet in the system 
	return RS_makeDwarfPlanet(sys, dplNum, dplCount);
}
// {{{ Dwarf Planet
Planet@ RS_makeDwarfPlanet(System@ sys, uint dplNum, uint dplCount) {
	// Planet radius
	float dpRad = randomf(RS_minDwarfPlanetRadius, RS_maxDwarfPlanetRadius), dpVol = dpRad * dpRad * dpRad * 4.189f;
	dplDesc.PlanetRadius = dpRad;
	dplDesc.RandomConditions = false;

	// Calculate planetary temperature
	if (RS_tempFalloff) {
		int type = -1;
		float temp = (sqrt(starDesc.Temperature * starDesc.Radius)) / sqr(orbDesc.Radius / RS_tempFalloffRadius);
		float tp = randomf(1.f);

		if (temp > 30000.f)
			type = getRandomType(DLavaTypes);
		else if (temp > 17000.f)
			type = getRandomType(DWarmTypes);
		else if (temp > 5000.f)
			type = getRandomType(DNormalTypes);
		else
			type = getRandomType(DColdTypes);

		dplDesc.setPlanetType(type);
	}
	
	// Planet orbit
	dplDesc.setOrbit(orbDesc);
	
	// Create planet
	Planet@ dpl = sys.makePlanet(dplDesc);
	Object@ planet = dpl.toObject();
	
	// Add random conditions
	if (randomf(1.f) < 0.6f)
		dpl.addPositiveCondition();
	else
		dpl.addNegativeCondition();

	if (randomf(1.f) < 0.5f) {
		if (randomf(1.f) < 0.6f)
			dpl.addPositiveCondition();
		else
			dpl.addNegativeCondition();
	}
	
	if (randomf(1.f) < 0.5f) {
		if (randomf(1.f) < 0.6f)
			dpl.addPositiveCondition();
		else
			dpl.addNegativeCondition();
	}	

	// Give the planet ore
	State@ ore = planet.getState(strOre);
	ore.max = dpVol * 6000.f;
	ore.val = ore.max * (0.5f + randomf(0.5f));

	//Set structure limit
	uint strucsp = 1;
	//uint strucsp = (RS_pctBetween(pRad, RS_minDwarfPlanetRadius, RS_maxDwarfPlanetRadius) * 0.5f + 0.5f) * RS_maxStructSpace;

	if (dpl.getPhysicalType().beginsWith("dwarflava")) 
	{
		strucsp = rand(2, 5);
	}
	else if (dpl.getPhysicalType().beginsWith("dwarfice")) 
	{
		//strucsp = (strucsp / 2);
		//strucsp = (strucsp);
		strucsp = rand(3, 6);
	}
	else if (dpl.getPhysicalType().beginsWith("dwarfdesert")) 
	{
		//strucsp = (strucsp);
		strucsp = rand(4, 8);
	}
	else if (dpl.getPhysicalType().beginsWith("dwarfrock")) 
	{
		//random amount of strucspace between 0 and RS_maxStructSpaceRockDwarf
		//lower amount more likely
		while(randomf(1.f) < 0.2f && strucsp < RS_maxStructSpaceRockDwarf) {
			strucsp++;
		}
		strucsp = (strucsp + dpRad);
	}
	
	if(strucsp <= 1)
		strucsp = 5;
	dpl.setStructureSpace(strucsp);
	
	float oceanic = strucsp / 2;
	if(dpl.hasCondition("oceanic"))
		dpl.setStructureSpace(oceanic);	
		
	float slots = dpl.getMaxStructureCount();
	
	State@ terSlots = planet.getState(strTerraform);
	if(slots >= 12) {
		terSlots.max = rand(2, 6);
		terSlots.val = terSlots.max;
	}
	else if(slots >= 6) {
		terSlots.max = rand(4, 8);
		terSlots.val = terSlots.max;
	}
	else {
		terSlots.max = rand(6, 12);
		terSlots.val = terSlots.max;
	}

	return dpl;
}
// }}}
// }}}
// {{{ Oddity Generation
// {{{ Comet
void RS_makeRandomComet(System@ sys) {
	comet_desc.clear();
	
	float baseRadius = randomf(1.0f,1.8f) * RS_orbitRadiusFactor;
	
	comet_desc.setFloat(strOrbRad, baseRadius);
	comet_desc.setFloat(strOrbMass, 5.f);
	Object@ comet = sys.makeOddity(comet_desc);
	
	State@ H2 = comet.getState(strHydrogen);
	H2.max = randomf(10000.f,25000.f);
	H2.val = H2.max;
}
// }}}
// {{{ Asteroids
void RS_makeRandomAsteroidNew(System@ sys, uint rocks, float starRad) {
	asteroid_desc.clear();
	
	asteroid_desc.setFloat(strOrbMass, 0.2f); //Slow down the orbit
	asteroid_desc.setFloat(strOrbEcc, randomf(0.9f,1.1f));
	
	float maxRadius = sys.toObject().radius * 0.9f;	
	float baseRadius = starRad * 2.f + (randomf(2.f,6.f) * RS_orbitRadiusFactor), rockMaxDev = RS_orbitRadiusFactor / 4.f;
	float basePitch = randomf(-0.2f,0.2f), rockPitchDev = 10.f / (2.f * twoPi * baseRadius);
	
	for(uint i = 0; i < rocks; ++i) {
		asteroid_desc.setFloat(strOrbDays, randomf(3.f, 6.f));
		asteroid_desc.setFloat(strRadius, randomf(4.f, 8.f));
		asteroid_desc.setFloat(strOrbYaw, twoPi * randomf(-0.4f,0.4f) / float(rocks));
		
		float rockDev = randomf(rockMaxDev), rockDevAng = randomf(twoPi);
		float oreVal = randomf(3000000, 9000000);
		
		asteroid_desc.setFloat(strOrbRad, min(baseRadius + (rockDev * cos(rockDevAng)), maxRadius));
		asteroid_desc.setFloat(strOrbPitch, basePitch + (rockDev * rockPitchDev * sin(rockDevAng)));
		asteroid_desc.setFloat(strMass, oreVal);
		
		Object@ asteroid = sys.makeOddity(asteroid_desc);
		
		State@ ore = asteroid.getState(strOre);
		ore.max = oreVal;
		ore.val = oreVal;
		
		State@ hp = asteroid.getState(strDmg);
		hp.val = 0;
		hp.max = oreVal;
	}
}

void RS_makeRandomAsteroid(System@ sys, uint rocks) {
	asteroid_desc.clear();
	
	asteroid_desc.setFloat(strOrbMass, 0.2f); //Slow down the orbit
	asteroid_desc.setFloat(strOrbEcc, randomf(0.9f,1.1f));
	
	float maxRadius = sys.toObject().radius * 0.8f;	
	float baseRadius = randomf(2.f,6.f) * RS_orbitRadiusFactor, rockMaxDev = RS_orbitRadiusFactor / 4.f;
	float basePitch = randomf(-0.2f,0.2f), rockPitchDev = 10.f / (2.f * twoPi * baseRadius);
	
	for(uint i = 0; i < rocks; ++i) {
		asteroid_desc.setFloat(strOrbDays, randomf(3.f, 6.f));
		asteroid_desc.setFloat(strRadius, randomf(4.f, 8.f));
		asteroid_desc.setFloat(strOrbYaw, twoPi * randomf(-0.4f,0.4f) / float(rocks));
		
		float rockDev = randomf(rockMaxDev), rockDevAng = randomf(twoPi);
		float oreVal = randomf(3000000, 9000000);
		
		asteroid_desc.setFloat(strOrbRad, min(baseRadius + (rockDev * cos(rockDevAng)), maxRadius));
		asteroid_desc.setFloat(strOrbPitch, basePitch + (rockDev * rockPitchDev * sin(rockDevAng)));
		asteroid_desc.setFloat(strMass, oreVal);
		
		Object@ asteroid = sys.makeOddity(asteroid_desc);
		
		State@ ore = asteroid.getState(strOre);
		ore.max = oreVal;
		ore.val = oreVal;
		
		State@ hp = asteroid.getState(strDmg);
		hp.val = 0;
		hp.max = oreVal;
	}
}
// }}}
// }}}
// {{{ System Generation
System@ RS_makeRandomSystem(Galaxy@ Glx, vector position, uint sysNum, uint sysCount) {
	// Create system sysNum/sysCount at position
	float sysType = randomf(100.f);
	
	if (RS_specialSystems && (RS_specialNum > 0 && sysNum > 0 && sysNum % RS_specialNum == 0)) {
		System@ sys = makeSpecialSystem(Glx, position);
		if (sys !is null)
			return sys;
	}
	
	if (sysNum >= 11) {
		// We can have dead systems when we already
		// have 11 live ones (one for each possible player)
		if(sysType >= 100)
			return RS_makeSupernova(Glx, position);
//		else if (sysType >= 80)
	//		return RS_makeProtostar(Glx, position);&& RS_makeOddities
//		//else if (sysType >= 90)
//			return RS_makeBinarySystem(Glx, position);
//		else if (sysType >= 90)
//			return RS_makeAsteroidBelt(Glx, position);
//		else if (sysType >= 80 ) 
//			return RS_makeUnstableStar(Glx, position);
//		else if (sysType >= 80) 
//			return makeNeutronStar(Glx, position);
		else
			return RS_makeStandardSystem(Glx, position);
	}
	else {
		// Guaranteed live systems
//		if (sysType >= 90)
//			return RS_makeBinarySystem(Glx, position);
//		else
			return RS_makeStandardSystem(Glx, position);
	}
}

// {{{ Systems with main sequence dwarf stars, cold sub-dwars OR the larger sub-gaints AND a potential tiny white dwarf OR brown dwarf binary companion.
System@ RS_makeStandardSystem(Galaxy@ glx, vector pos) {
	// Reset orbit parameters
	orbDesc.Offset = vector(0, 0, 0);
	orbDesc.setCenter(null);
	orbDesc.PosInYear = randomf(-0.2f, -2.f);
	orbDesc.IsStatic = true;

	// Create the system
	sysDesc.Position = pos;
	sysDesc.AutoStar = false;

	System @sys = @glx.createSystem(sysDesc);
	// Create the star
	float specialB;
	float number;
	float diceroll = randomf(0.f,100.f);
	if(diceroll <= 10.f){
	// white dwarf test
	starDesc.Temperature = randomf(0.f,100000.f); // D-Class White Dwarfs
	if(starDesc.Temperature < 500.f){
		starDesc.StarColor = Color(0x22220000);
			number = 9.f;
		}
	if(starDesc.Temperature < 1000.f){
		starDesc.StarColor = Color(0x56bd481d);
			number = 8.f;
		}
	else if(starDesc.Temperature < 3000.f){
		starDesc.StarColor = Color(0xa2dda416);
			number = 7.f;
		}
	else if(starDesc.Temperature < 5000.f){	
		starDesc.StarColor = Color(0xffeed945);
			number = 6.f;
		}
	else if(starDesc.Temperature < 7500.f){	
		starDesc.StarColor = Color(0xfff1e5bd);
			number = 5.f;
		}
	else if(starDesc.Temperature < 10000.f){	
		starDesc.StarColor = Color(0xffeef1f9);
			number = 4.f;
		}
	else if(starDesc.Temperature < 25000.f){	
		starDesc.StarColor = Color(0xffe0e7f9);
			number = 3.f;
		}
	else if(starDesc.Temperature < 45000.f){	
		starDesc.StarColor = Color(0xffbbc4f3);
			number = 2.f;
		}
	else if(starDesc.Temperature < 70000.f){	
		starDesc.StarColor = Color(0xffa8adea);
			number = 1.f;
		}
	else if(starDesc.Temperature < 100000.f){	
		starDesc.StarColor = Color(0xffc9b6ea);
			number = 0.f;
		}
	float dicerollWhite = randomf(0.f,100.f);
	if(dicerollWhite <= 20.f)
	sys.addTag("DDAwarf"+number);
	else if(dicerollWhite <= 40.f)
	sys.addTag("DDBwarf"+number);
	else if(dicerollWhite <= 60.f)
	sys.addTag("DDPwarf"+number);
	else if(dicerollWhite <= 80.f)
	sys.addTag("DDQwarf"+number);
	else if(dicerollWhite <= 100.f)
	sys.addTag("DDZwarf"+number);
	
	starDesc.Radius = RS_starSizeFactor / randomf(2.f,3.f); //min-max 17-25 at factor 50 //it's a white dwarf, a degenerating core of a dead star slowly cooling. Without any generation of energy, temperature is not relevant in the math. Had it been larger as a previous live star, it would have collapsed to a neutron Star, other exotic star or a black hole.
	specialB =(sqrt(sqrt(sqrt(starDesc.Temperature))))/2.f;
	}	
//10
	else if(diceroll <= 18.f){	
	starDesc.Temperature = randomf(300, 2200);
	//	Y-Class(Near absolutely no light) Coldest Brown Dwarf.
		if(starDesc.Temperature < 250.f){
			starDesc.StarColor = Color(0x105b2b13);
			number = 9.f;
			}
		else if(starDesc.Temperature < 300.f){
			starDesc.StarColor = Color(0x115a2914);
			number = 8.f;
			}
		else if(starDesc.Temperature < 350.f){
			starDesc.StarColor = Color(0x12592615);
			number = 7.f;
			}
		else if(starDesc.Temperature < 400.f){
			starDesc.StarColor = Color(0x13572417);
			number = 6.f;
			}
		else if(starDesc.Temperature < 450.f){
			starDesc.StarColor = Color(0x14562219);
			number = 5.f;
			}
		else if(starDesc.Temperature < 500.f){
			starDesc.StarColor = Color(0x1554211c);
			number = 4.f;
			}
		else if(starDesc.Temperature < 550.f){
			starDesc.StarColor = Color(0x1653201f);
			number = 3.f;
			}
		else if(starDesc.Temperature < 600.f){
			starDesc.StarColor = Color(0x17501e24);
			number = 2.f;
			}
		else if(starDesc.Temperature < 650.f){
			starDesc.StarColor = Color(0x184f1e27);
			number = 1.f;
			}
		else if(starDesc.Temperature <= 700.f){
			starDesc.StarColor = Color(0x194e1e2a);
			number = 0.f;
	//	T-Class(Near no light) Brown Dwarf.
			}
		else if(starDesc.Temperature < 760.f){
			starDesc.StarColor = Color(0x21461c33);
			number = 9.f;
			}
		else if(starDesc.Temperature < 820.f){
			starDesc.StarColor = Color(0x224a1e34);
			number = 8.f;
			}
		else if(starDesc.Temperature < 880.f){
			starDesc.StarColor = Color(0x234e1e34);
			number = 7.f;
			}
		else if(starDesc.Temperature < 940.f){
			starDesc.StarColor = Color(0x24542035);
			number = 6.f;
			}
		else if(starDesc.Temperature < 1000.f){
			starDesc.StarColor = Color(0x25592035);
			number = 5.f;
			}
		else if(starDesc.Temperature < 1060.f){
			starDesc.StarColor = Color(0x26602134);
			number = 4.f;
			}
		else if(starDesc.Temperature < 1120.f){
			starDesc.StarColor = Color(0x27672233);
			number = 3.f;
			}
		else if(starDesc.Temperature < 1180.f){
			starDesc.StarColor = Color(0x286e2232);
			number = 2.f;
			}
		else if(starDesc.Temperature < 1240.f){
			starDesc.StarColor = Color(0x29742331);
			number = 1.f;
			}
		else if(starDesc.Temperature <= 1300.f){
			starDesc.StarColor = Color(0x307b242e);
			number = 0.f;
			}
	//	L-Class(Near weak light) Brown Dwarf.
		else if(starDesc.Temperature < 1390.f){
			starDesc.StarColor = Color(0x3283242b);
			number = 9.f;
			}
		else if(starDesc.Temperature < 1480.f){
			starDesc.StarColor = Color(0x348a2427);
			number = 8.f;
			}
		else if(starDesc.Temperature < 1570.f){
			starDesc.StarColor = Color(0x36902525);
			number = 7.f;
			}
		else if(starDesc.Temperature < 1660.f){
			starDesc.StarColor = Color(0x38962624);
			number = 6.f;
			}
		else if(starDesc.Temperature < 1750.f){
			starDesc.StarColor = Color(0x409c2723);
			number = 5.f;
			}
		else if(starDesc.Temperature < 1840.f){
			starDesc.StarColor = Color(0x42a12923);
			number = 4.f;
			}
		else if(starDesc.Temperature < 1930.f){
			starDesc.StarColor = Color(0x44a62a23);
			number = 3.f;
			}
		else if(starDesc.Temperature < 2020.f){
			starDesc.StarColor = Color(0x46aa2c24);
			number = 2.f;
			}
		else if(starDesc.Temperature < 2110.f){
			starDesc.StarColor = Color(0x48ad2e25);
			number = 1.f;
			}
		else if(starDesc.Temperature <= 2200.f){
			starDesc.StarColor = Color(0x50b13027);
			number = 0.f;
			}
			if(starDesc.Temperature <= 700.f){
				//Note: M-Class Brown Dwarf Calculation, min size is 215
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(0.65f, 0.7f);
				sys.addTag("YDwarf"+number); //brown
				specialB =0.5f;
				}
			else if(starDesc.Temperature <= 1300.f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(0.8f, 0.95f);// they are supposed to be bigger than L-Class! Gravity havent collapsed them yet.
				sys.addTag("TDwarf"+number); //brown
				specialB =0.75f;
				}
			else{
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(0.75f, 0.9f);
				sys.addTag("LDwarf"+number); //brown
				specialB =1.f;
				}
			//Note M-Class Brown Dwarfs are generated in the M-Class section.
			}
//18			
	else if(diceroll <= 32.f){
	starDesc.Temperature = randomf(2800, 4500);
	//	C-Class(Pale Red Spectrum) Carbon Star, rare Red Dwarf, occasionally Red Giant+ branch.
		if(starDesc.Temperature < 2970.f){
			starDesc.StarColor = Color(0xffdb3d24);
			number = 9.f;
			}
		else if(starDesc.Temperature < 3140.f){
			starDesc.StarColor = Color(0xffe64124);
			number = 8.f;
			}
		else if(starDesc.Temperature < 3310.f){
			starDesc.StarColor = Color(0xffee4c2e);
			number = 7.f;
			}
		else if(starDesc.Temperature < 3480.f){
			starDesc.StarColor = Color(0xffee5a3b);
			number = 6.f;
			}
		else if(starDesc.Temperature < 3650.f){
			starDesc.StarColor = Color(0xffee694a);
			number = 5.f;
			}
		else if(starDesc.Temperature < 3820.f){
			starDesc.StarColor = Color(0xffee7b5d);
			number = 4.f;
			}
		else if(starDesc.Temperature < 3990.f){
			starDesc.StarColor = Color(0xffee8366);
			number = 3.f;
			}
		else if(starDesc.Temperature < 4160.f){
			starDesc.StarColor = Color(0xffee8d70);
			number = 2.f;
			}
		else if(starDesc.Temperature < 4330.f){
			starDesc.StarColor = Color(0xffee9a7b);
			number = 1.f;
			}
		else if(starDesc.Temperature <= 4500.f){
			starDesc.StarColor = Color(0xffee9f83);
			number = 0.f;
			}
			float sizeroll = randomf(0.f,100.f);
			if(sizeroll <= 2.5f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(30.f, 36.f); //hypergiant
				sys.addTag("CHypergiant"+number); //red  randomf(30.f,36.f)
				}
			else if(sizeroll <= 6.5f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(24.f, 30.f); //supergiant
				sys.addTag("CSupergiant"+number); //red  randomf(24.f,30.f)
				}
			else if(sizeroll <= 12.f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(18.f, 24.f); //bright giant
				sys.addTag("CBrightgiant"+number); //red  randomf(18.f,24.f)
				}
			else if(sizeroll <= 20.f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(12.f, 18.f); //giant
				sys.addTag("CGiant"+number); //red  randomf(12.f,18.f)
				}
			else{
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(0.8f, 1.2f); //dwarf
				sys.addTag("CDwarf"+number); //red  randomf(0.8f, 1.2f)
				}
			specialB =2.f;
			}
//32
	else if(diceroll <= 38.f){
	starDesc.Temperature = randomf(2800, 4500);
	//	S-Class(Dull Red Spectrum) Occasionally Red Giant+ branch. Transition stage of M-Class to C-Class.
		if(starDesc.Temperature < 2970.f){
			starDesc.StarColor = Color(0xffe05733);
			number = 9.f;
			}
		else if(starDesc.Temperature < 3140.f){
			starDesc.StarColor = Color(0xffec5b33);
			number = 8.f;
			}
		else if(starDesc.Temperature < 3310.f){
			starDesc.StarColor = Color(0xfffa6333);
			number = 7.f;
			}
		else if(starDesc.Temperature < 3480.f){
			starDesc.StarColor = Color(0xffff7038);
			number = 6.f;
			}
		else if(starDesc.Temperature < 3650.f){
			starDesc.StarColor = Color(0xffff8046);
			number = 5.f;
			}
		else if(starDesc.Temperature < 3820.f){
			starDesc.StarColor = Color(0xffff9254);
			number = 4.f;
			}
		else if(starDesc.Temperature < 3990.f){
			starDesc.StarColor = Color(0xffffa263);
			number = 3.f;
			}
		else if(starDesc.Temperature < 4160.f){
			starDesc.StarColor = Color(0xffffaf6f);
			number = 2.f;
			}
		else if(starDesc.Temperature < 4330.f){
			starDesc.StarColor = Color(0xffffbc78);
			number = 1.f;
			}
		else if(starDesc.Temperature <= 4500.f){
			starDesc.StarColor = Color(0xffffc680);
			number = 0.f;
			}
			float sizeroll = randomf(0.f,100.f);
			if(sizeroll <= 2.5f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(30.f, 36.f); //hypergiant
				sys.addTag("SHypergiant"+number); //red
				}
			else if(sizeroll <= 6.5f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(24.f, 30.f); //supergiant
				sys.addTag("SSupergiant"+number); //red
				}
			else if(sizeroll <= 12.f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(18.f, 24.f); //bright giant
				sys.addTag("SBrightgiant"+number); //red
				}
			else if(sizeroll <= 20.f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(12.f, 18.f); //giant
				sys.addTag("SGiant"+number); //red
				}
			else{
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(0.8f, 1.2f); //dwarf
				sys.addTag("SDwarf"+number); //red
				}
			specialB =2.f;
			}						
//38			
	else if(diceroll <= 48.f){
	// M-Class(Red Spectrum) Main Sequence Red Dwarf and occasional Gaint+
		starDesc.Temperature = randomf(2200, 3900);
		if(starDesc.Temperature < 2370.f){
			starDesc.StarColor = Color(0xffbb2c0d);
			number = 9.f;
			}
		else if(starDesc.Temperature < 2540.f){
			starDesc.StarColor = Color(0xffbb2f14);
			number = 8.f;
			}
		else if(starDesc.Temperature < 2710.f){
			starDesc.StarColor = Color(0xffbc3716);
			number = 7.f;
			}
		else if(starDesc.Temperature < 2880.f){
			starDesc.StarColor = Color(0xffbe3b16);
			number = 6.f;
			}
		else if(starDesc.Temperature < 3050.f){
			starDesc.StarColor = Color(0xffc24317);
			number = 4.f;
			}
		else if(starDesc.Temperature < 3220.f){
			starDesc.StarColor = Color(0xffc44917);
			number = 5.f;
			}
		else if(starDesc.Temperature < 3390.f){
			starDesc.StarColor = Color(0xffc75217);
			number = 3.f;
			}
		else if(starDesc.Temperature < 3560.f){
			starDesc.StarColor = Color(0xffc85b18);
			number = 2.f;
			}
		else if(starDesc.Temperature < 3730.f){
			starDesc.StarColor = Color(0xffc96318);
			number = 1.f;
			}
		else if(starDesc.Temperature <= 3900.f){
			starDesc.StarColor = Color(0xffcd6c19);
			number = 0.f;
			}
			float sizeroll = randomf(0.f,100.f);
			if(sizeroll <= 2.5f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(30.f, 36.f);	//hypergiant
				sys.addTag("MHypergiant"+number); //red
				specialB =2.f;
				}
			else if(sizeroll <= 6.5f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(24.f, 30.f); //supergiant
				sys.addTag("MSupergiant"+number); //red
				specialB =2.f;
				}
			else if(sizeroll <= 12.f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(18.f, 24.f); //bright giant 
				sys.addTag("MBrightgiant"+number); //red
				specialB =2.f;
				}
			else if(sizeroll <= 20.f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(12.f, 18.f); //giant
				sys.addTag("MGiant"+number); //red
				specialB =2.f;
				}
			else if(starDesc.Temperature <= 2800.f){
				//Note: M-Class Brown Dwarf Calculation, min size is 215
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(0.9f, 1.1f); //brown dwarf
				sys.addTag("MDwarf"+number); //brown
				specialB =1.2f;
				}
			else{
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(0.8f, 1.2f); //red dwarf
				sys.addTag("MDwarf"+number); //red
				specialB =2.f;
				}
			}
//48		
	else if(diceroll <= 62.f){
	starDesc.Temperature = randomf(3900, 5200);
	//	K-Class(Orange Spectrum) Main Sequence Orange Dwarf
		if(starDesc.Temperature < 4030.f){
			starDesc.StarColor = Color(0xffce761a);
			number = 9.f;
			}
		else if(starDesc.Temperature < 4160.f){
			starDesc.StarColor = Color(0xffd17f19);
			number = 8.f;
			}
		else if(starDesc.Temperature < 4290.f){
			starDesc.StarColor = Color(0xffd4881a);
			number = 7.f;
			}
		else if(starDesc.Temperature < 4420.f){
			starDesc.StarColor = Color(0xffd69019);
			number = 6.f;
			}
		else if(starDesc.Temperature < 4550.f){
			starDesc.StarColor = Color(0xffdb9b19);
			number = 5.f;
			}
		else if(starDesc.Temperature < 4680.f){
			starDesc.StarColor = Color(0xffdba31a);
			number = 4.f;
			}
		else if(starDesc.Temperature < 4810.f){
			starDesc.StarColor = Color(0xffdfa919);
			number = 3.f;
			}
		else if(starDesc.Temperature < 4940.f){
			starDesc.StarColor = Color(0xffe1b219);
			number = 2.f;
			}
		else if(starDesc.Temperature < 5070.f){
			starDesc.StarColor = Color(0xffe3b91a);
			number = 1.f;
			}
		else if(starDesc.Temperature <= 5200.f){
			starDesc.StarColor = Color(0xffe5bf1a);
			number = 0.f;
			}
			float sizeroll = randomf(0.f,100.f);
			if(starDesc.Temperature <= 4500.f && sizeroll <= 2.5f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(30.f, 36.f); //hypergiant
				sys.addTag("KHypergiant"+number); //red
				}
			else if(starDesc.Temperature > 4500.f && sizeroll <= 0.5f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(30.f, 36.f)*0.6f; //hypergiant
				sys.addTag("KHypergiant"+number); //yellow
				}
			else if(starDesc.Temperature <= 4500.f && sizeroll <= 6.5f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(24.f, 30.f); //supergiant
				sys.addTag("KSupergiant"+number); //red
				}
			else if(starDesc.Temperature > 4500.f && sizeroll <= 1.5f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(24.f, 30.f)*0.6f; //supergiant
				sys.addTag("KSupergiant"+number); //yellow
				}
			else if(starDesc.Temperature <= 4500.f && sizeroll <= 12.f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(18.f, 24.f); //bright giant
				sys.addTag("KBrightgiant"+number); //red
				}
			else if(starDesc.Temperature > 4500.f && sizeroll <= 2.875f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(18.f, 24.f)*0.6f; //bright giant
				sys.addTag("KBrightgiant"+number); //yellow
				}
			else if(starDesc.Temperature <= 4500.f && sizeroll <= 20.f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(12.f, 18.f); //giant
				sys.addTag("KGiant"+number); //red
				}
			else if(starDesc.Temperature > 4500.f && sizeroll <= 4.875f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(12.f, 18.f)*0.6f; //giant
				sys.addTag("KGiant"+number); //yellow
				}
			else if(starDesc.Temperature > 4500.f && sizeroll <= 32.4375f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(1.4f, 2.6f); //subgiant
				sys.addTag("KSubgiant"+number); //orange
				}
			else{
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(0.8f, 1.2f); //Main Sequence
				sys.addTag("KMSQ"+number); //orange
				}
			specialB =2.f;
			}
//62			
	else if(diceroll <= 76.f){
	starDesc.Temperature = randomf(5200, 6000);
	// G-Class(Yellow Spectrum) Main Sequence Yellow Dwarf 
		if(starDesc.Temperature < 5280.f){
			starDesc.StarColor = Color(0xffe7c41b);
			number = 9.f;
			}
		else if(starDesc.Temperature < 5360.f){
			starDesc.StarColor = Color(0xffe8c91e);
			number = 8.f;
			}
		else if(starDesc.Temperature < 5440.f){
			starDesc.StarColor = Color(0xffe8cc24);
			number = 7.f;
			}
		else if(starDesc.Temperature < 5520.f){
			starDesc.StarColor = Color(0xffe8ce2c);
			number = 5.f;
			}
		else if(starDesc.Temperature < 5600.f){
			starDesc.StarColor = Color(0xffead132);
			number = 5.f;
			}
		else if(starDesc.Temperature < 5680.f){
			starDesc.StarColor = Color(0xffecd33a);
			number = 4.f;
			}
		else if(starDesc.Temperature < 5760.f){
			starDesc.StarColor = Color(0xffecd744);
			number = 3.f;
			}
		else if(starDesc.Temperature < 5840.f){
			starDesc.StarColor = Color(0xffecda51);
			number = 2.f;
			}
		else if(starDesc.Temperature < 5920.f){
			starDesc.StarColor = Color(0xffeedc58);
			number = 1.f;
			}
		else if(starDesc.Temperature <= 6000.f){
			starDesc.StarColor = Color(0xffefdd62);
			number = 0.f;
			}
			float sizeroll = randomf(0.f,100.f);
			if(sizeroll <= 0.5f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(30.f, 36.f)*0.6f; //hypergiant
				sys.addTag("GHypergiant"+number); //yellow
				}
			else if(sizeroll <= 1.5f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(24.f, 30.f)*0.6f; //supergiant
				sys.addTag("GSupergiant"+number); //yellow
				}
			else if(sizeroll <= 2.875f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(18.f, 24.f)*0.6f; //bright giant
				sys.addTag("GBrightgiant"+number); //yellow
				}
			else if(sizeroll <= 4.875f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(12.f, 18.f)*0.6f; //giant
				sys.addTag("GGiant"+number); //yellow
				}
			else if(sizeroll <= 24.875f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(1.4f, 2.6f); //subgiant
				sys.addTag("GSubgiant"+number); //yellow
				}
			else{
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(0.8f, 1.2f); //Main Sequence
				sys.addTag("GMSQ"+number); //yellow
				}
			specialB =2.f;
			}
//76
	else if(diceroll <= 84.f){
	starDesc.Temperature = randomf(6000, 7600);
	//	F-Class(Yellow White Spectrum) Main Sequence Yellow-White Dwarf
		if(starDesc.Temperature < 6160.f){
			starDesc.StarColor = Color(0xfff0df6d);
			number = 9.f;
			}
		else if(starDesc.Temperature < 6320.f){
			starDesc.StarColor = Color(0xfff1df7b);
			number = 8.f;
			}
		else if(starDesc.Temperature < 6480.f){
			starDesc.StarColor = Color(0xfff1e288);
			number = 7.f;
			}
		else if(starDesc.Temperature < 6640.f){
			starDesc.StarColor = Color(0xfff2e390);
			number = 6.f;
			}
		else if(starDesc.Temperature < 6800.f){
			starDesc.StarColor = Color(0xfff2e49c);
			number = 5.f;
			}
		else if(starDesc.Temperature < 6960.f){
			starDesc.StarColor = Color(0xfff2e3a7);
			number = 4.f;
			}
		else if(starDesc.Temperature < 7120.f){
			starDesc.StarColor = Color(0xfff1e4b2);
			number = 3.f;
			}
		else if(starDesc.Temperature < 7280.f){
			starDesc.StarColor = Color(0xfff3e5bb);
			number = 2.f;
			}
		else if(starDesc.Temperature < 7440.f){
			starDesc.StarColor = Color(0xfff4e6c6);
			number = 1.f;
			}
		else if(starDesc.Temperature <= 7600.f){
			starDesc.StarColor = Color(0xfff4e5d0);
			number = 0.f;
			}
			float sizeroll = randomf(0.f,100.f);
			if(sizeroll <= 0.5f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(30.f, 36.f)*0.6f; //hypergiant
				sys.addTag("FHypergiant"+number); //yellow
				}
			else if(sizeroll <= 1.5f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(24.f, 30.f)*0.6f; //supergiant
				sys.addTag("FSupergiant"+number); //yellow
				}
			else if(sizeroll <= 2.875f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(18.f, 24.f)*0.6f; //bright giant
				sys.addTag("FBrightgiant"+number); //yellow
				}
			else if(sizeroll <= 4.875f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(12.f, 18.f)*0.6f; //giant
				sys.addTag("FGiant"+number); //yellow
				}
			else if(sizeroll <= 24.875f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(1.4f, 2.6f); //subgiant
				sys.addTag("FSubgiant"+number); //white yellow
				}
			else{
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(0.8f, 1.2f); //Main Sequence
				sys.addTag("FMSQ"+number); //white yellow
				}
			specialB =2.f;
			}
//84
	else if(diceroll <= 89.5f){
	starDesc.Temperature = randomf(7600, 10000);
	// A-Class(White Spectrum - NOT a White Dwarf!) Main Sequence Dwarf Star
		if(starDesc.Temperature < 7840.f){
			starDesc.StarColor = Color(0xfff2e8d9);
			number = 9.f;
			}
		else if(starDesc.Temperature < 8080.f){
			starDesc.StarColor = Color(0xfff4ebea);
			number = 8.f;
			}
		else if(starDesc.Temperature < 8320.f){
			starDesc.StarColor = Color(0xfff3ecf3);
			number = 7.f;
			}
		else if(starDesc.Temperature < 8560.f){
			starDesc.StarColor = Color(0xfff3ecf4);
			number = 6.f;
			}
		else if(starDesc.Temperature < 8800.f){
			starDesc.StarColor = Color(0xfff3ecf4);
			number = 5.f;
			}
		else if(starDesc.Temperature < 9040.f){
			starDesc.StarColor = Color(0xfff3ecf4);
			number = 4.f;
			}
		else if(starDesc.Temperature < 9280.f){
			starDesc.StarColor = Color(0xffefecf3);
			number = 3.f;
			}
		else if(starDesc.Temperature < 9520.f){
			starDesc.StarColor = Color(0xffeeedf4);
			number = 2.f;
			}
		else if(starDesc.Temperature < 9760.f){
			starDesc.StarColor = Color(0xffebebf3);
			number = 1.f;
			}
		else if(starDesc.Temperature <= 10000.f){
			starDesc.StarColor = Color(0xffe5e7f4);
			number = 0.f;
			}
			float sizeroll = randomf(0.f,100.f);
			if(starDesc.Temperature >= 8500.f && sizeroll <= 0.125f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(30.f, 36.f)*0.35f; //hypergiant
				sys.addTag("AHypergiant"+number); //blue
				}
			else if(starDesc.Temperature < 8500.f && sizeroll <= 0.5f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(30.f, 36.f)*0.6f; //hypergiant
				sys.addTag("AHypergiant"+number); //yellow
				}
			else if(starDesc.Temperature >= 8500.f && sizeroll <= 0.325f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(24.f, 30.f)*0.35f; //supergiant
				sys.addTag("ASupergiant"+number); //blue
				}
			else if(starDesc.Temperature < 8500.f && sizeroll <= 1.5f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(24.f, 30.f)*0.6f; //supergiant
				sys.addTag("ASupergiant"+number); //yellow
				}
			else if(starDesc.Temperature >= 8500.f && sizeroll <= 0.6f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(18.f, 24.f)*0.35f; //bright giant
				sys.addTag("ABrightgiant"+number); //blue
				}
			else if(starDesc.Temperature < 8500.f && sizeroll <= 2.875f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(18.f, 24.f)*0.6f; //bright giant
				sys.addTag("ABrightgiant"+number); //yellow
				}
			else if(starDesc.Temperature >= 8500.f && sizeroll <= 1.f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(12.f, 18.f)*0.35f; //giant
				sys.addTag("AGiant"+number); //blue
				}
			else if(starDesc.Temperature < 8500.f && sizeroll <= 4.875f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(12.f, 18.f)*0.6f; //giant
				sys.addTag("AGiant"+number); //yellow
				}
			else if(sizeroll <= 22.9375f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(1.4f, 2.6f); //subgiant
				sys.addTag("ASubgiant"+number); //white
				}
			else{
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(0.8f, 1.2f); //Main Sequence
				sys.addTag("AMSQ"+number); //white
				}
			specialB =2.f;
			}
//89.5
	else if(diceroll <= 94.f){
	starDesc.Temperature = randomf(10000, 30000);
	// B-Class(Blue-White Spectrum) Class-V Main Sequence Dwarf Star
		if(starDesc.Temperature < 12000.f){
			starDesc.StarColor = Color(0xffe2e5f4);
			number = 9.f;
			}
		else if(starDesc.Temperature < 14000.f){
			starDesc.StarColor = Color(0xffdfe5f4);
			number = 8.f;
			}
		else if(starDesc.Temperature < 16000.f){
			starDesc.StarColor = Color(0xffdee4f3);
			number = 7.f;
			}
		else if(starDesc.Temperature < 18000.f){
			starDesc.StarColor = Color(0xffdce3f4);
			number = 6.f;
			}
		else if(starDesc.Temperature < 20000.f){
			starDesc.StarColor = Color(0xffdae1f4);
			number = 5.f;
			}
		else if(starDesc.Temperature < 22000.f){
			starDesc.StarColor = Color(0xffd8e0f4);
			number = 4.f;
			}
		else if(starDesc.Temperature < 24000.f){
			starDesc.StarColor = Color(0xffd2def4);
			number = 3.f;
			}
		else if(starDesc.Temperature < 26000.f){
			starDesc.StarColor = Color(0xffd2def4);
			number = 2.f;
			}
		else if(starDesc.Temperature < 28000.f){
			starDesc.StarColor = Color(0xffcddaf4);
			number = 1.f;
			}
		else if(starDesc.Temperature <= 30000.f){
			starDesc.StarColor = Color(0xffcbd7f4);
			number = 0.f;
			}
			float sizeroll = randomf(0.f,100.f);
			if(sizeroll <= 0.25f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(30.f, 36.f)*0.35f; //hypergiant
				sys.addTag("BHypergiant"+number); //blue
				}
			else if(sizeroll <= 0.65f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(24.f, 30.f)*0.35f; //supergiant
				sys.addTag("BSupergiant"+number); //blue
				}
			else if(sizeroll <= 1.2f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(18.f, 24.f)*0.35f; //bright giant
				sys.addTag("BBrightgiant"+number); //blue
				}
			else if(sizeroll <= 2.f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(12.f, 18.f)*0.35f; //giant
				sys.addTag("BGiant"+number); //blue
				}
			else if(sizeroll <= 22.f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(1.4f, 2.6f); //subgiant
				sys.addTag("BSubgiant"+number); //whiteblue
				}
			else{
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(0.8f, 1.2f); //Main Sequence
				sys.addTag("BMSQ"+number); //whiteblue
				}
			specialB =2.f;
			}
//94
	else if(diceroll <= 100.f){
	starDesc.Temperature = randomf(30000, 52000);
	// O-Class(Blue Spectrum - NOT a Blue Dwarf!) Main Sequence Dwarf Star
		if(starDesc.Temperature < 32200.f){	
			starDesc.StarColor = Color(0xffc6d3f4);			
			number = 2.f;
			}
		else if(starDesc.Temperature < 34400.f){
			starDesc.StarColor = Color(0xffc1cdf4);			
			number = 2.f;
			}
		else if(starDesc.Temperature < 36600.f){
			starDesc.StarColor = Color(0xffbbc9f4);			
			number = 2.f;
			}
		else if(starDesc.Temperature < 38800.f){
			starDesc.StarColor = Color(0xffb3c2f2);			
			number = 2.f;
			}
		else if(starDesc.Temperature < 41000.f){
			starDesc.StarColor = Color(0xffa9b8f3);			
			number = 2.f;
			}
		else if(starDesc.Temperature < 43200.f){
			starDesc.StarColor = Color(0xff9fafee);			
			number = 2.f;
			}
		else if(starDesc.Temperature < 45400.f){
			starDesc.StarColor = Color(0xff92a4ed);			
			number = 2.f;
			}
		else if(starDesc.Temperature < 47600.f){
			starDesc.StarColor = Color(0xff8399ed);			
			number = 2.f;
			}
		else if(starDesc.Temperature < 49800.f){
			starDesc.StarColor = Color(0xff798ee8);			
			number = 2.f;
			}
		else if(starDesc.Temperature <= 52000.f){
			starDesc.StarColor = Color(0xff6e83e4);
			}
				float sizeroll = randomf(0.f,100.f);
			if(sizeroll <= 0.5f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(30.f, 36.f)*0.35f; //hypergiant randomf(48.f,96.f)
				sys.addTag("OHypergiant"+number); //blue
				}
			else if(sizeroll <= 1.3f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(24.f, 30.f)*0.35f; //supergiant randomf(24.f,48.f)
				sys.addTag("OSupergiant"+number); //blue
				}
			else if(sizeroll <= 2.4f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(18.f, 24.f)*0.35f; //bright giant randomf(12.f,24.f)
				sys.addTag("OBrightgiant"+number); //blue
				}
			else if(sizeroll <= 4.f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(12.f, 18.f)*0.35f; //giant randomf (8.f, 12.f)
				sys.addTag("OGiant"+number); //blue
				}
			else if(sizeroll <= 24.f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(1.4f, 2.6f); //subgiant
				sys.addTag("OSubgiant"+number); //blue
				}
			else{
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(0.8f, 1.2f); //Main Sequence
				sys.addTag("OMSQ"+number); //blue 
				}
			specialB =2.f;
			}
	starDesc.Brightness = (sqrt(sqrt(Pi*(starDesc.Radius^2)*starDesc.Temperature)))*specialB;
	float spriteSizeGlow = ((Pi*(starDesc.Radius^2)*starDesc.Temperature))/starDesc.Brightness;
	float spriteSize = starDesc.Radius* 55.f;
	float spriteSizeCloseGlow = starDesc.Radius* 10.f;
	Color StarColor = starDesc.StarColor;
	float StarTemp = starDesc.Temperature;
	starDesc.setOrbit(orbDesc);

	Star@ st = sys.makeStar(starDesc);
	
	float starRad = starDesc.Radius;

	Effect starEffect("SelfHealing");
	starEffect.set("Rate", 100000000.f);	
	st.toObject().addTimedEffect(starEffect, pow(10, 35), 0.f, st.toObject(), null, null, TEF_None);		
	
	State@ h3 = st.toObject().getState(strH3);
	h3.max = starDesc.Temperature * randomf(50000,100000);
	h3.val = h3.max * (0.5f + (randomf(0.5f)));	
	
	// Set planet orbit parameters

	orbDesc.MassRadius = starDesc.Radius;
	orbDesc.Mass = starDesc.Radius * RS_starMassFactor;
	orbDesc.Radius = RS_orbitRadiusFactor + sqrt(starDesc.Radius * starDesc.Temperature * 2.f);
	orbDesc.IsStatic = false;
	
	if((starDesc.Radius / RS_starSizeFactor) > 36.f){
		int belts = rand(0, 3) + rand(0, 3) + rand(1, 3);;
		while (randomf(1.f) < 1.f / (belts + 2.f)) {
			RS_makeRandomAsteroidNew(sys, rand(250,600), starRad);
			++belts;
		}
		sys.toObject().setStat(getEmpireByID(-1), strLivable, 0.f);
	}
		else if((starDesc.Radius / RS_starSizeFactor) > 32.f){
	int pCount = rand(0, 3);
	
	for(int p = 0; p < pCount; ++p) {
		orbDesc.Radius += (randomf(1.3f, 2.1f) * RS_orbitRadiusFactor);
		orbDesc.Eccentricity = randomf(0.5f, 1.5f);
		if(randomf(1.f) < 0.05f)
		orbDesc.Yaw = randomf(-0.1f,0.1f);
		if(randomf(1.f) < 0.05f)
		orbDesc.Pitch = randomf(-0.1f,0.1f);
		
		RS_makeRandomPlanet(sys, p, pCount);
	}
	int dpCount = rand(0, 3);
	
	for(int dp = 0; dp < dpCount; ++dp) {
		orbDesc.Radius += (randomf(1.3f, 2.1f) * RS_orbitRadiusFactor);
		orbDesc.Eccentricity = randomf(0.5f, 1.5f);
		if(randomf(1.f) < 0.1f)
		orbDesc.Yaw = randomf(-0.2f,0.2f);
		if(randomf(1.f) < 0.1f)
		orbDesc.Pitch = randomf(-0.2f,0.2f);
		
		RS_makeRandomDwarfPlanet(sys, dp, dpCount);
	}
		// Add oddities to system
	if(RS_makeOddities) {	
		int comets = 1;
		while (randomf(1.f) < (0.60f / comets)) {
			RS_makeRandomComet(sys);
			++comets;
		}
		
		int belts = 0;
		while (randomf(1.f) < 1.f / (belts + 4.f) && belts < pCount) {
			RS_makeRandomAsteroidNew(sys, rand(250,600), starRad);
			++belts;
			}
		}
	}
	else if((starDesc.Radius / RS_starSizeFactor) > 26.f){
	int pCount = rand(1, 3) + rand(0, 3);
	
	for(int p = 0; p < pCount; ++p) {
		orbDesc.Radius += (randomf(1.3f, 2.1f) * RS_orbitRadiusFactor);
		orbDesc.Eccentricity = randomf(0.5f, 1.5f);
		if(randomf(1.f) < 0.05f)
		orbDesc.Yaw = randomf(-0.1f,0.1f);
		if(randomf(1.f) < 0.05f)
		orbDesc.Pitch = randomf(-0.1f,0.1f);
		
		RS_makeRandomPlanet(sys, p, pCount);
		if(!RS_balancedStart || (pCount > 2 && pCount < 5))
		sys.toObject().setStat(getEmpireByID(-1), strLivable, 1.f);
	}
	int dpCount = rand(1, 3) + rand(0, 3);
	
	for(int dp = 0; dp < dpCount; ++dp) {
		orbDesc.Radius += (randomf(1.3f, 2.1f) * RS_orbitRadiusFactor);
		orbDesc.Eccentricity = randomf(0.5f, 1.5f);
		if(randomf(1.f) < 0.1f)
		orbDesc.Yaw = randomf(-0.2f,0.2f);
		if(randomf(1.f) < 0.1f)
		orbDesc.Pitch = randomf(-0.2f,0.2f);

		RS_makeRandomDwarfPlanet(sys, dp, dpCount);
	}
		// Add oddities to system
	if(RS_makeOddities) {	
		int comets = 1;
		while (randomf(1.f) < (0.60f / comets)) {
			RS_makeRandomComet(sys);
			++comets;
		}
		
		int belts = 0;
		while (randomf(1.f) < 1.f / (belts + 3.f) && belts < pCount) {
			RS_makeRandomAsteroidNew(sys, rand(250,600), starRad);
			++belts;
			}
		}
	}
	else if((starDesc.Radius / RS_starSizeFactor) > 16.f){
	int pCount = rand(1, 3) + rand(0, 3) + rand(0, 3);
	
	for(int p = 0; p < pCount; ++p) {
		orbDesc.Radius += (randomf(1.3f, 2.1f) * RS_orbitRadiusFactor);
		orbDesc.Eccentricity = randomf(0.5f, 1.5f);
		if(randomf(1.f) < 0.05f)
		orbDesc.Yaw = randomf(-0.1f,0.1f);
		if(randomf(1.f) < 0.05f)
		orbDesc.Pitch = randomf(-0.1f,0.1f);
		
		RS_makeRandomPlanet(sys, p, pCount);
		if(!RS_balancedStart || (pCount > 2 && pCount < 5))
		sys.toObject().setStat(getEmpireByID(-1), strLivable, 1.f);
	}
	int dpCount = rand(0, 3) + rand(0, 3);
	
	for(int dp = 0; dp < dpCount; ++dp) {
		orbDesc.Radius += (randomf(1.3f, 2.1f) * RS_orbitRadiusFactor);
		orbDesc.Eccentricity = randomf(0.5f, 1.5f);
		if(randomf(1.f) < 0.1f)
		orbDesc.Yaw = randomf(-0.2f,0.2f);
		if(randomf(1.f) < 0.1f)
		orbDesc.Pitch = randomf(-0.2f,0.2f);
		
		RS_makeRandomDwarfPlanet(sys, dp, dpCount);
	}
	// Add oddities to system
	if(RS_makeOddities) {	
		int comets = 1;
		while (randomf(1.f) < (0.60f / comets)) {
			RS_makeRandomComet(sys);
			++comets;
		}
		
		int belts = 0;
		while (randomf(1.f) < 1.f / (belts + 2.f) && belts < pCount) {
			RS_makeRandomAsteroidNew(sys, rand(250,600), starRad);
			++belts;
			}
		}
	}
	else if((starDesc.Radius / RS_starSizeFactor) > 6.f){
	int pCount = rand(0, 3) + rand(0, 3);
	
	for(int p = 0; p < pCount; ++p) {
		orbDesc.Radius += (randomf(1.3f, 2.1f) * RS_orbitRadiusFactor);
		orbDesc.Eccentricity = randomf(0.5f, 1.5f);
		if(randomf(1.f) < 0.05f)
		orbDesc.Yaw = randomf(-0.1f,0.1f);
		if(randomf(1.f) < 0.05f)
		orbDesc.Pitch = randomf(-0.1f,0.1f);
		
		RS_makeRandomPlanet(sys, p, pCount);
		if(!RS_balancedStart || (pCount > 2 && pCount < 5))
		sys.toObject().setStat(getEmpireByID(-1), strLivable, 1.f);
	}
	int dpCount = rand(1, 3) + rand(0, 3);
	
	for(int dp = 0; dp < dpCount; ++dp) {
		orbDesc.Radius += (randomf(1.3f, 2.1f) * RS_orbitRadiusFactor);
		orbDesc.Eccentricity = randomf(0.5f, 1.5f);
		if(randomf(1.f) < 0.1f)
		orbDesc.Yaw = randomf(-0.2f,0.2f);
		if(randomf(1.f) < 0.1f)
		orbDesc.Pitch = randomf(-0.2f,0.2f);
		
		RS_makeRandomDwarfPlanet(sys, dp, dpCount);
	}
		// Add oddities to system
	if(RS_makeOddities) {	
		int comets = 1;
		while (randomf(1.f) < (0.60f / comets)) {
			RS_makeRandomComet(sys);
			++comets;
		}
		
		int belts = 0;
		while (randomf(1.f) < 1.f / (belts + 2.f) && belts < pCount) {
			RS_makeRandomAsteroidNew(sys, rand(250,600), starRad);
			++belts;
			}
		}
	}
	else{
	int pCount = rand(0, 3);
	
	for(int p = 0; p < pCount; ++p) {
		orbDesc.Radius += (randomf(1.3f, 2.1f) * RS_orbitRadiusFactor);
		orbDesc.Eccentricity = randomf(0.5f, 1.5f);
		if(randomf(1.f) < 0.05f)
		orbDesc.Yaw = randomf(-0.1f,0.1f);
		if(randomf(1.f) < 0.05f)
		orbDesc.Pitch = randomf(-0.1f,0.1f);
		
		RS_makeRandomPlanet(sys, p, pCount);

	}
	int dpCount = rand(0, 3) + rand(0, 3);
	
	for(int dp = 0; dp < dpCount; ++dp) {
		orbDesc.Radius += (randomf(1.3f, 2.1f) * RS_orbitRadiusFactor);
		orbDesc.Eccentricity = randomf(0.5f, 1.5f);
		if(randomf(1.f) < 0.1f)
		orbDesc.Yaw = randomf(-0.2f,0.2f);
		if(randomf(1.f) < 0.1f)
		orbDesc.Pitch = randomf(-0.2f,0.2f);
		
		RS_makeRandomDwarfPlanet(sys, dp, dpCount);
	}
		// Add oddities to system
	if(RS_makeOddities) {	
		int comets = 1;
		while (randomf(1.f) < (0.60f / comets)) {
			RS_makeRandomComet(sys);
			++comets;
		}
		
		int belts = 0;
		while (randomf(1.f) < 1.f / (belts + 2.f) && belts < pCount) {
			RS_makeRandomAsteroidNew(sys, rand(250,600), starRad);
			++belts;
			}
		}
	}

	if(specialB >1.f){
	createEnvironmentStarX(spriteSize, pos, StarColor);
	createEnvironmentStarGlow(spriteSizeGlow, pos, StarColor);
	createEnvironmentCloseGlow(spriteSizeCloseGlow, pos, StarColor);
	}
	else{
	createEnvironmentStarGlow(spriteSizeGlow, pos, StarColor);
	}	
	return sys;
}
// }}}

// {{{ Binary System
System@ RS_makeBinarySystem(Galaxy@ glx, vector pos) {
	// Create the system
	sysDesc.Position = pos;
	sysDesc.AutoStar = false;

	System @sys = @glx.createSystem(sysDesc);
	sys.toObject().setStat(getEmpireByID(-1), strLivable, 1.f);

	// Star details
	starDesc.Brightness = 1;

	// Orbit details
	float orbOffset = 40.f;
	float orbRadius = 130.f;
	orbDesc.Eccentricity = 0.5f;

	orbDesc.Mass = 16.f;
	orbDesc.MassRadius = 8.f;
	orbDesc.Radius = orbRadius;
	orbDesc.Yaw = randomf(twoPi);

	// Create the primary star
	orbDesc.PosInYear = 0.f;
	orbDesc.Offset = vector(-orbOffset, 0, 0);
	starDesc.Temperature = randomf(2000,60000);
	starDesc.Brightness = 7;
	starDesc.Radius = randomf(70.f, 110.f);
	starDesc.setOrbit(orbDesc);
	
	float primaryRadius = starDesc.Radius;
	Star@ primary = sys.makeStar(starDesc);
	
	Effect starEffect("SelfHealing");
	starEffect.set("Rate", 100000000.f);
	primary.toObject().addTimedEffect(starEffect, pow(10, 35), 0.f, primary.toObject(), null, null, TEF_None);		

	State@ h3 = primary.toObject().getState(strH3);
	h3.max = starDesc.Temperature * randomf(25000,50000);
	h3.val = h3.max * (0.5f + (randomf(0.5f)));	
	
	// Create the secondary star
	orbDesc.PosInYear = 0.5f;
	orbDesc.Offset = vector(orbOffset, 0, 0);
	starDesc.Temperature = randomf(2000,21000);
	starDesc.Brightness = 7;
	starDesc.Radius = randomf(70.f, 110.f);
	starDesc.setOrbit(orbDesc);
	
	float secondaryRadius = starDesc.Radius;
	Star@ secondary = sys.makeStar(starDesc);

	secondary.toObject().addTimedEffect(starEffect, pow(10, 35), 0.f, secondary.toObject(), null, null, TEF_None);

	State@ he3 = secondary.toObject().getState(strH3);
	he3.max = starDesc.Temperature * randomf(25000,50000);
	he3.val = he3.max * (0.5f + (randomf(0.5f)));		
	
	// Set planet orbit parameters
	orbDesc.Yaw = 0.f;
	orbDesc.MassRadius = starDesc.Radius * RS_starSizeFactor;
	orbDesc.Mass = starDesc.Radius * RS_starMassFactor * RS_starSizeFactor;
	orbDesc.Radius = RS_orbitRadiusFactor * 2.5f;
	orbDesc.PosInYear = -1.f;
	orbDesc.Offset = vector(0, 0, 0);

	int pCount = rand(1, 6) + rand(1, 8);
	
	for(int p = 0; p < pCount; ++p) {
		orbDesc.Radius += randomf(1.3f, 2.1f) * RS_orbitRadiusFactor;
		orbDesc.Eccentricity = randomf(0.5f, 1.5f);

		RS_makeRandomPlanet(sys, p, pCount);
	}

	orbDesc.setCenter(null);
	orbDesc.PosInYear = -1.f;


	return sys;
}

// {{{ Asteroid belt
System@ RS_makeAsteroidBelt(Galaxy@ glx, vector pos) {
	// Create the system
	System@ sys;
	sysDesc.Position = pos;
	sysDesc.AutoStar = false;
	float maxRad = randomf(3.f, 8.f) * RS_orbitRadiusFactor;
	sysDesc.StartRadius = 3.f * maxRad;
	
	@sys = @glx.createSystem(sysDesc);

	// Create the asteroids
	asteroid_desc.clear();
	asteroid_desc.setFloat(strOrbMass, 0.1f); //Slow down the orbit

	uint rocks = rand(40, 60) * round(maxRad / RS_orbitRadiusFactor);;
	float radius;
	
	for(uint i = 0; i < rocks; ++i) {
		if (i == 0)
			radius = 140.f;
		else if (i % 10 == 0)
			radius = randomf(30.f, 90.f);
		else
			radius = randomf(6.f, 30.f);

		float oreVal = randomf(25000.f, 26000.f) * radius * radius;
		asteroid_desc.setFloat(strMass, oreVal);

		asteroid_desc.setFloat(strRadius, radius);
		asteroid_desc.setFloat(strOrbYaw, randomf(twoPi));
		asteroid_desc.setFloat(strOrbEcc, randomf(0.9f,1.1f));
		asteroid_desc.setFloat(strOrbPitch, randomf(twoPi));
		
		if (i == 0) {
			asteroid_desc.setFloat(strOrbRad, 0.01f);
			asteroid_desc.setFloat(strOrbMass, 0.0001f); //Slow down the orbit
			asteroid_desc.setFloat(strOrbDays, 0.f);
		}
		else {
			asteroid_desc.setFloat(strOrbRad, 160.f + randomf(1.2f) * (maxRad - 160.f));
			asteroid_desc.setFloat(strOrbMass, 0.1f); //Slow down the orbit
			asteroid_desc.setFloat(strOrbDays, randomf(3.f, 6.f));
		}
		
		Object@ asteroid = sys.makeOddity(asteroid_desc);

		if (i == 0)
			asteroid.setGlobalVisibility(true);
		
		State@ ore = asteroid.getState(strOre);
		ore.max = oreVal;
		ore.val = oreVal;
		
		State@ hp = asteroid.getState(strDmg);
		hp.val = 0;
		hp.max = oreVal;
	}
	return sys;
}
// }}}
// {{{ Minor Globular Cluster System, formerly Supernova System
System@ RS_makeSupernova(Galaxy@ glx, vector pos) {
	System@ sys;
	{
		sysDesc.Position = pos;
		
		sysDesc.AutoStar = false;
		
		@sys = @glx.createSystem(sysDesc);
	}
	
	
	float sizeFactor = 2.5f;	
	int gcCount = rand(4, 40) + rand(4, 40);
	orbDesc.Radius = (RS_orbitRadiusFactor * (sqrt(gcCount * RS_orbitRadiusFactor)))/3.f;
	float rad = orbDesc.Radius/2.f;
	for(int gc = 0; gc < gcCount; ++gc) {

		RS_makeGlobularCluster(sys, pos, gc, gcCount, sizeFactor, rad);
	}
	float glowSize = rad*25.f;
	Color glowCol(255,244,229,208);
	createEnvironmentGlobular(glowSize, pos, glowCol);
	return sys;
}
// }}}
// {{{ Quasar System
// The Quasar is special in that it outputs a float with the minimum
// distance from the quasar that systems should be generated at
float RS_makeQuasar(Galaxy@ glx, vector pos, float sizeFactor) {
	System@ sys;
	{
		sysDesc.Position = pos;
		sysDesc.AutoStar = false;
		
		@sys = @glx.createSystem(sysDesc);
		
		sys.addTag("CentralGlobular");
	}
	
	
	
	int gcCount = 250;//rand(100, 200) + rand(100, 200);	
	// Set Globular Cluster orbit parameters

	orbDesc.Radius = (((sizeFactor * RS_starSizeFactor)^4)*gcCount*3.f)*(sqrt(sqrt(sqrt(gcCount*3.f)))); //(change sizefactor calculation later)
	
	for(int gc = 0; gc < gcCount; ++gc) {
		float rad = orbDesc.Radius;
		//RS_makeGlobularCluster(sys, pos, gc, gcCount, sizeFactor, rad);
	}
			
	return orbDesc.Radius * 1.2f;
}
const float fadeOutFactor = 0.1f;	
// {{{ Globular Cluster Generation
Star@ RS_makeGlobularCluster(System@ sys, vector pos, uint gcNum, uint gcCount, float sizeFactor, float rad) {
// Make globular cluster at galactic center.
	return RS_makeGlobularStar(sys, pos, gcNum, gcCount, sizeFactor, rad);
}
// }}}

// {{{ Globular Cluster Stars
Star@ RS_makeGlobularStar(System@ sys, vector pos, uint gcNum, uint gcCount, float sizeFactor, float rad) {

	orbDesc.setCenter(null);
	orbDesc.PosInYear = randomf(-0.2f, -2.f);
	orbDesc.IsStatic = true;
	
	Star@ gc = sys.makeStar(starDesc);
		
	orbDesc.PosInYear = 0.f;

	float randomOffsetX = ((randomf(-1.f,1.f)) * (randomf((RS_orbitRadiusFactor/3.f), (rad*2.f))));
	float randomOffsetY = ((randomf(-1.f,1.f)) * (randomf((RS_orbitRadiusFactor/3.f), (rad*2.f))));
	float randomOffsetZ = ((randomf(-1.f,1.f)) * (randomf((RS_orbitRadiusFactor/3.f), (rad*2.f))));
	pos += vector(randomOffsetX, randomOffsetY, randomOffsetZ);	
	float specialB;
	float spriteSizeGlow;
	float number;
	const float diceroll = randomf(0.f,100.f);
	if(diceroll <= 10.f){
		starDesc.Temperature = randomf(5200, 6000);
	// G-Class(Yellow Spectrum) Main Sequence Yellow Dwarf 
		if(starDesc.Temperature < 5280.f){
			starDesc.StarColor = Color(0xffe7c41b);
			number = 9.f;
			}
		else if(starDesc.Temperature < 5360.f){
			starDesc.StarColor = Color(0xffe8c91e);
			number = 8.f;
			}
		else if(starDesc.Temperature < 5440.f){
			starDesc.StarColor = Color(0xffe8cc24);
			number = 7.f;
			}
		else if(starDesc.Temperature < 5520.f){
			starDesc.StarColor = Color(0xffe8ce2c);
			number = 5.f;
			}
		else if(starDesc.Temperature < 5600.f){
			starDesc.StarColor = Color(0xffead132);
			number = 5.f;
			}
		else if(starDesc.Temperature < 5680.f){
			starDesc.StarColor = Color(0xffecd33a);
			number = 4.f;
			}
		else if(starDesc.Temperature < 5760.f){
			starDesc.StarColor = Color(0xffecd744);
			number = 3.f;
			}
		else if(starDesc.Temperature < 5840.f){
			starDesc.StarColor = Color(0xffecda51);
			number = 2.f;
			}
		else if(starDesc.Temperature < 5920.f){
			starDesc.StarColor = Color(0xffeedc58);
			number = 1.f;
			}
		else if(starDesc.Temperature <= 6000.f){
			starDesc.StarColor = Color(0xffefdd62);
			number = 0.f;
			}
		starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(0.8f, 1.2f); //Main Sequence
//		sys.addTag("GMSQ"+number); //yellow
		specialB =2.f;
		starDesc.Brightness = (sqrt(sqrt(Pi*(starDesc.Radius^2)*starDesc.Temperature)))*specialB;
		spriteSizeGlow = ((Pi*(starDesc.Radius^2)*starDesc.Temperature))/starDesc.Brightness;				
		}
//10
	else if(diceroll <= 85.f){
	starDesc.Temperature = randomf(6000, 7600);
	//	F-Class(Yellow White Spectrum) Main Sequence Yellow-White Dwarf
		if(starDesc.Temperature < 6160.f){
			starDesc.StarColor = Color(0xfff0df6d);
			number = 9.f;
			}
		else if(starDesc.Temperature < 6320.f){
			starDesc.StarColor = Color(0xfff1df7b);
			number = 8.f;
			}
		else if(starDesc.Temperature < 6480.f){
			starDesc.StarColor = Color(0xfff1e288);
			number = 7.f;
			}
		else if(starDesc.Temperature < 6640.f){
			starDesc.StarColor = Color(0xfff2e390);
			number = 6.f;
			}
		else if(starDesc.Temperature < 6800.f){
			starDesc.StarColor = Color(0xfff2e49c);
			number = 5.f;
			}
		else if(starDesc.Temperature < 6960.f){
			starDesc.StarColor = Color(0xfff2e3a7);
			number = 4.f;
			}
		else if(starDesc.Temperature < 7120.f){
			starDesc.StarColor = Color(0xfff1e4b2);
			number = 3.f;
			}
		else if(starDesc.Temperature < 7280.f){
			starDesc.StarColor = Color(0xfff3e5bb);
			number = 2.f;
			}
		else if(starDesc.Temperature < 7440.f){
			starDesc.StarColor = Color(0xfff4e6c6);
			number = 1.f;
			}
		else if(starDesc.Temperature <= 7600.f){
			starDesc.StarColor = Color(0xfff4e5d0);
			number = 0.f;
			}
		starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(0.8f, 1.2f); //Main Sequence
//		sys.addTag("FMSQ"+number); //white yellow
		specialB =2.f;
		starDesc.Brightness = (sqrt(sqrt(Pi*(starDesc.Radius^2)*starDesc.Temperature)))*specialB;
		spriteSizeGlow = ((Pi*(starDesc.Radius^2)*starDesc.Temperature))/starDesc.Brightness;
		}
//90
	else if(diceroll <= 88.f){
	// M-Class(Red Spectrum) Red Gaint
		starDesc.Temperature = randomf(2200, 3900);//2200//2370
		if(starDesc.Temperature < 2800.f){
//			starDesc.StarColor = Color(0xffbb2c0d);
//			number = 9.f;
//			}
//		else if(starDesc.Temperature < 2540.f){
//			starDesc.StarColor = Color(0xffbb2f14);
//			number = 8.f;
//			}
//		else if(starDesc.Temperature < 2710.f){
//			starDesc.StarColor = Color(0xffbc3716);
//			number = 7.f;
//			}
//		else if(starDesc.Temperature < 2880.f){
//			starDesc.StarColor = Color(0xffbe3b16);
//			number = 6.f;
//			}
//		else if(starDesc.Temperature < 3050.f){
			starDesc.StarColor = Color(0xffc24317);
			number = 4.f;
			}
		else if(starDesc.Temperature < 3220.f){
			starDesc.StarColor = Color(0xffc44917);
			number = 5.f;
			}
		else if(starDesc.Temperature < 3390.f){
			starDesc.StarColor = Color(0xffc75217);
			number = 3.f;
			}
		else if(starDesc.Temperature < 3560.f){
			starDesc.StarColor = Color(0xffc85b18);
			number = 2.f;
			}
		else if(starDesc.Temperature < 3730.f){
			starDesc.StarColor = Color(0xffc96318);
			number = 1.f;
			}
		else if(starDesc.Temperature <= 3900.f){
			starDesc.StarColor = Color(0xffcd6c19);
			number = 0.f;
			}
		starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(12.f, 18.f); //giant
//		sys.addTag("MGiant"+number); //red
		specialB =2.f;
		starDesc.Brightness = (sqrt(sqrt(Pi*(starDesc.Radius^2)*starDesc.Temperature)))*specialB;
		spriteSizeGlow = ((Pi*(starDesc.Radius^2)*starDesc.Temperature))/starDesc.Brightness;
		}
//93
	else if(diceroll <= 100.f){
	starDesc.Temperature = randomf(30000, 52000);
	// A-Class(Blue Spectrum) Blue Straggler, binary main sequence hot merger
		if(starDesc.Temperature < 32200.f)
			starDesc.StarColor = Color(0xff6376e3);
		else if(starDesc.Temperature < 34400.f)
			starDesc.StarColor = Color(0xffc6fe04);
		else if(starDesc.Temperature < 36600.f)
			starDesc.StarColor = Color(0xff5566de);
		else if(starDesc.Temperature < 38800.f)
			starDesc.StarColor = Color(0xff5262dd);
		else if(starDesc.Temperature < 41000.f)
			starDesc.StarColor = Color(0xff515ed9);
		else if(starDesc.Temperature < 43200.f)
			starDesc.StarColor = Color(0xff535cd8);
		else if(starDesc.Temperature < 45400.f)
			starDesc.StarColor = Color(0xff585fd7);
		else if(starDesc.Temperature < 47600.f)
			starDesc.StarColor = Color(0xff5e61d7);
		else if(starDesc.Temperature < 49800.f)
			starDesc.StarColor = Color(0xff6564d7);
		else if(starDesc.Temperature <= 52000.f)
			starDesc.StarColor = Color(0xff6d67d6);
		starDesc.Radius = ((sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(0.8f, 1.2f))*1.4f; // special blue cluster only star
//		sys.addTag("BSS"); //Bright Blue
		specialB =2.f;
		starDesc.Brightness = (sqrt(sqrt(Pi*(starDesc.Radius^2)*starDesc.Temperature)))*specialB;
//		spriteSizeGlow = ((Pi*(starDesc.Radius^2)*starDesc.Temperature))/starDesc.Brightness;		
		spriteSizeGlow = sqrt((Pi*(starDesc.Radius^2)*starDesc.Temperature)); //special calculation!!
			}
		float spriteSize = starDesc.Radius* 55.f;
		float spriteCloseGlow = starDesc.Radius* 10.f;
//		vector pos = orbDesc.Offset = pos;
		Color StarColor = starDesc.StarColor;
	
		orbDesc.Offset += pos;
			createEnvironmentStarX(spriteSize, pos, StarColor);
			createEnvironmentStarGlow(spriteSizeGlow, pos, StarColor);
			createEnvironmentCloseGlow(spriteCloseGlow, pos, StarColor);
//		pos -= vector(randomOffsetX, randomOffsetY, randomOffsetZ);		
		starDesc.setOrbit(orbDesc);
		orbDesc.Offset -= pos;
//		starDesc.setOrbit(orbDesc); //the 3D stars are not generated on spot, and zoom on the cluster is not possible, so no reason to generate star right now.
	return gc;
}
// }}}


// {{{ Systems with main sequence dwarf stars, cold sub-dwars OR the larger sub-gaints AND a potential tiny white dwarf OR brown dwarf binary companion.
System@ RS_makeUnstableStar(Galaxy@ glx, vector pos) {
////////////////////////////////////////////////////////////
// Not used, didn't clean it of notes experimental notes. //
////////////////////////////////////////////////////////////
	// Reset orbit parameters
	orbDesc.Offset = vector(0, 0, 0);
	orbDesc.setCenter(null);
	orbDesc.PosInYear = randomf(-0.2f, -2.f);
	orbDesc.IsStatic = true;

	// Create the system
	sysDesc.Position = pos;
	sysDesc.AutoStar = false;

	System @sys = @glx.createSystem(sysDesc);
	// Create the star


	float diceroll = randomf(0.f,3.f);
				if(diceroll <= 2.f){
	// M-Class(Red Spectrum) Main Sequence Red Dwarf
		starDesc.Temperature = randomf(2200, 3900);
		if(starDesc.Temperature < 2370.f)
			starDesc.StarColor = Color(0xffbb2c0d);
		else if(starDesc.Temperature < 2540.f)
			starDesc.StarColor = Color(0xffbb2f14);
		else if(starDesc.Temperature < 2710.f)
			starDesc.StarColor = Color(0xffbc3716);
		else if(starDesc.Temperature < 2880.f)
			starDesc.StarColor = Color(0xffbe3b16);
		else if(starDesc.Temperature < 3050.f)
			starDesc.StarColor = Color(0xffc24317);
		else if(starDesc.Temperature < 3220.f)
			starDesc.StarColor = Color(0xffc44917);
		else if(starDesc.Temperature < 3390.f)
			starDesc.StarColor = Color(0xffc75217);
		else if(starDesc.Temperature < 3560.f)
			starDesc.StarColor = Color(0xffc85b18);
		else if(starDesc.Temperature < 3730.f)
			starDesc.StarColor = Color(0xffc96318);
		else if(starDesc.Temperature <= 3900.f)
			starDesc.StarColor = Color(0xffcd6c19);
				float sizeroll = randomf(0.f,1.f);
				if(sizeroll <= 0.7f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(18.f, 24.f); //bright giant
				}
				else if(sizeroll <= 0.85f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(24.f, 30.f); //supergiant
				}
				else if(sizeroll <= 0.95f){
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(30.f, 36.f); //hypergiant
				}
			else{
				starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(12.f, 18.f); //giant
				}
			starDesc.Radius = (sqrt(sqrt(sqrt(starDesc.Temperature)))) * RS_starSizeFactor * randomf(6.f, 12.f);
		// max planet radius is 80, max star radius at 3900 temp is 281, min at 2200 temp is 211, main sequence earth sun would be 
		starDesc.Brightness = sqrt(sqrt(Pi*(starDesc.Radius^2)*starDesc.Temperature));


//	vector pos = orbDesc.Offset;

		}
			else if(diceroll <= 3.f){
	starDesc.Temperature = randomf(30000, 52000);
	// Exotic Blue Spectrum - Blue Straggler, binary main sequence merger
	
	if(starDesc.Temperature < 32200.f)
		starDesc.StarColor = Color(0xff6376e3);
	else if(starDesc.Temperature < 34400.f)
		starDesc.StarColor = Color(0xffc6fe04);
	else if(starDesc.Temperature < 36600.f)
		starDesc.StarColor = Color(0xff5566de);
	else if(starDesc.Temperature < 38800.f)
		starDesc.StarColor = Color(0xff5262dd);
	else if(starDesc.Temperature < 41000.f)
		starDesc.StarColor = Color(0xff515ed9);
	else if(starDesc.Temperature < 43200.f)
		starDesc.StarColor = Color(0xff535cd8);
	else if(starDesc.Temperature < 45400.f)
		starDesc.StarColor = Color(0xff585fd7);
	else if(starDesc.Temperature < 47600.f)
		starDesc.StarColor = Color(0xff5e61d7);
	else if(starDesc.Temperature < 49800.f)
		starDesc.StarColor = Color(0xff6564d7);
	else if(starDesc.Temperature <= 52000.f)
		starDesc.StarColor = Color(0xff6d67d6);
			// main sequence *1.6.
			starDesc.Radius = (sqrt(sqrt(starDesc.Temperature)) * RS_starSizeFactor * randomf(4.f, 8.f));
	// max planet radius is 80, max star radius at 52000 temp is 1026, min at 30000 temp is 779, main sequence earth sun would be 
	starDesc.Brightness = sqrt(sqrt(Pi*(starDesc.Radius^2)*starDesc.Temperature));	
	

	}
		
	starDesc.setOrbit(orbDesc);
	Color StarColor = starDesc.StarColor;
	float spriteSizeGlow = ((Pi*(starDesc.Radius^2)*starDesc.Temperature))/starDesc.Brightness;
float spriteSize = starDesc.Radius *80.f;
	float starRad = starDesc.Radius;
	Star@ st = sys.makeStar(starDesc);
	
	Effect starEffect("SelfHealing");
	starEffect.set("Rate", 100000000.f);	
	st.toObject().addTimedEffect(starEffect, pow(10, 35), 0.f, st.toObject(), null, null, TEF_None);		

	
	State@ h3 = st.toObject().getState(strH3);
	h3.max = starDesc.Temperature * randomf(50000,100000);
	h3.val = h3.max * (0.5f + (randomf(0.5f)));	
	
	// Set planet orbit parameters

	orbDesc.MassRadius = starDesc.Radius;
	orbDesc.Mass = starDesc.Radius * RS_starMassFactor * RS_starSizeFactor;
	orbDesc.Radius = RS_orbitRadiusFactor + starDesc.Radius;
	orbDesc.IsStatic = false;
	int pCount = rand(0, 1) + rand(0, 1) + rand(0, 1);
	
	orbDesc.Radius += randomf(1.3f, 2.1f) * RS_orbitRadiusFactor;
	
	// Add oddities to system
	if(RS_makeOddities) {	
		int comets = 1;
		while (randomf(1.f) < (0.60f / comets)) {
			RS_makeRandomComet(sys);
			++comets;
		}
		
		int belts = 0;
		while (randomf(1.f) < 1.f / (belts + 2.f) && belts < pCount) {
			RS_makeRandomAsteroidNew(sys, rand(250,600), starRad);
			++belts;
		}
	}
	createEnvironmentStarX(spriteSize, pos, StarColor);
	createEnvironmentStarGlow(spriteSizeGlow, pos, StarColor);
	
	return sys;
}
// }}}


		string@ starX = "starX", starGlowSprite = "galactic_glow2", starCloseGlowSprite = "galactic_eye";
void createEnvironmentStarX(float spriteSize, vector pos, Color StarColor){
createGalaxyGasSprite(starX, spriteSize, pos, StarColor, spriteSize * fadeOutFactor);	
}

void createEnvironmentStarGlow(float spriteSizeGlow, vector pos, Color StarColor){
createGalaxyGasSprite(starGlowSprite, spriteSizeGlow, pos, StarColor, spriteSizeGlow * fadeOutFactor);	

}

void createEnvironmentCloseGlow(float spriteSizeCloseGlow, vector pos, Color StarColor){
createGalaxyGasSprite(starCloseGlowSprite, spriteSizeCloseGlow, pos, StarColor, spriteSizeCloseGlow * fadeOutFactor);	

}
/////////////////////// used for small clusters, that aren't currently generated ///////////////////////
	string@ glowSprite = "galactic_glow";	
	float fadeGlow = 0.f;
void createEnvironmentGlobular(float glowSize, vector pos, Color glowCol){
createGalaxyGasSprite(glowSprite, glowSize, pos, glowCol, glowSize * fadeGlow);
}
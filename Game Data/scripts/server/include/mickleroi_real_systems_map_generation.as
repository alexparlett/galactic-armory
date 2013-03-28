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
float RS_minPlanetRadius = 10, RS_maxPlanetRadius = 40;
float RS_orbitRadiusFactor = 400.f;
float RS_tempFalloffRadius  = RS_orbitRadiusFactor * 6.f;
uint RS_maxStructSpaceHome = 30;
uint RS_maxStructSpaceRock = 30;
uint RS_maxNumberMoonsGas = 40;
uint RS_maxNumberMoonsOther = 5;
float RS_starSizeFactor = 4.5f;
const float RS_starMassFactor = 1.f / 19800.f;
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
		bool livable = sys.toObject().getStat(space, strLivable) > 0.1f;
		
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
	plDesc.PlanetRadius = randomf(9.f,11.f);
	plDesc.RandomConditions = false;
	string@ name = "";

	orbDesc.Eccentricity = 1.f;
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
		pRad = randomf(RS_minPlanetRadius, RS_maxPlanetRadius);
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
	float pRad = randomf(RS_minPlanetRadius, RS_maxPlanetRadius), pVol = pRad * pRad * pRad * 4.189f;
	plDesc.PlanetRadius = pRad;
	plDesc.RandomConditions = false;

	// Calculate planetary temperature
	if (RS_tempFalloff) {
		int type = -1;
		float temp = starDesc.Temperature / sqr(orbDesc.Radius / RS_tempFalloffRadius);
		float tp = randomf(1.f);

		if (tp < 0.15f)
			type = getRandomType(GasTypes);
		else if (temp > 30000.f)
			type = getRandomType(LavaTypes);
		else if (temp > 17000.f)
			type = getRandomType(WarmTypes);
		else if (temp > 5000.f)
			type = getRandomType(NormalTypes);
		else
			type = getRandomType(ColdTypes);

		plDesc.setPlanetType(type);
	}
	
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
		if(sysType >= 97)
			return RS_makeSupernova(Glx, position);
		else if (sysType >= 85)
			return RS_makeBinarySystem(Glx, position);
		else if (sysType >= 75 && RS_makeOddities)
			return RS_makeAsteroidBelt(Glx, position);
		else if (sysType >= 70) 
			return makeUnstableStar(Glx, position);
		else if (sysType >= 65) 
			return makeNeutronStar(Glx, position);
		else
			return RS_makeStandardSystem(Glx, position);
	}
	else {
		// Guaranteed live systems
		if (sysType >= 90)
			return RS_makeBinarySystem(Glx, position);
		else
			return RS_makeStandardSystem(Glx, position);
	}
}

// {{{ Standard System
System@ RS_makeStandardSystem(Galaxy@ glx, vector pos) {
	// Reset orbit parameters
	orbDesc.Offset = vector(0, 0, 0);
	orbDesc.setCenter(null);
	orbDesc.PosInYear = -1.f;
	orbDesc.IsStatic = true;

	// Create the system
	sysDesc.Position = pos;
	sysDesc.AutoStar = false;

	System @sys = @glx.createSystem(sysDesc);

	// Create the star
	starDesc.Temperature = randomf(2000,40000);
	starDesc.Radius = randomf(30.f + (starDesc.Temperature / 1000.f),60.f + (starDesc.Temperature / 600.f)) * RS_starSizeFactor;
	starDesc.Brightness = 5;
	starDesc.setOrbit(orbDesc);
	
	Star@ st = sys.makeStar(starDesc);

	Effect starEffect("SelfHealing");
	starEffect.set("Rate", 100000000.f);	
	st.toObject().addTimedEffect(starEffect, pow(10, 35), 0.f, st.toObject(), null, null, TEF_None);		

	State@ h3 = st.toObject().getState(strH3);
	h3.max = starDesc.Temperature * randomf(50000,100000);
	h3.val = h3.max * (0.5f + (randomf(0.5f)));	
	
	// Set planet orbit parameters
	orbDesc.MassRadius = starDesc.Radius;
	orbDesc.Mass = starDesc.Radius * RS_starMassFactor;
	orbDesc.Radius = RS_orbitRadiusFactor;
	orbDesc.IsStatic = false;
	
	int pCount = rand(1, 5) + rand(1, 7);
	
	for(int p = 0; p < pCount; ++p) {
		orbDesc.Radius += randomf(1.3f, 2.1f) * RS_orbitRadiusFactor;
		orbDesc.Eccentricity = randomf(0.5f, 1.5f);

		RS_makeRandomPlanet(sys, p, pCount);
	}
	
	if(!RS_balancedStart || (pCount > 2 && pCount < 5))
		sys.toObject().setStat(getEmpireByID(-1), strLivable, 1.f);
	
	// Add oddities to system
	if(RS_makeOddities) {	
		int comets = 1;
		while (randomf(1.f) < (0.60f / comets)) {
			RS_makeRandomComet(sys);
			++comets;
		}
		
		int belts = 0;
		while (randomf(1.f) < 1.f / (belts + 2.f) && belts < pCount) {
			RS_makeRandomAsteroid(sys, rand(250,600));
			++belts;
		}
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

	// Add oddities to system
	if(RS_makeOddities) {	
		int comets = 1;
		while (randomf(1.f) < (0.2f / comets)) {
			RS_makeRandomComet(sys);
			++comets;
		}
		
		int belts = 0;
		while (randomf(1.f) < 1.f / (belts + 2.f) && belts < pCount) {
			RS_makeRandomAsteroid(sys, rand(250,600));
			++belts;
		}
	}

	return sys;
}
// }}}
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
// {{{ Supernova System
System@ RS_makeSupernova(Galaxy@ glx, vector pos) {
	System@ sys;
	{
		sysDesc.Position = pos;
		
		sysDesc.AutoStar = false;
		
		@sys = @glx.createSystem(sysDesc);
	}
	
	{
		starDesc.Temperature = randomf(4000,10000);
		starDesc.Radius = randomf(180,270) * RS_starSizeFactor;
		starDesc.Brightness = 7;
		starDesc.clearOrbit();
		
		Star@ st = sys.makeStar(starDesc);

		Effect starEffect("SelfHealing");
		starEffect.set("Rate", 100000000.f);		
		st.toObject().addTimedEffect(starEffect, pow(10, 35), 0.f, st.toObject(), null, null, TEF_None);		
		
		Object@ obj = st;
		
		State@ h3 = obj.getState(strH3);
		h3.max = starDesc.Temperature * randomf(100000,200000);
		h3.val = h3.max * (0.5f + (randomf(0.5f)));
	}

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
		
		sys.addTag("Quasar");
	}
	
	{
		starDesc.Temperature = randomf(60000,100000);
		starDesc.Radius = randomf(400,450) * sizeFactor * RS_starSizeFactor;
		starDesc.Brightness = 16;
		starDesc.clearOrbit();
		
		Star@ quasar = sys.makeStar(starDesc);

		Effect starEffect("SelfHealing");
		starEffect.set("Rate", 100000000.f);		
		quasar.toObject().addTimedEffect(starEffect, pow(10, 35), 0.f, quasar.toObject(), null, null, TEF_None);	
		
		Effect quasarExplosion("Quasar");
		quasar.toObject().addTimedEffect(quasarExplosion, pow(10, 35), 0.f,
				quasar.toObject(), null, null, TEF_None);
		
		Object@ obj = quasar;
		
		State@ h3 = obj.getState(strH3);
		h3.max = starDesc.Temperature * randomf(100000,200000);
		h3.val = h3.max * (0.5f + (randomf(0.5f)));
		
		return starDesc.Radius * 3.f;
	}
}
// }}}


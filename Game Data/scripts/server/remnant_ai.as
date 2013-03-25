#include "/include/empire_lib.as"
#include "/include/map_util.as"

bool initialized = false;
const bool logging = false;

const float OneHour = 60.f * 60.f;
const int MaxSeedPerTick = 5;
const int MaxSystemSeedPerScan = 5;

const float SeedPerPlanet = 9.f;
const float SeedPerPlanetAi = 20.f;
const float DefensePerPlanet = 20.f;
const float FirstSpawnIncrease = OneHour;
const float SpawnIncreaseInterval = OneHour;

const float BaseAttackSize = 15.f;
const float FirstWaveIncrease = OneHour;
const float WaveIncreaseInterval = OneHour;

const double BaseResearchRate = 1000.0;
const float ResearchLevelThreshold = 0.5f;
const float ResearchCheckInterval = 2.f * 60.f;
const float ResearchRateCheckInterval = 10.f * 60.f;

const float DefensiveSpawnInterval = 10.f * 60.f;
const float SystemCheckInterval = 10.f;
const float FirstAttackSpawnInterval = 30.f * 60.f;
const float AttackSpawnInterval = 15.f * 60.f;
const float RegroupInterval = 1.f * 60.f;
const float FleetBuildTimeout = 5.f;

const float StrengthPickRandomness = 0.3f;
const float TimeVarianceRandomness = 0.25f;

const float MetalGenPerSecond = 10000.f;

const float ShipRingRadius = 300.f;
const float ShipRingRadiusSQ = ShipRingRadius * ShipRingRadius;
const uint PicketShipsCount = 20;

const string@ str_RemnantSys = "rSys";
const string@ str_Victory = "Victory";
const string@ str_Metals = "Metals", str_Elects = "Electronics", str_AdvParts = "AdvParts", str_Fuel = "Fuel", str_Ammo = "Ammo";

string[] offensiveTechs =
{
	"Missiles", "Nanotech", "EnergyPhysics", "ProjWeapons",
	"ParticlePhysics", "BeamWeapons", "WarpPhysics", "Gravitics",
	"Sensors", "Computers", "MegaConstruction"
};

string[] defensiveTechs =
{
	"Materials", "Armor", "Shields", "Engines",
	"ShipConstruction", "ShipSystems", "Stealth"
};

// "Metallurgy", "Science", "Cargo", "Economics", "Chemistry"

void init_remnant_ai() {
	if(!initialized) {
		loadDefaults(false);
		initialized = true;
	}
}

void prep_remnant_ai_defaults(Empire@ emp) {
	// Design init is done by a task,
	// it needs to cheat some unlocks first
}

interface Task {
	bool update(Empire@ emp, RemnantAIData@ data, float tick);
};

float TargetSearch(SysSearchSettings& search, const SysStats& stats)
{
	uint empCount = search.empireCount;
	float enemyStrength = 0.f;
	float planets = 0.f;
	float weight = 0.f;

	for(uint i = 0; i < empCount; ++i)
	{
		Empire@ other = search.getEmpire(i);

		enemyStrength += stats.getStat(other, str_strength);
		planets += stats.getStat(other, str_planets);
	}

	if (planets == 0)
		weight = 0.f;
	else if (enemyStrength < 0.1f)
		weight = vary(planets, StrengthPickRandomness); 
	else
		weight = vary(1.f / enemyStrength * planets, StrengthPickRandomness);
	
	return weight;
}

float SourceSearch(SysSearchSettings& search, const SysStats& stats)
{
	Empire@ us = search.getEmpire(0);

	float weight = 0.f;

	if ( stats.getStat( us, str_RemnantSys ) > 0.5f )
		weight = randomf( 0.5f, 1.f );
		
	return weight;
}

class PrepareWave : Task
{
	SysSearchSettings search;
	float size;
	
	System@ target;
	SystemManager@ sourceManager;
	float buildTimeout;
	
	PrepareWave( RemnantAIData@ data, float str, Empire@ target )
	{
		if ( data.log )
		print("Wave start " + f_to_s( str ) + " at " + target.getName());
		
		size = str;
		
		search = data.sss_target;
		
		search.addEmpire( target );
		search.findBestSystem();
		
		@target = null;
		@sourceManager = null;
		buildTimeout = 0.f;
	}
	
	bool update(Empire@ emp, RemnantAIData@ data, float tick)
	{
		if ( sourceManager !is null )
		{
			buildTimeout -= tick;
			if ( buildTimeout < 0.f )
			{
				if ( sourceManager.BuildFleet( target, size, 1 ) )
					return true;
				else
				{
					buildTimeout = FleetBuildTimeout;
					if ( data.log )
					print("Build fleet at " + sourceManager.system.toObject().getName() + " delayed" );
				}
			}
		}
		else if ( search.searchFinished == true )
		{
			if ( target is null )
			{
				@target = search.getBestSystem();
				if ( target is null )
					return true;
				
				if ( data.log )
				print("Found target = " + target.toObject().getName() );
				
				search = data.sss_source;
				search.setSearchPos( target.toObject().getPosition() );
				search.findBestSystem();
			}
			else
			{
				System@ source = search.getBestSystem();

				if ( source is null )
				{
					return true;
				}
				
				if ( data.log )
				print("Found source = " + source.toObject().getName() );
				
				uint count = data.systems.length();
				for ( uint i = 0 ; i < count; i++ )
				{
					if ( data.systems[i].system is source )
					{
						@sourceManager = data.systems[i];
					}
				}
				
				if ( sourceManager is null )
				{
					@sourceManager = data.systems[rand(count - 1)];
				}
			}
		}
		
		return false;
	}
};

class SearchSetup : Task
{
	SearchSetup()
	{
	}
	
	bool update(Empire@ emp, RemnantAIData@ data, float tick)
	{
		data.sss_target.clearEmpires();
		data.sss_source.clearEmpires();
		data.sss_source.addEmpire( emp );
		
		return true;
	}
};

// {{{ RemnantAIData: Global remnant manager.
class SetupTask : Task
{
	int stage;
	bool warsDone;

	SetupTask()
	{
		stage = 0;
		warsDone = false;
	}

	bool update(Empire@ emp, RemnantAIData@ data, float tick) 
	{
		if ( !warsDone && emp.isAI() ) // isAI check for design making support if started as player
		{
			warsDone = true;
			// Declare war on everybody
			uint cnt = getEmpireCount();
			for (uint i = 0; i < cnt; ++i)
			{
				Empire@ other = getEmpire(i);

				if (other.ID > 0)
					declareWar(emp, other);
			}
		}
		
		if (stage == 0)
		{
			if ( !data.aiActive && emp.isAI() ) // isAI check for design making support if started as player
				emp.setStat(str_Victory, -1.f);
			else
				emp.setStat(str_Victory, 0.f);

			ResearchWeb web;
			web.prepare(emp);

			// Prepare technologies that we will level
			for ( uint i = 0; i < offensiveTechs.length(); i++ )
			{
				web.markAsVisible(offensiveTechs[i]);
				levelTo(web, offensiveTechs[i], 3);
			}

			for ( uint i = 0; i < defensiveTechs.length(); i++ )
			{
				web.markAsVisible(defensiveTechs[i]);
				levelTo(web, defensiveTechs[i], 5);
			}

			// for toys (mostly mass reduction and efficiency of few non-weapon systems)
			levelTo(web, "Science", 20);
			levelTo(web, "Metallurgy", 20);
			levelTo(web, "Economics", 20);
			levelTo(web, "Chemistry", 20);
			levelTo(web, "Cargo", 20);

			web.prepare(null);
			
			// Add remnant technology trait
			emp.addTrait("remnants");

			if ( data.aiActive )
				data.addTask( ResearchTask() );

			stage = 1;
			return false;
		}

		if (stage == 1) {
		
			data.GenerateDesigns( emp );
			
			// design making support if started as player
			if ( !emp.isAI() )
				return true;
			
			stage = 2;
			return false;
		}
		
		if (stage == 2) {
			// Seed the galaxy randomly with remnants
			if (!data.seededGalaxy) {
				data.seedGalaxy(emp);
				return false;
			}
			
			if ( data.log )
			print("Seed complete");
			stage = 3;
			return false;
		}
		
		if ( stage == 3 )
		{
			
			uint designCount = defaultDesigns.length();
			for(uint i = 0; i < designCount; ++i) {
				ShipDesign@ design = defaultDesigns[i];

				if(design.forRemnants && (design.goalID == GID_SpecialDefense
							|| design.goalID == GID_Invalid)) {
					if (design.generateForEmpire(emp)) {
						uint n = data.specialDesigns.length();
						data.specialDesigns.resize(n+1);
						@data.specialDesigns[n] = @design;

						const HullLayout@ lay = emp.getShipLayout(design.className);
						if (lay !is null)
							lay.updateThreshold = 0.f;
					}
				}
			}
			
			stage = 4;
			return false;
		}

		if ( stage == 4 )
		{
			data.seedSpecialSystems( emp );
			return true;
		}
		
		return true;
	}
};

class ResearchTask : Task
{
	ResearchTask()
	{
	}
	
	bool update(Empire@ emp, RemnantAIData@ data, float tick)
	{
		ResearchWeb web;
		web.prepare(emp);
		
		const string@ techName = pickTechPriority( web, defensiveTechs, offensiveTechs );
		
		const WebItem@ tech = web.getItem(techName);
		
		if ( tech !is null )
		{
			web.setActiveTech(tech.descriptor);
		}

//		print("Anger = " + f_to_s( data.angerLevel ) + " lev = " + f_to_s( scienceLvl ) + " perLev = " + f_to_s( data.sciencePerLevel ));
		
		double rate = data.baseResearchRate * data.angerLevel * data.researchFactor;
		
		if ( data.log )
		print( (( tech !is null ) ? ( "New tech " + techName ) : "Tech" ) + " with rate = " + f_to_s( rate ));
		
		web.setResearchRate( rate );
	
		data.UpdateTechMod( web );
		
		web.prepare(null);
		
		data.nextResearchCheck = ResearchCheckInterval;
		
		return true;
	}

	string@ pickTechPriority( ResearchWeb& web, string[]& techs1, string[]& techs2 )
	{
		string@ ret = null;
		uint len1 = techs1.length();
		uint len2 = techs2.length();
		
		uint num1 = 0;
		int least1 = -1;

		uint num2 = 0;
		int least2 = -1;

		for (uint i = 0; i < len1; ++i)
		{
			const WebItem@ it = web.getItem(techs1[i]);

			if ( @it != null )
			{
				if ( least1 == -1 || it.get_level() < least1 )
				{
					least1 = it.get_level();
					num1 = i;
				}
			}
		}

		for (uint i = 0; i < len2; ++i)
		{
			const WebItem@ it = web.getItem(techs2[i]);

			if ( @it != null )
			{
				if ( least2 == -1 || it.get_level() < least2 )
				{
					least2 = it.get_level();
					num2 = i;
				}
			}
		}
		
		if ( least1 > 1 )
			least1 -= 2;
		
		if ( least1 != -1 && least2 != -1 )
		{
			if ( least1 <= least2 )
				@ret = techs1[num1];
			else
				@ret = techs2[num2];
		}
		
		return ret;
	}

};

class ResearchRateTask : Task
{
	float empireTech;
	float empireResearchRate;
	uint currEmpire;
	string@ techList;

	ResearchRateTask()
	{
		empireTech = 0.f;
		empireResearchRate = 0.f;
		currEmpire = 0;
		@techList = "";
	}

	bool update(Empire@ emp, RemnantAIData@ data, float tick)
	{
		data.nextResearchRateCheck = ResearchRateCheckInterval;

		if ( currEmpire < getEmpireCount() )
		{
			Empire@ curr = getEmpire( currEmpire );
			currEmpire++;
		
			if ( curr.ID > 0 )
			{
				ResearchWeb web;
				web.prepare(curr);
				
				float techs = data.CalcTechLevels( web );
				float resRate = web.getResearchRate();
				
				if ( data.log )
				techList += curr.getName() + ":" + standardize( resRate ) + ",";

				if ( techs > empireTech )
					empireTech = techs;

				if ( resRate > empireResearchRate )
					empireResearchRate = resRate;

				web.prepare(null);
			}
			return false;
		}
		
		if ( data.log )
		print( techList );

		float techDiff = empireTech - data.currTechMod * 10.f;
		float threshold = ResearchLevelThreshold * ( defensiveTechs.length() + offensiveTechs.length() );
		
		if ( data.log )
		print("Research = " + standardize( empireResearchRate ) + " Tech = " + f_to_s( empireTech ) + " diff = " + f_to_s( techDiff ));
		
		if ( techDiff > threshold )
		{
			data.baseResearchRate = vary( empireResearchRate / data.angerLevel * 1.2f, 0.2f );
			
			if ( data.log )
			print("Research inc = " + standardize( data.baseResearchRate ));
		}
		else if ( techDiff < 0.f )
		{
			data.baseResearchRate = vary( empireResearchRate / data.angerLevel / 2.f, 0.2f );
			
			if ( data.log )
			print("Research dec = " + standardize( data.baseResearchRate ));
		}
		
		return true;
	}
};

class RemnantAIData
{	
	bool seededGalaxy;
	float SeedSystemChance;
	ShipDesign@[] remnantDesigns;
	ShipDesign@[] waveDesigns;
	ShipDesign@[] commandDesigns;
	ShipDesign@[] stationDesigns;
	ShipDesign@[] specialDesigns;
	ShipDesign@[] matches;
	Task@[] tasks;
	SystemManager@[] systems;

	bool startedSeed;
	uint curSystem;
	float curScale;

	bool log;
	/*--------------*/
	bool aiActive;
	float remnantMultiplier;
	float researchFactor;
	float seedPerPlanet;
	float defensePerPlanet;
	float nextSpawnIncrease;
	float angerLevel;
	float angerPerSystem;
	
	float currScaleMod;
	float scaleMod;
	float currTechMod;
	float techMod;
	float nextResearchCheck;
	float nextResearchRateCheck;
	
	float nextWaveTime;
	float nextWaveSizeMod;
	float nextWaveIncrease;
	float waveSize;
	int waveCount;
	
	int ourSystems;
	uint systemTick;

	float baseResearchRate;
	
	SysSearchSettings sss_target;
	SysSearchSettings sss_source;
	
	RemnantAIData(Empire@ emp)
	{
		InitVariables( emp, true );
		
		addTask(SetupTask());
		addTask(SearchSetup());
	}

	RemnantAIData(Empire@ emp, XMLReader@ xml)
	{
		loadDefaults( false );
		
		InitVariables( emp, false );
		
		PrepareDesigns( emp );

		addTask(SearchSetup());

		while(xml.advance()) 
		{
			string@ name = xml.getNodeName();
			switch(xml.getNodeType()) 
			{
				case XN_Element:
				if(name == "vars") 
				{
					LoadVariables( xml );
				}
				else if(name == "system") 
				{
					addSystem( SystemManager( emp, xml ));
				}
				break;
			}
		}

		if ( aiActive )
		{
			addTask( ResearchTask() );
		}
	}
	
	void LoadVariables( XMLReader@ xml )
	{
		while(xml.advance()) 
		{
			string@ varName = xml.getNodeName();
			if(xml.getNodeType() == XN_Element) 
			{
				string@ value = xml.getAttributeValue("v");
				if(varName == "anger")
				{
					angerLevel = s_to_f(value);
					print("Anger " + value);
				}
				else if(varName == "currScale")
				{
					currScaleMod = s_to_f(value);
					print("currScale " + value);
				}
				else if(varName == "scale")
				{
					scaleMod = s_to_f(value);
					print("Scale " + value);
				}
				else if(varName == "currTech")
				{
					currTechMod = s_to_f(value);
					print("currTech " + value);
				}
				else if(varName == "tech")
				{
					techMod = s_to_f(value);
					print("tech " + value);
				}
				else if(varName == "waveTime")
				{
					nextWaveTime = s_to_f(value);
					print("waveTime " + value);
				}
				else if(varName == "waveSizeMod")
				{
					nextWaveSizeMod = s_to_f(value);
					print("waveSizeMod " + value);
				}
				else if(varName == "waveSizeIncrease")
				{
					nextWaveIncrease = s_to_f(value);
					print("waveSizeIncrease " + value);
				}
				else if(varName == "waveSize")
				{
					waveSize = s_to_f(value);
					print("waveSize " + value);
				}
				else if(varName == "waveCount")
				{
					waveCount = s_to_i(value);
					print("waveCount " + value);
				}
				else if(varName == "angerSystem")
				{
					angerPerSystem = s_to_f(value);
					print("angerSystem " + value);
				}
				else if(varName == "baseResearch")
				{
					baseResearchRate = s_to_f(value);
					print("baseResearch " + value);
				}
				else if(varName == "researchRateCheck")
				{
					nextResearchRateCheck = s_to_f(value);
					print("researchRateCheck " + value);
				}
				else if(varName == "seedPerP")
				{
					seedPerPlanet = s_to_f(value);
					print("seedPerP " + value);
				}
				else if(varName == "defPerP")
				{
					defensePerPlanet = s_to_f(value);
					print("defPerP " + value);
				}
				else if(varName == "spawnIncrease")
				{
					nextSpawnIncrease = s_to_f(value);
					print("spawnIncrease " + value);
				}
			}
			else if(xml.getNodeType() == XN_Element_End && varName == "vars")
			{
				break;
			}
		}
	}

	void InitVariables( Empire@ emp, bool firstTime )
	{
		log = logging;
	
		SeedSystemChance = getGameSetting("GAME_REMNANTS", 0.3f);
		startedSeed = false;

		systemTick = 0;
		
		aiActive = getGameSetting("GAME_REMNANT_AI", 0.f ) > 0.5f;

		// design making support if started as player
		if ( !emp.isAI() )
			aiActive = false;
		
		remnantMultiplier = getGameSetting("GAME_REMNANT_MULT", 2.f);
		researchFactor = getGameSetting("GAME_REMNANT_RESEARCH", 1.f);

		nextResearchCheck = 60000.f;
		
		sss_target.setCallback( "TargetSearch" );
		sss_source.setCallback( "SourceSearch" );

		if ( firstTime )
		{
			angerLevel = 1.f;
			scaleMod = 1.f;
			currScaleMod = scaleMod;
			currTechMod = 0.f;
			techMod = currTechMod;
			// Check if we should do raids and seeding
			seededGalaxy = getGameSetting("GAME_REMNANTS", 0.3f) < 0.001f || getGameSetting("GAME_REMNANTS_ENABLED", 1.f) < 0.5f;
			angerPerSystem = getGameSetting("GAME_REMNANT_AGRO", 0.1f);

			seedPerPlanet = aiActive ? SeedPerPlanetAi : SeedPerPlanet;
			defensePerPlanet = DefensePerPlanet;
			nextSpawnIncrease = vary( FirstSpawnIncrease, TimeVarianceRandomness );
			
			nextWaveTime = FirstAttackSpawnInterval + randomf( 15.f );
			nextWaveSizeMod = nextWaveTime / FirstAttackSpawnInterval;
			nextWaveIncrease = vary( FirstWaveIncrease, TimeVarianceRandomness );
			waveSize = BaseAttackSize;
			waveCount = 1;
			baseResearchRate = BaseResearchRate;
			nextResearchRateCheck = ResearchRateCheckInterval;
		}
		else
		{
			// Don't need to re-seed
			seededGalaxy = true;
		}
	}
	
	float CalcSystemFlag()
	{
		return scaleMod + techMod;
	}
	
	float CalcSystemForces( float planets )
	{
		return vary( planets * remnantMultiplier * seedPerPlanet * angerLevel, 0.2f );
	}

	float CalcDefenseForces( float planets )
	{
		return vary( planets * remnantMultiplier * defensePerPlanet * angerLevel, 0.2f );
	}
	
	void IncreaseAnger()
	{
		angerLevel += angerPerSystem;
		if ( randomf(1.f) < 0.5f )
			currScaleMod += angerPerSystem / 2.f;

		if ( log )
		print( "Anger = " + f_to_s( angerLevel ) + " scale = " + f_to_s( currScaleMod ) );
	}

	void GenerateDesigns(Empire@ emp)
	{
		uint cnt = defaultDesigns.length();
		
		for (uint i = 0; i < cnt; ++i)
		{
			if ( defaultDesigns[i].forRemnants )
				defaultDesigns[i].generateDesign(emp, true, defaultDesigns[i].scale * currScaleMod, defaultDesigns[i].className);
		}
		
		scaleMod = currScaleMod;
		
		PrepareDesigns( emp );
	}
	
	void PrepareDesigns(Empire@ emp)
	{
		// Prepare list of our designs
		uint cnt = emp.getShipLayoutCnt();
		remnantDesigns.resize( cnt );
		waveDesigns.resize( cnt );
		commandDesigns.resize( cnt );
		stationDesigns.resize( cnt );
		uint currentR = 0;
		uint currentW = 0;
		uint currentC = 0;
		uint currentS = 0;

		for (uint i = 0; i < cnt; ++i)
		{
			const HullLayout@ layout = emp.getShipLayout(i);
			if ( !layout.get_obsolete() )
			{
				ShipDesign@ design = ShipDesign(layout.getName());
				design.scale = sqr(layout.scale);
				design.goalID = GoalID(layout.metadata);
				
				switch( design.goalID )
				{
				case GID_Remnant:
					@remnantDesigns[currentR] = design;
					currentR++;
					@waveDesigns[currentW] = design;
					currentW++;
				break;
				case GID_RemnantStation:
					@stationDesigns[currentS] = design;
					currentS++;
				break;
				case GID_RemnantCommand:
					@commandDesigns[currentC] = design;
					currentC++;
				break;
				case GID_RemnantWave:
					@waveDesigns[currentW] = design;
					currentW++;
				break;
				case GID_RemnantPicket:
					@remnantDesigns[currentR] = design;
					currentR++;
					@waveDesigns[currentW] = design;
					currentW++;
				break;
				}
			}
		}

		remnantDesigns.resize( currentR );
		waveDesigns.resize( currentW );
		commandDesigns.resize( currentC );
		stationDesigns.resize( currentS );
	
		matches.resize( max( currentR, currentW )); // assuming that stations and command designs are always less numerous

		if ( log )
		print("Have " + i_to_s( currentR ) + "/" + i_to_s( currentW ) + "/" + i_to_s( currentS ) + "/" + i_to_s( currentC ) + " designs");

		// ListDesigns();
	}
	
	void UpdateDesigns(Empire@ emp)
	{
		uint count = waveDesigns.length(); // remnantDesigns are subset of these
		for ( uint i = 0; i < count; ++i )
		{
			emp.updateHull( waveDesigns[i].className, 4.f );
		}

		count = commandDesigns.length();
		for ( uint i = 0; i < count; ++i )
		{
			emp.updateHull( commandDesigns[i].className, 4.f );
		}

		count = stationDesigns.length();
		for ( uint i = 0; i < count; ++i )
		{
			emp.updateHull( stationDesigns[i].className, 4.f );
		}

	
		PrepareDesigns( emp );
		
		techMod = currTechMod;
	}
	
	void PrintDesignList( ShipDesign@[]& list )
	{
		for ( uint i = 0; i < list.length(); ++i )
		{
			print( "Design " + list[i].className + " size " + f_to_s( list[i].scale ) + " role " + i_to_s( list[i].goalID ));
		}
	}
	
	void ListDesigns()
	{
		print("Base designs:");
		PrintDesignList( remnantDesigns );
		
		print("Wave designs:");
		PrintDesignList( waveDesigns );
		
		print("Station designs:");
		PrintDesignList( stationDesigns );

		print("Command designs:");
		PrintDesignList( commandDesigns );
	}
	
	float CalcTechLevels( ResearchWeb& web )
	{
		float levels = 0.f;

		for ( uint i = 0; i < defensiveTechs.length(); i++ )
		{
			// print("Def = " + defensiveTechs[i]);
			const WebItem@ item = web.getItem(defensiveTechs[i]);
			if ( item !is null )
				levels += item.get_level();
		}

		for ( uint i = 0; i < offensiveTechs.length(); i++ )
		{
			// print("Off = " + offensiveTechs[i]);
			const WebItem@ item = web.getItem(offensiveTechs[i]);
			if ( item !is null )
				levels += item.get_level();
		}
		
		return levels;
	}
	
	void UpdateTechMod( ResearchWeb& web )
	{
		currTechMod = CalcTechLevels( web ) / 10.f;

//		print( "New currMod = " + standardize( currTechMod ));
	}
	
	void UpdateWaveSize()
	{
		if ( gameTime >  2.f * FirstWaveIncrease )
		{
			if ( randomf( 1.f ) < 0.5f )
				waveCount++;
		}

		waveSize += randomf( 10.f, 15.f );

		nextWaveIncrease = vary( WaveIncreaseInterval, TimeVarianceRandomness );
		
		if ( log )
		print( "Waves: " + i_to_s( waveCount ) + " of size = " + f_to_s( waveSize ));
	}

	void UpdateSpawnSize()
	{
		nextSpawnIncrease = vary( SpawnIncreaseInterval, TimeVarianceRandomness );
		
		seedPerPlanet += randomf( 5.f, 10.f );
		defensePerPlanet += randomf( 5.f, 10.f );
		
		currScaleMod += 0.1f;

		if ( log )
		print( "Seeds: planet = " + f_to_s( seedPerPlanet ) + " defense = " + f_to_s( defensePerPlanet ) + " scaleMod " + f_to_s( currScaleMod ));
	}
	
	void SendWaves()
	{
		for ( uint empNumber = 0; empNumber < getEmpireCount(); empNumber++ )
		{
			Empire@ target = getEmpire( empNumber );
			
			if ( target.ID >= 0 )
			{
				if ( target.getStat( str_Victory ) > -0.5f )
				{
					for ( int wave = 0; wave < waveCount; wave++ )
						addTask( PrepareWave( this, remnantMultiplier * waveSize * nextWaveSizeMod * angerLevel, target ));
				}
			}
		}

		nextWaveTime = vary( AttackSpawnInterval, TimeVarianceRandomness );
		nextWaveSizeMod = nextWaveTime / AttackSpawnInterval;
	}
		
	void nextSystem()
	{
		Empire@ space = getEmpireByID(-1);
		uint empCnt = getEmpireCount();

		System@ sys = getSystem(curSystem);
		Object@ obj = sys;
		Empire@ us = getEmpireByID(-3);

		int spacePlanets = obj.getStat(space, str_planets);
		bool colonized = false;

		// Make sure no empire is present here
		for (uint i = 0; i < empCnt; ++i)
		{
			Empire@ other = getEmpire(i);

			if (other.ID > 0)
			{
				if (obj.getStat(other, str_planets) > 0.1f)
				{
					colonized = true;
					break;
				}
			}
		}

		if ( !colonized && spacePlanets > 0 && randomf(1.f) < SeedSystemChance )
		{
			curScale = CalcSystemForces( spacePlanets );
			ourSystems++;
		}
		else
		{
			curScale = 0.f;
			obj.setStat(us, str_RemnantSys, 0.f);
		}
	}

	void seedGalaxy(Empire@ emp)
	{
		if (remnantDesigns.length() == 0)
		{
			seededGalaxy = true;
			return;
		}

		if (!startedSeed)
		{
			startedSeed = true;
			curSystem = 0;
			curScale = 0.f;
			ourSystems = 0;
			nextSystem();
		}

		uint sysCnt = getSystemCount();

		if (curSystem < sysCnt)
		{
			System@ sys = getSystem(curSystem);
			
			if ( curScale > 0.f )
			{
				// addSeeder( SystemSeeder(sys, curScale, 1, false));
				addSystem( SystemManager( emp, this, sys, curScale ));
				// curSystem = sysCnt;
			}

			++curSystem;
			if (curSystem < sysCnt)
				nextSystem();
			return;
		}

		seededGalaxy = true;
		
		angerPerSystem += ( angerPerSystem * ( sysCnt - ourSystems ) ) / ourSystems;
		
		if ( log )
		print("Our systems = " + i_to_s( ourSystems ) + " new system anger value = " + f_to_s( angerPerSystem ));
	}

	/* {{{ Remnant Imperial Systems */
	void createDefenseRing(RemnantAIData@ data, Empire@ emp, System@ sys, Object@ obj, float radius, uint amount) {
		float angle = 0, angleInc = twoPi / float(amount);
		for (uint i = 0; i < amount; ++i) {
			vector pos = vector(radius * cos(angle), 0, radius * sin(angle));
			pos += obj.position;
			angle += angleInc;

			ShipDesign@ design = data.pickRandomLayout(specialDesigns, GID_SpecialDefense);
			if (@design == null)
				break;

			const HullLayout@ buildShip = @emp.getShipLayout(design.className);
			if (@buildShip == null)
				break;

			Object@ ship = spawnShip(emp, buildShip, sys, pos);
			ship.orbitAround(obj);
		}
	}

	void createRemnantResearchOutpost(System@ sys, RemnantAIData@ data, Empire@ emp) {
		// Create the star
		Star@ star = makeStar(sys, 1.f);

		// Create planets
		float orbit = orbitRadiusFactor * 1.f;
		uint capital = rand(3);
		uint outpost = 1;

		for (uint i = 0; i < 4; ++i) {
			orbit += orbitRadiusFactor * randomf(1.f, 2.f);
			Planet@ pl = null;
			Object@ obj = null;

			if (i == capital) {
				@pl = makePlanet(sys, 30, 0, orbit);
				@obj = pl;
				obj.setName(localize("#PL_ResearchOutpost"));
				
				pl.addCondition("remnant_research");
				
				createDefenseRing(data, emp, sys, obj, 60.f, 18);
				createDefenseRing(data, emp, sys, obj, 90.f, 12);				
			}
			else {
				@pl = makeRandomPlanet(sys, 0, orbit);
				@obj = pl;
				++outpost;
			}
		}
		for (uint i = 0; i < 15; ++i) {
			ShipDesign@ design = data.pickRandomLayout(waveDesigns, GID_Remnant);
			if (@design == null)
				break;

			const HullLayout@ buildShip = @emp.getShipLayout(design.className);
			if (@buildShip == null)
				break;

			// Calculate a random position in the system
			float theta = randomf(twoPi);
			float radius = sys.toObject().radius * randomf(0.4f, 0.8f);

			vector pos = vector(radius * cos(theta), 0, radius * sin(theta));

			HulledObj@ ship = spawnShip(emp, buildShip, sys, pos);
			ship.toObject().setStance(AIS_Defend);
		}	
	}			

	void createRemnantImperialSeat(System@ sys, RemnantAIData@ data, Empire@ emp) {
		// Create the star
		Star@ star = makeStar(sys, 1.f);

		// Create planets
		float orbit = orbitRadiusFactor * 1.f;
		uint capital = rand(3);
		uint outpost = 1;

		for (uint i = 0; i < 4; ++i) {
			orbit += orbitRadiusFactor * randomf(1.f, 2.f);
			Planet@ pl = null;
			Object@ obj = null;

			// Get structure types
			const subSystemDef@ city = getSubSystemDefByName("City");
			const subSystemDef@ mtl = getSubSystemDefByName("MetalMine");
			const subSystemDef@ elc = getSubSystemDefByName("AdvPartFact");
			const subSystemDef@ adv = getSubSystemDefByName("ElectronicFact");
			const subSystemDef@ yard = getSubSystemDefByName("ShipYard");
			const subSystemDef@ port = getSubSystemDefByName("SpacePort");
			const subSystemDef@ sci = getSubSystemDefByName("SciLab");

			if (i == capital) {
				@pl = makePlanet(sys, 60, 0, orbit);
				@obj = pl;
				obj.setName(localize("#PL_ImperialSeat"));


				// Add remnant capitol
				ObjectLock(obj);
				obj.setOwner(emp);
				pl.modPopulation(1000);
				pl.addStructure(getSubSystemDefByName("RemnantCapitol"));

				// Add structures
				for (uint i = 0; i < 7; ++i) {
					pl.addStructure(city);
					pl.addStructure(mtl);
					pl.addStructure(elc);
					pl.addStructure(adv);
					pl.addStructure(yard);
					pl.addStructure(port);
					pl.addStructure(sci);
				}

				pl.modPopulation(-pl.getPopulation());
				obj.setOwner(getEmpireByID(-1));

				createDefenseRing(data, emp, sys, obj, 60.f, 18);
				createDefenseRing(data, emp, sys, obj, 90.f, 12);
				createDefenseRing(data, emp, sys, obj, 120.f, 8);
			}
			else {
				@pl = makePlanet(sys, 40, 0, orbit);
				@obj = pl;
				obj.setName(localize("#PL_ImperialOutpost")+romanize(outpost));
				++outpost;

				// Add capitol
				ObjectLock(obj);
				obj.setOwner(emp);
				pl.modPopulation(1000);
				pl.addStructure(getSubSystemDefByName("Capital"));

				// Add structures
				for (uint i = 0; i < 4; ++i) {
					pl.addStructure(city);
					pl.addStructure(mtl);
					pl.addStructure(elc);
					pl.addStructure(adv);
					pl.addStructure(yard);
					pl.addStructure(port);
					pl.addStructure(sci);
				}
				
				pl.modPopulation(-pl.getPopulation());
				obj.setOwner(getEmpireByID(-1));

				createDefenseRing(data, emp, sys, obj, 50.f, 12);
				createDefenseRing(data, emp, sys, obj, 75.f, 6);
			}
		}
	}

	void createDefenseRing(Empire@ emp, const HullLayout@ layout, System@ sys, Object@ obj, float radius, uint amount, float z) {
		float angle = 0, angleInc = twoPi / float(amount);
		for (uint i = 0; i < amount; ++i) {
			vector pos = vector(radius * cos(angle), z, radius * sin(angle));
			pos += obj.position;
			angle += angleInc;

			Object@ ship = spawnShip(emp, layout, sys, pos);
			ship.orbitAround(obj);
		}
	}

	void createRemnantJumpSystem(System@ sys, RemnantAIData@ data, Empire@ emp) {
		Object@ sysObj = sys;
		
		// Create the star
		Star@ star = makeStar(sys, 2.f);

		// Retrieve layouts
		const HullLayout@ jumpLay = emp.getShipLayout(localize("#SH_Remnant Jump Bridge"));
		
		if (jumpLay is null)
			return;	
			
		float angle = 0, angleInc = twoPi / 2.f;
		float radius = sysObj.radius * 0.3f;
		for (uint i = 0; i < 2; ++i) {
			vector pos = vector(radius * cos(angle), 0, radius * sin(angle));
			angle += angleInc;

			Object@ ship = spawnShip(emp, jumpLay, sys, pos);
			ship.orbitAround(null);
		}
	}

	void createRemnantGateSystem(System@ sys, RemnantAIData@ data, Empire@ emp) {
		Object@ sysObj = sys;
		
		// Create the star
		Star@ star = makeStar(sys, 1.f);
		Object@ starObj = star;

		// Retrieve layouts
		const HullLayout@ gateLay = emp.getShipLayout(localize("#SH_Remnant Gate Array"));
		const HullLayout@ defLay = emp.getShipLayout(localize("#SH_Defense Grid"));

		if (gateLay is null || defLay is null)
			return;

		// Create the gates
		float angle = 0, angleInc = twoPi / 3.f;
		float radius = sysObj.radius * 0.3f;
		for (uint i = 0; i < 3; ++i) {
			vector pos = vector(radius * cos(angle), 0, radius * sin(angle));
			angle += angleInc;

			Object@ ship = spawnShip(emp, gateLay, sys, pos);
			ship.orbitAround(null);

			createDefenseRing(emp, defLay, sys, ship, 200.f, 18, 0.f);
			createDefenseRing(emp, defLay, sys, ship, 200.f, 8, -50.f);
			createDefenseRing(emp, defLay, sys, ship, 200.f, 8, 50.f);
		}

		// Create defense ships
		for (uint i = 0; i < 6; ++i) {
			ShipDesign@ design = data.pickRandomLayout(waveDesigns, GID_Remnant);
			if (@design == null)
				break;

			const HullLayout@ buildShip = @emp.getShipLayout(design.className);
			if (@buildShip == null)
				break;

			// Calculate a random position in the system
			float theta = randomf(twoPi);
			float radius = sys.toObject().radius * randomf(0.4f, 0.8f);

			vector pos = vector(radius * cos(theta), 0, radius * sin(theta));

			HulledObj@ ship = spawnShip(emp, buildShip, sys, pos);
			ship.toObject().setStance(AIS_Defend);
		}
	}

	void createSpatialGen(System@ sys, RemnantAIData@ data, Empire@ emp) {
		Object@ sysObj = sys;
		
		// Retrieve layouts
		const HullLayout@ spatLay = emp.getShipLayout(localize("#SH_Remnant Spatial Distortion Generator"));
		const HullLayout@ defLay = emp.getShipLayout(localize("#SH_Defense Grid"));
		
		if (spatLay is null || defLay is null)
			return;
			
		vector pos = vector(0,0,0);
		
		Object@ ship = spawnShip(emp, spatLay, sys, pos);
		ship.orbitAround(null);
		
		createDefenseRing(emp, defLay, sys, ship, 200.f, 18, 0.f);
		createDefenseRing(emp, defLay, sys, ship, 200.f, 8, -50.f);
		createDefenseRing(emp, defLay, sys, ship, 200.f, 8, 50.f);
		
		for (uint i = 0; i < 50; ++i) {
			ShipDesign@ design = data.pickRandomLayout(waveDesigns, GID_Remnant);
			if (@design == null)
				break;

			const HullLayout@ buildShip = @emp.getShipLayout(design.className);
			if (@buildShip == null)
				break;

			// Calculate a random position in the system
			float theta = randomf(twoPi);
			float radius = sysObj.radius * randomf(0.4f, 0.8f);

			vector spos = vector(radius * cos(theta), 0, radius * sin(theta));

			HulledObj@ ship = spawnShip(emp, buildShip, sys, spos);
			ship.toObject().setStance(AIS_Defend);
		}
	}
	
	void createZeroPoint(System@ sys, RemnantAIData@ data, Empire@ emp) {
		Object@ sysObj = sys;
		
		Star@ star = makeStar(sys, 1.5f);	
		
		// Retrieve layouts
		const HullLayout@ spLay = emp.getShipLayout(localize("#SH_Remnant Zero Point Field Generator"));
		
		if (spLay is null)
			return;
			
		// Create the Zer Points
		float angle = 0, angleInc = twoPi / 3.f;
		float radius = sysObj.radius * 0.3f;
		for (uint i = 0; i < 3; ++i) {
			vector pos = vector(radius * cos(angle), 0, radius * sin(angle));
			angle += angleInc;

			Object@ ship = spawnShip(emp, spLay, sys, pos);
			ship.setStance(AIS_Defend);
			ship.orbitAround(null);
		}		
		
		// Create the planets
		float orbit = orbitRadiusFactor * 1.f;	
		
		for (uint i = 0; i < 6; ++i) {
			orbit += orbitRadiusFactor * randomf(1.f, 2.f);
			Planet@ pl = null;

			@pl = makePlanet(sys, 40, 0, orbit);
		}		
	}
	
	void createIonCanon(System@ sys, RemnantAIData@ data, Empire@ emp) {
		Object@ sysObj = sys;
		
		// Retrieve layouts
		const HullLayout@ ionLay = emp.getShipLayout(localize("#SH_Remnant Ion Cannon"));
		const HullLayout@ defLay = emp.getShipLayout(localize("#SH_Defense Grid"));
		
		if (ionLay is null || defLay is null)
			return;
			
		vector pos = vector(0,0,0);
		
		Object@ ship = spawnShip(emp, ionLay, sys, pos);
		ship.orbitAround(null);
		
		createDefenseRing(emp, defLay, sys, ship, 200.f, 18, 0.f);
		createDefenseRing(emp, defLay, sys, ship, 200.f, 8, -50.f);
		createDefenseRing(emp, defLay, sys, ship, 200.f, 8, 50.f);
		
		for (uint i = 0; i < 50; ++i) {
			ShipDesign@ design = data.pickRandomLayout(waveDesigns, GID_Remnant);
			if (@design == null)
				break;

			const HullLayout@ buildShip = @emp.getShipLayout(design.className);
			if (@buildShip == null)
				break;

			// Calculate a random position in the system
			float theta = randomf(twoPi);
			float radius = sysObj.radius * randomf(0.4f, 0.8f);

			vector spos = vector(radius * cos(theta), 0, radius * sin(theta));

			HulledObj@ ship = spawnShip(emp, buildShip, sys, spos);
			ship.toObject().setStance(AIS_Defend);
		}
	}
	
	void seedSpecialSystems(Empire@ emp)
	{
		const string@ strImperialSeat = "ImperialSeat";
		const string@ strGateSystem = "GateSystem";
		const string@ strResearchOutpost = "ResearchOutpost";
		const string@ strJumpSystem = "JumpSystem";
		const string@ strSpatialGen = "SpatialGen";
		const string@ strZeroPoint = "ZeroPoint";
		const string@ strIonCanon = "IonCanon";

		uint sysCnt = getSystemCount();
		for (uint i = 0; i < sysCnt; ++i) {
			System@ sys = getSystem(i);

			if (sys.hasTag(strImperialSeat)) {
				createRemnantImperialSeat(sys, this, emp);
			}
			else if (sys.hasTag(strGateSystem)) {
				createRemnantGateSystem(sys, this, emp);
			}
			else if (sys.hasTag(strResearchOutpost)) {
				createRemnantResearchOutpost(sys, this, emp);
			}
			else if (sys.hasTag(strJumpSystem)) {
				createRemnantJumpSystem(sys, this, emp);
			}			
			else if (sys.hasTag(strSpatialGen)) {
				createSpatialGen(sys, this, emp);
			}
			else if (sys.hasTag(strZeroPoint)) {
				createZeroPoint(sys, this, emp);
			}
			else if (sys.hasTag(strIonCanon)) {
				createIonCanon(sys, this, emp);
			}
		}
	}
	
	void save(XMLWriter@ xml)
	{
		xml.createHeader();
		
		xml.addElement("vars", false);
		xml.addElement("enabled", true, "v", aiActive ? "true" : "false");
		xml.addElement("anger", true, "v", ftos_nice(angerLevel));
		xml.addElement("currScale", true, "v", ftos_nice(currScaleMod));
		xml.addElement("scale", true, "v", ftos_nice(scaleMod));
		xml.addElement("currTech", true, "v", ftos_nice(currTechMod));
		xml.addElement("tech", true, "v", ftos_nice(techMod));
		xml.addElement("waveTime", true, "v", ftos_nice(nextWaveTime));
		xml.addElement("waveSizeMod", true, "v", ftos_nice(nextWaveSizeMod));
		xml.addElement("waveSizeIncrease", true, "v", ftos_nice(nextWaveIncrease));
		xml.addElement("waveSize", true, "v", ftos_nice(waveSize));
		xml.addElement("waveCount", true, "v", i_to_s(waveCount));
		xml.addElement("angerSystem", true, "v", ftos_nice(angerPerSystem));
		xml.addElement("baseResearch", true, "v", ftos_nice(baseResearchRate));
		xml.addElement("researchRateCheck", true, "v", ftos_nice(nextResearchRateCheck));
		xml.addElement("seedPerP", true, "v", ftos_nice(seedPerPlanet));
		xml.addElement("defPerP", true, "v", ftos_nice(defensePerPlanet));
		xml.addElement("spawnIncrease", true, "v", ftos_nice(nextSpawnIncrease));
		xml.closeTag("vars");
		
		for ( uint i = 0;i < systems.length(); i++ )
		{
			systems[i].save( xml );
		}
	}

	void tick(Empire@ emp, float time)
	{
		// Make sure we have metals for repairs
		float gen = time * MetalGenPerSecond * angerLevel * scaleMod;
		emp.addStat( str_Metals, gen );
		emp.addStat( str_Elects, gen );
		emp.addStat( str_AdvParts, gen );
		emp.addStat( str_Fuel, gen );
		emp.addStat( str_Ammo, gen );

		// Update all tasks
		for (uint i = 0, cnt = tasks.length(); i < cnt; ++i)
		{
			Task@ task = tasks[i];

			if (task.update(emp, this, time)) {
				tasks.erase(i);
				--i; --cnt;
			}
		}
		
		if ( systemTick < systems.length() )
		{
			if ( systems[systemTick].update( emp, this, time ))
			{
				systems.erase( systemTick );
				
				if ( systems.length() == 0 )
				{
					emp.setStat(str_Victory, -1.f);
					aiActive = false;

					if ( log )
					print("Lost - AI deactivated");
				}
			}
			else
				systemTick++;
			
			if ( systemTick >= systems.length() )
				systemTick = 0;
		}
		else
			systemTick = 0;

		if ( aiActive )
		{
			nextSpawnIncrease -= time;
			if ( nextSpawnIncrease < 0.f )
				UpdateSpawnSize();
				
			nextResearchCheck -= time;
			if ( nextResearchCheck < 0.f )
				addTask(ResearchTask());
			
			nextResearchRateCheck -= time;
			if ( nextResearchRateCheck < 0.f )
				addTask(ResearchRateTask());

			nextWaveIncrease -= time;
			if ( nextWaveIncrease < 0.f )
				UpdateWaveSize();
			
			nextWaveTime -= time;
			if ( nextWaveTime < 0.f )
				SendWaves();
			
			if ( currTechMod - techMod > 0.45f )
				UpdateDesigns( emp );
			
			if ( currScaleMod - scaleMod > 0.05f )
				GenerateDesigns( emp );
		}
		
//		ResearchWeb web;
//		web.prepare(emp);
		
//		int link = -1;
//		float lev1, lev2, lev3, lev4;
//		web.getActiveTech(link).getLevels(lev1, lev2, lev3, lev4);
//		print( "Levels = " + f_to_s(lev1) + " " + f_to_s(lev2) + " " + f_to_s(lev3) + " " + f_to_s(lev4));
//		web.prepare(null);
	}

	void onDiplomaticMessage(Empire@ emp, Empire@ from, DiploMsg@ msg) {
	}

	void addTask(Task@ task) {
		uint pos = tasks.length();
		tasks.resize(pos + 1);
		@tasks[pos] = @task;
	}

	void removeTask(Task@ task) {
		for(uint i = 0, cnt = tasks.length(); i < cnt; ++i) {
			if(tasks[i] is task) {
				tasks.erase(i);
				return;
			}
		}
	}

	void addSystem(SystemManager@ system)
	{
		uint pos = systems.length();
		systems.resize(pos + 1);
		@systems[pos] = @system;
	}
	
	ShipDesign@ pickRandomLayoutUnderScale(Empire@ emp, ShipDesign@[]& designs, GoalID goal, float scale, ShipDesign@[]& matches)
	{
		uint cnt = designs.length();
		uint matchCount = 0;
		
		for(uint i = 0; i < cnt; ++i)
		{
			if(designs[i].goalID == goal || goal == GID_Invalid )
			{
				ShipDesign@ design = @designs[i];
				
				if (design.scale < scale)
					@matches[matchCount++] = design;
			}
		}
		
		if(matchCount == 0)
			return null;
		return matches[rand(matchCount - 1)];
	}

	ShipDesign@ pickLargestLayoutUnderScale(Empire@ emp, ShipDesign@[]& designs, GoalID goal, float scale)
	{
		uint cnt = designs.length();
		ShipDesign@ largestDesign = null;
		
		for(uint i = 0; i < cnt; ++i)
		{
			if( designs[i].goalID == goal || goal == GID_Invalid )
			{
				ShipDesign@ design = @designs[i];
				
				if (design.scale < scale)
					if (largestDesign is null || design.scale > largestDesign.scale)
						@largestDesign = design;
			}
		}
		
		return largestDesign;
	}

	ShipDesign@ pickRandomLayout(ShipDesign@[]& designs, GoalID goal)
	{
		uint cnt = designs.length();
		
		ShipDesign@[] matches;
		matches.resize(cnt);
		uint matchCount = 0;
		
		for(uint i = 0; i < cnt; ++i)
			if(designs[i].goalID == goal)
				@matches[matchCount++] = @designs[i];
		
		if(matchCount == 0)
			return null;
		return matches[rand(matchCount - 1)];
	}
};

enum SystemState
{
	SysIdle = 0,
	SysBuild,
	SysDefend,
	SysUpdate,
	SysFleet,
	SysEnd
};

class SystemManager
{
	System@ system;
	SystemState state;
	SystemState[] stateQueue;
	Object@ commandShip;

	float nextPresenceCheck;
	float nextRegroupCheck;
	float lastDefense;
	float systemFlag;
	int buildId;
	
	float retrofitTimeout;
	int retrofitId;
	
	float strToBuild;
	int largeToBuild;

	float strToDefend;
	int largeToDefend;

	Fleet@ attackFleet;
	System@ fleetTarget;
	float strToFleet;
	int largeToFleet;

	// not saved variables
	uint retrofitIndex;
	float defStrength;
	float offStrength;
	uint picketCount;
	
	SystemManager( Empire@ emp, RemnantAIData@ data, System@ sys, float initialStr )
	{
		@system = sys;
		buildId = 0;

		state = SysIdle;
		stateQueue.resize( 0 );
		
		strToBuild = initialStr;
		largeToBuild = 1;
		QueueState( SysBuild );

		strToDefend = initialStr;
		largeToDefend = 1;
		QueueState( SysDefend );
		
		retrofitTimeout = 0.f;
		retrofitId = 0;

		@attackFleet = null;
		@fleetTarget = null;
		strToFleet = 0.f;
		largeToFleet = 0;
		
		nextPresenceCheck = gameTime + SystemCheckInterval;
		nextRegroupCheck = gameTime + RegroupInterval;
		lastDefense = gameTime - DefensiveSpawnInterval;
		
		systemFlag = data.CalcSystemFlag();
		
		retrofitIndex = 0;
		defStrength = 0.f;
		offStrength = 0.f;
		picketCount = PicketShipsCount;
		
		if ( !data.aiActive )
			QueueState( SysEnd );

		// print( "Adding manager for " + sys.toObject().getName() + " seed " + f_to_s( strToBuild ));
		
		ShipDesign@ command = PickCommandShip( emp, data, strToBuild );
		const HullLayout@ buildShip = @emp.getShipLayout( command.className );

		float theta = randomf( twoPi );
		float radius = system.toObject().radius * randomf( 0.2f, 0.4f );

		vector pos( radius * cos( theta ), 0, radius * sin( theta ));

		HulledObj@ ship = spawnShip( emp, buildShip, system, pos );
		
		@commandShip = ship.toObject();
		commandShip.orbitAround( null );
		
		system.toObject().setStat( emp, str_RemnantSys, 1.f );
		
		// print( "Spawned " + commandShip.getName() + " at " + system.toObject().getName() + " build order for " + f_to_s( strToBuild ));
	}

	SystemManager( Empire@ emp, XMLReader@ xml )
	{
		retrofitIndex = 0;
		defStrength = 0.f;
		offStrength = 0.f;
		picketCount = PicketShipsCount;
		
		@attackFleet = null;
		@fleetTarget = null;
		
		while(xml.advance()) 
		{
			string@ varName = xml.getNodeName();
			if(xml.getNodeType() == XN_Element) 
			{
				string@ value = xml.getAttributeValue("v");
				if(varName == "sysId")
				{
					Object@ obj = getObjectByID( s_to_i( value ));
					@system = obj.toSystem();
					// print("sysId " + obj.getName());
				}
				else if(varName == "state")
				{
					state = SystemState( s_to_i(value));
					// print("state " + value);
				}
				else if(varName == "stateQueue")
				{
					while(xml.advance())
					{
						string@ varName1 = xml.getNodeName();
						if ( xml.getNodeType() == XN_Element && varName1 == "state" )
						{
							string@ value1 = xml.getAttributeValue("v");
							SystemState state1 = SystemState( s_to_i( value1 ));
							uint pos = stateQueue.length();
							stateQueue.resize( pos + 1 );
							stateQueue[pos] = state1;
							// print("State item " + i_to_s( pos ) + " val " + i_to_s( state1 ));
						}
						else if ( xml.getNodeType() == XN_Element_End && varName1 == "stateQueue" )
						{
							break;
						}
					}
					// print("stateQueue " + stateQueue.length());
				}
				else if(varName == "commandId")
				{
					@commandShip = getObjectByID( s_to_i( value ));
					// print("commandId " + commandShip.getName());
				}
				else if(varName == "nextPresenceCheck")
				{
					nextPresenceCheck = s_to_f(value);
					// print("nextPresenceCheck " + value);
				}
				else if(varName == "nextRegroupCheck")
				{
					nextRegroupCheck = s_to_f(value);
					// print("nextRegroupCheck " + value);
				}
				else if(varName == "lastDefense")
				{
					lastDefense = s_to_f(value);
					// print("lastDefense " + value);
				}
				else if(varName == "systemFlag")
				{
					systemFlag = s_to_f(value);
					// print("systemFlag " + value);
				}
				else if(varName == "buildId")
				{
					buildId = s_to_i(value);
					// print("buildId " + value);
				}
				else if(varName == "retrofitTimeout")
				{
					retrofitTimeout = s_to_f(value);
					// print("retrofitTimeout " + value);
				}
				else if(varName == "retrofitId")
				{
					retrofitId = s_to_i(value);
					// print("retrofitId " + value);
				}
				else if(varName == "strToBuild")
				{
					strToBuild = s_to_f(value);
					// print("strToBuild " + value);
				}
				else if(varName == "largeToBuild")
				{
					largeToBuild = s_to_i(value);
					// print("largeToBuild " + value);
				}
				else if(varName == "strToDefend")
				{
					strToDefend = s_to_f(value);
					// print("strToDefend " + value);
				}
				else if(varName == "largeToDefend")
				{
					largeToDefend = s_to_i(value);
					// print("largeToDefend " + value);
				}
				else if(varName == "attackFleet")
				{
					Object@ commander = emp.getFleetCommander( value );
					if ( commander !is null )
					{
						@attackFleet = commander.toHulledObj().getFleet();
					}
					else
						warning("Error loading fleet in " + system.toObject().getName());
						
					// print("attackFleet " + commander.getName() + " " + attackFleet.getName());
				}
				else if(varName == "fleetTarget")
				{
					Object@ obj = getObjectByID( s_to_i( value ));
					@fleetTarget = obj.toSystem();
					// print("fleetTarget " + obj.getName());
				}
				else if(varName == "strToFleet")
				{
					strToFleet = s_to_f(value);
					// print("strToFleet " + value);
				}
				else if(varName == "largeToFleet")
				{
					largeToFleet = s_to_i(value);
					// print("largeToFleet " + value);
				}
			}
			else if(xml.getNodeType() == XN_Element_End && varName == "system")
			{
				break;
			}
		}
	}
	
	void save( XMLWriter@ xml )
	{
		xml.addElement("system", false);
		xml.addElement("sysId", true, "v", i_to_s( system.toObject().uid ) );
		xml.addElement("state", true, "v", i_to_s( state ) );
		xml.addElement("stateQueue", false );
		for ( uint i = 0; i < stateQueue.length(); i++ )
		{
			xml.addElement("state", true, "v", i_to_s( stateQueue[i] ));
		}
		xml.closeTag("stateQueue");
		xml.addElement("commandId", true, "v", i_to_s( commandShip.uid ) );
		
		xml.addElement("nextPresenceCheck", true, "v", ftos_nice(nextPresenceCheck));
		xml.addElement("nextRegroupCheck", true, "v", ftos_nice(nextRegroupCheck));
		xml.addElement("lastDefense", true, "v", ftos_nice(lastDefense));
		xml.addElement("systemFlag", true, "v", ftos_nice(systemFlag));
		xml.addElement("buildId", true, "v", i_to_s(buildId));
		
		xml.addElement("retrofitTimeout", true, "v", ftos_nice(retrofitTimeout));
		xml.addElement("retrofitId", true, "v", i_to_s(retrofitId));
		
		xml.addElement("strToBuild", true, "v", ftos_nice(strToBuild));
		xml.addElement("largeToBuild", true, "v", i_to_s(largeToBuild));
		
		xml.addElement("strToDefend", true, "v", ftos_nice(strToDefend));
		xml.addElement("largeToDefend", true, "v", i_to_s(largeToDefend));

		if ( attackFleet !is null )
			xml.addElement("attackFleet", true, "v", attackFleet.getName() );
		if ( fleetTarget !is null )
			xml.addElement("fleetTarget", true, "v", i_to_s( fleetTarget.toObject().uid ) );
		xml.addElement("strToFleet", true, "v", ftos_nice(strToFleet));
		xml.addElement("largeToFleet", true, "v", i_to_s(largeToFleet));

		xml.closeTag("system");
	}
	
	ShipDesign@ PickCommandShip( Empire@ emp, RemnantAIData@ data, float str )
	{
		ShipDesign@ command = data.pickLargestLayoutUnderScale( emp, data.commandDesigns, GID_RemnantCommand, str );
		
		if ( command is null )
		{
			@command = data.commandDesigns[0];
			float minScale = command.scale;
			for ( uint i = 1; i < data.commandDesigns.length(); i++ )
			{
				if ( data.commandDesigns[i].scale < minScale )
				{
					@command = data.commandDesigns[i];
					minScale = command.scale;
				}
			}
		}
		
		return command;
	}
	
	void QueueState( SystemState queue )
	{
		// print( "Add state " + i_to_s( queue ) + " to " + system.toObject().getName());
		uint count = stateQueue.length();
		
		for ( uint i = 0; i < count; i++ )
		{
			if ( stateQueue[i] == queue )
				return;
		}
	
		uint pos = stateQueue.length();
		stateQueue.resize( pos + 1 );
		stateQueue[pos] = queue;
	}
	
	void PositionObject( Object@ obj, const HullLayout@ hull )
	{
		float commandScale = commandShip.toHulledObj().getHull().scale;
		
		if ( GoalID( hull.metadata ) == GID_RemnantStation )
		{
			if ( obj.inOrbitAround() !is commandShip )
			{
				float theta = randomf( twoPi );
				float radius = hull.scale + commandScale;
				obj.orbitAround( null );
				obj.position = commandShip.position + vector( radius * cos( theta ), 0, radius * sin( theta ));
				obj.orbitAround( commandShip );
			}
		}
		else if ( GoalID( hull.metadata ) == GID_RemnantPicket )
		{
			if ( obj.velocity.getLengthSQ() < 400.f )
			{
				Object@ sysObj = system;
				if ( obj.position.getLength() < 0.8f * sysObj.radius )
				{
					float theta = randomf( twoPi );
					vector offset = vector( 0.9f * sysObj.radius * cos( theta ), 0, 0.9f * sysObj.radius * sin( theta ));
					OrderList orders;
					orders.prepare( obj );
					orders.giveMoveOrder( sysObj.position + offset, false );
					orders.prepare( null );
				}
			}
		}
		else if ( GoalID( hull.metadata ) != GID_RemnantFighter )
		{
			if ( obj.velocity.getLengthSQ() < 400.f )
			{
				float distanceSQ = commandShip.position.getDistanceFromSQ( obj.position );
				if ( distanceSQ < 0.5f * ( ShipRingRadiusSQ + sqr( commandScale ))
					|| distanceSQ > 3.f * ( ShipRingRadiusSQ + sqr( commandScale )) )
				{
					float theta = randomf( twoPi );
					float radius = vary( commandScale + ShipRingRadius, 0.3f );
					vector offset = commandShip.position + vector( radius * cos( theta ), 0, radius * sin( theta ));
					OrderList orders;
					orders.prepare( obj );
					orders.giveMoveOrder( commandShip.getParent().position + offset, false );
					orders.prepare( null );
				}
			}
		}
	}

	void ScanSystem( Empire@ emp, RemnantAIData@ data, bool regroup, bool positionPickets )	
	{
		offStrength = 0.f;
		defStrength = 0.f;
		picketCount = 0;
	
		SysObjList objects;
		objects.prepare( system );
		for ( uint i = 0; i < objects.childCount; i++ )
		{
			Object@ obj = objects.getChild( i );
			if ( obj.getOwner() is emp )
			{
				HulledObj@ hulled = obj.toHulledObj();
				if ( hulled !is null && hulled.getFleet() is null )
				{
					const HullLayout@ hull = hulled.getHull();
					GoalID goal = GoalID( hull.metadata );
					float scale = sqr( hull.scale );
				
					if ( goal == GID_RemnantStation )
						defStrength += scale;
					else if ( goal != GID_RemnantFighter && goal != GID_RemnantCommand )
					{
						offStrength += scale;
						
						if ( goal == GID_RemnantPicket )
							picketCount++;
					}
					
					if ( goal == GID_RemnantPicket && positionPickets )
						PositionObject( obj, hull );
					else if ( regroup )
						PositionObject( obj, hull );
				}
			}
		}
		objects.prepare( null );
		
		// print( system.toObject().getName() + " pickets " + i_to_s( picketCount ));
	}

	bool SendShipForRetrofit( Empire@ emp )
	{
		bool ret = true;
		
		// this index adds small code complication but it reduces number of checks significantly
		if ( retrofitIndex > 0 )
			ret = false;
		
		if ( retrofitId == 0 )
		{
			SysObjList objects;
			objects.prepare( system );
			
			if ( retrofitIndex >= objects.childCount )
			{
				retrofitIndex = 0;
				ret = true;
			}
			
			for ( uint i = retrofitIndex; i < objects.childCount; i++ )
			{
				Object@ obj = objects.getChild( i );
				
				if ( obj.getOwner() is emp )
				{
					HulledObj@ hulled = obj.toHulledObj();
					if ( hulled !is null )
					{
						if ( hulled.getHull().obsolete && hulled.getFleet() is null )
						{
							OrderList orders;
							orders.prepare( obj );
							orders.giveRetrofitOrder( commandShip, true );
							orders.prepare( null );
							
							if ( GoalID( hulled.getHull().metadata ) != GID_RemnantPicket )
							{
								retrofitId = obj.uid;
								ret = false;
								retrofitTimeout = gameTime + 240.f;
								retrofitIndex = i;
							// print("Sending for retrofit:" + obj.getName() );
							
								break;
							}
						}
					}
				}
			}
			
			objects.prepare( null );

			if ( retrofitId == 0 )
				retrofitIndex = 0;
		}
		else
			ret = false;
		
		return ret;
	}
	
	bool BuildFleet( System@ target, float str, int large )
	{
		if ( fleetTarget is null )
		{
			@fleetTarget = target;
			strToFleet = str;
			largeToFleet = large;
			
			QueueState( SysFleet );
			
			return true;
		}
		else if ( fleetTarget is target )
		{
			strToFleet += str;
			largeToFleet += large;
			return true;
		}
		
		return false;
	}
	
	void BuildSmallShips( Empire@ emp, RemnantAIData@ data )
	{
		if ( picketCount < PicketShipsCount )
		{
			ShipDesign@ design = data.pickRandomLayoutUnderScale( emp, data.remnantDesigns, GID_RemnantPicket, 10000.f, data.matches );
				
			if ( design !is null )
			{
				const HullLayout@ buildShip = @emp.getShipLayout( design.className );
				
				if ( buildShip !is null )
					commandShip.makeShip( buildShip, PicketShipsCount - picketCount, true );
				
				// print( system.toObject().getName() + " adding picket " + i_to_s( PicketShipsCount - picketCount ));
			}
			
		}
	}
	
	void PrintQueue()
	{
		print("Length " + stateQueue.length());
		for ( uint i = 0; i < stateQueue.length(); i++ )
		{
			print("Element " + i_to_s( i ) + " = " + i_to_s( stateQueue[i] ));
		}
	}
	
	void IdleState( Empire@ emp, RemnantAIData@ data )
	{
		if ( stateQueue.length() > 0 )
		{
			// PrintQueue();
			state = stateQueue[0];
			// print( system.toObject().getName() + " new state = " + i_to_s( state ));
			if ( stateQueue.length() > 1 )
			{
				for ( uint i = 1; i < stateQueue.length(); i++ )
					stateQueue[i - 1] = stateQueue[i];
				
				stateQueue.erase( stateQueue.length() - 1 );
			}
			else
				stateQueue.erase( 0 );
				
			// PrintQueue();
			return;
		}
		
		if ( gameTime > nextPresenceCheck )
		{
			Object@ obj = system;
			SysPresence pres;
			emp.getSystemPresence( system, pres );
			
			// print( obj.getName() + " presence = " + f_to_s( pres.enemiesStr ));
			
			if ( pres.enemiesStr > 1.f ) // if enemies are present check if we need to rebuild some of our forces (every DefensiveSpawnInterval)
			{
				if ( gameTime > lastDefense )
				{
					float spacePlanets = obj.getStat( getEmpireByID(-1), str_planets );
					
					lastDefense = gameTime + DefensiveSpawnInterval;

					ScanSystem( emp, data, false, false );
					
					BuildSmallShips( emp, data );
					
					strToBuild = data.CalcSystemForces( spacePlanets ) - offStrength;
					largeToBuild = min( rand( spacePlanets ), 3 );

					if ( strToBuild > 0.f )
						QueueState( SysBuild );
					
					strToDefend = data.CalcDefenseForces( spacePlanets ) - defStrength;
					largeToDefend = min( rand( spacePlanets ), 3 );
					
					if ( strToDefend > 0.f )
						QueueState( SysDefend );
					
					nextRegroupCheck = gameTime + RegroupInterval;
					
					if ( data.log )
					print("Defensive build triggered in " + obj.getName() + " for " + f_to_s( strToBuild ) + " / " + f_to_s( strToDefend ) +
						" with " + i_to_s( largeToBuild ) + " / " + i_to_s( largeToDefend ) + " large");
				}
			}
			else //if ( pres.enemies < 0.1f ) // we can do some cleaning when noone is around
			{
				if ( systemFlag < data.CalcSystemFlag() )
				{
					const HullLayout@ commandLayout = commandShip.toHulledObj().getHull();
					if ( commandLayout.obsolete && commandShip.getConstructionQueueSize() < 1 )
					{
						ShipDesign@ command = PickCommandShip( emp, data, offStrength == 0 ? pres.usStr : offStrength );// - sqr( commandLayout.scale ));

						const HullLayout@ newLayout = @emp.getShipLayout( command.className );
						vector pos = commandShip.position;
						
						commandShip.destroy( true );

						HulledObj@ ship = spawnShip( emp, newLayout, system, pos );
						
						@commandShip = ship.toObject();
						commandShip.orbitAround( null );
						
						nextRegroupCheck = gameTime + RegroupInterval;
						
						ScanSystem( emp, data, true, false );
						BuildSmallShips( emp, data );
					}
					else
					{
						if ( SendShipForRetrofit( emp ) )
						{
							systemFlag = data.CalcSystemFlag();
							// if ( data.log )
							// print( obj.getName() + " finished retrofit" );
						}
					}
				}
				else if ( gameTime > nextRegroupCheck )
				{
					// const HullLayout@ commandLayout = commandShip.toHulledObj().getHull();
					float spacePlanets = obj.getStat( getEmpireByID(-1), str_planets );

					nextRegroupCheck = gameTime + RegroupInterval;
					
					ScanSystem( emp, data, true, pres.enemies < 0.1f );
					BuildSmallShips( emp, data );
					
					float offGen = data.CalcSystemForces( spacePlanets );
					float defGen = data.CalcDefenseForces( spacePlanets );
					
					if ( offStrength == 0.f || offGen / offStrength > 1.4f )
					{
						strToBuild = offGen - offStrength;

						largeToBuild = 1;

						if ( data.log )
						{
							print( obj.getName() + " off str = " + f_to_s( offStrength ) + " new one " + f_to_s( offGen ));
						}
						
						QueueState( SysBuild );
					}

					if ( defStrength == 0.f || defGen / defStrength > 1.8f )
					{
						strToDefend = defGen - defStrength;

						largeToDefend = 1;

						if ( data.log )
						{
							print( obj.getName() + " def str = " + f_to_s( defStrength ) + " new one " + f_to_s( defGen ));
						}
						
						QueueState( SysDefend );
					}
				}
			}
			
			nextPresenceCheck = gameTime + SystemCheckInterval;
		}
	}

	void BuildState( Empire@ emp, RemnantAIData@ data )
	{
		if ( buildId != 0 )
		{
			Object@ obj = getObjectByID( buildId );
			
			if ( obj !is null )
			{
				buildId = 0;
				
				const HullLayout@ hull = obj.toHulledObj().getHull();
				float scale = sqr( hull.scale );
				
				// print( "Built " + obj.getName() + " size " + f_to_s( scale ) );
				strToBuild -= scale;
				obj.setStance( AIS_Defend );
				PositionObject( obj, hull );
			}
		}
		
		if ( buildId == 0 && commandShip.getConstructionQueueSize() < 1 )
		{
			ShipDesign@ design;
			
			if ( largeToBuild > 0 )
			{
				@design = data.pickLargestLayoutUnderScale( emp, data.remnantDesigns, GID_Invalid, strToBuild );
				largeToBuild--;
			}
			else
				@design = data.pickRandomLayoutUnderScale( emp, data.remnantDesigns, GID_Invalid, strToBuild, data.matches );
				
			if ( design !is null )
			{
				const HullLayout@ buildShip = @emp.getShipLayout( design.className );
				
				if ( buildShip !is null )
				{
					buildId = commandShip.makeShip( buildShip );
				}
			}
			else
			{
				state = SysIdle;
				nextRegroupCheck = gameTime + RegroupInterval;
				// if ( data.log )
				// print( system.toObject().getName() + " finished build");
			}
		}
	}

	void DefendState( Empire@ emp, RemnantAIData@ data )
	{
		if ( buildId != 0 )
		{
			Object@ obj = getObjectByID( buildId );
			
			if ( obj !is null )
			{
				buildId = 0;
				
				const HullLayout@ hull = obj.toHulledObj().getHull();
				float scale = sqr( hull.scale );
				
				// print( "Defense " + obj.getName() + " size " + f_to_s( scale ) );
				strToDefend -= scale;
				obj.setStance( AIS_Defend );
				PositionObject( obj, hull );
			}
		}
		
		if ( buildId == 0 && commandShip.getConstructionQueueSize() < 1 )
		{
			ShipDesign@ design;
			
			if ( largeToDefend > 0 )
			{
				@design = data.pickLargestLayoutUnderScale( emp, data.stationDesigns, GID_Invalid, strToDefend );
				largeToDefend--;
			}
			else
				@design = data.pickRandomLayoutUnderScale( emp, data.stationDesigns, GID_Invalid, strToDefend, data.matches );
				
			if ( design !is null )
			{
				const HullLayout@ buildShip = @emp.getShipLayout( design.className );
				
				if ( buildShip !is null )
				{
					buildId = commandShip.makeShip( buildShip );
				}
			}
			else
			{
				state = SysIdle;
				nextRegroupCheck = gameTime + RegroupInterval;
				
				// if ( data.log )
				// print( system.toObject().getName() + " finished defend");
			}
		}
	}

	void FleetState( Empire@ emp, RemnantAIData@ data )
	{
		if ( buildId != 0 )
		{
			Object@ obj = getObjectByID( buildId );
			
			if ( obj !is null )
			{
				buildId = 0;
				
				const HullLayout@ hull = obj.toHulledObj().getHull();
				float scale = sqr( hull.scale );
				
				// print( "Defense " + obj.getName() + " size " + f_to_s( scale ) );
				strToFleet -= scale;
				obj.setStance( AIS_Engage );
				
				if ( attackFleet is null )
				{
					float theta = randomf( twoPi );
					vector offset1 = commandShip.position + vector( 0.f, ShipRingRadius, 0.f );
					vector offset2 = commandShip.position + vector( ShipRingRadius * cos( theta ), ShipRingRadius, ShipRingRadius * sin( theta ));
					
					@attackFleet = emp.createFleet( obj );

					OrderList orders;
					orders.prepare( obj );
					orders.giveMoveOrder( commandShip.getParent().position + offset1, true );
					orders.giveMoveOrder( commandShip.getParent().position + offset2, true );
					orders.prepare( null );
				}
				else
					attackFleet.addMember( obj );
			}
		}
		
		if ( buildId == 0 && commandShip.getConstructionQueueSize() < 1 )
		{
			ShipDesign@ design;
			
			if ( largeToFleet > 0 )
			{
				@design = data.pickLargestLayoutUnderScale( emp, data.waveDesigns, GID_Invalid, strToFleet );
				largeToFleet--;
			}
			else
				@design = data.pickRandomLayoutUnderScale( emp, data.waveDesigns, GID_Invalid, strToFleet, data.matches );
				
			if ( design !is null )
			{
				const HullLayout@ buildShip = @emp.getShipLayout( design.className );
				
				if ( buildShip !is null )
				{
					buildId = commandShip.makeShip( buildShip );
				}
			}
			else
			{
				state = SysIdle;

				Object@ lead = attackFleet.getCommander();
				OrderList orders;
				lead.setStance(AIS_Engage);
				if ( orders.prepare( lead ) )
				{
					orders.clearOrders( false );
					// orders.giveGotoOrder( target, false );
					orders.giveAttackOrder( fleetTarget, true );
					orders.prepare( null );
				}
				
				// if ( data.log )
				// print( system.toObject().getName() + " finished fleet to " + fleetTarget.toObject().getName());
				
				@attackFleet = null;
				@fleetTarget = null;
			}
		}
	}
	
	bool update( Empire@ emp, RemnantAIData@ data, float tick )
	{
		bool ret = false;

		if ( retrofitId != 0 )
		{
			Object@ obj = getObjectByID( retrofitId );
			
			if ( obj !is null && obj.getOwner() is emp && !obj.toHulledObj().getHull().obsolete )
			{
				retrofitId = 0;
				PositionObject( obj, obj.toHulledObj().getHull() );

				// print("Confirmed retrofit of " + obj.getName() );
			}
			
			if ( gameTime > retrofitTimeout )
			{
				retrofitId = 0;
				if ( data.log )
				print("Retrofit timeout in " + system.toObject().getName() );
			}
		}
		
		if ( commandShip.isValid() && commandShip.getOwner() is emp )
		{
			switch ( state )
			{
			case SysIdle:
				IdleState( emp, data );
				break;
			case SysBuild:
				BuildState( emp, data );
				break;
			case SysDefend:
				DefendState( emp, data );
				break;
			case SysFleet:
				FleetState( emp, data );
				break;
			case SysEnd:
				if ( data.log )
				print("System manager terminating for " + system.toObject().getName());
				
				system.toObject().setStat( emp, str_RemnantSys, 0.f );
				ret = true;
				break;
			}
		}
		else
		{
			if ( commandShip.isValid() )
				commandShip.destroy( true );
				
			data.IncreaseAnger();
			if ( data.log )
			print( system.toObject().getName() + " lost" );
			ret = true;
		}
		
		return ret;
	}
};

void MatterCreation( Event@ evt, float Amount )
{
	float produceTotal = Amount * evt.time;
	float produce;
	bool fullM = false, fullE = false;
	
	State@ metal = evt.obj.getState(str_Metals);
	State@ elect = evt.obj.getState(str_Elects);
	State@ advs = evt.obj.getState(str_AdvParts);
	State@ fuel = evt.obj.getState(str_Fuel);
	State@ ammo = evt.obj.getState(str_Ammo);

	produce = min( metal.getFreeSpace(), produceTotal * 0.5f );
	if ( produce > 0.f )
	{
		metal.add( produce, evt.obj );
		produceTotal -= produce;
	}
	else
		fullM = true;

	produce = min( elect.getFreeSpace(), produceTotal * 0.5f );
	if ( produce > 0.f )
	{
		elect.add( produce, evt.obj );
		produceTotal -= produce;
	}
	else
		fullE = true;
	
	produce = min( advs.getFreeSpace(), produceTotal );
	if ( produce > 0.f )
	{
		advs.add( produce, evt.obj );
		produceTotal -= produce;
	}
	
	produce = min( fuel.getFreeSpace(), produceTotal );
	if ( produce > 0.f )
	{
		fuel.add( produce, evt.obj );
		produceTotal -= produce;
	}
	
	produce = min( ammo.getFreeSpace(), produceTotal );
	if ( produce > 0.f )
	{
		ammo.add( produce, evt.obj );
		produceTotal -= produce;
	}	
	
	if ( !fullM && produceTotal > 0.1f )
	{
		produce = min( metal.getFreeSpace(), produceTotal );
		metal.add( produce, evt.obj );
		produceTotal -= produce;
	}

	if ( !fullE && produceTotal > 0.1f )
	{
		produce = min( elect.getFreeSpace(), produceTotal );
		elect.add( produce, evt.obj );
	}
}
// }}}

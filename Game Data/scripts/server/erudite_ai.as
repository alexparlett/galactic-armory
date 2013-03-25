#include "/include/empire_lib.as"

import void terraForm(string@ sID, float Oid) from "GAImprovements";

/* {{{ Constants and Initialization */
bool initialized = false;
void init_erudite_ai() {
	if(!initialized) {
		// Warn if there's a data mismatch
		if (uint(PV_COUNT) != varDefaults.length())
			error("Personality mismatch: "+varDefaults.length()+" defaults but "+uint(PV_COUNT)+" variables");
		if (uint(PV_COUNT) != varNames.length())
			error("Personality mismatch: "+varNames.length()+" names but "+uint(PV_COUNT)+" variables");

		// Initialize data
		loadDefaults(false);
		loadPersonalities();
		initialized = true;
	}
	
	print("Erudite AI Initialized");
}

void prep_erudite_ai_defaults(Empire@ emp) {
}

const string@ actShortWorkWeek = "work_low", actForcedLabor = "work_forced",
	  actTaxBreak = "tax_break", strEthics = "ethics", strEcoMode = "eco_mode";
const string@ strOre = "Ore", strH3 = "H3";	  
const string@ strTradeMode = "TradeMode";
const string@ strShipYard = "ShipYard", strSpacePort = "SpacePort";
const string@ strFuel = "Fuel", strStrength = "str";
const string@ strDifficulty = "Difficulty", strCheats = "Cheats";
const string@ strPlanet = "Planet";
const string@ strExternalResearch = "ExtRes";
const string@ strPeaceTreaty = "peace";
const string@ strAIAvoid = "AIAvoid";
const string@ strIndifferent = "forever_indifferent";

const string@ strManaged = "Managed";
const string@ strExpansion = "Expansion";

const string@ strPlanetWeapon1 = "PlanetCannon", strPlanetWeapon2 = "PlanetMissile", strPlanetWeapon3 = "PlanetLaser", strPlanetWeapon4 = "PlanetPC", strPlanetWeapon5 = "PlanetDefenseNetwork";

const string@ strPlanetShields = "PlanetShields";

// Specialised object flags
ObjectFlag objWaiting = objUser07;
ObjectFlag objImprovement = objUser03;

// Improvement strings
const string@ strTerraform = "Terraform";

const float minCheatingResources = 0.f;

/* }}} */
/* {{{ Personalities */
enum PersonalityVariable {
	PV_ScoutBuildWeight,
	PV_ScoutExploredWeight,

	PV_ContextNeglectWeight,
	PV_ContextFrontlineMaxDist,

	PV_PlanetsStrength,
	PV_FighterChance,
	PV_EnemyRatioIgnore,

	PV_RemnantWeight,
	PV_MaxFleetDist,
	PV_FleetPatrolInterval,
	PV_FleetCampaignInterval,
	PV_FleetEradicateInterval,
	PV_FleetDefendDist,
	PV_FleetPatrolDist,
	PV_FleetAttackDist,
	PV_FleetAttackRatio,
	PV_FleetRemnantDist,
	PV_FleetRemnantRatio,
	PV_FleetRetreatRatio,
	PV_FleetMopupRatio,
	PV_FleetDefendMinRatio,
	PV_FleetMaxRetrofitting,

	PV_ScalingCurve,
	PV_AlwaysSurplus,
	PV_BudgetSurplusMultiplier,

	PV_ResearchPriorityChance,
	PV_ResearchTargetDelay,
	PV_ResearchTargetChance,

	PV_PeaceRatio,
	PV_MilitaryBlock,
	PV_IgnoreMilitaryScale,
	PV_NotableEnemyRatio,

	PV_TradeMaxRate,
	PV_TradeMaxStored,
	PV_TradeMaxDuration,

	PV_TradeLowRatio,
	PV_TradeHighRatio,

	PV_ProposalMinDuration,
	PV_ProposalMaxDuration,
	PV_ProposalMinInterval,
	PV_ProposalMaxInterval,
	PV_ProposalMinTimeout,
	PV_ProposalMaxTimeout,
	PV_ProposalMinCounter,
	PV_ProposalMaxCounter,

	PV_ConsiderWarStrengthRatio,
	PV_ConsiderBribeStrengthRatio,
	PV_ConsiderObliterateStrengthRatio,

	PV_BoredomFactor,
	PV_BoredomNoBribes,

	PV_SystemMaxRetrofitting,

	PV_COUNT
};

float[] varDefaults = {
	1.f, //ScoutBuildWeight
	0.3f, //ScoutExploredWeight

	0.f, //ContextNeglectWeight
	60000.f * 60000.f, //ContextFrontlineMaxDist
	
	32.f, //PlanetsStrength
	0.25f, //FighterChance
	1.5f, //EnemyRatioIgnore

	7.f, //RemnantWeight
	30000.f * 30000.f, //MaxFleetDist
	6.f * 60.f, //FleetPatrolInterval
	4.f * 60.f, //FleetCampaignInterval
	4.f * 60.f, //FleetEradicateInterval
	100000.f * 100000.f, //FleetDefendDist
	75000.f * 75000.f, //FleetPatrolDist
	80000.f * 80000.f, //FleetAttackDist
	2.0f, //FleetAttackRatio
	65000.f * 65000.f, //FleetRemnantDist
	1.0f, //FleetRemnantRatio
	0.5f, //FleetRetreatRatio
	6.0f, //FleetMopupRatio
	0.25f, //FleetDefendMinRatio
	2.f, //FleetMaxRetrofitting

	1.3f, //ScalingCurve
	500.f * 1000.f, //AlwaysSurplus
	2.f, //BudgetSurplusMultiplier

	0.1f, //ResearchPriorityChance
	30.f * 60.f, //ResearchTargetDelay
	0.4f, //ResearchTargetChance

	10.f, //PeaceRatio
	60.f * 12.f, //MilitaryBlock
	2.f, //IgnoreMilitaryScale
	0.8f, //NotableEnemyRatio

	0.6f, //TradeMaxRate
	0.8f, //TradeMaxStored
	20.f * 60.f, //TradeMaxDuration

	0.8f, //TradeLowRatio
	1.2f, //TradeHighRatio

	2.f * 60.f, //ProposalMinDuration
	15.f * 60.f, //ProposalMaxDuration
	4.f * 60.f, //ProposalMinInterval
	10.f * 60.f, //ProposalMaxInterval
	3.f * 60.f, //ProposalMinTimeout
	8.f * 60.f, //ProposalMaxTimeout
	0.5f * 60.f, //ProposalMinCounter
	2.5f * 60.f, //ProposalMaxCounter

	2.0f, //ConsiderWarStrengthRatio
	0.5f, //ConsiderBribeStrengthRatio
	4.0f, //ConsiderObliterateStrengthRatio

	1.05f, //BoredomFactor
	4.0f,  //BoredomNoBribes

	1.f //SystemMaxRetrofitting
};

string[] varNames = {
	"ScoutBuildWeight",
	"ScoutExploredWeight",

	"ContextNeglectWeight",
	"ContextFrontlineMaxDist",

	"PlanetsStrength",
	"FighterChance",
	"EnemyRatioIgnore",

	"RemnantWeight",
	"MaxFleetDist",
	"FleetPatrolInterval",
	"FleetCampaignInterval",
	"FleetEradicateInterval",
	"FleetDefendDist",
	"FleetPatrolDist",
	"FleetAttackDist",
	"FleetAttackRatio",
	"FleetRemnantDist",
	"FleetRemnantRatio",
	"FleetRetreatRatio",
	"FleetMopupRatio",
	"FleetDefendMinRatio",
	"FleetMaxRetrofitting",

	"ScalingCurve",
	"AlwaysSurplus",
	"BudgetSurplusMultiplier",

	"ResearchPriorityChance",
	"ResearchTargetDelay",
	"ResearchTargetChance",

	"PeaceRatio",
	"MilitaryBlock",
	"IgnoreMilitaryScale",
	"NotableEnemyRatio",

	"TradeMaxRate",
	"TradeMaxStored",
	"TradeMaxDuration",

	"TradeLowRatio",
	"TradeHighRatio",

	"ProposalMinDuration",
	"ProposalMaxDuration",
	"ProposalMinInterval",
	"ProposalMaxInterval",
	"ProposalMinTimeout",
	"ProposalMaxTimeout",
	"ProposalMinCounter",
	"ProposalMaxCounter",

	"ConsiderWarStrengthRatio",
	"ConsiderBribeStrengthRatio",
	"ConsiderObliterateStrengthRatio",

	"BoredomFactor",
	"BoredomNoBribes",

	"SystemMaxRetrofitting"
};

string@ raceName;
string@ raceDescription;

enum PersonalityFlag {
	PF_COUNT,
};

bool[] flagDefaults = {
};

string[] flagNames = {
};

enum PersonalityString {
	PS_ShipSet,
	PS_Weapon1,
	PS_Weapon2,
	PS_Weapon3,
	PS_Weapon4,
	PS_Weapon5,
	PS_COUNT,
};

string[] stringDefaults = {
	"",
	"PlanetCannon",
	"PlanetMissile",
	"PlanetLaser",
	"PlanetPC",
	"PlanetDefenseNetwork",
};

string[] stringNames = {
	"ShipSet",
	"Weapon1",	
	"Weapon2",	
	"Weapon3",
	"Weapon4",
	"Weapon5",
	
};

enum PersonalityList {
	PL_Traits,

	PL_ConstructionTechs,
	PL_ResearchTechs,
	PL_PeacePriorityTechs,
	PL_WarPriorityTechs,
	PL_LinkTechs,
	PL_LinkFromTechs,

	PL_RepleacableBuildings,

	PL_COUNT,
};

string[] listNames = {
	"Traits",

	"ConstructionTechs",
	"ResearchTechs",
	"PeacePriorityTechs",
	"WarPriorityTechs",
	"LinkTechs",
	"LinkFromTechs",

	"ReplaceableBuildings"
};

enum ListType {
	LT_String,
	LT_Float,
}

ListType[] listTypes = {
	LT_String, //Traits

	LT_String, //ConstructionTechs
	LT_String, //ResearchTechs
	LT_String, //PeacePriorityTechs
	LT_String, //WarPriorityTechs
	LT_String, //LinkTechs
	LT_String, //LinkFromTechs

	LT_String, //RelplaceableBuildings
};

/* {{{ Generic list type */
interface List {
	uint length();

	void clear();
	void resize(uint num);
	void set(uint i, string@ str);
	void add(string@ str);
	string@ get(uint i);
};

class StringList : List {
	string@[] list;

	void resize(uint num) {
		list.resize(num);
	}

	void clear() {
		list.resize(0);
	}

	void set(uint i, string@ str) {
		@list[i] = str;
	}

	void add(string@ str) {
		uint n = list.length();
		list.resize(n+1);
		@list[n] = str;
	}

	string@ opIndex(uint i) {
		return list[i];
	}

	string@ get(uint i) {
		return list[i];
	}

	uint length() {
		return list.length();
	}
}

class FloatList : List {
	float[] list;

	void resize(uint num) {
		list.resize(num);
	}

	void clear() {
		list.resize(0);
	}

	void set(uint i, string@ str) {
		list[i] = s_to_f(str);
	}

	void add(string@ str) {
		add(s_to_f(str));
	}

	void add(float val) {
		uint n = list.length();
		list.resize(n+1);
		list[n] = val;
	}

	float opIndex(uint i) {
		return list[i];
	}

	string@ get(uint i) {
		return ftos_nice(list[i]);
	}

	uint length() {
		return list.length();
	}
}

List@ makeList(ListType type) {
	switch (type) {
		case LT_String:
			return StringList();
		case LT_Float:
			return FloatList();
	}
	return null;
}
/* }}} */

class Personality {
	uint id;

	Personality() {
		id = 0;
		initVars();
		initLists();
	}

	/* {{{ Variables */
	float[] values;
	string@[] strValues;

	float opIndex(PersonalityVariable var) {
		return values[uint(var)];
	}

	string@ opIndex(PersonalityString str) {
		return strValues[uint(str)];
	}

	void initVars() {
		values.resize(PV_COUNT);
		for (uint i = 0; i < uint(PV_COUNT); ++i)
			values[i] = varDefaults[i];

		strValues.resize(PS_COUNT);
		for (uint i = 0; i < uint(PS_COUNT); ++i)
			@strValues[i] = stringDefaults[i];
	}
	/* }}} */
	/* {{{ Flags */
	bool[] flags;

	bool opIndex(PersonalityFlag var) {
		if (uint(var) < flags.length())
			return flags[uint(var)];
		return false;
	}

	void initFlags() {
		flags.resize(PF_COUNT);
		for (uint i = 0; i < uint(PF_COUNT); ++i)
			flags[i] = flagDefaults[i];
	}
	/* }}} */
	/* {{{ Lists */
	List@[] lists;

	List@ opIndex(PersonalityList var) {
		if (uint(var) < lists.length())
			return lists[uint(var)];
		return null;
	}

	void initLists() {
		lists.resize(PL_COUNT);
		for (uint i = 0; i < uint(PL_COUNT); ++i)
			@lists[i] = makeList(listTypes[i]);

		// Construction technologies
		StringList@ ct = cast<StringList>(this[PL_ConstructionTechs]);
		ct.add("MegaConstruction");
		ct.add("ShipConstruction");
		ct.add("Metallurgy");
		ct.add("Economics");

		// Technologies to research normally
		StringList@ techs = cast<StringList>(this[PL_ResearchTechs]);
		techs.add("Science");
		techs.add("EnergyPhysics");
		techs.add("ParticlePhysics");
		techs.add("Materials");
		techs.add("Metallurgy");
		techs.add("Chemistry");
		techs.add("Economics");
		techs.add("Biology");
		techs.add("Sociology");
		techs.add("ProjWeapons");
		techs.add("Engines");
		techs.add("ShipConstruction");
		techs.add("MegaConstruction");
		techs.add("ShipSystems");
		techs.add("Cargo");
		techs.add("Armor");
		techs.add("Nanotech");
		techs.add("Gravitics");
		techs.add("WarpPhysics");

		// Technologies that have priority in peacetime
		StringList@ peaceTechs = cast<StringList>(this[PL_PeacePriorityTechs]);
		peaceTechs.add("Science");
		peaceTechs.add("Metallurgy");
		peaceTechs.add("Economics");
		peaceTechs.add("Biology");
		peaceTechs.add("Sociology");

		// Technologies that have priority in wartime
		StringList@ warTechs = cast<StringList>(this[PL_WarPriorityTechs]);
		warTechs.add("ProjWeapons");
		warTechs.add("Armor");
		warTechs.add("Materials");

		// Link techs
		StringList@ toTechs = cast<StringList>(this[PL_LinkTechs]);
		StringList@ fromTechs = cast<StringList>(this[PL_LinkFromTechs]);

		toTechs.add("Armor"); fromTechs.add("ProjWeapons");
		toTechs.add("Chemistry"); fromTechs.add("Science");
		toTechs.add("MegaConstruction"); fromTechs.add("ShipConstruction");
		toTechs.add("Biology"); fromTechs.add("Science");
		toTechs.add("Sociology"); fromTechs.add("Biology");
		toTechs.add("Nanotech"); fromTechs.add("Chemistry");

		// Buildings that can mostly be replaced safely
		StringList@ replaceable = cast<StringList>(this[PL_RepleacableBuildings]);
		replaceable.add("MetalMine");
		replaceable.add("ElectronicFact");
		replaceable.add("AdvPartFact");
		replaceable.add("GoodsFactory");
		replaceable.add("LuxsFactory");
	}
	/* }}} */
	/* {{{ Designs */
	ShipDesign@[] startingDesigns;
	ShipDesign@[] unlockedDesigns;

	// {{{ Add default designs to sets
	void addDefaultDesigns() {
		// Add starting designs
		uint realLayoutCount = 0;
		uint designCount = defaultDesigns.length();
		startingDesigns.resize(designCount);
		for(uint i = 0; i < designCount; ++i)
			if(defaultDesigns[i].forAI)
				@startingDesigns[realLayoutCount++] = @defaultDesigns[i];
		startingDesigns.resize(realLayoutCount);

		// Add unlocked designs
		realLayoutCount = 0;
		designCount = createDesigns.length();
		unlockedDesigns.resize(designCount);
		for(uint i = 0; i < designCount; ++i)
			if(createDesigns[i].forAI)
				@unlockedDesigns[realLayoutCount++] = @createDesigns[i];
		unlockedDesigns.resize(realLayoutCount);
	}
	// }}}
	/* {{{ Get design by class name */
	ShipDesign@ getDesign(string@ name) {
		ShipDesign@ design = null;

		// Look through starting designs
		uint cnt = startingDesigns.length();
		for (uint i = 0; i < cnt; ++i) {
			if (startingDesigns[i].className == name)
				@design = startingDesigns[i];
		}

		// Look through unlocked designs
		cnt = unlockedDesigns.length();
		for (uint i = 0; i < cnt; ++i) {
			if (unlockedDesigns[i].className == name)
				@design = unlockedDesigns[i];
		}

		return design;
	}
	/* }}} */
	/* }}} */
	/* {{{ XML Loading */
	bool load(XMLReader@ xml, uint ID) {
		if (xml is null)
			return false;

		id = ID;
		while(xml.advance()) {
			string@ name = xml.getNodeName();
			switch(xml.getNodeType()) {
				case XN_Element:
					if (name == "var") {
						loadVariable(xml);
					}
					else if(name == "race") {
						loadRaceDesc(xml);
					}
					else if (name == "list") {
						loadList(xml);
					}
					else if (name == "flag") {
						loadFlag(xml);
					}
					else if (name == "layouts") {
						loadLayouts(xml);
					}
				break;
				case XN_Element_End:
					if (name == "personality")
						return true;
				break;
			}
		}
		return true;
	}

	void loadVariable(XMLReader@ xml) {
		// Look for the correct variable enum to use
		string@ varName = xml.getAttributeValue("id");

		// Check for float variables
		uint var = uint(PV_COUNT);
		for (uint i = 0; i < uint(PV_COUNT); ++i) {
			if( varNames[i] == varName) {
				var = i;
				break;
			}
		}

		if (var < uint(PV_COUNT)) {
			string@ value = xml.getAttributeValue("value");
			if (value == "")
				values[var] = sqr(s_to_f(xml.getAttributeValue("value_sq")));
			else
				values[var] = s_to_f(value);
			return;
		}

		// Check for string variables
		var = uint(PS_COUNT);
		for (uint i = 0; i < uint(PS_COUNT); ++i) {
			if( stringNames[i] == varName) {
				var = i;
				break;
			}
		}

		if (var < uint(PS_COUNT)) {
			@strValues[var] = xml.getAttributeValue("value");
			return;
		}

		warning("Error: Unknown personality variable "+varName);
	}
	
	void loadRaceDesc(XMLReader@ xml) {
		@raceName = xml.getAttributeValue("name");
		@raceDescription = xml.getAttributeValue("desc");
	}

	void loadFlag(XMLReader@ xml) {
		// Look for the correct flag enum to use
		string@ flagName = xml.getAttributeValue("id");
		uint flag = uint(PF_COUNT);
		for (uint i = 0; i < uint(PF_COUNT); ++i) {
			if( flagNames[i] == flagName) {
				flag = i;
				break;
			}
		}

		if (flag >= uint(PF_COUNT)) {
			warning("Error: Unknown personality flag "+flagName);
			return;
		}

		// Load variable
		flags[flag] = xml.getAttributeValue("value") == "true";
	}

	void loadList(XMLReader@ xml) {
		// Look for the correct list enum to use
		string@ listName = xml.getAttributeValue("id");
		List@ list = null;
		for (uint i = 0; i < uint(PL_COUNT); ++i) {
			if( listNames[i] == listName) {
				@list = this[PersonalityList(i)];
				break;
			}
		}

		if (list is null) {
			warning("Error: Unknown personality list "+listName);
			return;
		}

		// Check the mode
		string@ listMode = xml.getAttributeValue("mode");
		if (listMode != "append") {
			list.clear();
		}

		// Load the list
		string@ text = null;
		while(xml.advance()) {
			string@ name = xml.getNodeName();

			switch(xml.getNodeType()) {
				case XN_Text:
					@text = xml.getNodeData();
				break;

				case XN_Element_End:
					if (name == "li") {
						if (text !is null)
							list.add(text);
					}
					if (name == "list") {
						return;
					}
				break;
			}
		}
	}

	void loadLayouts(XMLReader@ xml) {
		while(xml.advance()) {
			string@ name = xml.getNodeName();

			switch(xml.getNodeType()) {
				case XN_Element:
					if(name == "default") {
						ShipDesign@ design = loadDesignDescriptor(xml);
						if(design is null)
							continue;

						int l = startingDesigns.length();
						startingDesigns.resize(l + 1);
						@startingDesigns[l] = @design;
					}
					else if(name == "design") {
						ShipDesign@ design = loadDesignDescriptor(xml);
						if(design is null)
							continue;
						
						int l = unlockedDesigns.length();
						unlockedDesigns.resize(l + 1);
						@unlockedDesigns[l] = @design;
					}
					else if (name == "obsolete") {
						string@ design = localize(xml.getAttributeValue("name"));

						uint designCount = startingDesigns.length();
						for (uint i = 0; i < designCount; ++i) {
							if (startingDesigns[i].className == design) {
								startingDesigns.erase(i);
								--i; --designCount;
							}
						}
					}
				break;

				case XN_Element_End:
					if (name == "layouts")
						return;
				break;
			}
		}
	}
	/* }}} */
};

Personality@[] erudite_personalities;

void loadPersonalities() {
	// Load all personalities
	for (uint i = 0; i < persDesc.length(); ++i) {
		if (persDesc[i].forAI != "erudite_ai")
			continue;

		Personality@ pers = Personality();
		pers.addDefaultDesigns();

		uint n = erudite_personalities.length();
		if (pers.load(XMLReader(persDesc[i].file), i)) {
			erudite_personalities.resize(n+1);
			@erudite_personalities[n] = pers;
		}
	}

	// Check if we should add a default personality
	if (erudite_personalities.length() == 0) {
		erudite_personalities.resize(1);
		@erudite_personalities[0] = Personality();
	}
}

Personality@ getPersonality(uint id) {
	uint cnt = erudite_personalities.length();
	for (uint i = 0; i < cnt; ++i) {
		if (erudite_personalities[i].id == id)
			return erudite_personalities[i];
	}
	return erudite_personalities[0];
}

Personality@ getRandomPersonality() {
	return erudite_personalities[rand(erudite_personalities.length() - 1)];
}

/* }}} */
/* {{{ Ship Design */
class ShipDesignLine {
	ShipDesign@ design;
	const HullLayout@ layout;
	float scaleMultiplier;
	float scale;

	ShipDesignLine(ShipDesign@ Design) {
		@design = Design;
		scaleMultiplier = 1.f;
		scale = design.scale;
	}

	bool setScaleMultiplier(Empire@ emp, float mult) {
		if (scaleMultiplier == mult)
			return false;
		if (!design.autoscale)
			return false;
		scaleMultiplier = mult;
		generate(emp);
		return true;
	}

	const HullLayout@ get(Empire@ emp) {
		if (layout !is null) {
			if (design.scalefrom > 0 && sqr(layout.scale) < design.scale)
				return null;
			@layout = layout.getLatestVersion();
			return layout;
		}
		@layout = emp.getShipLayout(design.className);
		scale = sqr(layout.scale);
		scaleMultiplier = scale / design.scale;
		return layout;
	}

	const HullLayout@ generate(Empire@ emp) {
		// Get the correct scaling factor
		if (design.scalefrom > 0)
			scale = design.scalefrom * scaleMultiplier;
		else
			scale = design.scale * scaleMultiplier;

		// Round off the scale
		if (scale < 16)
			scale = round(scale * 100.f) / 100.f;
		else
			scale = round(scale);

		// Demo scale limitation
		if (isDemo && scale > 200)
			scale = 200;

		if (layout !is null) {
			@layout = layout.getLatestVersion();
			if (layout.obsolete || design.className != layout.getName())
				return layout;
		}
		@layout = design.generateDesign(emp, true, scale, design.className);
		return layout;
	}

	void save(XMLWriter@ xml) {
		if(design !is null)
			xml.addElement("d", true, "n", design.className, "s", f_to_s(scale), "m", f_to_s(scaleMultiplier));
	}

	ShipDesignLine(EmpireAIData@ data, Empire@ emp, XMLReader@ xml) {
		int i = s_to_i(xml.getAttributeValue("i"));
		while (xml.advance()) {
			string@ name = xml.getNodeName();
			switch(xml.getNodeType()) {
				case XN_Element:
					if (name == "d") {
						string@ name = xml.getAttributeValue("n");
						scale = s_to_f(xml.getAttributeValue("s"));
						scaleMultiplier = s_to_f(xml.getAttributeValue("m"));

						@layout = emp.getShipLayout(name);
						@design = data.pers.getDesign(name);
					}
				break;
				case XN_Element_End:
					if (name == "design")
						return;
				break;
			}
		}
	}
};
/* }}} */
/* {{{ Timers */
/* {{{ Timer class */
class Timer {
	float length;
	float value;

	Timer() {
		length = 0;
		value = 0;
	}

	Timer(float Length) {
		length = Length;
		value = 0;
	}

	Timer(float Length, bool start) {
		length = Length;
		value = 0;
	}

	void setLength(float Length) {
		float prevLength = length;
		length = Length;
		value = length - min(prevLength - value, length);
	}

	float getLength() {
		return length;
	}

	float getProgress() {
		if (length == 0)
			return 1.f;
		return value / length;
	}

	void setRemaining(float remaining) {
		value = length - remaining;
	}

	float getRemaining() {
		return length - value;
	}

	void trigger() {
		value = length;
	}

	void randomize() {
		value = length * randomf(1.f);
	}

	void reset() {
		value = 0;
	}

	bool tick(float time) {
		value += time;
		if (value >= length) {
			value = 0;
			return true;
		}
		return false;
	}
};
/* }}} */

enum GlobalTimer {
	GT_EconUpdate,
	GT_CheatEconomy,
	GT_BuiltShips,
	GT_LayoutScaling,
	GT_DesignShipsBase,
	GT_BoredomTimer,
	GT_ResearchTick,

	GT_COUNT,
};

float[] timerLengths = {
	1.f,   // GT_EconUpdate
	4.f,   // GT_CheatEconomy
	1.f,   // GT_BuiltShips
	1.f,   // GT_LayoutScaling
	120.f, // GT_DesignShipsBase
	60.f,  // GT_BoredomTimer
	1.f,   // GT_ResearchTick
};
/* }}} */
/* {{{ State Enumerations */
enum FleetState {
	FS_Muster,
	FS_Patrol,
	FS_Defend,
	FS_Campaign,
	FS_Eradicate,

	FS_COUNT,
	FS_DEAD,
};

enum WarStatus {
	WS_Losing,
	WS_Normal,
	WS_Winning, // Winning
	WS_Dominating,

	WS_COUNT,
};

enum ObjectPriority {
	OP_Ignored = 0,
	OP_Low = 1,
	OP_Normal = 2,
	OP_High = 3,

	OP_Focus = 5,
	OP_Critical = 9,
};
/* }}} */
/* {{{ Data Enumerations */
enum GlobalData {
	GD_Strength,
	GD_Economy,
	GD_ScaleMultiplier,
	GD_TotalEnemyStrength,
	GD_TotalEnemies,
	GD_Boredom,
	GD_TotalAlliedStrength,
	GD_TotalAllies,
	GD_TotalNeutralStrength,
	GD_TotalNeutrals,

	GD_COUNT,
};

enum GlobalSet {
	GS_ExpansionSystems,
	GS_PatrolSystems,

	GS_COUNT,
};

enum ResourceType {
	RT_Metals,
	RT_Electronics,
	RT_AdvParts,
	RT_Food,
	RT_Luxuries,
	RT_Goods,
	RT_Fuel,
	RT_Ammo,

	RT_COUNT,
	RT_None,
};

enum ResourceFlag {
	rf_none = 0,
	rf_mtl = 1,
	rf_elc = 2,
	rf_adv = 4,
	rf_fud = 8,
	rf_lux = 16,
	rf_gud = 32,
	rf_ful = 64,
	rf_amo = 128,
};

enum PlanetResource {
	PR_Metals,
	PR_Electronics,
	PR_AdvParts,
	PR_Food,
	PR_Labor,
	PR_Fuel,
	PR_Ammo,

	PR_Total,
	PR_COUNT,
	PR_None,
}

enum TradeMode {
	TM_All,
	TM_ImportOnly,
	TM_ExportOnly,
	TM_Nothing,
};

/* {{{ Resource type / name conversion */
string@ strMetals = "Metals", strElectronics = "Electronics";
string@ strAdvParts = "AdvParts", strFood = "Food";
string@ strLuxuries = "Luxs", strGoods = "Guds";
string@ strFuels = "Fuel", strAmmo = "Ammo";

// Convert between construction and global resource
ResourceType getResourceType(PlanetResource res) {
	if (res < 4 || res > 4)
		return ResourceType(res);
	return RT_None;
}

PlanetResource getResourceType(ResourceType res) {
	if (res < 4 || res > 5)
		return PlanetResource(res);
	return PR_None;
}

// Type to name
string@ getResourceName(ResourceType type) {
	switch (type) {
		case RT_Metals: return strMetals;
		case RT_Electronics: return strElectronics;
		case RT_AdvParts: return strAdvParts;
		case RT_Food: return strFood;
		case RT_Luxuries: return strLuxuries;
		case RT_Goods: return strGoods;
		case RT_Fuel: return strFuels;
		case RT_Ammo: return strAmmo;
	}
	return "";
}

// Name to type
ResourceType getResourceType(const string& name) {
	if (name == strMetals)
		return RT_Metals;
	if (name == strElectronics)
		return RT_Electronics;
	if (name == strAdvParts)
		return RT_AdvParts;
	if (name == strFood)
		return RT_Food;
	if (name == strLuxuries)
		return RT_Luxuries;
	if (name == strGoods)
		return RT_Goods;
	if (name == strFuel)
		return RT_Fuel;
	if (name == strAmmo)
		return RT_Ammo;
	return RT_Metals;
}

// Get relative modifier for a resource
const float[] resourceMod = {1.f, 5.f, 7.f, 23.f, 3.f, 0.3f, 1.f, 7.f};
float getResourceMod(ResourceType type) {
	return resourceMod[uint(type)];
}
/* }}} */

enum ResourceData {
	RD_Stored,
	RD_Income,
	RD_Expense,
	RD_Demand,
	RD_Net,

	RD_COUNT,
};

enum ResourceStatus {
	RS_Critical,
	RS_Low,
	RS_Enough,
	RS_Surplus,
};
/* }}} */
/* {{{ Utility functions */
int getUncolonizedPlanets(System@ sys) {
	Object@ obj = sys;
	Empire@ space = getEmpireByID(-1);

	if (obj is null)
		return 0;

	int totalPlanets = obj.getStat(space, str_planets);
	uint empCnt = getEmpireCount();
	for (uint i = 0; i < empCnt; ++i) {
		Empire@ emp = getEmpire(i);
		if (!emp.isValid() || emp.ID < 0)
			continue;

		totalPlanets -= obj.getStat(emp, str_planets);
	}

	return totalPlanets;
}

float getEnemyStrength(System@ sys, Empire@ emp, bool includeSpecial) {
	Object@ sysObj = sys;
	float enemyStrength = 0;
	uint empCnt = getEmpireCount();

	if (sysObj is null)
		return 0;
	for (uint i = 0; i < empCnt; ++i) {
		Empire@ otherEmp = getEmpire(i);
		if (!otherEmp.isValid() || (emp.ID < 0 && !includeSpecial) || emp is otherEmp)
			continue;

		if (sys.hasMilitary(otherEmp) && emp.isEnemy(otherEmp))
			enemyStrength += sysObj.getStrength(otherEmp);
	}

	return enemyStrength;
}
/* }}} */
/* {{{ Built ship actions */
interface BuiltShipAction {
	int getID();
	BuiltShipAction@ duplicate(int ID);
	bool execute(EmpireAIData@ data, Object@ obj, OrderList& list);
	void save(XMLWriter@ xml);
};

interface BuiltShipCallback {
	void act(int ID);
};

class BuiltShipActor : BuiltShipCallback {
	BuiltShipAction@ action;
	EmpireAIData@ data;

	BuiltShipActor(EmpireAIData@ Data, BuiltShipAction@ Action) {
		@data = Data;
		@action = Action;
	}

	void act(int ID) {
		data.queue(action.duplicate(ID));
	}
};

class MoveBuiltShip : BuiltShipAction {
	Object@ moveTo;
	Object@ moveBack;
	int id;

	MoveBuiltShip(int ID, Object@ to) {
		id = ID;
		@moveTo = to;
		@moveBack = null;
	}

	MoveBuiltShip(int ID, Object@ to, Object@ back) {
		id = ID;
		@moveTo = to;
		@moveBack = back;
	}

	BuiltShipAction@ duplicate(int ID) {
		return MoveBuiltShip(ID, moveTo);
	}

	int getID() {
		return id;
	}

	bool execute(EmpireAIData@ data, Object@ obj, OrderList& list) {
		if (obj.getOwner() !is null && list.prepare(obj)) {
			list.giveGotoOrder(moveTo, false);
			if (moveBack !is null)
				list.giveGotoOrder(moveBack, true);
			list.prepare(null);
		}
		return true;
	}

	void save(XMLWriter@ xml) {
		xml.addElement("act", true, "t", "MoveBuiltShip",
				"i", i_to_s(id), "to", i_to_s(moveTo.uid),
				"back", i_to_s(moveBack is null ? -1 : moveBack.uid));
	}
};

class SysFleetBuiltShip : BuiltShipAction {
	int id;
	SystemController@ sys;

	SysFleetBuiltShip(int ID, SystemController@ ctrl) {
		id = ID;
		@sys = ctrl;
	}

	BuiltShipAction@ duplicate(int ID) {
		return SysFleetBuiltShip(ID, sys);
	}

	int getID() {
		return id;
	}

	bool execute(EmpireAIData@ data, Object@ obj, OrderList& list) {
		if (obj.getFlag(objWaiting))
			return false;

		HulledObj@ hulled = obj;
		if (hulled is null || hulled.getFleet() !is null)
			return true;

		if (obj.getOwner() !is null && list.prepare(obj)) {
			FleetController@ fleet = sys.closestFleet;
			if (fleet !is null && fleet.leader !is null && fleet.getDistanceFromSQ(sys.sys.toObject()) < data[PV_MaxFleetDist]) {
				list.joinFleet(fleet.leader);
			}
			else {
				list.makeFleet();
				Fleet@ fl = hulled.getFleet();
				if (fl is null)
					return true;
				data.addFleet(fl);
			}
			list.prepare(null);
		}
		return true;
	}

	void save(XMLWriter@ xml) {
		xml.addElement("act", true, "t", "SysFleetBuiltShip",
				"i", i_to_s(id), "sys", i_to_s(sys.sys.toObject().uid));
	}
};

BuiltShipAction@ loadBuiltShipAction(EmpireAIData@ data, Empire@ emp, XMLReader@ xml) {
	int i = s_to_i(xml.getAttributeValue("i"));
	while (xml.advance()) {
		string@ name = xml.getNodeName();
		switch(xml.getNodeType()) {
			case XN_Element:
				if (name == "act") {
					string@ type = xml.getAttributeValue("t");
					int id = s_to_i(xml.getAttributeValue("i"));

					if (type == "SysFleetBuiltShip") {
						int sysID = s_to_i(xml.getAttributeValue("sys"));
						System@ sys = getObjectByID(sysID);
						SystemController@ ctrl = data.getController(sys);

						if (ctrl is null)
							return null;

						return SysFleetBuiltShip(id, ctrl);
					}
					else if (type == "MoveBuiltShip") {
						int toID = s_to_i(xml.getAttributeValue("to"));
						int backID = s_to_i(xml.getAttributeValue("back"));

						Object@ to = getObjectByID(toID);
						if (to is null)
							return null;

						if (backID < 0) {
							return MoveBuiltShip(id, to);
						}
						else {
							Object@ back = getObjectByID(backID);
							return MoveBuiltShip(id, to, back);
						}
					}
				}
			break;
			case XN_Element_End:
				if (name == "action")
					return null;
			break;
		}
	}
	return null;
}

/* }}} */
/* {{{ System Sweeps */
interface SystemSweep {
	float call(const EmpireAIData@, Empire@, System@);
	bool complete(EmpireAIData@, Empire@, System@);
};

class SystemSweepCallback : SysSearchCallback {
	EmpireAIData@ data;
	Empire@ emp;
	SystemSweep@ sweep;

	SystemSweepCallback(EmpireAIData@ Data, Empire@ Emp) {
		@data = Data;
		@emp = Emp;
	}

	void setSweep(SystemSweep@ Sweep) {
		@sweep = Sweep;
	}

	float call(System@ sys, SysSearchSettings& settings, const SysStats& stats) {
		if (sweep !is null)
			return sweep.call(data, emp, sys);
		return 0.f;
	}

	bool complete(System@ best) {
		SystemSweep@ swp = sweep;
		if (swp !is null) {
			@sweep = null;
			return swp.complete(data, emp, best);
		}
		return false;
	}
}
/* }}} */
/* {{{ AI Controller */
class EmpireAIData {
	/* {{{ Class data */
	double[] globalData;
	set_int[] globalSets;
	double[] resourceData;
	ResourceStatus[] resourceStatus;
	ResourceType bottleneckResource;
	ResourceType surplusResource;
	Timer[] timers;

	Personality@ pers;
	ShipDesignLine@[] shipDesigns;
	BuiltShipAction@[] actions;
	int[] actions_ids;

	uint difficulty;
	bool cheating;
	float cheatFactor;
	float difficultyFactor;

	System@ homeSystem;
	Planet@ homePlanet;

	bool hasTicked;
	bool hasMood;
	bool hasCivilActs;
	bool hasActivity;
	bool hasDebt;	

	bool logging;
	bool logFleets;
	bool gotTrait;	

	set_int controlledSystems;
	SystemController@[] systemControllers;
	int sysFullNum;

	set_int controlledFleets;
	set_int patrolsTo;
	FleetController@[] fleetControllers;
	int fleetFullNum;

	RelationsManager@[] relations;
	bool peaceTime;
	int relFullNum;

	SysSearchSettings sss_sweep;
	SystemSweepCallback@ sss_cb;
	SystemSweep@[] systemSweeps;
	uint sweepFullNum;

	ResearchManager research;

	EmpireAIData(Empire@ emp) {
		// Initialize members
		init(emp);
	}

	void init(Empire@ emp) {
		// Initialize global data
		if (!initialized)
			init_erudite_ai();

		// Initialize variables
		hasTicked = false;
		hasMood = true;
		hasCivilActs = true;
		hasDebt = false;
		sysFullNum = 0;
		relFullNum = 0;
		fleetFullNum = 0;
		sweepFullNum = 0;
		peaceTime = true;
		hasActivity = false;
		bottleneckResource = RT_None;
		surplusResource = RT_None;
		logging = false;
		logFleets = false;

		difficulty = emp.getSetting(strDifficulty) + 1;
		cheating = emp.getSetting(strCheats) > 0;
		cheatFactor = pow(1.6f, difficulty);

		// For cheating AIs, difficulty only decides the
		// amount they cheat, it doesn't disable any logic
		if (cheating)
			difficulty = 6;
		difficultyFactor = difficulty / 4.f;

		// Initialize Data arrays
		globalData.resize(GD_COUNT);
		resourceData.resize(RT_COUNT * RD_COUNT);
		resourceStatus.resize(RT_COUNT);
		globalSets.resize(GS_COUNT);

		// Initialize timers
		timers.resize(GT_COUNT);
		for (uint i = 0; i < uint(GT_COUNT); ++i) {
			timers[i].setLength(timerLengths[i]);
			timers[i].trigger();
		}

		// Initialize globals
		setGlobal(GD_ScaleMultiplier, 1.f);
		setGlobal(GD_Boredom, 1.f);

		// Initialize system search
		@sss_cb = SystemSweepCallback(this, emp);
		sss_sweep.setCallback(sss_cb);

		// Pick a personality
		uint persID = uint(emp.getSetting("Personality"));
		if (persID < 1) {
			@pers = getRandomPersonality();
			emp.setSetting("Personality", float(pers.id));
		}
		else {
			@pers = getPersonality(persID - 1);
		}
		
		emp.setRaceName(raceName);
		emp.setRaceDescription(raceDescription);
		

		// Only set certain things at game start
		if (gameTime < 2.f) {
			// Set the right shipset
			string@ shipSet = this[PS_ShipSet];
			if (shipSet.length() == 0)
				emp.setRandomShipSet();
			else
				emp.setShipSet(shipSet);
			// Set up alternate weapons
			@strPlanetWeapon1 = this[PS_Weapon1];
			@strPlanetWeapon2 = this[PS_Weapon2];
			@strPlanetWeapon3 = this[PS_Weapon3];
			@strPlanetWeapon4 = this[PS_Weapon4];
			@strPlanetWeapon5 = this[PS_Weapon5];

			// Set traits
			if (getGameSetting("GAME_AI_TRAITS", 1.f) != 0) {
				StringList@ repl = cast<StringList@>(this[PL_Traits]);
				for (uint i = 0; i < repl.length(); ++i)
					emp.addTrait(repl.get(i));
			}
		}
	}
	/* }}} */
	/* {{{ Data querying */
	double getGlobal(GlobalData data) const {
		return globalData[uint(data)];
	}

	double opIndex(GlobalData data) const {
		return globalData[uint(data)];
	}

	float opIndex(PersonalityVariable var) const {
		return pers[var];
	}

	string@ opIndex(PersonalityString var) const {
		return pers[var];
	}

	List@ opIndex(PersonalityList var) const {
		return pers[var];
	}

	bool opIndex(PersonalityFlag var) const {
		return pers[var];
	}

	void setGlobal(GlobalData data, double val) {
		globalData[uint(data)] = val;
	}

	void incGlobal(GlobalData data) {
		++globalData[uint(data)];
	}

	void decGlobal(GlobalData data) {
		--globalData[uint(data)];
	}

	ResourceStatus getResStatus(ResourceType type) const {
		return resourceStatus[uint(type)];
	}

	void setResStatus(ResourceType type, ResourceStatus prior) {
		resourceStatus[uint(type)] = prior;
	}

	double getResData(ResourceType type, ResourceData data) const {
		return resourceData[uint(type) * RD_COUNT + uint(data)];
	}

	void setResData(ResourceType type, ResourceData data, double val) {
		resourceData[uint(type) * RD_COUNT + uint(data)] = val;
	}

	ResourceStatus getBottleneck(uint resources) const {
		int status = int(RS_Surplus);
		if (resources & rf_mtl != 0)
			status = min(status, int(getResStatus(RT_Metals)));
		if (resources & rf_elc != 0)
			status = min(status, int(getResStatus(RT_Electronics)));
		if (resources & rf_adv != 0)
			status = min(status, int(getResStatus(RT_AdvParts)));
		if (resources & rf_fud != 0)
			status = min(status, int(getResStatus(RT_Food)));
		if (resources & rf_gud != 0)
			status = min(status, int(getResStatus(RT_Goods)));
		if (resources & rf_lux != 0)
			status = min(status, int(getResStatus(RT_Luxuries)));
		if (resources & rf_ful != 0)
			status = min(status, int(getResStatus(RT_Fuel)));
		if (resources & rf_amo != 0)
			status = min(status, int(getResStatus(RT_Ammo)));
		return ResourceStatus(status);
	}

	ResourceStatus getConstructionBottleneck() const {
		return ResourceStatus(min(int(resourceStatus[RT_Metals]), min(int(resourceStatus[RT_Electronics]), min(int(resourceStatus[RT_AdvParts]), min(int(resourceStatus[RT_Fuel]), int(resourceStatus[RT_Ammo]))))));
	}

	bool setHas(GlobalSet set, int num) {
		return globalSets[uint(set)].exists(num);
	}

	void setAdd(GlobalSet set, int num) {
		globalSets[uint(set)].insert(num);
	}
	
	void setRemove(GlobalSet set, int num) {
		globalSets[uint(set)].erase(num);
	}
	/* }}} */
	/* {{{ Sweep handling */
	void addSweep(SystemSweep@ sweep) {
		uint pos = systemSweeps.length();
		systemSweeps.resize(pos + 1);
		@systemSweeps[pos] = @sweep;

		if (pos == 0) {
			sysFullNum = 0;
			sss_cb.setSweep(sweep);
			sss_sweep.findBestSystem();
		}
	}

	void runSweeps(Empire@ emp, float time) {
		// Make sure we have sweeps
		uint cnt = systemSweeps.length();
		if (cnt == 0)
			return;

		// Wait until the current sweep finishes
		if (!sss_sweep.searchFinished)
			return;

		// Complete the current sweep
		if (sss_cb.complete(sss_sweep.getBestSystem())) {
			if (sweepFullNum < cnt) {
				systemSweeps.erase(sweepFullNum);
				--cnt;
			}
		}

		// Check that we didn't lose our last sweep
		if (cnt == 0)
			return;

		// Find new sweep
		sweepFullNum = (sweepFullNum + 1) % cnt;
		SystemSweep@ sweep = systemSweeps[sweepFullNum];

		sss_cb.setSweep(sweep);
		sss_sweep.findBestSystem();
	}
	/* }}} */
	/* {{{ System controller handling */
	void addController(SystemController@ obj) {
		uint pos = systemControllers.length();
		systemControllers.resize(pos + 1);
		@systemControllers[pos] = @obj;
		if (obj.sys !is null) {
			Object@ sysObj = obj.sys;
			controlledSystems.insert(sysObj.uid);
		}
	}

	SystemController@ addSystem(System@ sys) {
		SystemController@ ctrl = SystemController(this, sys);
		addController(ctrl);
		return ctrl;
	}

	bool manages(System@ sys) {
		return controlledSystems.exists(sys.toObject().uid);
	}

	bool canSee(Empire@ emp, System@ sys) const {
		return sys.isVisibleTo(emp) || cheating;
	}

	void updateSystemControllers(Empire@ emp, float time) {
		int sysCnt = int(systemControllers.length());
		for (int i = sysCnt - 1; i >= 0; --i) {
			if ((i == sysFullNum && systemControllers[i].fullUpdate(this, emp))
					|| systemControllers[i].update(this, emp, time)) {
				Object@ sysObj = systemControllers[i].sys;
				sysObj.setStat(emp, strManaged, 0.f);
				controlledSystems.erase(sysObj.uid);
				systemControllers.erase(i);
			}
		}

		if (sysCnt > 0)
			sysFullNum = (sysFullNum + 1) % sysCnt;
		else
			sysFullNum = 0;
	}

	SystemController@ getController(System@ system) {
		if (!manages(system))
			return null;
		uint cnt = systemControllers.length();
		for (uint i = 0; i < cnt; ++i) {
			SystemController@ ctrl = systemControllers[i];
			if (ctrl.sys is system)
				return ctrl;
		}
		return null;
	}

	SystemController@ getClosestSystem(System@ system) {
		double minDist = 0;
		int minInd = -1;
		uint cnt = systemControllers.length();
		vector pos = system.toObject().getPosition();

		for (uint i = 0; i < cnt; ++i) {
			System@ sys = systemControllers[i].sys;
			if (sys is system)
				continue;

			double dist = sys.toObject().getPosition().getDistanceFromSQ(pos);
			if (dist < minDist || minDist == 0) {
				minInd = int(i);
				minDist = dist;
			}
		}

		if (minInd < 0)
			return null;
		return systemControllers[minInd];
	}

	SystemController@ getClosestSystem(vector pos) {
		double minDist = 0;
		int minInd = -1;
		uint cnt = systemControllers.length();

		for (uint i = 0; i < cnt; ++i) {
			System@ sys = systemControllers[i].sys;
			double dist = sys.toObject().getPosition().getDistanceFromSQ(pos);
			if (dist < minDist || minDist == 0) {
				minInd = int(i);
				minDist = dist;
			}
		}

		if (minInd < 0)
			return null;
		return systemControllers[minInd];
	}
	/* }}} */
	/* {{{ Fleet controller handling */
	void addController(FleetController@ obj) {
		uint pos = fleetControllers.length();
		fleetControllers.resize(pos + 1);
		@fleetControllers[pos] = @obj;

		if (obj.fleet !is null)
			controlledFleets.insert(obj.fleet.ID);
	}

	FleetController@ addFleet(Fleet@ fleet) {
		if (fleet is null)
			return null;
		if (manages(fleet))
			return null;

		FleetController@ ctrl = FleetController(fleet);
		addController(ctrl);
		return ctrl;
	}

	bool manages(Fleet@ fleet) {
		return controlledFleets.exists(fleet.ID);
	}

	void updateFleetControllers(Empire@ emp, float time) {
		int fleetCnt = int(fleetControllers.length());
		for (int i = fleetCnt - 1; i >= 0; --i) {
			if ((i == fleetFullNum && fleetControllers[i].fullUpdate(this, emp))
					|| fleetControllers[i].update(this, emp, time)) {
				if (fleetControllers[i].fleet !is null)
					controlledFleets.erase(fleetControllers[i].fleet.ID);
				fleetControllers.erase(i);
			}
		}

		if (fleetCnt > 0)
			fleetFullNum = (fleetFullNum + 1) % fleetCnt;
		else
			fleetFullNum = 0;
	}

	FleetController@ getController(Fleet@ fleet) {
		uint cnt = fleetControllers.length();
		for (uint i = 0; i < cnt; ++i) {
			FleetController@ ctrl = fleetControllers[i];
			if (ctrl.fleet is fleet)
				return ctrl;
		}
		return null;
	}

	FleetController@ getClosestFleet(vector pos) {
		double minDist = 0;
		int minInd = -1;
		uint cnt = fleetControllers.length();

		for (uint i = 0; i < cnt; ++i) {
			FleetController@ fleet = fleetControllers[i];
			if (fleet.leader is null)
				continue;
			double dist = fleet.leader.toObject().getPosition().getDistanceFromSQ(pos);
			if (dist < minDist || minDist == 0) {
				minInd = int(i);
				minDist = dist;
			}
		}

		if (minInd < 0)
			return null;
		return fleetControllers[minInd];
	}
	/* }}} */
	/* {{{ Built ship actions */
	void queue(BuiltShipAction@ action) {
		uint n = actions.length();
		actions.resize(n+1);
		@actions[n] = action;
		actions_ids.resize(n+1);
		actions_ids[n] = action.getID();
	}

	void checkActions() {
		uint cnt = actions.length();
		if(cnt == 0)
			return;
		OrderList list;
		for (int i = cnt - 1; i >= 0; --i) {
			Object@ obj = getObjectByID(actions_ids[i]);
			
			if(obj !is null) {
				if (actions[i].execute(this, obj, list)) {
					actions.erase(i);
					actions_ids.erase(i);
				}
			}
		}
	}
	/* }}} */
	/* {{{ Timer handling */
	bool tickTimer(GlobalTimer timer, float time) {
		return timers[uint(timer)].tick(time);
	}

	void triggerTimer(GlobalTimer timer) {
		timers[uint(timer)].trigger();
	}

	void setTimer(GlobalTimer timer, float time) {
		timers[uint(timer)].setRemaining(time);
	}
	/* }}} */
	/* {{{ Global Economy Handling */
	void collectEconomicData(Empire@ emp) {
		// Collect basic statistics
		double val = 0, income = 0, expense = 0, demand = 0;
		for (uint i = 0; i < uint(RT_COUNT); ++i) {
			ResourceType type = ResourceType(i);
			string@ name = getResourceName(type);

			// Store stats
			emp.getStatStats(name, val, income, expense, demand);
			setResData(type, RD_Stored, val);
			setResData(type, RD_Income, income);
			setResData(type, RD_Expense, expense);
			setResData(type, RD_Demand, demand);
			setResData(type, RD_Net, income - expense - demand);
		}

		// Calculate derived statistics
		int economy = 0;
		ResourceStatus bottleneck = RS_Surplus;
		bottleneckResource = RT_None;

		ResourceStatus surplusStatus = RS_Critical;
		surplusResource = RT_None;

		for (uint i = 0; i < uint(RT_COUNT); ++i) {
			ResourceType type = ResourceType(i);

			double net = getResData(type, RD_Net);
			double income = getResData(type, RD_Income);
			double stored = getResData(type, RD_Stored);

			ResourceStatus status = RS_Enough;
			if (stored > this[PV_AlwaysSurplus]) {
				status = RS_Surplus;
			}
			else if (net < 0) {
				// Consider how soon we'll run out when deciding
				// the resource level
				if (stored < abs(net * 40))
					status = RS_Critical;
				else if (stored < abs(net * 80))
					status = RS_Low;
				else if (stored < abs(net * 160))
					status = RS_Enough;
				else
					status = RS_Surplus;
			}
			else {
				// Consider the amount of stored income when deciding
				// the resource level
				if (stored > net * 160)
					status = RS_Surplus;
				else if (stored > net * 80)
					status = RS_Enough;
				else if (stored > net * 40)
					status = RS_Low;
				else
					status = RS_Critical;
			}
			// Push even if indebted
			if (getGameTime() < 1200.0 && hasDebt && status <= RS_Low){
				if (getGameTime() < 300.0)
					status = RS_Enough;
				else
					status = RS_Low;
			}

			// Store status of resource
			setResStatus(type, status);

			// Alter global economy index
			switch (status) {
				case RS_Surplus: economy += 2; break;
				case RS_Enough: economy += 1; break;
				case RS_Low: economy -= 2; break;
				case RS_Critical: economy -= 4; break;
			}

			// Check if this is the bottleneck resource
			if (status < bottleneck) {
				bottleneck = status;
				bottleneckResource = type;
			}
			if (status > surplusStatus) {
				surplusStatus = status;
				surplusResource = type;
			}
		}

		// Global economy index
		setGlobal(GD_Economy, economy);

		// Check mood-based resources
		if (!hasMood) {
			setResStatus(RT_Luxuries, RS_Surplus);
			setResStatus(RT_Goods, RS_Surplus);
		}
	}

	void cheatEconomy(Empire@ emp) {
		// Collect basic statistics
		double val = 0, income = 0, expense = 0, demand = 0;
		for (uint i = 0; i < uint(RT_COUNT); ++i) {
			ResourceType type = ResourceType(i);
			string@ name = getResourceName(type);

			emp.getStatStats(name, val, income, expense, demand);

			income = max(income, minCheatingResources);
			income *= cheatFactor - 1;

			emp.addStat(name, income);
		}
	}

	void updateCivilActs(Empire@ emp) {
		// * Update current focus/mandate
		ResourceStatus mtl = getResStatus(RT_Metals);
		ResourceStatus elc = getResStatus(RT_Electronics);
		ResourceStatus adv = getResStatus(RT_AdvParts);

		int type = 0;
		if (mtl <= RS_Critical)
			type = 4;
		else if (mtl <= RS_Low)
			type = 1;
		else if (mtl >= RS_Surplus && elc <= RS_Critical)
			type = 5;
		else if (mtl >= RS_Enough && elc <= RS_Low)
			type = 2;
		else if (mtl >= RS_Surplus && elc >= RS_Surplus && adv <= RS_Critical)
			type = 6;
		else if (mtl >= RS_Enough && elc >= RS_Enough && adv <= RS_Low)
			type = 3;

		emp.setSetting(strEcoMode, float(type));
	}
	
	void dumpResourceStatus() {
		for (uint i = 0; i < uint(RT_COUNT); ++i) {
			ResourceType type = ResourceType(i);
			string@ prior = "";

			switch (getResStatus(type)) {
				case RS_Surplus: prior = "Surplus"; break;
				case RS_Enough: prior = "Enough"; break;
				case RS_Low: prior = "Low"; break;
				case RS_Critical: prior = "Critical"; break;
			}

			warning(getResourceName(type)+" Status: "+prior);
		}
	}
	/* }}} */
	/* {{{ Diplomacy Handling */
	void collectDiplomaticData(Empire@ emp) {
		// Collect data about all enemies
		float estr = 0.f, astr = 0.f, nstr = 0.f;
		uint enemyCnt = 0, alliedCnt = 0, neutralCnt = 0;
		uint empCnt = getEmpireCount();

		for (uint i = 0; i < empCnt; ++i) {
			Empire@ otherEmp = getEmpire(i);

			if (!otherEmp.isValid() || otherEmp.ID < 0 || otherEmp is emp)
				continue;

			if (emp.isEnemy(otherEmp)) {
				estr =+ otherEmp.getStat(strStrength);
				++enemyCnt;
			}
			else if (emp.isAllied(otherEmp)) {
				astr =+ otherEmp.getStat(strStrength);
				++alliedCnt;
			}
			else {
				nstr =+ otherEmp.getStat(strStrength);
				++neutralCnt;
			}
		}

		setGlobal(GD_TotalEnemyStrength, estr);
		setGlobal(GD_TotalEnemies, float(enemyCnt));
		
		setGlobal(GD_TotalEnemyStrength, astr);
		setGlobal(GD_TotalEnemies, float(alliedCnt));
		
		setGlobal(GD_TotalEnemyStrength, nstr);
		setGlobal(GD_TotalEnemies, float(neutralCnt));

		// Check if we're at peace
		peaceTime = estr <= 0;
	}

	void updateRelations(Empire@ emp, float time) {
		int relCnt = int(relations.length());
		for (int i = relCnt - 1; i >= 0; --i) {
			relations[i].update(this, emp, time);
			if (i == relFullNum)
				relations[i].fullUpdate(this, emp);
		}

		if (relCnt > 0)
			relFullNum = (relFullNum + 1) % relCnt;
		else
			relFullNum = 0;
	}

	void onDiplomaticMessage(Empire@ emp, Empire@ from, DiploMsg@ msg) {
	}
	/* }}} */
	/* {{{ Debug message handling */
	void onDebugMessage(Empire@ emp, string@ arg1, string@ arg2, string@ arg3) {
		if (arg1 is null)
			return;

		if (arg1 == "resstat") {
			dumpResourceStatus();
		}
		else if (arg1 == "civacts") {
			warning("EcoMode: " + f_to_s(emp.getSetting(strEcoMode), 0));
		}
		else if (arg1 == "logres") {
			research.logging = !research.logging;
			if (research.logging)
				warning(emp.getName()+": logging research");
			else
				warning(emp.getName()+": no longer logging research");
		}
		else if (arg1 == "logfleets") {
			logFleets = !logFleets;
			if (logFleets)
				warning(emp.getName()+": logging fleets");
			else
				warning(emp.getName()+": no longer logging fleets");

			uint cnt = fleetControllers.length();
			for (uint i = 0; i < cnt; ++i) {
				FleetController@ ct = fleetControllers[i];
				ct.logging = logFleets;
			}
		}
		else if (arg1 == "sys") {
			uint cnt = systemControllers.length();
			for (uint i = 0; i < cnt; ++i) {
				SystemController@ ct = systemControllers[i];
				if (ct.sys.toObject().getName() == arg2) {
					ct.onDebugMessage(this, emp, arg3);
					break;
				}
			}
		}
		else if (arg1 == "fleet") {
			uint cnt = fleetControllers.length();
			for (uint i = 0; i < cnt; ++i) {
				FleetController@ ct = fleetControllers[i];
				if (ct.fleet.getName() == arg2) {
					ct.onDebugMessage(this, emp, arg3);
					break;
				}
			}
		}
	}
	/* }}} */
	/* {{{ Tick delegation */
	void tick(Empire@ emp, float time) {
		if (!hasTicked) {
			// First tick for this ai data
			firstTick(emp);

			// First tick for this empire in the game
			if (gameTime < 2.f)
				firstGameTick(emp);
		}

		// If we're dead, don't do anything at all
		if (emp.getStat(strPlanet) <= 0)
			return;

		// Update global economy
		if (tickTimer(GT_EconUpdate, time)) {
			collectEconomicData(emp);

			if (hasCivilActs && difficulty >= 2)
				updateCivilActs(emp);
		}

		if (cheating && tickTimer(GT_CheatEconomy, time))
			cheatEconomy(emp);

		// Update ships waiting to be built
		if (tickTimer(GT_BuiltShips, time))
			checkActions();

		// Design new layouts
		if (tickTimer(GT_DesignShipsBase, time * difficultyFactor)) {
			if (unlockNewDesigns(emp))
				pruneObsoleteDesigns(emp);
			else
				setTimer(GT_DesignShipsBase, 4.f);
		}

		// Update layout scaling
		if (tickTimer(GT_LayoutScaling, time))
			updateLayoutScaling(emp);

		// Update running sweeps
		runSweeps(emp, time);

		// Update systems
		updateSystemControllers(emp, time);

		// Update fleets
		updateFleetControllers(emp, time);

		// Update diplomatic data
		collectDiplomaticData(emp);

		// Update relations
		updateRelations(emp, time);

		// Update research
		if (tickTimer(GT_ResearchTick, time))
			research.update(this, emp, time);

		// Become bored over time
		if (tickTimer(GT_BoredomTimer, time)) {
			if (!hasActivity)
				setGlobal(GD_Boredom, this[GD_Boredom] * this[PV_BoredomFactor]);
			else
				setGlobal(GD_Boredom, this[GD_Boredom] / this[PV_BoredomFactor]);
			hasActivity = false;
		}
	}

	void firstTick(Empire@ emp) {
		// Check some empire things
		hasMood = !emp.hasTraitTag(strIndifferent);
		hasCivilActs = !emp.hasTraitTag("disable_civil_acts");
		hasDebt = emp.hasTraitTag("half_exports");

		// Add initial sweeps
		addSweep(FindSystems());

		// Make sure initial designs are generated
		{
			ResearchWeb web;
			web.prepare(emp);
			
			uint realLayoutCount = 0, designCount = pers.startingDesigns.length();
			shipDesigns.resize(designCount);
			for(uint i = 0; i < designCount; ++i) {
				if (pers.startingDesigns[i].hasDesign(emp)) {
					ShipDesignLine@ line = ShipDesignLine(pers.startingDesigns[i]);
					if (line.get(emp) !is null) {
						if (line.design.replaces == line.layout.getName()) {
							line.scaleMultiplier = 1.f;
							if (line.generate(emp) !is null)
								@shipDesigns[realLayoutCount++] = line;
						}
						else {
							@shipDesigns[realLayoutCount++] = line;
						}
					}
					else if (line.generate(emp) !is null) {
						@shipDesigns[realLayoutCount++] = line;
					}
				}
				else if (pers.startingDesigns[i].canCreate(emp, web)) {
					ShipDesignLine@ line = ShipDesignLine(pers.startingDesigns[i]);
					if (line.generate(emp) !is null)
						@shipDesigns[realLayoutCount++] = line;
				}
			}
			shipDesigns.resize(realLayoutCount);
		}

		hasTicked = true;
	}

	void firstGameTick(Empire@ emp) {
		// Initialize relations management
		uint empCnt = getEmpireCount();
		relations.resize(empCnt);
		uint realEmpCnt = 0;
		for (uint i = 0; i < empCnt; ++i) {
			Empire@ other = getEmpire(i);

			if (other.isValid() && other !is emp && other.ID > 0)
				@relations[realEmpCnt++] = RelationsManager(this, emp, other);
		}
		relations.resize(realEmpCnt);
	}
	/* }}} */
	/* {{{ Layout handling */
	void updateLayoutScaling(Empire@ emp) {
		// Don't scale up if we don't have lots of resources
		if (getBottleneck(rf_mtl & rf_elc & rf_adv & rf_ful) < RS_Surplus)
			return;

		// Calculate multiplier
		float mult = 0.f;
		float limMult = 0.f;
		{
			ResearchWeb web;
			web.prepare(emp);

			float minTech = pow(10.f, 20.f);
			StringList@ ct = cast<StringList>(this[PL_ConstructionTechs]);
			uint len = ct.length();
			for (uint i = 0; i < len; ++i) {
				const WebItemDesc@ desc = getWebItemDesc(ct[i]);
				float level = 0.f;

				if (desc !is null) {
					if (web.isTechVisible(desc)) {
						const WebItem@ item = web.getItem(desc);
						level = item.level;
					}
				}

				if (level < minTech)
					minTech = level;
				mult += level;
			}

			mult = max(floor(mult / len) - 1, 0.f);

			if (mult > minTech + 8.f)
				mult = minTech + 8.f;

			limMult = pow(this[PV_ScalingCurve], max(mult - 1, 0.f));
			mult = pow(this[PV_ScalingCurve], mult * min(difficultyFactor,1.f));
			setGlobal(GD_ScaleMultiplier, mult);
		}

		// Regenerate designs if needed
		uint cnt = shipDesigns.length();
		if (cnt > 0) {
			uint n = rand(cnt - 1);
			uint look = min(cnt, 10);
			for(uint i = 0; i < look; ++i) {
				float fact = mult;
				if (shipDesigns[n].design.goalID == GID_StrikeCraft)
					fact = limMult;
				if (shipDesigns[n].setScaleMultiplier(emp, fact))
					break;
				n = (n + 1) % cnt;
			}
		}
	}

	void pruneObsoleteDesigns(Empire@ emp) {
		// Remove designs that are marked obselete from the build lists
		uint cnt = shipDesigns.length();
		for (uint i = 0; i < cnt; ++i) {
			const HullLayout@ lay = shipDesigns[i].layout;
			if (lay !is null)
				@lay = lay.getLatestVersion();

			// We want to remove design lines when:
			//	* There is no valid design
			//  * The latest version is a different design (different name)
			//  * The latest version is obsolete
			//
			if (lay is null
				|| lay.obsolete
				|| lay.getName() != shipDesigns[i].design.className
			) {
				shipDesigns.erase(i);
				--i; --cnt;
			}
		}
	}

	bool unlockNewDesigns(Empire@ emp) {
		uint createDesignCount = pers.unlockedDesigns.length();
		if(createDesignCount == 0)
			return false;
		
		ShipDesign@ newDesign = @pers.unlockedDesigns[rand(createDesignCount - 1)];
		const HullLayout@ preDesigned = emp.getShipLayout(newDesign.className);
		
		if(preDesigned !is null)
			return false;
		
		{
			ResearchWeb web;
			web.prepare(emp);
			if(!newDesign.canCreate(emp, web))
				return false;
		}
		
		//Create and add design
		ShipDesignLine@ line = ShipDesignLine(newDesign);
		if (line.generate(emp) is null)
			return false;

		uint n = shipDesigns.length();
		shipDesigns.resize(n+1);
		@shipDesigns[n] = line;
		return true;
	}

	ShipDesignLine@ getRandomLayout(GoalID goal) {
		uint cnt = shipDesigns.length();
		
		ShipDesignLine@[] matches;
		matches.resize(cnt);
		uint matchCount = 0;
		
		for(uint i = 0; i < cnt; ++i)
			if(shipDesigns[i].design.goalID == goal)
				@matches[matchCount++] = @shipDesigns[i];
		
		if(matchCount == 0)
			return null;
		if(matchCount == 1)
			return matches[0];
		return matches[rand(matchCount - 1)];
	}

	const HullLayout@ getRandomLayout(Empire@ emp, GoalID goal) {
		ShipDesignLine@ design = getRandomLayout(goal);
		if (design is null)
			return null;
		return design.get(emp);
	}

	ShipDesignLine@ getRandomLayout(GoalID goal, float underScale) {
		uint cnt = shipDesigns.length();
		
		ShipDesignLine@[] matches;
		matches.resize(cnt);
		uint matchCount = 0;
		
		for(uint i = 0; i < cnt; ++i)
			if(shipDesigns[i].design.goalID == goal && shipDesigns[i].scale < underScale)
				@matches[matchCount++] = @shipDesigns[i];
		
		if(matchCount == 0)
			return null;
		return matches[rand(matchCount - 1)];
	}

	const HullLayout@ getRandomLayout(Empire@ emp, GoalID goal, float underScale) {
		ShipDesignLine@ design = getRandomLayout(goal, underScale);
		if (design is null)
			return null;
		return design.get(emp);
	}
	/* }}} */
	/* {{{ Saving and loading */
	void save(XMLWriter@ xml) {
		xml.createHeader();

		// Write global data
		for (uint i = 0; i < uint(GD_COUNT); ++i)
			xml.addElement("gd", true, "i", i_to_s(i), "v", ftos_nice(globalData[i]));

		// Write timer state
		for (uint i = 0; i < uint(GT_COUNT); ++i)
			xml.addElement("gt", true, "i", i_to_s(i), "v", ftos_nice(timers[i].getRemaining()));

		// Save global sets
		for (uint i = 0; i < uint(GS_COUNT); ++i) {
			xml.addElement("gs", false, "i", i_to_s(i));
			globalSets[i].resetIter();
			while (globalSets[i].hasNext()) {
				int item = globalSets[i].next();
				xml.addElement("i", true, "v", i_to_s(item));
			}

			xml.closeTag("gs");
		}
		
		// Save home system / planet
		if (homeSystem !is null && homePlanet !is null)
			xml.addElement("home", true, "sys", i_to_s(homeSystem.toObject().uid), "pl",i_to_s(homePlanet.toObject().uid));

		// Save systemControllers
		for (uint i = 0; i < systemControllers.length(); ++i) {
			xml.addElement("system", false);
			systemControllers[i].save(xml);
			xml.closeTag("system");
		}

		// Save fleetControllers
		for (uint i = 0; i < fleetControllers.length(); ++i) {
			xml.addElement("fleet", false);
			fleetControllers[i].save(xml);
			xml.closeTag("fleet");
		}

		// Save built ship actions
		for (uint i = 0; i < actions.length(); ++i) {
			xml.addElement("action", false);
			actions[i].save(xml);
			xml.closeTag("action");
		}

		// Save ship designs
		for (uint i = 0; i < shipDesigns.length(); ++i) {
			xml.addElement("design", false);
			shipDesigns[i].save(xml);
			xml.closeTag("design");
		}

		// Save researchManager
		xml.addElement("research", false);
		research.save(xml);
		xml.closeTag("research");

		// Save relations managers
		for (uint i = 0; i < relations.length(); ++i) {
			xml.addElement("relation", false);
			relations[i].save(xml);
			xml.closeTag("relation");
		}
	}

	EmpireAIData(Empire@ emp, XMLReader@ xml) {
		// Initialize members
		init(emp);

		while (xml.advance()) {
			string@ name = xml.getNodeName();
			switch(xml.getNodeType()) {
				case XN_Element:
					if (name == "gd") {
						// Load global data
						int i = s_to_i(xml.getAttributeValue("i"));
						float val = s_to_f(xml.getAttributeValue("v"));

						globalData[i] = double(val);
					}
					else if (name == "gt") {
						// Load timer state
						int i = s_to_i(xml.getAttributeValue("i"));
						float val = s_to_f(xml.getAttributeValue("v"));

						timers[i].setRemaining(val);
					}
					else if (name == "gs") {
						// Load global sets
						loadSet(xml);
					}
					else if (name == "home") {
						// Load home system / planet
						@homeSystem = getObjectByID(s_to_i(xml.getAttributeValue("sys")));
						@homePlanet = getObjectByID(s_to_i(xml.getAttributeValue("pl")));
					}
					else if (name == "fleet") {
						addController(FleetController(emp, xml));
					}
					else if (name == "system") {
						addController(SystemController(this, emp, xml));
					}
					else if (name == "design") {
						uint n = shipDesigns.length();
						shipDesigns.resize(n+1);
						@shipDesigns[n] = ShipDesignLine(this, emp, xml);
					}
					else if (name == "action") {
						// Load built ship actions
						BuiltShipAction@ act = loadBuiltShipAction(this, emp, xml);
						if (act !is null) {
							uint n = actions.length();
							actions.resize(n+1);
							@actions[n] = act;
							actions_ids.resize(n+1);
							actions_ids[n] = act.getID();
						}
					}
					else if (name == "research") {
						research.load(this, emp, xml);
					}
					else if (name == "relation") {
						uint n = relations.length();
						relations.resize(n+1);
						@relations[n] = RelationsManager(this, emp, xml);
					}
				break;
			}
		}

	 	// Make sure we have relation managers for all empires
		uint empCnt = getEmpireCount();
		for (uint i = 0; i < empCnt; ++i) {
			Empire@ other = getEmpire(i);

			if (other.isValid() && other !is emp && other.ID > 0) {
				uint cnt = relations.length();
				bool found = false;
				for (uint j = 0; j < cnt; ++j) {
					if (relations[j].other is other) {
						found = true;
						break;
					}
				}

				if (!found) {
					relations.resize(cnt+1);
					@relations[cnt] = RelationsManager(this, emp, other);
				}
			}
		}

		// Trigger appropriate timers
		triggerTimer(GT_EconUpdate);
	}

	void loadSet(XMLReader@ xml) {
		int i = s_to_i(xml.getAttributeValue("i"));
		while (xml.advance()) {
			string@ name = xml.getNodeName();
			switch(xml.getNodeType()) {
				case XN_Element:
					if (name == "i") {
						int item = s_to_i(xml.getAttributeValue("v"));
						globalSets[i].insert(item);
					}
				break;
				case XN_Element_End:
					if (name == "gs")
						return;
				break;
			}
		}
	}
	/* }}} */
};
/* }}} */
/* {{{ Research Manager */
class ResearchManager {
	const WebItem@ watchTech;
	float goalLevel;
	int link;

	uint targetTech;
	bool logging;

	ResearchManager() {
		link = -1;
		goalLevel = -1;
		targetTech = 0;
		logging = false;
	}

	const WebItem@ getLowestAvailableTech(ResearchWeb& web) {
		float lowest = -1;
		const WebItem@ lowestItem = null;

		uint cnt = getWebItemDescCount();
		for (uint i = 0; i < cnt; ++i) {
			const WebItemDesc@ desc = getWebItemDesc(i);

			if (web.isTechVisible(desc)) {
				const WebItem@ item = web.getItem(desc);

				if (item.level < lowest || lowest < 0) {
					@lowestItem = item;
					lowest = item.level;
				}
			}
		}
		return lowestItem;
	}

	const WebItem@ getLowestAvailableTech(ResearchWeb& web, StringList@ list) {
		float lowest = -1;
		const WebItem@ lowestItem = null;

		uint cnt = list.length();
		for (uint i = 0; i < cnt; ++i) {
			const WebItem@ item = web.getItem(list[i]);

			if (item is null)
				continue;

			if (item.level < lowest || lowest < 0) {
				@lowestItem = item;
				lowest = item.level;
			}
		}
		return lowestItem;
	}

	void switchTechnology(EmpireAIData@ data, Empire@ emp) {
		ResearchWeb web;
		web.prepare(emp);
		link = -1;
		double rate = web.getResearchRate();

		// Check if we should research a link
		if ((gameTime > data[PV_ResearchTargetDelay] || rate > pow(10.f, 5.f))
				&& randomf(1.f) <= data[PV_ResearchTargetChance]) {
			StringList@ toTechs = cast<StringList>(data[PL_LinkTechs]);
			uint techs = toTechs.length();

			while (targetTech < techs && isUnlocked(web, toTechs[targetTech]))
				++targetTech;

			if (targetTech < techs) {
				StringList@ fromTechs = cast<StringList>(data[PL_LinkFromTechs]);
				@watchTech = web.getItem(fromTechs[targetTech]);

				if (watchTech !is null) {
					float progress, cost;
					float best = -1.f;
					for (uint i = 0; i < watchTech.descriptor.linkCount; ++i) {
						watchTech.getLinkLevels(i, progress,cost);
						if (cost > 0 && progress < cost) {
							float ratio = progress / cost;
							if (ratio > best) {
								best = ratio;
								link = i;
							}
						}
					}
				}
			}
			else if (logging) {
				warning(emp.getName()+": Completed target techs");
			}
		}

		// Research the lowest available tech
		if (link < 0) {
			StringList@ list;

			// There is a chance we pick a priority tech
			if (randomf(1.f) < data[PV_ResearchPriorityChance]) {
				if (data.peaceTime) {
					@list = cast<StringList>(data[PL_PeacePriorityTechs]);
					if (logging)
						warning(emp.getName()+": Peacetime Prior Tech");
				}
				else {
					@list = cast<StringList>(data[PL_WarPriorityTechs]);
					if (logging)
						warning(emp.getName()+": Wartime Prior Tech");
				}
			}
			else {
				@list = cast<StringList>(data[PL_ResearchTechs]);
			}

			@watchTech = getLowestAvailableTech(web, list);

			float level = 0.f, progress = 0.f, cost = 0.f, max = 0.f;
			watchTech.getLevels(level, progress, cost, max);

			if (rate > 0 && (cost - progress) / rate > 60.f * 60.f * 6.f
					&& targetTech < data[PL_LinkTechs].length()) {
				@watchTech = null;
				return;
			}

			if (logging)
				warning(emp.getName()+" picked "+watchTech.descriptor.get_name());

			goalLevel = watchTech.level + 1;
			web.setActiveTech(watchTech.descriptor);
		}
		else if (watchTech !is null) {
			goalLevel = -1;
			web.setActiveTech(watchTech.descriptor, link);

			if (logging)
				warning(emp.getName()+" picked link "+link+" on "+watchTech.descriptor.get_name());
		}
	}

	void update(EmpireAIData@ data, Empire@ emp, float time) {
		if (watchTech is null || (link < 0 && watchTech.level >= goalLevel)) {
			switchTechnology(data, emp);
		}
		else if (link >= 0) {
			float progress, cost;
			watchTech.getLinkLevels(link, progress, cost);
			if(progress >= cost)
				switchTechnology(data, emp);
		}
	}

	void save(XMLWriter@ xml) {
		xml.addElement("r", true,
			"w", watchTech is null ? "" : watchTech.descriptor.get_name(),
			"gl", f_to_s(goalLevel),
			"l", i_to_s(link),
			"t", i_to_s(targetTech));
	}

	void load(EmpireAIData@ data, Empire@ emp, XMLReader@ xml) {
		while (xml.advance()) {
			string@ name = xml.getNodeName();
			switch(xml.getNodeType()) {
				case XN_Element:
					if (name == "r") {
						link = s_to_i(xml.getAttributeValue("l"));
						targetTech = uint(s_to_i(xml.getAttributeValue("t")));
						goalLevel = s_to_f(xml.getAttributeValue("gl"));

						string@ techName = xml.getAttributeValue("w");
						if (techName == "") {
							@watchTech = null;
						}
						else {
							ResearchWeb web;
							web.prepare(emp);

							@watchTech = web.getItem(techName);
						}
					}
				break;
				case XN_Element_End:
					if (name == "research")
						return;
				break;
			}
		}
	}
};
/* }}} */
/* {{{ System Controller */
/* {{{ Find new Systems Sweep */
class FindSystems : SystemSweep {
	System@ found;

	float call(const EmpireAIData@ data, Empire@ emp, System@ sys) {
		if (sys.hasPlanets(emp) && sys.toObject().getStat(emp, strManaged) < 0.5f)
			@found = sys;
		return 0;
	}

	bool complete(EmpireAIData@ data, Empire@ emp, System@ best) {
		if (found !is null) {
			Object@ sysObj = found;
			sysObj.setStat(emp, strManaged, 1.f);
			data.addSystem(found);
		}
		@found = null;
		return false;
	}
};
/* }}} */
/* {{{ System Context Data Collection Sweep */
class UpdateSystemContext : SystemSweep {
	SystemController@ ctrl;
	SystemContextData context;
	bool disabled;

	UpdateSystemContext(SystemController@ sys) {
		@ctrl = sys;
		disabled = false;
		context.reset();
	}

	float call(const EmpireAIData@ data, Empire@ emp, System@ sys) {
		if (sys is null || ctrl is null || disabled)
			return 0;
		ctrl.addContext(data, emp, context, sys);
		return 0;
	}

	void disable() {
		disabled = true;
		@ctrl = null;
	}

	bool complete(EmpireAIData@ data, Empire@ emp, System@ best) {
		if (disabled)
			return true;
		ctrl.setContext(data, emp, context);
		context.reset();
		return false;
	}
};
/* }}} */
class SystemContextData {
	// * Basic collected context data
	// Closeness of visible enemies
	double frontline;
	// The relative amount of remnants close to this system
	double remnants;
	// Closeness of unexplored territory
	double undiscovered;
	// Index for systems that can be expanded into
	double expansion;

	// * Closest systems we can attack
	System@ closestRemnants;
	double closestRemnantDist;
	double closestRemnantStrength;

	System@ closestEnemies;
	double closestEnemyDist;
	double closestEnemyStrength;

	// * Closest system we can expand into
	// Distance
	double expandDist;
	// Saved system
	System@ expandSys;
	// Unowned planets in system
	int expandPlanets;

	SystemContextData() {
		reset();
	}

	void reset() {
		frontline = 0;
		undiscovered = 0;
		remnants = 0;
		expansion = 0;

		expandDist = -1;
		@expandSys = null;
		expandPlanets = 0;

		@closestRemnants = null;
		closestRemnantStrength = 0;
		closestRemnantDist = 0;

		@closestEnemies = null;
		closestEnemyStrength = 0;
		closestEnemyDist = 0;
	}

// {{{ Debugging
	void dump() {
		warning("Frontline: "+ftos_nice(frontline));
		warning("Remnants: "+ftos_nice(remnants));
		warning("Undiscovered: "+ftos_nice(undiscovered));
		warning("Expansion: "+ftos_nice(expansion));
	}
// }}}
// {{{ Saving and Loading
	void save(XMLWriter@ xml) {
		xml.addElement("frontline", true, "v", f_to_s(frontline));
		xml.addElement("remnants", true, "v", f_to_s(remnants));
		xml.addElement("undiscovered", true, "v", f_to_s(undiscovered));
		xml.addElement("expansion", true, "v", f_to_s(expansion));

		xml.addElement("closestRemnants", true, "v", i_to_s(closestRemnants is null ? -1 : closestRemnants.toObject().uid));
		xml.addElement("closestRemnantDist", true, "v", f_to_s(closestRemnantDist));
		xml.addElement("closestRemnantStrength", true, "v", f_to_s(closestRemnantStrength));

		xml.addElement("closestEnemies", true, "v", i_to_s(closestEnemies is null ? -1 : closestEnemies.toObject().uid));
		xml.addElement("closestEnemyDist", true, "v", f_to_s(closestEnemyDist));
		xml.addElement("closestEnemyStrength", true, "v", f_to_s(closestEnemyStrength));

		xml.addElement("expandSys", true, "v", i_to_s(expandSys is null ? -1 : expandSys.toObject().uid));
		xml.addElement("expandDist", true, "v", f_to_s(expandDist));
		xml.addElement("expandPlanets", true, "v", i_to_s(expandPlanets));
	}

	void load(XMLReader@ xml) {
		while (xml.advance()) {
			string@ name = xml.getNodeName();
			switch(xml.getNodeType()) {
				case XN_Element:
					if (name == "closestRemnants") {
						int id = s_to_i(xml.getAttributeValue("v"));
						if (id > 0)
							@closestRemnants = getObjectByID(id);
					}
					else if (name == "closestRemnantDist") {
						closestRemnantDist = s_to_f(xml.getAttributeValue("v"));
					}
					else if (name == "closestRemnantStrength") {
						closestRemnantStrength = s_to_f(xml.getAttributeValue("v"));
					}
					else if (name == "closestEnemies") {
						int id = s_to_i(xml.getAttributeValue("v"));
						if (id > 0)
							@closestEnemies = getObjectByID(id);
					}
					else if (name == "closestEnemyDist") {
						closestEnemyDist = s_to_f(xml.getAttributeValue("v"));
					}
					else if (name == "closestEnemyStrength") {
						closestEnemyStrength = s_to_f(xml.getAttributeValue("v"));
					}
					else if (name == "expandSys") {
						int id = s_to_i(xml.getAttributeValue("v"));
						if (id > 0)
							@expandSys = getObjectByID(id);
					}
					else if (name == "expandDist") {
						expandDist = s_to_f(xml.getAttributeValue("v"));
					}
					else if (name == "expandPlanets") {
						expandPlanets = s_to_f(xml.getAttributeValue("v"));
					}
					else if (name == "frontline") {
						frontline = s_to_f(xml.getAttributeValue("v"));
					}
					else if (name == "remnants") {
						remnants = s_to_f(xml.getAttributeValue("v"));
					}
					else if (name == "undiscovered") {
						undiscovered = s_to_f(xml.getAttributeValue("v"));
					}
					else if (name == "expansion") {
						expansion = s_to_f(xml.getAttributeValue("v"));
					}
				break;
				case XN_Element_End:
					if (name == "context")
						return;
				break;
			}
		}
	}
// }}}
};

/* {{{ Queued Ship Tracking */
enum QueuedShipState {
	QSS_Waiting,
	QSS_Building,
	QSS_Built,
	QSS_Destroyed,
	QSS_TimedOut,
};

class QueuedShip {
	Timer deathTimer;
	QueuedShipState state;
	int shipID;

	QueuedShip(int id) {
		shipID = id;
		state = QSS_Building;

		setTimeout(180.f);
	}

	QueuedShip(Object@ obj) {
		shipID = obj.uid;
		state = QSS_Built;

		setTimeout(180.f);
	}

	QueuedShip(int id, QueuedShipState beginState, float timeout) {
		shipID = id;
		state = beginState;
		setTimeout(timeout);
	}

	void setTimeout(float time) {
		deathTimer.setLength(time);
		deathTimer.reset();
	}

	QueuedShipState update(Empire@ emp, float time) {
		if (deathTimer.tick(time)) {
			state = QSS_TimedOut;
		}
		else {
			Object@ obj = getObjectByID(shipID);
			bool exists = obj !is null && obj.getOwner() is emp;
			switch (state) {
				case QSS_Waiting:
					if (!exists)
						state = QSS_Building;
				break;
				case QSS_Building:
					if (exists)
						state = QSS_Built;
				break;
				case QSS_Built:
					if (!exists)
						state = QSS_Destroyed;
				break;
			}
		}
		return state;
	}

	// {{{ Debug
	void dump() {
		Object@ obj = getObjectByID(shipID);
		if (obj is null)
			warning(shipID+" doesn't exist, state "+int(state)+", timer "+deathTimer.getRemaining());
		else
			warning(shipID+" is "+obj.getName()+", state "+int(state)+", timer "+deathTimer.getRemaining());
	}
	// }}}
	// {{{ Saving and Loading
	void save(XMLWriter@ xml) {
		xml.addElement("id", true, "v", i_to_s(shipID));
		xml.addElement("state", true, "v", i_to_s(int(state)));
		xml.addElement("timer", true, "v", i_to_s(deathTimer.getRemaining()));
	}

	QueuedShip(XMLReader@ xml) {
		// Load data
		while (xml.advance()) {
			string@ name = xml.getNodeName();
			switch(xml.getNodeType()) {
				case XN_Element:
					if (name == "id") {
						shipID = s_to_i(xml.getAttributeValue("v"));
					}
					else if (name == "state") {
						state = QueuedShipState(s_to_i(xml.getAttributeValue("v")));
					}
					else if (name == "timer") {
						deathTimer.setLength(180.f);
						deathTimer.setRemaining(s_to_i(xml.getAttributeValue("v")));
					}
				break;
				case XN_Element_End:
					if (name == "queued")
						return;
				break;
			}
		}
	}
	// }}}
};
/* }}} */
class SystemController {
	System@ sys;
	SystemContextData context;
	UpdateSystemContext@ contextSweep;
	ObjectPriority priority;

	float enemyStrength;
	float ourStrength;
	float enemyRatio;

	float lastFullUpdate;
	bool startTick;

	Timer scoutTimer;
	Timer expandTimer;
	Timer developTimer;
	Timer ringTimer;

	PlanetController@[] planets;
	set_int controlledPlanets;

	FleetController@ closestFleet;
	FleetController@[] fleets;
	set_int controlledFleets;

	bool hasEnemies;
	bool hasEnemyMilitary;
	bool hasNotableEnemies;
	bool hasEnemyPlanets;
	bool ringworld;

	int ownedPlanets;
	int developedPlanets;
	int unownedPlanets;

	bool developed;
	bool logging;

	int lowPlanets;
	int highPlanets;

	int trackingPlanet;
	int developingPlanet;

	int[] shipsPresent;
	float[] scalePresent;

	bool claimedExpansion;
	bool canExpandExternally;
	uint numRoids;

	set_int trackedColonizers;
	QueuedShip@[] colonizers;
	QueuedShip@[] retrofitting;

	SystemController(EmpireAIData@ data, System@ system) {
		@sys = system;
		createVars(data);
		data.addSweep(contextSweep);

		canExpandExternally = randomf(0.f, 6.f) < float(data.difficulty);
	}

	void createVars(EmpireAIData@ data) {
		lastFullUpdate = gameTime;
		trackingPlanet = 0;
		developingPlanet = 0;
		enemyRatio = 0;
		hasEnemies = false;
		hasEnemyMilitary = false;
		hasNotableEnemies = false;
		hasEnemyPlanets = false;
		ringworld = false;
		startTick = false;
		claimedExpansion = false;
		canExpandExternally = true;
		priority = OP_Normal;
		logging = false;

		@contextSweep = UpdateSystemContext(this);
		enemyStrength = 0;

		shipsPresent.resize(GID_COUNT);
		scalePresent.resize(GID_COUNT);

		scoutTimer.setLength(20.f);
		scoutTimer.randomize();

		expandTimer.setLength(20.f / data.difficultyFactor);
		expandTimer.randomize();

		developTimer.setLength(20.f / data.difficultyFactor);
		developTimer.randomize();
		
		ringTimer.setLength(120.f);
		ringTimer.randomize();

		numRoids = 0;
	}

	// {{{ Tracking expansion logic
	void resetExpansion(EmpireAIData@ data, Empire@ emp) {
		if (context.expandSys is null)
			return;
		if (claimedExpansion) {
			claimedExpansion = false;

			Object@ sysObj = context.expandSys;
			data.setRemove(GS_ExpansionSystems, sysObj.uid);
			sysObj.setStat(emp, strExpansion, 0);
		}
		@context.expandSys = null;
		colonizers.resize(0);
	}

	void claimExpansion(EmpireAIData@ data, Empire@ emp) {
		if (claimedExpansion || context.expandSys is null)
			return;
		claimedExpansion = true;

		Object@ sysObj = context.expandSys;
		data.setAdd(GS_ExpansionSystems, sysObj.uid);
		sysObj.setStat(emp, strExpansion, 1);
	}

	void trackExpansion(EmpireAIData@ data, Empire@ emp, Object@ ship) {
		claimExpansion(data, emp);

		uint n = colonizers.length();
		colonizers.resize(n+1);
		@colonizers[n] = QueuedShip(ship);

		trackedColonizers.insert(ship.uid);
	}

	void queueExpansion(EmpireAIData@ data, Empire@ emp, int id) {
		claimExpansion(data, emp);

		uint n = colonizers.length();
		colonizers.resize(n+1);
		@colonizers[n] = QueuedShip(id);

		trackedColonizers.insert(id);
	}

	void updateExpansion(EmpireAIData@ data, Empire@ emp, float time) {
		// Update all tracking ships
		for (int i = colonizers.length() - 1; i >= 0; --i) {
			if (colonizers[i].update(emp, time) >= QSS_Destroyed) {
				trackedColonizers.erase(colonizers[i].shipID);
				colonizers.erase(i);
			}
		}

		// Make sure our expansion system is still viable
		if (context.expandSys !is null) {
			int expandID = context.expandSys.toObject().uid;
			if (!data.canSee(emp, context.expandSys) || (!claimedExpansion && data.setHas(GS_ExpansionSystems, expandID))) {
				resetExpansion(data, emp);
			}
			else if (context.expandSys.hasEnemyMilitaryOf(emp)
					&& !context.expandSys.hasPlanets(emp)) {
				if (getEnemyStrength(context.expandSys, emp, true) > data[PV_IgnoreMilitaryScale])
					resetExpansion(data, emp);
			}
		}
	}

	int getExpansionCount() {
		return colonizers.length();
	}

	// }}}
	// {{{ Retrofitting
	bool assignRetrofit(EmpireAIData@ data, Empire@ emp, Object@ obj) {
		OrderList list;
		if (list.prepare(obj)) {
			// Give the order
			list.giveOrder("AutoRetrofit:true:", false);

			if (logging)
				log("Retrofitting "+obj.getName());

			// Add to tracking retrofit
			uint n = retrofitting.length();
			retrofitting.resize(n+1);
			@retrofitting[n] = QueuedShip(obj.uid, QSS_Waiting, 240.f);
			return true;
		}
		return false;
	}
	// }}}
	// {{{ Update things to go on in the system
	bool update(EmpireAIData@ data, Empire@ emp, float time) {
		// Update various small things
		Object@ obj = sys;

		// Check if we have enemies
		hasEnemies = sys.hasEnemiesOf(emp);
		hasEnemyMilitary = sys.hasEnemyMilitaryOf(emp);
		return false;
	}

	void firstTick(EmpireAIData@ data, Empire@ emp) {
	}

	bool fullUpdate(EmpireAIData@ data, Empire@ emp) {
		// Check how long it's been since our last full update
		float time = gameTime - lastFullUpdate;
		lastFullUpdate = gameTime;

		// Keep a lock here, to speed things up
		ObjectLock(sys.toObject());

		// Check if we still have planets
		if (!sys.hasPlanets(emp)) {
			resetExpansion(data, emp);
			contextSweep.disable();
			return true;
		}

		// Check if we are the home system
		if (data.homeSystem is null) {
			@data.homeSystem = sys;
			priority = OP_High;
		}

		// Find closest fleet
		@closestFleet = data.getClosestFleet(sys.toObject().getPosition());

		// Check all objects in the system and gather stats
		SysObjList objs;
		objs.prepare(sys);
		Object@ sysObj = sys;

		// Check if we should do our first tick
		if (!startTick) {
			startTick = true;
			firstTick(data, emp);
		}

		// Update the planets fully
		developedPlanets = lowPlanets = highPlanets = 0;
		ownedPlanets = int(planets.length());
		for (int i = 0; i < ownedPlanets; ++i) {
			if (planets[i].update(data, emp, this, time)) {
				controlledPlanets.erase(planets[i].planet.toObject().uid);
				planets.erase(i);
				--i; --ownedPlanets;
			}
			else {
				if (planets[i].developed)
					++developedPlanets;
				if (planets[i].avgStored < 0.3f)
					++lowPlanets;
				if (planets[i].avgStored > 0.7f)
					++highPlanets;
			}
		}

		// Collect data about system
		enemyStrength = 0;
		ourStrength = sysObj.getStrength(emp);
		uint empCnt = getEmpireCount();
		for (uint i = 0; i < empCnt; ++i) {
			Empire@ otherEmp = getEmpire(i);
			if (!otherEmp.isValid())
				continue;

			if (sys.hasMilitary(otherEmp) && emp.isEnemy(otherEmp))
				enemyStrength += sysObj.getStrength(otherEmp);
		}

		// Update moving colonizers
		updateExpansion(data, emp, time);

		// Data to track for objects
		uint maxRetrofit = uint(data[PV_SystemMaxRetrofitting]);
		int prevUnownedPlanets = unownedPlanets;
		ownedPlanets = int(planets.length());
		developed = unownedPlanets == 0 && developedPlanets == ownedPlanets;
		unownedPlanets = 0;
		hasEnemyPlanets = false;
		enemyRatio = ourStrength > 0 ? enemyStrength / ourStrength : enemyStrength;

		hasNotableEnemies = hasEnemyMilitary && enemyRatio > data[PV_NotableEnemyRatio];
		
		numRoids = 0;

		// Track ships present per goal
		for (uint i = 0; i < uint(GID_COUNT); ++i) {
			shipsPresent[i] = 0;
			scalePresent[i] = 0;
		}

		// Track static defenses for a single planet
		PlanetController@ tracking;
		if (ownedPlanets > 0) {
			trackingPlanet = (trackingPlanet + 1) % ownedPlanets;
			@tracking = planets[trackingPlanet];
			tracking.defenses = 0;
		}

		// Update current retrofitting
		for (int i = retrofitting.length() - 1; i >= 0; --i) {
			if (retrofitting[i].update(emp, time) >= QSS_Built)
				retrofitting.erase(i);
		}

		// Check objects
		bool tempring = false;
		for (uint i = 0; i < objs.childCount; ++i) {
			Object@ obj = objs.getChild(i);
			Planet@ pl = obj;
			HulledObj@ hulled = obj;
			Oddity@ odd = obj;

			// * Check for owned planets to add
			if (pl !is null)  {
				if (obj.getOwner() is emp) {
					if (!manages(pl)) {
						PlanetController@ ctrl = PlanetController(pl);
						ctrl.init(data, emp, this);

						manage(ctrl);
						data.hasActivity = true;
					}
					if(pl.getPhysicalType() == "ringworld" && tempring == false)
						tempring = true;
				}
				else {
					if (!obj.getOwner().isValid())
						++unownedPlanets;
					if (obj.getOwner().isEnemy(emp))
						hasEnemyPlanets = true;
				}
			}
	
			else if (odd !is null)	{
				// Asteroid stuff
				if (odd.getOddityType() == ODT_Asteroid && odd.getOddityType() != ODT_Comet) {
					float val = 0.f, we = 0.f;
					obj.getStateVals(strOre, val, we, we, we);
					if (val > 0.f)
						numRoids++;
				}
			}
				
			else if (hulled !is null) {
				// Track ships by goal
				if (obj.getOwner() is emp) {
					const HullLayout@ layout = hulled.getHull();
					uint goal = layout.metadata;

					++shipsPresent[goal];
					scalePresent[goal] += sqr(layout.scale);

					switch (goal) {
						case GID_StaticDefense:
							// Track defenses per planet
							if (tracking !is null) {
								Object@ orbiting = obj.inOrbitAround();
								if (orbiting is tracking.planet) {
									tracking.defenses += sqr(layout.scale);
									
									if (retrofitting.length() < maxRetrofit
										&& layout !is layout.getLatestVersion()
										&& data.getConstructionBottleneck() >= RS_Surplus
									) {
										assignRetrofit(data, emp, obj);
									}
								}
							}
						break;
						
						case GID_Colonize:
							// Send off spare colonizers when we can
							if (unownedPlanets == 0 && context.expandSys !is null && !trackedColonizers.exists(obj.uid)
									&& (data.systemControllers.length() * (30.f - (data.difficulty * 5.f)) < gameTime / 60.f
									  || data.manages(context.expandSys) || gameTime / 60.f > 90.f - (data.difficulty * 10.f))
									&& canExpandExternally) {
								OrderList list;
								if (list.prepare(obj)) {
									Object@ expObj = context.expandSys.toObject();
									list.giveGotoOrder(expObj, false);
									list.giveGotoOrder(obj.getParent(), true);

									trackExpansion(data, emp, obj);
								}
							}
						break;

						case GID_Miner:	
						case GID_Trade:
							if (retrofitting.length() < maxRetrofit
								&& layout !is layout.getLatestVersion()
								&& data.getConstructionBottleneck() >= RS_Surplus) {
								assignRetrofit(data, emp, obj);
							}
						break;
						
						case GID_Carrier:
						case GID_Fight:
						case GID_FightSpecialised:
						case GID_Lead:
						case GID_Tanker:
							// Add stuff that should have a fleet to a fleet
							if (closestFleet !is null && hulled.getFleet() is null) {
								HulledObj@ leader = closestFleet.fleet.getCommander();
								if (leader !is null) {
									OrderList list;
									if (list.prepare(obj))
										list.joinFleet(leader);
								}
							}
						break;
					}
				}
			}
		}
		
		//Set the ringworld bool
		if(tempring == false && ringworld == true)
			ringworld = false;
		else if(tempring == true && ringworld == false)
			ringworld = true;

		// Remove ourselves from the expansion list when appropriate
		if (prevUnownedPlanets > 0 && unownedPlanets == 0) {
			data.setRemove(GS_ExpansionSystems, sysObj.uid);
			sysObj.setStat(emp, strExpansion, 0);
		}
		
		// Check if we should build scouts
		if (!hasNotableEnemies && scoutTimer.tick(time)) {
			if (context.undiscovered > 0) {
				int scouts = int(context.undiscovered * data[PV_ScoutBuildWeight]);
				tryBuild(data, data.getRandomLayout(emp, GID_Explore), max(scouts, 1), false, null);
			}
		}
		
		// Check if we should build a ringworld
		if (!hasNotableEnemies && ringTimer.tick(time)) {
			if(!ringworld) {
				const HullLayout@ ring = emp.getShipLayout("Ringworld");
				if(ring !is null) {
					//Get resources
					float mtls = ring.getStats().getCost("Metal"), elecs = ring.getStats().getCost("Electronics"), parts = ring.getStats().getCost("AdvParts");
					float netm = data.getResData(RT_Metals, RD_Net), nete = data.getResData(RT_Electronics, RD_Net), neta = data.getResData(RT_AdvParts, RD_Net);
					if(netm >= sqrt(mtls) && nete >= sqrt(elecs)&& neta >= sqrt(parts)) {
						ringworld = true;
						tryBuild(data, ring, true);
					}
				}
			}
		}		

		// Queue expansion
		if (expandTimer.tick(time)) {
			if (logging)
				log("Expand Update");

			// We can always expand outwards if this is the only system left
			if (!canExpandExternally && data.systemControllers.length() <= 1)
				canExpandExternally = true;

			// Build colony ships for other planets in this system if we can
			if (unownedPlanets > 0 && unownedPlanets > shipsPresent[GID_Colonize]) {
				if (data.getBottleneck(rf_mtl | rf_elc | rf_adv | rf_fud) >= RS_Surplus || priority >= OP_High) {
					int num = tryBuild(data, data.getRandomLayout(emp, GID_Colonize), 1, false, null);
					if (logging)
						log("Building local colonizers: "+num);
				}
				else if (logging)
					log("Not building local colonizers: insufficient resources");
			}

			/// Build colony ships for the expansion system if we can
			else if (context.expandSys !is null && canExpandExternally) {
				int planetsLeft = getUncolonizedPlanets(context.expandSys);
				if (planetsLeft == 0) {
					resetExpansion(data, emp);
					if (logging)
						log("Completed system");
				}
				else if (planetsLeft > getExpansionCount()) {
					if (data.getBottleneck(rf_mtl | rf_elc | rf_adv | rf_fud) >= RS_Surplus &&
							(data.systemControllers.length() * (30.f - (data.difficulty * 5.f)) < gameTime / 60.f
							  || data.manages(context.expandSys) || gameTime / 60.f > 90.f - (data.difficulty * 10.f))) {
						int id = tryBuild(data, data.getRandomLayout(emp, GID_Colonize), false);
						if (id > 0) {
							data.queue(MoveBuiltShip(id, context.expandSys, sys));
							queueExpansion(data, emp, id);
							if (logging)
								log("Built external colonizer");
						}
						else if (logging)
							log("Failed building external colonizer");
					}
				}
			}
		}

		// Queue military and defenses
		if (developTimer.tick(time)) {
			ResourceStatus bottleneck = data.getBottleneck(rf_mtl | rf_elc | rf_adv | rf_ful);
			// Develop by building haulers in this system if there is more than one owned planet and no enemies	and bank resources are low.		
            if(!hasNotableEnemies && bottleneck <= RS_Critical && ownedPlanets > 1) {
				if (shipsPresent[GID_Trade] < ownedPlanets && gameTime > 60.f * 60.f) {
					float weight = (ownedPlanets / (shipsPresent[GID_Trade] > 0 ? shipsPresent[GID_Trade]: 1));
					if (randomf(1.f) < weight)
						tryBuild(data, data.getRandomLayout(emp, GID_Trade), false);
				}
				else if ((emp.hasTraitTag("half_exports") && getGameTime() < 1200.0)
					&& (shipsPresent[GID_Trade] < ownedPlanets * 10)) {
					float weight = ((ownedPlanets) / (shipsPresent[GID_Trade] > 0 ? shipsPresent[GID_Trade]: 1));
					if (randomf(1.f) < weight)
						tryBuild(data, data.getRandomLayout(emp, GID_Trade), false);
				}
			}	
				// Make farmers if there are asteroids
			if (!hasNotableEnemies && numRoids > 0) {
				float weight = (pow(numRoids, 0.25f) / (shipsPresent[GID_Miner] > 0 ? shipsPresent[GID_Miner]: 1));
				if (randomf(1.f) < weight) {
					if (data.getResStatus(RT_Electronics) <= RS_Low)
						tryBuild(data, emp.getShipLayout("Orbital Electronics Factory"), false);
					else if (data.getResStatus(RT_AdvParts) <= RS_Low)
						tryBuild(data, emp.getShipLayout("Orbital Advanced Parts Factory"), false);
					else if (data.getResStatus(RT_Metals) <= RS_Low)
						tryBuild(data, emp.getShipLayout("Orbital Metal Factory"), false);
				}		
			}

			PlanetController@ developing;
			if (ownedPlanets > 0) {
				developingPlanet = (developingPlanet + 1) % ownedPlanets;
				@developing = planets[developingPlanet];
			}

			// Develop defenses on the developing planet
			if(developing !is null) {
				float shipbay, shipbayUsed;
				developing.planet.toObject().getShipBayVals(shipbayUsed, shipbay);

				if (developing.inQueue == 0
					&& ((shipbayUsed <= 1.f
							 && hasNotableEnemies
							 && (enemyRatio > data[PV_EnemyRatioIgnore]))
						|| (bottleneck >= RS_Enough))
					&& gameTime > data[PV_MilitaryBlock]
				) {
					float offensive = (context.frontline + enemyStrength) / 10 * developing.totalPriority;

					if (offensive > 0) {
						// Check if we should build fighter craft or defenses
						float fighterChance = 0, shipbayFree = shipbay - shipbayUsed;

						if (hasEnemies && (shipbayFree > 0 && shipbayUsed < offensive &&
								 scalePresent[GID_StrikeCraft] < offensive * ownedPlanets))
							fighterChance = data[PV_FighterChance];

						// Build fighters
						if (fighterChance > 0 && randomf(1.f) < fighterChance) {
							float budget = min(developing.getBuildBudget(data), shipbayFree);
							if (!hasNotableEnemies)
								budget /= 4.f;

							const HullLayout@ fighter = data.getRandomLayout(emp, GID_StrikeCraft, budget);

							if (fighter !is null) {
								budget /= sqr(fighter.scale);
								if (budget > 0)
									developing.buildShip(fighter, min(int(budget), 40), true);
							}
						}
					}
				}
				
				// Develop Defenses
				if(bottleneck >= RS_Enough && gameTime > data[PV_MilitaryBlock] && developing.defenses < (sqrt(50) * sqrt(developing.planet.getMaxStructureCount())) * (gameTime / (60.f * 60.f))) {
					float budget = developing.getBuildBudget(data);
					const HullLayout@ defense = data.getRandomLayout(emp, GID_StaticDefense, budget);

					if (defense !is null) {
						budget /= sqr(defense.scale);
						if (budget > 0) {
							developing.buildShip(defense);							
						}
					}
				}
			}
			// Develop fleet strength for nearby fleet
			if (bottleneck >= RS_Enough && gameTime > data[PV_MilitaryBlock]) 
			{
				if (closestFleet !is null && closestFleet.getDistanceFromSQ(sysObj) < data[PV_MaxFleetDist]) {
					if (data.difficulty >= 3 || closestFleet.sys is sys)
						// Support an existing fleet
						closestFleet.buildAt(data, emp, this);
				}
				else {
					// Build a new fleet
					GoalID goal = GID_Lead;
					if (data.difficulty == 1)
						goal = GID_Fight;

					const HullLayout@ layout = data.getRandomLayout(emp, goal);
					int id = tryBuild(data, layout, false);
					if (id > 0)
						data.queue(SysFleetBuiltShip(id, this));
				}
			}				
		}
		return false;
	}
	// }}}
	// {{{ Managed planets
	bool manages(Planet@ pl) {
		return controlledPlanets.exists(pl.toObject().uid);
	}

	void manage(PlanetController@ pl) {
		uint num = planets.length();
		planets.resize(num+1);
		@planets[num] = pl;
		if (pl.planet !is null)
			controlledPlanets.insert(pl.planet.toObject().uid);
	}
	// }}}
	// {{{ Debug messages
	void onDebugMessage(EmpireAIData@ data, Empire@ emp, string@ arg) {
		if (arg == "context") {
			context.dump();
		}
		else if (arg == "exp") {
			if (context.expandSys is null)
				warning("Expansion: None");
			else
				warning("Expansion: to "+context.expandSys.toObject().getName()+" has "+getExpansionCount());
		}
		else if (arg == "col") {
			warning("Colonizers: "+colonizers.length());
			for (uint i = 0; i < colonizers.length(); ++i)
				colonizers[i].dump();
		}
		else if (arg == "local") {
			warning("Unowned planets: "+unownedPlanets);
			warning("Present colonizers: "+shipsPresent[GID_Colonize]);
		}
		else if (arg == "log") {
			logging = !logging;
			if (logging)
				log("now logging");
			else
				log("no longer logging");
		}
	}

	void log(string@ text) {
		warning(sys.toObject().getName()+": "+text);
	}
	// }}}
	// {{{ Build ships in this system
	// Try to build up to num, return how many were actually queued
	int tryBuild(EmpireAIData@ data, const HullLayout@ layout, int maxNum, bool allowQueue, BuiltShipCallback@ cb) {
		if (layout is null)
			return 0;
		uint cnt = planets.length();
		float scale = sqr(layout.scale);
		for (uint i = 0; i < cnt; ++i) {
			if (!allowQueue && planets[i].inQueue > 0)
				continue;
			// If we're using different govs, don't use resource planets	
			string@ govtype = planets[i].planet.getGovernorType();
			if ((govtype == "metalworld" ||
				govtype == "agrarian" ||
				govtype == "resworld" ||
				govtype == "fuelworld" ||
				govtype == "h3fuelworld" ||	
				govtype == "h3logworld" ||		
				govtype == "logworld" ||
				govtype == "ammoworld" ||
				govtype == "luxworld" ||
				govtype == "elecworld" ||
				govtype == "advpartworld" ||
				govtype == "economic" && scale > 20.f) || 
				(govtype == "resworld" || 
				govtype == "luxworld")
				)
			continue;
			float budget = planets[i].getBuildBudget(data);
			int build = min(maxNum, int(budget / scale));

			if (build > 0) {
				if (cb !is null)
					planets[i].buildShip(layout, build, cb);
				else
					planets[i].buildShip(layout, build, false);

				maxNum -= build;
				if (maxNum == 0)
					break;
			}
		}
		return maxNum;
	}

	int tryBuild(EmpireAIData@ data, const HullLayout@ layout, bool allowQueue) {
		if (layout is null)
			return 0;
		uint cnt = planets.length();
		float scale = sqr(layout.scale);
		for (uint i = 0; i < cnt; ++i) {
			if (!allowQueue && planets[i].inQueue > 0)
				continue;
			// If we're using different govs, don't use resource planets	
			string@ govtype = planets[i].planet.getGovernorType();
			if ((govtype == "metalworld" ||
				govtype == "agrarian" ||
				govtype == "resworld" ||
				govtype == "fuelworld" ||
				govtype == "h3fuelworld" ||	
				govtype == "h3logworld" ||		
				govtype == "logworld" ||
				govtype == "ammoworld" ||
				govtype == "luxworld" ||
				govtype == "elecworld" ||
				govtype == "advpartworld" ||
				govtype == "economic" && scale > 20.f) || 
				(govtype == "resworld" || 
				govtype == "luxworld")
				)
			continue;				
			int budget = planets[i].getBuildBudget(data) / scale;
			if (budget > 0)
				return planets[i].buildShip(layout);
		}
		return 0;
	}
	// }}}
	// {{{ Collect data about the context around the system
	void addContext(const EmpireAIData@ data, Empire@ emp, SystemContextData& context, System@ other) const {
		Object@ otherObj = other;
		Object@ sysObj = sys;

		// Don't count things in our system, rely on the updates to do that
		if (other is sys)
			return;

		// Calculate weight
		float dist = otherObj.position.getDistanceFromSQ(sysObj.position);
		float weight = 100000000.f / dist;

		// Ignore systems with too little weight
		if (weight < data[PV_ContextNeglectWeight])
			return;

		// General data
		bool visible = data.canSee(emp, other);
		if (!visible) {
			float visited = otherObj.getStat(emp, str_visited);
			visible = visited > 0 && visited >= float(gameTime - 120.f);
		}

		// Determine how much unexplored territory is around us
		if (!visible) {
			if (!emp.isScouting(other)) {
				// Put less weight into already explored things
				if (other.hasExplored(emp))
					context.undiscovered += weight * data[PV_ScoutExploredWeight];
				else
					context.undiscovered += weight;
			}
		}
		else {
			// Determine how many enemies we can see close to this system
			float numWeight = 0.f;
			float remnWeight = 0.f;
			if (other.hasEnemiesOf(emp)) {
				// Check for enemy planets and military
				float planetsWeight = data[PV_PlanetsStrength];

				uint empCnt = getEmpireCount();
				for (uint i = 0; i < empCnt; ++i) {
					Empire@ otherEmp = getEmpire(i);
					if (!otherEmp.isValid())
						continue;

					if (emp.isEnemy(otherEmp)) {
						// Deal differently with remnants and pirates
						if (otherEmp.ID < 0) {
							if (other.hasMilitary(otherEmp)) {
								if (otherEmp.ID == -3)
									remnWeight += otherObj.getStrength(otherEmp) * data[PV_RemnantWeight];
							}
						}
						else {
							if (other.hasPlanets(otherEmp))
								numWeight += planetsWeight;
							if (other.hasMilitary(otherEmp))
								numWeight += otherObj.getStrength(otherEmp);
						}
					}
				}

				if (numWeight > 0) {
					if (dist < data[PV_ContextFrontlineMaxDist])
						context.frontline += numWeight * weight;

					if (dist < context.closestEnemyDist || context.closestEnemyDist < 0) {
						context.closestEnemyDist = dist;
						@context.closestEnemies = other;
						context.closestEnemyStrength = numWeight;
					}
				}

				if (remnWeight > 0) {
					context.remnants += remnWeight * weight;

					if (dist < context.closestRemnantDist || context.closestRemnantDist < 0) {
						context.closestRemnantDist = dist;
						@context.closestRemnants = other;
						context.closestRemnantStrength = numWeight;
					}
				}
			}

			// We might be able to expand into this system
			if (!other.hasEnemyMilitaryOf(emp) || (numWeight < data[PV_IgnoreMilitaryScale] && remnWeight == 0)) {
				// Check if we are already expanding here
				if (otherObj.getStat(emp, strExpansion) < 0.5f) {
					if (otherObj.getStat(emp, strManaged) < 0.5f) {
						if (otherObj.getStat(emp, strAIAvoid) < 0.5f) {
							// Check if we have unowned systems here
							int planetCount = getUncolonizedPlanets(other);

							if (planetCount > 0) {
								context.expansion += weight * planetCount;

								// System that already have other empire planets should have a lower weight
								double wt = dist;
								if (planetCount != otherObj.getStat(getEmpireByID(-1), str_planets))
									wt *= 3.0;

								if (context.expandDist < 0 || wt < context.expandDist) {
									context.expandDist = wt;
									@context.expandSys = other;
									context.expandPlanets = planetCount;
								}
							}
						}
					}
				}
			}
		}
	}

	void setContext(EmpireAIData@ empData, Empire@ emp, SystemContextData& data) {
		// Retrieve some previous data for interpolation purposes
		double prevFrontline = context.frontline;
		double prevUndiscovered = context.undiscovered;

		System@ lastExpandSys = context.expandSys;
		int lastExpandPlanets = context.expandPlanets;

		// Set all data
		context = data;

		// Make sure we're still expanding to the same thing
		if (!claimedExpansion) {
			@lastExpandSys = null;
		}
		else if (lastExpandSys !is null && lastExpandSys !is context.expandSys) {
			@context.expandSys = lastExpandSys;
			context.expandPlanets = lastExpandPlanets;
		}

		// Make sure this is a valid expansion system
		if (lastExpandSys is null && context.expandSys !is null) {
			int expID = context.expandSys.toObject().uid;
			if (empData.setHas(GS_ExpansionSystems, expID) || empData.manages(context.expandSys)) {
				@context.expandSys = null;
			}
			else {
				claimedExpansion = false;
				colonizers.resize(0);
			}
		}

		// Frontline should fall off slowly
		context.frontline = context.frontline * 0.15 + prevFrontline * 0.85;
	}
	// }}}
	// {{{ Fleet handling
	bool manages(Fleet@ fleet) {
		return controlledFleets.exists(fleet.ID);
	}

	bool manages(FleetController@ fleet) {
		return controlledFleets.exists(fleet.fleet.ID);
	}

	void registerFleet(FleetController@ fleet) {
		if (manages(fleet))
			return;
		uint num = fleets.length();
		fleets.resize(num+1);
		@fleets[num] = fleet;
		controlledFleets.insert(fleet.fleet.ID);
	}

	void deregisterFleet(FleetController@ fleet) {
		if (!manages(fleet))
			return;
		controlledFleets.erase(fleet.fleet.ID);
		for (uint i = 0; i < fleets.length(); ++i) {
			if (fleets[i] is fleet) {
				fleets.erase(i);
				break;
			}
		}
	}
	// }}}
	// {{{ Saving and Loading
	void save(XMLWriter@ xml) {
		xml.addElement("context", false);
		context.save(xml);
		xml.closeTag("context");

		xml.addElement("id", true, "v", i_to_s(sys is null ? -1 : sys.toObject().uid));

		xml.addElement("enemyStrength", true, "v", f_to_s(enemyStrength));
		xml.addElement("ourStrength", true, "v", f_to_s(ourStrength));
		xml.addElement("enemyRatio", true, "v", f_to_s(enemyRatio));

		xml.addElement("expandTimer", true, "v", f_to_s(expandTimer.getRemaining()));
		xml.addElement("scoutTimer", true, "v", f_to_s(scoutTimer.getRemaining()));
		xml.addElement("developTimer", true, "v", f_to_s(developTimer.getRemaining()));
		xml.addElement("ringTimer", true, "v", f_to_s(ringTimer.getRemaining()));
		
		xml.addElement("canExpandExternally", true, "v", canExpandExternally ? "1" : "0");
		xml.addElement("hasEnemyPlanets", true, "v", hasEnemyPlanets ? "1" : "0");
		xml.addElement("claimedExpansion", true, "v", claimedExpansion ? "1" : "0");
		xml.addElement("priority", true, "v", i_to_s(priority));
		xml.addElement("ringworld", true, "v", ringworld ? "1" : "0");

		for (uint i = 0; i < planets.length(); ++i) {
			xml.addElement("planet", false);
			planets[i].save(xml);
			xml.closeTag("planet");
		}

		for (uint i = 0; i < colonizers.length(); ++i) {
			xml.addElement("queued", false, "type", "colonizer");
			colonizers[i].save(xml);
			xml.closeTag("queued");
		}

		for (uint i = 0; i < retrofitting.length(); ++i) {
			xml.addElement("queued", false, "type", "retrofit");
			retrofitting[i].save(xml);
			xml.closeTag("queued");
		}
	}

	SystemController(EmpireAIData@ data, Empire@ emp, XMLReader@ xml) {
		createVars(data);

		// Load data
		bool reading = true;
		while (xml.advance() && reading) {
			string@ name = xml.getNodeName();
			switch(xml.getNodeType()) {
				case XN_Element:
					if (name == "context") {
						context.load(xml);
					}
					else if (name == "id") {
						int id = s_to_i(xml.getAttributeValue("v"));
						if (id > 0)
							@sys = getObjectByID(id);
					}
					else if (name == "enemyStrength") {
						enemyStrength = s_to_f(xml.getAttributeValue("v"));
					}
					else if (name == "ourStrength") {
						ourStrength = s_to_f(xml.getAttributeValue("v"));
					}
					else if (name == "enemyRatio") {
						enemyRatio = s_to_f(xml.getAttributeValue("v"));
					}
					else if (name == "expandTimer") {
						expandTimer.setRemaining(s_to_f(xml.getAttributeValue("v")));
					}
					else if (name == "scoutTimer") {
						scoutTimer.setRemaining(s_to_f(xml.getAttributeValue("v")));
					}
					else if (name == "developTimer") {
						developTimer.setRemaining(s_to_f(xml.getAttributeValue("v")));
					}
					else if (name == "ringTimer") {
						developTimer.setRemaining(s_to_f(xml.getAttributeValue("v")));
					}
					else if (name == "canExpandExternally") {
						canExpandExternally = xml.getAttributeValue("v") == "1";
					}
					else if (name == "hasEnemyPlanets") {
						hasEnemyPlanets = xml.getAttributeValue("v") == "1";
					}
					else if (name == "claimedExpansion") {
						claimedExpansion = xml.getAttributeValue("v") == "1";
					}
					else if (name == "ringworld") {
						ringworld = xml.getAttributeValue("v") == "1";
					}
					else if (name == "priority") {
						priority = ObjectPriority(s_to_i(xml.getAttributeValue("v")));
					}
					else if (name == "planet") {
						manage(PlanetController(data, emp, xml));
					}
					else if (name == "queued") {
						string@ type = xml.getAttributeValue("type");
						if (type == "retrofit") {
							uint n = retrofitting.length();
							retrofitting.resize(n+1);
							@retrofitting[n] = QueuedShip(xml);
						}
						else {
							uint n = colonizers.length();
							colonizers.resize(n+1);
							@colonizers[n] = QueuedShip(xml);
						}
					}
				break;
				case XN_Element_End:
					if (name == "system")
						reading = false;
				break;
			}
		}

		// Check if we have enemies
		hasEnemies = sys.hasEnemiesOf(emp);
		hasEnemyMilitary = sys.hasEnemyMilitaryOf(emp);

		// Find closest fleet
		@closestFleet = data.getClosestFleet(sys.toObject().getPosition());
		data.addSweep(contextSweep);
	}
	// }}}
};
/* }}} */
/* {{{ Planet Controller */
class PlanetController {
	Planet@ planet;
	ObjectPriority priority;
	int totalPriority;
	bool developed;
	float defenses;
	bool checkd;
	bool buildingImp;
	bool logging;
	bool changed;

	// Construction resource completion percentage
	float[] construction;
	PlanetResource bottleneck;
	PlanetResource lowRes;
	uint inQueue;

	float[] stored;
	float avgStored;

	PlanetController(Planet@ pl) {
		@planet = pl;
		createVars();
	}

	void createVars() {
		inQueue = 0;
		defenses = 0;
		bottleneck = PR_None;
		priority = OP_Normal;
		totalPriority = 2;
		developed = false;
		checkd = false;
		buildingImp = false;
		logging = false;
		changed = false;

		construction.resize(PR_COUNT);
		stored.resize(PR_COUNT);
	}

	void init(EmpireAIData@ data, Empire@ emp, SystemController@ sys) {
		// Check if we're the home planet
		if (data.homePlanet is null && data.homeSystem is sys.sys) {
			@data.homePlanet = planet;
			priority = OP_High;
			changed = true;
		}
	}	

	// {{{ Update logic
	bool update(EmpireAIData@ data, Empire@ emp, SystemController@ sys, float time) {
		Object@ obj = planet;
		bool gettingstuff = false;
		
		// Remove this planet if we no longer own it
		if (obj.getOwner() !is emp)
			return true;

		// Remove this planet if it's in a different system somehow
		if (obj.getParent() !is sys.sys)
			return true;

		// Update data
		developed = planet.getStructureCount() >= uint(planet.getMaxStructureCount()) - 1; //Allow for port rebuilding.
		totalPriority = int(priority) * int(sys.priority);
		if (sys.hasNotableEnemies)
			totalPriority += 1;

		updateConstructionData();
		updateStorageData();

		// Check if we should get a weapon or shield gettingstuff bool is now used to decide if we should not reset governors when system has enemy forces in
		if ( sys.hasNotableEnemies && inQueue == 0 && (sys.priority >= OP_High || bottleneck >= RS_Enough)) {
			const subSystemDef@ weapon1 = getSubSystemDefByName(strPlanetWeapon1);
			const subSystemDef@ weapon2 = getSubSystemDefByName(strPlanetWeapon2);
			const subSystemDef@ weapon3 = getSubSystemDefByName(strPlanetWeapon3);
			const subSystemDef@ weapon4 = getSubSystemDefByName(strPlanetWeapon4);
			const subSystemDef@ weapon5 = getSubSystemDefByName(strPlanetWeapon5);			
			const subSystemDef@ pshields = getSubSystemDefByName(strPlanetShields);	
			
			//Shields
			if (emp.subSysUnlocked(pshields)) {
				int numShield = planet.getStructureCount(pshields);
				if (developed && numShield == 0) {
					int replaceable = getReplaceableBuilding(data);
					if (replaceable >= 0) {
						if (planet.usesGovernor())
							planet.setUseGovernor(false);
						planet.removeStructure(replaceable);
						planet.buildStructure(pshields);						
						gettingstuff = true;                  
					}
				}
			}	
			
			//Weapons
			if (emp.subSysUnlocked(weapon1) || emp.subSysUnlocked(weapon2) || emp.subSysUnlocked(weapon3) || emp.subSysUnlocked(weapon4) || emp.subSysUnlocked(weapon5)) {
				if (developed) {
					int replaceable = getReplaceableBuilding(data);
					if (replaceable >= 0) {
						if (planet.usesGovernor())
							planet.setUseGovernor(false);	
		
						planet.removeStructure(replaceable);	
						
						//Continue On through the switch statements not breaking till either a weapon is build or case 3 is completed.
						uint choice = rand(3);	
						switch(choice) {
							case 1:	
								if(emp.subSysUnlocked(weapon4)) {
									planet.buildStructure(weapon4);
									break;
								}	
								else if (emp.subSysUnlocked(weapon2)) {
									planet.buildStructure(weapon2);
									break;
								}	
							
							case 2:								
								if(emp.subSysUnlocked(weapon5)) {
									planet.buildStructure(weapon5);
									break;
								}	
									
							case 3: default:
								if(emp.subSysUnlocked(weapon3))
									planet.buildStructure(weapon3);
								else if (emp.subSysUnlocked(weapon1))
									planet.buildStructure(weapon1);
							break;	
						}	
						
						gettingstuff = true;
					}
				}
			}
		}
		else if (!sys.hasNotableEnemies) {
			gettingstuff = false;
			planet.setUseGovernor(true);
		}


		// Select Governor and Reactivate if deactivated
		if (!gettingstuff) 
		{	
			if (!changed)
			{
				selectGovernor(planet, data);
				planet.setUseGovernor(true);
				changed = true;
				if(logging) {
					string@ gov = planet.getGovernorType();
					warning("Selected "+gov+" Governor");
				}	
			}			
			if(!planet.usesGovernor()) 
			{
				planet.setUseGovernor(true);
			}
		}

		// Check if we should build improvement
		buildingImp = obj.getFlag(objImprovement);
		if(developed && !buildingImp && gameTime > 90 * 60)
			buildImprovement(planet, data);
		
		// Check if we should import or export resources
		if (data.difficulty >= 3)
			updateTradeModes(data, emp, sys);

		return false;
	}
	// }}}
	// {{{ Data collection
	int getReplaceableBuilding(EmpireAIData@ data) {
		PlanetStructureList list;
		list.prepare(planet);

		StringList@ repl = cast<StringList@>(data[PL_RepleacableBuildings]);
		uint replCnt = repl.length();

		uint count = list.getCount();
		for (uint i = 0; i < count; ++i) {
			const subSystemDef@ def = list.getStructure(i).type;
			for (uint n = 0; n < replCnt; ++n) {
				if (def is getSubSystemDefByName(repl.get(n)))
					return i;
			}
		}
		return -1;
	}

	void updateConstructionData() {
		Object@ obj = planet;

		// Update construction status
		inQueue = obj.getConstructionQueueSize();
		if (inQueue > 0) {
			float bottleneckSize = 1.f;
			bottleneck = PR_None;

			for (uint i = 0; i < uint(PR_COUNT); ++i) {
				float req = 0.f, done = 0.f;
				obj.getConstructionCost(0, getResourceName(getResourceType(PlanetResource(i))), done, req);
				float perc = req > 0 ? done / req : 1.f;

				if (perc < bottleneckSize)  {
					perc = bottleneckSize;
					bottleneck = PlanetResource(i);
				}
				construction[i] = perc;
			}
		}
		else {
			bottleneck = PR_None;
			for (uint i = 0; i < uint(PR_COUNT); ++i)
				construction[i] = 1.f;
		}
	}

	void updateStorageData() {
		Object@ obj = planet;

		float lowPerc = 1.f;
		avgStored = 0.f;
		lowRes = PR_None;

		for (uint i = 0; i < uint(PR_COUNT); ++i) {
			float val = 0.f, max = 0.f, temp = 0.f, perc = 1.f;
			if (obj.getStateVals(getResourceName(getResourceType(PlanetResource(i))), val, max, temp, temp))
				perc = max > 0 ? val / max : 1.f;

			avgStored += perc / PR_COUNT;
			if (perc < lowPerc) {
				lowPerc = perc;
				lowRes = PlanetResource(i);
			}
			stored[i] = perc;
		}
	}
	// }}}
	// {{{ Actions
	void updateTradeModes(EmpireAIData@ data, Empire@ emp, SystemController@ sys) {
		Object@ obj = planet;
		State@ state = obj.getState(strTradeMode);

		state.val = float(int(getTradeMode(PR_AdvParts, data)));
		state.max = float(int(getTradeMode(PR_Electronics, data)));
		state.required = float(int(getTradeMode(PR_Metals, data)));
		state.inCargo = float(int(getTradeMode(PR_Food, data)));
	}

	TradeMode getTradeMode(PlanetResource res, EmpireAIData@ data) {
		// If we have enough of this resource, we don't care
		float perc = stored[uint(res)];
		if (perc >= 0.5f)
			return TM_All;

		ResourceStatus status = data.getResStatus(getResourceType(res));
		if (status <= RS_Low && totalPriority < 5)
			return TM_ExportOnly;
		return TM_All;
	}
	// }}}
	// {{{ Build order manipulation
	float getBuildBudget(EmpireAIData@ data) {
		// Only build on fully developed planets
		if (!developed)
			return 0;

		// Calculate the maximum amount of scale we can build
		float budget = 0.f;
		
		int shipyards = planet.getStructureCount(getSubSystemDefByName(strShipYard));
		budget += 6.f * shipyards;

		int spaceports = planet.getStructureCount(getSubSystemDefByName(strSpacePort));
		budget += 5.f * sqrt(spaceports);
		
		// Our resource status affects the maximum we can build
		budget *= 0.4f + 0.6f * min(stored[PR_Metals], min(stored[PR_Electronics], min(stored[PR_AdvParts], stored[PR_Fuel])));

		// Affected by global scale multiplier
		budget *= data[GD_ScaleMultiplier];

		// Increase our budget if we have a ton of resources in the back
		if (data.getConstructionBottleneck() >= RS_Surplus)
			budget *= data[PV_BudgetSurplusMultiplier];

		return budget;
	}

	int buildShip(const HullLayout@ layout) {
		if (layout is null)
			return 0;
		return planet.toObject().makeShip(layout);
	}

	void buildShip(const HullLayout@ layout, uint count, bool batch) {
		if (layout is null)
			return;
		planet.toObject().makeShip(layout, count, batch);
	}

	void buildShip(const HullLayout@ layout, uint count, BuiltShipCallback@ action) {
		if (layout is null)
			return;
		for (uint i = 0; i < count; ++i) {
			int id = planet.toObject().makeShip(layout);
			if (id > 0)
				action.act(id);
		}
	}
	
	void selectGovernor(Planet@ pl, EmpireAIData@ data) {
		State@ ore = pl.toObject().getState(strOre), h3 = pl.toObject().getState(strH3);
		Empire@ emp = getActiveEmpire();
		float slots = pl.getMaxStructureCount();		
		
		ResourceStatus metal = data.getResStatus(RT_Metals);
		ResourceStatus elecs = data.getResStatus(RT_Electronics);
		ResourceStatus parts = data.getResStatus(RT_AdvParts);
		ResourceStatus ammo = data.getResStatus(RT_Ammo);
		ResourceStatus fuel = data.getResStatus(RT_Fuel);
		ResourceStatus food = data.getResStatus(RT_Food);
		ResourceStatus goods = data.getResStatus(RT_Goods);
		ResourceStatus luxes = data.getResStatus(RT_Luxuries);
		
		
		
		if(logging)
		{
			warning("Choosing Gov On " + planet.toObject().getName());
			warning("metal: " + i_to_s(int(metal)));
			warning("elects: " + i_to_s(int(elecs)));
			warning("parts: " + i_to_s(int(parts)));
			warning("ammo: " + i_to_s(int(ammo)));
			warning("fuel: " + i_to_s(int(fuel)));
			warning("food: " + i_to_s(int(food)));
			warning("goods: " + i_to_s(int(goods)));
			warning("luxes: " + i_to_s(int(luxes)));
		}
		
		//Heavily prefer economic development in the early game
		if(gameTime < 10.0 * 60.0) 
		{
			if(pl.hasCondition("geotherm") || pl.hasCondition("sterile"))
			{
				pl.setGovernorType("economic");
				return;
			}
			if(pl.hasCondition("ore_rich") || pl.hasCondition("ore_extreme") && !pl.hasCondition("ore_poor"))
			{
				pl.setGovernorType("metalworld");
				return;
			}
			else
			{
				pl.setGovernorType("default");
				return;
			}			
		}
		else 
		{
			if(pl.hasCondition("ringworld_special"))
			{
				pl.setGovernorType("forge");
				return;
			}
			if(pl.hasCondition("geotherm") || pl.hasCondition("sterile") || pl.hasCondition("ore_rich") || pl.hasCondition("ore_extreme") && !pl.hasCondition("ore_poor")) 
			{
				if(metal >= RS_Surplus && elecs >= RS_Surplus && parts >= RS_Surplus) {
					pl.setGovernorType("forge");
					return;
				}
				else if(metal <= RS_Enough || elecs <= RS_Enough || parts <= RS_Enough) {
					pl.setGovernorType("economic");
					return;
				}
			}
			else if(pl.hasCondition("rare_pheno") || pl.hasCondition("remnant_research") || pl.hasCondition("remant_relic") || pl.hasCondition("neutrino_bombardment") && !pl.hasCondition("unstable") && !pl.hasCondition("high_winds")) 
			{
				pl.setGovernorType("resworld");
				return;
			}
			else if(pl.hasCondition("dense_flora") && !pl.hasCondition("barren_waste")) 
			{
				if(food <= RS_Low) {
					pl.setGovernorType("agrarian");
					return;
				}
			}			
			else if(pl.hasCondition("natural_catalysts")) 
			{
				if(fuel <= RS_Low) {
					if(h3.val > 0) {
						pl.setGovernorType("h3fuelworld");
						return;
					}
					else if(food >= RS_Enough) {
						pl.setGovernorType("fuelworld");
						return;
					}
				}
				else if(ammo <= RS_Critical) {
					pl.setGovernorType("ammoworld");
					return;
				}			
				else if(fuel < RS_Enough && ammo < RS_Enough) 
				{
					if(h3.val > 0) {
						pl.setGovernorType("h3logworld");
						return;
					}
					else if(food >= RS_Enough) {
						pl.setGovernorType("logworld");
						return;
					}
				}
			}
			else 
			{
				if(slots >= 30 && (metal >= RS_Surplus && elecs >= RS_Surplus && parts >= RS_Surplus)) {
					pl.setGovernorType("shipworld");
					return;
				}
				else if (food < RS_Enough) {
					pl.setGovernorType("agrarian");
					return;
				}				
				else if(slots <= 10)
				{
					pl.setGovernorType("resworld");
					return;
				}				
				else if(fuel <= RS_Low) {
					if(h3.val > 0) {
						pl.setGovernorType("h3fuelworld");
						return;
					}
					else if(food >= RS_Enough) {
						pl.setGovernorType("fuelworld");
						return;
					}
				}
				else {
					pl.setGovernorType("economic");
					return;
				}
			}
		}
	}
	
	void buildImprovement(Planet@ pl, EmpireAIData@ data) {
		Object@ obj = pl;
		State@ form = obj.getState(strTerraform);
		
		ResourceStatus metal = data.getResStatus(RT_Metals);
		ResourceStatus elecs = data.getResStatus(RT_Electronics);
		ResourceStatus parts = data.getResStatus(RT_AdvParts);	
		
		if(metal >= RS_Surplus && elecs >= RS_Surplus && parts >= RS_Surplus) 
		{
			if(form.val > 0) 
			{
				const subSystemDef@ def = getSubSystemDefByName("Terraforming");
				if(def is null)
					return;
				else if(obj.getOwner().subSysUnlocked(def))
					terraForm("Terraforming", obj.uid);
			}
			else
			{
				return;	
			}	
		}
		else
		{
			return;
		}	
	}	
	// }}}
	// {{{ Saving and Loading
	void save(XMLWriter@ xml) {
		xml.addElement("id", true, "v", i_to_s(planet is null ? -1 : planet.toObject().uid));
		xml.addElement("priority", true, "v", i_to_s(priority));
	}

	PlanetController(EmpireAIData@ data, Empire@ emp, XMLReader@ xml) {
		createVars();

		// Load data
		while (xml.advance()) {
			string@ name = xml.getNodeName();
			switch(xml.getNodeType()) {
				case XN_Element:
					if (name == "id") {
						int id = s_to_i(xml.getAttributeValue("v"));
						if (id > 0)
							@planet = getObjectByID(id);
					}
					else if (name == "priority") {
						priority = ObjectPriority(s_to_i(xml.getAttributeValue("v")));
					}
				break;
				case XN_Element_End:
					if (name == "planet")
						return;
				break;
			}
		}
	}
	// }}}
};
/* }}} */
/* {{{ Fleet Controller */
/* {{{ Fleet context */
/* {{{ Fleet Context Data Collection Sweep */
class UpdateFleetContext : SystemSweep {
	FleetController@ ctrl;
	FleetContextData context;
	bool disabled;

	UpdateFleetContext(FleetController@ fleet) {
		@ctrl = fleet;
		disabled = false;
		context.reset();
	}

	float call(const EmpireAIData@ data, Empire@ emp, System@ sys) {
		if (ctrl !is null)
			ctrl.addContext(data, emp, context, sys);
		return 0;
	}

	void disable() {
		disabled = true;
		@ctrl = null;
	}

	bool complete(EmpireAIData@ data, Empire@ emp, System@ best) {
		if (disabled)
			return true;
		if (ctrl !is null)
			ctrl.setContext(data, emp, context);
		context.reset();
		return false;
	}
};
/* }}} */
class FleetContextData {
	// Closest system to defend/patrol
	System@ patrolSys;
	double bestPatrolSys;
	float patrolDist;
	float patrolEnemies;

	// Closest system to attack
	System@ attackSys;
	double bestAttackSys;
	float attackDist;
	float attackEnemies;

	// Closest system to clear from remnants
	System@ remnSys;
	double bestRemnSys;
	float remnDist;
	float remnEnemies;

	FleetContextData() {
		reset();
	}

	void reset() {
		@patrolSys = null;
		bestPatrolSys = 0;
		patrolEnemies = 0;
		patrolDist = 0;

		@attackSys = null;
		bestAttackSys = 0;
		attackEnemies = 0;
		attackDist = 0;

		@remnSys = null;
		bestRemnSys = 0;
		remnEnemies = 0;
		remnDist = 0;
	}

// {{{ Debugging
	void dump() {
		if (patrolSys is null)
			warning("Patrol: (null)");
		else
			warning("Patrol: "+patrolSys.toObject().getName());

		if (attackSys is null)
			warning("Attack: (null)");
		else
			warning("Attack: "+attackSys.toObject().getName());

		if (remnSys is null)
			warning("Remnants: (null)");
		else
			warning("Remnants: "+remnSys.toObject().getName());
	}
// }}}
// {{{ Saving and loading
	void save(XMLWriter@ xml) {
		xml.addElement("patrolSys", true, "v", i_to_s(patrolSys is null ? -1 : patrolSys.toObject().uid));
		xml.addElement("bestPatrolSys", true, "v", f_to_s(bestPatrolSys));
		xml.addElement("patrolDist", true, "v", f_to_s(patrolDist));
		xml.addElement("patrolEnemies", true, "v", f_to_s(patrolEnemies));
		xml.addElement("attackSys", true, "v", i_to_s(attackSys is null ? -1 : attackSys.toObject().uid));
		xml.addElement("bestAttackSys", true, "v", f_to_s(bestAttackSys));
		xml.addElement("attackDist", true, "v", f_to_s(attackDist));
		xml.addElement("attackEnemies", true, "v", f_to_s(attackEnemies));
		xml.addElement("remnSys", true, "v", i_to_s(remnSys is null ? -1 : remnSys.toObject().uid));
		xml.addElement("bestRemnSys", true, "v", f_to_s(bestRemnSys));
		xml.addElement("remnDist", true, "v", f_to_s(remnDist));
		xml.addElement("remnEnemies", true, "v", f_to_s(remnEnemies));
	}

	void load(XMLReader@ xml) {
		while (xml.advance()) {
			string@ name = xml.getNodeName();
			switch(xml.getNodeType()) {
				case XN_Element:
					if (name == "patrolSys") {
						int id = s_to_i(xml.getAttributeValue("v"));
						if (id > 0)
							@patrolSys = getObjectByID(id);
					}
					else if (name == "bestPatrolSys") {
						bestPatrolSys = s_to_f(xml.getAttributeValue("v"));
					}
					else if (name == "patrolDist") {
						patrolDist = s_to_f(xml.getAttributeValue("v"));
					}
					else if (name == "patrolEnemies") {
						patrolEnemies = s_to_f(xml.getAttributeValue("v"));
					}
					else if (name == "attackSys") {
						int id = s_to_i(xml.getAttributeValue("v"));
						if (id > 0)
							@attackSys = getObjectByID(id);
					}
					else if (name == "bestAttackSys") {
						bestAttackSys = s_to_f(xml.getAttributeValue("v"));
					}
					else if (name == "attackDist") {
						attackDist = s_to_f(xml.getAttributeValue("v"));
					}
					else if (name == "attackEnemies") {
						attackEnemies = s_to_f(xml.getAttributeValue("v"));
					}
					else if (name == "remnSys") {
						int id = s_to_i(xml.getAttributeValue("v"));
						if (id > 0)
							@remnSys = getObjectByID(id);
					}
					else if (name == "bestRemnSys") {
						bestRemnSys = s_to_f(xml.getAttributeValue("v"));
					}
					else if (name == "remnDist") {
						remnDist = s_to_f(xml.getAttributeValue("v"));
					}
					else if (name == "remnEnemies") {
						remnEnemies = s_to_f(xml.getAttributeValue("v"));
					}
				break;
				case XN_Element_End:
					if (name == "context")
						return;
				break;
			}
		}
	}
// }}}
};
/* }}} */
/* {{{ Main fleet controller */
interface FleetHandler {
	void init(EmpireAIData@ data, Empire@ emp, FleetController@ fleet);
	FleetState update(EmpireAIData@ data, Empire@ emp, FleetController@ fleet, float time);

	void save(XMLWriter@ xml);
	void load(Empire@ emp, XMLReader@ xml);
};

class FleetController {
	Fleet@ fleet;
	FleetContextData context;
	UpdateFleetContext@ contextSweep;
	bool logging;

	System@ sys;
	SystemController@ sysCtrl;

	System@ targetSystem;
	float targetEnemies;
	float targetStrength;

	HulledObj@ leader;

	float strength;
	float[] strengths;

	uint count;
	uint militaryCount;
	uint civCount;
	uint[] counts;

	FleetState state;
	FleetHandler@[] handlers;
	bool initialized;

	QueuedShip@[] retrofitting;
	int retrofitNum;
	float lastUpdateTime;

	Timer reMoveTimer;
	Timer reCountTimer;

	FleetController(Fleet@ fl) {
		createVars(fl);

		@targetSystem = sys;
		randomizeFormation();
	}

	void createVars(Fleet@ fl) {

		handlers.resize(FS_COUNT);
		@handlers[FS_Muster] = FleetMuster();
		@handlers[FS_Patrol] = FleetPatrol();
		@handlers[FS_Defend] = FleetDefend();
		@handlers[FS_Campaign] = FleetCampaign();
		@handlers[FS_Eradicate] = FleetEradicate();

		state = FS_Muster;
		initialized = false;
		targetEnemies = -1;
		targetStrength = -1;
		retrofitNum = 0;
		lastUpdateTime = gameTime;

		reMoveTimer.setLength(3.f * 60.f);
		reMoveTimer.randomize();

		reCountTimer.setLength(16.f);
		reCountTimer.randomize();

		logging = false;

		counts.resize(GID_COUNT);
		strengths.resize(GID_COUNT);

		@fleet = fl;
		@leader = fleet.getCommander();

		if (leader !is null)
			@sys = leader.toObject().getParent();

		updateShipCounts();
	}

	void randomizeFormation() {
		fleet.setFormation(FleetFormation(rand(0, 3)));
	}

	void init(EmpireAIData@ data, Empire@ emp) {
		initialized = true;
		logging = data.logFleets;
		for (uint i = 0; i < uint(FS_COUNT); ++i)
			handlers[i].init(data, emp, this);
	}

	void remove() {
		@sysCtrl = null;
		@sys = null;
		@fleet = null;
	}

	float getDistanceFromSQ(Object@ from) {
		if (leader is null) return pow(10, 35);
		return from.getPosition().getDistanceFromSQ(leader.toObject().getPosition());
	}

	// {{{ Build logic
	int buildAt(EmpireAIData@ data, Empire@ emp, SystemController@ sys) {
		if (counts[GID_Tanker] < uint(ceil(0.05f * float(count))))
			return doBuild(data, emp, sys, GID_Tanker, ceil(0.05f * float(count)) - counts[GID_Tanker]);
		if (counts[GID_Lead] < uint(0.10 * count) && data.difficulty > 1)
			return doBuild(data, emp, sys, GID_Lead, 0.10 * count - counts[GID_Lead]);
		if (counts[GID_FightSpecialised] < uint(0.15 * count))
			return doBuild(data, emp, sys, GID_FightSpecialised, 0.15 * count - counts[GID_FightSpecialised]);
		if (counts[GID_Carrier] < uint(0.04 * count) && data.getRandomLayout(emp, GID_Carrier) !is null)
			return doBuild(data, emp, sys, GID_Carrier, 0.04 * count - counts[GID_Carrier]);
		return doBuild(data, emp, sys, GID_Fight, -1);
	}

	int doBuild(EmpireAIData@ data, Empire@ emp, SystemController@ sys, GoalID goal, int maxCount) {
		const HullLayout@ lay = data.getRandomLayout(emp, goal);
		if (lay is null) return 0;

		// Figure out the max amount of ships to build in one go
		int maxShips = sys.developedPlanets * 2;
		if (sys.context.expandSys is null)
			maxShips *= 3;
		if (sys.fleets.length() > 0)
			maxShips *= 3;
		if (data.getConstructionBottleneck() >= RS_Surplus)
			maxShips *= 2;
		maxShips *= data.difficultyFactor;

		BuiltShipCallback@ cb = BuiltShipActor(data, SysFleetBuiltShip(0, sys));
		uint amount = 0;

		if (maxCount > 0)
			amount = sys.tryBuild(data, lay, min(maxCount, maxShips), false, cb);
		else
			amount = sys.tryBuild(data, lay, maxShips, false, cb);

		return amount;
	}
	// }}}
	// {{{ Update logic
	bool update(EmpireAIData@ data, Empire@ emp, float time) {
		// Make sure we're still active
		if (fleet is null) {
			if (contextSweep !is null)
				contextSweep.disable();
			return true;
		}

		Object@ prevLeader = leader;

		// Update simple fleet data
		@leader = fleet.getCommander();
		count = fleet.getMemberCount();
		strength = fleet.strength;

		// Kill the fleet if we must
		Object@ leaderObj = leader;
		if (leaderObj is null || leaderObj.getOwner() !is emp) {
			if (count == 0) {
				if (contextSweep !is null)
					contextSweep.disable();
				return true;
			}
			else {
				return false;
			}
		}

		// Make sure we are a military ship
		if (!leader.isMilitary()) {
			// Check if the entire fleet is non-military at this point
			if (militaryCount == 0) {
				// Find a fleet to merge into
				uint fleetCount = data.fleetControllers.length();
				for (uint i = 0; i < fleetCount; ++i) {
					FleetController@ ctrl = data.fleetControllers[i];
					if (ctrl !is this) {
						mergeInto(ctrl);
						if (contextSweep !is null)
							contextSweep.disable();
						return true;
					}
				}
				if (contextSweep !is null)
					contextSweep.disable();
				return true;
			}

			// Pick a different leader
			OrderList orders;
			if (orders.prepare(leader)) {
				orders.forfeitFleetCommand();

				@leader = fleet.getCommander();
				@leaderObj = leader;

				if (leaderObj is null || leaderObj.getOwner() !is emp) {
					if (count == 0) {
						if (contextSweep !is null)
							contextSweep.disable();
						return true;
					}
					else {
						return false;
					}
				}

				orders.joinFleet(leaderObj);
			}
		}

		// Figure out the system we're in
		System@ leaderParent = leaderObj.getParent();

		if (leaderParent !is sys) {
			if (sysCtrl !is null)
				sysCtrl.deregisterFleet(this);
			if (sys is null)
				@targetSystem = sys;
			@sys = leaderParent;
			@sysCtrl = data.getController(sys);
			if (sysCtrl !is null)
				sysCtrl.registerFleet(this);
		}

		// Make sure we're moving to the right system
		if (sys !is targetSystem && targetSystem !is null)
			if (leader !is prevLeader || reMoveTimer.tick(time))
				setTargetSystem(targetSystem);

		// Make sure we're initialized
		if (!initialized)
			init(data, emp);

		return false;
	}

	bool fullUpdate(EmpireAIData@ data, Empire@ emp) {
		// Get update time
		float time = gameTime - lastUpdateTime;
		lastUpdateTime = gameTime;

		// Make sure our sweep is running
		if (contextSweep is null) {
			@contextSweep = UpdateFleetContext(this);
			data.addSweep(contextSweep);
		}

		// Update extensive fleet data
		if (reCountTimer.tick(time))
			updateShipCounts();

		// Update current retrofitting
		for (int i = retrofitting.length() - 1; i >= 0; --i) {
			if (retrofitting[i].update(emp, time) >= QSS_Built)
				retrofitting.erase(i);
		}

		// Check enemies in target system
		if (targetSystem !is null) {
			if (data.canSee(emp, targetSystem)) {
				Object@ targSys = targetSystem;
				targetEnemies = 0;
				targetStrength = targSys.getStrength(emp);

				uint empCnt = getEmpireCount();
				for (uint i = 0; i < empCnt; ++i) {
					Empire@ otherEmp = getEmpire(i);
					if (!otherEmp.isValid())
						continue;

					if (emp.isEnemy(otherEmp)) {
						if (targetSystem.hasMilitary(otherEmp))
							targetEnemies += targSys.getStrength(otherEmp);
						if (targetSystem.hasPlanets(otherEmp))
							targetEnemies += data[PV_PlanetsStrength];
					}
				}
			}
			else {
				targetEnemies = -1;
				targetStrength = -1;
				fleet.stayInFormation = true;
			}
		}

		// Update state handler
		state = handlers[state].update(data, emp, this, time);
		if (state == FS_DEAD) {
			if (contextSweep !is null)
				contextSweep.disable();
			return true;
		}
		return false;
	}

	void setTargetSystem(System@ sys) {
		if (targetSystem !is sys) {
			@targetSystem = sys;
			targetEnemies = -1;
			targetStrength = -1;
		}

		if (leader !is null && leader.toObject().getOwner() !is null) {
			OrderList list;
			if (list.prepare(leader.toObject())) {
				list.clearOrders(false);
				if (targetSystem !is null)
					list.giveGotoOrder(targetSystem.toObject(), false);
			}
		}
	}

	void updateShipCounts() {
		// Update the types of ships we have
		count = fleet.getMemberCount();
		militaryCount = 0;
		civCount = 0;
		for (uint i = 0; i < uint(GID_COUNT); ++i) {
			counts[i] = 0;
			strengths[i] = 0;
		}

		if (leader !is null) {
			// Add stats for the leader
			const HullLayout@ layout = leader.getHull();
			uint num = uint(layout.metadata);

			++counts[num];
			strengths[num] += sqr(layout.scale);

			if (leader.isMilitary())
				++militaryCount;
			else
				++civCount;

			// Check if the leader still has orders left
			OrderList orders;
			if (orders.prepare(leader.toObject())) {
				if (orders.getOrderCount() == 0)
					orders.refreshAutomation();
			}
		}

		for (uint i = 0; i < fleet.getMemberCount(); ++i) {
			HulledObj@ member = fleet.getMember(i);
			if (member !is null) {
				const HullLayout@ layout = member.getHull();
				uint num = uint(layout.metadata);
				float scale = sqr(layout.scale);

				if (member.isMilitary())
					++militaryCount;
				else
					++civCount;

				++counts[num];
				strengths[num] += scale;
			}
		}
	}
	// }}}
	// {{{ Data collection functions
	bool hasSufficientFuel() {
		// We always need at least 5% tankers
		if (counts[GID_Tanker] < uint(ceil(0.05f * float(count))))
			return false;
		if (counts[GID_Tanker] == 0)
			return false;

		// Check fullness of tanker fuel
		float suppliedPerTanker = (0.95f * float(count)) / float(counts[GID_Tanker]);
		float totalSupplies = 0.f;

		for (uint i = 0; i < fleet.getMemberCount(); ++i) {
			HulledObj@ member = fleet.getMember(i);
			if (member !is null) {
				const HullLayout@ layout = member.getHull();
				uint num = uint(layout.metadata);

				if (layout.metadata == GID_Tanker) {
					float val = 0.f, temp = 0.f;
					if (member.toObject().getStateVals(strFuel, val, temp, temp, temp))
						totalSupplies += suppliedPerTanker * val;
				}
			}
		}

		return totalSupplies >= 0.50f * float(count);
	}
	// }}}
	// {{{ Collect data about the context around the fleet
	void addContext(const EmpireAIData@ data, Empire@ emp, FleetContextData& context, System@ other) const {
		Object@ otherObj = other;
		Object@ sysObj = sys;

		// Don't count things in our system, rely on the updates to do that
		if (other is sys || sysObj is null || leader is null)
			return;

		// Calculate weight
		float dist = getDistanceFromSQ(otherObj);
		if (dist == 0) return;
		float weight = 100000000.f / dist;

		// Ignore systems with too little weight
		if (weight < data[PV_ContextNeglectWeight])
			return;

		// Vision stays for two minutes after the scout leaves
		bool visible = data.canSee(emp, other);
		if (!visible)
			visible = otherObj.getStat(emp, str_visited) >= float(gameTime - 120.f);

		// Ignore completely invisible systems
		if (!visible)
			return;

		// Check for ourselves
		bool ours = other.hasPlanets(emp);

		// Check for enemy planets and military
		float numWeight = 0.f;
		float remnWeight = 0.f;
		float planetsWeight = data[PV_PlanetsStrength];
		int planets = -1;
		bool hasEnemyPlanets = false;

		if (other.hasEnemiesOf(emp)) {
			uint empCnt = getEmpireCount();
			for (uint i = 0; i < empCnt; ++i) {
				Empire@ otherEmp = getEmpire(i);
				if (!otherEmp.isValid())
					continue;

				if (emp.isEnemy(otherEmp)) {
					// Deal differently with remnants and pirates
					if (otherEmp.ID < 0) {
						if (other.hasMilitary(otherEmp)) {
							if (otherEmp.ID == -3) {
								remnWeight += otherObj.getStrength(otherEmp) * data[PV_RemnantWeight];

								if (planets < 0)
									planets = otherObj.getStat(getEmpireByID(-1), str_planets);
							}
						}
					}
					else {
						if (other.hasPlanets(otherEmp)) {
							numWeight += planetsWeight;
							hasEnemyPlanets = true;
						}
						if (other.hasMilitary(otherEmp))
							numWeight += otherObj.getStrength(otherEmp);
					}
				}
			}
		}

		if (numWeight > 0) {
			if (ours) {
				double wt = numWeight * weight;
				if (wt > context.bestPatrolSys) {
					context.bestPatrolSys = wt;
					context.patrolDist = dist;
					context.patrolEnemies = numWeight;
					@context.patrolSys = other;
				}
			}
			else {
				double wt = weight / numWeight;
				if (hasEnemyPlanets)
					wt *= 0.2f;
				if (wt > context.bestAttackSys) {
					context.bestAttackSys = wt;
					context.attackDist = dist;
					context.attackEnemies = numWeight;
					@context.attackSys = other;
				}
			}
		}
		else if (ours && dist <= data[PV_FleetPatrolDist]) {
			double wt = randomf(1.f) * weight;
			if (wt > context.bestPatrolSys) {
				context.bestPatrolSys = wt;
				context.patrolDist = dist;
				context.patrolEnemies = 0;
				@context.patrolSys = other;
			}
		}
		else if (ours && dist > data[PV_FleetPatrolDist]) {
			double wt = randomf(1.f) * weight * 0.25;
			if (wt > context.bestPatrolSys) {
				context.bestPatrolSys = wt;
				context.patrolDist = dist;
				context.patrolEnemies = 0;
				@context.patrolSys = other;
			}
		}

		if (remnWeight > 0) {
			double wt = weight / remnWeight * max(planets, 0);
			if (wt > context.bestRemnSys) {
				context.bestRemnSys = wt;
				context.remnDist = dist;
				context.remnEnemies = remnWeight;
				@context.remnSys = other;
			}
		}
	}

	void setContext(EmpireAIData@ empData, Empire@ emp, FleetContextData& data) {
		context = data;
	}
	// }}}
	// {{{ Fleet merging
	void mergeInto(FleetController@ other) {
		if (other is null || other.leader is null)
			return;

		OrderList list;

		// Switch over members
		uint memCnt = fleet.getMemberCount();
		for (uint i = 0; i < memCnt; ++i) {
			Object@ member = fleet.getMember(i);
			if (member !is null) {
				if (list.prepare(member)) {
					list.leaveFleet();
					list.joinFleet(other.leader);
				}
			}
		}

		if (leader !is null) {
			if (list.prepare(leader)) {
				list.forfeitFleetCommand();
				list.joinFleet(other.leader);
			}
		}
	}
	// }}}
	// {{{ Debug
	void onDebugMessage(EmpireAIData@ data, Empire@ emp, string@ arg) {
		if (arg == "context") {
			context.dump();
		}
		else if (arg == "state") {
			warning("State: "+i_to_s(int(state)));
		}
		else if (arg == "target") {
			if (targetSystem is null)
				warning("Target: (null)");
			else
				warning("Target: "+targetSystem.toObject().getName());
		}
		else if (arg == "log") {
			logging = !logging;
			if (logging)
				log("now logging");
			else
				log("no longer logging");
		}
	}

	void log(string@ str) {
		if (leader !is null)
			warning(leader.toObject().getOwner().getName()+"."+fleet.getName()+": "+str);
	}
	// }}}
	// {{{ Retrofitting
	void allowRetrofitNow(EmpireAIData@ data, Empire@ emp) {
		// Make sure we are allowed to retrofit
		if (retrofitting.length() >= uint(data[PV_FleetMaxRetrofitting]))
			return;
		if (fleet.getMemberCount() == 0)
			return;

		// Check members
		if (uint(retrofitNum) > fleet.getMemberCount())
			retrofitNum = 0;

		for (uint i = 0; i < 5; ++i) {
			uint num = retrofitNum;
			retrofitNum = (retrofitNum + 1) % fleet.getMemberCount();

			HulledObj@ member = fleet.getMember(num);

			if (member !is null) {
				const HullLayout@ layout = member.getHull();
				const HullLayout@ newLayout = layout.getLatestVersion();

				if (layout !is newLayout) {
					assignRetrofit(data, emp, member);
					return;
				}
			}
		}

		// Check Leader
		if (leader !is null && militaryCount > 0) {
			const HullLayout@ layout = leader.getHull();
			const HullLayout@ newLayout = layout.getLatestVersion();

			if (layout !is newLayout)
				assignRetrofit(data, emp, leader);
		}
	}

	bool assignRetrofit(EmpireAIData@ data, Empire@ emp, Object@ obj) {
		if (sysCtrl is null)
			return false;

		OrderList list;
		if (list.prepare(obj)) {
			// Give the order
			list.giveOrder("AutoRetrofit:true:", false);

			if (logging)
				log("Retrofitting "+obj.getName());

			// Add to tracking retrofit
			uint n = retrofitting.length();
			retrofitting.resize(n+1);
			@retrofitting[n] = QueuedShip(obj.uid, QSS_Waiting, 240.f);

			// Make sure we join a new fleet
			obj.setFlag(objWaiting, true);
			data.queue(SysFleetBuiltShip(obj.uid, sysCtrl));

			return true;
		}
		return false;
	}
	// }}}
	// {{{ Saving and Loading
	void save(XMLWriter@ xml) {
		xml.addElement("context", false);
		context.save(xml);
		xml.closeTag("context");

		xml.addElement("id", true, "v", i_to_s(fleet.ID));
		xml.addElement("state", true, "v", i_to_s(int(state)));

		xml.addElement("targetSystem", true, "v", i_to_s(targetSystem is null ? -1 : targetSystem.toObject().uid));
		xml.addElement("targetEnemies", true, "v", f_to_s(targetEnemies));
		xml.addElement("targetStrength", true, "v", f_to_s(targetStrength));

		for (uint i = 0; i < uint(FS_COUNT); ++i) {
			xml.addElement("stateData", false, "i", i_to_s(i));
			handlers[i].save(xml);
			xml.closeTag("stateData");
		}

		for (uint i = 0; i < retrofitting.length(); ++i) {
			xml.addElement("queued", false);
			retrofitting[i].save(xml);
			xml.closeTag("queued");
		}
	}

	FleetController(Empire@ emp, XMLReader@ xml) {
		// Load data
		while (xml.advance()) {
			string@ name = xml.getNodeName();
			switch(xml.getNodeType()) {
				case XN_Element:
					if (name == "context") {
						context.load(xml);
					}
					else if (name == "id") {
						int id = s_to_i(xml.getAttributeValue("v"));
						Fleet@ fl = getFleetByID(id);
						createVars(fl);
					}
					else if (name == "targetSystem") {
						int id = s_to_i(xml.getAttributeValue("v"));
						if (id > 0)
							@targetSystem = getObjectByID(id);
					}
					else if (name == "targetEnemies") {
						targetEnemies = s_to_f(xml.getAttributeValue("v"));
					}
					else if (name == "targetStrength") {
						targetStrength = s_to_f(xml.getAttributeValue("v"));
					}
					else if (name == "state") {
						state = FleetState(s_to_i(xml.getAttributeValue("v")));
					}
					else if (name == "stateData") {
						int i = s_to_i(xml.getAttributeValue("i"));
						handlers[i].load(emp, xml);
					}
					else if (name == "queued") {
						uint n = retrofitting.length();
						retrofitting.resize(n+1);
						@retrofitting[n] = QueuedShip(xml);
					}
				break;
				case XN_Element_End:
					if (name == "fleet")
						return;
				break;
			}
		}
	}
	// }}}
};
/* }}} */
/* {{{ Muster new fleet strength */
class FleetMuster : FleetHandler {
	Timer timer;
	System@ lastSys;

	Timer fuelCheckTimer;
	bool hasSufficientFuel;

	void init(EmpireAIData@ data, Empire@ emp, FleetController@ fleet) {
		hasSufficientFuel = true;
		fuelCheckTimer.setLength(20.f);
		fuelCheckTimer.trigger();

	}

	void resetTimer(EmpireAIData@ data, bool hop) {
		// Reset the timer to a short hop or a complete interval
		if (hop)
			timer.setLength(25.f);
		else
			timer.setLength(data[PV_FleetPatrolInterval] / min(1.f, data.difficultyFactor));
		timer.reset();
	}

	FleetState update(EmpireAIData@ data, Empire@ emp, FleetController@ fleet, float time) {
		// Ignore if we're not at our target yet
		if (fleet.sys !is fleet.targetSystem)
			return FS_Muster;

		// Reset timer in a new system
		if (lastSys !is fleet.sys) {
			timer.reset();
			@lastSys = fleet.sys;
		}

		// Stay in formation for the last few minutes so we can prepare to leave
		fleet.fleet.stayInFormation = timer.getProgress() > 0.6f;

		// Check for enough fuel
		if (fuelCheckTimer.tick(time))
			hasSufficientFuel = fleet.hasSufficientFuel();

		// Patrol every once in a while
		if (timer.tick(time)) {
			if (!hasSufficientFuel)
				resetTimer(data, true);

			// When we see an enemy system nearby, and we can probably take it:
			// Lyrical Tokarev, Kill them all!
			if (fleet.context.attackSys !is null
				&& fleet.context.attackEnemies > 0
				&& fleet.context.attackDist < data[PV_FleetAttackDist]
				&& (fleet.strength / fleet.context.attackEnemies) > data[PV_FleetAttackRatio]
				&& hasSufficientFuel
			) {
				resetTimer(data, false);
				fleet.setTargetSystem(fleet.context.attackSys);
				if (fleet.logging)
					fleet.log("Campaign to "+fleet.context.attackSys.toObject().getName());
				return FS_Campaign;
			}
			/*else if (fleet.logging && fleet.context.attackSys !is null) {
				fleet.log("Not campaigning to "+fleet.context.attackSys.toObject().getName());
				fleet.log("    Enemies "+fleet.context.attackEnemies);
				fleet.log("    Distance "+fleet.context.attackDist+" (max: "+data[PV_FleetAttackDist]+")");
				if (fleet.context.attackEnemies > 0)
					fleet.log("    Strength "+(fleet.strength / fleet.context.attackEnemies)
							+" (our: "+fleet.strength+") (min: "+data[PV_FleetAttackRatio]+") ");
				fleet.log("    Fuel? "+(hasSufficientFuel ? "yes" : "no"));
			}*/

			// Eradicate those pest remnants from our galaxy when we have a chance to
			if (fleet.context.remnSys !is null
				&& fleet.context.remnEnemies > 0
				&& fleet.context.remnDist < data[PV_FleetRemnantDist]
				&& (fleet.strength / fleet.context.remnEnemies) > data[PV_FleetRemnantRatio]
				&& hasSufficientFuel
			) {
				resetTimer(data, false);
				fleet.setTargetSystem(fleet.context.remnSys);
				if (fleet.logging)
					fleet.log("Eradicating "+fleet.context.remnSys.toObject().getName());
				return FS_Eradicate;
			}

			// Patrol to a close system
			Object@ sys = fleet.context.patrolSys;
			if (sys !is null
				&& sys !is fleet.sys
				&& fleet.context.patrolDist < data[PV_FleetPatrolDist]
				&& !data.setHas(GS_PatrolSystems, sys.uid)
				&& hasSufficientFuel
			) {
				resetTimer(data, false);
				data.setAdd(GS_PatrolSystems, sys.uid);
				fleet.setTargetSystem(fleet.context.patrolSys);
				if (fleet.logging)
					fleet.log("Patrol to "+fleet.context.patrolSys.toObject().getName());
				return FS_Patrol;
			}
		}

		// When there are enemies here, defend this system
		if (fleet.sysCtrl !is null
			&& (fleet.sys.hasEnemyMilitaryOf(emp)
				|| fleet.sys.hasEnemyPlanetsOf(emp))
		) {
			//timer.reset(); // Gets fleets stuck in systems when enemies trickle in
			fleet.setTargetSystem(fleet.sys);
			if (fleet.logging)
				fleet.log("Defend current "+fleet.sys.toObject().getName());
			return FS_Defend;
		}

		// When there are enemies somewhere close, defend from them
		if (fleet.context.patrolSys !is null
			&& fleet.context.patrolSys !is fleet.sys
			&& fleet.context.patrolEnemies > 0
			&& fleet.strength / fleet.context.patrolEnemies > data[PV_FleetDefendMinRatio]
			&& fleet.context.patrolDist < data[PV_FleetDefendDist]
			&& data.canSee(emp, fleet.context.patrolSys)
			&& (fleet.context.patrolSys.hasEnemyMilitaryOf(emp)
				|| fleet.context.patrolSys.hasEnemyPlanetsOf(emp))
			&& hasSufficientFuel
		) {
			resetTimer(data, false);
			fleet.setTargetSystem(fleet.context.patrolSys);
			if (fleet.logging)
				fleet.log("Defense to "+fleet.context.patrolSys.toObject().getName());
			return FS_Defend;
		}

		if (fleet.sysCtrl !is null
			&& fleet.sysCtrl.developed
			&& timer.getProgress() < 0.5f
			&& !fleet.sys.hasEnemyMilitaryOf(emp)
			&& !fleet.sys.hasEnemyPlanetsOf(emp)
			&& data.getConstructionBottleneck() >= RS_Enough
		) {
			fleet.allowRetrofitNow(data, emp);
		}
		return FS_Muster;
	}

	void fullUpdate(EmpireAIData@ data, Empire@ emp, FleetController@ fleet) {
	}

	void save(XMLWriter@ xml) {
		xml.addElement("timer", true, "v", i_to_s(timer.getRemaining()));
		xml.addElement("lastSys", true, "v", i_to_s(lastSys is null ? -1 : lastSys.toObject().uid));
	}

	void load(Empire@ emp, XMLReader@ xml) {
		while (xml.advance()) {
			string@ name = xml.getNodeName();
			switch(xml.getNodeType()) {
				case XN_Element:
					if (name == "timer") {
						timer.setRemaining(s_to_i(xml.getAttributeValue("v")));
					}
					else if (name == "lastSys") {
						int id = s_to_i(xml.getAttributeValue("v"));
						if (id > 0)
							@lastSys = getObjectByID(id);
					}
				break;
				case XN_Element_End:
					if (name == "stateData")
						return;
				break;
			}
		}
	}
}
/* }}} */
/* {{{ Patrol border systems */
class FleetPatrol : FleetHandler {
	void init(EmpireAIData@ data, Empire@ emp, FleetController@ fleet) {
	}

	FleetState update(EmpireAIData@ data, Empire@ emp, FleetController@ fleet, float time) {
		if (fleet.sys is fleet.targetSystem) {
			data.setRemove(GS_PatrolSystems, fleet.sys.toObject().uid);
			return FS_Muster;
		}

		// Stay in formation during travel
		fleet.fleet.stayInFormation = true;

		return FS_Patrol;
	}

	void fullUpdate(EmpireAIData@ data, Empire@ emp, FleetController@ fleet) {
	}

	void save(XMLWriter@ xml) {
	}

	void load(Empire@ emp, XMLReader@ xml) {
	}
}
/* }}} */
/* {{{ Defend our own systems */
class FleetDefend : FleetHandler {
	void init(EmpireAIData@ data, Empire@ emp, FleetController@ fleet) {
	}

	FleetState update(EmpireAIData@ data, Empire@ emp, FleetController@ fleet, float time) {
		// Stay in formation during travel and when in heavy combat
		fleet.fleet.stayInFormation = (fleet.sys !is fleet.targetSystem)
			|| (fleet.targetEnemies > 0
				&& fleet.targetStrength / fleet.targetEnemies
					< data[PV_FleetMopupRatio]);

		if (fleet.sys !is fleet.targetSystem)
			return FS_Defend;
		if (fleet.sys.hasEnemyMilitaryOf(emp) || fleet.sys.hasEnemyPlanetsOf(emp))
			return FS_Defend;
		return FS_Muster;
	}

	void fullUpdate(EmpireAIData@ data, Empire@ emp, FleetController@ fleet) {
	}

	void save(XMLWriter@ xml) {
	}

	void load(Empire@ emp, XMLReader@ xml) {
	}
}
/* }}} */
/* {{{ Attack enemy systems */
class FleetCampaign : FleetHandler {
	Timer timer;

	void init(EmpireAIData@ data, Empire@ emp, FleetController@ fleet) {
		timer.setLength(data[PV_FleetCampaignInterval] / min(1.f, data.difficultyFactor));
	}

	FleetState update(EmpireAIData@ data, Empire@ emp, FleetController@ fleet, float time) {
		// Stay in formation during travel and when in heavy combat
		fleet.fleet.stayInFormation = (fleet.sys !is fleet.targetSystem)
			|| (fleet.targetEnemies > 0
				&& fleet.targetStrength / fleet.targetEnemies
					< data[PV_FleetMopupRatio]);

		// If we're not at our destination yet, wait
		if (fleet.sys !is fleet.targetSystem)
			return FS_Campaign;

		// Retreat if overpowered
		if (fleet.targetEnemies > 0 && data.difficulty >= 3) {
			float ratio = max(fleet.targetStrength, fleet.strength) / fleet.targetEnemies;
			if (ratio < data[PV_FleetRetreatRatio]) {
				Object@ sys = fleet.context.patrolSys;
				if (sys !is null) {
					data.setAdd(GS_PatrolSystems, sys.uid);
					fleet.setTargetSystem(fleet.context.patrolSys);
					if (fleet.logging)
						fleet.log("Campaign -> Retreat to "+sys.getName());
					return FS_Patrol;
				}
			}
		}

		// Stay here until we eliminate all enemies
		if (fleet.sys.hasEnemiesOf(emp)) {
			if (fleet.sys.hasEnemyMilitaryOf(emp)
				|| fleet.sys.hasEnemyPlanetsOf(emp))
				timer.reset();
			return FS_Campaign;
		}

		// Wait for a while after we've killed the enemies
		if (!timer.tick(time))
			return FS_Campaign;

		// Attack another system if we can
		if (fleet.context.attackSys !is null
			&& fleet.context.attackEnemies > 0
			&& fleet.context.attackDist < data[PV_FleetAttackDist]
			&& (fleet.strength / fleet.context.attackEnemies) > data[PV_FleetAttackRatio]
			&& fleet.hasSufficientFuel()
		) {
			fleet.setTargetSystem(fleet.context.attackSys);

			if (fleet.logging)
				fleet.log("Campaign continues to "+fleet.context.attackSys.toObject().getName());
			return FS_Campaign;
		}

		// Otherwise, return to patrolling
		Object@ sys = fleet.context.patrolSys;
		if (sys !is null
			&& fleet.context.patrolDist < data[PV_FleetPatrolDist]
			&& !data.setHas(GS_PatrolSystems, sys.uid)
		) {
			data.setAdd(GS_PatrolSystems, sys.uid);
			fleet.setTargetSystem(fleet.context.patrolSys);
			if (fleet.logging)
				fleet.log("Campaign -> Patrol to "+fleet.context.patrolSys.toObject().getName());
			return FS_Patrol;
		}
		return FS_Campaign;
	}

	void fullUpdate(EmpireAIData@ data, Empire@ emp, FleetController@ fleet) {
	}

	void save(XMLWriter@ xml) {
		xml.addElement("timer", true, "v", i_to_s(timer.getRemaining()));
	}

	void load(Empire@ emp, XMLReader@ xml) {
		while (xml.advance()) {
			string@ name = xml.getNodeName();
			switch(xml.getNodeType()) {
				case XN_Element:
					if (name == "timer") {
						timer.setRemaining(s_to_i(xml.getAttributeValue("v")));
					}
				break;
				case XN_Element_End:
					if (name == "stateData")
						return;
				break;
			}
		}
	}
}
/* }}} */
/* {{{ Eradicate remnants from systems */
class FleetEradicate : FleetHandler {
	Timer timer;

	void init(EmpireAIData@ data, Empire@ emp, FleetController@ fleet) {
		timer.setLength(data[PV_FleetEradicateInterval] / min(1.f, data.difficultyFactor));
	}

	FleetState update(EmpireAIData@ data, Empire@ emp, FleetController@ fleet, float time) {
		// Stay in formation during travel and when in heavy combat
		fleet.fleet.stayInFormation = (fleet.sys !is fleet.targetSystem)
			|| (fleet.targetEnemies > 0
				&& fleet.targetStrength / fleet.targetEnemies
					< data[PV_FleetMopupRatio]);

		// If we're not at our destination yet, wait
		if (fleet.sys !is fleet.targetSystem)
			return FS_Campaign;

		// Retreat if overpowered
		if (fleet.targetEnemies > 0) {
			float ratio = max(fleet.strength, fleet.targetStrength) / fleet.targetEnemies;
			if (ratio < data[PV_FleetRetreatRatio] && data.difficulty >= 3) {
				Object@ sys = fleet.context.patrolSys;
				if (sys !is null) {
					data.setAdd(GS_PatrolSystems, sys.uid);
					fleet.setTargetSystem(fleet.context.patrolSys);
					if (fleet.logging)
						fleet.log("Eradicate -> Retreat to "+sys.getName());
					return FS_Patrol;
				}
			}
		}

		// Stay here until we eliminate all enemies
		if (fleet.sys.hasEnemiesOf(emp)) {
			if (fleet.sys.hasEnemyMilitaryOf(emp)
				|| fleet.sys.hasEnemyPlanetsOf(emp))
				timer.reset();
			return FS_Campaign;
		}

		// Wait for a while after we've killed the enemies
		if (!timer.tick(time))
			return FS_Campaign;

		// Return to patrolling
		Object@ sys = fleet.context.patrolSys;
		if (sys !is null
			&& fleet.context.patrolDist < data[PV_FleetPatrolDist]
			&& !data.setHas(GS_PatrolSystems, sys.uid)
		) {
			data.setAdd(GS_PatrolSystems, sys.uid);
			fleet.setTargetSystem(fleet.context.patrolSys);
			if (fleet.logging)
				fleet.log("Eradicate -> Patrol to "+fleet.context.patrolSys.toObject().getName());
			return FS_Patrol;
		}
		return FS_Campaign;
	}

	void fullUpdate(EmpireAIData@ data, Empire@ emp, FleetController@ fleet) {
	}

	void save(XMLWriter@ xml) {
		xml.addElement("timer", true, "v", i_to_s(timer.getRemaining()));
	}

	void load(Empire@ emp, XMLReader@ xml) {
		while (xml.advance()) {
			string@ name = xml.getNodeName();
			switch(xml.getNodeType()) {
				case XN_Element:
					if (name == "timer") {
						timer.setRemaining(s_to_i(xml.getAttributeValue("v")));
					}
				break;
				case XN_Element_End:
					if (name == "stateData")
						return;
				break;
			}
		}
	}
}
/* }}} */
/* }}} */
/* {{{ Relations Manager */
enum TreatyType {
	TT_Unknown = 0,
	TT_Trade = 1,
	TT_RequestForPeace = 2,
	TT_ThreatForWar = 4,

	TT_Insufficient = 8,
	TT_Expensive = 16,
	TT_Invalid = 32,
};

class TreatyDescriptor {
	uint type;
	float timeout;

	float theirPoints;
	float ourPoints;

	TreatyDescriptor() {
		theirPoints = 0;
		ourPoints = 0;

		timeout = -1.f;
		type = TT_Unknown;
	}
};

class RelationsManager {
	Empire@ other;
	uint lastProposalType;

	float strRatio;
	float strength;
	uint planets;

	float lastUpdateTime;
	bool atWar;
	bool atPeace;
	bool canDeclare;

	Timer proposalTimer;
	Timer treatyTimer;
	Treaty@ proposedTreaty;

	RelationsManager(EmpireAIData@ data, Empire@ emp, Empire@ forEmp) {
		@other = forEmp;
		lastProposalType = TT_Unknown;
		canDeclare = other.isAI() || getGameSetting("AI_IGNORE_PLAYER", 0.f) < 0.5f;

		lastUpdateTime = gameTime;
		proposalTimer.setLength(randomf(data[PV_ProposalMinInterval],
			data[PV_ProposalMaxInterval]));
		proposalTimer.reset();

		updateData(data, emp);
	}

	/* {{{ Data collection */
	void updateData(EmpireAIData@ data, Empire@ emp) {
		atWar = emp.isEnemy(other);
		atPeace = emp.hasTreatyTag(other, strPeaceTreaty);

		strength = other.getStat(strStrength);
		planets = uint(other.getStat(strPlanet));

		float ourStrength = emp.getStat(strStrength) + emp.getStat(strPlanet) * 8.f;
		float theirStrength = strength + planets * 8.f;

		strRatio = ourStrength / max(1.f, theirStrength);
		strRatio /= max(1.f, data[GD_TotalEnemies] + 1.f);
		strRatio *= data[GD_Boredom];

		if (strRatio == 0)
			strRatio = 0.01f;
	}
	/* }}} */
	/* {{{ Update management */
	void update(EmpireAIData@ data, Empire@ emp, float time) {
	}

	void fullUpdate(EmpireAIData@ data, Empire@ emp) {
		// Don't update the first few seconds to prevent team treaties from being rejected
		if (gameTime < 2.f)
			return;

		// Check how long it has been since our last update
		float time = gameTime - lastUpdateTime;
		lastUpdateTime = gameTime;

		// Update generic data in the class
		updateData(data, emp);

		// Don't engage in any diplomacy if we haven't met each other yet
		if (!emp.hasMet(other))
			return;

		TreatyList treaties;
		treaties.prepare(emp);

		// Figure out what's up with our proposal
		if (proposedTreaty !is null) {
			// If active, we're done
			if (proposedTreaty.isActive()) {
				@proposedTreaty = null;
			}

			// If rejected, see if we should declare war
			else if (!proposedTreaty.isProposed()) {
				// If our last proposal was a threat, declare war now
				if (lastProposalType & TT_ThreatForWar != 0 && !atWar) {
					declareWar(emp, other);
				}
				@proposedTreaty = null;
			}

			// If timed out, retract the treaty
			else if (treatyTimer.tick(time)) {
				treaties.retract(other);

				// If our last proposal was a threat, declare war now
				if (lastProposalType & TT_ThreatForWar != 0 && !atWar) {
					declareWar(emp, other);
				}

				// Set timer for a new proposal
				treatyTimer.setLength(randomf(data[PV_ProposalMinInterval],
					data[PV_ProposalMaxInterval]));
				treatyTimer.reset();

				@proposedTreaty = null;
			}
			return;
		}

		Treaty@ proposed = treaties.getProposedTreaty(other);
		if (proposed !is null)  {
			// Consider treaties proposed to us
			if (proposed.getToEmpire() is emp) {
				bool accept = considerTreaty(data, emp, proposed);
				treaties.setAcceptance(other, accept);
			}
		}
		
		// Propose new treaties on a timer
		if (proposalTimer.tick(time)) {
			// Make a new proposal
			if (atWar) {
				if (data[GD_Boredom] < data[PV_BoredomNoBribes]) {
					if (strRatio > 1.f) {
						if (strRatio < data[PV_ConsiderObliterateStrengthRatio]) {
							@proposedTreaty = treaties.getProposedTreaty(other);
							createWarThreat(data, emp, other);
							lastProposalType = TT_ThreatForWar;
						}
					}
					else {
						if (strRatio < data[PV_ConsiderBribeStrengthRatio]) {
							@proposedTreaty = treaties.getProposedTreaty(other);
							createPeaceBribe(data, emp, other);
						}
					}
				}
			}
			else {
				if (gameTime > data[PV_MilitaryBlock]
					&& strRatio > data[PV_ConsiderWarStrengthRatio]
					&& !atPeace && canDeclare
				) {
					if (strRatio > data[PV_ConsiderObliterateStrengthRatio]) {
						declareWar(emp, other);
					}
					else {
						createWarThreat(data, emp, other);
						@proposedTreaty = treaties.getProposedTreaty(other);
						lastProposalType = TT_ThreatForWar;
					}
				}
				else {
					createTradeTreaty(data, emp, other);
					@proposedTreaty = treaties.getProposedTreaty(other);
					lastProposalType = TT_Trade;
				}
			}

			// Set timer for retracting the treaty
			treatyTimer.setLength(randomf(data[PV_ProposalMinTimeout],
				data[PV_ProposalMaxTimeout]));
			treatyTimer.reset();

			proposalTimer.setLength(randomf(data[PV_ProposalMinInterval],
				data[PV_ProposalMaxInterval]));
			proposalTimer.reset();
		}
	}
	/* }}} */
	/* {{{ Treaty Weighing */
	// We use income to express things that aren't resources in points
	float getPtsIndex(EmpireAIData@ data) {
		float mtl = data.getResData(RT_Metals, RD_Income) * getResourceMod(RT_Metals);
		float elc = data.getResData(RT_Electronics, RD_Income) * getResourceMod(RT_Electronics);
		float adv = data.getResData(RT_AdvParts, RD_Income) * getResourceMod(RT_AdvParts);
		float ful = data.getResData(RT_Fuel, RD_Income) * getResourceMod(RT_Fuel);
		float amo = data.getResData(RT_Ammo, RD_Income) * getResourceMod(RT_Ammo);

		return max(mtl, max(elc, adv));
	}
	
	//Calculates the expected payout assuming some chance to default at any moment, using our production as a base for the guess
	float expectedPayout(EmpireAIData@ data, ResourceType type, float rate, float time) {
		// Integrate production * Chance to default so far over time
		float production = data.getResData(type, RD_Income) - (data.getResData(type, RD_Expense) * 0.5f);
		
		//Don't believe huge numbers
		if(rate > production * 10.f)
			rate = production * 10.f;
		
		float pRatio = production / (production + rate);
		return rate * (pow(pRatio, time) - 1.f) / log(pRatio);
	}

	TreatyDescriptor getTreatyInfo(EmpireAIData@ data, Empire@ emp, Treaty@ treaty) {
		TreatyDescriptor desc;

		// Index for non-resource clauses
		float ptsIndex = getPtsIndex(data);
		
		// Check which side we are
		bool usReversed = treaty.getToEmpire() is emp;

		// Collect essential data
		for(uint i = 0; i < treaty.clauseCount; ++i) {
			const Clause@ clause = treaty.getClause(i);
			const string@ id = clause.id;

			if (id == "timeout") {
				desc.timeout = clause.getOption(0).toFloat();
			}
			else if (id == "failwar") {
				desc.type |= TT_ThreatForWar;
			}
			else if (id == "peace") {
				desc.type |= TT_RequestForPeace;
			}
		}

		// If nothing special was found, we have a trade treaty
		if (desc.type == uint(TT_Unknown))
			desc.type = TT_Trade;

		// Get weights for clauses
		for(uint i = 0; i < treaty.clauseCount; ++i) {
			const Clause@ clause = treaty.getClause(i);
			const string@ id = clause.id;

			float pts = 0.f;
			bool reversed = clause.isReversed();
			bool fromUs = reversed == usReversed;

			if (id == "trade") {
				ResourceType resource = getResourceType(clause.getOption(0).toString());
				float requested = clause.getOption(1).toFloat();

				// Get the weight for this resource
				if (resource >= RT_COUNT || (!fromUs && desc.timeout <= 15.f)) {
					//Very short trade offers seem like a scam, so treat that as invalid
					desc.type |= TT_Invalid;
				}
				else if(fromUs)
					pts = getWeightPerUnit(data, emp, resource) * requested * desc.timeout;
				else //Reduce the weight of the large timeouts and resource counts, on the assumption that they can't really provide the resources
					pts = getWeightPerUnit(data, emp, resource) * expectedPayout(data, resource, requested, desc.timeout);

				// Make sure we think we have enough to give
				if (fromUs) {
					float net = data.getResData(resource, RD_Net);
					float stored = data.getResData(resource, RD_Stored);

					if (requested > net && requested * desc.timeout > stored)
						desc.type |= TT_Insufficient;
					else if (requested > net * data[PV_TradeMaxRate] && requested * desc.timeout > stored * data[PV_TradeMaxStored])
						desc.type |= TT_Expensive;
				}
			}
			else if (id == "send") {
				ResourceType resource = getResourceType(clause.getOption(0).toString());
				float requested = clause.getOption(1).toFloat();

				// Get the weight for this resource
				if (resource >= RT_COUNT) {
					desc.type |= TT_Invalid;
				}
				else
					pts = getWeightPerUnit(data, emp, resource) * requested;

				// Make sure we think we have enough to give
				if (fromUs) {
					float stored = data.getResData(resource, RD_Stored);
					if (requested > stored)
						desc.type |= TT_Insufficient;
					else if (requested > stored * data[PV_TradeMaxStored])
						desc.type |= TT_Expensive;
				}
			}
			else if (id == "research") {
				float requested = clause.getOption(0).toFloat();
				float ourResearch = float(emp.getResearchRate());

				// Get the weight for this
				if (desc.timeout <= 0) {
					desc.type |= TT_Invalid;
				}
				else
					pts = (requested / max(ourResearch, 1.f)) * ptsIndex * desc.timeout * 0.2f;

				// Make sure we have enough research left to share
				if (fromUs) {
					float external = emp.getStat(strExternalResearch);

					if (external + requested > ourResearch)
						desc.type |= TT_Insufficient;
				}
			}
			else if (id == "vision") {
				if (desc.timeout <= 0) {
					desc.type |= TT_Invalid;
				}
				pts = ptsIndex * desc.timeout * 0.1f;
			}
			else if (id == "timeout") {
				// Do nothing, handled at a higher level
				continue;
			}
			else if (id == "peace") {
				// Do nothing, handled at a higher level
				continue;
			}
			else if (id == "failwar") {
				// Do nothing, handled at a higher level
				continue;
			}
			else {
				// Don't try anything with clauses we don't know about
				desc.type |= TT_Invalid;
				continue;
			}

			if (fromUs)
				desc.theirPoints += pts;
			else
				desc.ourPoints += pts;
		}

		return desc;
	}

	float getWeightPerUnit(EmpireAIData@ data, Empire@ emp, ResourceType type) {
		// Base resource weight
		float weight = getResourceMod(type);

		// Multiplier based on our stores
		switch (data.getResStatus(type)) {
			case RS_Critical: weight *= 4.f; break;
			case RS_Low: weight *= 2.f; break;
			case RS_Enough: weight *= 1.f; break;
			case RS_Surplus: weight *= 0.5f; break;
		}

		return weight;
	}
	/* }}} */
	/* {{{ Consider treaties from the other party */
	bool considerTreaty(EmpireAIData@ data, Empire@ emp, Treaty@ treaty) {
		TreatyDescriptor desc = getTreatyInfo(data, emp, treaty);

		// Reject anything that is invalid or we don't have enough resources
		if (desc.type & TT_Invalid != 0 || desc.type & TT_Insufficient != 0)
			return false;

		// If we're bored to death, don't accept bribes
		if (desc.type & TT_RequestForPeace != 0 && data[GD_Boredom] > data[PV_BoredomNoBribes])
			return false;

		// If we're threatened or bribed, we need to include our relative strengths
		if (desc.type & TT_ThreatForWar != 0 || desc.type & TT_RequestForPeace != 0) {
			float pts = getPtsIndex(data) * 0.4f * desc.timeout;
			if (strRatio < 1.f)
				desc.ourPoints += pts / strRatio;
			else
				desc.theirPoints += pts * strRatio;
		}

		// Calculate points ratio
		float ptsRatio = desc.ourPoints / max(1.f, desc.theirPoints);

		// Treaties that are expensive have less weight
		if (desc.type & TT_Expensive != 0) {
			// We will never trade over our expensive value if this is a normal
			// trade, only if we're being threatened
			if (desc.type & TT_ThreatForWar == 0)
				return false;

			ptsRatio *= 0.6f;
		}

		// Treaties that last a long time have less weight
		if (desc.timeout > 0)
			ptsRatio /= ceil(desc.timeout / data[PV_TradeMaxDuration]);

		// See if we should accept this treaty
		if (ptsRatio > randomf(data[PV_TradeLowRatio], data[PV_TradeHighRatio]))
			return true;

		// If we rejected an offer that was sort of acceptable
		// nonetheless, we will want to send a counter-offer right away
		proposalTimer.setLength(randomf(data[PV_ProposalMinCounter],
										data[PV_ProposalMaxCounter]));
		proposalTimer.reset();
		return false;
	}
	/* }}} */
	/* {{{ Clause manipulation */
	ResourceType getLowResource(EmpireAIData@ data, ResourceStatus lowerThan) {
		int[] types(RT_COUNT);
		int realCnt = 0;
		for (int i = 0; i < int(RT_COUNT); ++i) {
			if (data.getResStatus(ResourceType(i)) <= lowerThan)
				types[realCnt++] = i;
		}

		if (realCnt == 0)
			return RT_None;
		return ResourceType(types[rand(realCnt - 1)]);
	}

	ResourceType getHighResource(EmpireAIData@ data, ResourceStatus higherThan) {
		int[] types(RT_COUNT);
		int realCnt = 0;
		for (int i = 0; i < int(RT_COUNT); ++i) {
			if (data.getResStatus(ResourceType(i)) >= higherThan)
				types[realCnt++] = i;
		}

		if (realCnt == 0)
			return RT_None;
		return ResourceType(types[rand(realCnt - 1)]);
	}

	float addTradeClause(EmpireAIData@ data, Empire@ emp, Empire@ to, TreatyFactory@ fact, bool reversed, float targetPts, float timeout) {
		// Figure out which resource is beneficial to trade
		ResourceType toTrade = RT_None;
		if (reversed) {
			toTrade = getLowResource(data, RS_Low);
			if (toTrade == RT_None)
				toTrade = getLowResource(data, RS_Enough);
			if (toTrade == RT_None)
				toTrade = getLowResource(data, RS_Surplus);
		}
		else
			toTrade = getHighResource(data, RS_Enough);

		// Don't send treaties for luxuries / goods to eusocial folk
		if ((toTrade == RT_Luxuries || toTrade == RT_Goods)
			&& (to.hasTraitTag(strIndifferent)
				|| emp.hasTraitTag(strIndifferent))
		) {
			return 0;
		}

		// Make sure we found something to trade
		if (toTrade == RT_None)
			return 0;

		// Get the appropriate amount of resource to trade
		float weight = getWeightPerUnit(data, emp, toTrade);
		float totalAmount = targetPts / weight;

		// Make sure we have enough to trade
		if (!reversed) {
			totalAmount = min(totalAmount,
				max(data.getResData(toTrade, RD_Stored)
						* data[PV_TradeMaxStored],
					data.getResData(toTrade, RD_Net)
						* data[PV_TradeMaxRate] * timeout
				));
		}

		float tradeAmount = ceil(totalAmount / timeout);

		if (tradeAmount <= 0)
			return 0;

		// Add the clause
		Clause@ tradeClause = fact.treaty.addClause("trade", reversed);
		tradeClause.getOption(0).opAssign(getResourceName(toTrade));
		tradeClause.getOption(1).opAssign(tradeAmount);

		return targetPts;
	}

	float addSendClause(EmpireAIData@ data, Empire@ emp, Empire@ to, TreatyFactory@ fact, bool reversed, float targetPts, float timeout) {
		// Figure out which resource is beneficial to trade
		ResourceType toTrade = RT_None;
		if (reversed) {
			toTrade = getLowResource(data, RS_Low);
			if (toTrade == RT_None)
				toTrade = getLowResource(data, RS_Enough);
			if (toTrade == RT_None)
				toTrade = getLowResource(data, RS_Surplus);
		}
		else
			toTrade = getHighResource(data, RS_Enough);

		// Don't send treaties for luxuries / goods to eusocial folk
		if ((toTrade == RT_Luxuries || toTrade == RT_Goods)
			&& (to.hasTraitTag(strIndifferent)
				|| emp.hasTraitTag(strIndifferent))
		) {
			return 0;
		}

		// Make sure we found something to trade
		if (toTrade == RT_None)
			return 0;

		// Get the appropriate amount of resource to trade
		float weight = getWeightPerUnit(data, emp, toTrade);
		float totalAmount = targetPts / weight;

		// Make sure we have enough to send
		if (!reversed) {
			totalAmount = min(totalAmount,
				data.getResData(toTrade, RD_Stored)
				 * data[PV_TradeMaxStored]);
		}

		if (totalAmount <= 0)
			return 0;

		// Add the clause
		Clause@ tradeClause = fact.treaty.addClause("send", reversed);
		tradeClause.getOption(0).opAssign(getResourceName(toTrade));
		tradeClause.getOption(1).opAssign(totalAmount);

		return targetPts;
	}

	float addResearchClause(EmpireAIData@ data, Empire@ emp, Empire@ to, TreatyFactory@ fact, bool reversed, float targetPts, float timeout) {
		float ptsIndex = getPtsIndex(data) * 0.2f;
		float ourResearch = float(emp.getResearchRate());

		// Calculate how much research to share
		float sendResearch = ourResearch * timeout * ptsIndex / targetPts;

		// Make sure we have enough to share
		if (!reversed) {
			float external = emp.getStat(strExternalResearch);
			float availResearch = ourResearch - external;

			sendResearch = min(sendResearch, availResearch);
		}

		// Cancel out if we have no research left to share
		if (sendResearch <= 0)
			return 0;

		// Add the clause
		Clause@ resClause = fact.treaty.addClause("research", reversed);
		resClause.getOption(0).opAssign(sendResearch);

		return (sendResearch / max(ourResearch, 1.f)) * ptsIndex * timeout;
	}

	float addVisionClause(EmpireAIData@ data, Empire@ emp, Empire@ to, TreatyFactory@ fact, bool reversed, float targetPts, float timeout) {
		if (reversed) {
			if (to.hasVisibility(emp))
				return 0;
		}
		else {
			if (emp.hasVisibility(to))
				return 0;
		}

		// Add the clause
		fact.treaty.addClause("vision", reversed);

		// Calculate points
		float ptsIndex = getPtsIndex(data);
		return ptsIndex * timeout * 0.1f;
	}
	/* }}} */
	/* {{{ Create a trade treaty */
	bool createTradeTreaty(EmpireAIData@ data, Empire@ emp, Empire@ to) {
		TreatyFactory@ fact = TreatyFactory(emp, to);

		// Timeout for this treaty
		float timeout = randomf(data[PV_ProposalMinDuration],
								data[PV_ProposalMaxDuration]);

		// Total amount of points that go into this treaty
		float pts = getPtsIndex(data) * timeout * randomf(0.3f, 1.f);

		// Points currently added to the factory
		float ourPts = 0;
		float theirPts = 0;
		bool needTimeout = false;

		bool leftHasSpecial = false;
		bool rightHasSpecial = false;

		// Add clauses to the treaty
		for (uint i = 0; i < 8; ++i) {
			// Decide which empire should get the clause
			bool reversed = false;
			float clausePts = 0.f;
			float targPts = 0.f;

			bool hasSpecial = false;
			if (reversed)
				hasSpecial = rightHasSpecial;
			else
				hasSpecial = leftHasSpecial;

			if (ourPts > theirPts) {
				reversed = true;
				targPts = max(abs(pts - theirPts), abs(ourPts - theirPts));
			}
			else {
				targPts = max(abs(pts - ourPts), abs(ourPts - theirPts));
			}

			// No need to continue when we don't need to add any more points
			if (targPts == 0)
				break;

			// Add a random clause
			uint numClauses = hasSpecial ? 1 : 3;
			bool specialClause = false;
			switch(rand(numClauses)) {
				case 0:
					clausePts = addTradeClause(data, emp, to, fact, reversed, targPts, timeout);
					needTimeout = true;
				break;
				case 1:
					clausePts = addSendClause(data, emp, to, fact, reversed, targPts, timeout);
				break;
				case 2:
					clausePts = addResearchClause(data, emp, to, fact, reversed, targPts, timeout);
					specialClause = true;
					needTimeout = true;
				break;
				case 3:
					clausePts = addVisionClause(data, emp, to, fact, reversed, targPts, timeout);
					specialClause = true;
					needTimeout = true;
				break;
			}

			// Only one special clause a pop
			if (clausePts > 0 && specialClause) {
				if (reversed)
					rightHasSpecial = true;
				else
					leftHasSpecial = true;
			}

			// Record the added points
			if (reversed)
				theirPts += clausePts;
			else
				ourPts += clausePts;


			if (ourPts >= pts && theirPts >= pts && ourPts / max(theirPts, 1.f) >= data[PV_TradeLowRatio])
				break;
		}

		// Make sure we made a satisfying treaty
		if (ourPts < pts || theirPts < pts || ourPts / max(theirPts, 1.f) < data[PV_TradeLowRatio]) {
			return false;
		}

		// Add timeout clause if needed
		if (needTimeout) {
			Clause@ timeoutClause = fact.treaty.addClause("timeout", false);
			timeoutClause.getOption(0).opAssign(timeout);
		}

		fact.propose();
		return true;
	}
	/* }}} */
	/* {{{ Threaten war */
	bool createWarThreat(EmpireAIData@ data, Empire@ emp, Empire@ to) {
		TreatyFactory@ fact = TreatyFactory(emp, to);

		// Timeout for this treaty
		float timeout = randomf(data[PV_ProposalMinDuration],
								data[PV_ProposalMaxDuration]);

		// Figure out how expensive we want to make our threat
		float pts = getPtsIndex(data) * 0.4f * timeout * strRatio;
		float theirPts = 0;

		// Add clauses to the treaty
		bool hasSpecial = false;
		bool needTimeout = false;

		for (uint i = 0; i < 8; ++i) {
			// Decide which empire should get the clause
			bool reversed = true;
			float clausePts = 0.f;
			float targPts = abs(pts - theirPts);

			// No need to continue when we don't need to add any more points
			if (targPts == 0)
				break;

			// Add a random clause
			uint numClauses = hasSpecial ? 1 : 3;
			switch(rand(numClauses)) {
				case 0:
					clausePts = addTradeClause(data, emp, to, fact, reversed, targPts, timeout);
					needTimeout = true;
				break;
				case 1:
					clausePts = addSendClause(data, emp, to, fact, reversed, targPts, timeout);
				break;
				case 2:
					clausePts = addResearchClause(data, emp, to, fact, reversed, targPts, timeout);
					hasSpecial = true;
					needTimeout = true;
				break;
				case 3:
					clausePts = addVisionClause(data, emp, to, fact, reversed, targPts, timeout);
					hasSpecial = true;
					needTimeout = true;
				break;
			}

			// Record the added points
			theirPts += clausePts;

			if (theirPts >= pts)
				break;
		}

		// Add timeout and peace clause if needed
		if (needTimeout) {
			Clause@ timeoutClause = fact.treaty.addClause("timeout", false);
			timeoutClause.getOption(0).opAssign(timeout);

			fact.treaty.addClause("peace", false);
		}

		// Add clause to declare war if it fails
		fact.treaty.addClause("failwar", false);
		fact.propose();
		return true;
	}
	/* }}} */
	/* {{{ Bribe for peace */
	bool createPeaceBribe(EmpireAIData@ data, Empire@ emp, Empire@ to) {
		TreatyFactory@ fact = TreatyFactory(emp, to);

		// Timeout for this treaty
		float timeout = randomf(data[PV_ProposalMinDuration],
								data[PV_ProposalMaxDuration]);

		// Figure out how expensive we want to make our bribe
		float pts = getPtsIndex(data) * 0.4f * timeout / strRatio;
		float ourPts = 0;

		// Add clauses to the treaty
		bool hasSpecial = false;

		for (uint i = 0; i < 8; ++i) {
			// Decide which empire should get the clause
			bool reversed = false;
			float clausePts = 0.f;
			float targPts = abs(pts - ourPts);

			// No need to continue when we don't need to add any more points
			if (targPts == 0)
				break;

			// Add a random clause
			uint numClauses = hasSpecial ? 1 : 3;
			switch(rand(numClauses)) {
				case 0:
					clausePts = addTradeClause(data, emp, to, fact, reversed, targPts, timeout);
				break;
				case 1:
					clausePts = addSendClause(data, emp, to, fact, reversed, targPts, timeout);
				break;
				case 2:
					clausePts = addResearchClause(data, emp, to, fact, reversed, targPts, timeout);
					hasSpecial = true;
				break;
				case 3:
					clausePts = addVisionClause(data, emp, to, fact, reversed, targPts, timeout);
					hasSpecial = true;
				break;
			}

			// Record the added points
			ourPts += clausePts;

			if (ourPts >= pts)
				break;
		}

		// Add timeout and peace clause
		Clause@ timeoutClause = fact.treaty.addClause("timeout", false);
		timeoutClause.getOption(0).opAssign(timeout);

		fact.treaty.addClause("peace", false);
		fact.propose();
		return true;
	}
	/* }}} */
	// {{{ Saving and Loading
	void save(XMLWriter@ xml) {
		xml.addElement("id", true, "v", i_to_s(other.ID));
		xml.addElement("proposalTimer", true, "l", f_to_s(proposalTimer.getLength()), "r", f_to_s(proposalTimer.getRemaining()));
		xml.addElement("treatyTimer", true, "l", f_to_s(treatyTimer.getLength()), "r", f_to_s(treatyTimer.getRemaining()));
		xml.addElement("lastProposalType", true, "v", i_to_s(int(lastProposalType)));
	}

	RelationsManager(EmpireAIData@ data, Empire@ emp, XMLReader@ xml) {
		lastUpdateTime = gameTime;
		canDeclare = emp.isAI() || getGameSetting("AI_IGNORE_PLAYER", 0.f) < 0.5f;

		bool reading = true;
		while (xml.advance() && reading) {
			string@ name = xml.getNodeName();
			switch(xml.getNodeType()) {
				case XN_Element:
					if (name == "id") {
						int id = s_to_i(xml.getAttributeValue("v"));
						@other = getEmpireByID(id);
					}
					else if (name == "proposalTimer") {
						proposalTimer.setLength(s_to_f(xml.getAttributeValue("l")));
						proposalTimer.setRemaining(s_to_f(xml.getAttributeValue("r")));
					}
					else if (name == "treatyTimer") {
						treatyTimer.setLength(s_to_f(xml.getAttributeValue("l")));
						treatyTimer.setRemaining(s_to_f(xml.getAttributeValue("r")));
					}
					else if (name == "lastProposalType") {
						lastProposalType = uint(s_to_i(xml.getAttributeValue("v")));
					}
				break;
				case XN_Element_End:
					if (name == "relation")
						reading = false;
				break;
			}
		}

		// Retrieve proposed treaty
		TreatyList list;
		list.prepare(emp);
		@proposedTreaty = list.getProposedTreaty(other);
		if (proposedTreaty !is null && proposedTreaty.getFromEmpire() !is emp)
			@proposedTreaty = null;

		// First data update
		updateData(data, emp);
	}
	// }}}
}
/* }}} */

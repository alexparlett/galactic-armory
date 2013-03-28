//empire_ai.as
//Default implementation of the empire AI system
//==============================================
//HOW THIS WORKS:
//
//First: void registerEmpireData(Empire@) is called for every empire in the game - invalids, players, humans
//	This function should call emp.regScriptData(<some class instance>) when it wants to act on behalf of that empire.
//	This informs the engine what callbacks to use later on
//	This can and should be used to manage how the AI reacts to others, recalls what has happened, and plans for the future
//	NOTE: This function is called as the empires are generated. You cannot rely on the existence of other empires during this call.
//
//On every tick of the empire:
//	Internal states are updated automatically. This involves research, dispatching messages, handling the object list updates, and various other things
//
//	If the empire has received diplomatic messages, calls void onDiplomaticMessage(Empire@ receiver, Empire@ sender, <specified class>@, DiplomaticMessage@) for each message
//		This function should manipulate the diplomatic message to indicate how things went, as well as manage its states based on that reaction
//
//	Calls void empireAITick(Empire@, <specified class>@, float tickDuration)
//		This should handle logic that isn't handled by object orders and settings (e.g. Auto-Colonize, planet governors, etc)
//			This typically involves analyzing the situation, and giving orders to objects to fit the situation
//			As well as adjusting empire settings, such as the current research.
//

//Logs a single empire
bool logEmpire = false;

//global strings
string@ str_presence = "prs", str_visited = "visited", str_planets = "planets", str_control = "Control", str_fuel = "Fuel", str_strength = "str";
string@ str_fighterHull = "FighterHull", str_mediumHull = "MediumHull";

const float twoPi = 6.28318531f;

enum GoalID {
	GID_Invalid = 0,		//Erudite Only
	GID_Lead = 1,			//Erudite Only
	GID_Fight,				//Erudite Only
	GID_Trade,				//Erudite Only
	GID_Miner,				//Erudite Only
	GID_MegaMiner,			//Unused
	GID_Explore,			//Erudite Only
	GID_Colonize,			//Erudite Only
	GID_Defense,			//Unused	
	GID_Annihilate,			//Unused	
	GID_Supply,				//Erudite Only
	GID_StaticDefense,		//Erudite Only
	GID_FightSpecialised,	//Erudite Only
	GID_StrikeCraft,		//Erudite Only
	GID_Raid,				//Pirate Only
	GID_Pillage,			//Pirate Only
	GID_Remnant,			//Remnant Only
	GID_Tanker,				//Erudite Only
	GID_RemnantFighter,		//Remnant Only
	GID_Carrier,			//Erudite Only
	GID_RemnantCommand,		//Remnant Only
	GID_RemnantStation,		//Remnant Only
	GID_RemnantWave,		//Remnant Only
	GID_RemnantPicket,		//Remnant Only
	GID_SpecialDefense,		//Remnant Only
	GID_Ringworld,			//Erudite Only
	
	GID_COUNT,
};

ShipDesign@[] defaultDesigns, createDesigns;
dictionary designGoals;

bool loadedDefaults = false;
void loadDefaults() {
	loadDefaults(true);
}

void loadDefaults(bool loadPers) {
	if(loadedDefaults)
		return;
	loadedDefaults = true;

	// Set goal GIDs
	designGoals.set( "Leader", int64(GID_Lead) );
	designGoals.set( "Combat", int64(GID_Fight) );
	designGoals.set( "Trade", int64(GID_Trade) );
	designGoals.set( "Miner", int64(GID_Miner) );
	designGoals.set( "MegaMiner", int64(GID_MegaMiner) );	
	designGoals.set( "Explore", int64(GID_Explore) );
	designGoals.set( "Expand", int64(GID_Colonize) );
	designGoals.set( "Defense", int64(GID_Defense) );
	designGoals.set( "Annihilate", int64(GID_Annihilate) );
	designGoals.set( "Supply", int64(GID_Supply) );
	designGoals.set( "StaticDefense", int64(GID_StaticDefense) );
	designGoals.set( "CombatSpecialized", int64(GID_FightSpecialised) );
	designGoals.set( "Fighter", int64(GID_StrikeCraft) );
	designGoals.set( "Raid", int64(GID_Raid) );
	designGoals.set( "Pillage", int64(GID_Pillage) );
	designGoals.set( "Remnant", int64(GID_Remnant) );
	designGoals.set( "RemnantFighter", int64(GID_RemnantFighter) );
	designGoals.set( "Tanker", int64(GID_Tanker) );
	designGoals.set( "Carrier", int64(GID_Carrier) );
	designGoals.set( "RemnantCommand", int64(GID_RemnantCommand) );
	designGoals.set( "RemnantStation", int64(GID_RemnantStation) );
	designGoals.set( "RemnantWave", int64(GID_RemnantWave) );
	designGoals.set( "RemnantPicket", int64(GID_RemnantPicket) );
	designGoals.set( "SpecialDefense", int64(GID_SpecialDefense) );
	designGoals.set( "Ringworld", int64(GID_Ringworld) );
	
	// Read default layouts
	XMLReader@ xml = XMLReader("empire_defaults");
	if(xml is null)
		return;
	
	while(xml.advance()) {
		if(xml.getNodeType() == XN_Element) {
			if(xml.getNodeName() == "layouts") {
				loadDefaultLayouts(xml);
			}
			else if(xml.getNodeName() == "personalities") {
				loadPersonalities(xml, loadPers);
			}
		}
	}
}

void clearDefaults() {
	defaultDesigns.resize(0);
	createDesigns.resize(0);
}

int getGoalID(string@ goal) {
	int64 goalID = GID_Invalid;
	designGoals.get(goal, goalID);
	return int(goalID);
}

// Loads a ship design from an xml reader already advanced to the
// <default> or <design> tag.
ShipDesign@ loadDesignDescriptor(XMLReader@ xml) {
	if(xml.getNodeName() == "default") {
		ShipDesign@ design = loadShipDesign( XMLReader(xml.getAttributeValue("file")) );
		if(design is null)
			return null;

		@design.replaces = localize(xml.getAttributeValue("replaces"));
		@design.defaultFighter = localize(xml.getAttributeValue("strikecraft"));
		design.autoscale = xml.getAttributeValue("autoscale") != "false";
		design.scalefrom = s_to_f(xml.getAttributeValue("scalefrom"));
		
		int64 goalID = GID_Invalid;
		designGoals.get( xml.getAttributeValue("goal"), goalID);
		design.goalID = int(goalID);
		
		string@ only = xml.getAttributeValue("only");
		if(only == "Human")
			design.forAI = false;
		else if(only == "AI")
			design.forHuman = false;
		else if (only == "Pirates") {
			design.forPirates = true;
			design.forHuman = false;
			design.forAI = false;
		}
		else if (only == "Remnants") {
			design.forRemnants = true;
			design.forHuman = false;
			design.forAI = false;
		}
		else if (@only != null && only != "")
		{
			error ("Trait Only : " + only);
			design.forHuman = false;
			design.forAI = false;
			design.forTrait = only;
		}

		return design;
	}
	else if(xml.getNodeName() == "design") {
		ShipDesign@ design = loadShipDesign( XMLReader(xml.getAttributeValue("file")) );
		if(design is null)
			return null;
		
		@design.replaces = localize(xml.getAttributeValue("replaces"));
		@design.defaultFighter = localize(xml.getAttributeValue("strikecraft"));
		design.autoscale = xml.getAttributeValue("autoscale") != "false";
		design.scalefrom = s_to_f(xml.getAttributeValue("scalefrom"));

		if (xml.hasAttribute("minTime"))
			design.minTime = s_to_i(xml.getAttributeValue("minTime"));

		int64 goalID = GID_Invalid;
		designGoals.get( xml.getAttributeValue("goal"), goalID);
		design.goalID = int(goalID);
		
		return design;
	}
	return null;
}


void loadDefaultLayouts(XMLReader@ xml) {
	while(xml.advance()) {
		switch(xml.getNodeType()) {
			case XN_Element:
				if(xml.getNodeName() == "default") {
					ShipDesign@ design = loadDesignDescriptor(xml);
					if(design is null)
						continue;

					int l = defaultDesigns.length();
					defaultDesigns.resize(l + 1);
					@defaultDesigns[l] = @design;
				}
				else if(xml.getNodeName() == "design") {
					ShipDesign@ design = loadDesignDescriptor(xml);
					if(design is null)
						continue;
					
					int l = createDesigns.length();
					createDesigns.resize(l + 1);
					@createDesigns[l] = @design;
				}
				break;
			case XN_Element_End:
				if(xml.getNodeName() == "layouts")
					return;
				break;
		}
	}
}

class PersonalityDesc {
	string@ file;
	string@ forAI;

	PersonalityDesc(string@ File, string@ For) {
		@forAI = For;
		@file = File;
	}
};

PersonalityDesc@[] persDesc;

void loadPersonalities(XMLReader@ xml, bool loadNow) {
	while(xml.advance()) {
		switch(xml.getNodeType()) {
			case XN_Element:
				if (xml.getNodeName() == "personality") {
					string@ file = xml.getAttributeValue("file");
					string@ forAI = xml.getAttributeValue("for");

					uint n = persDesc.length();
					persDesc.resize(n+1);
					@persDesc[n] = PersonalityDesc(file, forAI);
				}
				break;
			case XN_Element_End:
				if(xml.getNodeName() == "personalities")
					return;
				break;
		}
	}
}

class SubSystem {
	const subSystemDef@ def;
	pos2df pos;
	float scale;
	int link;
	
	SubSystem() {
		link = -1;
	}
};

class ShipDesign {
	string@ className;
	string@ replaces;
	
	dictionary techRequirements;
	
	string@[] orders;
	SubSystem[] subSystems;
	int goalID;
	int minTime;
	
	float scale;
	float scalefrom;
	bool autoscale;
	
	bool forAI;
	bool forPirates;
	bool forHuman;
	bool forRemnants;
	bool fromHuman;

	string forTrait;
	
	bool ai_use_scale;
	float ai_scale_low;
	float ai_scale_hi;
	bool ai_force_scale;
	
	bool ai_use_dmg;
	float ai_dmg_low;
	float ai_dmg_hi;

	bool ai_target_ships;
	bool ai_target_planets;

	bool ai_deposit_ships;
	bool ai_deposit_planets;

	bool ai_dock_ships;
	bool ai_dock_planets;
	bool ai_dock_stations;
	DockingMode ai_dock_mode;

	float ai_engagement_range;
	float ai_defend_range;
	AIStance ai_stance;

	CarrierMode ai_carrier_mode;
	string@ defaultFighter;
	
	bool orbit;
	bool allowFetch;
	bool allowSupply;
	
	ShipDesign(string@ ClassName) {
		@className = @ClassName;
		forAI = true;
		forHuman = true;
		fromHuman = false;
		forPirates = false;
		forRemnants = false;
		scale = 1.f;
		scalefrom = 0.f;
		autoscale = true;
		goalID = GID_Invalid;
		ai_use_scale = false;
		ai_use_dmg = false;
		ai_target_ships = true;
		ai_target_planets = true;
		orbit = true;
		allowFetch = false;
		allowSupply = true;
		ai_deposit_ships = false;
		ai_deposit_planets = true;
		minTime = -1;
		ai_dock_ships = true;
		ai_dock_planets = true;
		ai_dock_stations = true;
		ai_engagement_range = -1.f;
		ai_dock_mode = DM_Never;
		@defaultFighter = null;
		ai_carrier_mode = CM_None;
		ai_stance = AIS_Engage;
		ai_defend_range = -1.f;
		forTrait = "";
	}

	ShipDesign(const HullLayout@ hull) {
		@className = hull.getName();
		forAI = true;
		forHuman = true;
		fromHuman = true;
		scale = hull.scale;
		goalID = GoalID(hull.metadata);
		ai_use_scale = false;
		ai_use_dmg = false;
		orbit = true; // shouldn't matter
		//warning("added design: " + className + " w/Goal: " + goalID);
	}

	bool generateForEmpire(Empire@ emp) {
		return generateForEmpire(emp, false);
	}

	const HullLayout@ generateDesign(Empire@ emp, bool aiLogic, float atScale, string@ withName) {
		if(fromHuman) return null;

		// Alter scale based on game limits
		float minScale = getGameSetting("LIMIT_MIN_SCALE", 0.f);
		if (minScale > 0 && atScale < minScale) {
			atScale = minScale;
		}
		else {
			float maxScale = getGameSetting("LIMIT_MAX_SCALE", 0.f);
			if (maxScale > 0 && atScale > maxScale) {
				atScale = maxScale;
			}
		}

		// Create hull layout
		clearActiveHull();
		setActiveHullScale(atScale);

		const subSystemDef@ def = getSubSystemDefByName(str_fighterHull);
		uint fighterHull = def is null ? 0 : def.ID;

		for(uint i = 0; i < subSystems.length(); ++i) {
			SubSystem@ sys = @subSystems[i];
			addSysToActiveHull(sys.def, sys.scale, sys.pos, sys.link);
		}
		setActiveHullMetaData(goalID);
		if(ai_use_scale)
			setActiveHullTargetScale(ai_scale_low, ai_scale_hi, ai_force_scale);
		if(ai_use_dmg)
			setActiveHullTargetDamage(ai_dmg_low, ai_dmg_hi);
		setActiveHullAllowTargets(ai_target_ships, ai_target_planets);
		setActiveHullDepositTargets(ai_deposit_ships, ai_deposit_planets);
		setActiveHullOrbitTargets(orbit);
		setActiveHullAllowFetch(allowFetch);
		setActiveHullAllowSupply(allowSupply);
		setActiveHullEngagementRange(ai_engagement_range);
		setActiveHullDefendRange(ai_defend_range);
		setActiveHullDefaultStance(ai_stance);

		// The AI wants auto-docking strike craft by default
		if (aiLogic && goalID == GID_StrikeCraft) {
			setActiveHullDockMode(DM_Clear);
			setActiveHullDockTargets(true, true, true);
		}
		else {
			setActiveHullDockMode(ai_dock_mode);
			setActiveHullDockTargets(ai_dock_ships, ai_dock_planets, ai_dock_stations);
		}

		setActiveHullCarrierMode(ai_carrier_mode);

		// Add orders
		if (orders.length() > 0) {
			activeHullClearOrders();
			for (uint i = 0; i < orders.length(); ++i) {
				OrderDescriptor@ desc = createOrderDescriptor(orders[i]);
				activeHullAddOrder(desc);
				freeOrderDescriptor(desc);
			}
		}

		if (!finalizeActiveHull(withName))
			return null;

		const HullLayout@ layout = @emp.getShipLayout(withName);

		if (aiLogic && layout !is null)
			layout.updateThreshold = 2.f;

		// Mark as a replacement
		if (replaces !is null && replaces != "") {
			const HullLayout@ oldLayout = @emp.getShipLayout(replaces);

			if (layout !is null && oldLayout !is null && !oldLayout.obsolete) {
				emp.updateHull(oldLayout, layout);
			}
		}

		// Set default fighter
		if (defaultFighter !is null && defaultFighter != "") {
			const HullLayout@ fighter = @emp.getShipLayout(defaultFighter);

			if (fighter !is null && layout !is null)
				layout.set_defaultFighter(fighter);
		}

		return layout;
	}

	bool generateForEmpire(Empire@ emp, bool aiLogic) {
		if (emp.getShipLayout(className) !is null && replaces is null) return false;
		return generateDesign(emp, aiLogic, scale, className) !is null;
	}

	bool hasDesign(Empire@ emp) {
		return emp.getShipLayout(className) !is null;
	}
	
	bool canCreate(Empire@ emp, ResearchWeb& web) {
		if(fromHuman) return true;

		// Check gametime
		if (gameTime < minTime * 60)
			return false;

		// Check explicit tech requirements
		if(techRequirements.resetIter()) {
			string@ tech = "";
			double level;
			do {
				techRequirements.getCurrentName(tech);
				techRequirements.getCurrent(level);
				const WebItem@ Tech = web.getItem(tech);
				if(Tech is null || Tech.level < level)
					return false;
			} while(techRequirements.advance());
		}
		
		// Check if subsystems are unlocked
		uint sysCount = subSystems.length();
		for(uint i = 0; i < sysCount; ++i)
			if(!emp.subSysUnlocked(subSystems[i].def))
				return false;

		// Check if we have the layout it replaces
		if (replaces !is null && replaces != "") {
			const HullLayout@ oldLayout = @emp.getShipLayout(replaces);
			
			if (oldLayout is null || oldLayout.obsolete)
				return false;
		}
		
		return true;
	}
};

ShipDesign@ loadShipDesign(XMLReader@ xml) {
	if(xml is null)
		return null;
	
	ShipDesign@ design = ShipDesign("unnamed");
	
	while(xml.advance()) {
		if(xml.getNodeType() == XN_Element) {
			string@ nodeName = xml.getNodeName();
			
			if(nodeName == "settings") {
				float newScale = s_to_f(xml.getAttributeValue("scale"));
				if(newScale < 0.0001f)
					return null;
				@design.className = localize(xml.getAttributeValue("name"));
				design.scale = newScale;
			}
			else if(nodeName == "subSystems") {
				if(!loadSubSystemsFromXML(design, xml))
					return null;
			}
			else if(nodeName == "techRequirements") {
				if(!loadTechReqsFromXML(design, xml))
					return null;
			}
			else if(nodeName == "ai") {
				if(!loadAIFromXML(design, xml))
					return null;
			}
			else if(nodeName == "orders") {
				if(!loadOrdersFromXML(design, xml))
					return null;
			}
		}
	}
	return design;
}

bool loadSubSystemsFromXML(ShipDesign@ design, XMLReader@ xml) {
	while(xml.advance()) {
		switch(xml.getNodeType()) {
			case XN_Element:
				if(xml.getNodeName() == "subSystem") {
					string@ globalName = xml.getAttributeValue("name");
					pos2df subSysPos( s_to_f(xml.getAttributeValue("x")), s_to_f(xml.getAttributeValue("y")) );
					float scale = s_to_f(xml.getAttributeValue("scale"));
					int linkIndex = xml.hasAttribute("link") ? s_to_i(xml.getAttributeValue("link")) : -1;
					
					const subSystemDef@ subSysDef = getSubSystemDefByName(globalName);
					
					if(subSysDef is null)
						return false;
					
					uint curCount = design.subSystems.length();
					
					design.subSystems.resize(curCount + 1);
					SubSystem@ subSys = @design.subSystems[curCount];
					
					@subSys.def = @subSysDef;
					subSys.scale = scale;
					subSys.pos = subSysPos;
					subSys.link = linkIndex;
				}
				break;
			case XN_Element_End:
				if(xml.getNodeName() == "subSystems")
					return true;
				break;
		}
	}
	return true;
}

bool loadOrdersFromXML(ShipDesign@ design, XMLReader@ xml) {
	while(xml.advance()) {
		switch(xml.getNodeType()) {
			case XN_Element:
				if(xml.getNodeName() == "order") {
					string@ order = xml.getAttributeValue("desc");
					uint n = design.orders.length();
					design.orders.resize(n+1);
					@design.orders[n] = order;
				}
				break;
			case XN_Element_End:
				if(xml.getNodeName() == "orders")
					return true;
				break;
		}
	}
	return true;
}

bool loadTechReqsFromXML(ShipDesign@ design, XMLReader@ xml) {
	while(xml.advance()) {
		switch(xml.getNodeType()) {
			case XN_Element:
				if(xml.getNodeName() == "tech") {
					string@ techName = xml.getAttributeValue("name");
					float level = s_to_f(xml.getAttributeValue("level"));
					
					if(techName.length() == 0 || level <= 0.f)
						break;
					
					design.techRequirements.set(techName, double(level));
				}
				break;
			case XN_Element_End:
				if(xml.getNodeName() == "techRequirements")
					return true;
				break;
		}
	}
	return true;
}

bool loadAIFromXML(ShipDesign@ design, XMLReader@ xml) {
	while(xml.advance()) {
		switch(xml.getNodeType()) {
			case XN_Element:
				{
					const string@ nodeName = xml.getNodeName();
					if(nodeName == "targetScale") {
						float low = s_to_f(xml.getAttributeValue("low"));
						float hi = s_to_f(xml.getAttributeValue("hi"));
						
						
						design.ai_use_scale = true;
						design.ai_scale_low = low;
						design.ai_scale_hi = hi;
						design.ai_force_scale = xml.getAttributeValue("forced") == "true";
					}
					else if(nodeName == "targetDamage") {
						float low = s_to_f(xml.getAttributeValue("low"));
						float hi = s_to_f(xml.getAttributeValue("hi"));
						
						design.ai_use_dmg = true;
						design.ai_dmg_low = low;
						design.ai_dmg_hi = hi;
					}
					else if(nodeName == "orbit") {
						design.orbit = xml.getAttributeValue("flag") == "true";
					}
					else if(nodeName == "allowFetch") {
						design.allowFetch = xml.getAttributeValue("flag") == "true";
					}
					else if(nodeName == "allowSupply") {
						design.allowSupply = xml.getAttributeValue("flag") == "true";
					}
					else if(nodeName == "allowTargets") {
						design.ai_target_ships = xml.getAttributeValue("ships") == "true";
						design.ai_target_planets = xml.getAttributeValue("planets") == "true";
					}
					else if(nodeName == "depositTargets") {
						design.ai_deposit_ships = xml.getAttributeValue("ships") == "true";
						design.ai_deposit_planets = xml.getAttributeValue("planets") == "true";
					}
					else if(nodeName == "dockTargets") {
						design.ai_dock_ships = xml.getAttributeValue("ships") == "true";
						design.ai_dock_planets = xml.getAttributeValue("planets") == "true";
						design.ai_dock_stations = xml.getAttributeValue("stations") == "true";
					}
					else if(nodeName == "dockMode") {
						int mode = s_to_i(xml.getAttributeValue("mode"));
						design.ai_dock_mode = mode == 0 ? DM_Never : (mode == 1 ? DM_Clear : DM_Contested);
					}
					else if(nodeName == "engagementRange") {
						design.ai_engagement_range = s_to_f(xml.getAttributeValue("value"));
					}
					else if(nodeName == "defendRange") {
						design.ai_defend_range = s_to_f(xml.getAttributeValue("value"));
					}
					else if(nodeName == "defaultStance") {
						design.ai_stance = AIStance(s_to_i(xml.getAttributeValue("value")));
					}
					else if(nodeName == "carrierMode") {
						int mode = s_to_i(xml.getAttributeValue("mode"));
						design.ai_carrier_mode = CarrierMode(mode);
					}
				} break;
			case XN_Element_End:
				if(xml.getNodeName() == "ai")
					return true;
				break;
		}
	}
	return true;
}

bool designIsNew(ShipDesign@[] shipDesigns, string@ name) {
	for(uint i = 0; i < shipDesigns.length(); ++i)
		if(shipDesigns[i].className == name)
			return false;
	return true;
}
// Check if a technology is unlocked
bool isUnlocked(ResearchWeb& web, const string@ tech) {
	const WebItem@ it = web.getItem(tech);
	return !(it is null) && web.isTechVisible(it.descriptor);
}

// Choose a technology to research
string@ pickTech(ResearchWeb& web, string[]& techs) {
	uint len = techs.length();
	uint num = 0;
	int least = -1;

	for (uint i = 0; i < len; ++i) {
		const WebItem@ it = web.getItem(techs[i]);

		if(@it != null && web.isTechVisible(it.descriptor)) {
			if (least == -1 || it.get_level() < least) {
				least = it.get_level();
				num = i;
			}
		}
	}

	return least == -1 ? "" : techs[num];
}

// Level a technology to a specific level
void levelTo(ResearchWeb& web, string@ techName, uint level) {
	const WebItem@ tech = web.getItem(techName);

	if (tech !is null)
		for (uint i = 0; i < level; ++i)
			levelTech(web, tech);
}

// Level up a technology once
void levelTech(ResearchWeb& web, const WebItem@ tech) {
	float level, progress, cost, max;
	tech.getLevels(level, progress, cost, max);
	web.addPoints(tech.descriptor, cost - progress + 10);
}

// Level all techs to a certain point
void markAllVisible(ResearchWeb& web) {
	uint cnt = getWebItemDescCount();
	for (uint i = 0; i < cnt; ++i) {
		const WebItemDesc@ desc = getWebItemDesc(i);
		web.markAsVisible(desc.get_id());
	}
}

void levelAllTo(ResearchWeb& web, float targLevel) {
	uint cnt = getWebItemDescCount();
	for (uint i = 0; i < cnt; ++i) {
		const WebItemDesc@ desc = getWebItemDesc(i);
		const WebItem@ tech = web.getItem(desc);

		float level, progress, cost, max;
		tech.getLevels(level, progress, cost, max);

		while (level < targLevel) {
			levelTech(web, tech);
			level += 1;
		}
	}
}

// Declare war on someone
void declareWar(Empire@ from, Empire@ to) {
	TreatyFactory@ factory = TreatyFactory(from, to);
	factory.treaty.addClause("war", false);
	factory.propose();
	@factory = null;
}

// Vary by a random factor
float vary(float time, float variation) {
	return time * randomf(1.f - variation, 1.f + variation);
}


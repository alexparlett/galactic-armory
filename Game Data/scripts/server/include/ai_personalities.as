class AIPersonality {
	// Personality id
	string@ id;

	// === Ship Design Set ===
	// Default designs to assign to empires
	ShipDesign@[] startingDesigns;
	// Designs that can be unlocked by empires
	ShipDesign@[] unlockedDesigns;
	// Ship set used
	string@ shipset;

	// === Ship Goal Weight Sets ===
	WeightList@[] colonizePriorities;
	WeightList@[] militaryPriorities;
	WeightList@[] defensePriorities;

	int[] colonizePrioritiesMinTime;
	int[] militaryPrioritiesMinTime;
	int[] defensePrioritiesMinTime;

	// == Race Settings ==
	string[] traits;

	// === Homeworld Settings ===
	// Set of building types to remove from the homeworld
	string[] homeworldRemove;
	// How many of those types to remove at maximum
	int[] homeworldRemoveCount;
	// Build order for homeworld
	string[] homeworldBuildOrder;

	// === Research Settings ===
	// Research technologies to keep at roughly the same level
	string[] researchTechs;
	// Technologies to potentially give priority
	string[] priorityTechs;
	// Chance that a priority tech is researched
	float priorityChance;
	// Time to wait before researching links
	float researchTargetDelay;
	// Technologies to target for research
	string[] targetTechs;
	// Corresponding technologies to research links from
	string[] researchForTarget;
	// Corresponding levels to research to
	int[] researchTo;
	// Chance that an unlock is attempted
	float unlockChance;

	// === Fleet Management ===
	// Size before splitting, multiplied by the amount of fleets
	float fleetBaseSplitSize;
	// Max distance between two distinct fleets, squared
	float fleetMaxDistanceSQ;

	// === Governor Assignment ===
	// Resources to check
	string[] checkResources;
	// Corresponding governors to assign
	string[] assignGovernors;
	// Random governors to assign to planets
	string[] randomGovernors;
	// Chance that a random governor is picked
	float randomGovernorChance;

	// === Strategy Settings ===
	// Number of seconds required to halve the required strength factor for going to war
	float boredomFactor;
	// The minimum force-size factor that this empire will keep trying to fight with
	float warTolerance;
	// The chance that a planet builds defenses instead of offensive ships
	float defensesChance;
	// The chance that a planet in a contested system builds defenses
	float defensesChanceContested;

	// {{{ Defaults
	AIPersonality() {
		@id = "invalid";
		@shipset = "";
		priorityChance = 0.15f;
		researchTargetDelay = 15.f * 60.f;
		unlockChance = 0.2f;
		fleetBaseSplitSize = 100.f;
		fleetMaxDistanceSQ = 12000.f * 12000.f;
		randomGovernorChance = 0.15f;
		boredomFactor = 60.f * 30.f;
		warTolerance = 0.5f;
		defensesChance = 0.15f;
		defensesChanceContested = 0.45f;
	}
	// }}}
	// {{{ Load data from the xml data file
	void load(XMLReader@ xml) {
		while(xml.advance()) {
			string@ name = xml.getNodeName();

			switch(xml.getNodeType()) {
				case XN_Element:
					// Regular Variables
					if (name == "personality")
						id = xml.getAttributeValue("id");
					else if (name == "shipset")
						shipset = xml.getAttributeValue("id");
					else if (name == "priorityChance")
						priorityChance = s_to_f(xml.getAttributeValue("value"));
					else if (name == "researchTargetDelay")
						researchTargetDelay = s_to_f(xml.getAttributeValue("value"));
					else if (name == "unlockChance")
						unlockChance = s_to_f(xml.getAttributeValue("value"));
					else if (name == "fleetBaseSplitSize")
						fleetBaseSplitSize = s_to_f(xml.getAttributeValue("value"));
					else if (name == "fleetMaxDistanceSQ")
						fleetMaxDistanceSQ = s_to_f(xml.getAttributeValue("value"));
					else if (name == "randomGovernorChance")
						randomGovernorChance = s_to_f(xml.getAttributeValue("value"));
					else if (name == "boredomFactor")
						boredomFactor = s_to_f(xml.getAttributeValue("value"));
					else if (name == "warTolerance")
						warTolerance = s_to_f(xml.getAttributeValue("value"));
					else if (name == "defensesChance")
						defensesChance = s_to_f(xml.getAttributeValue("value"));
					else if (name == "defensesChanceContested")
						defensesChanceContested = s_to_f(xml.getAttributeValue("value"));
					// Sub-sections
					else if (name == "homeworldRemove")
						loadHomeworldRemove(xml);
					else if (name == "homeworldBuild")
						loadHomeworldBuild(xml);
					else if (name == "priorityTechs")
						loadPriorityTechs(xml);
					else if (name == "researchTechs")
						loadResearchTechs(xml);
					else if (name == "unlockTechs")
						loadUnlockTechs(xml);
					else if (name == "resourceGovernors")
						loadResourceGovernors(xml);
					else if (name == "randomGovernors")
						loadRandomGovernors(xml);
					else if (name == "layouts")
						loadLayouts(xml);
					else if (name == "colonizePriorities")
						loadColonizePriorities(xml);
					else if (name == "militaryPriorities")
						loadMilitaryPriorities(xml);
					else if (name == "defensePriorities")
						loadDefensePriorities(xml);
					else if (name == "traits")
						loadTraits(xml);
				break;
				case XN_Element_End:
					if (name == "personality")
						return;
				break;
			}
		}
	}

	void loadHomeworldRemove(XMLReader@ xml) {
		while(xml.advance()) {
			string@ name = xml.getNodeName();

			switch(xml.getNodeType()) {
				case XN_Element:
					if (name == "remove") {
						uint num = homeworldRemove.length();
						homeworldRemove.resize(num+1);
						homeworldRemoveCount.resize(num+1);

						homeworldRemove[num] = xml.getAttributeValue("structure");
						homeworldRemoveCount[num] = s_to_i(xml.getAttributeValue("max"));
					}
				break;

				case XN_Element_End:
					if (name == "homeworldRemove")
						return;
				break;
			}
		}
	}

	void loadHomeworldBuild(XMLReader@ xml) {
		while(xml.advance()) {
			string@ name = xml.getNodeName();

			switch(xml.getNodeType()) {
				case XN_Element:
					if (name == "build") {
						uint num = homeworldBuildOrder.length();
						homeworldBuildOrder.resize(num+1);

						homeworldBuildOrder[num] = xml.getAttributeValue("structure");
					}
				break;

				case XN_Element_End:
					if (name == "homeworldBuild")
						return;
				break;
			}
		}
	}

	void loadPriorityTechs(XMLReader@ xml) {
		while(xml.advance()) {
			string@ name = xml.getNodeName();

			switch(xml.getNodeType()) {
				case XN_Element:
					if (name == "tech") {
						uint num = priorityTechs.length();
						priorityTechs.resize(num+1);
						
						
						priorityTechs[num] = xml.getAttributeValue("id");
					}
				break;

				case XN_Element_End:
					if (name == "priorityTechs")
						return;
				break;
			}
		}
	}

	void loadTraits(XMLReader@ xml) {
		while(xml.advance()) {
			string@ name = xml.getNodeName();

			switch(xml.getNodeType()) {
				case XN_Element:
					if (name == "trait") {
						uint num = traits.length();
						traits.resize(num+1);

						traits[num] = xml.getAttributeValue("id");
					}
				break;
				
				
				case XN_Element_End:
					if (name == "traits")
						return;
				break;
			}
		}
	}

	void loadResearchTechs(XMLReader@ xml) {
		while(xml.advance()) {
			string@ name = xml.getNodeName();

			switch(xml.getNodeType()) {
				case XN_Element:
					if (name == "tech") {
						uint num = researchTechs.length();
						researchTechs.resize(num+1);

						researchTechs[num] = xml.getAttributeValue("id");
					}
				break;

				case XN_Element_End:
					if (name == "researchTechs")
						return;
				break;
			}
		}
	}

	void loadUnlockTechs(XMLReader@ xml) {
		while(xml.advance()) {
			string@ name = xml.getNodeName();

			switch(xml.getNodeType()) {
				case XN_Element:
					if (name == "tech") {
						uint num = targetTechs.length();
						targetTechs.resize(num+1);
						researchForTarget.resize(num+1);

						targetTechs[num] = xml.getAttributeValue("id");
						researchForTarget[num] = xml.getAttributeValue("from");
					}
				break;

				case XN_Element_End:
					if (name == "unlockTechs")
						return;
				break;
			}
		}
	}

	void loadResourceGovernors(XMLReader@ xml) {
		while(xml.advance()) {
			string@ name = xml.getNodeName();

			switch(xml.getNodeType()) {
				case XN_Element:
					if (name == "governor") {
						uint num = assignGovernors.length();
						assignGovernors.resize(num+1);
						checkResources.resize(num+1);

						assignGovernors[num] = xml.getAttributeValue("id");
						checkResources[num] = xml.getAttributeValue("check");
					}
				break;

				case XN_Element_End:
					if (name == "resourceGovernors")
						return;
				break;
			}
		}
	}

	void loadRandomGovernors(XMLReader@ xml) {
		while(xml.advance()) {
			string@ name = xml.getNodeName();

			switch(xml.getNodeType()) {
				case XN_Element:
					if (name == "governor") {
						uint num = randomGovernors.length();
						randomGovernors.resize(num+1);

						randomGovernors[num] = xml.getAttributeValue("id");
					}
				break;

				case XN_Element_End:
					if (name == "randomGovernors")
						return;
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
						string@ design = xml.getAttributeValue("name");

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

	void loadColonizePriorities(XMLReader@ xml) {
		while(xml.advance()) {
			string@ name = xml.getNodeName();

			switch(xml.getNodeType()) {
				case XN_Element:
					if (name == "set") {
						uint num = colonizePriorities.length();
						colonizePriorities.resize(num+1);
						colonizePrioritiesMinTime.resize(num+1);

						@colonizePriorities[num] = WeightList();
						colonizePrioritiesMinTime[num] = s_to_i(xml.getAttributeValue("after"));
					}
					else if (name == "goal") {
						uint num = colonizePriorities.length();

						colonizePriorities[num-1].addWeight(s_to_f(xml.getAttributeValue("weight")),
															getGoalID(xml.getAttributeValue("id")));
					}
				break;

				case XN_Element_End:
					if (name == "colonizePriorities")
						return;
				break;
			}
		}
	}

	void loadMilitaryPriorities(XMLReader@ xml) {
		while(xml.advance()) {
			string@ name = xml.getNodeName();

			switch(xml.getNodeType()) {
				case XN_Element:
					if (name == "set") {
						uint num = militaryPriorities.length();
						militaryPriorities.resize(num+1);
						militaryPrioritiesMinTime.resize(num+1);

						@militaryPriorities[num] = WeightList();
						militaryPrioritiesMinTime[num] = s_to_i(xml.getAttributeValue("after"));
					}
					else if (name == "goal") {
						uint num = militaryPriorities.length();

						militaryPriorities[num-1].addWeight(s_to_f(xml.getAttributeValue("weight")),
															getGoalID(xml.getAttributeValue("id")));
					}
				break;

				case XN_Element_End:
					if (name == "militaryPriorities")
						return;
				break;
			}
		}
	}

	void loadDefensePriorities(XMLReader@ xml) {
		while(xml.advance()) {
			string@ name = xml.getNodeName();

			switch(xml.getNodeType()) {
				case XN_Element:
					if (name == "set") {
						uint num = defensePriorities.length();
						defensePriorities.resize(num+1);
						defensePrioritiesMinTime.resize(num+1);

						@defensePriorities[num] = WeightList();
						defensePrioritiesMinTime[num] = s_to_i(xml.getAttributeValue("after"));
					}
					else if (name == "goal") {
						uint num = defensePriorities.length();

						defensePriorities[num-1].addWeight(s_to_f(xml.getAttributeValue("weight")),
															getGoalID(xml.getAttributeValue("id")));
					}
				break;

				case XN_Element_End:
					if (name == "defensePriorities")
						return;
				break;
			}
		}
	}

	// }}}
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
	// {{{ Priority sets
	void pickColonizePriorities(WeightList@ data, bool cheating, int difficulty) {
		uint setCnt = colonizePriorities.length();
		data.clear();

		if (setCnt > 0) {
			WeightList@ foundSet = colonizePriorities[0];

			// Find appropriate set
			for (uint i = 0; i < setCnt; ++i) {
				if (colonizePrioritiesMinTime[i] * 60.f < gameTime) {
					@foundSet = colonizePriorities[i];
				}
			}

			// Copy over the priorities
			copyWeightList(foundSet, data, cheating, difficulty);
		}
	}

	void pickMilitaryPriorities(WeightList@ data, bool cheating, int difficulty) {
		uint setCnt = militaryPriorities.length();
		data.clear();

		if (setCnt > 0) {
			WeightList@ foundSet = militaryPriorities[0];

			// Find appropriate set
			for (uint i = 0; i < setCnt; ++i) {
				if (militaryPrioritiesMinTime[i] * 60.f < gameTime) {
					@foundSet = militaryPriorities[i];
				}
			}

			// Copy over the priorities
			copyWeightList(foundSet, data, cheating, difficulty);
		}
	}

	void pickDefensePriorities(WeightList@ data, bool cheating, int difficulty) {
		uint setCnt = defensePriorities.length();
		data.clear();

		if (setCnt > 0) {
			WeightList@ foundSet = defensePriorities[0];

			// Find appropriate set
			for (uint i = 0; i < setCnt; ++i) {
				if (defensePrioritiesMinTime[i] * 60.f < gameTime) {
					@foundSet = defensePriorities[i];
				}
			}

			// Copy over the priorities
			copyWeightList(foundSet, data, cheating, difficulty);
		}
	}

	void copyWeightList(WeightList@ from, WeightList@ to, bool cheating, int difficulty) {
		uint count = from.values.length();
		uint j = 0;

		to.weights.resize(count);
		to.values.resize(count);

		for (uint i = 0; i < count; ++i) {
			// Skip over clearly unneccesary designs
			if (from.values[i] == GID_Lead && difficulty == 0)
				continue;
			if (from.values[i] == GID_Explore && cheating)
				continue;

			to.weights[j] = from.weights[i];
			to.values[j] = from.values[i];
			++j;
		}


		to.weights.resize(j);
		to.values.resize(j);
	}
	// }}}
};

AIPersonality@[] personalities;

// Load personality xml files from a folder
void addPersonality(string@ filename) {
	XMLReader@ xml = XMLReader(filename);

	if (xml !is null) {
		uint num = personalities.length();
		personalities.resize(num+1);

		@personalities[num] = AIPersonality();
		personalities[num].addDefaultDesigns();
		personalities[num].load(xml);
	}
	else error("Error: Could not open personality "+filename);
}

// Pick a random personality from the list
AIPersonality@ pickRandomPersonality() {
	uint persCount = personalities.length();

	if (persCount > 0)
		return personalities[rand(persCount - 1)];
	else {
		error("Error: No AI personalities were loaded.");
		return AIPersonality();
	}
}

AIPersonality@ getPersonalityByID(string@ id) {
	uint persCount = personalities.length();
	for (uint i = 0; i < persCount; ++i) {
		if (personalities[i].id == id) {
			return personalities[i];
		}
	}

	return AIPersonality();
}

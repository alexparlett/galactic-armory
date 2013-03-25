#include "/include/empire_lib.as"

bool initialized = false;
bool logPirates = false;

float PirateResGenPerSecond = 200.f;
float ResearchPointsGenPerSecond = 200.f;

const float StrengthGTFORatio = 1.f;
const float StrengthPickRandomness = 0.1f;

float PirateRaidDelay = 12.f * 60.f;
float PirateRaidInterval = 10.f * 60.f;
float PirateRaidDuration = 5.f * 60.f;
float RaidSpawnTime = 2.f;
float RaidTimeRandomness = 0.2f;
float RaidCheckFullTime = 0.5f;

const float ResearchPointsPerSize = 400.f;

const float PirateMinimumMetalsForRaid = 240.f * 1000.f;
const float PirateMetalsForSplit = 480.f * 1000.f;
const float PirateBuildRaiderChance = 0.5f;
const float PirateMinPillagerFraction = 0.3f;
const float PirateCheckPoolsTime = 1.f;
const float PirateDivideGlobalResourceMinimum = 20.f * 1000.f;
const float PirateGalaxyCheckInterval = 10.f;

const uint PirateCheckShipsPerTick = 10;

const string@ strMtl = "Metals", strAdv = "AdvParts", strElc = "Electronics";

// Technologies to research and keep at equal levels
string[] researchTechs = {
	"BeamWeapons", "Missiles", "ProjWeapons", 
	"EnergyPhysics", "ShipSystems", "ParticlePhysics"
	"Engines", "Chemistry", "Cargo", "Armor", "Shields"
	"Stealth", "ShipConstruction", "Computers", "Materials"
};

void init_pirate_ai() {
	if(!initialized) {
		loadDefaults(false);
		initialized = true;

		float mult = getGameSetting("GAME_PIRATE_MULT", 1.f);
		PirateResGenPerSecond = mult * 150.f;
		ResearchPointsGenPerSecond = mult * 150.f;
		PirateRaidDelay = max((60 - (mult * 9.f)), 4.f)*60.f;
	}
}

void prep_pirate_ai_defaults(Empire@ emp) {
	// Design init is done by the research manager,
	// it needs to cheat some unlocks first
}

interface Task {
	bool update(Empire@ emp, PirateAIData@ data, float tick);
};

// {{{ Utilities.
// Search weigher for systems to attack
float BootySearch(SysSearchSettings& search, const SysStats& stats) {
	Empire@ us = search.getEmpire(0);
	uint empCount = search.empireCount;
	float ourStrength = stats.getStat(us, str_strength);
	float enemyStrength = 0.f;
	float planets = 0.f;
	float weight = 0.f;

	if(ourStrength > 0.1f)
		// We don't want to raid systems we're already in
		return 0.f;

	for(uint i = 1; i < empCount; ++i) {
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

// Keeps track of resources assigned to a particular raid
class ResourcePool {
	float mtl;
	float adv;
	float elc;

	bool used;
	float timer;

	ResourcePool() {
		mtl = 0.f;
		adv = 0.f;
		elc = 0.f;
		timer = 0.f;
		used = false;
	}

	void transferTo(ResourcePool@ other, float percent) {
		float takeMtl = percent * mtl;
		float takeAdv = percent * adv;
		float takeElc = percent * elc;

		mtl -= takeMtl;
		adv -= takeAdv;
		elc -= takeElc;

		other.mtl += takeMtl;
		other.adv += takeAdv;
		other.elc += takeElc;
	}

	void load(XMLReader@ xml) {
		mtl = s_to_f(xml.getAttributeValue("m"));
		elc = s_to_f(xml.getAttributeValue("e"));
		adv = s_to_f(xml.getAttributeValue("a"));

		used = xml.getAttributeValue("u") == "true";
		timer = s_to_f(xml.getAttributeValue("t"));
	}

	void save(XMLWriter@ xml, string@ tagname) {
		xml.addElement(tagname, true, "m", f_to_s(mtl, 3), "e", f_to_s(elc, 3),
		                              "a", f_to_s(adv, 3), "t", f_to_s(timer, 3),
									  "u", used ? "true" : "false");
	}

	void dump() {
		warning("m: "+standardize(mtl)+"  e: "+standardize(elc)+"  a: "+standardize(adv));
		warning("u: "+(used ? "true" : "false")+"  t: "+ftos_nice(timer));
	}

	void fromEmpire(Empire@ emp) {
		mtl = emp.getStat(strMtl);
		elc = emp.getStat(strElc);
		adv = emp.getStat(strAdv);
	}
}

// Tracks a ship so we know when to cash it in
class TrackedShip {
	HulledObj@ obj;
	ResourcePool@ pool;
	System@ origParent;

	TrackedShip(HulledObj@ Obj, ResourcePool@ Pool) {
		@obj = Obj;
		@pool = Pool;
		@origParent = obj.toObject().getCurrentSystem();
	}
};
// }}}
// {{{ PirateAIData: Global pirate manager.
class WarMongerTask : Task {
	bool update(Empire@ emp, PirateAIData@ data, float tick) {
		// Declare war on everybody
		uint cnt = getEmpireCount();
		for (uint i = 0; i < cnt; ++i) {
			Empire@ other = getEmpire(i);

			if (other.ID > 0)
				declareWar(emp, getEmpire(i));
		}

		return true;
	}
};

class PirateAIData {	
	float checkTimer;
	float researchPoints;
	float galaxyCheckTimer;
	bool searching;
	bool doRaids;

	set_int busyObjects;

	ResourcePool@ globalResources;
	ResourcePool@[] pools;

	TrackedShip@[] ships;
	uint trackedShips;
	uint checkShip;

	RaidManager@[] raids;
	Task@[] tasks;

	ShipDesign@[] shipDesigns;

	SysSearchSettings sss_booty;

	PirateAIData(Empire@ emp) {
		// Callbacks
		sss_booty.setCallback("BootySearch");

		// Declare war
		addTask(WarMongerTask());

		// Start researching
		addTask(ResearchManager(emp, this));

		// Not searching yet
		searching = false;

		checkShip = 0;
		trackedShips = 0;
		checkTimer = 0.f;
		researchPoints = 0;
		galaxyCheckTimer = PirateGalaxyCheckInterval;

		// Check if we should do raids
		doRaids = getGameSetting("GAME_PIRATE_RAIDS", 1.f) > 0.5f;

		// Init global resources
		@globalResources = ResourcePool();

		pools.resize(1);
		@pools[0] = ResourcePool();
		pools[0].timer = PirateRaidDelay;
	}

	PirateAIData(Empire@ emp, XMLReader@ xml) {
		// Not searching yet
		searching = false;

		// Start researching
		ResearchManager@ resman = ResearchManager(emp, this);
		resman.initialized = 2;

		addTask(resman);

		// Callbacks
		sss_booty.setCallback("BootySearch");

		// Global resources
		@globalResources = ResourcePool();
		globalResources.fromEmpire(emp);

		// Timers
		checkShip = 0;
		trackedShips = 0;
		researchPoints = 0;
		checkTimer = 0.f;
		galaxyCheckTimer = PirateGalaxyCheckInterval;

		// Read data
		while(xml.advance()) {
			string@ name = xml.getNodeName();
			switch(xml.getNodeType()) {
				case XN_Element:
					if(name == "vars") {
						while(xml.advance()) {
							string@ varName = xml.getNodeName();
							if(xml.getNodeType() == XN_Element) {
								string@ value = xml.getAttributeValue("v");
								if (varName == "doRaids")
									doRaids = value == "true";
								else if (varName == "gr")
									globalResources.load(xml);
							}
							else if(xml.getNodeType() == XN_Element_End && varName == "vars") {
								break;
							}
						}
					}
					else if(name == "dsgns") {
						uint index = 0;
						while(xml.advance()) {
							string@ node_name = xml.getNodeName();
							if(xml.getNodeType() == XN_Element && node_name == "d") {
								ShipDesign@ design = ShipDesign(xml.getAttributeValue("n"));
								design.goalID = s_to_i(xml.getAttributeValue("g"));
								shipDesigns.resize(index + 1);
								@shipDesigns[index] = @design;
								++index;
							}
							else if(xml.getNodeType() == XN_Element_End && node_name == "dsgns") {
								if(shipDesigns.length() == 0) {
									uint realLayoutCount = 0, designCount = defaultDesigns.length();
									shipDesigns.resize(designCount);
									for(uint i = 0; i < designCount; ++i)
										if(defaultDesigns[i].forAI)
											@shipDesigns[realLayoutCount++] = @defaultDesigns[i];
									shipDesigns.resize(realLayoutCount);
								}
								break;
							}
						}
					}
					else if (name == "pools") {
						while(xml.advance()) {
							string@ nodeName = xml.getNodeName();
							if(xml.getNodeType() == XN_Element && nodeName == "p") {
								uint num = pools.length();
								pools.resize(num+1);
								@pools[num] = ResourcePool();
								pools[num].load(xml);
							}
							else if(xml.getNodeType() == XN_Element_End && nodeName == "pools") {
								break;
							}
						}
					}
					else if (name == "raids") {
						if (pools.length() == 0) {
							pools.resize(1);
							@pools[0] = ResourcePool();
						}

						while(xml.advance()) {
							string@ nodeName = xml.getNodeName();
							if(xml.getNodeType() == XN_Element && nodeName == "r") {
								System@ sys = getObjectByID(s_to_i(xml.getAttributeValue("sys")));

								if (@sys != null) {
									RaidManager@ raid = RaidManager(sys, globalResources);

									raid.returnedPillagers = s_to_i(xml.getAttributeValue("ret"));
									raid.raidTimer = s_to_f(xml.getAttributeValue("time"));

									int poolNum = s_to_i(xml.getAttributeValue("pool"));

									if (poolNum >= 0 && poolNum < int(pools.length()))
										@raid.pool = pools[poolNum];
									else
										@raid.pool = pools[0];

									addRaid(raid);
								}
							}
							else if(xml.getNodeType() == XN_Element_End && nodeName == "raids") {
								break;
							}
						}
					}
					else if (name == "ships") {
						while(xml.advance()) {
							string@ nodeName = xml.getNodeName();
							if(xml.getNodeType() == XN_Element && nodeName == "t") {
								Object@ obj = getObjectByID(s_to_i(xml.getAttributeValue("id")));
								Object@ parent = getObjectByID(s_to_i(xml.getAttributeValue("sys")));
								int poolNum = s_to_i(xml.getAttributeValue("pool"));

								if (poolNum >= 0 && poolNum < int(pools.length()) && obj !is null && parent !is null) {
									HulledObj@ ship = obj;
									System@ sys = parent;

									if (obj !is null && sys !is null) {
										trackShip(ship, pools[poolNum]);
										@ships[trackedShips-1].origParent = sys;
									}
								}
							}
							else if(xml.getNodeType() == XN_Element_End && nodeName == "ships") {
								break;
							}
						}
					}

					if (pools.length() == 0) {
						pools.resize(1);
						@pools[0] = ResourcePool();
					}
				break;
			}
		}
	}


	void save(XMLWriter@ xml) {
		xml.createHeader();

		xml.addElement("vars", false);
		xml.addElement("doRaids", true, "v", doRaids ? "true" : "false");
		globalResources.save(xml, "gr");
		xml.closeTag("vars");
		
		if(shipDesigns.length() > 0) {
			xml.addElement("dsgns", false);
			for(uint i = 0; i < shipDesigns.length(); ++i) {
				ShipDesign@ design = shipDesigns[i];
				xml.addElement("d", true, "n", design.className, "g", i_to_s(design.goalID));
			}
			xml.closeTag("dsgns");
		}

		if (pools.length() > 0) {
			xml.addElement("pools", false);
			for (uint i = 0; i < pools.length(); ++i) {
				pools[i].save(xml, "p");
			}
			xml.closeTag("pools");
		}

		if(raids.length() > 0) {
			xml.addElement("raids", false);
			for (uint i = 0; i < raids.length(); ++i) {
				RaidManager@ raid = raids[i];
				xml.addElement("r", true, "sys", i_to_s(raid.sys.toObject().uid),
				                          "ret", i_to_s(raid.returnedPillagers),
										  "time", ftos_nice(raid.raidTimer),
										  "pool", i_to_s(getPoolIndex(raid.pool)));
			}
			xml.closeTag("raids");
		}

		if (trackedShips > 0) {
			xml.addElement("ships", false);
			for (uint i = 0; i < ships.length() && i < trackedShips; ++i) {
				TrackedShip@ track = ships[i];
				xml.addElement("t", true, "id", i_to_s(track.obj.toObject().uid),
				                          "sys", i_to_s(track.origParent.toObject().uid),
										  "pool", i_to_s(getPoolIndex(track.pool)));
			}
			xml.closeTag("ships");
		}
	}

	void tick(Empire@ emp, float time) {
		Empire@ space = getEmpireByID(-1);

		// Check if we should do raids
		if (doRaids) {
			// Generate resources into empire back
			float gen = time * PirateResGenPerSecond * ceil(gameTime / 600.0);

			emp.addStat(strMtl, gen);
			emp.addStat(strElc, gen * 0.4f);
			emp.addStat(strAdv, gen * 0.2f);

			globalResources.mtl += gen;
			globalResources.elc += gen * 0.4f;
			globalResources.adv += gen * 0.2f;

			// Check whether we have a system to plunder
			if (searching && sss_booty.searchFinished) {
				// Check all resource pools and raid timers to see if we should spawn a new raid
				if (checkTimer <= 0.1f) {
					System@ best = sss_booty.getBestSystem();
					checkTimer = PirateCheckPoolsTime;
					
					if (best !is null) {
						uint poolCnt = pools.length();
						float splitThres = poolCnt * PirateMetalsForSplit;
						bool launchedRaid = false;

						for (uint i = 0; i < poolCnt; ++i) {
							ResourcePool@ pool = pools[i];

							// Only bother with unused pools
							if (!pool.used) {
								// Check if we have enough resources
								if (pool.mtl < PirateMinimumMetalsForRaid) {
									
									if (poolCnt > 1) {
										// We have more pools left, dissolve the pool
										pool.transferTo(globalResources, 1.f);
										pools.erase(i);
										--i; --poolCnt;
									}
									continue;
								}

								// Check if we should split up the pool
								if (pool.mtl > splitThres) {
									uint num = pools.length();
									pools.resize(num+1);
									@pools[num] = ResourcePool();
									pool.transferTo(pools[num], 0.5f);
								}

								// Launch a raid
								if (!launchedRaid && pool.timer <= 0.1f) {
									RaidManager@ raid = RaidManager(best, pool);
									addRaid(raid);
									pool.used = true;
									launchedRaid = true;
								}
							}
						}
					}

					searching = false;
				}
				else
					checkTimer -= time;
			}

			uint poolCnt = pools.length();
			bool divide = globalResources.mtl > PirateDivideGlobalResourceMinimum;
			float divideAmt = 1.f / poolCnt;

			for (uint i = 0; i < poolCnt; ++i) {
				// Update pool timers
				if (!pools[i].used) {
					if (pools[i].timer > 0.1f) {
						pools[i].timer -= time;
					}
					else if (!searching && pools[i].mtl > PirateMinimumMetalsForRaid) {
						// Start search if we have available pools
						searching = true;

						// Update search empires
						sss_booty.clearEmpires();
						sss_booty.addEmpire(emp);

						uint empCount = getEmpireCount();
						for(uint i = 0; i < empCount; ++i) {
							const Empire@ other = getEmpire(i);
							if(!(other is emp) && other.isValid() && emp.isEnemy(other)) {
								sss_booty.addEmpire(other);
							}
						}

						sss_booty.findBestSystem();
					}
				}

				// Check if we should distribute resources from the global pool
				if (divide) {
					globalResources.transferTo(pools[i], divideAmt);
				}
			}

			// Update all currently active raids
			for (uint i = 0, cnt = raids.length(); i < cnt; ++i) {
				RaidManager@ raid = raids[i];

				if (raid.update(emp, this, time)) {
					raid.pool.used = false;
					raid.pool.timer = randomf(0.3f, 1.f) * PirateRaidInterval;

					raids.erase(i);
					--i; --cnt;
				}
			}

			// Periodically check all ships in the galaxy
			if (galaxyCheckTimer <= 0.1f) {
				galaxyCheckTimer = PirateGalaxyCheckInterval;

				System@ glx = getGalaxy().toObject().toSystem();
				SysObjList objs;
				objs.prepare(glx);

				for (uint i = 0; i < objs.childCount; ++i) {
					Object@ obj = objs.getChild(i);
					HulledObj@ hulled = obj;

					if (hulled !is null && obj.getOwner() is emp) {
						cashIn(globalResources, emp, hulled);
					}
				}
			}
			else
				galaxyCheckTimer -= time;
		}

		// Update all other tasks
		for (uint i = 0, cnt = tasks.length(); i < cnt; ++i) {
			Task@ task = tasks[i];

			if (task.update(emp, this, time)) {
				tasks.erase(i);
				--i; --cnt;
			}
		}

		// Check ships in the galaxy that should be cashed in
		if (trackedShips > 0) {
			for (uint i = 0; i < PirateCheckShipsPerTick && i < trackedShips; ++i) {
				if (checkShip < ships.length()) {
					HulledObj@ ship = ships[checkShip].obj;

					if (!ship.toObject().isValid())
						continue;

					if (ship.toObject().getCurrentSystem() !is ships[checkShip].origParent) {
						// Cash in ships from the galaxy
						cashIn(ships[checkShip].pool, emp, ship);
						ships.erase(checkShip);
						--checkShip; --trackedShips;
					}
				}
				else {
					// What?
					checkShip = 0;
					trackedShips = 0;
					break;
				}

				if (trackedShips == 0)
					checkShip = 0;
				else
					checkShip = (checkShip + 1) % trackedShips;
			}
		}
	}

	void onDiplomaticMessage(Empire@ emp, Empire@ from, DiploMsg@ msg) {
	}

	void trackShip(HulledObj@ obj, ResourcePool@ pool) {
		uint pos = trackedShips++;

		if (pos >= ships.length())
			if (ships.length() == 0)
				ships.resize(16);
			else
				ships.resize(ships.length() * 2);

		@ships[pos] = TrackedShip(obj, pool);
	}

	void addRaid(RaidManager@ raid) {
		uint pos = raids.length();
		raids.resize(pos + 1);
		@raids[pos] = @raid;
	}

	void removeRaid(RaidManager@ raid) {
		// Resource pool
		raid.pool.used = false;
		raid.pool.timer = randomf(0.3f, 1.f) * PirateRaidInterval;

		// Remove from the list
		for(uint i = 0, cnt = raids.length(); i < cnt; ++i) {
			if(raids[i] is raid) {
				raids.erase(i);
				return;
			}
		}
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

	int getPoolIndex(ResourcePool@ pool) {
		for (uint i = 0, cnt = pools.length(); i < cnt; ++i) {
			if (pools[i] is pool)
				return i;
		}
		return -1;
	}
	
	ShipDesign@ pickRandomAffordableLayout(ResourcePool@ pool, Empire@ emp, GoalID goal) {
		uint cnt = shipDesigns.length();

		ShipDesign@[] matches;
		matches.resize(cnt);
		uint matchCount = 0;
		
		for(uint i = 0; i < cnt; ++i) {
			if(shipDesigns[i].goalID == goal) {
				ShipDesign@ design = @shipDesigns[i];
				const HullLayout@ ship = @emp.getShipLayout(design.className);

				if (ship !is null) {
					HullStats@ stats = ship.getStats();
					
					if (stats.getCost(strMtl) <= pool.mtl && 
					stats.getCost(strElc) <= pool.elc &&
					stats.getCost(strAdv) <= pool.adv) {
						@matches[matchCount++] = design;
					}
				}
			}
		}
		
		if(matchCount == 0)
			return null;
		return matches[rand(matchCount - 1)];
	}

	void payForShip(ResourcePool@ pool, Empire@ emp, const HullLayout@ hull) {
		HullStats@ stats = hull.getStats();

		float mtl = stats.getCost(strMtl);
		float elc = stats.getCost(strElc);
		float adv = stats.getCost(strAdv);

		emp.addStat(strMtl, -mtl);
		emp.addStat(strElc, -elc);
		emp.addStat(strAdv, -adv);

		pool.mtl -= mtl;
		pool.elc -= elc;
		pool.adv -= adv;
	}

	void cashIn(ResourcePool@ pool, Empire@ emp, HulledObj@ hulled) {
		HullStats@ stats = hulled.getHull().getStats();

		// Get the cash back
		float mtl = stats.getCost(strMtl);
		float elc = stats.getCost(strElc);
		float adv = stats.getCost(strAdv);

		// Get the contents of the cargo bay
		const HullLayout@ hull = hulled.getHull();
		int goal = GoalID(hull.metadata);

		const State@ mtlCargo = hulled.toObject().getState(strMtl);
		if (@mtlCargo != null && mtlCargo.inCargo > 0.1f)
			mtl += mtlCargo.inCargo;

		const State@ elcCargo = hulled.toObject().getState(strElc);
		if (@elcCargo != null && elcCargo.inCargo > 0.1f)
			elc += elcCargo.inCargo;

		const State@ advCargo = hulled.toObject().getState(strAdv);
		if (@advCargo != null && advCargo.inCargo > 0.1f)
			adv += advCargo.inCargo;

		// Add resources to empire bank
		emp.addStat(strMtl, mtl);
		emp.addStat(strElc, elc);
		emp.addStat(strAdv, adv);

		// Add resources to pool
		pool.mtl += mtl;
		pool.elc += elc;
		pool.adv += adv;

		// Gain some research
		float scale = pow(hulled.getHull().scale, 2);
		researchPoints += ResearchPointsPerSize * scale;

		// Destroy the object
		hulled.toObject().destroy(true);
	}
};
// }}}
// {{{ RaidManager: Manages a single raid to a specific system.
class RaidManager {
	System@ sys;
	ResourcePool@ pool;
	float spawnTimer;
	float raidTimer;
	float checkTimer;
	int returnedPillagers;
	int pillagersFound;
	int raidersFound;

	RaidManager(System@ system, ResourcePool@ Pool) {
		if(logPirates)
			print("Pirates are raiding "+system.toObject().getName());

		@sys = system;
		@pool = Pool;
		spawnTimer = 0.f;
		raidTimer = vary(PirateRaidDuration, RaidTimeRandomness);
		returnedPillagers = 0;
		checkTimer = RaidCheckFullTime;
	}

	void retreat(Empire@ emp, PirateAIData@ data) {
		SysObjList objects;
		OrderList orders;
		objects.prepare(sys);

		uint cnt = objects.childCount;
		for (uint i = 0; i < cnt; ++i) {
			Object@ obj = objects.getChild(i);
			HulledObj@ hulled = obj;

			if (@hulled != null && obj.getOwner() is emp) {
				vector pos = obj.getPosition() - sys.toObject().getPosition();
				pos.normalize(sys.toObject().radius * 3.f);
				pos += sys.toObject().getPosition();

				orders.prepare(obj);
				orders.clearOrders(true);
				orders.giveMoveOrder(pos, false);

				data.trackShip(hulled, pool);
			}
		}

		objects.prepare(null);
		orders.prepare(null);
	}

	bool update(Empire@ emp, PirateAIData@ data, float time) {
		// Check if we're outnumbered
		SysPresence pr;
		emp.getSystemPresence(sys, pr);

		if ( raidTimer < PirateRaidDuration * 0.6f &&
			 pr.enemiesStr > 0.1f && pr.usStr > 40.f &&
			 pr.usStr / pr.enemiesStr <= StrengthGTFORatio) {

			if (logPirates)
				print(sys.toObject().getName()+" raid: getting the hell out of dodge.");
			retreat(emp, data);
			return true;
		}

		// Check the retreat timer
		if (raidTimer <= 0.1f) {
			if (logPirates)
				print(sys.toObject().getName()+" raid: retreating on schedule");
			retreat(emp, data);
			return true;
		}
		else
			raidTimer -= time;

		// Spawn new ships
		if (spawnTimer <= 0.1f) {
			spawnTimer = vary(RaidSpawnTime, RaidTimeRandomness);
			GoalID goal;

			// For every pillager that returns, spawn a new one
			if (returnedPillagers > 0)
				goal = GID_Pillage;
			// We always want at least a third of our ships to be pillagers
			else if (pillagersFound < (raidersFound+pillagersFound) * PirateMinPillagerFraction )
				goal = GID_Pillage;
			else
				goal = randomf(1.f) < PirateBuildRaiderChance ? GID_Raid : GID_Pillage;

			ShipDesign@ design = data.pickRandomAffordableLayout(pool, emp, goal);

			if (@design != null) {
				emp.updateHull(design.className, 10.f);
				const HullLayout@ buildShip = @emp.getShipLayout(design.className);
				
				data.payForShip(pool, emp, buildShip);

				// Calculate a random position at the edge of the system
				float theta = randomf(twoPi);
				float radius = sys.toObject().radius;

				vector pos = vector(radius * cos(theta), 0, radius * sin(theta));

				spawnShip(emp, buildShip, sys, pos);

				// Mark pillager as returned
				if (returnedPillagers > 0 && goal == GID_Pillage)
					--returnedPillagers;


				if (logPirates)
					print(sys.toObject().getName()+" raid: spawned a "+design.className);
			}
		} else
			spawnTimer -= time;

		// Check for full pillagers
		if (checkTimer <= 0.1f) {
			checkTimer = RaidCheckFullTime;

			SysObjList objects;
			OrderList orders;
			objects.prepare(sys);

			uint cnt = objects.childCount;
			pillagersFound = 0;
			raidersFound = 0;
			for (uint i = 0; i < objects.childCount; ++i) {
				Object@ obj = objects.getChild(i);
				HulledObj@ hulled = obj;

				if (@hulled != null && obj.getOwner() is emp) {
					const HullLayout@ hull = hulled.getHull();
					int goal = GoalID(hull.metadata);

					if (goal == GID_Pillage)
						++pillagersFound;
					else if (goal == GID_Raid)
						++raidersFound;

					if (goal == GID_Pillage && !data.busyObjects.exists(obj.uid)) {
						float used, max;
						obj.getCargoVals(used, max);

						if(used >= max - 0.1f) {
							// Return the pillager ship to the bank
							vector pos = obj.getPosition() - sys.toObject().getPosition();
							pos.normalize(sys.toObject().radius * 3.f);
							pos += sys.toObject().getPosition();

							orders.prepare(obj);
							orders.clearOrders(true);
							orders.giveMoveOrder(pos, false);

							data.busyObjects.insert(obj.uid);
							data.trackShip(hulled, pool);
							++returnedPillagers;
						}
					}
				}
			}

			objects.prepare(null);
			orders.prepare(null);
		}
		else
			checkTimer -= time;

		return false;
	}
};
// }}}
// {{{ ResearchManager: Manages which technologies are upgraded by the pirates
class ResearchManager : Task {
	const WebItem@ watchTech;
	float goalLevel;
	int initialized;

	ResearchManager(Empire@ emp, PirateAIData@ data) {
		initialized = 0;
	}
	
	void switchTechnology(Empire@ emp, PirateAIData@ data, ResearchWeb& web) {
		goalLevel = 0;
		
		float getNumLevels;
		string@ researchName;

		getNumLevels = 1.f;
		@researchName = pickTech(web, researchTechs);
		
		if(researchName is null)
			return;
		
		const WebItem@ tech = web.getItem(researchName);

		if(tech is null)
			return;
		
		@watchTech = @tech;
		
		goalLevel = tech.get_level() + getNumLevels;
		web.setActiveTech(tech.descriptor);

		if (data.researchPoints > 0.1f) {
			float level, progress, cost, max;
			tech.getLevels(level, progress, cost, max);
			float use = min(data.researchPoints, cost - progress);

			if (logPirates)
				print("Pirates adding "+use+" points to "+tech.descriptor.get_id());

			web.addPoints(tech.descriptor, use);
			data.researchPoints -= use;
		}

		if (logPirates)
			print("Pirates researching "+tech.descriptor.name+" to level "+tech.get_level()+" at rate "+web.getResearchRate());
	}

	bool update(Empire@ emp, PirateAIData@ data, float tick) {
		ResearchWeb web;
		web.prepare(emp);

		// Unlock technologies we start with
		if(initialized == 0) {
			web.markAsVisible("Missiles");
			web.markAsVisible("BeamWeapons");
			web.markAsVisible("Chemistry");
			web.markAsVisible("Armor");
			web.markAsVisible("Stealth");

			levelTo(web, "Missiles", 6);
			levelTo(web, "BeamWeapons", 6);
			levelTo(web, "EnergyPhysics", 20);
			levelTo(web, "Chemistry", 8);
			levelTo(web, "Cargo", 10);
			levelTo(web, "Engines", 3);
			levelTo(web, "Materials", 4);
			levelTo(web, "Armor", 3);
			levelTo(web, "ProjWeapons", 3);
			levelTo(web, "ShipConstruction", 4);
			levelTo(web, "Stealth", 4);

			initialized = 1;
		}

		if (initialized == 1) {
			// We load the designs here so we can use unlocked systems
			int designCount = defaultDesigns.length();
			uint realLayoutCount = 0;
			data.shipDesigns.resize(designCount);

			for(int i = 0; i < designCount; ++i)
				if(defaultDesigns[i].forPirates) {
					if (defaultDesigns[i].generateForEmpire(emp))
						@data.shipDesigns[realLayoutCount++] = @defaultDesigns[i];
				}

			data.shipDesigns.resize(realLayoutCount);

			initialized = 2;
		}

		// Set the appropriate research rate
		web.setResearchRate(ResearchPointsGenPerSecond * gameTime / 60.f);

		// Check if we should switch technologies
		if(watchTech is null || watchTech.get_level() >= goalLevel) {
			switchTechnology(emp, data, web);
		}
		
		web.prepare(null);
		return false;
	}
};
// }}}


#include "/include/empire_lib.as"

PirateAIData@ pirateData = null;

void registerPirateData(PirateAIData@ data) {
	pirateData = data;
}

PirateAIData@ getPirateData() {
	return pirateData;
}

class TrackedShip {
	HulledObj@ ship;
	System@ targ;
	
	bool isRetreating;
	
	TrackedShip(HulledObj@ obj, System@ target) {
		@ship = @obj;
		@targ = @target;
		
		isRetreating = false;
	}
	
	TrackedShip(XMLReader@ xml, System@ target) {
		@ship = getObjectByID(s_to_i(xml.getAttributeValue("obj"))).toHulledObj();
		@targ = @target;
		
		isRetreating = xml.getAttributeValue("ret") == "true";
	}
	
	void save(XMLWriter@ xml) {
		xml.addElement("ship",true,"obj",i_to_s(ship.toObject().uid),"ret",isRetreating ? "true":"false");
	}
	
	void retreat(Region@ region) {
		isRetreating = true;
	}
	
	bool destroyed() {
		if(@ship == null || !objectExists(ship.toObject().uid)) {
			return true;
		}
		return false;
	}

	bool retreated() {
		if(ship.toObject().getCurrentSystem() != targ) {
			return true;
		}
		return false;
	}
};

class Raid {
	
	TrackedShip@[] ships;
	System@ target;
	
	float checkTimer;
	float strengthRatio;
	float timeLeft;
	
	uint shipsPerCheck;
	uint lastShipIndex;
	
	Raid(System@ sys, float duration) {
		strengthRatio = 1.0f;
		timeLeft = duration;
		checkTimer = 0.0f;
		shipsPerCheck = 10;
		
		timeLeft = duration;
		lastShipIndex = 0;
		@target = @sys;
		
		spawnShips();
	}
	
	Raid(XMLReader@ xml {
		strengthRatio = 1.0f;
		timeLeft = duration;
		checkTimer = 0.0f;
		shipsPerCheck = 10;
		
		timeLeft = s_to_f(xml.getAttributeValue("time"));
		lastShipIndex = s_to_i(xml.getAttributeValue("index"));
		@target = getObjectByID(s_to_i(xml.getAttributeValue("targ"))).toSystem();
		
		uint index = 0;
		while(xml.advance()) {
			string@ name = xml.getNodeName();
			if(xml.getNodeType() == XN_Element && name == "ship") {
				TrackedShip@ ship = TrackedShip(xml,target);
				ships.resize(index + 1);
				@ships[index] = @ships;
				++index;	
			}
			else if(xml.getNodeType() == XN_Element_End && name == "r") {
				break;
			}
		}		
	}
	
	void save(XMLWriter@ xml) {
		xml.addElement("r",false,"time",f_to_s(timeLeft),"index",i_to_s(lastShipIndex),"targ",i_to_s(target.toObject().uid));
		
		for(uint i = 0; i < ships.length(); ++i) {
			ships[i].save(xml);
		}
		
		xml.closeTag("r");
		
	}
	
	void update(Region@ region, float time) {
		if(checkTimer <= 0.0f) {
			if(timeLeft <= 0.0f) {
				for(uint i = lastShipIndex; i <= lastShipIndex + shipsPerCheck && i < ships.length(); ++i) {
					if(!ships[i].isRetreating) {
						ships[i].retreat(region);
					}
				}
			}
			else {
				timeLeft -= time;
				
				SystemMonitor@ mon = region.getSystemMonitor(target);
				float strRatio = mon.ourStrength / mon.militaryStrength;
				if(strRatio < strengthRatio) {
					for(uint i = lastShipIndex; i <= lastShipIndex + shipsPerCheck && i < ships.length(); ++i) {
						if(!ships[i].isRetreating) {
							ships[i].retreat(region);
						}
					}			
				}				
			}	
			
			uint[] rem;
			for(uint i = lastShipIndex; i <= lastShipIndex + shipsPerCheck && i < ships.length(); ++i) {
				if(ships[i].destroyed()) {
					uint n = rem.length();
					rem.resize(n+1);
					rem[n] = i;
				}					
				else if(ships[i].retreated()) {
					region.resMan.shipReturned(ships[i].ship);
					ships[i].toObject().destroy(true);
					
					uint n = rem.length();
					rem.resize(n+1);
					rem[n] = i;
				}				
			}
				
			for(uint j = 0; j < rem.length(); ++j) {
				ships.erase(rem[j]);
			}
			
			lastShipIndex += shipsPerCheck;
			if(lastShipIndex >= ships.length()) {
				lastShipIndex = 0;
			}
			
			checkTimer = 200.0f;
		}
		else {
			checkTimer -= time;
		}
	}
	
	void spawnShips() {
		
	}	
};

class RaidManager {
	
	Raid@[] raids;
	
	float raidInterval;
	float raidDelay;
	float raidDuration;
	
	float lastRaid;
	
	RaidManager(Region@ region) {
		raidInterval = 12.0f * 60.0f / region.multiplier;
		raidDuration = 6.0f * 60.0f * region.multiplier;
		
		lastRaid = 0.0f;
	}
	
	RaidManager(Region@ region, XMLReader@ xml) {
		raidInterval = 12.0f * 60.0f / region.multiplier;
		raidDelay = 3.0f * 60.0f / region.multiplier;
		raidDuration = 6.0f * 60.0f * region.multiplier;
		
		lastRaid = s_to_f(xml.getAttributeValue("lr"));
		
		uint index = 0;
		while(xml.advance()) {
			string@ name = xml.getNodeName();
			if(xml.getNodeType() == XN_Element && name == "r") {
				Raid@ raid = Raid(xml);
				raids.resize(index + 1);
				@raids[index] = @raid;
				++index;				
			}
			else if(xml.getNodeType() == XN_Element_End && name == "rm") {
				break;
			}
		}
	}
	
	void update(PirateAIData@ data, Region@ region, Empire@ emp, float time) {
		for(uint i = 0; i < raids.length(); ++i) {
			raids[i].update(region,time);
		}
		
		if(getGameTime() - lastRaid > raidInterval) {
			//TODO: Add Raid Creation
		}
	}
	
	void save(XMLWriter@ xml) {
		xml.addElement("rm",false,"lr",f_to_s(lastRaid));
		
		for(uint i = 0; i < raids.length(); ++i) {
			raids[i].save(xml);
		}
		
		xml.closeTag("rm");
	}	
};

class ResourceManager {
	
	float credits;
	float materials;
	float crew;
	
	float passiveCredits;
	float passiveMaterials;
	float passiveCrew;
	
	ResourceManager(Region@ region) {
		credits = 0.0f;
		materials = 0.0f;
		crew = 0.0f;
		
		passiveCredits = 5.0f * region.multiplier;
		passiveMaterials = 10.0f * region.multiplier;
		passiveCrew = 2.5f * region.multiplier;
	}
	
	ResourceManager(Region@ region, XMLReader@ xml) {
		credits = s_to_f(xml.getAttributeValue("cr"));
		materials = s_to_f(xml.getAttributeValue("mt"));
		crew = s_to_f(xml.getAttributeValue("crew"));
		
		passiveCredits = 5.0f * region.multiplier;
		passiveMaterials = 10.0f * region.multiplier;
		passiveCrew = 2.5f * region.multiplier		
	}	
	
	void update(float time) {
		credits += passiveCredits * time;
		materials += passiveMaterials * time;
		crew += passiveCrew * time;
	}	
	
	void save(XMLWriter@ xml) {
		xml.addElement("res",false,"cr",f_to_s(credits),"mt",f_to_s(materials),"crew",f_to_s(crew));
	}
	
	void shipReturned(HulledObj@ ship) {
	}
	
	void shipBuilt(HulledObj@ ship) {
	}
	
	void baseBuilt() {
	}
	
	void baseDestroyed() {
	}
	
	bool canBuildBase() {
		return false;
	}
};

class SystemMonitor {

	System@ sys;
	
	float economicValue;
	float militaryStrength;
	float ourStrength;
	int inhabitedPlanets;
	
	float checkTimer;
	
	SystemMonitor(System@ system) {
		@sys = @system;
		
		economicValue = 0.0f;
		militaryStrength = 0.0f;
		inhabitedPlanets = 0;
		ourStrength = 0.0f;
		
		checkTimer = 0.0f;
	}
	
	SystemMonitor(XMLReader@ xml) {
		uint uid = s_to_i(xml.getAttributeValue("uid"));
		@sys = getObjectByID(uid).toSystem();
		
		economicValue = s_to_f(xml.getAttributeValue("ec"));
		militaryStrength = s_to_f(xml.getAttributeValue("ml"));
		outStrength = s_to_f(xml.getAttributeValue("os"));
		inhabitedPlanets = s_to_i(xml.getAttributeValue("in"));
		
		checkTimer = 0.0f;
	}
	
	void save(XMLWriter@ xml) {
		xml.addElement("sys",true,"uid",i_to_s(sys.toObject().uid),"ec",f_to_s(economicValue),"ml",f_to_s(militaryStrength),"in",i_to_s(inhabitedPlanets),"os",f_to_s(outStrength));
	}
		
	void update(Empire@ emp, float time) {
		if(checkTimer <= 0.0f) {
			inhabitedPlanets = 0;
			economicValue = 0.0f;
			militaryStrength = 0.0f;
			
			ourStrength = sys.toObject().getStrength(emp);
					
			uint cnt = getEmpireCount();
			for (uint i = 0; i < cnt; ++i) {
				Empire@ other = getEmpire(i);
				if (!other.isValid() || other.ID < 0) {
					continue;
				}

				inhabitedPlanets += sys.toObject().getPlanets(other);
				economicValue += sys.toObject().getCivStrength(other);
				militaryStrength += sys.toObject().getStrength(other);
			}	
			
			checkTimer = 200.0f;
		}		
		else {
			checkTimer -= time;
		}
	}
		
	float getSystemValue() {
		return (economicValue / militaryStrength);
	}	
	
};

class Region {
	
	uint asteroidBase;

	ResourceManager@ resMan;
	RaidManager@ raidMan;

	SystemMonitor@[] systems;

	float multiplier;
	float lastBaseTime;
	float minTimeSinceLastBase;
	
	Region(PirateAIData@ data) {
		multiplier = data.multipler;
		
		@resMan = ResourceManager(this);
		@raidMan = RaidManager(this);
		
		lastBaseTime = 0.0f;
		asteroidBase = 0;

		minTimeSinceLastBase = (60.0f * 45.0f) / multiplier;
	}
	
	Region(PirateAIData@ data, XMLReader@ xml) {
		multiplier = data.multipler;
		minTimeSinceLastBase = (60.0f * 45.0f) / multiplier;
		
		while(xml.advance()) {
			string@ name = xml.getNodeName();
			if(xml.getNodeType() == XN_Element) {
				if(name == "stms") {
					loadSystemMonitors(xml);
				}
				else if(name == "rm") {
					@raidMan = RaidManager(this,xml);
				}
				else if(name == "res") {
					@resMan = ResourceManager(this,xml);
				}
				else if(name == "base") {
					asteroidBase = s_to_i(xml.getAttributeValue("uid"));
					lastBaseTime = s_to_f(xml.getAttributeValue("time"));
				}
			}
			else if(xml.getNodeType() == XN_Element_End && name == "rgn"){
				break;
			}
		}
	}
	
	void save(XMLWriter@ xml) {
		xml.addElement("rgn",false);
		
		if(systems.length() > 0) {
			xml.addElement("stms",false);
			for(uint i = 0; i < systems.length(); ++i) {
				systems[i].save(xml);
			}
			xml.closeTag("stms");
		}
		
		raidMan.save(xml);
		resMan.save(xml);
		
		xml.addElement("base",true,"uid",i_to_s(asteroidBase),"time",f_to_s(lastBaseTime));
		
		xml.closeTag("rgn");
	}
	
	void update(PirateAIData@ data, Empire@ emp, float time) {		
		for(uint i = 0; i < systems.length(); ++i) {
			systems[i].update(emp,time);
		}
		
		resMan.update(time);
		
		if(hasBaseSystem()) {
			if(objectExists(asteroidBase)) {
				raidMan.update(data,this,emp,time);
			}
			else {
				asteroidBase = 0;
				lastBaseTime = getGameTime();
				resMan.baseDestroyed();
			}
		}
		else
		{
			float timeSince = getGameTime() - lastBaseTime;
			if(timeSince > minTimeSinceLastBase && resMan.canBuildBase()) {
				createBaseSystem(emp);
			}
		}
	}	
	
	void loadSystemMonitors(XMLReader@ xml) {
		uint index = 0;
		while(xml.advance()) {
			string@ name = xml.getNodeName();
			if(xml.getNodeType() == XN_Element && name == "sys") {
				SystemMonitor@ sysMon = SystemMonitor(xml);
				systems.resize(index + 1);
				@systems[index] = @sysMon;
				++index;
			}
			else if(xml.getNodeType() == XN_Element_End && name == "stms") {
				break;
			}
		}
	}	
	
	void addSystemMonitor(System@ sys) {
		uint n = systems.length();
	
		systems.resize(n + 1);
		@systems[n] = SystemMonitor(sys);
	}	
	
	SystemMonitor@ getSystemMonitor(System@ sys) {
		for(uint i = 0; i < systems.length(); ++i) {
			if(@systems[i].sys == @sys) {
				return systems[i];
			}
		}
		return null;
	}	
	
	System@ getBestSystem() {
		uint index = 0;
		float indexStrength = 1.0f;
		
		for(uint i = 0; i < systems.length(); ++i) {
			float iStrength = systems[i].inhabitedPlanets * systems[i].militaryStrength;
			if(iStrength <= indexStrength) {
				index = i;
				indexStrength = iStrength;
			}
		}
		
		return systems[index].sys;
	}	
	
	void createBaseSystem(Empire@ emp) {
		System@ targ = getBestSystem();
		
		Planet_Desc desc;
		Orbit_Desc orbit;
		
		resMan.baseBuilt();
	}
		
	bool hasBaseSystem() {
		return asteroidBase > 0;
	}
	
	System@ getBaseSystem() {
		if(objectExists(asteroidBase) {
			return = getObjectByID(asteroidBase).getCurrentSystem();
		}
		return null;
	}
};

class ResearchManager {

	ResearchManager(PirateAIData@ data) {
	}
	
	void update(PirateAIData@ data, Empire@ emp, float time)
	{
	}

};

class PirateAIData {

	bool regionsInitialized;
	float multipler;
	
	ResearchManager@ resMan;
	ShipDesign@[] shipDesigns;
	Region@[] regions;

	PirateAIData(Empire@ emp) {
		regionsInitialized = false;
		multipler = getGameSetting("MAP_PIRATES_MULT",1.0f);	
		
		@resMan = ResearchManager(this);
		
		registerPirateData(this);
	}

	PirateAIData(Empire@ emp, XMLReader@ xml) {
		regionsInitialized = false;
		multipler = getGameSetting("MAP_PIRATES_MULT",1.0f);	

		@resMan = ResearchManager(this);
		
		while(xml.advance()) {
			string@ name = xml.getNodeName();
			switch(xml.getNodeType()) {
				case XN_Element:
					if(name == "dsgns") {
						loadDesigns(xml);
					}
					else if(name == "rgns") {
						loadRegions(xml);
					}
				break;
			}
		}
		
		registerPirateData(this);
	}
	
	void save(XMLWriter@ xml) {
		xml.createHeader();
		
		if(shipDesigns.length() > 0) {
			xml.addElement("dsgns",false);
			for(uint i = 0; i < shipDesigns.length(); ++i) {
				ShipDesign@ design = shipDesigns[i];
				xml.addElement("d", true, "n", design.className, "g", i_to_s(design.goalID));				
			}
			xml.closeTag("dsgns");
		}
		
		if(regions.length() > 0) {
			xml.addElement("rgns",false);
			for(uint j = 0; j < regions.length(); ++j) {
				regions[j].save(xml);
			}
			xml.closeTag("rgns");
		}
	}
	
	void tick(Empire@ emp, float time) {
		if(!regionsInitialized) {
			createRegions();
		}
		
		for(uint i = 0; i < regions.length(); ++i) {
			regions[i].update(this,emp,time);
		}
		
		resMan.update(this,emp,time);
	}
	
	void onDiplomaticMessage(Empire@ emp, Empire@ from, DiploMsg@ msg) {
	}	
	
	void loadDesigns(XMLReader@ xml) {
		uint index = 0;
		while(xml.advance()) {
			string@ name = xml.getNodeName();
			if(xml.getNodeType() == XN_Element && name == "d") {
				ShipDesign@ design = ShipDesign(xml.getAttributeValue("n"));
				design.goalID = s_to_i(xml.getAttributeValue("g"));
				shipDesigns.resize(index + 1);
				@shipDesigns[index] = @design;
				++index;
			}
			else if(xml.getNodeType() == XN_Element_End && name == "dsgns") {
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
	
	void loadRegions(XMLReader@ xml) {
		uint index = 0;
		while(xml.advance()) {
			string@ name = xml.getNodeName();
			if(xml.getNodeType() == XN_Element && name == "rgn") {
				Region@ region = Region(this,xml);
				regions.resize(index + 1);
				@regions[index] = @region;
				++index;
			}
			else if(xml.getNodeType() == XN_Element_End && name == "rgns") {
				regionsInitialized = true;
				break;
			}
		}
	}		
		
	void createRegions() {
		float left = 0.0f, right = 0.0f, top = 0.0f, bottom = 0.0f;
		float width, height;
		
		float regionCount = getGameSetting("MAP_PIRATES_REGIONS",9.0f);
		
		Galaxy@ gal = getGalaxy();
		
		for(uint i = 0; i < gal.getSystemCount(); ++i) {
			vector pos = gal.getSystem(i).toObject().getPosition();
			
			if(pos.x < left) {
				left = pos.x;
			}
			
			if(pos.x > right) {
				right = pos.x;
			}
			
			if(pos.z < bottom) {
				bottom = pos.z;
			}
			
			if(pos.z > top) {
				top = pos.z;
			}
		}
		
		width = (right - left) / (regionCount / 3.0f);
		height = (top - bottom) / (regionCount / 3.0f);
		
		for(uint j = 0; j < uint(round(regionCount / 3.0f)); ++j) {
			for(uint k = 0; k < uint(round(regionCount / 3.0f)); ++k) {
				generateRegion(left + j * width, left + (j + 1) * width, bottom + k * height, bottom + (k + 1) * height); 
			}
		}
		
		regionsInitialized = true;
	}
	
	void generateRegion(float left, float right, float bottom, float top) {
		Galaxy@ gal = getGalaxy();
	
		uint n = regions.length();
		regions.resize(n+1);
		@regions[n] = Region(this);
		
	
		for(uint i = 0; i < gal.getSystemCount(); ++i) {
			System@ sys = gal.getSystem(i);
			vector pos = sys.toObject().getPosition();
			
			if(pos.x >= left && pos.x <= right && pos.z >= bottom && pos.z <= top) {
				regions[n].addSystemMonitor(sys);
			}
		}
	}
	
	ShipDesign@ getAffordableDesign(ResourceManager@ res) {
	}
};
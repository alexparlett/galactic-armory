#include "/include/empire_lib.as"

class RaidManager {
	
	RaidManager(Region@ region) {
	}
	
	RaidManager(Region@ region, XMLReader@ xml) {
	}
	
	void update(PirateAIData@ data, Region@ region, Empire@ emp, float time) {
	}
	
	void save(XMLWriter@ xml) {
	}	
};

class ResourceManager {
	
	float credits;
	float materials;
	
	ResourceManager(Region@ region) {
	}
	
	ResourceManager(Region@ region, XMLReader@ xml) {
	}	
	
	void update(Region@ region, Empire@ emp, float time) {
	}	
	
	void save(XMLWriter@ xml) {
	}
};

class SystemMonitor {

	System@ sys;
	
	float economicValue;
	float militaryStrength;
	int inhabitedPlanets;
	
	SystemMonitor(System@ sys) {
		this.sys = sys;
		
		economicValue = 0.0f;
		militaryStrength = 0.0f
		
		inhabitedPlanets = 0;
	}
	
	SystemMonitor(XMLReader@ xml) {
		uint uid = s_to_i(xml.getAttributeValue("uid"));
		@sys = getObjectByID(uid).toSystem();
		
		economicValue = s_to_f(xml.getAttributeValue("ec"));
		militaryStrength = s_to_f(xml.getAttributeValue("ml"));
		
		inhabitedPlanets = s_to_i(xml.getAttributeValue("in"));
	}
	
	void update() {
		inhabitedPlanets = 0;
		economicValue = 0.0f;
		militaryStrength = 0.0f;
		
		uint empCnt = getEmpireCount();
		for (uint i = 0; i < empCnt; ++i) {
			Empire@ emp = getEmpire(i);
			if (!emp.isValid() || emp.ID < 0) {
				continue;
			}

			inhabitedPlanets += sys.toObject().getPlanets(emp);
			economicValue += sys.toObject().getCivStrength(emp);
			militaryStrength += sys.toObject().getStrength(emp);
		}		
	}
	
	float getSystemValue() {
		return (economicValue / militaryStrength);
	}
	
	void save(XMLWriter@ xml) {
		xml.addElement("sys",true,"uid",i_to_s(sys.toObject().uid),"ec",f_to_s(economicValue),"ml",f_to_s(militaryStrength),"in",i_to_s(inhabitedPlanets));
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
		
		resMan = ResourceManager(this);
		raidMan = RaidManager(this);
		
		lastBaseTime = 0.0f;
		asteroidBase = -1;

		minTimeSinceLastBase = multiplier * 60.0f * 5.0f;
	}
	
	Region(PirateAIData@ data, XMLReader@ xml) {
		multiplier = data.multipler;
		
		lastBaseTime = 0.0f;
		asteroidBase = -1;
		
		minTimeSinceLastBase = multiplier * 60.0f * 60.0f;
		
		while(xml.advance()) {
			string@ name = xml.getNodeName();
			switch(xml.getNodeType()) {
				case XN_Element:
					if(name == "stms") {
						loadSystemMonitors(xml);
					}
					else if(name == "raid") {
						raidMan = RaidManager(this,xml);
					}
					else if(name == "res") {
						resMan = ResourceManager(this,xml);
					}
					else if(name == "base") {
						asteroidBase = s_to_i(xml.getAttributeValue("uid"));
						lastBaseTime = s_to_f(xml.getAttributeValue("time"));
					}
				break;
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
				@systems[index] = sysMon;
				++index;
			}
		}
	}
	

	void update(PirateAIData@ data, Empire@ emp, float time) {		
		for(uint i = 0; i < systems.length(); ++i) {
			systems[i].update();
		}
		
		resMan.update(this,emp,time);
		
		if(hasBaseSystem()) {
			if(objectExists(asteroidBase)) {
				raidMan.update(data,this,emp,time);
			}
			else {
				asteroidBase = -1;
				lastBaseTime = getGameTime();
			}
		}
		else
		{
			float timeSince = getGameTime() - lastBaseTime;
			if(timeSince > minTimeSinceLastBase) {
			}
		}
	}
	
	void save(XMLWriter@ xml) {
		xml.writeElement("rgn",false);
		
		if(systems.length() > 0) {
			xml.writeElement("stms",false);
			for(uint i = 0; i < systems.length(); ++i) {
				systems[i].save(xml);
			}
			xml.closeTag("stms");
		}
		
		raidMan.save(xml);
		resMan.save(xml);
		
		xml.writeElement("base",true,"uid",i_to_s(asteroidBase),"time",f_to_s(lastBaseTime));
		
		xml.closeTag("rgn");
	}
	
	void addSystemMonitor(System@ sys) {
		uint n = systems.length();
	
		systems.resize(n + 1);
		@systems[n] = SystemMonitor(sys);
	}	
	
	void createBaseSystem(Empire@ emp, System@ targ) {
	}
	
	bool hasBaseSystem() {
		return asteroidBase >= 0;
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
		
		resMan = ResearchManager(this);
	}

	PirateAIData(Empire@ emp, XMLReader@ xml) {
		regionsInitialized = false;
		multipler = getGameSetting("MAP_PIRATES_MULT",1.0f);	

		resMan = ResearchManager(this);
		
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
			if(xml.getNodeType() == XN_Element) {
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

	void save(XMLWriter@ xml) {
		xml.createHeader();
		
		if(shipDesigns.length() > 0) {
			xml.writeElement("dsgns",false);
			for(uint i = 0; i < shipDesigns.length(); ++i) {
				ShipDesign@ design = shipDesigns[i];
				xml.addElement("d", true, "n", design.className, "g", i_to_s(design.goalID));				
			}
			xml.closeTag("dsgns");
		}
		
		if(regions.length() > 0) {
			xml.writeElement("rgns",false);
			for(uint j = 0; j < regions.length(); ++j) {
				regions[j].save(xml);
			}
			xml.closeTag("rgns");
		}
	}
	
	void onDiplomaticMessage(Empire@ emp, Empire@ from, DiploMsg@ msg) {
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
};
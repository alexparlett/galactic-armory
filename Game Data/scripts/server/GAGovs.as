//Globals
ObjectFlag objImprovement = objUser03, setImpPause = objSetting00;
float upTime, lastUpdate = 0.f, lastReq = 0.f;
bool initialized;

//Constants
const string@ strWorkers = "Workers", strTrade = "Trade";
const string@ strFuel = "Fuel", strAmmo = "Ammo", strFood = "Food";
const string@ strMtl = "Metals", strElc = "Electronics", strAdv = "AdvParts";

const float mil = 1000000.0f;
const subSystemDef@ city = null;
const subSystemDef@ port = null;
const subSystemDef@ capitol = null;
const subSystemDef@ GC = null;
const subSystemDef@ yard = null;

void init() {
	@city = getSubSystemDefByName("City");
	@port = getSubSystemDefByName("SpacePort");
	@capitol = getSubSystemDefByName("Capital");
	@GC = getSubSystemDefByName("GalacticCapital");	
	@yard = getSubSystemDefByName("ShipYard");
	
	initialized = true;
	
	print("Governors Initialized");
}

/*
 * This function checks that a planet isnt building improvements
 * before it will allow the build queue to continue
 */
bool setGov(Planet@ pl)
{
	Object@ obj = pl;
	
	//Init the subsystems.
	if(!initialized)
		init();
	
	//Don't allow gov to run when planets are building improvements
	if(obj.getFlag(objImprovement) && !obj.getFlag(setImpPause))
		return true;

	return false;
}

/*
 * This function checks the worker levels of a planet
 * and adjusts the number of cities as needed
 */
bool checkWorkers(Planet@ pl)
{
	Object@ obj = pl;
	State@ workers = obj.getState(strWorkers);
	float wmax = pl.getMaxPopulation();
	
	PlanetStructureList list;
	list.prepare(pl);	
	
	uint slots = pl.getStructureCount(), structs = list.getCount();		
	
	if(wmax - workers.required < 12.f * mil)
	{
		for(uint i = 0; i < list.getCount(); i++)
		{	
			const subSystemDef@ def = list.getStructure(i).type;
			
			if(structs < slots) 
			{
				pl.buildStructure(city);
				return true;
			}
			else
			{
				if(def is port || def is yard || def is city || def is capitol || def is GC || list.getCount(def) <= 1)
					continue;
					
				pl.removeStructure(i);
				pl.buildStructure(city);
				return true;
			}
		}
	}	
	return false;
}

/*
 * This function checks the trade amount of a planet
 * and adjusts the number of ports as needed
 */
bool checkTrade(Planet@ pl)
{
	Object@ obj = pl;
	Empire@ emp = obj.getOwner();
	State@ trade = obj.getState(strTrade);	

	PlanetStructureList list;
	list.prepare(pl);	
	
	bool maxed = false;
	if(gameTime - lastUpdate > 5.f || gameTime <= 30) {
		//Work off an average of the last update and this one
		float req = (trade.inCargo + lastReq) / 2;
		
		//Error checking incase it hits halfway through a planet update
		if(req > trade.max * 10)
			return false;
			
		if(req >= trade.max)
			maxed = true;
			
		lastUpdate = gameTime;
		lastReq = req;
	}
	
	uint slots = pl.getStructureCount(), structs = list.getCount();		
	
	for(uint i = 0; i < list.getCount(); i++)
	{	
		const subSystem@ sys = list.getStructure(i);
		const subSystemDef@ def = sys.type;
		
		// Only continues if the planet is using its maximum trade capability for the last 10 seconds.
		// This will not be completely accurate as if a planet is importing the rate will be maxed
		// Need to find a way around this.
		if(maxed) {
			if(structs < slots) 
			{
				pl.buildStructure(port);
				return true;
			}
			else
			{
				if(def is port || def is yard || def is city || def is capitol || def is GC || list.getCount(def) <= 1)
					continue;
					
				pl.removeStructure(i);
				pl.buildStructure(port);
				return true;
			}
		}
	}
	
	return false;
}
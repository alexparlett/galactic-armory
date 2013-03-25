//Slight Bend
//============
//Creates a line of planets with a bend at one end
//No Dust

#include "/include/map_lib.as"

void makeMap(Galaxy@ Glx) {
	prepMap();
	
	uint sysCount = getGameSetting("SYSTEM_COUNT",150);
	float rad, theta, Xxx, Yyy;
	float maxRad = sqrt(sysCount) * getGameSetting("MAP_SYSTEM_SPACING", 3000.f) * orbitRadiusFactor / 70.f; //Magic number = old base setting
	float maxHgt = maxRad / 4.f;
	if(getGameSetting("MAP_FLATTEN", 0) == 1)
		maxHgt = 0;
	setMakeOddities(getGameSetting("MAP_ODDITIES", 1.f) != 0.f);
	
	float minRad = 250.f;
	
	uint sysIndex = 0;
	for(; sysIndex < sysCount; ++sysIndex) {
		theta = randomf(twoPi);
		rad = range(minRad, maxRad, pow(randomf(1.f),0.85f));
   
		//MAIN KEY.  Determines location of a base star.
	     if(sysIndex < (sysCount / 2))
		Xxx = pow(5.f - (rad/maxRad), 2.f) * maxHgt;     
             else
		Xxx = pow(-5.f - (rad/maxRad), 2.f) * -maxHgt;

	     if(sysIndex < (sysCount / 2))
		Yyy = pow(5.f - (rad/maxRad), 2.f) * maxHgt / randomf(rad, maxRad);     
             else
		Yyy = -pow(5.f - (rad/maxRad), 2.f) * maxHgt;

		vector position(Xxx, Yyy, 0);
		
		System@ sys = makeRandomSystem(Glx, position, sysIndex, sysCount);

		updateProgress(sysIndex, sysCount);
	}
	
	if(jumpBridges && sysCount >= 20)
	{
		float density = getGameSetting("MAP_BRIDGE_DENSITY", 0.1f);
		float availableGates = float(sysCount) * density;
		float gateIndex = 0;
		
		while(gateIndex < availableGates)
		{
			if(makeGateSystem(Glx))
				gateIndex++;
			updateBridgeProgress(gateIndex,availableGates);
		}
	}
}

Planet@ setupHomeworld(System@ sys, Empire@ owner) {
	return setupStandardHomeworld(sys, owner);
}
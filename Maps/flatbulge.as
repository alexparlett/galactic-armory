//flatbulge
//============
//a line of stars with a bulge in the middle
//No Dust

#include "/include/map_lib.as"

void makeMap(Galaxy@ Glx) {
	prepMap();
	
	uint sysCount = getGameSetting("SYSTEM_COUNT",150);
	float rad, theta;
	float maxRad = sqrt(sysCount) * getGameSetting("MAP_SYSTEM_SPACING", 3000.f) * orbitRadiusFactor / 70.f; //Magic number = old base setting
	float maxHgt = maxRad / 4.f;
	if(getGameSetting("MAP_FLATTEN", 0) == 1)
		maxHgt = 0;
	setMakeOddities(getGameSetting("MAP_ODDITIES", 1.f) != 0.f);
	
	float minRad = 250.f;

	uint sysIndex = 0;
	float xxx, yyy, zzz, side;
	for(; sysIndex < sysCount; ++sysIndex) {
		theta = randomf(twoPi);
		rad = range(minRad, maxRad, pow(randomf(1.f),0.85f));
		side = randomf(-1.f, 1.f);
		//MAIN KEY.  Determines location of a base star.
		if(sysIndex < (sysCount / 2))
			xxx = (getGameSetting("MAP_SYSTEM_SPACING", 3000.f) + rad) * side;
		else
			xxx = ((1000.f+sysIndex)^2.f) + (getGameSetting("MAP_SYSTEM_SPACING", 3000.f));
			
		if(sysIndex < (sysCount / 2))
			yyy = (getGameSetting("MAP_SYSTEM_SPACING", 3000.f) + rad) * side;
		else
			yyy = ((1000.f+sysIndex)^2.f) + (getGameSetting("MAP_SYSTEM_SPACING", 3000.f));
			
		zzz = (rad/minRad + (getGameSetting("MAP_SYSTEM_SPACING", 3000.f))) * side;
		vector position(xxx, yyy, zzz);
		
		System@ sys = makeRandomSystem(Glx, position, sysIndex, sysCount);
		if(sys.hasTag("JumpSystem"))
			sysIndex -= 1;
		updateProgress(sysIndex, sysCount);	
	}
}

Planet@ setupHomeworld(System@ sys, Empire@ owner) {
	return setupStandardHomeworld(sys, owner);
}
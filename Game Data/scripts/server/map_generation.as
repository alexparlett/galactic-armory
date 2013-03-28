#include "/include/mickleroi_real_systems_map_generation.as"
#include "/include/vanilla_map_generation.as"

// {{{ Imports
import void initSpecialSystems() from "special_systems";
import System@ makeSpecialSystem(Galaxy@, vector) from "special_systems";
import System@ makeUnstableStar(Galaxy@ Glx, vector pos) from "special_systems";
import System@ makeNeutronStar(Galaxy@ Glx, vector pos) from "special_systems";
// }}}

// Strings
string@ strOre = "Ore", strDmg = "Damage", strMoonEx = "moon", strRingEx = "natural_ring", strComet = "comet", strAsteroid = "asteroid", strHydrogen = "hydrogen";
string@ strOrbPitch = "orb_disc_pitch", strOrbEcc = "orb_eccentricity", strOrbDays = "orb_days_per_year", strOrbRad = "orb_radius", strOrbMass = "orb_mass";
string@ strOrbPosInYear = "orb_year_pos", strOrbYaw = "orb_disc_yaw", strMass = "mass", strTerraform = "Terraform";
string@ strRadius = "radius";
string@ strLivable = "Livable";
string@ strH3 = "H3";

// Mathematical
const float Pi    = 3.14159265f;
const float twoPi = 6.28318531f;
uint gateSystems = 0;

// Descriptors
Oddity_Desc comet_desc, asteroid_desc;
Planet_Desc plDesc;
System_Desc sysDesc;
Star_Desc starDesc;
Orbit_Desc orbDesc;

int[] ColdTypes;
int[] NormalTypes;
int[] WarmTypes;
int[] LavaTypes;
int[] GasTypes;

void setOrbitDesc(Orbit_Desc& orb) {
	orbDesc.set(orb);
}

void initPlanetType(int[]& arr, string@ tag) {
	uint cnt = getPlanetTypeCount();
	for (uint i = 0; i < cnt; ++i) {
		const PlanetType@ tp = getPlanetType(i);
		if (tp.hasTag(tag)) {
			uint n = arr.length();
			arr.resize(n+1);
			arr[n] = tp.id;
		}
	}
}

int getRandomType(int[]& arr) {
	return arr[rand(0, arr.length() - 1)];
}

void initPlanetTypes() {
	initPlanetType(ColdTypes, "ice");
	initPlanetType(NormalTypes, "terran");
	initPlanetType(WarmTypes, "desert");
	initPlanetType(LavaTypes, "lava");
	initPlanetType(GasTypes, "gas");
}

void setMakeOddities(bool make) {
	RS_setMakeOddities(make);
}

bool getMakeOddities() {
	return RS_getMakeOddities();
}

float getOrbitRadiusFactor() { 
	return RS_getOrbitRadiusFactor();
}

void initMapGeneration() {
	RS_initMapGeneration();

	print("Map Generation Initialized");	
}

float range(float low, float high, float pct) {
	return RS_range(low, high, pct);
}

float pctBetween(float x, float low, float hi) {
	return RS_pctBetween(x, low, hi);
}

void addStruct(uint count, string@ name, Planet@ pl) {
	RS_addStruct(count, name, pl);
}

set_int disregardPlanets;
Planet@ getRandomPlanet(System@ sys) {
	return RS_getRandomPlanet(sys);
}

Planet@ makeRandomPlanet(System@ sys, uint plNum, uint plCount) {
	return RS_makeRandomPlanet(sys, plNum, plCount);
}

Planet@ setupStandardHomeworld(System@ sys, Empire@ emp) {
	return RS_setupStandardHomeworld(sys, emp);
}

void createSecondaryPlanet(System@ sys, Empire@ emp) {
	RS_createSecondaryPlanet(sys, emp);
}

Planet@ makeStandardPlanet(System@ sys, uint plNum, uint plCount) {
	return RS_makeStandardPlanet(sys, plNum, plCount);
}

void makeRandomComet(System@ sys) {
	RS_makeRandomComet(sys);
}

void makeRandomAsteroid(System@ sys, uint rocks) {
	RS_makeRandomAsteroid(sys, rocks);
}

System@ makeRandomSystem(Galaxy@ Glx, vector position, uint sysNum, uint sysCount) {
	return RS_makeRandomSystem(Glx, position, sysNum, sysCount);
}

System@ makeStandardSystem(Galaxy@ glx, vector pos) {
	return RS_makeStandardSystem(glx, pos);
}

System@ makeBinarySystem(Galaxy@ glx, vector pos) {
	return RS_makeBinarySystem(glx, pos);
}

System@ makeAsteroidBelt(Galaxy@ glx, vector pos) {
	return RS_makeAsteroidBelt(glx, pos);
}

System@ makeSupernova(Galaxy@ glx, vector pos) {
	return RS_makeSupernova(glx, pos);
}

float makeQuasar(Galaxy@ glx, vector pos, float sizeFactor) {
	return RS_makeQuasar(glx, pos, sizeFactor);
}


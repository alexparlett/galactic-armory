Planet_Desc plDesc;
Orbit_Desc orbDesc;
Star_Desc starDesc;
System_Desc sysDesc;

import Planet@ makeRandomPlanet(System@,uint,uint) from "map_generation";
import void makeRandomComet(System@) from "map_generation";
import void makeRandomAsteroid(System@, uint) from "map_generation";
import bool getMakeOddities() from "map_generation";
import void setOrbitDesc(Orbit_Desc&) from "map_generation";


const float starMassFactor = 1.f / 11000.f;
const float orbitRadiusFactor = 300.f;
const float starSizeFactor = 2.5f;
const float planetSlotRadius = 0.75f;
const float planetSlotOre = 6.f;
const float planetSlotHP = 0.7f * 1000.f;

const string@ strOre = "Ore", strDmg = "Damage", strH3 = "H3";
const string@ strLivable = "Livable", strTerraform = "Terraform";
const string@ strAIAvoid = "AIAvoid";

Planet@ makePlanet(System@ sys, int slots, int conditions, float orbit) {
	orbDesc.Radius = orbit;


	plDesc.setOrbit(orbDesc);
	plDesc.PlanetRadius = planetSlotRadius * float(slots);
	plDesc.RandomConditions = false;

	Planet@ pl = sys.makePlanet(plDesc);
	Object@ obj = pl;
	
	if (pl.getPhysicalType().beginsWith("gas")) 
	{
		State@ h3 = obj.getState(strH3);
		h3.max = starDesc.Temperature * randomf(100000,200000);
		h3.val = h3.max * (0.5f + (randomf(0.5f)));				
	}		

	// Set the structure slots
	pl.setStructureSpace(float(slots));


	// Add random conditions
	if (randomf(1.f) < 0.6f)
		pl.addPositiveCondition();
	else
		pl.addNegativeCondition();

	if (randomf(1.f) < 0.5f) {
		if (randomf(1.f) < 0.6f)
			pl.addPositiveCondition();
		else
			pl.addNegativeCondition();
	}
	
	if (randomf(1.f) < 0.5f) {
		if (randomf(1.f) < 0.6f)
			pl.addPositiveCondition();
		else
			pl.addNegativeCondition();
	}	

		// Give the planet ore
	State@ ore = obj.getState(strOre);
	ore.max = planetSlotOre * pow(float(slots) * 10.f, 3);
	ore.val = ore.max * (0.5f + randomf(0.5f));
	
	// Give the planet HP
	obj.getState(strDmg).max = pow(float(slots) * 10.f, 3) * planetSlotHP;

	Effect starEffect("SelfHealing");
	starEffect.set("Rate", 5000000.f);	
	pl.toObject().addTimedEffect(starEffect, pow(10, 35), 0.f, pl.toObject(), null, null, TEF_None);	

	Effect planetEffect("PlanetRegen");
	pl.toObject().addTimedEffect(planetEffect, pow(10, 35), 0.f, pl.toObject(), null, null, TEF_None);	
	
	float terslots = pl.getMaxStructureCount();	
	State@ terSlots = obj.getState(strTerraform);
	if(terslots >= 30) {
		terSlots.max = rand(2, 6);
		terSlots.val = terSlots.max;
	}
	else if(terslots >= 20) {
		terSlots.max = rand(6, 10);
		terSlots.val = terSlots.max;
	}
	else {
		terSlots.max = rand(10, 14);
		terSlots.val = terSlots.max;
	}		
	
	return pl;
}

Star@ makeStar(System@ sys, float starSize) {
	starDesc.Temperature = randomf(2000,60000);
	starDesc.Brightness = 5;
	starDesc.Radius = randomf(30.f + (starDesc.Temperature / 1000.f),
						60.f + (starDesc.Temperature / 600.f))
						* starSizeFactor * starSize;
	starDesc.Brightness = 1;

	orbDesc.Offset = vector(0, 0, 0);
	orbDesc.IsStatic = true;
	orbDesc.PosInYear = -1.f;
	orbDesc.setCenter(null);
	starDesc.setOrbit(orbDesc);

	orbDesc.IsStatic = false;
	orbDesc.MassRadius = starDesc.Radius;
	orbDesc.Mass = starDesc.Radius * starMassFactor;

	Star@ star = sys.makeStar(starDesc);
	Object@ obj = star.toObject();

	Effect starEffect("SelfHealing");
	starEffect.set("Rate", 100000000000.f);	
	star.toObject().addTimedEffect(starEffect, pow(10, 35), 0.f, star.toObject(), null, null, TEF_None);

	return star;
}

System@ makeSystem(Galaxy@ Glx, vector pos, float radius) {
	sysDesc.StartRadius = radius;
	sysDesc.Position = pos;
	sysDesc.AutoStar = false;

	return Glx.createSystem(sysDesc);
}

vector makeRandomVector(float radius) {
	float theta = randomf(6.28318531f);
	return vector(radius * cos(theta), 0, radius * sin(theta));
}

void makePlanets(System@ sys, float orbit, int planets) {
	orbDesc.Radius = orbit;

	for (int i = 0; i < planets; ++i) {
		orbDesc.Radius += randomf(1.f, 2.5f) * orbitRadiusFactor;
		orbDesc.Eccentricity = randomf(0.5f, 1.5f);
		
		setOrbitDesc(orbDesc);
		makeRandomPlanet(sys, i, planets);
	}

	// Add oddities to system
	if(getMakeOddities()) {
		int comets = 1;
		while (randomf(1.f) < (0.60f / comets)) {
			makeRandomComet(sys);
			++comets;
		}
		
		int belts = 0;
		while (randomf(1.f) < 1.f / (belts + 3.f) && belts < planets) {
			makeRandomAsteroid(sys, rand(20,50));
			++belts;
		}
	}
}
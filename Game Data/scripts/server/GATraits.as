const string@ strCargo = "vCargoStore", strMineRate = "vMineRate", strElecFabRate = "vElecFab";
const string@ strEcoStore = "vEcoStore";
const string@ strAdvFabRate = "vAdvFab", strGoodsFabRate = "vGoodsFab", strLuxFabRate = "vLuxFab";
const string@ strFoodGen = "vFoodGen";
const string@ strFabRate = "vFabRate";  // variable of ship subsystems Refinery, ElectsFab, AdvAssembler
const string@ strCapMRate = "vCapitalMetalRate", strCapERate = "vCapitalElecRate";
const string@ strCapARate = "vCapitalAvdPartsRate", strCapFRate = "vCapitalFoodRate";
const string@ strCrewRepair = "vCrewRegen", strRepair = "vRepair", strRemoteRepair = "vRemoteRep";
const string@ strLaborGen = "vLabor", strLaborPool = "vLaborPool", strLabor = "Labr";
const string@ strOneSpace = "vOneSpace", strSize = "Size";
const string@ strMetals = "Metals", strElects = "Electronics", strAdvParts = "AdvParts";
const string@ strFood = "Food", strGoods = "Guds", strLuxuries = "Luxs";
const string@ strMetal = "vMetal", strElect = "vElec", strAdvPart = "vParts";
const string@ strDurability = "Durability", strShielding = "vShielding", strArmor = "Armor", strHull = "Hull";
const string@ strDamage = "vDamage", strRange = "vRange";
const string@ strAmmo = "vAmmoUse", strEfficiency = "vEfficiency", strThrust = "vThrust";
const string@ strStructs = "vStructures";
const string@ strResearch = "Research", strStructure = "Structure";
const string@ strMass = "Mass";
const string@ strDefense = "Defense", strWeapon = "Weapon", strSpecWeap = "SpecWeapon", strECM = "ECM";
/* Trait subsystem alterations */

//Unique Trait for cannonFodder, implemented this way as we cant use name and SubSysEvalMode in the same function
void cannonFodder (subSystem@ subSys, const string@ name, float Factor) {
	if (name == strDurability && (subSys.type.hasTag(strHull) || subSys.type.hasTag(strArmor)))
		subSys.setVariable(strDurability, subSys.getVariable(strDurability) * Factor);
	if (name ==  strShielding)
		subSys.setVariable(strShielding, subSys.getVariable(strShielding) * Factor);
	if (name == strMetal && (subSys.type.hasTag(strHull) || subSys.type.hasTag(strArmor)))
		subSys.setVariable(strMetal, subSys.getVariable(strMetals) * Factor);
	if (name == strElect && (subSys.type.hasTag(strHull) || subSys.type.hasTag(strArmor)))	
		subSys.setVariable(strElect, subSys.getVariable(strElects) * Factor);
	if (name == strAdvPart && (subSys.type.hasTag(strHull) || subSys.type.hasTag(strArmor)))	
		subSys.setVariable(strAdvPart, subSys.getVariable(strAdvParts) * Factor);	
}

//Changes the fuel (needs to have vThrust variable otherwise would effect
// efficency of other modules) and ammo usage of a subsystem can be reused
void resourceUsage (subSystem@ subSys, const string@ name, float Factor) {
	if (name == strAmmo)
		subSys.setVariable(strAmmo, subSys.getVariable(strAmmo) * Factor);	
	if (name == strEfficiency && subSys.hasVariable(strThrust))
		subSys.setVariable(strEfficiency, subSys.getVariable(strEfficiency) * Factor);
}

//Increases the amount of structures by a flat amount can be reused
void alterStructures (subSystem@ subSys, const string@ name, float Factor) {
	if (name == strStructs)
		subSys.setVariable(strStructs, subSys.getVariable(strStructs) * Factor);
}

//Lowers the build cost of all things with a Research tag
void alterBuildCost (subSystem@ subSys, SubSystemEvalMode mode, float Factor) {
	if (mode == SSVM_Costs && subSys.type.hasTag(strResearch)) {
		uint cnt = subSys.getCostCount();
		for (uint i = 0; i < cnt; ++i)
			subSys.setCost(i, subSys.getCost(i) * Factor);
	}
}

const string@ strResRate = "vResRate";
void increaseResearch (subSystem@ subSys, const string@ name, float Factor) {
	if(name == strResRate)
		subSys.setVariable(strResRate, subSys.getVariable(strResRate) * Factor);
}

//Increases the damage of all weapons !! Would be easier if they used a unified damage variable!!
void alterDamage (subSystem@ subSys, const string@ name, float Factor) {
	if(name == strDamage && (!subSys.type.hasTag(strDefense) && !subSys.type.hasTag(strECM) && (subSys.type.hasTag(strWeapon) || subSys.type.hasTag(strSpecWeap))))
		subSys.setVariable(strDamage, subSys.getVariable(strDamage) * Factor);
}

//Changes the damage of all weapons with a Structure tag
void planetDamage (subSystem@ subSys, const string@ name, float Factor) {
	if (name == strDamage && subSys.type.hasTag(strStructure))
		subSys.setVariable(strDamage, subSys.getVariable(strDamage) * Factor);		
}

//Changes the mass by Factor
void lowerMass (subSystem@ subSys, const string@ name, float Factor) {
	if (name == strMass)
		subSys.setVariable(strMass, subSys.getVariable(strMass) * Factor);
}

//Changes Mass and HP  for all sub systems with Hull or Armor tag
void ultraDense (subSystem@ subSys, const string@ name, float HP, float Mass) {
	if(name == strMass && (subSys.type.hasTag(strHull) || subSys.type.hasTag(strArmor)))
		subSys.setVariable(strMass, subSys.getVariable(strMass) * Mass);
	if(name == strDurability && subSys.type.hasTag(strHull) || subSys.type.hasTag(strArmor))
		subSys.setVariable(strDurability, subSys.getVariable(strDurability) * HP);
}

//Changes Range for all sub systems with Weapon or SpecWeap tag
void increaseRange (subSystem@ subSys, const string@ name, float Factor) {
	if(name == strRange && !subSys.type.hasTag(strDefense) && !subSys.type.hasTag(strECM) && subSys.type.hasTag(strWeapon))
		subSys.setVariable(strRange, subSys.getVariable(strRange) * Factor);
}

//Changes vAoE_Damage for all subsystems with a Weapon tag.
const string@ strWMD = "WMD";
void mwdDamage (subSystem@ subSys, const string@ name, float Factor) {
	if(name == strDamage && subSys.type.hasTag(strWMD))
		subSys.setVariable(strDamage, subSys.getVariable(strDamage) * Factor);
}

//Changes Energy Damage for specific variables or weapons using BeamEnergyWeapon tag
const string@ strBeamEnergy = "BeamEnergyWeapon", strEnergyWeapon = "EnergyWeapon";
void increaseEnergyDamage (subSystem@ subSys, const string@ name, float Factor) {
	if (name == strDamage && (subSys.type.hasTag(strBeamEnergy) || subSys.type.hasTag(strEnergyWeapon)))
		subSys.setVariable(strDamage, subSys.getVariable(strDamage) * Factor);		
}

//Changes Damage for Weapons with the Tag Laser.
const string@ strLaser = "Laser";
void improveEnergyWeapons (subSystem@ subSys, const string@ name, float Range, float Damage) {
	if (name == strDamage && subSys.type.hasTag(strLaser))
		subSys.setVariable(strDamage, subSys.getVariable(strDamage) * Damage);
	if (name == strRange && subSys.type.hasTag(strLaser))
		subSys.setVariable(strRange, subSys.getVariable(strRange) * Range);
}

//Changes Damage for Weapons using vMissileDamage or vTorpDamage
const string@ strMissWeap = "MissileWeapon", strWarheadWeapon = "WarheadWeapon";
void increaseMissileDamage (subSystem@ subSys, const string@ name, float Factor) {
	if (name == strDamage && (subSys.type.hasTag(strMissWeap) || subSys.type.hasTag(strWarheadWeapon)))
		subSys.setVariable(strDamage, subSys.getVariable(strDamage) * Factor);
}

//Changes Damage for Weapons using vTorpDamage and Range for weapons with a Torpedo Tag.
const string@ strTorpedo = "Torpedo";
void improveTorpedos (subSystem@ subSys, const string@ name, float Range, float Damage) {
	if (name == strDamage && subSys.type.hasTag(strTorpedo))
		subSys.setVariable(strDamage, subSys.getVariable(strDamage) * Range);
	if (name == strRange && subSys.type.hasTag(strTorpedo))
		subSys.setVariable(strRange, subSys.getVariable(strRange) * Range);
}

//Changes Damage for Weapons with a ProjWeapon tag
const string@ strProjWeap = "ProjWeapon", strProjectileWeapon = "ProjectileWeapon", strRoid = "Roid";
void increaseBallisticDamage (subSystem@ subSys, const string@ name, float Factor) {
	if ((name == strDamage && (subSys.type.hasTag(strProjWeap) || subSys.type.hasTag(strProjectileWeapon))) && !subSys.type.hasTag(strRoid))
		subSys.setVariable(strDamage, subSys.getVariable(strDamage) * Factor);
}

//Changes Range and Damage for weapons with a Railgun Tag
const string@ strRailgun = "Railgun";
void improveBallistics (subSystem@ subSys, const string@ name, float Range, float Damage) {
	if (name == strDamage && subSys.type.hasTag(strRailgun))
		subSys.setVariable(strDamage, subSys.getVariable(strDamage) * Damage);
	if (name == strRange && subSys.type.hasTag(strRailgun))
		subSys.setVariable(strRange, subSys.getVariable(strRange) * Range);	
}

//Changes Effectivity and AOEDamage for weapon with a Defense Tag
const string@ strEffectivity = "vEffectivity", strPDWeap = "PDWeap";
void improvePointDefense (subSystem@ subSys, const string@ name, float Efficiency, float Damage) {
	if (name == strEffectivity && (subSys.type.hasTag(strDefense) || subSys.type.hasTag(strPDWeap)))
		subSys.setVariable(strEffectivity, subSys.getVariable(strEffectivity) * Efficiency);
	if (name == strDamage && (subSys.type.hasTag(strDefense) || subSys.type.hasTag(strPDWeap)))
		subSys.setVariable(strDamage, subSys.getVariable(strDamage) * Damage);
}

//Changes Damage for weapons using vBombDamage
const string@ strBomb = "Bomb";
void increaseBombDamage (subSystem@ subSys, const string@ name, float Factor) {
	if (name == strDamage && subSys.type.hasTag(strBomb))
		subSys.setVariable(strDamage, subSys.getVariable(strDamage) * Factor);
}

const string@ strDR = "vDR";
void alterDR (subSystem@ subSys, const string@ name, float Factor) {
	if(name == strDR && subSys.type.hasTag(strStructure))
		subSys.setVariable(strDR, subSys.getVariable(strDR) * Factor);
}

void increaseProduction (subSystem@ subSys, const string@ name, float Factor) {
	if (name == strMineRate)
		subSys.setVariable(strMineRate, subSys.getVariable(strMineRate) * Factor);
	if (name == strElecFabRate)
		subSys.setVariable(strElecFabRate, subSys.getVariable(strElecFabRate) * Factor);
	if (name == strAdvFabRate)
		subSys.setVariable(strAdvFabRate, subSys.getVariable(strAdvFabRate) * Factor);
	if (name == strFoodGen)
		subSys.setVariable(strFoodGen, subSys.getVariable(strFoodGen) * Factor);
		
	// variable of ship subsystems Refinery, ElectsFab, AdvAssembler
	if (name == strFabRate)											
		subSys.setVariable(strFabRate, subSys.getVariable(strFabRate) * Factor);
		
	//Capital Production
	if (name == strCapMRate)
		subSys.setVariable(strCapMRate, subSys.getVariable(strCapMRate) * Factor);
	if (name == strCapERate)
		subSys.setVariable(strCapERate, subSys.getVariable(strCapERate) * Factor);
	if (name == strCapARate)
		subSys.setVariable(strCapARate, subSys.getVariable(strCapARate) * Factor);
	if (name == strCapFRate)
		subSys.setVariable(strCapFRate, subSys.getVariable(strCapFRate) * Factor);
}

/* Traits that apply once */

import void LevelTech (Empire@ emp, string@ techName, float Level) from "Traits";

void levelComputers(Empire@ emp, float Level) {
	LevelTech(emp, "Computers", Level);
}

void levelEnergyWeapons(Empire@ emp, float Level) {
	LevelTech(emp, "BeamWeapons", Level);
}

void levelMissileWeapons(Empire@ emp, float Level) {
	LevelTech(emp, "Missiles", Level);
}

void levelProjectileWeapons(Empire@ emp, float Level) {
	LevelTech(emp, "ProjWeapons", Level);
}

/* Trait ticks */

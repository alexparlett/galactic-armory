string@ str_vShieldReg = "vShieldReg", str_vRegCost = "vRegCost", str_vAbsorption = "vAbsorption";
string@ str_vDamage = "vDamage";
string@ str_vRange = "vRange", str_vDelay = "vDelay", strMaxHP = "Durability";
string@ str_ClipSize = "vClip", str_vAmmoUse = "vAmmoUse", str_WasteHeat = "vWasteHeat", str_vPowCost = "vPowCost";
string@ strNoModifiers = "NoModifiers", strECM = "ECM";

import float rangeFactor(float factor, float sensorSize, float gunSize) from "subSysAlterations";
import float interp(float From, float To, float pct) from "subSysAlterations";

//Increases all types of cargos
string@ str_vCargo1 = "vFuelStore", str_vCargo2 = "vAmmoStore", str_vCargo3 = "vCargoStore", str_vCargo4 = "vEcoStore";
void increaseCargoSpace(subSystem@ subSys, const string@ name, float CompressorSize, float ImprovementFactor) {
	const string@ cargoVar = null;
	for(uint i = 0; i < 4; ++i) {
		switch(i) {
			case 0: @cargoVar = @str_vCargo1; break;
			case 1: @cargoVar = @str_vCargo2; break;
			case 2: @cargoVar = @str_vCargo3; break;
			case 3: @cargoVar = @str_vCargo4; break;
		}
		
		if(name == cargoVar) {
			float cargo = subSys.getVariable(cargoVar);
			if(cargo > 0)
				subSys.setVariable(cargoVar, cargo * interp(1, ImprovementFactor, CompressorSize / subSys.size));
			break; //No need to test further names this step
		}
	}
}

void decreaseShieldAbsorptionAndIncreaseRegenAndCost(subSystem@ subSys, const string@ name, float DecreaseAbsorption, float IncreaseRegen, float IncreaseCost) {
	if(!subSys.type.hasTag(strNoModifiers)) {
		if(name == str_vAbsorption) {
			float absorb = subSys.getVariable(str_vAbsorption);
			if(absorb > 0)
				if(absorb - DecreaseAbsorption >= 0)
					subSys.setVariable(str_vAbsorption, absorb - DecreaseAbsorption);
				else 
					subSys.setVariable(str_vAbsorption, 0);
		}
		else if(name == str_vRegCost) {
			float cost = subSys.getVariable(str_vRegCost);
			if(cost > 0)
				subSys.setVariable(str_vRegCost, cost + IncreaseCost);
		}
		else if(name == str_vShieldReg) {
			float regen = subSys.getVariable(str_vShieldReg);
			if(regen > 0)
				subSys.setVariable(str_vShieldReg, regen + IncreaseRegen);
		}
	}
}

void improveAll(subSystem@ subSys, const string@ name, float SourceSize, float Factor, float delFactor, float Amount, float damagemod, float ammoUseMod, float powCostMod, float wasteHeatMod) {
	if(!subSys.type.hasTag(strNoModifiers) && !subSys.type.hasTag(strECM)) {
		if(name == str_vRange) {
			float range = subSys.getVariable(str_vRange);
		if(range > 0)
			subSys.setVariable(str_vRange, range * Factor);
		}
		else if(name == str_vDelay) {
			float fireDelay = subSys.getVariable(str_vDelay);
		if(fireDelay > 0)
			subSys.setVariable(str_vDelay, fireDelay * delFactor);
		}
		else if(name == strMaxHP){
			subSys.setVariable(strMaxHP, subSys.getVariable(strMaxHP) + Amount);
		}
		else if(name == str_vDamage) {
			float dmg = subSys.getVariable(str_vDamage);
			dmg *= damagemod;
			subSys.setVariable(str_vDamage, dmg);
		}
		else if(name == str_vAmmoUse) {
			float ammoUse = subSys.getVariable(str_vAmmoUse);
			ammoUse *= ammoUseMod;
			subSys.setVariable(str_vAmmoUse, ammoUse);
		}
		else if(name == str_WasteHeat) {
			float wasteHeat = subSys.getVariable(str_WasteHeat);
			wasteHeat *= wasteHeatMod;
			subSys.setVariable(str_WasteHeat, wasteHeat);
		}
		else if(name == str_vPowCost) {
			float powCost = subSys.getVariable(str_vPowCost);
			powCost *= powCostMod;
			subSys.setVariable(str_vPowCost, powCost);
		}
	}	
}

void improveAllRange(subSystem@ subSys, const string@ name, float SourceSize, float Factor) {
	if(!subSys.type.hasTag(strNoModifiers)) {
	   if(name == str_vRange) {
		  float range = subSys.getVariable(str_vRange);
		  if(range > 0)
			 subSys.setVariable(str_vRange, range * rangeFactor(Factor, SourceSize, subSys.size));
	   }
	}  
}

void alterDamage(subSystem@ subSys, const string@ name, float damagemod, float ammoUseMod, float powCostMod, float wasteHeatMod) {
 	if(!subSys.type.hasTag(strNoModifiers) && !subSys.type.hasTag(strECM)) {
		if(name == str_vDamage) {
		  float dmg = subSys.getVariable(str_vDamage);
		  dmg *= damagemod;
		  subSys.setVariable(str_vDamage, dmg);
	   }
	   else if(name == str_vAmmoUse) {
		  float ammoUse = subSys.getVariable(str_vAmmoUse);
		  ammoUse *= ammoUseMod;
		  subSys.setVariable(str_vAmmoUse, ammoUse);
	   }
	   else if(name == str_WasteHeat) {
		  float wasteHeat = subSys.getVariable(str_WasteHeat);
		  wasteHeat *= wasteHeatMod;
		  subSys.setVariable(str_WasteHeat, wasteHeat);
	   }
	   else if(name == str_vPowCost) {
		  float powCost = subSys.getVariable(str_vPowCost);
		  powCost *= powCostMod;
		  subSys.setVariable(str_vPowCost, powCost);
	   }
	}  
}

string@ strExtendable = "Extendable";
void alterClipSize(subSystem@ subSys, const string@ name, float clipmulti) {
	if(subSys.type.hasTag(strExtendable)) {
	    if(name == str_ClipSize) {
		   float clipsize = subSys.getVariable(str_ClipSize);
		   clipsize *= clipmulti;
		   subSys.setVariable(str_ClipSize, clipsize);
	    }
	}	
}

const float minimumFiringDelay = 0.1f;
void coolantSystem(subSystem@ subSys, const string@ name, float Factor, float Penalty, float Penalty_ammo, float heatFactor) {
	if(!subSys.type.hasTag(strNoModifiers)) {
		if(name == str_vDelay) {
			float fireDelay = subSys.getVariable(str_vDelay);
			if(fireDelay > 0)
				subSys.setVariable(str_vDelay, max(fireDelay * Factor, min(minimumFiringDelay,fireDelay) ));
		}
		else if(name == str_vAmmoUse) {
			float ammoUse = subSys.getVariable(str_vAmmoUse);
			if(ammoUse > 0)
				subSys.setVariable(str_vAmmoUse, ammoUse * Penalty_ammo);
		}
		else if(name == str_vPowCost) {
			float powUse = subSys.getVariable(str_vPowCost);
			if(powUse > 0)
				subSys.setVariable(str_vPowCost, powUse * Penalty);
		}
		else if(name == str_WasteHeat){
			float wasteHeat = subSys.getVariable(str_WasteHeat);
			if(wasteHeat > 0)
				subSys.setVariable(str_WasteHeat, wasteHeat * heatFactor);			
		}
	}	
}

void makeRapidMount(subSystem@ subSys, const string@ name, float OrigSize, float Range) {
   if(!subSys.type.hasTag(strNoModifiers) && !subSys.type.hasTag(strECM)) {
      if(name == str_vDelay) {
         float trueImpact = (OrigSize + subSys.size) / subSys.size;
         float extraImpact = 1.f + (trueImpact / (4.f + trueImpact));
      
         float fireDelay = subSys.getVariable(str_vDelay);
         fireDelay /= trueImpact * extraImpact;
         subSys.setVariable(str_vDelay, fireDelay);
      }
      else if(name == str_vDamage) {
         float trueImpact = (OrigSize + subSys.size) / subSys.size;
         float extraImpact = 1.f + (trueImpact / (4.f + trueImpact));
      
         float dmg = subSys.getVariable(str_vDamage);
         //Slightly increased dps (roughly equivalent to multiple of the same gun)
         dmg *= (1.f + trueImpact / (15.f + trueImpact)) / extraImpact;
         subSys.setVariable(str_vDamage, dmg);
      }
      else if(name == str_vAmmoUse) {
         float trueImpact = (OrigSize + subSys.size) / subSys.size;
         float extraImpact = 1.f + (trueImpact / (4.f + trueImpact));
      
         float ammoUse = subSys.getVariable(str_vAmmoUse);
         //ammoUse *= extraImpact;
         //subSys.setVariable(str_vAmmoUse, ammoUse);
      }
      else if(name == str_WasteHeat) {
         float trueImpact = (OrigSize + subSys.size) / subSys.size;
         float extraImpact = 1.f + (trueImpact / (4.f + trueImpact));
      
         float wasteHeat = subSys.getVariable(str_WasteHeat);
         wasteHeat *= extraImpact;
         subSys.setVariable(str_WasteHeat, wasteHeat);
      }
      else if(name == str_vPowCost) {
         float trueImpact = (OrigSize + subSys.size) / subSys.size;
         float extraImpact = 1.f + (trueImpact / (4.f + trueImpact));
      
         float powCost = subSys.getVariable(str_vPowCost);
         powCost *= trueImpact * extraImpact;
         subSys.setVariable(str_vPowCost, powCost);
      }
      else if(name == str_vRange) {
         float rng = subSys.getVariable(str_vRange);
         rng *= Range;
         subSys.setVariable(str_vRange, rng);
      }
   }   
}


const string@ strSpace = "vExtra", strHull = "Hull";
void alterSpaceAmount(subSystem@ subSys, const string@ name, float Amount) {
	if(subSys.type.hasTag(strHull)) {
		if(name == strSpace) {
			float space = subSys.getVariable(strSpace);
			subSys.setVariable(strSpace, space + Amount);
		}
	}
}
	

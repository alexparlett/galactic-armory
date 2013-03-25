//GA Planetary Conditions
const string@ strStruct = "Structure";

//changes research rate.
const string@ strResRate = "vResRate";
void modResearch(subSystem@ subSys, const string@ name, float Factor) {
	if(name == strResRate && subSys.type.hasTag(strStruct)) {
		float rate = subSys.getVariable(strResRate);
		if(rate > 0)
			subSys.setVariable(strResRate, rate * Factor);
	}		
}

//change luxuries fab rate
const string@ strLux = "vLuxFab";
void modLuxuries(subSystem@ subSys, const string@ name, float Factor) {
	if(name == strLux && subSys.type.hasTag(strStruct)) {
		float rate = subSys.getVariable(strLux);
		if(rate > 0)
			subSys.setVariable(strLux, rate * Factor);
	}	
}

//change the ammo and fuel fab rate
const string@ strFuelFab = "vFuelRate", strAmmoFab = "vAmmoRate";
void modLogistics(subSystem@ subSys, const string@ name, float Factor) {
	if(name == strFuelFab && subSys.type.hasTag(strStruct)) {
		float rate = subSys.getVariable(strFuelFab);
		if(rate > 0)
			subSys.setVariable(strFuelFab, rate * Factor);
	}
	else if(name == strAmmoFab && subSys.type.hasTag(strStruct)) {
		float rate = subSys.getVariable(strAmmoFab);
		if(rate > 0)
			subSys.setVariable(strAmmoFab, rate * Factor);
	}
}

//changes goods fab rate
const string@ strGoods = "vGoodsFab";
void modGoods(subSystem@ subSys, const string@ name, float Factor) {
	if(name == strGoods && subSys.type.hasTag(strStruct)) {
		float rate = subSys.getVariable(strGoods);
		if(rate > 0)
			subSys.setVariable(strGoods, rate * Factor);
	}			
}

const string@ strDamage = "vDamage", strRange = "vRange";
void modPlanDefenses(subSystem@ subSys, const string@ name, float Factor) {
	if(name == strDamage && subSys.type.hasTag(strStruct))
		subSys.setVariable(strDamage, subSys.getVariable(strDamage) * Factor);
	if(name == strRange && subSys.type.hasTag(strStruct))
		subSys.setVariable(strRange, subSys.getVariable(strRange) * Factor);
}	

const string@ strDR = "vDR";
void modDR (subSystem@ subSys, const string@ name, float Factor) {
	if(name == strDR && subSys.type.hasTag(strStruct))
		subSys.setVariable(strDR, subSys.getVariable(strDR) * Factor);
}		

//Changes the cost of a structure by the specified factor and if it has the tag
// arg0 is factor
const string@ strMetals = "Metals", strElec = "Electronics", strAdvParts = "AdvParts", strLabor = "Labr", strFarm = "Farm";
void changeCosts(subSystem@ subSys, SubSystemEvalMode mode, float Factor) {
	if(subSys.type.hasTag(strFarm) && subSys.type.hasTag(strStruct)){
		switch(mode) {
			case SSVM_Costs:
				{
					subSys.setCost(strMetals, subSys.getCost(strMetals) * Factor);
					subSys.setCost(strElec, subSys.getCost(strElec) * Factor);
					subSys.setCost(strAdvParts, subSys.getCost(strAdvParts) * Factor);
					subSys.setCost(strLabor, subSys.getCost(strLabor) * Factor);
				} break;
		}
	}	
}
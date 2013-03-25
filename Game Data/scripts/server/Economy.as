const string@ strOre = "Ore", strFuel = "Fuel", strAmmo = "Ammo";
const string@ strMtl = "Metals", strMine = "MineM", strMtlGen = "MtlG";
const string@ strElc = "Electronics", strElcGen = "ElcG";
const string@ strAdv = "AdvParts", strAdvGen = "AdvG";
const string@ strFood = "Food", strGoods = "Guds", strLuxuries = "Luxs";
const string@ strLabor = "Labr", strH3 = "H3";

//Provided because AS lacks e# syntax
const double million = 1000000.0;

//Conversion ratios between resources
const float ElcFromMtl = 0.5f;
const float AdvFromMtl = 1.f;
const float AdvFromElc = 1.f;
const float AmmoFromMtl = 2.f;
const float FuelFromFood = 1.f;
const float FuelFromHe3 = 2.f;

//Conversion rates when working with no resources (scales down from 1 to this value as the value/max ratio declines)
const float deadOreRate = 0.2f;
const float deadElcRate = 0.01f;
const float deadAdvRate = 0.001f;

float getRate(float val, float max, float deadRate) {
	if(max <= 0)
		return 0;
	float pct = val / max;
	if(pct <= 0)
		return deadRate;
	else if(pct >= 1.f)
		return 1.f;
	else
		return (pct * (1.f - deadRate)) + deadRate;
}

//Processes Ore into Metals
float processOre(Object@ obj, float Rate) {
	State@ resource = obj.getState(strOre);
	
	Rate *= getRate(resource.getAvailable(), resource.max, deadOreRate);
	if(Rate <= 0)
		return 0;
	
	State@ outRes = obj.getState(strMtl);
	float maxOut = outRes.getTotalFreeSpace(obj);
	float consume = Rate;

	if (obj.getOwner().hasTraitTag("lossy_mining"))
		consume *= 1.667f;
	
	if(maxOut > 0) {
		if(Rate > maxOut)
			Rate = maxOut;
		outRes.add(Rate, obj);
		resource.consume(min(consume,resource.getAvailable()), obj);
		return Rate;
	}
	return 0;
}

//Produces Electronics from Metals
float makeElectronics(Object@ obj, float Rate) {
	State@ resource = obj.getState(strMtl);
		
	const float has = resource.getAvailable();
	
	State@ outRes = obj.getState(strElc);
	float maxOut = outRes.getTotalFreeSpace(obj);
	
	if(maxOut > 0) {
		Rate = min(maxOut, Rate);
		
		float useUp = Rate / ElcFromMtl;
		if(useUp > has) {
			Rate = has * ElcFromMtl;
			useUp = has;
		}
		outRes.add(Rate, obj);
		resource.consume(useUp, obj);
		return Rate;
	}
	return 0;
}

//Produces Ammo from Metals
float makeAmmo(Object@ obj, float Rate) {
	State@ resource = obj.getState(strMtl);
		
	const float has = resource.getAvailable();
	
	State@ outRes = obj.getState(strAmmo);
	float maxOut = outRes.getTotalFreeSpace(obj);
	
	if(maxOut > 0) {
		Rate = min(maxOut, Rate);
		
		float useUp = Rate / AmmoFromMtl;
		if(useUp > has) {
			Rate = has * AmmoFromMtl;
			useUp = has;
		}
		outRes.add(Rate, obj);
		resource.consume(useUp, obj);
		return Rate;
	}
	return 0;
}

//Produces Fuel from Food
float makeFuel(Object@ obj, float Rate) {
	State@ resource = obj.getState(strFood);
		
	const float has = resource.getAvailable();
	
	State@ outRes = obj.getState(strFuel);
	float maxOut = outRes.getTotalFreeSpace(obj);
	
	if(maxOut > 0 && resource.val > resource.max * 0.25f) {
		Rate = min(maxOut, Rate);
		
		float useUp = Rate / FuelFromFood;
		if(useUp > has) {
			Rate = has * FuelFromFood;
			useUp = has;
		}
		outRes.add(Rate, obj);
		resource.consume(useUp, obj);
		return Rate;
	}
	return 0;
}

//Produces HE3 Fuel from Food
float makeH3Fuel(Object@ obj, float Rate) {
	State@ resource = obj.getState(strH3);
		
	const float has = resource.getAvailable();
	
	State@ outRes = obj.getState(strFuel);
	float maxOut = outRes.getTotalFreeSpace(obj);
	
	if(maxOut > 0 && resource.val > resource.max * 0.25f && has > 0.01f) {
		Rate = min(maxOut, Rate);
		
		float useUp = Rate / FuelFromHe3;
		if(useUp > has) {
			Rate = has * FuelFromHe3;
			useUp = has;
		}
		outRes.add(Rate, obj);
		resource.consume(useUp, obj);
		return Rate;
	}
	return 0;
}

//Produces AdvParts from Metals, Electronics
float makeAdvParts(Object@ obj, float Rate) {
	State@ mtls = obj.getState(strMtl), elects = obj.getState(strElc);
	
	const float hasM = mtls.getAvailable(), hasE = elects.getAvailable();
	
	State@ outRes = obj.getState(strAdv);
	float maxOut = outRes.getTotalFreeSpace(obj);
	
	if(maxOut <= 0)
		return 0;
	
	Rate = min(maxOut, Rate);
	
	float useUpM = Rate / AdvFromMtl, useUpE = Rate / AdvFromElc;
	if(useUpM > hasM)
		useUpM = hasM;
	if(useUpE > hasE)
		useUpE = hasE;
	
	Rate = min(useUpM * AdvFromMtl, useUpE * AdvFromElc);
	
	outRes.add(Rate, obj);
	mtls.consume(Rate / AdvFromMtl, obj);
	elects.consume(Rate / AdvFromElc, obj);
	return Rate;
}

void produceGoods(Event@ evt, float Rate) {
	evt.target.getOwner().addStat(strGoods, Rate * evt.time);
}

void produceLuxuries(Event@ evt, float Rate) {
	evt.target.getOwner().addStat(strLuxuries, Rate * evt.time);
}

//returns optimal Metal production, ignoring cargo space, not ignoring available ore (becouse there is nothing player can do with missing ore)
float optimalProcessOre(Object@ obj, float Rate) {
	State@ resource = obj.getState(strOre);
	
	Rate *= getRate(resource.getAvailable(), resource.max, deadOreRate);
	if(Rate <= 0)
		return 0;
	
	return Rate;
}
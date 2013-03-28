const string@ strOre = "Ore",strH3 = "H3", strDamage = "Damage", strMass = "mass";
const string@ strMtl = "Metals", strMine = "MineM", strMtlGen = "MtlG", strMineOpt = "MineMOpt";
const string@ strElc = "Electronics", strElcGen = "ElcG", strElcGenOpt = "ElcGOpt";
const string@ strAdv = "AdvParts", strAdvGen = "AdvG", strAdvGenOpt = "AdvGOpt", strFoodGen = "FudGe";
const string@ strFood = "Food", strGoods = "Guds", strLuxuries = "Luxs";
const string@ strLabor = "Labr", strWorkers = "Workers", strTrade = "Trade", strTradeTarget = "TradeTarget", strMood = "Mood", strTradeMode = "TradeMode";
const string@ actShortWorkWeek = "work_low", actForcedLabor = "work_forced", actTaxBreak = "tax_break", strEthics = "ethics", strEcoMode = "eco_mode";
const string@ actStockPile = "act_stockpile";
const string@ strRadius = "radius", strStatic = "static";
const string@ strLuxsGen = "LuxG", strGudsGen = "GudsG";
const string@ strFuelGen = "FuelG", strFuel = "Fuel";
const string@ strAmmoGen = "AmmoG", strAmmo = "Ammo";

const string@ strNoFood = "no_food", strFastConsumption = "fast_consumption", strConsumeMetals = "consume_metals", strFastReproduction = "fast_reproduction";
const string@ strPlanetClearOnLost = "planet_clear_on_lost", strDisableCivilActs = "disable_civil_acts";
const string@ strSlowConsumption = "low_consume", strSlowReproduction = "low_reproduction";
const string@ strAlwaysHappy = "always_happy", strPlanetRemoveConditions = "planet_remove_conditions";
const string@ strLowLuxuries = "low_luxuries_consumption", strHighLuxuries = "high_luxuries_consumption";
const string@ strDoubleLabor = "double_pop_labor", strHalfLabor ="half_pop_labor", strIndifferent = "forever_indifferent";
const string@ strHalfExports = "half_exports", strH3FuelGen = "H3FuelG";
const string@ strGroundForces = "GroundForces";
ObjectFlag objImprovement = objUser03, setImpPause = objSetting00, objInvasion = objUser02;

const string@ strPosition = "position", strRotation = "rotation";
const double million = 1000000.0;
const double c_e = 2.71828183;

//Conversion rates when working with no resources (scales down from 1 to this value as the value/max ratio declines)
const float deadOreRate = 0.2f;
const float deadElcRate = 0.01f;
const float deadAdvRate = 0.001f;

import float processOre(Object@ obj, float Rate) from "Economy";
import float makeElectronics(Object@ obj, float Rate) from "Economy";
import float makeAdvParts(Object@ obj, float Rate) from "Economy";
import float makeFuel(Object@ obj, float Rate) from "Economy";
import float makeAmmo(Object@ obj, float Rate) from "Economy";
import float optimalProcessOre(Object@ obj, float Rate) from "Economy";
import void chooseGovernor(Planet@ pl) from "BasicEffects";
import float makeH3Fuel(Object@ obj, float Rate) from "Economy";
import float getRate(float val, float max, float deadRate) from "Economy";

//EMPIRE ACTS:
//============
//Short Work Week:
//	75% labor output, happiness trends toward 25%
//Forced Labor:
//	80% labor output, regardless of happiness; happiness trends toward -50%

//Work Ethic Campaign:
//	150% labor output, 75% economic output
//Academic Campaign:
//	50% labor output, 125% economic output

//Tax Break:
//	People consume goods 50% faster (more happiness as a result, but low supply causes problems faster)
//Regressive Tax:
//	Goods consumption reduced 50%. Metals Production reduced 50%, Electronics reduced 20%. Mood -10%.
//Progressive Tax:
//	Luxuries consumption reduced 50%. Electronics Production reduced 20%, AdvParts reduced 50%. Mood -20%.

//RESOURCE MODES:
//Metal/Electronics/AdvParts Focus
// +50% Chosen resource generation rate. -35% Other resource generation rate
//Metal/Electronics/AdvParts Frenzy
// +100% Chosen resource generation rate. -90% Other resource generation rate

const float baseWorkRate = 0.5f, workPopulationLevel = float(60.0 * million), workMoodImpact = 2.f, laborRate = 10.f;

const float moodDecayRate = float(1.0 - 0.1);

const float goodsPerPerson = float(15.0 / million), luxPerPerson = float(1.5 / million);
const float noGoodsDecay = float(1.0 - 0.1), luxGrowth = float(1.0 - 0.135);

float approachVal(float val, float approach, float percentToward) {
	return approach + ((val - approach) * percentToward);
}


enum popMode {
	PM_Normal,
	PM_Work_Slow,
	PM_Work_Hard
};

enum ethic {
	EC_Normal,
	EC_Labor,
	EC_Economy,
};

enum ecoMode {
	EM_Normal,
	EM_Focus,
	EM_Frenzy,
	
	EM_Metals,
	EM_Elects,
	EM_AdvParts,
};

enum TradeMode {
	TM_All,
	TM_ImportOnly,
	TM_ExportOnly,
	TM_Nothing,
};

void popEcoInit(Event@ evt) {
	State@ mood = evt.obj.getState(strMood);
	mood.max = 1.f;
	evt.obj.getState(strLuxsGen);
	evt.obj.getState(strGudsGen);
	evt.obj.getState(strFoodGen);
	evt.obj.getState(strTrade);
	evt.obj.getState(strFoodGen);
	evt.obj.getState(strFood);
	evt.obj.getState(strMtl);
	evt.obj.getState(strMine);
	evt.obj.getState(strMtlGen);
	evt.obj.getState(strElc);
	evt.obj.getState(strElcGen);
	evt.obj.getState(strAdv);
	evt.obj.getState(strAdvGen);
	evt.obj.getState(strFuel);
	evt.obj.getState(strFuelGen);
	evt.obj.getState(strAmmo);
	evt.obj.getState(strAmmoGen);
	evt.obj.getState(strH3FuelGen);

	evt.obj.getState(strMineOpt);
	evt.obj.getState(strElcGenOpt);
	evt.obj.getState(strAdvGenOpt);

	print("Planet Initialized");
}

float modifyEcoRate(float rate, ecoMode type, ecoMode rateMode, ecoMode typeMode) {
	if(rateMode == EM_Normal)
		return rate;
	if(type == typeMode) {
		if(rateMode == EM_Focus)
			return rate * 1.5f;
		else
			return rate * 2.f;
	}
	else {
		if(rateMode == EM_Focus)
			return rate * 0.65f; //-35%
		else
			return rate * 0.1f; //-90%
	}
}

//Performs economic generation for planets
void tick(Planet@ pl, float time) {
	Object@ obj = pl;
	Empire@ emp = obj.getOwner();
	if(emp is null || emp.isValid() == false)
		return;
	
	State@ mood = obj.getState(strMood);
	
	int runner = rand(1,100);
	
	float population = pl.getPopulation();
	if(population <= 0.1f)
		return;
	
	float lackOfWorkers = 1.f;
	{
		State@ workers = pl.toObject().getState(strWorkers);
		lackOfWorkers = clamp(workers.val / max(workers.required,1.f),0.1f,1.f);
	}
	
	// Update population growth
	float foodSupplyPct = 1.f;
	{
		float pop = pl.getPopulation();
		float maxPop = pl.getMaxPopulation();
		float reproduction = 0.02f;
		float consumptionRate = 1.f;

		if (emp.hasTraitTag(strFastConsumption))
			consumptionRate *= 2.f;
		if (emp.hasTraitTag(strFastReproduction))
			reproduction *= 2.f;
		if(obj.isUnderAttack())
			reproduction *= 0.5f;
		if (emp.hasTraitTag(strSlowConsumption))
			consumptionRate *= 0.5f;
		if (emp.hasTraitTag(strSlowReproduction))
			reproduction *= 0.66f;

		float growth = (pop * maxPop) / (pop + ((maxPop - pop) * pow(float(c_e), -reproduction * time))) - pop;
		pl.modPopulation(growth);

		// Consume food
		if (!emp.hasTraitTag(strNoFood)) {
			// Consume food
			double consumption = 0.06/million * double(consumptionRate);
			foodSupplyPct = populationConsume(pl, strFood, consumption, time);
		}

		// Consume metals if we have that trait
		if (emp.hasTraitTag(strConsumeMetals)) {
			double consumption = 6/million * double(consumptionRate);
			foodSupplyPct = populationConsume(pl, strMtl, consumption, time);
		}
	}
	
	bool hasCivilActs = !emp.hasTraitTag(strDisableCivilActs);
	popMode mode = PM_Normal;
	if (hasCivilActs)
		if(emp.getSetting(actShortWorkWeek) == 1)
			mode = PM_Work_Slow;
		else if(emp.getSetting(actForcedLabor) == 1)
			mode = PM_Work_Hard;
	
	ethic workEthic = EC_Normal;
	if (hasCivilActs)
		switch(uint(emp.getSetting(strEthics))) {
			case 1:
				workEthic = EC_Labor; break;
			case 2:
				workEthic = EC_Economy; break;
		}
	
	ecoMode ecoRate = EM_Normal, ecoType = EM_Metals;
	uint ecoSetting = 0;

	if (hasCivilActs) {
		ecoSetting = uint(emp.getSetting(strEcoMode));
		switch((ecoSetting-1) % 3) { //pick 1-3 and 4-6 as 0-2
			case 0:
				ecoType = EM_Metals; break;
			case 1:
				ecoType = EM_Elects; break;
			case 2:
				ecoType = EM_AdvParts; break;
		}
	}
	
	if(ecoSetting >= 4)
		ecoRate = EM_Frenzy;
	else if(ecoSetting > 0)
		ecoRate = EM_Focus;
	
	float moodDecayFactor = time;
	float moodDecayToward = 0;
	float popFactor = getGameSetting("WORK_POP_MULTI",1.0);
	bool hasMood = !emp.hasTraitTag(strIndifferent);
	
	float workRate = time * baseWorkRate * lackOfWorkers * (0.5f + ((population / workPopulationLevel) * popFactor));
	
	switch(mode) {
		case PM_Work_Slow:
			workRate *= 0.75f;
			moodDecayToward = 0.25f;
		case PM_Normal:
			workRate *= pow(workMoodImpact, mood.val);
			break;
		case PM_Work_Hard:
			workRate *= 0.8f;
			moodDecayToward = -0.5f;
			break;
	}
	
	//Decay mood
	if (hasMood)
		mood.val = approachVal(mood.val, moodDecayToward, pow(moodDecayRate,moodDecayFactor));
	else
		mood.val = 0;
	
	float tickLabor = workRate * laborRate;
	float tickEco = workRate;
	if(workEthic == EC_Labor) {
		tickLabor *= 1.5f;
		tickEco *= 0.9f;
	}
	else if(workEthic == EC_Economy) {
		tickLabor *= 0.5f;
		tickEco *= 1.1f;
	}

	if (emp.hasTraitTag(strDoubleLabor))
		tickLabor *= 2.f;
		
	if (emp.hasTraitTag(strHalfLabor))
		tickLabor *= 0.5f;
	
	//Produce things
	State@ labor = obj.getState(strLabor);
	obj.getState(strLabor).add(tickLabor, obj);	

	State@ foodRate = obj.getState(strFoodGen);
	State@ goodsRate = obj.getState(strGudsGen);
	State@ luxsRate = obj.getState(strLuxsGen);

	goodsRate.inCargo = 0;
	luxsRate.inCargo = 0;

	float produceGoods = goodsRate.max * time;
	float produceLuxs = luxsRate.max * time;

	System@ parent = obj.getParent();
	bool blockaded = parent !is null && parent.isBlockadedFor(emp);
	
	State@ advRate = obj.getState(strAdvGen);
	if(@advRate != null && advRate.max > 0)
		advRate.val = makeAdvParts(obj, modifyEcoRate(advRate.max * tickEco, EM_AdvParts, ecoRate, ecoType)) / time;
		
	State@ elcRate = obj.getState(strElcGen);
	if(@elcRate != null && elcRate.max > 0)
		elcRate.val = makeElectronics(obj, modifyEcoRate(elcRate.max * tickEco, EM_Elects, ecoRate, ecoType)) / time;

	State@ mtlRate = obj.getState(strMine);
	if(@mtlRate != null && mtlRate.max > 0)
		mtlRate.val = processOre(obj, modifyEcoRate(mtlRate.max * tickEco, EM_Metals, ecoRate, ecoType)) / time;
		
	State@ fuelRate = obj.getState(strFuelGen);
	if(@fuelRate != null && fuelRate.max > 0)
		fuelRate.val = makeFuel(obj, fuelRate.max) / time;
		
	State@ h3fuelRate = obj.getState(strH3FuelGen);
	if(@h3fuelRate != null && h3fuelRate.max > 0)
		h3fuelRate.val = makeH3Fuel(obj, h3fuelRate.max * tickEco) / time;		

	State@ ammoRate = obj.getState(strAmmoGen);
	if(@ammoRate != null && ammoRate.max > 0)
		ammoRate.val = makeAmmo(obj, ammoRate.max * tickEco) / time;		

	// Optimal rates of production
	State@ mtlRateOpt = obj.getState(strMineOpt);
	mtlRateOpt.val = 0.f;
	if(@mtlRate != null && mtlRate.max > 0)
		mtlRateOpt.val = optimalProcessOre(obj, modifyEcoRate(mtlRate.max * tickEco, EM_Metals, ecoRate, ecoType)) / time;

	State@ elcRateOpt = obj.getState(strElcGenOpt);
	elcRateOpt.val = 0.f;
	if(@elcRate != null && elcRate.max > 0)
		elcRateOpt.val = modifyEcoRate(elcRate.max * tickEco, EM_Elects, ecoRate, ecoType) / time;

	State@ advRateOpt = obj.getState(strAdvGenOpt);
	advRateOpt.val = 0.f;
	if(@advRate != null && advRate.max > 0)
		advRateOpt.val = modifyEcoRate(advRate.max * tickEco, EM_AdvParts, ecoRate, ecoType) / time;

	float consumeFactor = time;
	if(hasCivilActs && emp.getSetting(actTaxBreak) == 1)
		consumeFactor *= 1.5f;
	
	if(hasMood) {
		//Consume goods and luxuries
		//Lacking goods only hurts happiness
		const float needGoods = population * goodsPerPerson * consumeFactor;
		float gotGoods = 0.f;
		if (produceGoods > 0) {
			if (needGoods < produceGoods) {
				produceGoods -= needGoods;
				gotGoods += needGoods;
			}
			else {
				gotGoods += produceGoods;
				produceGoods = 0.f;
			}
		}

		if (!blockaded  || runner > 95) {
			float consumedGoods = emp.consumeStat(strGoods, needGoods - gotGoods);
			gotGoods += consumedGoods;
			goodsRate.inCargo = consumedGoods;
		}
		if(gotGoods < needGoods)
			mood.val = approachVal(mood.val, -1.f, pow(noGoodsDecay, consumeFactor * (needGoods-gotGoods)/needGoods) );
	
		//Having luxuries only increases happiness
		float needLux = population * luxPerPerson * consumeFactor;
		if (emp.hasTraitTag(strLowLuxuries))
			needLux *= 0.5f;
		else if (emp.hasTraitTag(strHighLuxuries))
			needLux *= 2.f;

		float gotLux = 0.f;
		if (produceLuxs > 0) {
			if (needLux < produceLuxs) {
				produceLuxs -= needLux;
				gotLux += needLux;
			}
			else {
				gotLux += produceLuxs;
				produceLuxs = 0.f;
			}
		}

		luxsRate.inCargo = gotLux;
		if (!blockaded || runner > 95) {
			float consumedLux = emp.consumeStat(strLuxuries, needLux - gotLux);
			gotLux += consumedLux;
			luxsRate.inCargo = consumedLux;
		}
		if(gotLux > 0)
			mood.val = approachVal(mood.val, 1.f, pow(luxGrowth, consumeFactor * (1.f - (needLux-gotLux)/needLux) ) );
		
		if(pl.toObject().isUnderAttack())
			mood.val = approachVal(mood.val, -1.f, pow(noGoodsDecay, time));
		if(foodSupplyPct < 1.f)
			mood.val = approachVal(mood.val, -1.f + foodSupplyPct, pow(noGoodsDecay, time));

		//Artificially keep population happy
		if (mood.val < 0 && emp.hasTraitTag(strAlwaysHappy))
			mood.val = 0;
	}

	// Add excess goods/luxuries to the bank
	if (!blockaded || runner > 95) {
		if (produceGoods > 0) {
			emp.addStat(strGoods, produceGoods);
			goodsRate.inCargo -= produceGoods;
		}	
		
		goodsRate.inCargo /= time;

		if (produceLuxs > 0) {
			emp.addStat(strLuxuries, produceLuxs);
			luxsRate.inCargo -= produceLuxs;
		}	

		luxsRate.inCargo /= time;	
		
		//Trade things
		State@ tradeRate = obj.getState(strTrade);
		float tickTrade = tradeRate.val * time * lackOfWorkers;
		float tradeTarget = 0.5f;		
		
		string@ govName = pl.getGovernorType();
		if (hasCivilActs && emp.getSetting(actStockPile) >= 0.5f)
			tradeTarget = 0.95f;
		else if (govName == "shipworld" || govName == "forge" || (govName == "outpost"))  	
			tradeTarget = 0.8f;
		else if (govName == "agrarian" || govName == "metalworld" || (govName == "advpartworld") || govName == "elecworld" || (govName == "resworld") || govName == "ammoworld" || govName == "fuelworld" || govName == "h3fuelworld")  	
			tradeTarget = 0.4f;
				
		State@ TrdMode = obj.getState(strTradeMode);
		TradeMode trdMode = TradeMode(int(TrdMode.val));
		State@ tradeTargetState = obj.getState(strTradeTarget);
		if(trdMode == TM_All || trdMode == TM_ExportOnly)
			tradeTargetState.val = tradeTarget;	
		else
			tradeTargetState.val = 0;
				
		if(tickTrade > 0.f) {
			float tradeEff = 1.f;
			if (gameTime < 1200.f && emp.hasTraitTag(strHalfExports))
				tradeEff = 0.5f;

			float cargoUsed, cargoSpace, cargoSpaceLeft;
			obj.getCargoVals(cargoUsed, cargoSpace); cargoSpaceLeft = cargoSpace - cargoUsed;
			
			//Set Trade Mode
			float tval = 0, tmax = 0, treq = 0, tcargo = 0;
			TradeMode advMode = TM_All, elcMode = TM_All, mtlMode = TM_All, fudMode = TM_All;
			if (obj.getStateVals(strTradeMode, tval, tmax, treq, tcargo)) {
				advMode = TradeMode(int(tval));
				elcMode = TradeMode(int(tmax));
				mtlMode = TradeMode(int(treq));
				fudMode = TradeMode(int(tcargo));
			}			
		
			//emp.getStatStats(strFood, v,i,e,d);	
			State@ sp_Food = obj.getState(strFood);
			float foodWeight = getResourceWeight(sp_Food, cargoSpaceLeft, tradeTarget); //float(e/max(i,1.0));
			
			State@ sp_Metals = obj.getState(strMtl);
			float mtlWeight = getResourceWeight(sp_Metals, cargoSpaceLeft, tradeTarget);
			
			State@ sp_Elecs = obj.getState(strElc);
			float elecWeight = getResourceWeight(sp_Elecs, cargoSpaceLeft, tradeTarget);
			
			State@ sp_Advs = obj.getState(strAdv);
			float advWeight = getResourceWeight(sp_Advs, cargoSpaceLeft, tradeTarget);
			
			State@ sp_Ammo = obj.getState(strAmmo);
			float ammoWeight = getResourceWeight(sp_Ammo, sp_Ammo.getTotalFreeSpace(obj), tradeTarget);
			
			State@ sp_Fuel = obj.getState(strFuel);
			float fuelWeight = getResourceWeight(sp_Fuel, sp_Fuel.getTotalFreeSpace(obj), tradeTarget);			
			
			float totalWeight = abs(foodWeight) + abs(mtlWeight) + abs(elecWeight) + abs(advWeight) + abs(ammoWeight) + abs(fuelWeight);
			
			if(totalWeight > 0) {
				advRate.inCargo = tradeResource(emp, obj, sp_Advs, strAdv, tickTrade * advWeight/totalWeight, tradeEff, advMode);
				elcRate.inCargo = tradeResource(emp, obj, sp_Elecs, strElc, tickTrade * elecWeight/totalWeight, tradeEff, elcMode);
				mtlRate.inCargo = tradeResource(emp, obj, sp_Metals, strMtl, tickTrade * mtlWeight/totalWeight, tradeEff, mtlMode);
				foodRate.inCargo = tradeResource(emp, obj, sp_Food, strFood, tickTrade * foodWeight/totalWeight, 1.f, fudMode);
				ammoRate.inCargo = tradeResource(emp, obj, sp_Ammo, strAmmo, tickTrade * ammoWeight/totalWeight, tradeEff, mtlMode);
				fuelRate.inCargo = tradeResource(emp, obj, sp_Fuel, strFuel, tickTrade * fuelWeight/totalWeight, tradeEff, fudMode);				
				tickTrade -= abs(advRate.inCargo) + abs(elcRate.inCargo) + abs(mtlRate.inCargo) + abs(foodRate.inCargo) +  abs(ammoRate.inCargo) + abs(fuelRate.inCargo);
			}
			else {
				advRate.inCargo = 0;
				elcRate.inCargo = 0;
				mtlRate.inCargo = 0;
				foodRate.inCargo = 0;
				ammoRate.inCargo = 0;
				fuelRate.inCargo = 0;
				tradeRate.inCargo = 0;
			}
			
			if(tickTrade > 0) {
				float traded = 0.f;

				traded = tradeResource(emp, obj, sp_Advs, strAdv, tickTrade * sign(advWeight), tradeEff, advMode);
				advRate.inCargo += traded;
				if(advRate.inCargo > 0)
					tradeRate.inCargo = advRate.inCargo;
				tickTrade -= abs(traded);

				if (tickTrade > 0) {
					traded = tradeResource(emp, obj, sp_Elecs, strElc, tickTrade * sign(elecWeight), tradeEff, elcMode);
					elcRate.inCargo += traded;
					if(elcRate.inCargo > 0)
						tradeRate.inCargo += elcRate.inCargo;					
					tickTrade -= abs(traded);

					if (tickTrade > 0) {
						traded = tradeResource(emp, obj, sp_Metals, strMtl, tickTrade * sign(mtlWeight), tradeEff, mtlMode);
						mtlRate.inCargo += traded;
						if(mtlRate.inCargo > 0)
							tradeRate.inCargo += mtlRate.inCargo;
						tickTrade -= abs(traded);

						if (tickTrade > 0) {
							traded = tradeResource(emp, obj, sp_Food, strFood, tickTrade * sign(foodWeight), 1.f, fudMode);
							foodRate.inCargo += traded;
							if(foodRate.inCargo > 0)
								tradeRate.inCargo += foodRate.inCargo;
							tickTrade -= abs(traded);
						
							if (tickTrade > 0) {
								traded = tradeResource(emp, obj, sp_Fuel, strFuel, tickTrade * sign(fuelWeight), tradeEff, fudMode);
								fuelRate.inCargo += traded;
								if(fuelRate.inCargo > 0) {
									tradeRate.inCargo += fuelRate.inCargo;
								}	
								tickTrade -= abs(traded);
							
								if(tickTrade > 0) {
									traded = tradeResource(emp, obj, sp_Ammo, strAmmo, tickTrade * sign(ammoWeight), tradeEff, mtlMode);
									ammoRate.inCargo += traded;
									if(ammoRate.inCargo > 0) {
										tradeRate.inCargo += ammoRate.inCargo;
									}	
									tickTrade -= abs(traded);
								}	
							}
						}	
					}
				}
			}
			tradeRate.required = ((tradeRate.val * time) - tickTrade) / time;

			advRate.inCargo /= time;
			elcRate.inCargo /= time;
			mtlRate.inCargo /= time;
			foodRate.inCargo /= time;
			ammoRate.inCargo /= time;
			fuelRate.inCargo /= time;
			tradeRate.inCargo /= time;
		}
		else {
			tradeRate.required = 0;
			advRate.inCargo = 0;
			elcRate.inCargo = 0;
			mtlRate.inCargo = 0;
			foodRate.inCargo = 0;
			ammoRate.inCargo = 0;
			fuelRate.inCargo = 0;	
			tradeRate.inCargo = 0;
		}
	}
	else {
		advRate.inCargo = 0;
		elcRate.inCargo = 0;
		mtlRate.inCargo = 0;
		foodRate.inCargo = 0;
		goodsRate.inCargo = 0;
		luxsRate.inCargo = 0;
		ammoRate.inCargo = 0;
		fuelRate.inCargo = 0;

		State@ tradeRate = obj.getState(strTrade);
		tradeRate.inCargo = 0;		
		tradeRate.required = 0;
	}

	// Update worker stat
	State@ workers = pl.toObject().getState(strWorkers);
	workers.val = pl.getPopulation();
	workers.max = pl.getMaxPopulation();
}

float sign(float x) {
	if(x > 0)
		return 1.f;
	else if(x < 0)
		return -1.f;
	else
		return 0.f;
}

float getResourceWeight(State@ state, float freeCargoSpace, float tradeToPct) {
	if(abs(state.max) < 0.01f)
		return 0.f;
	float pct = (state.val + state.inCargo)	/ (state.max + state.inCargo + freeCargoSpace);
	if(pct > 0.5f)
		return (1.f/tradeToPct) * (pct - tradeToPct);
	else if(pct < 0.5f)
		return (-1.f/tradeToPct) * (tradeToPct - pct);
	else
		return 0;
}

//Trade a maximal amount of the specified resource. If amount is negative, it will be imported.
//Returns the amount that was traded
float tradeResource(Empire@ emp, Object@ obj, State@ state, const string@ statName, float amount, float tradeEff, TradeMode mode) {
	if (mode == TM_Nothing)
		return 0;
	if(abs(amount) < 0.01f)
		return 0;
	float cargoUsed, cargoMax;
	obj.getCargoVals(cargoUsed, cargoMax);
	
	
	
	float halfCapacity = (state.max + cargoMax + state.inCargo - cargoUsed) * 0.5f;
	if(amount > 0) {
		if (mode == TM_ImportOnly)
			return 0;
		float give = min(state.val + state.inCargo - halfCapacity, amount);
		if(give > 0.05f) {
			emp.addStat(statName, give * tradeEff);
			state.consume(give, obj);
			return give;
		}
		else {
			return 0;
		}
	}
	else {
		if (mode == TM_ExportOnly)
			return 0;
		amount = abs(amount);
		float take = min(halfCapacity - (state.val + state.inCargo), amount);
		if(take > 0.05f) {
			take = emp.consumeStat(statName, take);
			if(take > 0) {
				state.add(take, obj);
				return -take;
			}
			else {
				return 0;
			}
		}
		else {
			return 0;
		}
	}
	
}

/* Helper to consume an amount of resource per population */
//Returns the pct of food we ate compared to our needs
float populationConsume(Planet@ pl, const string@ state, double amnPer, double time) {
	double pop = pl.getPopulation();
	double maxPop = pl.getMaxPopulation();

	State@ Troops = pl.toObject().getState(strGroundForces);
	double troops = Troops.val;
	double maxtroops = Troops.max;

	State@ res = pl.toObject().getState(state);
	double avail = res.getAvailable();
	double popneeded = pop * time * amnPer;
	double troopneeded = troops * time * amnPer;
	double needed = popneeded + troopneeded;

	if (avail >= needed) {
		res.consume(needed, pl.toObject());
		return 1.f;
	}
	else {
		res.consume(avail, pl.toObject());
		//Up to 10% of the population will die per second		
		pl.modPopulation(-1.f * min((popneeded - avail) / amnPer, pop * (1.f - pow(0.95f,float(time))) ));
		//Up to 5% of the troops will die per second
		Troops.val -= ((1.f * min((troopneeded - avail) / amnPer, Troops.val * (1.f - pow(0.975f,float(time))) )));
		return avail/needed;
	}
}

// Is called when a planet is destroyed. Return true to prevent the destruction.
bool onDestroy(Planet@ pl, bool silent) {
	if (!silent) {
		System@ sys = pl.toObject().getParent();
		if (sys is null)
			return false;

		State@ ore = pl.toObject().getState(strOre);

		// A percentage of max ore is base
		float remnOre = ore.max * 0.1f;

		// All the ore left on the planet
		remnOre += ore.getAvailable();

		// All the metals left on the planet
		remnOre += pl.toObject().getState(strMtl).getAvailable();

		// Make asteroids
		Oddity_Desc asteroid_desc;
		asteroid_desc.id = "asteroid";

		vector pos = pl.toObject().position;
		float dist = 90.f;

		uint rocks = rand(1, 10);
		for (uint i = 0; i < rocks; ++i) {
			float orePerc = randomf(0.9f, 1.1f) / rocks;
			float useOre = orePerc * remnOre;

			asteroid_desc.clear();
			asteroid_desc.setFloat(strRadius, orePerc * randomf(15.f, 30.f));
			asteroid_desc.setFloat(strStatic, 1.f);
			asteroid_desc.setFloat(strMass, useOre);

			asteroid_desc.setVector(strPosition, pos + vector(randomf(-0.5f, 0.5f) * dist, randomf(-0.5f, 0.5f) * dist, randomf(-0.5f, 0.5f) * dist));
			asteroid_desc.setVector(strRotation, vector(randomf(360.f), randomf(360.f), randomf(360.f)));
			Object@ asteroid = sys.makeOddity(asteroid_desc);
		
			State@ ore = asteroid.getState(strOre);
			ore.max = useOre;
			ore.val = ore.max;

			State@ dmg = asteroid.getState(strDamage);
			dmg.max = useOre;
			dmg.val = 0;
		}

		if(canAchieve)
			achieve(AID_DEST_PLANET);
	}

	return false;
}

// Is called when a planet changes owners. Return true to prevent the takeover.
bool onOwnerChange(Planet@ pl, Empire@ from, Empire@ to) {
	Object@ obj = pl;

	// Clear planet when previous owner has trait
	if (from !is null && from.isValid() && from.hasTraitTag(strPlanetClearOnLost)) {
		obj.clearBuildQueue();
		pl.removeAllStructures();
	}
	
	// If its rebuilding Capitol cancel build
	if( to !is null && to.isValid() && (obj.getConstructionQueueSize() > 0 && obj.getConstructionName() == "Planet Capitol"))
		obj.clearBuildQueue();	
	
	// Remove planet conditions if new owner has trait
	if (to !is null && to.isValid() && to.hasTraitTag(strPlanetRemoveConditions)) {
		for (int i = pl.getConditionCount() - 1; i >= 0; --i) {
			const PlanetCondition@ cond = pl.getCondition(i);
			if (!cond.constructed && !cond.hasTag("neutrino") && !cond.hasTag("remnant") && !cond.hasTag("homeworld") && !cond.hasTag("improvement") && !cond.hasTag("bombardment"))
				pl.removeCondition(cond.get_id());
		}
	}

	// Check achievements
	if (canAchieve && to is getPlayerEmpire()) {
		if(pl.hasCondition("microcline")) {
			achieve(AID_MICROCLINE);
		}
	}

	// Clear any import/export flags
	obj.setStateVals(strTradeMode, 0, 0, 0, 0);
	
	// Clear any flags
	obj.setFlag(objImprovement, false);
	obj.setFlag(setImpPause, false);
	obj.setFlag(objInvasion, false);

	return false;
}

// Is called when a planet is repaired. Return true to prevent normal repair behaviour.
// bool onRepair(Planet@ pl, float amount) {
// 	return false;
// }

string@ strDR = "DR";
// Is called when a planet is damaged. Return true to prevent normal damage behaviour.
bool onDamage(Planet@ pl, Event@ evt) {
	State@ dr = pl.toObject().getState(strDR);
	
	if(dr !is null)
		evt.damage *= 1 - (dr.max / (1500 + dr.max));
 	return false;
}
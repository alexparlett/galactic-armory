const string@ strCrew = "Crew", strPower = "Power", strFuel = "Fuel", strAir = "Air", strBoardingDefense = "BoardingDefense";
const string@ strPDEffectivity = "PDEffectivity", strShields = "Shields", strShieldArmor = "ShieldArmor";
const string@ strUnobtainable = "Unobtainable";
float troopDamage = 1.f, troopRepair = 5.f;

void takeOver(Object@ obj, Empire@ owner) {
	if(obj.getOwner() is owner)
		return;
	obj.setOwner(owner);
	
	HulledObj@ ship = @obj;
	if(ship !is null && !ship.getHull().hasSystemWithTag(strUnobtainable))
		owner.acquireForeignHull(ship.getHull());

	ship.forceActivate();
	
	State@ crew = obj.getState(strCrew);
	crew.val = crew.max;
	
	State@ air = obj.getState(strAir);
	air.val = air.max;
	
	State@ pow = obj.getState(strPower);
	pow.val = pow.max;
	
	State@ fuel = obj.getState(strFuel);
	if(fuel.max > 0 && fuel.val / fuel.max < 0.1f)
		fuel.val = fuel.max * 0.1f;
}

void BoardTick(Event@ evt, float Troops) {
	if (evt.obj is null) {
		evt.state = ESC_DISABLE;
		return;
	}

	Empire@ owner = evt.obj.getOwner();
	if(owner is null || owner.isValid() == false) {
		evt.state = ESC_DISABLE;
		return;
	}
	
	Object@ target = evt.target;	
	State@ crew = target.getState(strCrew);
	
	Empire@ otherOwner = target.getOwner();
	if(otherOwner is owner) {
		target.repair(evt.time * Troops * troopRepair);
		return;
	}
	
	if(target.hasState(strPDEffectivity)){
		evt.source.system.trigger("PDEffect", evt.target, null, 0, 0);
		float chance = target.getState(strPDEffectivity).val;
		if(randomf(1.f) <= chance)
			return;
	}
	
	if(target.hasState(strShields)){
		float shieldVal = target.getState(strShields).val;
		float shieldMax = target.getState(strShields).max;
		if(shieldVal / shieldMax > 0.5f)
			return;
	}
	
	if(target.hasState(strShieldArmor)){
		float shieldArmorVal = target.getState(strShieldArmor).val;
		float shieldArmorMax = target.getState(strShieldArmor).max;
		if(shieldArmorVal / shieldArmorMax > 0.5f)
			return;
	}
	
	// Troops are killed taking out boarding defenses
	HulledObj@ targ = target;
	float tickTroops = Troops * evt.time;

	if (targ !is null) {
		uint sysCnt = targ.getSubSystemCount();

		for (uint i = 0; i < sysCnt; ++i) {
			SysRef@ ref = targ.getSubSystem(i);

			if (ref.system.type.hasTag(strBoardingDefense)) {
				tickTroops = targ.damageSystem(ref, evt.obj, tickTroops);

				if (tickTroops <= 0.f)
					return;
			}
		}
	}

	if(crew.val <= 0) {
		takeOver(target, owner);

		if (shigatsu)
			target.playSound("boardingparty_41");
	}
	else {
		// Remaining Troops kill crew
		float strength = Troops / crew.val;
		strength = pow(strength, 1.2f);
		
		crew.val -= troopDamage * strength * tickTroops;
		
		if(crew.val <= 0) {
			takeOver(target, owner);

			if (shigatsu)
				target.playSound("boardingparty_41");
		}
	}
}

//I changed the filename to GABoarding.as on 2011/03/06 00:37. Let's see, if it changes back to GAboarding.as.
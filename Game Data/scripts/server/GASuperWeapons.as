const string@ strQuasar = "Quasar", strLastFire = "LastFire", strPower = "Power", strDamage = "Damage", strBridgeCharge="RemnantBridgeCharge";

ObjectFlag objStopHeal = objUser03;

import void dealDamage(Event@ evt, float amount, uint flags) from "Combat";
import void dealDamage(Event@ evt, float amount) from "Combat";

void clearOrders(Object@ obj){
	AIStance old = obj.getStance();
	obj.setStance(AIS_HoldFire);
	obj.setStance(old);

	OrderList orders;
	if(orders.prepare(obj)) {
		orders.clearOrders(true);
		orders.prepare(null);
	}
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////                                     Spatial Generator                                   ////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
float checkSG(const Object@ src, const Object@ trg, const Effector@ eff) {
	// Can Only Fire Once every 10 minutes
	float lastfire = 0.f, tmp = 0.f; 
	src.getStateVals(strLastFire, lastfire, tmp, tmp, tmp);
	if(gameTime - lastfire < 600.f && lastfire > 0.f)
		return 0.f;
		
	return 1.f;
}

void SpatialDmg(Event@ evt) {
	Object@ obj = evt.obj, targ = evt.target;
	System@ sys = targ.getCurrentSystem();
	
	// Clean Up.
	obj.setStateVals(strLastFire, gameTime, 0.f, 0.f, 0.f);		
	clearOrders(obj);		
	
	// Weapon will lock on, but will have no effect as a quasar is exotic (Done this way because I cant check for tag in can fire as it wont work with consts)
	if(sys.hasTag("Quasar")) {
		clearOrders(obj);
		return;
	}

	// Get the HP to deal the damage
	State@ dmg = targ.getState(strDamage);
	float dmgAmount = dmg.max * 0.9f;
	
	uint cnc = rand(100);
	if(cnc > 95) {
		dealDamage(evt, dmg.max+1);
	} else {
		dmg.max = rand(5.00f,100.00f) * 1000.f * 1000.f;
		dmg.val = 0.f;
		targ.radius *= randomf(0.5f, 0.8f);
		sys.addTag("UnstableStar");	
	}
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////                                     Zero Point Generator                                ////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void ZPDrainTrigger(Event@ evt, float Rate) {
	if(evt.target !is null && evt.obj !is null) {
		State@ powFrom = evt.target.getState(strPower);
		float takeAmt = min(Rate, powFrom.val);
		powFrom.val -= takeAmt;	
		
		// Trigger the AoE Effect
		evt.source.system.trigger("ZPAreaDrain", evt.target, null, 0, 0);
	}
}

void ZPDrainTriggered(Event@ evt, float Rate, float AoE_Range) {
	if(evt.target !is null && evt.obj !is null){
		float rangeCheck = evt.target.position.getDistanceFromSQ(evt.obj.position);
		if(rangeCheck < AoE_Range * AoE_Range){	
			State@ powFrom = evt.target.getState(strPower);
			float takeAmt = min(Rate, powFrom.val);
			powFrom.val -= takeAmt;
		}
	}
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////                                     Ion Canon                                           ////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
float checkIC(const Object@ src, const Object@ trg, const Effector@ eff) {
	if(trg.toHulledObj() !is null) {
		const HulledObj@ hulled = trg.toHulledObj();
		
		if(hulled.getHull().scale < 3600)
			return 0.f;
	}
	return 1.f;
}

void IonCannonFire(Event@ evt, float Damage) {
	if(@evt.target != null && @evt.obj != null) {
		dealDamage(evt, Damage);
		clearOrders(evt.obj);			
	}
}
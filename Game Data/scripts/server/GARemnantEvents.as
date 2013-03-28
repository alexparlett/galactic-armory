const string@ strQuasar = "Quasar", strLastFire = "LastFire", strPower = "Power";
const string@ strDamage = "Damage", strBridgeCharge="RemnantBridgeCharge";
const string@ strStargate = "Stargate";

ObjectFlag objStopHeal = objUser03;

import void dealDamage(Event@ evt, float amount, uint flags) from "Combat";
import void dealDamage(Event@ evt, float amount) from "Combat";
import void clearOrders(Object@ obj) from "GATools";
import void doJump(Object@ jumpShip, Object@ jumpTo) from "JumpDrive";


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

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////                                     Jump Bridge                                         ////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void GateJump(Event@ evt) {
	Object@ jumpShip = evt.obj;
	Object@ jumpFrom = evt.target;
	const State@ targetID = jumpFrom.getState(strStargate);
	
	if(@targetID !is null){
		Object@ jumpTo = getObjectByID(targetID.val);
		if (@jumpTo !is null){
			if(jumpTo.isValid()){
				State@ bridgeCharge = evt.target.getState(strBridgeCharge);
				
				print(f_to_s(bridgeCharge.val));
				print(f_to_s(bridgeCharge.max));
				
				if(jumpShip.getMass() < bridgeCharge.val) {
					bridgeCharge.val -= jumpShip.getMass();
					
					jumpShip.velocity = vector(0,0,0);
			
					clearOrders(jumpShip);
					doJump(jumpShip, jumpTo);
					return;
				}
				else {
					jumpShip.getOwner().postMessage("#link:o"+jumpShip.uid+"##c:red#"+jumpShip.getName()+"#c##link#: Aborting stargate jump. End point #link:o"+jumpTo.uid+"##c:red#"+jumpTo.getName()+"#c##link# not enough energy to transport.");
					clearOrders(jumpShip);
					return;
				}
			}
			else{
				jumpShip.getOwner().postMessage("#link:o"+jumpShip.uid+"##c:red#"+jumpShip.getName()+"#c##link#: Aborting stargate jump. End point #link:o"+jumpTo.uid+"##c:red#"+jumpTo.getName()+"#c##link# has invalid hyperspace coordinates.");
				clearOrders(jumpShip);
				return;
			}
		}
		else{
			clearOrders(jumpShip);
			jumpShip.getOwner().postMessage("#link:o"+jumpShip.uid+"##c:red#"+jumpShip.getName()+"#c##link#: Aborting stargate jump. Starting point #link:o"+jumpFrom.uid+"##c:red#"+jumpFrom.getName()+"#c##link# has invalid hyperspace coordinates.");
			return;
		}
	}
	clearOrders(jumpShip);
	jumpShip.getOwner().postMessage("#link:o"+jumpShip.uid+"##c:red#"+jumpShip.getName()+"#c##link#: Aborting stargate jump. #link:o"+jumpFrom.uid+"##c:red#"+jumpFrom.getName()+"#c##link# has invalid hyperspace coordinates.");	
}
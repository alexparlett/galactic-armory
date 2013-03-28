const string@ strFuel = "Fuel";

import void clearOrders(Object@ obj) from "GATools";

float checkRange(const Object@ src, const Object@ trg, const Effector@ eff) {
	//Can only jump to significant sources of gravity
	if(trg.toStar() is null && trg.toPlanet() is null && trg.toSystem() is null)
		return 0.f;

	//Check that it is within range
	float dist = src.getPosition().getDistanceFromSQ(trg.getPosition());
	if(dist < eff[0] * eff[0]) // || dist > eff[1] * eff[1]) //Max range is implied in the effector
		return 0.f;

	return 1.f;
}

float checkFuel(const Object@ src, const Object@ trg, const Effector@ eff) {
	if(!src.hasState(strFuel))
	{
		return 0.f;
	}
	
	const State@ fuel = src.getState(strFuel);
	
	if(fuel.val - eff[4] < fuel.max * 0.05f || fuel.max <= 0)
		return 0.f;
		
	return 1.f;
}

void checkJumpSetting(Event@ evt) {
	if(getGameSetting("GAME_AUTO_JUMP", 0.f) >= 0.5f) {
		if(@evt.target != null && @evt.obj != null) {
			HulledObj@ ship = evt.obj;
			uint cnt = ship.getSubSystemCount();
			for(uint i = 0; i < cnt; i++) {
				subSystem@ sys = ship.getSubSystem(i).system;
				if(sys.type.hasTag("JumpDrive")) {
					triggerAutoJump(evt.obj);
					return;
				}
			}
		}
	}
}

void triggerAutoJump(Object@ obj) {
	Effect AutomatedJumpEvent("AutomatedJumpEvent");	
	obj.addTimedEffect(AutomatedJumpEvent, pow(10, 35), 0.f, obj, null, null, TEF_None);
}

void autoJump(Event@ evt) {
	Object@ obj = evt.target;

	if(obj.getTarget() !is null) {
		Object@ targ = obj.getTarget();

		if(obj.toHulledObj().canUseToolOn("JumpDrive", targ)) {
			OrderList orders;
			if(orders.prepare(obj))
				orders.giveUseToolOrder("JumpDrive", targ, true, true, false);
		}
	}
}

void Jump(Event@ evt, float FuelCost) {
	Object@ jumpShip = evt.obj;
	Object@ jumpTo = evt.target;
	
	State@ fuel = jumpShip.getState(strFuel);
	
	//Checks if the planet or star is in the same system and if not sets the target to the edge of the target system
	if(jumpTo.toPlanet() !is null || jumpTo.toStar() !is null) {
		if(jumpTo.getCurrentSystem() !is jumpShip.getCurrentSystem())
			@jumpTo = jumpTo.getCurrentSystem().toObject();
	}
	
	//Clear Orders, Consume Fuel and do the jump.
	clearOrders(jumpShip);	
	fuel.consume(FuelCost, jumpShip);
	doJump(jumpShip, jumpTo);
	
	evt.state = ESC_DISABLE;
}	

void doJump(Object@ jumpShip, Object@ jumpTo) {	
	//Get the direction and distance to move the ship
	vector toTarg = jumpTo.getPosition() - jumpShip.getPosition();
	float len = toTarg.getLength();
	if(jumpTo.toSystem() !is null)
		len -= jumpShip.radius + (jumpTo.radius - 134.f); //Jump 67 units closer to the target
	else
		len -= jumpShip.radius + jumpTo.radius + 67.f; //Jump 67 units away from the target
	toTarg.normalize(len);

	//Move the ship
	jumpShip.position += toTarg;
	jumpShip.velocity = vector(0, 0, 0);

	//Convince it not to wander off
	jumpShip.setDestination(jumpShip.getPosition());

	//Clear orbiting object so it re-evaluates
	jumpShip.orbitAround(null);

	//Force it to be reparented correctly
	jumpShip.reparent();
	//NOTE: It will take 2 game frames to relocate the ship to the other system
}
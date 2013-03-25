const string@ strFuel = "Fuel", strBridgeCharge = "RemnantBridgeCharge";

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

const string@ strStargate = "Stargate";
float checkStargate(const Object@ src, const Object@ trg, const Effector@ eff) {
	const HulledObj@ stargate = trg;
	if (@stargate !is null){
		const HullLayout@ stargateHull = stargate.getHull();
		if (@stargateHull !is null){
			if(stargateHull.hasSystemWithTag(strStargate)){
				return 1.f;
			}
		}
	}
	return 0.f;
}

float checkStargateJump(const Object@ src, const Object@ trg, const Effector@ eff) {
	const HulledObj@ stargate = trg;
	if (@stargate !is null){
		const HullLayout@ stargateHull = stargate.getHull();
		if (@stargateHull !is null){
			if(stargateHull.hasSystemWithTag(strStargate)) {
				const State@ targetID = trg.getState(strStargate);
				
				if(@targetID !is null){
					const Object@ jumpTo = getObjectByID(targetID.val);
					if (@jumpTo !is null){
						if(jumpTo.isValid()){
							float jumpShipScale = src.radius * src.radius;
							float jumpFromScale = trg.radius * trg.radius;
							float jumpToScale = jumpTo.radius * jumpTo.radius;
							if(jumpShipScale <= jumpFromScale){
								if(jumpShipScale <= jumpToScale){
									return 1.f;
								}
							}
						}
					}
				}
			}
		}
	}
	return 0.f;
}

void createLink(Event@ evt) {
	evt.obj.getState(strStargate).val = evt.target.uid;
	evt.obj.getOwner().postMessage("Hyperspace route established from #link:o"+evt.obj.uid+"##c:red#"+evt.obj.getName()+"#c##link# to #link:o"+evt.target.uid+"##c:red#"+evt.target.getName()+"#c##link#.");	
	clearOrders(evt.obj);
}

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

void clearOrders(Object@ obj){
	AIStance old = obj.getStance();
	obj.setStance(AIS_HoldFire);
	obj.setStance(old);

	OrderList orders;
	if(orders.prepare(obj)) {
		orders.clearOrders(false);
		orders.prepare(null);		
	}
}
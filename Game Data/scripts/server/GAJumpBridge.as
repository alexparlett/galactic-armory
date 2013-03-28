import void clearOrders(Object@ obj) from "GATools";

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

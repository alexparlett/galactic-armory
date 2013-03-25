string@ strHeatsink = "Heatsink", strOverheated = "Overheated";

float CheckEmpire(const Object@ src, const Object@ trg, const Effector@ eff) {
	Empire@ source = src.getOwner();
	Empire@ target = trg.getOwner();
	if(@source == @target)
		return 0.f;
	return 1.f;
}

float CheckMetals(const Object@ src, const Object@ trg, const Effector@ eff) {
	Empire@ source = src.getOwner();
	
	if(source.hasTraitTag("no_bank"))
		return 1.f;
	
	if(@source != null){
		float metalsInBank = source.getStat("Metals");
		if (metalsInBank < eff[1])
			return 0.f;
		else
			return 1.f;
	}
	return 0.f;
}

float CheckAoERangeAsMinRange(const Object@ src, const Object@ trg, const Effector@ eff) {
	float distance = src.getPosition().getDistanceFromSQ(trg.getPosition()) - (src.radius + trg.radius);
	if(distance <= eff[1] * eff[1] * 1.05f) {    //uses aoe_range of effector, which has to be the second paramter!
			return 0.f;
	}
	return 1.f;
}

float CheckArtyAoERangeAsMinRange(const Object@ src, const Object@ trg, const Effector@ eff) {
	float distance = src.getPosition().getDistanceFromSQ(trg.getPosition()) - (src.radius + trg.radius);
	if(distance <= 45.f + (eff[1] * eff[1] * 2.f)) {    //uses aoe_range of effector, which has to be the second paramter!
			return 0.f;
	}
	return 1.f;
}

float minimumRangeTachyonBlaster(const Object@ src, const Object@ trg, const Effector@ eff) {
	float distSQ = src.getPosition().getDistanceFromSQ(trg.getPosition()) - (src.radius + trg.radius);
	
	if(distSQ >= 60.f + (eff.range * eff.range * 0.02f))
		return 1.f;
	else
		return 0.f;
}

float YesDoIt(const Object@ src, const Object@ trg, const Effector@ eff) {
	return 1.f;
}

float hasSlots(const Object@ src, const Object@ trg, const Effector@ eff) {
   const Planet@ pl = trg.toPlanet();
   if (@pl !is null){
      float maxStructs = pl.getMaxStructureCount();
      if(maxStructs > 0)
         return 1.f;
      else
         return 0.f;
   }
   else
      return 0.f;
}

float isNotPlanet(const Object@ src, const Object@ trg, const Effector@ eff) {
   const Planet@ pl = trg.toPlanet();
   if (@pl !is null){
         return 0.f;
   }
   else
      return 1.f;
}

float isStar(const Object@ src, const Object@ trg, const Effector@ eff) {
   const Star@ star = trg.toStar();
   if (@star !is null){
         return 1.f;
   }
   else
      return 0.f;
}

float checkHeat(const Object@ src, const Object@ trg, const Effector@ eff) {
   const State@ overheated = src.getState(strOverheated);
   if (overheated.val >= 1.f){
         return 0.f;
   }
   else
      return 1.f;
}
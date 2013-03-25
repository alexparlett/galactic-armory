enum DamageFlags {
	DF_Kinetic = 1,
	DF_Explosive = 2,
	DF_Energy = 4,
	DF_AoE = 8,
	DF_Particle = 16,
	
	DF_HalfArmorPierce = 128,
	DF_ArmorPiercing = 256,
	DF_ShieldPiercing = 512,
	
	DF_InterceptableByPD = 1024,
	DF_PFW = 2048,
	DF_AntiFighter = 4096,
	DF_NBC = 8192,
	DF_IgnoreDR = 16384,
};

string@ strPower = "Power", strOre = "Ore", strParts = "Parts", strDamage = "Damage", strShields = "Shields", strShieldArmor = "ShieldArmor";
string@ strFuel = "Fuel", strFood = "Food", strMetals = "Metals", strElects = "Electronics", strAdvParts = "AdvParts";
string@ strControl = "Control", strCrew = "Crew", strAmmo = "Ammo", strDamageTimer = "DamageTimer", strShieldArmorCollapseTimer = "ShieldArmorCollapseTimer";
string@ strPDEffectivity = "PDEffectivity", strShieldGen = "ShieldGen", strVAbsorption = "vAbsorption", strShieldTimer="ShieldTimer";
string@ strShieldArmorLowTimer = "ShieldArmorLowTimer", strShieldArmorStatus = "ShieldArmorStatus";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////                                       Basic Stuff                                       ////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void SetTimer(string@ name, Object@ obj, float time) {
	State@ timer = obj.getState(name);
	if (@timer != null)
		timer.val = gameTime + time;
}

bool TimerEnded(string@ name, Object@ obj){
	State@ timer = obj.getState(name);
	if (@timer != null && timer.val - gameTime <= 0.f)
		return true;
		
	return false;
}

void AddPDEffectivity(Event@ evt, float Effectivity){
	State@ pdEffect = evt.obj.getState(strPDEffectivity);
	
	pdEffect.max = min(pdEffect.max + Effectivity, 0.8f);
	pdEffect.val = min(pdEffect.val + Effectivity, 0.8f);
}

void SubPDEffectivity(Event@ evt, float Effectivity){
	if(evt.obj.hasState(strPDEffectivity)){
		State@ pdEffect = evt.obj.getState(strPDEffectivity);
	
		pdEffect.max = max(pdEffect.max - Effectivity, 0.f);
		pdEffect.val = max(pdEffect.val - Effectivity, 0.f);
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////                                           Dodge                                          ////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//Returns the chace of an event occuring within time t
//p should be the chance of the event occuring given t=1
float chanceOverTime(float p, float t) {
	return 1.f-pow(1.f-p,t);
}

//The faster the object is moving relative to its size, the harder it is to hit
void DodgeHitMod(Event@ evt, float HitMod) {
	if(evt.flags & DF_AoE != 0)
		return;

   if (evt.flags & DF_AntiFighter != 0 && randomf(1.f) >= 0.5f){
      return;
   }
   else{
	float dodgeChance = 1.f - HitMod;
	//Better chance for faster acceleration, and larger attacker, and smaller defender
	float chanceMult = min((evt.target.acceleration.getLength() / 5.f) + sqrt(evt.obj.radius) + 1.f - evt.target.radius, 5.f);
	if(chanceMult <= 0.05f)
		return;
	
	if(randomf(1.f) < chanceOverTime(dodgeChance, chanceMult))
		evt.damage = 0.f;
   }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////                                           Armor                                          ////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//Hulls receive some % of all incoming damage, then tweak it up or down based on the overall strength of the hull
void DealHullDamage(Event@ evt, float ReceivePct, float DmgAlter) {

	if(evt.flags & DF_InterceptableByPD != 0){
		if(evt.target.hasState(strPDEffectivity)){
			float chance =  evt.target.getState(strPDEffectivity).max;
			if(randomf(1.f) <= chance)
				evt.damage = 0.f;
			evt.flags ^= DF_InterceptableByPD;  // PD test done once. No further testing needed.
		}
	}

	if(evt.flags & DF_PFW == 0){	
		SysRef@ hull = @evt.dest;
		float damage = min( ReceivePct * evt.damage, hull.HP);

		if(damage > 0) {
			if(evt.flags & DF_IgnoreDR != 0) {
				evt.damage -= damage;
				damage = clamp(damage, 0.f, hull.HP);
				//Check done no further checks necessary
				evt.flags |= DF_IgnoreDR;				
			}
			else {
				evt.damage -= damage;
				damage = clamp(damage + DmgAlter, 0.f, hull.HP);
			}
			hull.HP -= damage;
			SetTimer(strDamageTimer, evt.target, 8.f);
		}
	}
	else
		evt.damage = 0;
}

//Reduces damage taken by Soak, down to a minimum of 20% damage
void SoakDamage(Event@ evt, float Soak) {

	if(evt.flags & DF_InterceptableByPD != 0){
		if(evt.target.hasState(strPDEffectivity)){
			float chance =  evt.target.getState(strPDEffectivity).max;
			if(randomf(1.f) <= chance)
				evt.damage = 0.f;
			evt.flags ^= DF_InterceptableByPD;  // PD test done once. No further testing needed.
		}
	}

	if(evt.flags & DF_ArmorPiercing != 0)
		return;

	SysRef@ dest = evt.dest;
	if(dest is null)
		return;
	
	float deal;
	if(evt.flags & DF_HalfArmorPierce == 0) {
		if(evt.flags & DF_IgnoreDR != 0) {
			deal = min(evt.damage, dest.HP);
			//Check done no further checks necessary
			evt.flags |= DF_IgnoreDR;
		}
		else {
			evt.damage = max(evt.damage - Soak, evt.damage * 0.2f);
			deal = min(evt.damage, dest.HP);
		}
		dest.HP -= deal;
		evt.damage -= deal;		
	}
	else {
		if(evt.flags & DF_IgnoreDR != 0) {
			deal = min(evt.damage * 0.5f, dest.HP);
			//Check done no further checks necessary
			evt.flags |= DF_IgnoreDR;			
		}
		else {
			evt.damage = max(evt.damage - (Soak * 0.5f), evt.damage * 0.4f);
			deal = min(evt.damage * 0.5f, dest.HP);
		}
		dest.HP -= deal;
		evt.damage -= deal;
		evt.flags |= DF_ArmorPiercing;		
	}
	SetTimer(strDamageTimer, evt.target, 8.f);
}

//Any damage in excess of Threshold is reduced down to AbsorbPct of itself (100 dealt, threshold 50, absPct 0.5, deals 75 damage)
void ReactDamage(Event@ evt, float Threshold, float AbsorbPct) {

	if(evt.flags & DF_InterceptableByPD != 0){
		if(evt.target.hasState(strPDEffectivity)){
			float chance =  evt.target.getState(strPDEffectivity).max;
			if(randomf(1.f) <= chance)
				evt.damage = 0.f;
			evt.flags ^= DF_InterceptableByPD;  // PD test done once. No further testing needed.
		}
	}

	if(evt.flags & DF_ArmorPiercing != 0)
		return;
		
			
	if(evt.flags & DF_HalfArmorPierce != 0) {
		evt.flags |= DF_ArmorPiercing;
		if(randomf(1.f) > 0.5f)
			return;
	}

	SysRef@ dest = evt.dest;
	if(dest is null)
		return;
	
	if(evt.flags & DF_IgnoreDR == 0) {
		if(evt.damage > Threshold)
			evt.damage = Threshold + ((evt.damage - Threshold) * AbsorbPct);
	} else {
		//Check done no further checks necessary
		evt.flags |= DF_IgnoreDR;
	}
	
	float deal = min(evt.damage, dest.HP);
	dest.HP -= deal;
	evt.damage -= deal;
	SetTimer(strDamageTimer, evt.target, 8.f);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////                                          Shields                                         ////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//Damage is routed to "Shields"
//For all weapons, shields have a % chance of absorbing the shot based on their % charge (modified by absorbFactor), up to their current charge amount
//For energy/explosive weapons, shields will always let a % of damage through. If the shield fails to block a hit, all further damage passes through.
void ShieldSoak(Event@ evt, float StoreMax, float absorbFactor) {

	if(evt.flags & DF_InterceptableByPD != 0){
		if(evt.target.hasState(strPDEffectivity)){
			float chance =  evt.target.getState(strPDEffectivity).max;
			if(randomf(1.f) <= chance)
				evt.damage = 0.f;
			evt.flags ^= DF_InterceptableByPD;  // PD test done once. No further testing needed.
		}
	}

	if(evt.flags & DF_ShieldPiercing != 0)
		return;
		
	float factor = 1.f;
		
	if (evt.flags & DF_Particle != 0)
		factor += 0.2f;
		
	Object@ obj = evt.target;
	State@ shld = obj.getState(strShields);
	
	if(evt.flags & DF_Kinetic != 0) {		
		//Check to see if we should absorb the shot
		if(randomf(1.f) < clamp((shld.val * absorbFactor) / shld.max, 0.f, 1.f)) {
			float soak = min(evt.damage, shld.val) * factor;
			if(soak > 0) {
				evt.damage -= soak;
				shld.val -= soak;
			}
			else {
				//The shields have collapsed, no further checks are necessary
				evt.flags |= DF_ShieldPiercing;
			}
		}
	}
	else {		
		float shieldStability = clamp((shld.val * absorbFactor) / shld.max, 0.f, 1.f);
		
		float soak = min(evt.damage, shld.val) * shieldStability * factor;
		if(soak > 0) {
			shld.val -= soak;
			evt.damage -= soak;
		}
		else {
			//The shields have collapsed, no further checks are necessary
			evt.flags |= DF_ShieldPiercing;
		}
	}
}

//Shields regen slower the closer to being full they are
void ShieldRegen(Event@ evt, float Rate, float Cost) {
	Object@ obj = evt.obj, targ = evt.target;
	if(Cost > 0) {
		State@ power = obj.getState(strPower), shld = targ.getState(strShields);
		
		if(shld.max <= 0)
			return;
		
		//Rate *= 2 * (1 - (shld.val/shld.max));   //regenerates faster when shields are weaker
		Rate = min(shld.max - shld.val, Rate * evt.time);
		if(Rate > 0) {
			float p = power.getAvailable();
			if(power.max * 0.1f > p)
				return;			
			
			float use  = min(Rate * Cost, p - power.max * 0.1f);
			Rate = use / Cost;

			shld.val += Rate;
			power.consume(use, obj);
		}
	}
	else {
		State@ shld = targ.getState(strShields);
		if(shld.max <= 0)
			return;
		//Rate *= 2 * (1 - (shld.val/shld.max));	//regenerates faster when shields are weaker
		Rate = min(shld.max - shld.val, Rate * evt.time);
		shld.val += Rate;
	}
}

void ShieldArmorSoak(Event@ evt, float StoreMax, float absorbFactor, float collapseTime) {

	if(evt.flags & DF_InterceptableByPD != 0){
		if(evt.target.hasState(strPDEffectivity)){
			float chance =  evt.target.getState(strPDEffectivity).max;
			if(randomf(1.f) <= chance)
				evt.damage = 0.f;
			evt.flags ^= DF_InterceptableByPD;  // PD test done once. No further testing needed.
		}
	}

	if(evt.flags & DF_ShieldPiercing != 0)
		return;
		
	float factor = 1.f;
		
	if (evt.flags & DF_Particle != 0)
		factor += 0.2f;

	Object@ obj = evt.target;
	State@ shldarm = obj.getState(strShieldArmor);
	
	float soak = min(evt.damage, shldarm.val) * clamp((shldarm.val * absorbFactor) / shldarm.max, 0.f, 1.f) * factor;
	if(soak > 0.00001f) {
		shldarm.val -= soak;
		evt.damage -= soak;
		
		State@ shdArmorStatus = obj.getState(strShieldArmorStatus);
		if (@shdArmorStatus != null){
			float shldArmLoad = shldarm.val / shldarm.max;
			if(shdArmorStatus.val == 0){
				if (shldArmLoad <= 0.15f){
					SetTimer(strShieldArmorLowTimer, evt.target, 5.0f);
					shdArmorStatus.val = 1;			//start checking whether shield armor load is below 15% for duration of strShieldArmorLowTimer 
				}
			}
			else{
				if (shldArmLoad > 0.15f){
					shdArmorStatus.val = 0;   		//stop checking shield armor load if load is above 15%
				}
				else if (TimerEnded(strShieldArmorLowTimer, evt.target)){
					shdArmorStatus.val = 0;
					shldarm.val = 0;   				//shield armor collapses after enduring to much damage over time
					evt.flags |= DF_ShieldPiercing;
					SetTimer(strShieldArmorCollapseTimer, evt.target, collapseTime);
				}
			}
		}
	}
	else {
		//The shields have collapsed, no further checks are necessary
		evt.flags |= DF_ShieldPiercing;
		SetTimer(strShieldArmorCollapseTimer, evt.target, collapseTime);
	}	
}

//ShieldArmor regens with constant rate
void ShieldArmorRegen(Event@ evt, float Rate, float Cost) {
	Object@ obj = evt.obj, targ = evt.target;
	
	if (!TimerEnded(strShieldArmorCollapseTimer, targ)){
		return;
	}
		
	if(Cost > 0) {
		State@ power = obj.getState(strPower), shldarm = targ.getState(strShieldArmor);
		
		if(shldarm.max <= 0)
			return;
		
		//Rate *= 2 * (1 - (shldarm.val/shldarm.max));				//regenerates faster when shields are weaker
		Rate = min(shldarm.max - shldarm.val, Rate * evt.time);
		if(Rate > 0) {
			float p = power.getAvailable();
			if(power.max * 0.1f > p)
				return;			
			
			float use  = min(Rate * Cost, p - power.max * 0.1f);
			Rate = use / Cost;

			shldarm.val += Rate;
			power.consume(use, obj);
		}
	}
	else {
		State@ shldarm = targ.getState(strShieldArmor);
		if(shldarm.max <= 0)
			return;
		//Rate *= 2 * (1 - (shldarm.val/shldarm.max));
		Rate = min(shldarm.max - shldarm.val, Rate * evt.time);
		shldarm.val += Rate;
	}
}
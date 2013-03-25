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

import void dealDamage(Event@ evt, float amount, uint flags) from "Combat";
import void dealDamage(Event@ evt, float amount) from "Combat";

string@ strPower = "Power", strOre = "Ore", strParts = "Parts", strDamage = "Damage", strShields = "Shields", strShieldArmor = "ShieldArmor";
string@ strFuel = "Fuel", strFood = "Food", strMetals = "Metals", strElects = "Electronics", strAdvParts = "AdvParts";
string@ strControl = "Control", strCrew = "Crew", strAmmo = "Ammo", strDamageTimer = "DamageTimer", strVisibility = "VisibilityTimer";
string@ strPDEffectivity = "PDEffectivity", strHeatsink = "Heatsink", strOverheated = "Overheated", strH3 = "H3";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////                                       Basic Stuff                                       ////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//Does not work (yet)
void SetVisible(Event@ evt, float VisibleTime){
	if(VisibleTime > 0.f){
		//print("SetVisibleTimer" + gameTime);
		//bool visible = evt.obj.getGlobalVisibility();
		//if(visible)
		//	print("visible");
		//else if(!visible)
		//	print("invisible");
		evt.obj.setGlobalVisibility(true);
		//visible = evt.obj.getGlobalVisibility();		
		//if(visible)
		//	print("visible");
		//else if(!visible)
		//	print("invisible");
		
		State@ visibilityTimer = evt.obj.getState(strVisibility);
		if (@visibilityTimer != null){
			visibilityTimer.val = gameTime + VisibleTime;
		}
	}
}

float rangeMod(Event@ evt, float Range, float effectiveRange, float minimum){
	if(@evt.target != null && @evt.obj != null){
		float Distance = evt.target.position.getDistanceFrom(evt.obj.position);
		if(Distance <= effectiveRange) {
			//print("Range: " + Range + " Distance: " + Distance + " effectiveRange: " + effectiveRange + " minimum: " + minimum);
			//print("return chance: " + 1.f);
			return 1.f;
		}
		else
		{
			//print("Range: " + Range + " Distance: " + Distance + " effectiveRange: " + effectiveRange + " minimum: " + minimum);
			//print("Range - Distance: " + (Range - Distance) + " Range - effectiveRange: " + (Range - effectiveRange) + " division: " + (Range - Distance) / (Range - effectiveRange));
			//print("return chance: " + max((Range - Distance) / (Range - effectiveRange), minimum));
			if(Range > effectiveRange)
				return max(0.f,min((Range - Distance) / (Range - effectiveRange), minimum));
			else
				return 1.f;
		}
	}
	return 1.f;
}

bool handleHeat(Event@ evt, float wasteHeat){

	if(wasteHeat == 0)
		return true;

	State@ heatsink = evt.obj.getState(strHeatsink);
	State@ overheated = evt.obj.getState(strOverheated);
		
	if(@overheated != null && overheated.val >= 1.f)
		return false;
		
	if (@heatsink != null && heatsink.val < heatsink.max){
		//if(heatsink.max - heatsink.val >= wasteHeat)
		//	heatsink.val += wasteHeat;
		//else
		//	heatsink.val += heatsink.max - heatsink.val;
		heatsink.val += wasteHeat;
		if(heatsink.val >= heatsink.max)
			overheated.val = 1.f;
		return true;
	}
	else
		return false;
}

bool handleHeatDuration(Event@ evt, float wasteHeat){

	if(wasteHeat == 0)
		return true;

	State@ heatsink = evt.obj.getState(strHeatsink);
	State@ overheated = evt.obj.getState(strOverheated);
		
	if(@overheated != null && overheated.val >= 1.f)
		return false;
		
	if (@heatsink != null && heatsink.val < heatsink.max){
		//if(heatsink.max - heatsink.val >= wasteHeat)
		//	heatsink.val += wasteHeat;
		//else
		//	heatsink.val += heatsink.max - heatsink.val;
		heatsink.val += wasteHeat * evt.time;
		if(heatsink.val >= heatsink.max)
			overheated.val = 1.f;
		return true;
	}
	else
		return false;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////                                       Direct Hit                                        ////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void EnergyDamageInstant(Event@ evt, float Damage, float Cost, float Range, float effectiveRangeFactor, float minDamage, float wasteHeat) {
	Object@ targ = evt.target;
	if(@targ != null && @evt.obj != null) {
	
		if(!handleHeat(evt, wasteHeat))
			return;
	
		if(Cost > 0) {
			float tickCost = Cost;
			State@ power = evt.obj.getState(strPower);
			float fireDuration = min(power.getAvailable() / tickCost, 1.f);
			if(fireDuration > 0) {
				power.val -= Cost * fireDuration;
				dealDamage(evt, Damage * fireDuration * rangeMod(evt, Range, Range * effectiveRangeFactor, minDamage), DF_Energy);
			}
			else {
				evt.state = ESC_DISABLE;
			}
		}
		else {
			dealDamage(evt, Damage * rangeMod(evt, Range, Range * effectiveRangeFactor, minDamage), DF_Energy);
		}
	}
}

void EnergyDamage(Event@ evt, float Damage, float Cost, float Range, float effectiveRangeFactor, float minDamage, float wasteHeat) {
	Object@ targ = evt.target;
	if(@targ != null && @evt.obj != null) {
		
		//print(evt.source.system.type.getName() + ": " + evt.time);
	
		if(!handleHeatDuration(evt, wasteHeat))
			return;
	
		if(Cost > 0) {
			float tickCost = Cost * evt.time;
			State@ power = evt.obj.getState(strPower);
			float fireDuration = min(power.getAvailable() / tickCost, evt.time);
			if(fireDuration > 0) {
				power.val -= Cost * fireDuration;
				dealDamage(evt, Damage * fireDuration * rangeMod(evt, Range, Range * effectiveRangeFactor, minDamage), DF_Energy);
			}
			else {
				evt.state = ESC_DISABLE;
			}
		}
		else {
			dealDamage(evt, Damage * evt.time * rangeMod(evt, Range, Range * effectiveRangeFactor, minDamage), DF_Energy);
		}
	}
}

void MegaEnergyDamage(Event@ evt, float Damage, float Cost, float wasteHeat) {
	Object@ targ = evt.target;
	if(@targ != null && @evt.obj != null) {
	
		if(!handleHeatDuration(evt, wasteHeat))
			return;
	
		if(Cost > 0) {		
			float tickCost = Cost * evt.time;
			State@ pow = evt.obj.getState(strPower);
			float fireDuration = min(pow.getAvailable() / tickCost, evt.time);
			if(fireDuration > 0) {
				pow.val -= Cost * fireDuration;
				dealDamage(evt, Damage * fireDuration, DF_Energy);
			}
			else {
				evt.state = ESC_DISABLE;
			}
		}
		else {
			dealDamage(evt, Damage * evt.time, DF_Energy);
		}
	}
}

void EnergyDamageCrit(Event@ evt, float Damage, float Cost, float Range, float effectiveRangeFactor, float minDamage, float wasteHeat) {
	Object@ targ = evt.target;
	if(@targ != null && @evt.obj != null) {
		
		if(!handleHeatDuration(evt, wasteHeat))
			return;
	
		//if(randomf(1.f) <= critChance)
		if(randomf(1.f) <= 0.05f)
			Damage = Damage * 2.5f;
	
		if(Cost > 0) {
			float tickCost = Cost * evt.time;
			State@ power = evt.obj.getState(strPower);
			float fireDuration = min(power.getAvailable() / tickCost, evt.time);
			if(fireDuration > 0) {
				power.val -= Cost * fireDuration;
				dealDamage(evt, Damage * fireDuration * rangeMod(evt, Range, Range * effectiveRangeFactor, minDamage), DF_Energy);
			}
			else {
				evt.state = ESC_DISABLE;
			}
		}
		else {
			dealDamage(evt, Damage * evt.time * rangeMod(evt, Range, Range * effectiveRangeFactor, minDamage), DF_Energy);
		}
	}
}

void PhasedMissileDmg(Event@ evt, float Damage) {
	Object@ targ = evt.target;
	if(@targ != null && @evt.obj != null) {		
		if(evt.target.hasState(strPDEffectivity)){
			evt.source.system.trigger("PDEffect", evt.target, null, 0, 0);
		}
		if(targ.hasState(strShields)) {
			State@ shld = targ.getState(strShields);		
			if(shld.val <= shld.max * 0.5) {
				evt.target.playSound("impact_explosive");
				dealDamage(evt, Damage, DF_Explosive | DF_ArmorPiercing);	
			}
			else {
				evt.state = ESC_DISABLE;
			}
		}
		else if(targ.hasState(strShieldArmor)) {
			State@ shldArm = targ.getState(strShieldArmor);		
			if(shldArm.val <= shldArm.max * 0.5) {
				evt.target.playSound("impact_explosive");
				dealDamage(evt, Damage, DF_Explosive | DF_ArmorPiercing);	
			}
			else {
				evt.state = ESC_DISABLE;
			}		
		} 
		else { 
			evt.target.playSound("impact_explosive");
			dealDamage(evt, Damage, DF_Explosive | DF_ArmorPiercing);
		}
	}
}

//Energy Damage that pierces armor
void PhasedDamage(Event@ evt, float Damage, float Cost, float Range, float effectiveRangeFactor, float minDamage, float wasteHeat) {
	Object@ targ = evt.target;
	if(@targ != null && @evt.obj != null) {
	
		if(!handleHeatDuration(evt, wasteHeat))
			return;
	
		if(Cost > 0) {
			float tickCost = Cost * evt.time;
			State@ power = evt.obj.getState(strPower);
			float fireDuration = min(power.getAvailable() / tickCost, evt.time);
			if(fireDuration > 0) {
				power.val -= Cost * fireDuration;
				dealDamage(evt, Damage * fireDuration * rangeMod(evt, Range, Range * effectiveRangeFactor, minDamage), DF_Energy | DF_ArmorPiercing);
			}
			else {
				evt.state = ESC_DISABLE;
			}
		}
		else {
			dealDamage(evt, Damage * evt.time * rangeMod(evt, Range, Range * effectiveRangeFactor, minDamage), DF_Energy | DF_ArmorPiercing);
		}
	}
}

void TeraTorpedoDmg(Event@ evt, float Damage) {
	Object@ targ = evt.target;
	if(@targ != null && @evt.obj != null) {
		if(evt.target.hasState(strPDEffectivity)){
			evt.source.system.trigger("PDEffect", evt.target, null, 0, 0);
		}	
		evt.target.playSound("impact_explosive");
		dealDamage(evt, Damage, DF_Explosive | DF_ShieldPiercing);
	}
}

//Energy Damage that pierces shields
void TRayBombDamage(Event@ evt, float Damage) {
	Object@ targ = evt.target;
	if(@targ != null && @evt.obj != null) {
		evt.target.playSound("impact_explosive");
		dealDamage(evt, Damage * evt.time, DF_Energy | DF_ShieldPiercing);
	}
}

//Energy Damage that pierces shields
void TRayDamage(Event@ evt, float Damage, float Cost, float Range, float effectiveRangeFactor, float minDamage, float wasteHeat) {
	Object@ targ = evt.target;
	if(@targ != null && @evt.obj != null) {
	
		if(!handleHeatDuration(evt, wasteHeat))
			return;
	
		if(Cost > 0) {
			float tickCost = Cost * evt.time;
			State@ power = evt.obj.getState(strPower);
			float fireDuration = min(power.getAvailable() / tickCost, evt.time);
			if(fireDuration > 0) {
				power.val -= Cost * fireDuration;
				dealDamage(evt, Damage * fireDuration * rangeMod(evt, Range, Range * effectiveRangeFactor, minDamage), DF_Energy | DF_ShieldPiercing);
			}
			else {
				evt.state = ESC_DISABLE;
			}
		}
		else {
			dealDamage(evt, Damage * evt.time * rangeMod(evt, Range, Range * effectiveRangeFactor, minDamage), DF_Energy | DF_ShieldPiercing);
		}
	}
}

void ParticleEnergyDamage(Event@ evt, float Damage, float Cost, float Range, float effectiveRangeFactor, float minDamage, float wasteHeat) {
	Object@ targ = evt.target;
	if(@targ != null && @evt.obj != null) {
	
		if(!handleHeatDuration(evt, wasteHeat))
			return;
	
		if(Cost > 0) {
			float tickCost = Cost * evt.time;
			State@ power = evt.obj.getState(strPower);
			float fireDuration = min(power.getAvailable() / tickCost, evt.time);
			if(fireDuration > 0) {
				power.val -= Cost * fireDuration;
				dealDamage(evt, Damage * fireDuration * rangeMod(evt, Range, Range * effectiveRangeFactor, minDamage), DF_Energy | DF_Particle);
			}
			else {
				evt.state = ESC_DISABLE;
			}
		}
		else {
			dealDamage(evt, Damage * evt.time * rangeMod(evt, Range, Range * effectiveRangeFactor, minDamage), DF_Energy | DF_Particle);
		}
	}
}

//These two functions manage the instant hit and damage-over-time of the plasma weapon
void PlasmaFrontDamage(Event@ evt, float FrontDamage, float DoTDamage, float Range, float effectiveRangeFactor, float minDamage, float wasteHeat) {
	if(@evt.target != null && @evt.obj != null)
	
		if(!handleHeat(evt, wasteHeat))
			return;
	
		evt.target.damage(evt.obj, FrontDamage * rangeMod(evt, Range, Range * effectiveRangeFactor, minDamage), DF_Energy);
}

void PlasmaDoTDamage(Event@ evt, float FrontDamage, float DoTDamage, float Range, float effectiveRangeFactor, float minDamage, float wasteHeat) {
	if(@evt.target != null && @evt.obj != null)
		evt.target.damage(evt.obj, DoTDamage * evt.time, DF_Energy);
}

void ParticleDamage(Event@ evt, float Damage, float Range, float effectiveRangeFactor, float minDamage, float minHitChance, float wasteHeat) {
	float hitchance = rangeMod(evt, Range, Range * effectiveRangeFactor, minHitChance);
	
	if(@evt.target != null && @evt.obj != null) {
	
		if(!handleHeat(evt, wasteHeat))
			return;
	
		if(randomf(1.f) <= hitchance) {
			evt.target.playSound("impact_particle");
			dealDamage(evt, Damage * rangeMod(evt, Range, Range * effectiveRangeFactor, minDamage), DF_Particle);
		}
	}
}

void WaveDamage(Event@ evt, float Damage, float Range, float effectiveRangeFactor, float minDamage, float minHitChance, float wasteHeat) {
	float hitchance = rangeMod(evt, Range, Range * effectiveRangeFactor, minHitChance);
	
	if(@evt.target != null && @evt.obj != null) {
	
		if(!handleHeat(evt, wasteHeat))
			return;
	
		if(randomf(1.f) <= hitchance) {
			evt.target.playSound("impact_plasma");
			dealDamage(evt, Damage * rangeMod(evt, Range, Range * effectiveRangeFactor, minDamage), DF_IgnoreDR);
		}
	}
}

void DoT(Event@ evt, float Damage, float Range, float effectiveRangeFactor, float minDamage, float minHitChance, float wasteHeat) {
	float hitchance = rangeMod(evt, Range, Range * effectiveRangeFactor, minHitChance);
	
	if(@evt.target != null && @evt.obj != null) {
	
		if(!handleHeatDuration(evt, wasteHeat))
			return;
	
		if(randomf(1.f) <= hitchance) {
			evt.target.playSound("impact_plasma");
			dealDamage(evt, Damage * evt.time * rangeMod(evt, Range, Range * effectiveRangeFactor, minDamage));
		}
	}
}

void NaniteDoT(Event@ evt, float Damage) {
	if(@evt.target != null && @evt.obj != null){
		if(evt.target.hasState(strPDEffectivity))
			evt.source.system.trigger("PDEffect", evt.target, null, 0, 0);
		
		evt.target.playSound("impact_explosive");
		dealDamage(evt, Damage * evt.time, DF_InterceptableByPD);
	}
}

void PFWDamage(Event@ evt, float Damage, float Cost, float wasteHeat) {
	Object@ targ = evt.target;
	if(@targ != null && @evt.obj != null) {
	
		if(!handleHeatDuration(evt, wasteHeat))
			return;
	
		if(Cost > 0) {
			float tickCost = Cost * evt.time;
			State@ power = evt.obj.getState(strPower);
			float fireDuration = min(power.getAvailable() / tickCost, evt.time);
			if(fireDuration > 0) {
				power.val -= Cost * fireDuration;

				dealDamage(evt, Damage * fireDuration, DF_Energy | DF_PFW | DF_ArmorPiercing);

			}	
			else {
				evt.state = ESC_DISABLE;
			}
		}
		else {
			dealDamage(evt, Damage * evt.time, DF_Energy | DF_PFW | DF_ArmorPiercing);

		}
	}
}

void AntiFighterDamage(Event@ evt, float Damage, float Cost) {
	Object@ targ = evt.target;
	if(@targ != null && @evt.obj != null) {
	
		if(evt.target.hasState(strPDEffectivity)){
			evt.source.system.trigger("PDEffect", evt.target, null, 0, 0);
		}

		State@ ammo = evt.obj.getState(strAmmo);
		if(ammo.getAvailable() >= Cost) {
			ammo.val -= Cost;
			evt.target.playSound("impact_explosive");
			dealDamage(evt, Damage, DF_AntiFighter | DF_InterceptableByPD);
		}
		else {
			evt.state = ESC_DISABLE;
		}
	}
}

void ProjWeaponDamage(Event@ evt, float Damage) {
	if(@evt.target != null && @evt.obj != null) {
		if(evt.target.hasState(strPDEffectivity)){
			evt.source.system.trigger("PDEffect", evt.target, null, 0, 0);
		}
		evt.target.playSound("impact_explosive");
		dealDamage(evt, Damage, DF_InterceptableByPD);
	}
}

void LargeBombDamage(Event@ evt, float Damage) {
	if(@evt.target != null && @evt.obj != null) {
		evt.target.playSound("impact_large_bomb");
		dealDamage(evt, Damage, DF_Explosive);
	}
}

void ProjDamage(Event@ evt, float Damage, float Range, float effectiveRangeFactor, float minHitChance) {
	
	float hitchance = rangeMod(evt, Range, Range * effectiveRangeFactor, minHitChance);
	
	if(@evt.target != null && @evt.obj != null) {
		if(randomf(1.f) <= hitchance) {
			evt.target.playSound("impact_kinetic");
			dealDamage(evt, Damage, DF_Kinetic);
		}
	}
}

void ProjPierceDamage(Event@ evt, float Damage, float Range, float effectiveRangeFactor, float minHitChance) {

	float hitchance = rangeMod(evt, Range, Range * effectiveRangeFactor, minHitChance);

	if(@evt.target != null && @evt.obj != null)
		if(randomf(1.f) <= hitchance)
			evt.target.playSound("impact_kinetic");
			dealDamage(evt, Damage, DF_Kinetic + DF_HalfArmorPierce);
}

void ArmorPiercingDamage(Event@ evt, float Damage, float Range, float effectiveRangeFactor, float minHitChance) {
	
	float hitchance = rangeMod(evt, Range, Range * effectiveRangeFactor, minHitChance);
	
	if(@evt.target != null && @evt.obj != null) {
		if(randomf(1.f) <= hitchance) {
			evt.target.playSound("impact_kinetic");
			dealDamage(evt, Damage, DF_Kinetic | DF_ArmorPiercing);
		}
	}
}

float GAPersonPerDamage = 1000.f;
void NBCDamage(Event@ evt, float Damage) {
	Planet@ targ = evt.target.toPlanet();
	if(@targ != null) {
		float canKillPpl = min(targ.getPopulation(), Damage * evt.time * randomf(GAPersonPerDamage)); //Will randomly damage between 0 and PersonPerDamage people per damage point
		targ.modPopulation(canKillPpl * -1.f);
	}
}

void LongRangeLaserDamage(Event@ evt, float Damage, float Cost, float VisibleTime) {
	Object@ targ = evt.target;
	if(@targ != null && @evt.obj != null) {
		if(Cost > 0) {
			float tickCost = Cost * evt.time;
			State@ power = evt.obj.getState(strPower);
			float fireDuration = min(power.getAvailable() / tickCost, evt.time);
			if(fireDuration > 0) {
				power.val -= Cost * fireDuration;
				dealDamage(evt, Damage * fireDuration, DF_Energy);
				
				SetVisible(@evt, VisibleTime);
			}
			else {
				evt.state = ESC_DISABLE;
			}
		}
		else {
			dealDamage(evt, Damage * evt.time, DF_Energy);
			
			SetVisible(@evt, VisibleTime);
		}
	}
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////                                     Area of Effect                                      ////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void AreaDamageTrigger(Event@ evt, float Damage) {	
	if(@evt.target != null && @evt.obj != null){
		evt.target.playSound("impact_artillery");
		dealDamage(evt, Damage);
		evt.source.system.trigger("AreaDamage", evt.target, null, 0, 0);
	}
}

void AreaDamageTriggerHeat(Event@ evt, float Damage, float wasteHeat) {	
	if(@evt.target != null && @evt.obj != null){
	
		if(!handleHeat(evt, wasteHeat))
			return;
	
		dealDamage(evt, Damage);
		evt.source.system.trigger("AreaDamage", evt.target, null, 0, 0);
	}
}

void AreaDamageTriggered(Event@ evt, float AoE_Damage, float AoE_Range) {
	if(@evt.target != null && @evt.obj != null){
		float rangeCheck = evt.target.position.getDistanceFromSQ(evt.obj.position);
		if(rangeCheck < AoE_Range * AoE_Range){
			dealDamage(evt, AoE_Damage * (1 - (rangeCheck / (AoE_Range * AoE_Range))));
		}
	}
}

void ParticleAreaDamageTriggerHeat(Event@ evt, float Damage, float wasteHeat) {	
	if(@evt.target != null && @evt.obj != null){
	
		if(!handleHeat(evt, wasteHeat))
			return;
	
		dealDamage(evt, Damage, DF_Particle);
		evt.source.system.trigger("ParticleAreaDamage", evt.target, null, 0, 0);
	}
}

void ParticleAreaDamageTriggered(Event@ evt, float AoE_Damage, float AoE_Range) {
	if(@evt.target != null && @evt.obj != null){
		float rangeCheck = evt.target.position.getDistanceFromSQ(evt.obj.position);
		if(rangeCheck < AoE_Range * AoE_Range){
			dealDamage(evt, AoE_Damage * (1 - (rangeCheck / (AoE_Range * AoE_Range))), DF_Particle);
		}
	}
}

void PFWAreaDamageTrigger(Event@ evt, float Damage) {
	if(@evt.target != null && @evt.obj != null){
		evt.target.playSound("impact_particle");
		dealDamage(evt, Damage, DF_Energy | DF_PFW | DF_ArmorPiercing);
		evt.source.system.trigger("PFWAreaDamage", evt.target, null, 0, 0);
	}
}

void PFWAreaDamageTriggered(Event@ evt, float AoE_Damage, float AoE_Range) {
	if(@evt.target != null && @evt.obj != null){
		float rangeCheck = evt.target.position.getDistanceFromSQ(evt.obj.position);
		if(rangeCheck < AoE_Range * AoE_Range)
			dealDamage(evt, AoE_Damage * (1 - (rangeCheck / (AoE_Range * AoE_Range))), DF_Energy | DF_PFW | DF_ArmorPiercing);
	}
}

void EMPAreaDamageTrigger(Event@ evt, float Damage) {
	if(@evt.target != null && @evt.obj != null){
		if(evt.target.hasState(strPDEffectivity)){
			evt.source.system.trigger("PDEffect", evt.target, null, 0, 0);
		}	
		evt.target.playSound("impact_particle");
		dealDamage(evt, Damage, DF_Energy | DF_PFW | DF_ArmorPiercing);
		evt.source.system.trigger("EMPAreaDamage", evt.target, null, 0, 0);
	}
}

void EMPAreaDamageTriggered(Event@ evt, float Damage, float AoE_Range) {
	if(@evt.target != null && @evt.obj != null){
		float rangeCheck = evt.target.position.getDistanceFromSQ(evt.obj.position);
		if(rangeCheck < AoE_Range * AoE_Range)
			dealDamage(evt, Damage, DF_Energy | DF_PFW | DF_ArmorPiercing);
	}
}

void HeliocideDmg(Event@ evt, float Damage, float Cost) {
	Object@ targ = evt.target, obj = evt.obj;
	if(@targ != null) {
		if(Cost > 0) {
			float tickCost = Cost * evt.time;
			State@ pow = obj.getState(strPower);
			State@ h3 = obj.getState(strH3);
			float fireDuration = min(pow.getAvailable() / tickCost, evt.time);
			float h3Cost = Cost / 100;
			if(h3.getAvailable() < h3Cost)
				fireDuration = 0;
			if(fireDuration > 0) {
				pow.val -= Cost * fireDuration;
				h3.val -= h3Cost * fireDuration;
				dealDamage(evt, Damage * fireDuration, DF_Energy);
			}
			else {
				evt.state = ESC_DISABLE;
			}
		}
		else {
			evt.state = ESC_DISABLE;
		}
	}
}

//void AreaDamage(Event@ evt, float AoE_Damage, float AoE_Range) {
//	Object@ obj = evt.obj;
//	Empire@ owner = obj.getOwner();
//	SysObjList objects;
//	if (@evt.obj.getParent().toSystem() != null) {
//		objects.prepare(evt.obj.getParent().toSystem());
//		for(uint i = 0; i < objects.childCount; ++i) {
//			Object@ trg = objects.getChild(i);
//			if(@trg != @obj) {    // do not do damage, when target is equal to ship, that fired
//				Empire@ otherOwner = trg.getOwner();
//				float RangeCheck = evt.target.position.getDistanceFromSQ(trg.position);
//				if(RangeCheck < AoE_Range * AoE_Range) {
//					if(otherOwner is owner) {
//						trg.damage(evt.obj, (AoE_Damage / 5) * (1 - (RangeCheck / (AoE_Range * AoE_Range))));
//					}
//					else {
//						trg.damage(evt.obj, AoE_Damage * (1 - (RangeCheck / (AoE_Range * AoE_Range))));
//					}
//				}
//			}
//		}
//	}
//}
//
//void PFWAreaDamage(Event@ evt, float AoE_Damage, float AoE_Range) {
//	Object@ obj = evt.obj;
//	Empire@ owner = obj.getOwner();
//	SysObjList objects;
//	if (@evt.obj.getParent().toSystem() != null){
//		objects.prepare(evt.obj.getParent().toSystem());
//		for(uint i = 0; i < objects.childCount; ++i) {
//			Object@ trg = objects.getChild(i);
//			if(@trg != @obj) {    // do not do damage, when target is equal to ship, that fired
//				Empire@ otherOwner = trg.getOwner();
//				float RangeCheck = evt.target.position.getDistanceFromSQ(trg.position);
//				if(RangeCheck < AoE_Range * AoE_Range) {
//					if(otherOwner is owner) {
//						trg.damage(evt.obj, (AoE_Damage / 5) * (1 - (RangeCheck / (AoE_Range * AoE_Range))), DF_Energy | DF_PFW | DF_ArmorPiercing);
//					}
//					else {
//						trg.damage(evt.obj, AoE_Damage * (1 - (RangeCheck / (AoE_Range * AoE_Range))), DF_Energy | DF_PFW | DF_ArmorPiercing);
//					}
//				}
//			}
//		}
//	}
//}

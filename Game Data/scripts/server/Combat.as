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


string@ strPower = "Power", strOre = "Ore", strParts = "Parts", strDamage = "Damage", strShields = "Shields";
string@ strFuel = "Fuel", strFood = "Food", strMetals = "Metals", strElects = "Electronics", strAdvParts = "AdvParts";
string@ strControl = "Control", strCrew = "Crew", strAmmo = "Ammo", strTerraform = "Terraform";

float minimumRange(const Object@ from, const Object@ to, const Effector@ eff) {
	float distSQ = from.getPosition().getDistanceFromSQ(to.getPosition()) - (from.radius + to.radius);
	float range = eff.range * 0.1f;
	
	if(distSQ >= range * range)
		return 1.f;
	else
		return 0.f;
}

//Returns the chace of an event occuring within time t
//p should be the chance of the event occuring given t=1
float chanceOverTime(float p, float t) {
	return 1.f-pow(1.f-p,t);
}

//If a random number 0-1 is greater than HitMod, negate all damage
//HitMod should be expressed as a chance, less than 100%, to hit
void HitMod(Event@ evt, float HitMod) {
	if(evt.flags & DF_AoE != 0)
		return;
	if(randomf(1.f) > HitMod)
		evt.damage = 0.f;
}

//The faster the object is moving relative to its size, the harder it is to hit
void DodgeHitMod(Event@ evt, float HitMod) {
	if(evt.flags & DF_AoE != 0)
		return;
	
	float dodgeChance = 1.f - HitMod;
	//Better chance for faster acceleration, and larger attacker, and smaller defender
	float chanceMult = min((evt.target.acceleration.getLength() / 5.f) + sqrt(evt.obj.radius) + 1.f - evt.target.radius, 5.f);
	if(chanceMult <= 0.05f)
		return;
	
	if(randomf(1.f) < chanceOverTime(dodgeChance, chanceMult))
		evt.damage = 0.f;
}

float PersonPerDamage = 1000.f;
void DmgToPpl(Event@ evt, float Housing) {
	Planet@ pl = evt.target.toPlanet();
	if(@pl != null) {
		float canKillPpl = min(pl.getPopulation(), evt.damage * randomf(PersonPerDamage)); //Will randomly damage between 0 and PersonPerDamage people per damage point
		evt.damage -= canKillPpl / PersonPerDamage;
		pl.modPopulation(canKillPpl * -1.f);
	}
}

//Hulls receive some % of all incoming damage, then tweak it up or down based on the overall strength of the hull
void DealHullDamage(Event@ evt, float ReceivePct, float DmgAlter) {
	SysRef@ hull = @evt.dest;
	float damage = min( ReceivePct * evt.damage, hull.HP);
	if(damage > 0) {
		evt.damage -= damage;
		
		damage = clamp(damage + DmgAlter, 0.f, hull.HP);
		hull.HP -= damage;
	}
}

//Reduces damage taken by Soak, down to a minimum of 20% damage
void SoakDamage(Event@ evt, float Soak) {
	if(evt.flags & DF_ArmorPiercing != 0)
		return;

	SysRef@ dest = evt.dest;
	if(dest is null)
		return;
	
	if(evt.flags & DF_HalfArmorPierce == 0) {
		evt.damage = max(evt.damage - Soak, evt.damage * 0.2f);
		float deal = min(evt.damage, dest.HP);
		dest.HP -= deal;
		evt.damage -= deal;
	}
	else {
		evt.damage = max(evt.damage - (Soak * 0.5f), evt.damage * 0.4f);
		float deal = min(evt.damage * 0.5f, dest.HP);
		dest.HP -= deal;
		evt.damage -= deal;
		evt.flags |= DF_ArmorPiercing;
	}
	
}

//Any damage in excess of Threshold is reduced down to AbsorbPct of itself (100 dealt, threshold 50, absPct 0.5, deals 75 damage)
void ReactDamage(Event@ evt, float Threshold, float AbsorbPct) {
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
	
	if(evt.damage > Threshold)
		evt.damage = Threshold + ((evt.damage - Threshold) * AbsorbPct);
	
	float deal = min(evt.damage, dest.HP);
	dest.HP -= deal;
	evt.damage -= deal;
}

//Damage is routed to "Shields"
//For all weapons, shields have a % chance of absorbing the shot based on their % charge (modified by absorbFactor), up to their current charge amount
//For energy/explosive weapons, shields will always let a % of damage through. If the shield fails to block a hit, all further damage passes through.
void ShieldSoak(Event@ evt, float StoreMax, float absorbFactor) {
	if(evt.flags & DF_ShieldPiercing != 0)
		return;

	if(evt.flags & DF_Kinetic != 0) {
		Object@ obj = evt.target;
		State@ shld = obj.getState(strShields);
		
		//Check to see if we should absorb the shot
		if(randomf(1.f) < clamp((shld.val * absorbFactor) / shld.max, 0.f, 1.f)) {
			float soak = min(evt.damage, shld.val);
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
		Object@ obj = evt.target;
		State@ shld = obj.getState(strShields);
		
		float shieldStability = clamp((shld.val * absorbFactor) / shld.max, 0.f, 1.f);
		
		float soak = min(evt.damage, shld.val) * shieldStability;
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

//Redirects all damage to the linked system
void RedirectDamage(Event@ evt) {
	HulledObj@ targ = evt.target;
	SysRef@ linked = evt.dest.getLinked(targ);
	evt.damage = targ.damageSystem(linked, evt.obj, evt.damage);
}

//Destroys link if external mount is destroyed
void DestroyLinked(Event@ evt) {
	HulledObj@ targ = evt.target;
	SysRef@ linked = evt.dest.getLinked(targ);
	
	float dmg = linked.HP;
	evt.damage = targ.damageSystem(linked, evt.obj, dmg);
}

//Shields regen slower the closer to being full they are
void ShieldRegen(Event@ evt, float Rate, float Cost) {
	Object@ obj = evt.obj, targ = evt.target;
	if(Cost > 0) {
		State@ pow = obj.getState(strPower), shld = targ.getState(strShields);
		
		if(shld.max <= 0)
			return;
		
		Rate *= 2 * (1 - (shld.val/shld.max));
		Rate = min(shld.max - shld.val, Rate * evt.time);
		if(Rate > 0) {
			float p = pow.getAvailable();
			float use = Rate * Cost;
			if(use <= p) {
				shld.val += Rate;
				pow.consume(use, obj);
			}
			else {
				shld.val += p / Cost;
				pow.consume(p, obj);
			}
		}
	}
	else {
		State@ shld = targ.getState(strShields);
		if(shld.max <= 0)
			return;
		Rate *= 2 * (1 - (shld.val/shld.max));
		Rate = min(shld.max - shld.val, Rate * evt.time);
		shld.val += Rate;
	}
}

void healMyDamage(Event@ evt, float rate, float maxhp) {
	SysRef@ sys = evt.dest;
	if(sys is null)
		return;
	if(sys.HP < maxhp) {
		sys.HP += evt.time * rate;
		if(sys.HP >= maxhp)
			sys.HP = maxhp;
	}
}

ObjectFlag objPDamage = objUser01;
void dealDamage(Event@ evt, float amount) {
	Object@ targ = evt.target;
	if (targ !is null && evt.obj !is null) {
		if(targ.toPlanet() !is null) {
			State@ hp = targ.getState(strDamage);
			State@ shlds = targ.getState(strShields);
			if(amount > (hp.max * 0.1f) && shlds.val <= 0) {
				float max = targ.toPlanet().getMaxStructureCount();
				if(max > 0) {
					float take = min(max,randomf(1,5));
					max -= take;
					targ.setFlag(objPDamage, true);
					targ.toPlanet().setStructureSpace(max);
					
					// Set slots that might be recoverable from terraforming later
					State@ form = evt.obj.getState(strTerraform);
					form.max += rand(take);
				}	
			}
		}	
		targ.damage(evt.obj, amount);
	}	
}

void dealDamage(Event@ evt, float amount, uint flags) {
	Object@ targ = evt.target;
	if (targ !is null && evt.obj !is null) {
		if(targ.toPlanet() !is null) {
			State@ hp = targ.getState(strDamage);
			State@ shlds = targ.getState(strShields);
			if(amount > (hp.max * 0.1f) && shlds.val <= 0) {
				float max = targ.toPlanet().getMaxStructureCount();
				if(max > 0) {
					float take = min(max,randomf(1,5));
					max -= take;
					targ.setFlag(objPDamage, true);
					targ.toPlanet().setStructureSpace(max);
					
					// Set slots that might be recoverable from terraforming later
					State@ form = evt.obj.getState(strTerraform);
					form.max += rand(take);	
				}	
			}
		}
		targ.damage(evt.obj, amount, flags);
	}	
}

void DoT(Event@ evt, float Damage) {
	dealDamage(evt, Damage * evt.time);
}

//Randomly succeed, with an increased chance of success for larger objects
void ChanceDoT(Event@ evt, float Damage, float Chance) {
	if(randomf(1.f) < chanceOverTime(Chance, evt.time))
		dealDamage(evt, Damage * evt.time);
	//else
	//	evt.state = ESC_DISABLE;
}

void ChanceDoTAoE(Event@ evt, float Damage, float Chance) {
	if(randomf(1.f) < chanceOverTime(Chance, evt.time))
		dealDamage(evt, Damage * evt.time, DF_AoE);
	//else
	//	evt.state = ESC_DISABLE;
}

float closerRange(const Object@ from, const Object@ to, const Effector@ eff) {
	float distSQ = from.getPosition().getDistanceFromSQ(to.getPosition()) - (from.radius + to.radius);
	float range = eff.range * 0.8f;
	
	if(distSQ <= range * range)
		return 1.f;
	else
		return 0.f;
}

//Deals % damage-per-tick, until the object is repossessed
const string@ strSpaceOwned = "SpaceOwned";
void SpaceDamage(Event@ evt, float Damage) {
	Empire@ owner = evt.target.getOwner();
	if((@owner != null && owner.isValid()) || evt.target.toHulledObj().getHull().hasSystemWithTag(strSpaceOwned)) {
		evt.state = ESC_DISABLE;
	}
	else {
		dealDamage(evt, Damage * evt.time * evt.target.getState(strDamage).max);
	}
}

void EnergyDamage(Event@ evt, float Damage, float Cost) {
	Object@ targ = evt.target;
	if(@targ != null) {
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

const float MaxImpartedVelocity = 50.f;
void ImpartForce(Event@ evt, float Force, float PowCost) {
	Object@ targ = evt.target;
	
	//Massive targets can't be affected
	float targMass = targ.getMass();
	if(targMass > abs(Force * 10000.f)) {
		evt.state = ESC_DISABLE;
		return;
	}
	
	if(@targ != null) {
		float fireDuration = evt.time;
		State@ pow = evt.obj.getState(strPower);

		if (PowCost > 0)
			fireDuration = min(pow.getAvailable() / (PowCost * evt.time), evt.time);

		if (fireDuration > 0) {
			//Break static orbits
			targ.orbitAround(null);
			
			pow.val -= fireDuration * PowCost;
			
			vector relVelocity = targ.velocity - evt.obj.velocity;
			
			float relSpeed = relVelocity.getLength();
			if(relSpeed < MaxImpartedVelocity) {
				float factor = 1.f - (relSpeed / MaxImpartedVelocity);
				
				float accel = Force * fireDuration / targMass;
				
				vector relPos = targ.getPosition() - evt.obj.getPosition();
				relPos.normalize(accel);
				relVelocity += relPos;
				if(relVelocity.getLengthSQ() > MaxImpartedVelocity * MaxImpartedVelocity)
					relVelocity.normalize(MaxImpartedVelocity);
				
				targ.velocity = relVelocity;
			}
		}
		else {
			evt.state = ESC_DISABLE;
		}
	}
}

void MatchVelocity(Event@ evt, float Force, float PowCost) {
	Object@ targ = evt.target;
	if(@targ != null) {
		float fireDuration = evt.time;
		State@ pow = evt.obj.getState(strPower);

		if (PowCost > 0)
			fireDuration = min(pow.getAvailable() / (PowCost * evt.time), evt.time);

		if (fireDuration > 0) {
			pow.val -= fireDuration * PowCost;

			// Speed based on other's mass
			float speed = Force * fireDuration / targ.getMass();

			// Get target velocity change
			vector targDeltaV = evt.obj.velocity - targ.velocity;
			float targDeltaS = targDeltaV.getLength();

			// Don't exceed our max speed change
			if (abs(targDeltaS) > abs(speed))
				targDeltaV.normalize(targDeltaS > 0.f ? abs(speed) : -abs(speed));

			targ.orbitAround(null);
			targ.velocity += targDeltaV;
		}
		else {
			evt.state = ESC_DISABLE;
		}
	}
}

//Energy Damage that pierces armor
void PhasedDamage(Event@ evt, float Damage, float Cost) {
	Object@ targ = evt.target;
	if(@targ != null) {
		if(Cost > 0) {
			float tickCost = Cost * evt.time;
			State@ pow = evt.obj.getState(strPower);
			float fireDuration = min(pow.getAvailable() / tickCost, evt.time);
			if(fireDuration > 0) {
				pow.val -= Cost * fireDuration;
				dealDamage(evt, Damage * fireDuration, DF_Energy | DF_ArmorPiercing);
			}
			else {
				evt.state = ESC_DISABLE;
			}
		}
		else {
			dealDamage(evt, Damage * evt.time, DF_Energy | DF_ArmorPiercing);
		}
	}
}

float starDamageFactor = 100000000.f; //Amount of damage to deal from a star, based on its radius. (mitigated by small size)
float starRadiusBase = 100.f; //Radius of an object that receives 50% of the damage for a tick. Twice this radius receives 66.7%, half receives 33.3%
void StarDamage(Event@ evt) {
	Object@ targ = evt.target;
	if (targ.toStar() !is null) {
		targ.damage(evt.obj, sqr(starDamageFactor));
		evt.state = ESC_DISABLE;
	}
	else {
		float damage = evt.obj.radius * starDamageFactor * evt.time;
		damage *= targ.radius / (starRadiusBase + targ.radius);
		targ.damage(evt.obj, damage, DF_Energy | DF_Explosive | DF_AoE);
	}
}

void QuasarExplode(Event@ evt) {
	Object@ quasar = evt.target;

	Effect dmg("QuasarDamage");
	dmg.set("Damage", pow(10, 12) * 0.7f);

	if(canAchieve)
		achieve(AID_DEST_QUASAR);

	uint sysCnt = getSystemCount();
	for (uint i = 0; i < sysCnt; ++i) {
		System@ sys = getSystem(i);
		Object@ sysObj = sys;

		if (sysObj is null)
			continue;

		float dist = sysObj.position.getDistanceFrom(quasar.position);

		SysObjList list;
		list.prepare(sys);

		uint objCnt = list.childCount;
		for (uint j = 0; j < objCnt; ++j) {
			Object@ obj = list.getChild(j);
			if (obj.toStar() is null)
				continue;

			obj.addTimedEffect(dmg, 10.f, dist / 500.f, quasar, null, null, TEF_None);
		}
	}
}

void QuasarDamage(Event@ evt, float Damage) {
	evt.target.damage(evt.obj, Damage * evt.time, DF_AoE);
}

//These two functions manage the instant hit and damage-over-time of the plasma weapon
void PlasmaFrontDamage(Event@ evt, float FrontDamage, float DoTDamage) {
	evt.target.damage(evt.obj, FrontDamage, DF_Energy);
}

void PlasmaDoTDamage(Event@ evt, float FrontDamage, float DoTDamage) {
	evt.target.damage(evt.obj, DoTDamage * evt.time, DF_Energy);
}

void ProjDamage(Event@ evt, float Damage) {
	dealDamage(evt, Damage, DF_Kinetic);
}

void PopDamage(Event@ evt, float Damage) {
	Planet@ pl = evt.target;
	if (pl !is null) {
		float val = 0.f, max = 0.f, tmp = 0.f;
		if (evt.target.getStateVals(strShields, val, max, tmp, tmp) && max > 0)
			Damage *= 1.f - clamp(val / max, 0.f, 1.f);	
		float killPeople = min(Damage * PersonPerDamage, pl.getPopulation());
		pl.modPopulation(killPeople * -1.f);
	}
}

void ProjPierceDamage(Event@ evt, float Damage) {
	dealDamage(evt, Damage, DF_Kinetic + DF_HalfArmorPierce);
}

void ExplosiveDamage(Event@ evt, float Damage) {
	dealDamage(evt, Damage, DF_Explosive);
}

void ArtyDamage(Event@ evt, float Damage) {
	dealDamage(evt, Damage, DF_Kinetic + DF_Explosive);
}

void ProjDamage(Event@ evt, float Damage, float Cost) {
	Object@ targ = evt.target;
	if(@targ != null) {
		State@ ammo = evt.obj.getState(strAmmo);
		if(ammo.getAvailable() >= Cost) {
			ammo.val -= Cost;
			dealDamage(evt, Damage, DF_Kinetic);
		}
		else {
			evt.state = ESC_DISABLE;
		}
	}
}

void SuckPower(Event@ evt, float Rate) {
	Object@ targ = evt.target, obj = evt.obj;
	if(@targ != null && targ.hasState(strPower) && obj.hasState(strPower)) {
		State@ powTo = obj.getState(strPower), powFrom = targ.getState(strPower);
		float takeAmt = min(Rate * evt.time, min(powTo.getTotalFreeSpace(obj), powFrom.val));
		powTo.add(takeAmt,obj); powFrom.val -= takeAmt;
	}
}

void ChargeGun(Event@ evt, const Effector@ eff, EffectorState@ state) {
	//Amount of charge that must be generated
	float chargeReq = eff[2];
	float chargeLeft = chargeReq - state.val1;
	if(chargeLeft <= 0)
		return;
	State@ power = evt.obj.getState(strPower);
	if(power.val <= 0)
		return;
	//Charge slower as we have less power, and consume no more than half of the remaining power in a single tick
	float chargeRate = eff[3] * evt.time;
	float chargeAmt = min(min(chargeRate * power.val / power.max, 0.5f * power.val), chargeLeft);
	state.val2 = chargeReq;
	if(chargeAmt > 0) {
		power.val -= chargeAmt;
		state.val1 += chargeAmt;
	}
}

void ChargeProgress(Event@ evt, const Effector@ eff, EffectorState@ state, float& val, float& max) {
	val = state.val1;
	max = state.val2;
}

void SelfDestruct(Event@ evt) {
	//Amount of charge that must be generated
	evt.dest.system.trigger("Detonation", evt.obj, null, 0, 0);
	evt.obj.destroy();
}

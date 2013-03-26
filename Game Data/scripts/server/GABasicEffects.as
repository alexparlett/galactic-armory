string@ strPower = "Power", strOre = "Ore", strParts = "Parts", strDamage = "Damage", strAsteroids = "Asteroids", strH3 = "H3";
string@ strFuel = "Fuel", strFood = "Food", strMetals = "Metals", strElects = "Electronics", strAdvParts = "AdvParts";
string@ strControl = "Control", strCrew = "Crew", strAmmo = "Ammo", strVisibility = "VisibilityTimer";
string@ strHeatsink = "Heatsink", strOverheated = "Overheated", strDamageTimer = "DamageTimer";
string@ strEPow = "ePow";
string@ strStaticPosition = "StaticPosition";

void StaticCheckPosition(Event@ evt) {
	Object@ gate = evt.obj;
	
	gate.velocity = vector(0, 0, 0);	
	
	vector pos = gate.getPosition();
	
	float ox = 0.f,oy = 0.f,oz = 0.f,obs = 0.f;
	gate.getStateVals(strStaticPosition,ox,oy,oz,obs);
	
	if(ox <= 0 && oy <= 0 && oz <= 0)
	{
		game.setStateVals(strStaticPosition,pos.x,pos.y,pos.z,0);
	} else if(pos.x != ox || pos.y != oy || pos.z != oz) {
		vector old = vector(ox,oy,oz);
		gate.position = old;
	}
}

void startEmergencyPower(Event@ evt) {
	Object@ obj = evt.obj;
	
	State@ ePow = obj.getState(strEPow);
	if(ePow.max < 1.f)
		ePow.max = 1;
	else
		ePow.max++;
}


void addEmergencyPower(Event@ evt) {
	Object@ obj = evt.obj;
	
	State@ ePow = obj.getState(strEPow);
	if(ePow.val < 1.f)
		ePow.val = 1;
	else
		ePow.val++;
}

void removeEmergencyPower(Event@ evt) {
	Object@ obj = evt.obj;
	
	State@ ePow = obj.getState(strEPow);
	if(ePow.val < 1.f)
		return;
	else
		ePow.val--;
}

float getResourceWeight(State@ state, float freeCargoSpace) {
	if(abs(state.max) < 0.01f)
		return 0.f;
	if(abs(freeCargoSpace) < 0.01f)
		return 0.f;
	float pct = (freeCargoSpace + state.inCargo) / (state.max + state.inCargo);
	if(pct > 0.f)
		return 1.f * pct;
	else
		return 0.f;
}

float sign(float x) {
	if(x > 0)
		return 1.f;
	else
		return 0.f;
}

//Ammo Fabricator
void FabricateAmmo(Event@ evt, float Rate, float MetalCost) {
	Object@ targ = evt.target;
	if(@targ !is null) {
		State@ ammo = targ.getState(strAmmo);
		State@ metal = targ.getState(strMetals);
	
		Rate *= evt.time;
		
		float canMake = min(metal.getAvailable() / MetalCost, Rate);
		canMake = min(canMake, ammo.getTotalFreeSpace(targ));
		if(canMake > 0) {
			metal.consume(canMake * MetalCost, targ);
			ammo.add(canMake, targ);
		}
	}   
}

void ImportAmmo(Event@ evt, float Rate) {
	Object@ obj = evt.obj;

    State@ dmgTimer = obj.getState(strDamageTimer);
   
    if (@dmgTimer != null){
	    if (dmgTimer.val - gameTime <= 0.f){
	
			// Check for blockades
			System@ parent = evt.obj.getParent();
			Empire@ emp = evt.obj.getOwner();
			if (parent !is null && parent.isBlockadedFor(emp))
				return;

			//Trade things
			float tickTrade = Rate * evt.time;
			
			State@ shipammo = obj.getState(strAmmo);
			
			float ammoWeight = getResourceWeight(shipammo, shipammo.getTotalFreeSpace(obj));
			float totalWeight = abs(ammoWeight);

			float take;
			
			if(totalWeight > 0) {
				take = max(0.f, min(float(emp.getStat(strAmmo)),tickTrade * ammoWeight/totalWeight));
				emp.consumeStat(strAmmo, take);
				shipammo.val += take;
				tickTrade -= take;
			}
			
			if(tickTrade > 0) {
				take = max(0.f, min(float(emp.getStat(strAmmo)),tickTrade * sign(ammoWeight)));
				emp.consumeStat(strAmmo, take);
				shipammo.val += take;
				tickTrade -= take;
			}
		}
	}
}

void CollectAsteroids(Event@ evt, float Rate) {
   State@ asteroids = evt.obj.getState(strAsteroids);
   
	if (@asteroids != null && asteroids.val < asteroids.max){
		asteroids.val += min(asteroids.max - asteroids.val, evt.time * Rate);
	}
}

void ReleaseHeat(Event@ evt, float Rate) {
   State@ heatsink = evt.obj.getState(strHeatsink);
   State@ overheated = evt.obj.getState(strOverheated);
   
	if (@heatsink != null && heatsink.val > 0.f){
		heatsink.val -= min(heatsink.val, evt.time * Rate);
		if(@overheated != null && overheated.val >= 1.f && heatsink.val / heatsink.max <= 0.5f)
			overheated.val = 0.f;
	}
}

//Do not work (yet)
void SetVisible(Event@ evt, float Time){	
	//print("SetVisibleTimer" + gameTime);
	evt.obj.setGlobalVisibility(true);
	
	State@ visibilityTimer = evt.obj.getState(strVisibility);
	if (@visibilityTimer != null){
		visibilityTimer.val = gameTime + Time;
	}
}

void SetInvisible(Event@ evt){
	State@ visibilityTimer = evt.obj.getState(strVisibility);
	if (@visibilityTimer != null && visibilityTimer.val < 0.001f && visibilityTimer.val >= 0.f){	
		//print("SetInvisibleTimer" + gameTime);	
		evt.obj.setGlobalVisibility(false);
			visibilityTimer.val = -1.f;
	}
	else{
		if ((visibilityTimer.val - gameTime) < 0.001f)
			 visibilityTimer.val = 0.f;
		}
}

void SetInvisibleOnce(Event@ evt) {
	//print("SetInvisibleOnce" + gameTime);
	evt.obj.setGlobalVisibility(false);
}

void SetVisibleOnce(Event@ evt) {
	//print("SetVisibleOnce" + gameTime);
	evt.obj.setGlobalVisibility(true);
}

void ScoopH3(Event@ evt, float Rate, float PowCost) {
	Object@ targ = evt.target, obj = evt.obj;
	if(targ !is null && obj !is null) {
		State@ h3To = obj.getState(strH3), h3From = targ.getState(strH3);
		float duration = evt.time;

		State@ powFrom = null;
		if (PowCost > 0) {
			@powFrom = obj.getState(strPower);
			duration = min(evt.time, powFrom.getAvailable() / PowCost);
		}

		if(duration > 0) {
			float takeAmt = min(Rate * duration, min(h3To.getTotalFreeSpace(obj), h3From.val));
			h3To.add(takeAmt,obj);
			h3From.val -= takeAmt;

			if (PowCost > 0 && powFrom !is null)
				powFrom.consume(duration * PowCost,obj);
				
			if (h3From.val <= 0.01f)
				targ.damage(obj, 1000.f);
			else
				targ.damage(obj, takeAmt);
		}							
	}
}

float CanHarvest(const Object@ src, const Object@ trg, const Effector@ eff) {
	const Empire@ emp = trg.getOwner();
	if(trg.toStar() !is null || trg.toPlanet() !is null) {
		if(emp is null || !emp.isValid())
			return 1.f;
	}
	return 0.f;
}

void convertH3(Event@ evt, float Rate, float H3CostPer) {
	Object@ targ = evt.target;
	if(@targ !is null) {
		Rate *= evt.time;
		State@ he3From = targ.getState(strH3);
		State@ fuelTo = targ.getState(strFuel);
		float canMake = min(he3From.getAvailable() / H3CostPer, Rate);
		canMake = min(canMake, fuelTo.getTotalFreeSpace(targ));
		if(canMake > 0) {
			he3From.consume(canMake * H3CostPer, targ);
			fuelTo.add(canMake, targ);
		}
	}
}

void importdockBuilt(Event@ evt, float Rate) {
	Object@ obj = evt.obj;
	Empire@ emp = obj.getOwner();	
	
	emp.consumeStat("importer", Rate);	
}	

void importdockDestroyed(Event@ evt, float Rate) {
	Object@ obj = evt.obj;
	Empire@ emp = obj.getOwner();	
	
	emp.addStat("importer", Rate);	
}	

void spaceportDestroyed(Event@ evt, float Amount) {
	Object@ obj = evt.obj;
	Empire@ emp = obj.getOwner();
	
	emp.consumeStat("importer", Amount);
}	

void spaceportBuilt(Event@ evt, float Amount) {
	Object@ obj = evt.obj;
	Empire@ emp = obj.getOwner();
	
	emp.addStat("importer", Amount);
}		

void BankImport(Event@ evt, float Rate) {
	Object@ obj = evt.obj;
	
	// Check for blockades
	System@ parent = evt.obj.getParent();
	Empire@ emp = evt.obj.getOwner();
	if (parent !is null && parent.isBlockadedFor(emp))
		return;

	//Trade things
	float tickTrade = Rate * evt.time;
	
	State@ shipmetal = obj.getState(strMetals);
	State@ shipelect = obj.getState(strElects);
	State@ shipparts = obj.getState(strAdvParts);
	State@ shipfuel = obj.getState(strFuel);
	State@ shipammo = obj.getState(strAmmo);
	
	float mtlWeight = getResourceWeight(shipmetal, shipmetal.getTotalFreeSpace(obj));
	float elecWeight = getResourceWeight(shipelect, shipelect.getTotalFreeSpace(obj));
	float partsWeight = getResourceWeight(shipparts, shipparts.getTotalFreeSpace(obj));
	float fuelWeight = getResourceWeight(shipfuel, shipfuel.getTotalFreeSpace(obj));
	float ammoWeight = getResourceWeight(shipammo, shipammo.getTotalFreeSpace(obj));
	float totalWeight = abs(mtlWeight) + abs(elecWeight) + abs(partsWeight) + abs(ammoWeight) + abs(fuelWeight);

	float take;
	
	if(totalWeight > 0) {
		take = max(0.f, min(float(emp.getStat(strMetals)),tickTrade * mtlWeight/totalWeight));
		emp.consumeStat(strMetals, take);
		shipmetal.val += take;
		tickTrade -= take;

		take = max(0.f, min(float(emp.getStat(strElects)),tickTrade * elecWeight/totalWeight));	
		emp.consumeStat(strElects, take);
		shipelect.val += take;
		tickTrade -= take;

		take = max(0.f, min(float(emp.getStat(strAdvParts)),tickTrade * partsWeight/totalWeight));	
		emp.consumeStat(strAdvParts, take);
		shipparts.val += take;
		tickTrade -= take;

		take = max(0.f, min(float(emp.getStat(strFuel)),tickTrade * fuelWeight/totalWeight));
		emp.consumeStat(strFuel, take);
		shipfuel.val += take;
		tickTrade -= take;
		
		take = max(0.f, min(float(emp.getStat(strAmmo)),tickTrade * ammoWeight/totalWeight));
		emp.consumeStat(strAmmo, take);
		shipammo.val += take;
		tickTrade -= take;
	}
	
	if(tickTrade > 0) {
		take = max(0.f, min(float(emp.getStat(strMetals)),tickTrade * sign(mtlWeight)));
		emp.consumeStat(strMetals, take);
		shipmetal.val += take;
		tickTrade -= take;

		if(tickTrade > 0) {
			take = max(0.f, min(float(emp.getStat(strElects)),tickTrade * sign(elecWeight)));	
			emp.consumeStat(strElects, take);
			shipelect.val += take;
			tickTrade -= take;
					
			if(tickTrade > 0) {
				take = max(0.f, min(float(emp.getStat(strAdvParts)),tickTrade * sign(partsWeight)));	
				emp.consumeStat(strAdvParts, take);
				shipparts.val += take;
				tickTrade -= take;			
				
				if(tickTrade > 0) {
					take = max(0.f, min(float(emp.getStat(strFuel)),tickTrade * sign(fuelWeight)));
					emp.consumeStat(strFuel, take);
					shipfuel.val += take;
					tickTrade -= take;			
					
					if(tickTrade > 0) {	
						take = max(0.f, min(float(emp.getStat(strAmmo)),tickTrade * sign(ammoWeight)));
						emp.consumeStat(strAmmo, take);
						shipammo.val += take;
						tickTrade -= take;
					}
				}
			}
		}
	}	
}

void SelfHealing(Event@ evt, float Rate) {
	Object@ obj = evt.obj, targ = evt.target;
	
	// Check it has HP
	State@ dmg = targ.getState(strDamage);
	if(dmg.max <= 0)
		return;
		
	// Establish Rate	
	Rate *= 5 * (1 - (dmg.val/dmg.max));
	Rate = Rate * evt.time;
	
	// Check That the Rate wont reduce the damage val below 0
	if(Rate > dmg.val)
		Rate = dmg.val;
	
	// Heal the Damage
	if(Rate > 0)
		dmg.val -= Rate;
}

ObjectFlag objPDamage = objUser01;
void PlanetRegen(Event@ evt) {
	Object@ obj = evt.obj, targ = evt.target;
	Planet@ pl = obj;
	
	State@ lastIncrease = obj.getState("PlanetRegenLast");
	float max = lastIncrease.max;
	
	// Heal Planet Slot Damage
	if(obj.getFlag(objPDamage)) {

		float slots = pl.getMaxStructureCount();
		
		if(slots < 5) {
			if ( max > 0 && (max + 180) > gameTime ) {
				return; //returns if its too soon to increase again
			} else {
				//if enough time has passed it does the regen
				pl.setStructureSpace(slots + 1); //increases by 1
				float newcount = pl.getMaxStructureCount();
				if(newcount >= 5)
					obj.setFlag(objPDamage, false);
				lastIncrease.max = gameTime; //sets the state to game time.
			}	
		} else {
			obj.setFlag(objPDamage, false);
		}
	}
}

string@ strDamage = "Damage", strControl = "Control", strCrew = "Crew", strAmmo = "Ammo";
string@ strFuel = "Fuel", strFood = "Food", strMetals = "Metals", strElects = "Electronics", strAdvParts = "AdvParts";
string@ strDamageTimer = "DamageTimer", strDelRepair = "HasDelRepair", strRepair = "HasRepair";

//Repair Method for Crewquarters, ICC and Repairbay
void DelayedShipRepairManpower(Event@ evt, float Rate, float MetalCost) {
   State@ dmgTimer = evt.obj.getState(strDamageTimer);
   State@ dmg = evt.obj.getState(strDamage);
   
   if (@dmgTimer != null){
	   if (dmgTimer.val - gameTime <= 0.f){
			Empire@ owner = evt.obj.getOwner();	
			if(@owner != null){
				if (owner.hasTraitTag("no_bank")){  	//when trait no_bank is selected, repair does not cost metals
					evt.obj.repair(evt.time * Rate);
				}
				else{
					float metalsInBank = owner.getStat(strMetals);
					if (metalsInBank >= MetalCost){
						if(dmg.val > 0)
							owner.consumeStat(strMetals, MetalCost * evt.time);
						evt.obj.repair(evt.time * Rate);
					}
					else
					{
						float ratio = metalsInBank/MetalCost;
						if(dmg.val > 0)
							owner.consumeStat(strMetals, metalsInBank * evt.time);
						evt.obj.repair(evt.time * Rate * ratio);
					}
				}
			}
	   }
   }
}

//Repair Method for RepairTool, RepairFacilities and NaniteRepair
void ShipRepairMachines(Event@ evt, float Rate, float MetalCost) {
	if(@evt.target != null){
		State@ dmg = evt.target.getState(strDamage);
		
		if(@evt.obj != null){
			Empire@ owner = evt.obj.getOwner();	
			
			if(@owner != null){
				if (owner.hasTraitTag("no_bank")){  	//when trait no_bank is selected, repair does not cost metalls
					evt.target.repair(evt.time * Rate);
				}
				else{
					float metalsInBank = owner.getStat(strMetals);
					if (metalsInBank >= MetalCost){
						if (dmg.val > 0)
							owner.consumeStat(strMetals, MetalCost * evt.time);
						evt.target.repair(evt.time * Rate);
					}
					else
					{
						float ratio = metalsInBank/MetalCost;
						if (dmg.val > 0)
							owner.consumeStat(strMetals, metalsInBank * evt.time);
						evt.obj.repair(evt.time * Rate * ratio);
					}
				}
			}
		}
	}
}

void HasDelRepair(Event@ evt, float Amount) {
   State@ delRepair = evt.obj.getState(strDelRepair);
   State@ repair = evt.obj.getState(strRepair);

   delRepair.max += Amount;
   delRepair.val += Amount;
   repair.max += Amount;
   repair.val += Amount;
}
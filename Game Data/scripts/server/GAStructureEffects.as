string@ strMetals = "Metals", strElectronics = "Electronics", strAdvParts = "AdvParts", strFood = "Food";
string@ strNoFood = "no_food", strNoBank = "no_bank", strAIHelp = "ai_help";

void AIPlanetCapitalTick(Event@ evt, float MetalRate, float ElectRate, float AdvPartRate, float FoodRate) {
	Object@ obj = @evt.target;
	if(!obj.getOwner().isValid())
		return;
		
	if (!obj.getOwner().hasTrait(strAIHelp)){
		return;
	}
		
	//if (!obj.getOwner().hasTraitTag(strNoBank)){
	//	MetalRate = 0;
	//	ElectRate = 0;
	//	AdvPartRate = 0;
	//	FoodRate = 0;
	//}

	//Metals
	obj.getState(strMetals).add(evt.time * MetalRate, obj);
	
	//Electronics
	obj.getState(strElectronics).add(evt.time * ElectRate, obj);
	
	//Advanced Parts
	obj.getState(strAdvParts).add(evt.time * AdvPartRate, obj);
	
	//Food (not generated into cargo)
	if (!obj.getOwner().hasTraitTag(strNoFood)) {
		State@ state = obj.getState(strFood);
		float amount = evt.time * FoodRate;

		if (state.max - state.val >= amount)
			state.val += amount;
		else
			state.val = state.max;
	}
}




void IncreaseSlots(Event@ evt, float Amount) {
   float space, max;
   
   Object@ planet = @evt.target;
   Planet@ pl = @evt.target;
   
   if(!planet.getOwner().isValid())
      return;
      
   space = pl.getMaxStructureCount();   
   max = space + Amount;
      
   pl.setStructureSpace(max);
}

void DecreaseSlots(Event@ evt, float Amount){
   float space, max;
   
   Object@ planet = @evt.target;   
   Planet@ pl = @evt.target;
   
   if(!planet.getOwner().isValid())
      return;
      
   space = pl.getMaxStructureCount();  
   max = space - Amount;
      
   pl.setStructureSpace(max);
}

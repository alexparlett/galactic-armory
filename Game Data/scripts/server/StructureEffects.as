string@ strMetals = "Metals", strElectronics = "Electronics", strAdvParts = "AdvParts", strFood = "Food", strFuel = "Fuel", strAmmo = "Ammo";
string@ strNoFood = "no_food";

void PlanetCapitalTick(Event@ evt, float MetalRate, float ElectRate, float AdvPartRate, float FoodRate, float FuelRate, float AmmoRate) {
	Object@ obj = @evt.target;
	if(!obj.getOwner().isValid())
		return;

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
	
	//Fuel
	obj.getState(strFuel).add(evt.time*FuelRate, obj);
	
	//Ammo
	obj.getState(strAmmo).add(evt.time*AmmoRate, obj);
}

void ChangeResearchOwner(Event@ evt, Empire@ from, Empire@ to, float Amount) {
	if (evt.dest.getState() == SS_Active) {
		if (from.isValid())
			from.modResearchRate(-1.f * Amount);
		if (to.isValid())
			to.modResearchRate(Amount);
	}
}

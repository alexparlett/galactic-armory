string@ coloredEmpire(Empire@ emp) {
	return combine("#c:", emp.color.format(), "#", emp.getName(), "#c#");
}

void postFailure(Empire@ to, Empire@ lacking, const string@ resource) {
	string@ failed = combine(localize("#EM_Trty_failed"), coloredEmpire(lacking), localize("#EM_Trty_insufficient"), resource);
	to.postMessage(combine(localize("#EM_Trty_with"), coloredEmpire(lacking), failed), "diplomacy", 10);
	lacking.postMessage(combine(localize("#EM_Trty_with"), coloredEmpire(to), failed), "diplomacy", 10);
}

ClauseState Send(Clause@ clause, Empire@ from, Empire@ to) {
	const string@ res = clause.getOption(0).toString();
	
	//Don't trade invalid amounts
	if(res != "Metals" && res != "Electronics" && res != "AdvParts" && res != "Food" && res != "Luxs" && res != "Guds" && res != "Fuel" && res != "Ammo")
		return CS_FAILED;
	
	float amt = clause.getOption(1).toFloat();

	//Don't trade backwards (this is done at a higher level)
	if(amt <= 0)
		return CS_FAILED;
	
	float consumed = from.consumeStat(res, amt);
	if(consumed < amt) {
		//If there wasn't enough, return the amount and fail out
		from.addStat(res, consumed);

		// Post failure messages
		postFailure(to, from, res);

		return CS_FAILED;
	}

	to.addStat(res, amt);
	return CS_CLAUSE_ENDED;
}

ClauseState Begin(Clause@ clause, Empire@ from, Empire@ to) {
	const string@ res = clause.getOption(0).toString();
	
	//Don't trade invalid amounts
	if(res != "Metals" && res != "Electronics" && res != "AdvParts" && res != "Food" && res != "Luxs" && res != "Guds" && res != "Fuel" && res != "Ammo")
		return CS_FAILED;
	
	//Don't trade backwards (this is done at a higher level)
	//Don't start the treaty if we don't have enough for even a single second
	float rate = clause.getOption(1).toFloat();	
	if(rate <= 0 || from.getStat(res) <= rate * 1.f) {
		postFailure(to, from, res);
		return CS_FAILED;
	}
	
	return CS_NOCHANGE;
}

ClauseState Tick(Clause@ clause, Empire@ from, Empire@ to, double tick) {
	const string@ res = clause.getOption(0).toString();
	float amt = clause.getOption(1).toFloat() * float(tick);
	
	float consumed = from.consumeStat(res, amt);
	if(consumed < amt) {
		//If there wasn't enough, give what we took (prevents abuse of the treaty)
		to.addStat(res, consumed);

		// Post failure messages
		postFailure(to, from, res);

		return CS_FAILED;
	}
	
	to.addStat(res, consumed);
	return CS_NOCHANGE;
}

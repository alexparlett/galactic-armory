
ClauseState DeclareWar(Clause@ clause, Empire@ from, Empire@ to) {
	
	for(uint i = 0; i < getEmpireCount(); i++) {
		Empire@ emp = getEmpire(i);
		
		if(emp.isAllied(to)) {
			from.setEnemy(emp, true);
			from.clearTreatiesWith(emp);
			emp.clearTreatiesWith(from);
		}
	}	

	from.setEnemy(to, true); //Bi-directional
	from.clearTreatiesWith(to);
	to.clearTreatiesWith(from);


	TreatyList treaties;
	
	treaties.prepare(from);
	treaties.retract(to);
	treaties.setAcceptance(to, false);
	treaties.prepare(null);
	
	if (from.isValid() && from.ID > 0 && to.hasMet(from))
		to.postMessage(localize("#EM_The") + ("#c:" + from.color.format() + "#" + from.getName() + "#c#") + localize("#EM_DeclaredWar"), "war", 10);
	
	return CS_ENDED;
}

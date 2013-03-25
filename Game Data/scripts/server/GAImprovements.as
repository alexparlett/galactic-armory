// Globals / Constants
const string@ strFormer = "Former";
const string@ strMetals = "Metals", strElects = "Electronics", strAdvParts = "AdvParts";
const string@ strImp = "Improvement", strCosts = "impCosts", strTotalCosts = "impTotalCosts", strTerraform = "Terraform";
const float Rate = 1000.f;
ObjectFlag objImprovement = objUser03;

/* {{{ Message Events */
void cancelImprovement(float Oid) {
	Object@ obj = getObjectByID(int(round(Oid)));

	State@ mtls = obj.getState(strMetals), elects = obj.getState(strElects), parts = obj.getState(strAdvParts);
	
	float mtl = 0.f, ele = 0.f, prt = 0.f, tmp = 0.f;
	float tmtl = 0.f, tele = 0.f, tprt = 0.f;	
	obj.getStateVals(strCosts, mtl, ele, prt, tmp);
	obj.getStateVals(strTotalCosts, tmtl, tele, tprt, tmp);	
	
	mtls.add((tmtl - mtl) / 2, obj);
	elects.add((tele - ele) / 2, obj);
	parts.add((tprt - prt) / 2, obj);
	
	obj.setStateVals(strImp, 0, 0, 0, 0);
	obj.setStateVals(strCosts, 0, 0, 0, 0);
	obj.setStateVals(strTotalCosts, 0, 0, 0, 0);	
	
	obj.setFlag(objImprovement, false);	
}

void terraForm(string@ sID, float Oid) {
	float Amount;
	uint evtID;

	const subSystemDef@ def = getSubSystemDefByName(sID);
	Object@ obj = getObjectByID(int(round(Oid)));
	Planet@ pl = obj.toPlanet();
	Empire@ emp = obj.getOwner();
	
	SubSystemFactory factory;
	factory.objectScale = 10.f;
	factory.objectSizeFactor = 10.f;
	factory.prepare(pl);	
	
	if(factory.generateSubSystems(def, null)) {	
		subSystem@ subsys = factory.get_active();
	
		//Set the flag if the def was found
		obj.setFlag(objImprovement, true);		
	
		if(def.hasTag("Former")) {
			//Sets the number of slots
			Amount = subsys.getVariable("vSlotIncrease");		
		
			State@ form = obj.getState(strTerraform);	
			Amount = min(Amount, form.val);	
			
			evtID = 1;			
		} 
		
		obj.setStateVals(strImp, evtID, obj.uid, Amount, 0);
		obj.setStateVals(strCosts, subsys.getCost(2), subsys.getCost(1), subsys.getCost(0), 0);
		obj.setStateVals(strTotalCosts, subsys.getCost(2), subsys.getCost(1), subsys.getCost(0), 0);
	}
}
/* {{{ Improvement Functions */
void IncreaseSlots(Object@ obj, float Amount) {
	Planet@ pl = obj.toPlanet();
	float space, max;
	
	State@ form = obj.getState(strTerraform);
	form.val = form.val - Amount;
   
	space = pl.getMaxStructureCount();   
	max = space + Amount;
      
	pl.setStructureSpace(max);
}
/* }}} */
/* {{{ Tick Functions */
void createImp(Object@ obj) {
	State@ mtls = obj.getState(strMetals), elects = obj.getState(strElects), parts = obj.getState(strAdvParts);
	Empire@ emp = obj.getOwner();

	// Setup Improvement Type and Amount
	State@ imp = obj.getState(strImp);
	int evtID = int(round(imp.val));
	float Amount = imp.required;
	
	// Get Costs
	State@ costs = obj.getState(strCosts);
	
	float canMakeMetal = min(min(mtls.getAvailable(), Rate), costs.val);	
	mtls.consume(canMakeMetal, obj);
	costs.val -= canMakeMetal;	
	
	float canMakeElect = min(min(elects.getAvailable(), Rate), costs.max);	
	elects.consume(canMakeElect, obj);
	costs.max -= canMakeElect;	
	
	float canMakeParts = min(min(parts.getAvailable(), Rate), costs.required);	
	parts.consume(canMakeParts, obj);
	costs.required -= canMakeParts;
	
	if(costs.val <= 0 && costs.max <= 0 && costs.required <= 0) {
		//Reset total costs
		obj.setStateVals(strTotalCosts, 0, 0, 0, 0);
	
		//Select which function based on evtID
		switch(evtID) {
			case 1: IncreaseSlots(obj, Amount); break;
		}
		emp.postMessage("An Improvement has been completed on #link:o"+obj.uid+"##c:green#"+obj.getName()+"#c##link#");	
		obj.setFlag(objImprovement, false);	
	}
}
/* }}} */
/* {{{ Client messages */
void onMessage(Empire@ emp, uint msg, string@ arg1, float arg2) {
	switch (msg) {
		case 0: cancelImprovement(arg2); break;
		case 1: terraForm(arg1, arg2); break;
	}
}
/* }}} */

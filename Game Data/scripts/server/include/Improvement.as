// Globals / Constants
const string@ strFormer = "Former";
const string@ strMetals = "Metals", strElects = "Electronics", strAdvParts = "AdvParts";
const string@ strTerraform = "Terraform";
const float Rate = 1000.f;
ObjectFlag objImprovement = objUser03, setImpPause = objSetting00;

class Improvement {

	uint event;
	
	Object@ pl;
	const subSystemDef@ def;
	Planet@ planet;
	Empire@ emp;
	
	float totalMetal;
	float totalElecs;
	float totalParts;
	
	float currentMetal;
	float currentElecs;
	float currentParts;
	
	float amount;
	
	Improvement() {
	}
	
	Improvement(string@ subsystemID, float uid, uint event) {
		@def = getSubSystemDefByName(subsystemID);
		@pl = getObjectByID(int(round(uid)));
		@planet = pl.toPlanet();
		@emp = pl.getOwner();
		
		this.event = event;
		
		initSubsystemValues();
		
		pl.setFlag(objImprovement, true);
	}
	
	void initSubsystemValues() {
		SubSystemFactory factory;
		factory.objectScale = 10.f;
		factory.objectSizeFactor = 10.f;
		factory.prepare(pl);	
		
		if(factory.generateSubSystems(def, null)) {	
			subSystem@ subsys = factory.get_active();
		
			if(def.hasTag("Former")) {
				amount = subsys.getVariable("vSlotIncrease");		
			
				State@ form = pl.getState(strTerraform);	
				amount = min(amount, form.val);	
			} 
			
			currentMetal = totalMetal = subsys.getCost(2);
			currentElecs = totalElecs = subsys.getCost(1);
			currentParts = totalParts = subsys.getCost(0);
		}
	}
	
	void increaseSlots() {
		float space, max;
		
		State@ form = pl.getState(strTerraform);
		form.val = form.val - amount;
	   
		space = planet.getMaxStructureCount();   
		max = space + amount;
		  
		planet.setStructureSpace(max);	
	}
	
	void finishImprovement() {
		switch(event) {
			case 1: increaseSlots();
		}	
	}
	
	void update() {
		if(pl is null || !pl.getOwner().isValid() || !pl.getFlag(objImprovement)) {
			endImprovement(this);
			
			return;
		}
	
		if(pl.getFlag(setImpPause)) {
			return;
		}
		
		State@ mtls = pl.getState(strMetals); 
		State@ elects = pl.getState(strElects);
		State@ parts = pl.getState(strAdvParts);
	
		float canMakeMetal = min(min(mtls.getAvailable(), Rate), currentMetal);	
		mtls.consume(canMakeMetal, pl);
		currentMetal -= canMakeMetal;	
		
		float canMakeElect = min(min(elects.getAvailable(), Rate), currentElecs);	
		elects.consume(canMakeElect, pl);
		currentElecs -= canMakeElect;	
		
		float canMakeParts = min(min(parts.getAvailable(), Rate), currentParts);	
		parts.consume(canMakeParts, pl);
		currentParts -= canMakeParts;
		
		if(currentMetal <= 0 && currentElecs <= 0 && currentParts <= 0) {
			finishImprovement();
			
			emp.postMessage("An Improvement has been completed on #link:o"+pl.uid+"##c:green#"+pl.getName()+"#c##link#");	
			
			pl.setFlag(objImprovement,false);
			pl.setFlag(setImpPause, false);
			
			endImprovement(this);
		}	
	}
	
	void cancel() {
		State@ mtls = pl.getState(strMetals); 
		State@ elects = pl.getState(strElects);
		State@ parts = pl.getState(strAdvParts);
		
		mtls.add((totalMetal - currentMetal) / 2, pl);
		elects.add((totalElecs - currentElecs) / 2, pl);
		parts.add((totalParts - currentParts) / 2, pl);
		
		pl.setFlag(objImprovement,false);
		pl.setFlag(setImpPause, false);
	}
}

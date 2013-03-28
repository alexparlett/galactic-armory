const string@ strTroops = "GroundForces";
const float baseTime = 180.f;
const float baseDeath = 20.f;
const float skirmishDeath = 50.f;

class SurveyMission {

	string@ strSurvey;

	Empire@ emp;
	Object@ pl;
	Object@ ship;

	float startTime;
	float troopsRemaining;
	float successRates;

	bool surveyed;
	
	SurveyMission() {
	}

	SurveyMission(Empire@ emp, Object@ pl, Object@ ship, float troops) {
		@this.emp = @emp;
		@this.pl = @pl;
		@this.ship = @ship;

		strSurvey = "Survey"+emp.getName();
		startTime = getGameTime();
		troopsRemaining = troops;
		successRates = 0.f;

		surveyed = false;
	}

	void update() {
		if(pl is null || pl.getOwner().isValid()) {
			if(pl.getOwner() is emp) {
				State@ forces = pl.getState(strTroops);
				forces.val += troopsRemaining;
			}

			endSurveyMission(this);
			return;
		}

		if(getGameTime() - startTime > baseTime) {
			pl.setStateVals(strSurvey,1.f,0.f,0.f,successRates/baseTime);
			surveyed = true;
		}

		if(!surveyed) {
			successRates += explore() ? 1 : 0;
		}

		checkForEnemyParties();

		if(troopsRemaining <= 0) {
			endSurveyMission(this);
			return;
		}
	}

	bool explore() {
		if(randomf(1.00f) > randomf(0.80f,1.00f)) {
			troopsRemaining -= baseDeath + (0.05f * troopsRemaining);
			return false;
		}
		return true;
	}

	void checkForEnemyParties() {
		for(uint i = 0; i < getEmpireCount(); i++) {
			Empire@ other = getEmpire(i);
			if(emp.isEnemy(other)) {
				uint index = findSurveyMissionByObjectAndEmpire(pl,other);
				
				if(index >= 0) {
					SurveyMission@ miss = getSurveyMission(index);

					float ourStrength = troopsRemaining / miss.troopsRemaining;
					float theirStrength = miss.troopsRemaining / troopsRemaining;

					miss.skirmishEnemy(skirmishDeath + (randomf(miss.troopsRemaining * 0.05f) * ourStrength));
					skirmishEnemy(skirmishDeath + (randomf(troopsRemaining * 0.05f) * theirStrength));
				}
			}
		}
	}

	void reinforceMission(float troops) {
		troopsRemaining += troops;
	}

	void skirmishEnemy(float troops) {
		troopsRemaining -= troops;
	}
}
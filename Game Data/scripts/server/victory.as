/*
 * Check each empire for victory or loss condition.
 *  - Sets a "Victory" stat on the empire:
 *  	0 is normal
 *  	1 is victory
 *		-1 is loss
 */

const string@ strVictory = "Victory", strPlanet = "Planet", strShip = "Ship", strTeam = "Team";
const string@ strDifficulty = "Difficulty", strCheats = "Cheats";
const float victoryCheckInterval = 1.f;
float victoryCheckTimer = 0.f;
bool log = false;

void checkVictoryAchievements() {
	if(!canAchieve)
		return;

	float playerTeam = getPlayerEmpire().getSetting(strTeam);

	uint enemyCnt = 0;
	uint cnt = getEmpireCount();
	for (uint i = 0; i < cnt; ++i) {
		Empire@ emp = getEmpire(i);

		if(emp is getPlayerEmpire())
			continue;

		//Ignore empires in the same team
		float team = emp.getSetting(strTeam);
		if(playerTeam > 0.5f && team > 0.5f && abs(playerTeam-team) < 0.5f)
			continue;

		//Only count empires that are dead
		if(emp.getStat(strVictory) < 1.5f)
			continue;

		float diff = emp.getSetting(strDifficulty);
		float cheats = emp.getSetting(strCheats);

		//Difficulty achievements
		if(diff == 0.f) {
			achieve(AID_BEAT_TRIVIAL);
		}
		else if(diff == 5.f) {
			if(cheats == 0.f)
				achieve(AID_BEAT_HARDEST);
			else
				achieve(AID_BEAT_HARDEST_CHEATING);
		}

		//Track how many enemies we've beaten
		++enemyCnt;
	}

	if(enemyCnt >= 7)
		achieve(AID_BEAT_SEVEN);
}

void tick(float time) {
	if (victoryCheckTimer >= victoryCheckInterval) {
		victoryCheckTimer = 0.f;

		uint cnt = getEmpireCount();

		/* First check all empires for loss conditions */
		for (uint i = 0; i < cnt; ++i) {
			Empire@ emp = getEmpire(i);

			// Check that the empire has no more ships or planets
			if (emp.isValid() && emp.ID >= 0 && abs(emp.getStat(strVictory)) < 0.5f) {
				if (emp.getStat(strPlanet) < 0.5f) {
					emp.setStat(strVictory, 2.f);
					emp.setFlag(empLost, true);

					if (log)
						warning(emp.getName()+" has been eliminated.");
				}
			}
		}

		/* Check for empires that have won */
		for (uint i = 0; i < cnt; ++i) {
			Empire@ emp = getEmpire(i);

			if (emp.isValid() && emp.ID >= 0 && abs(emp.getStat(strVictory)) < 0.5f) {
				bool won = true;
				bool hasEnemies = false;
				float team = emp.getStat(strTeam);

				for (uint j = 0; j < cnt; ++j) {
					Empire@ other = getEmpire(j);

					// We don't need to kill ourselves, silly.
					if (other is emp)
						continue;

					// If in different teams and the other has not lost, we have not won
					float otherTeam = other.getStat(strTeam);
					bool sameTeam = team > 0.5f && otherTeam > 0.5f && abs(team-otherTeam) < 0.5f;

					if (other.isValid() && other.ID >= 0 && !sameTeam) {
						hasEnemies = true;
						if (other.getStat(strVictory) < 1.5f) {
							won = false;
							break;
						}
					}
				}

				if (won && hasEnemies) {
					emp.setStat(strVictory, 1.f);

					if(emp is getPlayerEmpire())
						checkVictoryAchievements();

					if (log)
						warning(emp.getName()+" has won the game");
				}
			}
		}
	}
	else
		victoryCheckTimer += time;
}

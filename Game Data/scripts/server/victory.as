/*
 * Check each empire for victory or loss condition.
 *  - Sets a "Victory" stat on the empire:
 *  	0 is normal
 *  	1 is victory
 *		-1 is loss
 */

const string@ strVictory = "Victory", strPlanet = "Planet", strShip = "Ship", strTeam = "Team";
const float victoryCheckInterval = 1.f;
float victoryCheckTimer = 0.f;
bool log = false;

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

					if (log)
						warning(emp.getName()+" has won the game");
				}
			}
		}
	}
	else
		victoryCheckTimer += time;
}

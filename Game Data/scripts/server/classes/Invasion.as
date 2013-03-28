string@ strForces = "GroundForces", strInv = "Invasion", strInvForces = "InvasionTroops";
string@ strDefenseStructure = "", strInvasionDefences = "", strInvasionWeapons = "";
float baseDropship = 5000.f;
float baseIntercepts = 4.f;

class Invasion {

	dictionary empireIndex;

	float[] enemyTroops;
	float[] enemyWeaponTech;
	float[] enemyDefenseTech;
	Empire@[] invaders;

	float weaponTech;
	float defenseTech;
	uint defenseStructures;
	float groundForces;

	Object@ pl;
	Planet@ planet;
	Empire@ owner;
	
	Invasion() {
	}

	Invasion(Object@ pl, Empire@ invader, float troops) {
		@this.pl = pl;
		@planet = pl.toPlanet();
		@owner = pl.getOwner();

		initEmpireDefender();
		initEmpireInvasion(invader, troops);
	}

	void reinforceInvasion(Empire@ emp, float troops) {
		if(emp is owner) {
			groundForces += troops;
			weaponTech = (weaponTech + getEmpireTech(emp,strInvasionWeapons)) / 2.f;
			defenseTech = (defenseTech + getEmpireTech(emp,strInvasionDefences)) / 2.f;
		}
		else {
			float troopsAfterIntercept = interceptDrop(emp, troops);

			if(troopsAfterIntercept > 0.f) {
				uint index;
				empireIndex.get(emp.getName(),index);

				enemyTroops[index] += troops;
				enemyWeaponTech[index] = (enemyWeaponTech[index] + getEmpireTech(emp,strInvasionWeapons)) / 2.f;
				enemyDefenseTech[index] = (enemyDefenseTech[index] + getEmpireTech(emp,strInvasionDefences)) / 2.f;
			}
		}
	}

	float interceptDrop(Empire@ invader, float troops) {
		float troopsAfterIntercept = troops;
		float intercepts = defenseStructures * baseIntercepts * defenseTech;

		for(float i = 0; i < intercepts; i++) {
			if(randomf(1.f) + weaponTech > randomf(1.f) + getEmpireTech(invader,strInvasionDefences))
				troopsAfterIntercept -= baseDropship;
		}

		return troopsAfterIntercept;
	}

	void initEmpireInvasion(Empire@ invader, float troops) {
		float troopsAfterIntercept = interceptDrop(invader, troops);

		if(troopsAfterIntercept > 0.f) {
			uint n = invaders.length();

			empireIndex.set(invader.getName(),n);

			invaders.resize(n+1);
			enemyTroops.resize(n+1);
			enemyWeaponTech.resize(n+1);
			enemyDefenseTech.resize(n+1);

			@invaders[n] = @invader;
			enemyTroops[n] = troopsAfterIntercept;
			enemyWeaponTech[n] = getEmpireTech(invader,strInvasionWeapons);
			enemyWeaponTech[n] = getEmpireTech(invader,strInvasionDefences);
		}
	}

	void initEmpireDefender() {
		weaponTech = getEmpireTech(owner,strInvasionWeapons);
		defenseTech = getEmpireTech(owner,strInvasionDefences);

		float obs = 0.f;
		pl.getStateVals(strForces,groundForces,obs,obs,obs);

		defenseStructures = planet.getStructureCount(getSubSystemDefByName(strDefenseStructure));
	}

	float getEmpireTech(Empire@ emp, string@ tech) {
		ResearchWeb web;
		web.prepare(emp);

		const WebItem@ selection = web.getItem(tech);

		float techlevel = selection.get_level();

		return techlevel;
	}

	bool empireIsInvading(string@ empireName) {
		return empireIndex.exists(empireName);
	}

	void update() {
	}
}
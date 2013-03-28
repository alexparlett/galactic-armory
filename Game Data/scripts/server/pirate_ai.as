#include "/include/empire_lib.as"

void init_pirate_ai() {
}

void prep_pirate_ai_defaults(Empire@ emp) {
}

class PirateAIData {	

	Region@[] regions;

	PirateAIData(Empire@ emp) {
	}

	PirateAIData(Empire@ emp, XMLReader@ xml) {
	}

	void save(XMLWriter@ xml) {
	}
	
	void onDiplomaticMessage(Empire@ emp, Empire@ from, DiploMsg@ msg) {
	}

	void tick(Empire@ emp, float time) {
	}
};

class Region {

	System@[] systems;
	
	Region() {
	}
	
	Region(XMLReader@ xml) {
	}
	
	void update(PirateAIData@ data, Empire@ emp, float tick) {
	}
	
	void load(XMLReader@ xml) {
	}

	void save(XMLWriter@ xml) {
	}
};


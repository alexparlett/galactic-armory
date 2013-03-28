#include "/include/empire_lib.as"
#include "/include/map_util.as"


void init_remnant_ai() {
}

void prep_remnant_ai_defaults(Empire@ emp) {
}

class RemnantAIData {
	RemnantAIData(Empire@ emp) {
	}

	RemnantAIData(Empire@ emp, XMLReader@ xml) {
	}

	void save(XMLWriter@ xml) {
	}
	
	void onDiplomaticMessage(Empire@ emp, Empire@ from, DiploMsg@ msg) {
	}

	void tick(Empire@ emp, float time) {
	}
};
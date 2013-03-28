#include "/include/Improvement.as"

Improvement@[] improvements;

int findImprovementByObject(Object@ pl) {
	for(uint i = 0; i < improvements.length(); i++)
		if(improvements[i].pl is pl)
			return i;
	return -1;
}

int findImprovement(Improvement@ improvement) {
	for (uint i = 0; i < improvements.length(); ++i)
		if (improvements[i] is improvement)
			return i;
	return -1;
}

void endImprovement(Improvement@ improvement) {
	int index = findImprovement(improvement);
	if(index < 0) return;
	
	improvements.erase(index);
}

void cancelImprovement(float uid) {
	Object@ pl = getObjectByID(int(round(uid)));
	
	int index = findImprovementByObject(pl);
	if(index < 0) return;
	
	improvements[index].cancel();
	improvements.erase(index);
}

void tick(float time) {
	for(uint i = 0; i < improvements.length(); i++) {
		improvements[i].update();
	}
}

void startImprovement(string@ subsystemID, float uid, uint event) {
	uint n = improvements.length();
	improvements.resize(n+1);
	@improvements[n] = Improvement(subsystemID, uid, event);
}

void onMessage(Empire@ emp, uint msg, string@ arg1, float arg2) {
	switch (msg) {
		case 0: cancelImprovement(arg2); break;
		default: startImprovement(arg1, arg2, msg); break;
	}
}

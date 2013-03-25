dictionary planetTypes;
bool initialized = false;

int getPlanetIconIndex(string@ physicalType) {
	if (!initialized)
		initTypes();

	int64 index = 0;
	planetTypes.get(physicalType, index);
	return int(index);
}

void initTypes() {
	initialized = true;

	planetTypes.set("rock1", 12);
	planetTypes.set("rock2", 0);
	planetTypes.set("rock3", 44);
	planetTypes.set("rock4", 13);
	planetTypes.set("rock5", 0);
	planetTypes.set("rock6", 0);
	planetTypes.set("rock7", 0);
	planetTypes.set("rock8", 45);
	planetTypes.set("rock9", 46);
	planetTypes.set("rock10", 47);
	planetTypes.set("rock11", 48);
	planetTypes.set("rock12", 49);
	planetTypes.set("rock13", 53);
	planetTypes.set("rock14", 54);
	planetTypes.set("rock15", 55);
	planetTypes.set("rock16", 56);

	planetTypes.set("lava", 2);
	planetTypes.set("lava1", 38);
	planetTypes.set("lava2", 39);
	planetTypes.set("lava3", 40);
	planetTypes.set("lava4", 41);
	planetTypes.set("lava5", 42);
	
	planetTypes.set("ice", 33);
	planetTypes.set("ice1", 34);
	planetTypes.set("ice2", 35);
	planetTypes.set("ice3", 36);
	planetTypes.set("ice4", 37);
	
	planetTypes.set("gas1", 8);
	planetTypes.set("gas2", 58);
	planetTypes.set("gas3", 57);
	planetTypes.set("gas4", 23);
	planetTypes.set("gas5", 24);
	planetTypes.set("gas6", 25);
	planetTypes.set("gas7", 26);
	planetTypes.set("gas8", 27);
	planetTypes.set("gas9", 28);	
	planetTypes.set("gas10", 29);	
	planetTypes.set("gas11", 30);	
	planetTypes.set("gas12", 31);	
	planetTypes.set("gas13", 32);	

	planetTypes.set("desert1", 14);
	planetTypes.set("desert2", 15);
	planetTypes.set("desert3", 4);
	planetTypes.set("desert4", 1);
	planetTypes.set("desert5", 4);
	planetTypes.set("desert6", 9);
	planetTypes.set("desert7", 10);
	planetTypes.set("desert8", 11);
	planetTypes.set("desert9", 9);
	planetTypes.set("desert10", 10);
	planetTypes.set("desert11", 16);
	planetTypes.set("desert12", 17);
	planetTypes.set("desert13", 18);
	planetTypes.set("desert14", 19);
	planetTypes.set("desert15", 20);
	planetTypes.set("desert16", 21);
	planetTypes.set("desert17", 22);
}

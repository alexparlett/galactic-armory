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

	planetTypes.set("rock1", 6);
	planetTypes.set("rock2", 0);
	planetTypes.set("rock3", 5);
	planetTypes.set("rock4", 7);
	planetTypes.set("rock5", 0);
	planetTypes.set("rock6", 0);
	planetTypes.set("rock7", 0);

	planetTypes.set("lava", 2);
	planetTypes.set("ice", 3);
	
	planetTypes.set("gas1", 8);
	planetTypes.set("gas2", 8);
	planetTypes.set("gas3", 8);
	planetTypes.set("gas4", 8);
	planetTypes.set("gas5", 8);
	planetTypes.set("gas6", 8);
	planetTypes.set("gas7", 8);
	planetTypes.set("gas8", 8);
	planetTypes.set("gas9", 8);	

	planetTypes.set("desert1", 4);
	planetTypes.set("desert2", 4);
	planetTypes.set("desert3", 4);
	planetTypes.set("desert4", 1);
	planetTypes.set("desert5", 4);
	planetTypes.set("desert6", 9);
	planetTypes.set("desert7", 10);
	planetTypes.set("desert8", 11);
	planetTypes.set("desert9", 9);
	planetTypes.set("desert10", 10);
}

//advisor_classes.as
//=================
//classes

class St
{
	float val;
	float max;
	float req;
	float cargo;

	St(float val, float max, float req, float cargo) {
		this.val = val;
		this.max = max;
		this.req = req;
		this.cargo = cargo;
	}
}

class Crg
{
	float space;
	float used;
	float left;

	Crg(float space, float used) {
		this.space = space;
		this.used = used;
		this.left = space - used;
	}
}

class PlStates
{
	St@ MtlGen;
	St@ MtlGenOpt;
	St@ Mtl;
	
	St@ AmoGen;

	St@ ElcGen;
	St@ ElcGenOpt;
	St@ Elc;

	St@ AdvGen;
	St@ AdvGenOpt;
	St@ Adv;

	St@ Labor;

	St@ Trade;
	St@ TradeTarget;

	Crg@ Cargo;

	float get_MtlCon() {
		return ElcGenOpt.val * MTL_TO_ELC + AdvGenOpt.val * MTL_TO_ADV + AmoGen.val * MTL_TO_AMO;
	}

	float get_MtlExp() {
		return MtlGenOpt.val - MtlCon;
	}

	float get_ElcCon() {
		return AdvGenOpt.val * ELC_TO_ADV;
	}

	float get_ElcExp() {
		return ElcGenOpt.val - ElcCon;
	}

	float get_AdvExp() {
		return AdvGenOpt.val;
	}

	PlStates(Object@ obj) {
		float val = 0.f, max = 0.f, req = 0.f, cargo = 0.f;

		// Metals
		obj.getStateVals(strMtlGen, val, max, req, cargo);
		@MtlGen = St(val, max, req, cargo);
		obj.getStateVals(strMtlGenOpt, val, max, req, cargo);
		@MtlGenOpt = St(val, max, req, cargo);
		obj.getStateVals(strMtl, val, max, req, cargo);
		@Mtl = St(val, max, req, cargo);

		//Electronics
		obj.getStateVals(strElcGen, val, max, req, cargo);
		@ElcGen = St(val, max, req, cargo);
		obj.getStateVals(strElcGenOpt, val, max, req, cargo);
		@ElcGenOpt = St(val, max, req, cargo);
		obj.getStateVals(strElc, val, max, req, cargo);
		@Elc = St(val, max, req, cargo);

		// AdvParts
		obj.getStateVals(strAdvGen, val, max, req, cargo);
		@AdvGen = St(val, max, req, cargo);
		obj.getStateVals(strAdvGenOpt, val, max, req, cargo);
		@AdvGenOpt = St(val, max, req, cargo);
		obj.getStateVals(strAdv, val, max, req, cargo);
		@Adv = St(val, max, req, cargo);
		
		// Ammo
		obj.getStateVals(strAmmoG, val, max, req, cargo);
		@AmoGen = St(val, max, req, cargo);

		// Labor
		obj.getStateVals(strLabr, val, max, req, cargo);
		@Labor = St(val, max, req, cargo);

		// Trade
		obj.getStateVals(strTrade, val, max, req, cargo);
		@Trade = St(val, max, req, cargo);
		obj.getStateVals(strTradeTarget, val, max, req, cargo);
		@TradeTarget = St(val, max, req, cargo);

		// Cargo
		float cargoUsed, cargoSpace;
		obj.getCargoVals(cargoUsed, cargoSpace);
		@Cargo = Crg(cargoSpace, cargoUsed);
	}
}

class planetItem 
{
	Planet@ pl;
	int weight;
	check@ ch;

	planetItem(Planet@ pl, check@ ch, int weight) {
		@this.pl = pl;
		@this.ch = ch;
		this.weight = weight;
	}

	int opCmp(planetItem@ other) const {
		int val = 0;

		int myVal = weight;
		int otherVal = other.weight;
				
		if (otherVal < myVal)
			val = 1;
		else if (otherVal > myVal)
			val = -1;

		// Sort by id if equal
		if (val == 0) {
			if (other.pl.toObject().uid < pl.toObject().uid)
				return 1;
			return -1;
		}
		return val;
	}
}

interface infoPanel
{
	void update();
	void remove();
	void setPosition(pos2di p);
	void setSize();
	void setPlanet(Planet@ pl);
}

interface check
{
	int calcWeight(Planet@ pl);
	infoPanel@ createInfoPanel(Planet@ pl, pos2di position, GuiElement@ parent);
}
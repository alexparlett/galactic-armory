//advisor_weights.as
//=================
//weights methods
#include "/advisor_const.as"
#include "/advisor_classes.as"

//IMPORTS

//GLOBALS
const int WEIGHT_QUEUE = 1;
const int WEIGHT_MTL_EFF = 20;
const int WEIGHT_ELC_EFF_NORES = 5;
const int WEIGHT_ADV_EFF_NORES = 5;
const int WEIGHT_ELC_EFF_NOCRG = 10;
const int WEIGHT_ADV_EFF_NOCRG = 10;
const int WEIGHT_MTL_CRG = 3;
const int WEIGHT_ELC_CRG = 3;
const int WEIGHT_ADV_CRG = 3;
const int WEIGHT_MTL_CRG_LOW = 1;
const int WEIGHT_ELC_CRG_LOW = 1;
const int WEIGHT_ADV_CRG_LOW = 1;

const int WEIGHT_STRUCT_FREESLOT_NOGOV = 100;
const int WEIGHT_STRUCT_FREESLOT_RENOVATE = 100;
const int WEIGHT_STRUCT_OFFLINE = 100;
const int WEIGHT_STRUCT_DESTROYED = 100;
const int WEIGHT_STRUCT_WORKERS_LOW = 100;

//CLASSES

class econCheck : check
{
	int calcWeight(Planet@ pl) {
		Object@ obj = pl.toObject();
		int weight = 0;

		bool queue = (obj.getConstructionQueueSize() > 0);

		PlStates@ pls = PlStates(obj);

		int mtlDiff = effDiff(pls.MtlGen.val, pls.MtlGenOpt.val);						// Metals (Production efficiency)
		int elcDiff = effDiff(pls.ElcGen.val, pls.ElcGenOpt.val);						// Electronics (Production efficiency)
		int advDiff = effDiff(pls.AdvGen.val, pls.AdvGenOpt.val);						// Adv. Parts (Production efficiency)
		int mtlcDiff = cargoDiff(pls.Mtl, pls.TradeTarget, pls.Cargo.left, pls.MtlExp);	// Metals (Cargo %)
		int elccDiff = cargoDiff(pls.Elc, pls.TradeTarget, pls.Cargo.left, pls.ElcExp);	// Electronics (Cargo %)
		int advcDiff = cargoDiff(pls.Adv, pls.TradeTarget, pls.Cargo.left, pls.AdvExp);	// AdvParts (Cargo %)

		// Weight calc
		if (queue)
			weight += WEIGHT_QUEUE;

		weight += mtlDiff * WEIGHT_MTL_EFF;
		if (mtlcDiff < 0)
			weight += int(abs(mtlcDiff)) * WEIGHT_MTL_CRG_LOW;
		else
			weight += mtlcDiff * WEIGHT_MTL_CRG;

		if (elccDiff < 0) {
			weight += elcDiff * WEIGHT_ELC_EFF_NORES;
			weight += int(abs(elccDiff)) * WEIGHT_ELC_CRG_LOW;
		}
		else {
			weight += elcDiff * WEIGHT_ELC_EFF_NOCRG;
			weight += elccDiff * WEIGHT_ELC_CRG;
		}

		if (advcDiff < 0) {
			weight += advDiff * WEIGHT_ADV_EFF_NORES;
			weight += int(abs(advcDiff)) * WEIGHT_ADV_CRG_LOW;
		}
		else {
			weight += advDiff * WEIGHT_ADV_EFF_NOCRG;
			weight += advcDiff * WEIGHT_ADV_CRG;
		}

		return weight;
	}

	infoPanel@ createInfoPanel(Planet@ pl, pos2di position, GuiElement@ parent) {
		return econPanel(pl, position, parent);
	}
}

class structureCheck : check
{
	int calcWeight(Planet@ pl) {
		Object@ obj = pl.toObject();
		int weight = 0;

		bool queue = (obj.getConstructionQueueSize() > 0);

		uint[] arrEmpDef = getStructuresWithHousingOrWorkers(obj);

		int cnt = pl.getStructureCount();
		int max = pl.getMaxStructureCount();

		float housing_que = 0;
		float workers_que = 0;
		int queStr = 0;
		uint que = obj.getConstructionQueueSize();
		for (uint i = 0; i < que; ++i) {
			string@ type = obj.getConstructionType(i);
			string@ name = obj.getConstructionName(i);
			if (@type != null && type == "structure")
			{
				SubSystemFactory factory;
				subSystem@ ss = getSubSystemFromName(factory, pl, name, arrEmpDef);
				if (@ss != null) {
					if (ss.hasHint(strHousing))
						housing_que += ss.getHint(strHousing);
					if (ss.hasHint(strWorkers))
						workers_que += ss.getHint(strWorkers);
				}

				++queStr;
			}
		}

		if (max - cnt - queStr > 0) // free slots
		{
			if (pl.usesGovernor())
			{
				string@ governor = pl.getGovernorType();
				if (governor == "rebuilder")
					weight += WEIGHT_STRUCT_FREESLOT_RENOVATE;
			}
			else
				weight += WEIGHT_STRUCT_FREESLOT_NOGOV;
		}

		PlanetStructureList list;
		list.prepare(pl);
		uint strCnt = list.getCount();

		float housing = 0;
		float workers = 0;
		for(uint i = 0; i < strCnt; ++i) {
			const subSystem@ ss = list.getStructure(i);

			if (ss.hasHint(strHousing))
				housing += ss.getHint(strHousing);
			if (ss.hasHint(strWorkers))
				workers += ss.getHint(strWorkers);

			//const subSystemDef@ ssd = ss.type;
			//warning(ssd.getName());
			//warning("H: " + standardize(ss.getHint(strHousing)));
			//warning("W: " + standardize(ss.getHint(strWorkers)));
			//for (uint h = 0; h < ss.getHintCount(); h++) {
			//	warning("  " + ss.getHintName(h));
			//}

			switch(list.getStructureState(i).getState()) {
				case SS_Disabled:
					weight += WEIGHT_STRUCT_OFFLINE;
					break;
				case SS_Destroyed:
					weight += WEIGHT_STRUCT_DESTROYED;
					break;
			}
		}

		float workersDiff = (housing + housing_que + workers + workers_que);
		if (workersDiff < 0) {
			weight += WEIGHT_STRUCT_WORKERS_LOW;
		}

		return weight;
	}

	infoPanel@ createInfoPanel(Planet@ pl, pos2di position, GuiElement@ parent) {
		return structurePanel(pl, position, parent);
	}
}

//FUNCTIONS

int effDiff(float gen, float opt)
{
	if (opt > 0) {
		float pct = gen / opt;
		float diff = 1.f - pct;
		return int(diff * 100);
	}
	return 0;
}

int cargoDiff(St@ st, St@ tt, float left, float exp)
{
	float gen = st.val + st.cargo;
	float opt = st.max + st.cargo + left;

	if (opt > 0) {
		float pct = gen / opt;
		if (pct > 1.f)
			return 0;

		float diff;
		if (exp > 0) // special trade behavior is only for exporting resources
			diff = pct - tt.val;
		else
			diff = pct - 0.5f;
		return int(diff * 100);
	}
	return 0;
}

// create array with empire structures with Housing or Workers only
uint[] getStructuresWithHousingOrWorkers(Object@ obj)
{
	uint[] arrEmpDef;
	for (uint s = 0; s < obj.getOwner().getSubSysDataCnt(); s++) {
		const subSystemDef@ ssd = obj.getOwner().getSubSysData(s).type;
		for (uint h = 0; h < ssd.getHintCount(); h++) {
			const string@ hn = ssd.getHintName(h);
			if (hn == strHousing || hn == strWorkers) {
				arrEmpDef.resize(arrEmpDef.length() + 1);
				arrEmpDef[arrEmpDef.length()-1] = s;
				break;
			}
		}
	}

	return arrEmpDef;
}

subSystem@ getSubSystemFromName(SubSystemFactory@ factory, Planet@ pl, string@ name, uint[] arrEmpDef)
{
	Object@ obj = pl.toObject();
	for (uint s = 0; s < arrEmpDef.length(); s++) {
		const subSystemDef@ ssd = obj.getOwner().getSubSysData(arrEmpDef[s]).type;
		const string@ ssd_name = ssd.getName();
		if (name == ssd_name) {
			factory.objectScale = 10.f;
			factory.objectSizeFactor = 10.f;
			factory.prepare(pl);
			if(factory.generateSubSystems(ssd, null))
				return factory.get_active();
		}
	}

    return null;
}
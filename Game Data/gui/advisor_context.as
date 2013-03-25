//advisor_context.as
//=================
//methods for context menues

//IMPORTS
import string@ formatDistance(float range) from "gui";
import string@ formatValue(float val, float max, string@ name, Color full, Color empty) from "gui";
import string@ formatValue(int val, int max, string@ name, Color full, Color empty) from "gui";
import string@ formatState(Object@ obj, string@ state, string@ name, Color full, Color empty, bool reverse) from "gui";

//EXPORTS

const float unitsPerAU = 1000.f;

string@ getPlanetContext(Object@ obj) {
	//Object@ curObject;
	//string@ strJumpDrive = "Jump Drive", strMinRange = "vJumpRangeMin", strMaxRange = "vJumpRange";

	ObjectLock lock(obj);

	//@curObject = @obj;
	HulledObj@ hull;
	Planet@ pl = obj;
	System@ sys = obj;
	Star@ star = obj;

	Empire@ emp = getActiveEmpire();
	Empire@ owner = obj.getOwner();
	
	Color ownerColor = owner.color;

	string@ mo_text = combine("#c:", ownerColor.format(), "#", obj.getName(), "#c#");

	if (@pl != null && owner is emp)
		if (!pl.usesGovernor())
			mo_text += " ("+localize("#PG_NoGov")+")";
		else
			mo_text += " ("+localize("#PG_"+pl.getGovernorType())+")";

	mo_text += formatState(obj, "Damage", localize("#MO_HP"), Color(255, 0, 220, 0), Color(255, 255, 0, 0), true);
	mo_text += formatState(obj, "Shields", localize("#MO_Shields"), Color(255, 80, 180, 200), Color(255, 200, 80, 180), false);
	
	float used, max;
	obj.getCargoVals(used, max);
	if(max > 0.f)
		mo_text += formatValue(used, max, localize("#MO_Cargo"), Color(0xffCDCDCD), Color(0xff737373));
	obj.getShipBayVals(used, max);
	if(max > 0.f)
		mo_text += formatValue(used, max, localize("#MO_ShipBay"), Color(0xff7DA7D9), Color(0xff605CA8));

	if (pl !is null && obj.isVisibleTo(emp)) {
		mo_text += formatState(obj, "Workers", localize("#MO_Population"), Color(0xffa65296), Color(0xffd23323), false);

		mo_text += formatValue(int(pl.getStructureCount()), int(pl.getMaxStructureCount()),
				localize("#MO_Slots"), Color(0xffA67C52), Color(0xff616161));
	}
	
	if(owner is emp) {
		if(@pl != null) {
			uint condCnt = pl.getConditionCount();
			if(condCnt > 0) {
				mo_text += combine("\n",localize("#MO_Conditions"),": ");
				for(uint i = 0; i < condCnt; ++i) {
					const PlanetCondition@ cond = pl.getCondition(i);
					if (@cond != null)
						if(i != 0)
							mo_text += ", " + localize("#PC_" + cond.get_id());
						else
							mo_text += localize("#PC_" + cond.get_id());
					else
						error("Planet condition was null: "+i+"/"+condCnt);
				}
			}
		}
		
		uint queue = obj.getConstructionQueueSize();
		if(queue > 0) {
			mo_text += "\n"+localize("#MO_Building")+" ";
			string@ cnstr_name = obj.getConstructionName();
			if(@cnstr_name != null)
				mo_text += cnstr_name + " ";
			mo_text += "(" + round(obj.getConstructionProgress() * 100) + "%)";
			if(queue > 1)
				mo_text += "\n  " + (queue - 1) + " "+localize("#more_in_queue");
		}
	}
	else if(obj.toOddity() !is null) {
		mo_text += formatState(obj, "Ore", localize("#MO_Ore"), Color(255, 0xC6, 0x9C, 0x6D), Color(255, 0x73, 0x63, 0x57), false);
	}
	
	if (pl is null || obj.thrust > 0) {
		float speed = obj.velocity.getLength() / unitsPerAU;
		if(speed > 0.001f) {
			string@ speedText;
			if(speed < 0.1f)
				@speedText = f_to_s(speed, 3);
			else if(speed < 1.f)
				@speedText = f_to_s(speed, 2);
			else if(speed < 10.f)
				@speedText = f_to_s(speed, 1);
			else
				@speedText = standardize(speed);
		
			mo_text += "\n"+localize("#MO_Speed")+speedText+localize("#MO_AUps");
		}
	}
	
	Object@ selected = getSelectedObject(getSubSelection());
	if(selected !is null && selected !is obj) {
		string@ strAU = localize("#MO_AU");
		float dist = selected.getPosition().getDistanceFrom(obj.getPosition());
		if(dist > 0.01f) {
			mo_text += combine("\n", localize("#MO_Distance"), formatDistance(dist), strAU);
		}
	}
		
	return combine("#font:stroked#", mo_text, "#font#");
}

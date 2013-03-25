void export_layout(string@ folderName, string@ layoutName) {
	if(layoutName is null || layoutName.length() == 0 || folderName is null || folderName.length() == 0)
		return;
	export_layout( getActiveEmpire().getShipLayout(layoutName), folderName, layoutName);
}

bool export_layout(const HullLayout@ layout,string@ folderName, string@ layoutName) {
	return export_layout(layout, folderName, layoutName, false);
}

bool export_layout(const HullLayout@ layout, string@ folderName, string@ layoutName, bool exportOrders) {
	if(layout is null || layout.getSubSysCnt() == 0 || layoutName.length() == 0 || folderName.length() == 0)
		return false;
	
	XMLWriter@ xml;
	if(!folderName.opEquals("Default")) {
		@xml = XMLWriter("Layouts/" + folderName + "/" + layoutName);
	}
	else {
		@xml = XMLWriter("Layouts/" + layoutName);
	}
	
	if(xml is null)
		return false;
	
	xml.createHeader();
	
	xml.addElement("settings", true, "scale", ftos_nice(layout.scale * layout.scale, 3), "name", layoutName);
	xml.addLineBreak();
	
	xml.addElement("subSystems", false);
	xml.addLineBreak();
	for(uint i = 0; i < layout.getSubSysCnt(); ++i) {
		const subSystem@ curSubSystem = layout.getSubSys(i);
		pos2df subSysPos = layout.getSubSysPos(i);
		int linkIndex = layout.getSubSysLink(i);
		
		xml.addElement("subSystem", true, "name", getSubSystemReferenceName(curSubSystem.type.ID), "x", ftos_nice(subSysPos.x), "y", ftos_nice(subSysPos.y), "scale", ftos_nice(curSubSystem.scale), "link", i_to_s(linkIndex));
		xml.addLineBreak();
	}
	xml.closeTag("subSystems");
	xml.addLineBreak();
	
	xml.addElement("ai", false);
	xml.addLineBreak();
		float low, hi;
		bool forced;

		if(layout.getTargetScales(low, hi, forced)) {
			xml.addElement("targetScale", true, "low", ftos_nice(low), "hi", ftos_nice(hi), "forced", forced ? "true" : "false");
			xml.addLineBreak();
		}
		if(layout.getTargetDamage(low, hi, forced)) {
			xml.addElement("targetDamage", true, "low", ftos_nice(low), "hi", ftos_nice(hi), "forced", forced ? "true" : "false");
			xml.addLineBreak();
		}
		xml.addElement("orbit", true, "flag", layout.orbits ? "true" : "false");
		xml.addLineBreak();

		xml.addElement("allowFetch", true, "flag", layout.allowFetch ? "true" : "false");
		xml.addLineBreak();

		xml.addElement("allowDeposit", true, "flag", layout.allowDeposit ? "true" : "false");
		xml.addLineBreak();

		xml.addElement("allowSupply", true, "flag", layout.allowSupply ? "true" : "false");
		xml.addLineBreak();

		bool ships, planets, stations;

		layout.getAllowTargets(ships, planets);
		xml.addElement("allowTargets", true, "ships", ships ? "true" : "false", "planets", planets ? "true" : "false");
		xml.addLineBreak();

		layout.getDepositTargets(ships, planets, stations);
		xml.addElement("depositTargets", true, "ships", ships ? "true" : "false", "planets", planets ? "true" : "false", "stations", stations ? "true" : "false");
		xml.addLineBreak();

		xml.addElement("multiTarget", true, "flag", layout.multiTarget ? "true" : "false");
		xml.addLineBreak();

		xml.addElement("engagementRange", true, "value", ftos_nice(layout.engagementRange));
		xml.addLineBreak();

		xml.addElement("defendRange", true, "value", ftos_nice(layout.defendRange));
		xml.addLineBreak();

		xml.addElement("defaultStance", true, "value", i_to_s(int(layout.defaultStance)));
		xml.addLineBreak();

		layout.getDockTargets(ships, planets, stations);
		xml.addElement("dockTargets", true, "ships", ships ? "true" : "false", "planets", planets ? "true" : "false", "stations", stations ? "true" : "false");
		xml.addLineBreak();

		xml.addElement("dockMode", true, "mode", layout.dockMode == DM_Never ? "0" : (layout.dockMode == DM_Clear ? "1" : "2"));
		xml.addLineBreak();

		xml.addElement("carrierMode", true, "mode", i_to_s(int(layout.carrierMode)));
		xml.addLineBreak();
		
		if(layout.defaultFighter !is null) {
			xml.addElement("defaultFighter", true, "value", layout.defaultFighter.getName());
			xml.addLineBreak();
		}		

	xml.closeTag("ai");
	xml.addLineBreak();

	if (exportOrders) {
		xml.addElement("orders", false);
		xml.addLineBreak();

		uint orderCnt = layout.getOrderCount();
		for (uint i = 0; i < orderCnt; ++i) {
			xml.addElement("order", true, "desc", layout.getOrder(i).toString());
			xml.addLineBreak();
		}

		xml.closeTag("orders");
		xml.addLineBreak();
	}

	return true;
}

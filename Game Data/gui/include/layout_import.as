void import_layout(LayoutWindow@ win, string@ folderName, string@ layoutName) {
	if(layoutName.length() == 0)
		return;
	
	XMLReader@ xml;
	if(!folderName.opEquals("Default")) {
		@xml = XMLReader("Layouts/" + folderName + "/" + layoutName);
	}
	else {
		@xml = XMLReader("Layouts/" + layoutName);
	}	
	
	if(xml is null)
		return;
	
	while(xml.advance()) {
		if(xml.getNodeType() == XN_Element) {
			string@ nodeName = xml.getNodeName();
			
			if(nodeName == "settings") {
				float newScale = s_to_f(xml.getAttributeValue("scale"));
				if(newScale < 0.0001f)
					continue;
				if(xml.hasAttribute("name"))
					layoutName = xml.getAttributeValue("name");
				win.clearLayout();
				win.setScale(newScale);
				win.setName(layoutName);
			}
			else if(nodeName == "subSystems") {
				loadSubSystemsFromXML(win, xml);
			}
			else if(nodeName == "ai") {
				loadAIFromXML(win, xml);
			}
			else if(nodeName == "orders") {
				loadOrdersFromXML(win, xml);
			}
		}
	}
	
	win.handleQueuedLinks();
	win.updateLayout();
}

//Loads all elements from the <subSystems></subSystems> segment of the xml file
void loadSubSystemsFromXML(LayoutWindow@ win, XMLReader@ xml) {
	while(xml.advance()) {
		switch(xml.getNodeType()) {
			case XN_Element:
				if(xml.getNodeName() == "subSystem") {
					string@ globalName = xml.getAttributeValue("name");
					pos2df subSysPos( s_to_f(xml.getAttributeValue("x")), s_to_f(xml.getAttributeValue("y")) );
					int link = s_to_i(xml.getAttributeValue("link"));
					float scale = s_to_f(xml.getAttributeValue("scale"));
					
					const subSystemDef@ subSysDef = getSubSystemDefByName(globalName);
					
					if(@subSysDef != null) {
						win.addSubSystem(subSysDef.ID, scale, subSysPos);

						if (link > 0)
							win.addQueuedLink(win.subSystems.length() - 1, link);
					}
				}
				break;
			case XN_Element_End:
				if(xml.getNodeName() == "subSystems")
					return;
				break;
		}
	}
}

bool loadAIFromXML(LayoutWindow@ win, XMLReader@ xml) {
	while(xml.advance()) {
		switch(xml.getNodeType()) {
			case XN_Element:
				{
					const string@ nodeName = xml.getNodeName();
					if(nodeName == "targetScale") {
						win.setTargetScales(s_to_f(xml.getAttributeValue("low")), s_to_f(xml.getAttributeValue("hi")), xml.getAttributeValue("forced") == "true");
					}
					else if(nodeName == "targetDamage") {
						win.setTargetDamage(s_to_f(xml.getAttributeValue("low")), s_to_f(xml.getAttributeValue("hi")), xml.getAttributeValue("forced") == "true");
					}
					else if(nodeName == "orbit") {
						win.setOrbits(xml.getAttributeValue("flag") == "true");
					}
					else if(nodeName == "multiTarget") {
						win.setMultiTarget(xml.getAttributeValue("flag") == "true");
					}
					else if(nodeName == "engagementRange") {
						win.setEngagementRange(s_to_f(xml.getAttributeValue("value")));
					}
					else if(nodeName == "allowFetch") {
						win.setAllowFetch(xml.getAttributeValue("flag") == "true");
					}
					else if(nodeName == "allowDeposit") {
						win.setAllowDeposit(xml.getAttributeValue("flag") == "true");
					}
					else if(nodeName == "allowSupply") {
						win.setAllowSupply(xml.getAttributeValue("flag") == "true");
					}
					else if(nodeName == "dockMode") {
						int mode = s_to_i(xml.getAttributeValue("mode"));
						win.setDockMode(mode == 0 ? DM_Never : (mode == 1 ? DM_Clear : DM_Contested));
					}
					else if(nodeName == "carrierMode") {
						int mode = s_to_i(xml.getAttributeValue("mode"));
						win.setCarrierMode(CarrierMode(mode));
					}
					else if(nodeName == "allowTargets") {
						win.setAllowTargets(xml.getAttributeValue("ships") == "true", xml.getAttributeValue("planets") == "true");
					}
					else if(nodeName == "depositTargets") {
						win.setDepositTargets(xml.getAttributeValue("ships") == "true", xml.getAttributeValue("planets") == "true", xml.getAttributeValue("stations") == "true");
					}
					else if(nodeName == "dockTargets") {
						win.setDockTargets(xml.getAttributeValue("ships") == "true", xml.getAttributeValue("planets") == "true", xml.getAttributeValue("stations") == "true");
					}
					else if (nodeName == "defendRange") {
						win.setDefendRange(s_to_f(xml.getAttributeValue("value")));
					}
					else if (nodeName == "defaultStance") {
						win.setDefaultStance(AIStance(s_to_i(xml.getAttributeValue("value"))));
					}
					else if (nodeName == "defaultFighter") {
						win.setDefaultFighter(xml.getAttributeValue("value"));
					}					
				} break;
			case XN_Element_End:
				if(xml.getNodeName() == "ai")
					return true;
				break;
		}
	}
	return true;
}

void loadOrdersFromXML(LayoutWindow@ win, XMLReader@ xml) {
	while(xml.advance()) {
		switch(xml.getNodeType()) {
			case XN_Element:
				if(xml.getNodeName() == "order") {
					string@ str = xml.getAttributeValue("desc");
					OrderDescriptor@ desc = createOrderDescriptor(str);
					win.addOrderToDesign(desc);
					freeOrderDescriptor(desc);
				}
				break;
			case XN_Element_End:
				if(xml.getNodeName() == "orders")
					return;
				break;
		}
	}
}

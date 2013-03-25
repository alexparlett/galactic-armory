#include "~/Game Data/gui/include/str_indicator.as"
#include "~/Game Data/gui/include/gui_skin.as"

//pinned_objects.as
//=================
//This file generates the pinned object icons/readouts that are available to the user
//Pinned objects show up as an icon with a few readouts related to the object's status
//
import void triggerPlanetWin(Planet@ pl, bool bringToFront) from "planet_win";
import void triggerQueueWin(Object@ obj) from "queue_win";
import void showSystemWindow(System@ sys) from "sys_win";
import int getPlanetIconIndex(string@ physicalType) from "planet_icons";
import void triggerContextMenu(Object@) from "context_menu";

//Delay till requesting multiplayer updates for pinned objects
const float syncDelay = 0.333f;
float syncTimer = 0;

enum ScrEventResult {
	SER_None,
	SER_Done,
	SER_Absorb
};

int pinnedElementID;
string@ lc_idle;
Empire@ prevEmp;
GuiButton@ newPinButton;

Color transparent;
Color opaque;

const float barUpdateInterval = 1.f;

//pin (interface)
//===============
//
interface pin {
	Object@ getObject();
	
	//Should return true if the object is to be un-pinned
	bool update(float tick, uint visualIndex);
	
	//Removes the related elements from the interface
	void removePin();

	//Save the pin
	void save(XMLWriter@ xml);
	
	ScrEventResult OnEvent(const GUIEvent@ evt);
};

class planetPin : pin {
	Object@ obj;
	GuiPanel@ panel;
	GuiButton@ icon;
	GuiExtText@ name;
	GuiExtText@ data;
	string@ objName;

	GuiImage@ zoom;
	GuiImage@ remove;
	Fleet@ fleet;

	GuiScripted@ strBar;
	StrengthBar@ strScript;
	
	int prevOwnerID;
	bool wasIdle;

	float barUpdate;
	
	planetPin(Object@ object) {
		@obj = @object;
		int y = pinYStart + ((pinHeight + pinSpacing) * pins.length());
		
		const int panelWidth = 170;
		
		@panel = GuiPanel(recti( pos2di( pinLeftMargin, y), dim2di( panelWidth, 33)), false, SBM_Invisible, SBM_Invisible, null);
		panel.setID(pinnedElementID);

		// Create system strength bar for stars or systems
		if (object.toSystem() !is null || object.toStar() !is null) {
			@strScript = StrengthBar();
			@strBar = GuiScripted(recti(pos2di(36, 16), dim2di(panelWidth-30, 12)), strScript, panel);
			strScript.init(strBar);
			strScript.outlineCol.A = 255;

			barUpdate = 0.f;
		}
		
		// Icon
		@icon = GuiButton(recti( pos2di(0, 0), dim2di(pinHeight, pinHeight)), null, panel);

		if(@object.toPlanet() != null) {
			if (object.toPlanet().hasCondition("ringworld_special")) {
				icon.setImages("ringworld_icon", "ringworld_icon");
			}
			else {
				int ind = getPlanetIconIndex(object.toPlanet().getPhysicalType());
				icon.setSprites("planet_icons_new", ind, ind, ind);
			}
		}
		else if (object.toOddity() !is null) {
			icon.setImages("asteroid_icon", "asteroid_icon");
		}
		else if(@obj.toHulledObj() != null) {
			string@ bank = "neumon_shipset";
			uint ind = 2;

			obj.toHulledObj().getSpriteIcon(bank, ind);

			icon.setSprites(bank, ind, ind, ind);
		}
		else {
			const string@ iconMaterial = "ship_ico_small";
			if(@obj.toStar() != null) {
				@iconMaterial = "sys_list_star";
			}
			else if(@obj.toSystem() != null) {
				@iconMaterial = "sys_list_planet_group";
			}
			else {
				@iconMaterial = "sys_list_star";
			}
			icon.setImages(iconMaterial, iconMaterial);
		}

		icon.setAppearance(BA_ScaleImage,BA_Background);
		icon.setID(pinnedElementID);

		// Zoom button
		@zoom = GuiImage(pos2di(0, 0), "clause_edit", panel);
		zoom.setClickThrough(false);
		zoom.setScaleImage(true);
		zoom.setSize(dim2di(12, 12));
		zoom.setColor(transparent);
		zoom.setID(pinnedElementID);

		// Remove button
		@remove = GuiImage(pos2di(20, 0), "remove_pin", panel);
		remove.setClickThrough(false);
		remove.setScaleImage(true);
		remove.setSize(dim2di(12, 12));
		remove.setColor(transparent);
		remove.setID(pinnedElementID);
		
		//Inititalize to a gibberish ID
		prevOwnerID = -5821934;
		bool wasIdle = false;
		
		@name = GuiExtText( recti( pos2di(36, -2), dim2di( panelWidth - 34, 16)), panel);
		name.setID(pinnedElementID);
		
		@data = GuiExtText( recti( pos2di(36, 16 -2), dim2di( panelWidth - 34, 16)), panel);
		data.setID(pinnedElementID);

		@objName = object.getName();
	}

	void setFleet(Fleet@ newFleet) {
		@fleet = newFleet;
		@obj = fleet.getCommander();
	}
	
	Object@ getObject() { return obj; }

	bool update(float tick, uint visualIndex) {
		if (fleet is null)
			return updateObject(tick, visualIndex);
		else
			return updateFleet(tick, visualIndex);
	}

	bool updateFleet(float tick, uint visualIndex) {
		@obj = fleet.getCommander();
		if(fleet.getMemberCount() == 0 && (obj is null || !obj.isValid()))
			return true;
		pos2di pos = panel.getPosition();
		int y = pinYStart + ((pinHeight + pinSpacing) * visualIndex);
		if(pos.y != y) {
			pos.y = y;
			animate(panel, pos, panel.getSize(), 700);
		}

		Empire@ owner = obj.getOwner();
		if(@owner != null && (owner.ID != prevOwnerID || objName != fleet.getName())) {
			prevOwnerID = owner.ID;
			@objName = fleet.getName();
			string@ ownerCol = owner.color.format();
			name.setText(combine("#font:stroked##c:", ownerCol, "#", objName, "#c##font#"));
		}

		if (owner is getActiveEmpire())
			data.setText(i_to_s(fleet.getMemberCount()+1)+" "+strShips);
		return false;
	}
	
	bool updateObject(float tick, uint visualIndex) {
		if(obj is null || !obj.isValid())
			return true;
		pos2di pos = panel.getPosition();
		int y = pinYStart + ((pinHeight + pinSpacing) * visualIndex);
		if(pos.y != y) {
			pos.y = y;
			animate(panel, pos, panel.getSize(), 700);
		}
		
		Empire@ owner = obj.getOwner();
		if(@owner != null && (owner.ID != prevOwnerID || objName != obj.getName())) {
			prevOwnerID = owner.ID;
			@objName = obj.getName();
			string@ ownerCol = owner.color.format();
			name.setText(combine("#font:stroked##c:", ownerCol, "#", objName, "#c##font#"));
		}
		
		string@ dataInfo;
		bool nowIdle = false;
		if(obj.getOwner() is getActiveEmpire()) {
			if(obj.getConstructionQueueSize() > 0) {
				float pct = obj.getConstructionProgress();
				@dataInfo = "#img:obj_building_yes#:" + f_to_s(pct * 100.f, 0) + "%";
			}
			else {
				OrderList orders;
				orders.prepare(obj);
				uint ordCnt = orders.getOrderCount();
				if(ordCnt > 0) {
					bool foundOrder = false;
					for (uint i = 0; i < ordCnt; ++i) {
						Order@ ord = orders.getOrder(i);
						if (!ord.isAutomation()) {
							foundOrder = true;
							@dataInfo = ord.getName();
							break;
						}
					}

					if (!foundOrder && !wasIdle)
						@dataInfo = lc_idle;
				}
				else if(!wasIdle) {
					@dataInfo = lc_idle;
				}
				orders.prepare(null);
			}
		}
		wasIdle = nowIdle;
		if(@dataInfo != null)
			data.setText(combine("#font:stroked#", dataInfo, "#font#"));

		// Update strength bar
		if (strScript !is null) {
			if (barUpdate <= 0.f) {
				SystemStats stats;
				strScript.update(obj.getCurrentSystem(), stats);
				barUpdate = barUpdateInterval;
			} else
				barUpdate -= tick;
		}

		return false;
	}
	
	void removePin() {
		icon.remove();
		panel.remove();
	}

	void focusCam() {
		if (!shiftKey && obj.toStar() is null)
			setCameraFocus(obj);
		else
			setCameraFocus(obj.getParent());
		setGuiFocus(null);
	}

	void save(XMLWriter@ xml) {
		if (fleet !is null)
			xml.addElement("p", true, "i", i_to_s(fleet.ID), "t", "fleet");
		else
			xml.addElement("p", true, "i", i_to_s(obj.uid), "t", "obj");
	}
	
	ScrEventResult OnEvent(const GUIEvent@ evt) {
		switch(evt.EventType) {
			case GEVT_Clicked:
			case GEVT_Focus_Gained:
				if ((evt.Caller is icon && evt.EventType == GEVT_Clicked) || evt.Caller is name || evt.Caller is data || evt.Caller is panel) {
					if(ctrlKey) {
						@obj = null;
						@fleet = null;
					}
					else {
						if (fleet !is null) {
							selectObject(null);
							ObjectLock lock(obj);
							addSelectedObject(obj);
							uint cnt = fleet.getMemberCount();
							for (uint i = 0; i < cnt; ++i)
								addSelectedObject(fleet.getMember(i));
						}
						else if(isSelected(obj)) {
							if (obj.toPlanet() !is null && obj.getOwner() is getActiveEmpire()) {
								triggerPlanetWin(obj.toPlanet(), true);
							}
							else if (obj.toStar() !is null) {
								showSystemWindow(obj.getCurrentSystem());
							}
							else if (obj.toSystem() !is null) {
								showSystemWindow(obj.toSystem());
							}
							else if (obj.toHulledObj() !is null){
								if (obj.toHulledObj().getHull().hasSystemWithTag("BuildBay"))
									triggerQueueWin(obj);
								else
									focusCam();
							}
						}
						else
							selectObject(obj);
						setGuiFocus(null); //Clear focus so the camera will work
						return SER_Absorb;
					}
				}
				break;
			case GEVT_Right_Clicked:
				if(evt.Caller is icon && obj !is null) {
					triggerContextMenu(obj);
					return SER_Absorb;
				}
				break;
		}

		if (evt.Caller is zoom) {
			if (evt.EventType == GEVT_Focus_Gained) {
				focusCam();
				return SER_Absorb;
			}
			else if (evt.EventType == GEVT_Mouse_Over) {
				zoom.setColor(opaque);
				return SER_Absorb;
			}
			else if (evt.EventType == GEVT_Mouse_Left) {
				zoom.setColor(transparent);
				return SER_Absorb;
			}
		}

		if (evt.Caller is remove) {
			if (evt.EventType == GEVT_Focus_Gained) {
				@obj = null;
				@fleet = null;
				return SER_Absorb;
			}
			else if (evt.EventType == GEVT_Mouse_Over) {
				remove.setColor(opaque);
				return SER_Absorb;
			}
			else if (evt.EventType == GEVT_Mouse_Left) {
				remove.setColor(transparent);
				return SER_Absorb;
			}
		}

		return SER_None;
	}
};

int pinLeftMargin = 4, pinYStart = 126, pinHeight = 32, pinSpacing = 4;
pin@[] pins;

int getPinEndHeight() {
	return pinYStart + ((pinHeight + pinSpacing) * pins.length()) + 24;
}

bool OnPinEvent(const GUIEvent@ evt) {
	for(uint i = 0; i < pins.length(); ++i)
		switch(pins[i].OnEvent(evt)) {
			case SER_Absorb:
				return true;
			case SER_Done:
				return false;
		}
	return false;
}

void updatePins(float tick) {
	for(uint i = 0; i < pins.length(); ++i) {
		if(pins[i].update(tick, i)) {
			unPin(i); --i;
		}
	}

	Object@ selected = getSelectedObject(getSubSelection());
	newPinButton.setVisible(selected !is null && isPinned(selected) == -1 && pinEnabled);

	newPinButton.setPosition(pos2di(pinLeftMargin+4, pinYStart + ((pinHeight + pinSpacing) * pins.length())));
	
	if(isClient()) {
		syncTimer -= tick;
		if(syncTimer < 0) {
			syncTimer = syncDelay;
			for(uint i = 0; i < pins.length(); ++i)
				requestObjectSync(pins[i].getObject());
		}
	}
}

void unPin(uint index) {
	pins[index].removePin();
	@pins[index] = null;
	for(uint i = index + 1, len = pins.length(); i < len; ++i)
		@pins[i-1] = @pins[i];
	pins.resize(pins.length() - 1);
}

int isPinned(Object@ obj) {
	for(uint i = 0, len = pins.length(); i < len; ++i) {
		if(pins[i].getObject() is obj)
			return int(i);
	}
	return -1;
}

//Creates the associated pin and adds it to the list
void addPin(Object@ obj) {
	if(obj is null || !obj.isValid() || isPinned(obj) >= 0)
		return;
	//Create new pin first, so it can position itself appropriately
	pin@ newPin = planetPin(obj);
	
	uint pinsLen = pins.length();
	pins.resize(pinsLen + 1);
	@pins[pinsLen] = @newPin;
}

void addFleetPin(Fleet@ fl) {
	if (fl is null)
		return;

	planetPin@ newPin = planetPin(fl.getCommander());
	newPin.setFleet(fl);

	uint pinsLen = pins.length();
	pins.resize(pinsLen + 1);
	@pins[pinsLen] = @newPin;
}

// Creates a pin for the selection
void pinSelection() {
	Object@ obj = getSelectedObject(getSubSelection());
	HulledObj@ ship = obj;

	// Non ships or non-owned objects are pinned as-is
	if (ship is null || obj.getOwner() !is getActiveEmpire()) {
		addPin(obj);
		return;
	}

	// If we have an entire fleet selected, pin the fleet
	ObjectLock lock(obj);
	Fleet@ fl = ship.getFleet();
	if (fl is null) {
		addPin(obj);
		return;
	}

	uint cnt = fl.getMemberCount();
	for (uint i = 0; i < cnt; ++i) {
		Object@ member = fl.getMember(i);
		if (!isSelected(member)) {
			addPin(obj);
			return;
		}
	}

	addFleetPin(fl);
}

//Pins the (singular) selected object
bool pinSelectedObject(uint8 flags) {
	if(flags & KF_Pressed != 0) {
		pinSelection();
		return true;
	}
	return false;
}

bool pinSelectedObject_btn(const GUIEvent@ evt) {
	if (evt.EventType == GEVT_Clicked) {
		pinSelection();
		return true;
	}
	return false;
}

enum LoadedPinType {
	LPT_Object,
	LPT_Fleet,
};

class LoadedPin {
	int id;
	LoadedPinType type;

	LoadedPin(int ID, LoadedPinType Type) {
		type = Type;
		id = ID;
	}

	void apply() {
		switch (type) {
			case LPT_Object:
				addPin(getObjectByID(id));
			break;
			case LPT_Fleet:
				addFleetPin(getFleetByID(id));
			break;
		}
	}
};
LoadedPin@[] loadedPins;
string@ strShips;

bool pinEnabled = true;
void setPinButtonVisible(bool vis) {
	pinEnabled = vis;
	newPinButton.setVisible(vis);
}

void init() {
	@prevEmp = getActiveEmpire();
	pinnedElementID = reserveGuiID();
	bindGuiCallback(pinnedElementID, "OnPinEvent");
	@lc_idle = localize("#idle");
	@strShips = localize("#FL_Members");

	transparent = Color(160, 255, 255, 255);
	opaque = Color(255, 255, 255, 255);
	
	bindFuncToKey('P', "pinSelectedObject");

	EmpireObjects objects;
	objects.prepare(getActiveEmpire());

	// Move pins down when displaying ship limit
	if (getGameSetting("LIMIT_SHIPS", 0) > 0)
		pinYStart += 20;

	@newPinButton = GuiButton(getSkinnable("Button"), recti(pinLeftMargin+4, pinYStart, pinLeftMargin+42, pinYStart+14), null, null);
	setTextExpand(newPinButton, localize("#pinBtn"));
	newPinButton.setToolTip(localize("#addPin"));

	bindGuiCallback(newPinButton, "pinSelectedObject_btn");
	
	if(loadedPins.length() == 0 && gameTime < 2.f) {
		if(objects.getCount() > 0) {
			uint maxObjs = 5;
			do {
				addPin(objects.getObject());
				maxObjs -= 1;
			} while(maxObjs > 0 && objects.nextObject());
		}
	}
	else {
		for(uint i = 0; i < loadedPins.length(); ++i)
			loadedPins[i].apply();
		loadedPins.resize(0);
	}
	objects.prepare(null);
}

void tick(float time) {
	// Check if we should try to find our first planet
	if (pins.length() == 0 && prevEmp !is getActiveEmpire()) {
		@prevEmp = getActiveEmpire();
		EmpireObjects objects;
		objects.prepare(prevEmp);

		uint cnt = objects.getCount();
		if (cnt == 0)
			@prevEmp = null;
		else for (uint i = 0; i < cnt; ++i) {
			Planet@ pl = objects.getObject();

			if (pl !is null) {
				addPin(pl.toObject());
				cameraZoomTo(pl.toObject(), true, false);
				cameraSetDistance(600.f);
				cameraSetTopDown(40.f);
				break;
			}
		}
	}

	updatePins(time);
}


void onSaveFileLoad(XMLReader@ xml) {
	while(xml.advance()) {
		const string@ name = xml.getNodeName();
		if(name == "p") {
			int id = s_to_i(xml.getAttributeValue("i"));
			uint len = loadedPins.length();
			loadedPins.resize(len+1);

			string@ type = xml.getAttributeValue("t");
			if (type == "fleet")
				@loadedPins[len] = LoadedPin(id, LPT_Fleet);
			else
				@loadedPins[len] = LoadedPin(id, LPT_Object);
		}
	}
}

void onSaveFileWrite(XMLWriter@ xml) {
	uint pinCount = pins.length();
	if(pinCount == 0)
		return;
	
	xml.createHeader();
	
	for(uint i = 0; i < pinCount; ++i)
		pins[i].save(xml);
}

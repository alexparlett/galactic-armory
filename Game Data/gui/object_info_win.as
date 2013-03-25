#include "~/Game Data/gui/include/dialog.as"
#include "~/Game Data/gui/include/gui_skin.as"

import int getPlanetIconIndex(string@ physicalType) from "planet_icons";
import void onClick(Object@) from "gui";
import void onDoubleClick(Object@) from "gui";
import void onRightClick(Object@) from "gui";

// {{{ Constants
string@ strDamage = "Damage", strShields = "Shields", strPower = "Power", strFuel = "Fuel", strShieldArmor = "ShieldArmor";
string@ strAmmo = "Ammo", strWorkers = "Workers";
string@ strAdvParts = "AdvParts", strElectronics = "Electronics", strMetals = "Metals", strOre = "Ore";
string@ strRingworldBonus = "ringworld_special";

string@ fuelLocale, ammoLocale;
Color pinGlobal;
Color pinStatic;

const Texture@ smBarTex;

const string[] statNames = {"Mood", "Ammo", "Food", "Heatsink", "Asteroids",
							"Crew", "Labr", "Ore", "H3", "Troops"};
const uint[] statColors = {0xff8fb54a, 0xffb54f4a, 0xff267d44, 0xffb54f4a, 0xff7d5a2b,
						   0xff4a74b5, 0xff43267d, 0xff7d5a2b, 0xff267d44, 0xff4a74b5};

const string[] econStats = {"Slots", "Ore", "AdvParts",
							"Electronics", "Metals"};
const uint[] econColors = {0xff267d44, 0xff7d5a2b, 0xff7e94a6,
						   0xffa0a600, 0xffa6a6a6};

const uint stances = 4;
const string[] stanceText = {"#ST_Engage", "#ST_Defend", "#ST_HoldPosition", "#ST_HoldFire"};
const AIStance[] stanceType = {AIS_Engage, AIS_Defend, AIS_HoldPosition, AIS_HoldFire};
const uint[] stanceSprite = {1, 7, 0, 2};
int[] stanceID;

const uint formations = 4;
const string[] formationText = {"#FF_Wall", "#FF_Box", "#FF_Escort", "#FF_Wedge"};
const FleetFormation[] formationType = {FF_Wall, FF_Box, FF_Escort, FF_Wedge};
const uint[] formationSprite = {5, 3, 6, 4};
int[] formationID;

// Default range for a local area defend onder
const float defaultLocalAreaSize = 40.f * 1000.f; // 40 AU
string@ standardize_nice(float val) {
	float absVal = abs(val);
	if (absVal < 0.005f)
		return "0.00";
	else if (val < 0)
		return "-"+standardize(absVal);
	else
		return standardize(absVal);
}
// }}}
// {{{ Stat bar
class StatBar : ScriptedGuiHandler {
	GuiScripted@ script;
	GuiStaticText@ label;
	GuiStaticText@ text;
	ObjectInfoWindow@ win;
	bool showBoth;
	bool hoverLabel;
	
	Color fillCol;
	Color bgCol;
	float value;
	uint textSize;

	float statValue;
	float statMax;
	bool intMode;
	bool hovered;

	const Texture@ barTex;

	StatBar(recti rectangle, uint textSpace, GuiElement@ parent, ObjectInfoWindow@ window) {
		pos2di pos = rectangle.UpperLeftCorner;
		dim2di size = rectangle.getSize();
		textSize = textSpace;
		@win = window;

		// Create the elements
		@script = GuiScripted(rectangle, this, parent);

		@label = GuiStaticText(recti(pos2di(2, 0), dim2di(textSpace - 2, size.height)),
				null, false, false, false, script);
		label.setTextAlignment(EA_Left, EA_Center);
		label.setVisible(false);
		label.setFont("stroked");

		@text = GuiStaticText(recti(pos2di(textSpace, 0),
				dim2di(size.width - textSpace - 2, size.height)),
				null, false, false, false, script);
		text.setTextAlignment(EA_Center, EA_Center);
		text.setFont("stroked");

		showBoth = true;
		hoverLabel = true;

		bgCol = Color(0xff666666);
		fillCol = Color(0xffffffff);
		value = 1.f;
		hovered = false;
	}
	void remove() {
		label.remove();
		text.remove();
		script.remove();
	}
	void setVisible(bool vis) {
		script.setVisible(vis);
	}
	void setHoverLabel(bool hover) {
		label.setVisible(!hover);
		if (hoverLabel != hover) {
			if (hover)
				text.setSize(text.getSize() + dim2di(6, 0));
			else
				text.setSize(text.getSize() - dim2di(6, 0));
		}

		hoverLabel = hover;
	}
	void update(bool both) {
		if ((both || hovered) && !hoverLabel) {
			if (statMax <= 0) {
				text.setText("- / -");
			}
			else {
				if (!intMode) {
					text.setText(combine(
						standardize_nice(statValue), " / ",
						standardize_nice(statMax)));
				}
				else {
					text.setText(combine(
						i_to_s(statValue), " / ",
						i_to_s(statMax)));
				}
			}
		}
		else {
			if (statMax <= 0) {
				text.setText("-");
			}
			else {
				if (!intMode) {
					text.setText(standardize_nice(statValue));
				}
				else {
					text.setText(i_to_s(statValue));
				}
			}
		}
	}
	
	void set(string@ labelText, float val, float max, Color pos, Color neg) {
		setVisible(true);

		label.setText(labelText);

		if (max <= 0) {
			bgCol = Color(0xff666666);
			value = 0.f;
		}
		else {
			fillCol = pos;
			bgCol = neg;

			value = clamp(val / max, 0.f, 1.f);
		}
		statValue = val;
		statMax = max;
		intMode = false;

		update(showBoth);		
	}
	void setInt(string@ labelText, int val, int max, Color pos, Color neg) {
		setVisible(true);
		label.setText(labelText);

		if (max <= 0) {
			bgCol = Color(0xff666666);
			value = 0.f;
		}
		else {
			fillCol = pos;
			bgCol = neg;
			value = clamp(float(val) / float(max), 0.f, 1.f);
		}	
		statValue = float(val);
		statMax = float(max);
		intMode = true;

		update(showBoth);		
	}

	void draw(GuiElement@ ele) {
		ele.toGuiScripted().setAbsoluteClip();
		recti absPos = ele.getAbsolutePosition();

		if (!hoverLabel) {
			absPos = recti(
				absPos.UpperLeftCorner + pos2di(textSize, 4),
				absPos.LowerRightCorner - pos2di(4, 4)
			);
		}

		const pos2di topLeft = absPos.UpperLeftCorner;
		const pos2di botRight = absPos.LowerRightCorner;
		const dim2di size = absPos.getSize();
		int offset = max(value * float(size.width), 0.f);

		if (barTex is null) {
			drawRect(recti(topLeft,
				pos2di(topLeft.x + offset, botRight.y)),
				fillCol);

			drawRect(recti(topLeft + pos2di(offset, 0),
				botRight), bgCol);
		}
		else {
			drawTexture(barTex,
					recti(topLeft, pos2di(topLeft.x + offset, botRight.y)),
					recti(pos2di(), dim2di(offset, barTex.size.height)),
					fillCol, true);

			drawTexture(barTex,
					recti(topLeft + pos2di(offset, 0), botRight),
					recti(pos2di(offset, 0), barTex.size - dim2di(offset, 0)),
					bgCol, true);
		}

		clearDrawClip();
	}

	void hover() {
		if (!hovered) {
			if (hoverLabel)
				label.setVisible(true);
			hovered = true;
			update(true);
		}
	}

	void unhover() {
		if (hovered) {
			if (hoverLabel)
				label.setVisible(false);
			hovered = false;
			update(showBoth);
		}
	}
	EventReturn onGUIEvent(GuiElement@ ele, const GUIEvent& evt) {
		switch (evt.EventType) {
			case GEVT_Mouse_Over:
				if (win is null)
					hover();
				else
					win.hoverBars();
				break;
			case GEVT_Mouse_Left:
				if (win is null)
					unhover();
				else
					win.unhoverBars();
				break;
		}
		return ER_Pass;
	}

	EventReturn onKeyEvent(GuiElement@ ele, const KeyEvent& evt) {
		return ER_Pass;
	}

	EventReturn onMouseEvent(GuiElement@ ele, const MouseEvent& evt) {
		return ER_Pass;
	}
};
// }}}
// {{{ Object Info Window
class ObjectInfoWindow : ScriptedGuiHandler {
	GuiScripted@ script;
	Object@ obj;
	Empire@ owner;
	bool pinned;

	GuiImage@ fleetIcon;
	GuiButton@ icon;
	GuiStaticText@ name;
	GuiStaticText@ curOrder;
	StatBar@[] bars;
	GuiButton@ resize;

	GuiStaticText@ automationText;
	GuiButton@[] automation;

	GuiButton@ stayButton;
	GuiButton@ DRButton;
	GuiButton@[] stButtons;
	GuiButton@[] ffButtons;

	GuiPanel@ ordersPanel;
	GuiStaticText@[] orders;
	GuiButton@[] removeOrders;
	GuiStaticText@ noOrdersText;

	GuiButton@ statsButton;
	GuiButton@ cargoButton;
	GuiButton@ econButton;
	GuiButton@ ordersButton;

	GuiPanel@ statsPanel;
	StatBar@[] statBars;

	GuiPanel@ econPanel;
	StatBar@[] econBars;

	GuiPanel@ cargoPanel;
	GuiExtText@ cargoText;

	float updateTime;
	int removeID;
	int automationID;
	bool expanded;

	ObjectInfoWindow(recti pos) {
		@script = GuiScripted(pos, this, null);
		removeID = reserveGuiID();
		expanded = true;

		// Object Icon
		@icon = GuiButton(recti(pos2di(126, 5), dim2di(57, 57)), null, script);
		icon.setAppearance(BA_ScaleImage,BA_Background);

		@fleetIcon = GuiImage(pos2di(316, 5), "fleet_leader_gui", script);

		// Object Name
		@name = GuiStaticText(
				recti(pos2di(124, 4), dim2di(216, 20)),
				null, false, false, false, script);
		name.setTextAlignment(EA_Center, EA_Center);
		name.setFont("stroked");

		// Object Order
		@curOrder = GuiStaticText(
				recti(pos2di(124, 24), dim2di(216, 20)),
				null, false, false, false, script);
		curOrder.setTextAlignment(EA_Center, EA_Top);
		curOrder.setFont("stroked");

		// Resize button
		@resize = GuiButton(recti(pos2di(212, 51), dim2di(39, 11)), null, script);
		resize.setImage("obj_info_resize");

		// Defend rango button
		@DRButton = GuiButton(recti(pos2di(439, 7), dim2di(21, 21)), null, script);
		DRButton.setToolTip(localize("#OI_EngageRange")+localize("#ER_System"));
		DRButton.setSprites("object_commands", 25, 26, 26);
		DRButton.setVisible(false);

		bindGuiCallback(DRButton, "DRButtonPressed");

		// Stay in Formation button
		@stayButton = GuiButton(recti(pos2di(4, 7), dim2di(21, 21)), null, script);
		stayButton.setToggleButton(true);
		stayButton.setToolTip(localize("#FF_Stay"));
		stayButton.setSprites("object_commands", 24, 26, 25);
		stayButton.setVisible(false);

		bindGuiCallback(stayButton, "stayButtonPressed");

		// Stance buttons
		stButtons.resize(stances);

		for (uint i = 0; i < stances; ++i) {
			@stButtons[i] = GuiButton(recti(pos2di(344+i*21, 7), dim2di(21, 21)), null, script);
			stButtons[i].setToggleButton(true);
			stButtons[i].setToolTip(localize(stanceText[i]));
			stButtons[i].setVisible(false);
			stButtons[i].setID(stanceID[i]);

			uint pos = stanceSprite[i]*3;
			stButtons[i].setSprites("object_commands", pos, pos+2, pos+1);
		}

		// Formation buttons
		ffButtons.resize(formations);

		for (uint i = 0; i < formations; ++i) {
			@ffButtons[i] = GuiButton(recti(pos2di(33+i*22, 7), dim2di(21, 21)), null, script);
			ffButtons[i].setToggleButton(true);
			ffButtons[i].setToolTip(localize(formationText[i]));
			ffButtons[i].setID(formationID[i]);
			ffButtons[i].setVisible(false);

			uint pos = formationSprite[i]*3;
			ffButtons[i].setSprites("object_commands", pos, pos+2, pos+1);
		}

		// Tab buttons
		@statsButton = ToggleButton(true, recti(pos2di(116, 67), dim2di(83, 13)),
						localize("#OI_Stats"), script);
		@econButton = ToggleButton(false, recti(pos2di(203, 67), dim2di(83, 13)),
						localize("#OI_Economy"), script);
		@cargoButton = ToggleButton(false, recti(pos2di(289, 67), dim2di(83, 13)),
						localize("#OI_Cargo"), script);
		@ordersButton = ToggleButton(false, recti(pos2di(375, 67), dim2di(85, 13)),
						localize("#OI_Orders"), script);

		recti panelPos(pos2di(116, 83), dim2di(344, 62));

		// Stats panel
		@statsPanel = GuiPanel(panelPos, false, SBM_Auto, SBM_Invisible, script);
		statsPanel.fitChildren();
		statBars.resize(statNames.length());

		// Economy panel
		@econPanel = GuiPanel(panelPos, false, SBM_Auto, SBM_Invisible, script);
		econPanel.fitChildren();
		econPanel.setVisible(false);
		econBars.resize(econStats.length());

		// Cargo panel
		@cargoPanel = GuiPanel(panelPos, false, SBM_Auto, SBM_Invisible, script);
		cargoPanel.fitChildren();
		cargoPanel.setVisible(false);
		@cargoText = GuiExtText(recti(8, 2, 208, 90), cargoPanel);

		// Orders panel
		@ordersPanel = GuiPanel(panelPos, false, SBM_Auto, SBM_Invisible, script);
		ordersPanel.fitChildren();
		ordersPanel.setVisible(false);

		// Create automation order buttons
		@automationText = GuiStaticText(recti(pos2di(4, 68), pos2di(111, 80)),
				localize("#OI_Automation"), false, false, false, script);
		automationText.setTextAlignment(EA_Center, EA_Center);

		automation.resize(9);
		automationID = reserveGuiID();
		for (uint i = 0; i < 9; ++i) {
			@automation[i] = GuiButton(recti(
				pos2di(4 + (i % 3) * 36, 82 + (i / 3) * 21),
				dim2di(36, 20)), null, script);
			automation[i].setID(automationID);
			automation[i].setAppearance(BA_ScaleImage, BA_Background);
		}

		// Create bars
		int x = 4;
		int y = 31;
		bars.resize(4);
		@bars[0] = StatBar(recti(pos2di(4, 31), dim2di(116, 14)), 72, script, null);
		@bars[1] = StatBar(recti(pos2di(4, 48), dim2di(116, 14)), 72, script, null);
		@bars[2] = StatBar(recti(pos2di(344, 31), dim2di(116, 14)), 72, script, null);
		@bars[3] = StatBar(recti(pos2di(344, 48), dim2di(116, 14)), 72, script, null);
		
		for (uint i = 0; i < 4; ++i) {
			bars[i].showBoth = false;
			@bars[i].barTex = getMaterialTexture("objectInfoBar");
			bars[i].text.setTextAlignment(EA_Right, EA_Center);
		}

		pinned = false;
		updateTime = 0;
	}

	void updateAutomation(GuiButton@ ele, Order@ ord) {
		string@ name = ord.getName();
		ele.setVisible(true);
		ele.setToolTip(name);

		uint ind = 0;
		switch (ord.getType()) {
			case OrdT_Colonize: ind = 0; break;
			case OrdT_Defend: ind = 1; break;
			case OrdT_AutoDock: ind = 2; break;
			case OrdT_AutoUnDock: ind = 3; break;
			case OrdT_Replenish: ind = 4; break;
			case OrdT_Work: ind = 5; break;
			case OrdT_Trade_Local: ind = 6; break;
			case OrdT_Fetch: {
				ind = 9;
				string@ resource = name.substr(fetchFront,
						name.length() - fetchBack - fetchFront);
				if (resource == fuelLocale)
					ind = 7;
				else if (resource == ammoLocale)
					ind = 8;
			} break;
			case OrdT_Collect: ind = 10; break;
			case OrdT_Supply: ind = 11; break;
			case OrdT_Deposit: ind = 12; break;
			case OrdT_AutoRetrofit: ind = 13; break;
			case OrdT_AutoExplore: ind = 14; break;
		}

		ele.setSprites("automation_icons", ind, ind, ind);
	}

	void hoverBars() {
		uint cnt = statBars.length();
		for(uint i = 0; i < cnt; ++i)
			if (statBars[i] !is null)
				statBars[i].hover();
		cnt = econBars.length();
		for(uint i = 0; i < cnt; ++i)
			if (econBars[i] !is null)
				econBars[i].hover();
	}

	void unhoverBars() {
		uint cnt = statBars.length();
		for(uint i = 0; i < cnt; ++i)
			if (statBars[i] !is null)
				statBars[i].unhover();
		cnt = econBars.length();
		for(uint i = 0; i < cnt; ++i)
			if (econBars[i] !is null)
				econBars[i].unhover();
	}
	
	bool isVisible() {
		return script.isVisible();
	}


	void setVisible(bool vis) {
		script.setVisible(vis);
	}

	recti getAbsolutePosition() {
		return script.getAbsolutePosition();
	}

	void setPosition(pos2di pos) {
		script.setPosition(pos - pos2di(0, 20));
	}

	void draw(GuiElement@ ele) {
		ele.toGuiScripted().setAbsoluteClip();
		const recti absPos = ele.getAbsolutePosition();
		const pos2di topLeft = absPos.UpperLeftCorner;
		const pos2di botRight = absPos.LowerRightCorner;
		const dim2di size = absPos.getSize();

		const Texture@ tex = getMaterialTexture("objectInfoWinBG");
		drawTexture(tex, topLeft, recti(pos2di(0, 0), tex.size), Color(0xffffffff), true);

		if (owner !is null && owner.ID > 0) {
			const Texture@ bg = getBackground(owner.background);
			drawTexture(bg, recti(topLeft + pos2di(124, 3), dim2di(216, 59)),
					recti(pos2di(0, 98), dim2di(256, 50)),
					Color(0xffffffff), true);
		}

		if (ordersPanel.isVisible()) {
			recti ordArea = recti(topLeft + pos2di(116, 83), dim2di(344, 62));
			setDrawClip(ordArea);

			uint ordCnt = orders.length();
			Color oddCol(0xff222222), evCol(0xff1a1a1a), bgCol(0xff303030);

			drawRect(ordArea, bgCol);
			for (uint i = 0; i < ordCnt; ++i) {
				recti pos = orders[i].getAbsolutePosition();
				pos = recti(pos.UpperLeftCorner - pos2di(6, 0),
							   pos.UpperLeftCorner + pos2di(344, 20));

				drawPane(pos, (i % 2 == 0) ? evCol : oddCol, true);
			}
		}

		clearDrawClip();
	}

	void updateIcon() {
		if(@obj.toPlanet() != null) {
			if (obj.toPlanet().hasCondition(strRingworldBonus)) {
				icon.setImages("ringworld_icon", "ringworld_icon");
			}
			else {
				int ind = getPlanetIconIndex(obj.toPlanet().getPhysicalType());
				icon.setSprites("planet_icons_new", ind, ind, ind);
				icon.setSize(dim2di(55, 55));
			}
		}
		else if (obj.toOddity() !is null) {
			icon.setImages("asteroid_icon", "asteroid_icon");
		}
		else if(@obj.toHulledObj() != null) {
			icon.setSize(dim2di(67, 55));
			string@ bank = "neumon_shipset";
			uint ind = 2;

			obj.toHulledObj().getSpriteIcon(bank, ind);

			icon.setSprites(bank, ind, ind, ind);
		}
		else {
			const string@ iconMaterial = "ship_ico_small";
			if(@obj.toStar() != null) {
				@iconMaterial = "sys_list_star";
				icon.setSize(dim2di(55, 55));
			}
			else if(@obj.toSystem() != null) {
				@iconMaterial = "sys_list_planet_group";
				icon.setSize(dim2di(55, 55));
			}
			else {
				@iconMaterial = "sys_list_star";
				icon.setSize(dim2di(55, 55));
			}
			icon.setImages(iconMaterial, iconMaterial);
		}
	}

	void update(float time) {
		Object@ prevObj = obj;
		if (!pinned || obj is null || !obj.isValid()) {
			@obj = getSelectedObject(getSubSelection());
		}

		if (obj is null || !obj.isValid() || obj.getOwner() is null) {
			setVisible(false);
			return;
		}
		else {
			setVisible(true);
		}

		// Update stuff that only changes when the object changes
		if (obj !is prevObj) {
			updateIcon();
		}
		else {
			if (updateTime <= 0) {
				updateTime = 0.2f;
			}
			else {
				updateTime -= time;
				return;
			}
		}

		ObjectLock lock(obj);

		// Collect variables
		@owner = obj.getOwner();
		Empire@ us = getActiveEmpire();
		Planet@ pl = obj;
		HulledObj@ hulled = obj;

		// Update regular stuff
		string@ objName = obj.getName();
		name.setText(objName);

		if (hulled !is null) {
			// Update obsolete toggle
			const HullLayout@ layout = hulled.getHull();
			if (layout.obsolete) {
				uint level = 0;
				const HullLayout@ upd = layout.supercededBy;
				while (upd !is null) {
					++level;
					@upd = upd.supercededBy;
				}

				Color white(0xffffffff), red(0xffff0000);
				red = red.interpolate(white, clamp(float(level) / 6.f, 0.f, 1.f));

				name.setColor(red);
				name.setToolTip(layout.getName()+localize("#OITT_Obsolete"));
			}
			else {
				name.setColor(Color(0xffffffff));
				name.setToolTip(null);
			}

			// Update fleet icon
			Fleet@ fl = hulled.getFleet();
			if (fl !is null) {
				fleetIcon.setVisible(true);
				fleetIcon.setColor(owner.color);

				if (fl.getCommander() is obj) {
					fleetIcon.setImage("fleet_leader_gui");
				}
				else {
					fleetIcon.setImage("fleet_member_gui");
				}
			}
			else {
				fleetIcon.setVisible(false);
			}
		}
		else {
			fleetIcon.setVisible(false);
			name.setColor(Color(0xffffffff));
			name.setToolTip(null);
		}

		// Update main bars
		float val = 0.f, max = 0.f, req = 0.f, cargo = 0.f;
		obj.getStateVals(strDamage, val, max, req, cargo);
		bars[0].set(localize("#MO_HP"), max - val, max, Color(0xff00ff00), Color(0xff555555));

		if(obj.hasState(strShieldArmor)) {
		val = 0.f; max = 0.f; req = 0.f; cargo = 0.f;
		obj.getStateVals(strShieldArmor, val, max, req, cargo);
		bars[1].set(localize("#MO_SAHP"), val, max, Color(0xff00baff), Color(0xff555556));		
		} else {
		val = 0.f; max = 0.f; req = 0.f; cargo = 0.f;
		obj.getStateVals(strShields, val, max, req, cargo);
		bars[1].set(localize("#MO_Shields"), val, max, Color(0xff00baff), Color(0xff555556));
		}
		
		val = 0.f; max = 0.f; req = 0.f; cargo = 0.f;
		obj.getStateVals(strFuel, val, max, req, cargo);
		bars[2].set(localize("#OI_Fuel"), val, max, Color(0xffff8500), Color(0xff555556));

		// Update planet-specific
		if (pl !is null) {
			val = 0.f; max = 0.f; req = 0.f; cargo = 0.f;
			obj.getStateVals(strWorkers, val, max, req, cargo);
			bars[3].set(localize("#OI_Population"), val, max, Color(0xffbf00ff), Color(0xff555556));
		}
		else {
			val = 0.f; max = 0.f; req = 0.f; cargo = 0.f;
			obj.getStateVals(strPower, val, max, req, cargo);
			bars[3].set(localize("#OI_Power"), val, max, Color(0xffffe400), Color(0xff555556));
		}

		// Update stats panel
		if (statsPanel.isVisible())
			updateStats();

		// Update economy panel
		if (econPanel.isVisible())
			updateEconomy();

		// Update cargo panel
		if (cargoPanel.isVisible())
			updateCargo();

		// Update formation and stance buttons
		updateButtons();

		// Update orders
		updateOrders();
	}

	void updateOrders() {
		if (owner is getActiveEmpire()) {
			OrderList list;
			list.prepare(obj);
			curOrder.setVisible(true);

			uint ordCnt = list.getOrderCount();

			// Remove extra order entries
			if (ordersPanel.isVisible()) {
				uint oldOrdCnt = orders.length();
				for (uint i = ordCnt; i < oldOrdCnt; ++i) {
					orders[i].remove();
					removeOrders[i].remove();
				}

				orders.resize(ordCnt);
				removeOrders.resize(ordCnt);
			}

			// Add new orders
			bool found = false;
			uint automCnt = 0;
			for (uint i = 0; i < ordCnt; ++i) {
				Order@ ord = list.getOrder(i);

				if (ord.isAutomation()) {
					if (automCnt < 9)
						updateAutomation(automation[automCnt], ord);
					++automCnt;
				}
				else if (!found) {
					curOrder.setText(ord.getName());
					found = true;
				}

				if (ordersPanel.isVisible()) {
					if (orders[i] is null) {
						@orders[i] = GuiStaticText(
							recti(pos2di(6, i * 20), dim2di(300, 20)),
							null, false, false, false, ordersPanel);
						orders[i].setTextAlignment(EA_Left, EA_Center);

						@removeOrders[i] = GuiButton(
							recti(pos2di(0, i * 20), dim2di(12, 12)),
							null, ordersPanel);
						removeOrders[i].setImage("remove_pin");
						removeOrders[i].setAlignment(EA_Right, EA_Center, EA_Right, EA_Center);
						removeOrders[i].setID(removeID);
					}

					orders[i].setText(list.getOrder(i).getName());

					if (ordCnt > 3)
						removeOrders[i].setPosition(pos2di(310, i * 20 + 5));
					else
						removeOrders[i].setPosition(pos2di(330, i * 20 + 5));
				}
			}

			// Hide unused automation icons
			for (; automCnt < 9; ++automCnt)
				automation[automCnt].setVisible(false);

			// Set current order text
			if (!found) {
				if (obj.getConstructionQueueSize() > 0)
					curOrder.setText(combine(localize("#MO_Building") +
						" ", obj.getConstructionName(), " (",
						f_to_s(obj.getConstructionProgress() * 100, 0),
						"%)"));
				else if (obj.getDestination().x != 0 && obj.getDestination().getDistanceFrom(obj.getPosition()) > 1.f)
					curOrder.setText(localize("#ORD_Move"));
				else
					curOrder.setText(localize("#idle"));
			}
		}
		else {
			curOrder.setVisible(false);

			// Remove extra order entries
			if (ordersPanel.isVisible()) {
				uint oldOrdCnt = orders.length();
				for (uint i = 0; i < oldOrdCnt; ++i) {
					orders[i].remove();
					removeOrders[i].remove();
				}

				orders.resize(0);
				removeOrders.resize(0);
			}

			for (uint i = 0; i < 9; ++i)
				automation[i].setVisible(false);
		}
	}

	void updateDR() {
		if (obj is null)
			return;
		HulledObj@ hulled = obj;
		float range = obj.getDefendRange();
		if (hulled !is null) {
			Fleet@ fl = hulled.getFleet();
			if (fl !is null) {
				Object@ comm = fl.getCommander();
				if(comm !is null)
					range = comm.getDefendRange();
			}
		}
		
		string@ text = "";

		if (range < -0.5f) {
			text = localize("#OI_EngageRange")+localize("#ER_System");
			DRButton.setSprites("object_commands", 27, 28, 29);
		}
		else if (range < 0.5f) {
			text = localize("#OI_EngageRange")+localize("#ER_Galaxy");
			DRButton.setSprites("object_commands", 33, 34, 35);
		}
		else {
			text = localize("#OI_EngageRange")+localize("#ER_Local");
			text += combine(" (", standardize(range/1000.f), localize("#au"), ")");
			DRButton.setSprites("object_commands", 30, 31, 32);
		}

		text += localize("#OI_EngageControl");
		DRButton.setToolTip(text);
	}

	void updateButtons() {
		Empire@ emp = getActiveEmpire();

		//Update formation buttons
		HulledObj@ hulled = obj;
		bool visible = false;

		if (@hulled != null && obj.getOwner() is emp) {
			Fleet@ fl = hulled.getFleet();

			if (@fl != null) {
				visible = true;
				FleetFormation form = fl.getFormation();

				for (uint i = 0; i < formations; ++i)
					ffButtons[i].setPressed(form == formationType[i]);
				stayButton.setPressed(fl.stayInFormation);
			}
		}

		for (uint i = 0; i < formations; ++i)
			ffButtons[i].setVisible(visible);
		stayButton.setVisible(visible);

		//Update stance buttons
		if (@obj != null && obj.getOwner() is emp) {
			AIStance stance = obj.getStance();

			for (uint i = 0; i < stances; ++i) {
				stButtons[i].setVisible(true);
				stButtons[i].setPressed(stance == stanceType[i]);
			}

			DRButton.setVisible(true);
			updateDR();
		} else {
			for (uint i = 0; i < stances; ++i)
				stButtons[i].setVisible(false);
			DRButton.setVisible(false);
		}
		
		// Hold position and defend are only for mobile objects
		if(obj is null || obj.thrust <= 0.0001f) {
			stButtons[1].setVisible(false);
			stButtons[2].setVisible(false);
			stButtons[3].setPosition(pos2di(344+21, 7));
			DRButton.setVisible(false);
		}
		else {
			stButtons[3].setPosition(pos2di(344+63, 7));
			DRButton.setVisible(obj.getOwner() is emp);
		}
	}

	void updateStats() {
		System@ sys = obj;
		if (obj.toStar() !is null)
			@sys = obj.getParent();

		uint statCnt = statNames.length();
		uint j = 0;

		Empire@ emp = getActiveEmpire();
		const Empire@ space = getEmpireByID(-1);

		if (sys is null) {
			for (uint i = 0; i < statCnt; ++i) {
				float val = 0.f, max = 0.f, req = 0.f, cargo = 0.f;
				obj.getStateVals(statNames[i], val, max, req, cargo);

				if (max <= 0)
					continue;

				if (statBars[j] is null) {
					@statBars[j] = StatBar(recti(pos2di((j % 2)*172+3, (j/2) * 20), dim2di(172, 20)), 60, statsPanel, this);
					@statBars[j].barTex = smBarTex;
					statBars[j].showBoth = false;
					statBars[j].setHoverLabel(false);
				}
				statBars[j].set(localize("#OI_"+statNames[i]), val, max, Color(statColors[i]), Color(0xff666666));
				++j;
			}
		}
		else if (sys.isVisibleTo(emp)) {
			for (uint i = 0; i < 4; ++i) {
				if (statBars[i] is null) {
					@statBars[i] = StatBar(recti(pos2di((i % 2)*172+3, (i/2) * 20), dim2di(172, 20)), 60, statsPanel, this);
					@statBars[i].barTex = smBarTex;
					statBars[i].showBoth = false;
					statBars[i].setHoverLabel(false);
				}
			}
			j = 4;

			Object@ sysObj = sys;
			float mil = sysObj.getStrength(emp);
			float civ = sysObj.getCivStrength(emp);
			float enmMil = sysObj.getStat(emp, "str_enemy");
			float tot = mil + civ + enmMil;

			int planets = sysObj.getPlanets(emp);
			int totPlanets = sysObj.getPlanets(space);

			statBars[0].set("Military", mil, tot, Color(0xff2b496b), Color(0xff666666));
			statBars[1].set("Enemy", enmMil, tot, Color(0xff6b2b30), Color(0xff666666));
			statBars[2].set("Civilian", civ, tot, Color(0xff506b2b), Color(0xff666666));
			statBars[3].setInt("Planets", planets, totPlanets, Color(0xff2b6b4a), Color(0xff666666));
		}

		for (uint i = j; i < statCnt; ++i) {
			if (statBars[i] !is null) {
				statBars[i].remove();
				@statBars[i] = null;
			}
		}
		statsPanel.fitChildren();
	}

	void updateEconomy() {
		System@ sys = obj;
		if (obj.toStar() !is null)
			@sys = obj.getParent();

		float cargoUsed = 0.f, cargoCap = 0.f;
		obj.getCargoVals(cargoUsed, cargoCap);
		uint statCnt = econStats.length();
		uint j = 0;

		for (uint i = 0; i < statCnt; ++i) {
			float val = 0.f, max = 0.f, req = 0.f, cargo = 0.f;
			if (i == 0) {
				Planet@ pl = obj;
				if (pl !is null) {
					val = pl.getStructureCount();
					max = pl.getMaxStructureCount();
				}
			}
			else {
				obj.getStateVals(econStats[i], val, max, req, cargo);
				if (i > 1) {
					max += cargoCap;
					val += cargo;
				}
			}

			if (max <= 0)
				continue;

			if (econBars[j] is null) {
				@econBars[j] = StatBar(recti(pos2di((j % 2)*172+3, (j/2) * 20), dim2di(172, 20)), 60, econPanel, this);
				@econBars[j].barTex = smBarTex;
				econBars[j].setHoverLabel(false);
				econBars[j].showBoth = false;
			}

			if(i == 0)
				econBars[j].setInt(localize("#OI_"+econStats[i]), int(val), int(max), Color(econColors[i]), Color(0xff666666));
			else
				econBars[j].set(localize("#OI_"+econStats[i]), val, max, Color(econColors[i]), Color(0xff666666));
			++j;
		}

		for (uint i = j; i < statCnt; ++i) {
			if (econBars[i] !is null) {
				econBars[i].remove();
				@econBars[i] = null;
			}
		}
		econPanel.fitChildren();
	}

	void updateCargo() {
		string@ cargoWinText;
		float cargo, cargoMax;
		obj.getCargoVals(cargo, cargoMax);
		
		if(cargoMax > 0)
			@cargoWinText = "#tab:4#"+localize("#OI_All")+":#tab:50#"+standardize_nice(cargo)+" / "+standardize_nice(cargoMax)+"\n";
		else
			@cargoWinText = "#c:red#"+localize("#OI_NoCargoBay")+"#c#";
		
		if(cargo > 0) {
			const uint NumberOfStates = obj.getStateCount();
			int[] orderedStates = {-1, -1, -1, -1};
			float[] stateValues = {0,0,0,0};
			
			const uint NumToDisplay = min(4, NumberOfStates);
			
			for(uint i = 0; i < NumberOfStates; ++i)
			{
				const State@ curState = obj.getStateN(i);
				if(curState.inCargo <= 0)
					continue;

				const Resource@ res = getResource(obj.getStateName(i));
				if (res is null || !res.canBeCargo)
					continue;
				
				//Find a matching location
				for(uint test = 0; test < NumToDisplay; ++test)
				{
					int testStateIndex = orderedStates[test];
					if(testStateIndex == -1 || stateValues[test] < curState.inCargo)
					{
						//Insert the value
						for(int cpy = int(NumToDisplay) - 1; cpy > int(test); --cpy)
						{
							stateValues[cpy] = stateValues[cpy - 1];
							orderedStates[cpy] = orderedStates[cpy - 1];
						}
						stateValues[test] = curState.inCargo;
						orderedStates[test] = i;
						break;
					}
				}
			}
			
			for(uint i = 0; i < NumToDisplay; i++)
				if(orderedStates[i] != -1)
					cargoWinText += "#tab:4#"+localize("#OI_"+obj.getStateName(orderedStates[i])) + ":#tab:50#" + standardize_nice(stateValues[i]) + "\n";
		}
		
		cargoText.setText(cargoWinText);
		cargoPanel.fitChildren();
	}

	EventReturn onGUIEvent(GuiElement@ ele, const GUIEvent& evt) {
		if (evt.EventType == GEVT_Focus_Gained && evt.Caller.isAncestor(ele))
			script.bringToFront();

		switch (evt.EventType) {
			case GEVT_Clicked:
				if (evt.Caller is statsButton) {
					statsButton.setPressed(true);
					econButton.setPressed(false);
					cargoButton.setPressed(false);
					ordersButton.setPressed(false);

					statsPanel.setVisible(true);
					econPanel.setVisible(false);
					cargoPanel.setVisible(false);
					ordersPanel.setVisible(false);

					updateStats();
				}
				else if (evt.Caller is econButton) {
					statsButton.setPressed(false);
					econButton.setPressed(true);
					cargoButton.setPressed(false);
					ordersButton.setPressed(false);

					statsPanel.setVisible(false);
					econPanel.setVisible(true);
					cargoPanel.setVisible(false);
					ordersPanel.setVisible(false);

					updateEconomy();
				}
				else if (evt.Caller is cargoButton) {
					statsButton.setPressed(false);
					econButton.setPressed(false);
					cargoButton.setPressed(true);
					ordersButton.setPressed(false);

					statsPanel.setVisible(false);
					econPanel.setVisible(false);
					cargoPanel.setVisible(true);
					ordersPanel.setVisible(false);

					updateCargo();
				}
				else if (evt.Caller is ordersButton) {
					statsButton.setPressed(false);
					econButton.setPressed(false);
					cargoButton.setPressed(false);
					ordersButton.setPressed(true);

					statsPanel.setVisible(false);
					econPanel.setVisible(false);
					cargoPanel.setVisible(false);
					ordersPanel.setVisible(true);

					updateOrders();
				}
				else if (evt.Caller is resize) {
					int width = getScreenWidth(), height = getScreenHeight();
					dim2di size = ele.getSize();

					if (expanded)
						size.height = 63;
					expanded = !expanded;

					animate(ele, pos2di((width - size.width) / 2, height - size.height),
							ele.getSize(), 370.f);
				}
				else if (evt.Caller.getID() == removeID){
					OrderList list;
					if (list.prepare(obj)) {
						uint ordCnt = orders.length();
						int num = -1;
						for (uint i = 0; i < ordCnt; ++i) {
							if (removeOrders[i] is evt.Caller) {
								num = i;
								break;
							}
						}

						if (num >= 0)
							list.clearOrder(num);
					}

					updateOrders();
				}
			break;
			case GEVT_Right_Clicked:
				if (evt.Caller is icon) {
					onRightClick(obj);
					return ER_Pass;
				}
				else if (evt.Caller.getID() == automationID) {
					OrderList orders;
					if (!orders.prepare(obj))
						return ER_Pass;

					uint index = 0;
					for (; index < 9; ++index) {
						if (automation[index] is evt.Caller)
							break;
					}

					if (index >= 9)
						return ER_Pass;

					uint ordCnt = orders.getOrderCount();
					uint autom = 0;
					for (uint i = 0; i < ordCnt; ++i) {
						Order@ ord = orders.getOrder(i);
						if (!ord.isAutomation())
							continue;

						if (autom == index) {
							orders.clearOrder(i);
							updateOrders();
							return ER_Pass;
						}

						++autom;
					}
				}
			break;
			case GEVT_Focus_Gained:
				if (evt.Caller is name) {
					if (obj.getOwner() is getActiveEmpire())
						addEntryDialog(localize("#OI_Rename"), obj.getName(),
								localize("#OI_Rename"), RenameObject(obj));
					return ER_Absorb;
				}
				else if (evt.Caller.toGuiButton() is null) {
					return ER_Absorb;
				}
			break;
		}
		return ER_Pass;
	}

	EventReturn onKeyEvent(GuiElement@ ele, const KeyEvent& evt) {
		return ER_Pass;
	}

	EventReturn onMouseEvent(GuiElement@ ele, const MouseEvent& evt) {
		switch (evt.EventType) {
			case MET_RIGHT_UP: {
				pos2di point = getMousePosition();
				if (icon.getAbsolutePosition().isPointInside(point)) {
					onRightClick(obj);
					return ER_Absorb;
				}
			} break;
		}
		return ER_Pass;
	}
}
// }}}
// {{{ Object commands
class RenameObject : EntryDialogCallback {
	Object@ obj;

	RenameObject(Object@ Obj) {
		@obj = Obj;
	}

	void call(EntryDialog@ dialog, string@ text) {
		if (obj.getOwner() is getActiveEmpire())
			obj.setName(text);
	}
};

class RenameFleet : EntryDialogCallback {
	Fleet@ fl;

	RenameFleet(Fleet@ fleet) {
		@fl = fleet;
	}

	void call(EntryDialog@ dialog, string@ text) {
		fl.setName(text);
	}
};

bool ffButtonPressed(const GUIEvent@ evt) {
	if (evt.EventType == GEVT_Clicked) {
		Object@ lastSelected = getSelectedObject(getSubSelection());
		HulledObj@ obj = lastSelected;

		if (@obj != null) {
			Fleet@ fl = obj.getFleet();
			if (@fl != null)
				for (uint i = 0; i < formations; ++i)
					if (formationID[i] == evt.Caller.getID())
						fl.setFormation(formationType[i]);
		}

		return true;
	}
	return false;
}

bool stayButtonPressed(const GUIEvent@ evt) {
	if (evt.EventType == GEVT_Clicked) {
		Object@ lastSelected = getSelectedObject(getSubSelection());
		HulledObj@ obj = lastSelected;

		if (obj !is null) {
			Fleet@ fl = obj.getFleet();
			if (fl !is null)
				fl.stayInFormation = evt.Caller.toGuiButton().isPressed();
		}
	}
	return false;
}

void setDR(float range) {
	Object@ lastSelected = getSelectedObject(getSubSelection());
	HulledObj@ obj = lastSelected;
	if (@obj != null) {
		Fleet@ fl = obj.getFleet();
		if (@fl != null) {
			Object@ comm = fl.getCommander();
			if(comm !is null)
				comm.setDefendRange(range);
			return;
		}
	}

	uint cnt = getSelectedObjectCount();
	for (uint j = 0; j < cnt; ++j) {
		getSelectedObject(j).setDefendRange(range);
	}
}

void DRDialogOK(OptionDialog@ dialog, bool success) {
	if (success)
		setDR(s_to_f(dialog.getTextOption(0))*1000.f);
}

bool DRButtonPressed(const GUIEvent@ evt) {
	if (evt.EventType == GEVT_Clicked) {
		Object@ lastSelected = getSelectedObject(getSubSelection());
		float range = lastSelected.getDefendRange();
		if (ctrlKey) {
			OptionDialog@ dialog = addOptionDialog(localize("#OI_SetEngageTitle"), localize("#OI_SetEngage"), DRDialogOK);
			dialog.addCaptionedTextOption(localize("#OI_EngageRange"), localize("#au"), ftos_nice(range > 0.5f ? range/1000.f  : 40.f));
			dialog.fitChildren();
		}
		else {
			if (range < -0.5f) {
				range = defaultLocalAreaSize;
			}
			else if (range < 0.5f) {
				range = -1.f;
			}
			else {
				range = 0;
			}

			setDR(range);
		}
	}
	return false;
}

bool stButtonPressed(const GUIEvent@ evt) {
	if (evt.EventType == GEVT_Clicked) {
		Object@ lastSelected = getSelectedObject(getSubSelection());
		AIStance stance = AIS_Engage;

		for (uint i = 0; i < stances; ++i) {
			if (stanceID[i] == evt.Caller.getID()) {
				stance = stanceType[i];
				break;
			}
		}

		HulledObj@ obj = lastSelected;

		if (@obj != null) {
			Fleet@ fl = obj.getFleet();
			if (@fl != null) {
				Object@ comm = fl.getCommander();
				if (comm !is null && comm.uid == lastSelected.uid) {
					lastSelected.setStance(stance);

					uint cnt = fl.getMemberCount();
					for (uint i = 0; i < cnt; ++i) {
						fl.getMember(i).setStance(stance);
					}

					return true;
				}
			}
		}

		uint cnt = getSelectedObjectCount();
		for (uint j = 0; j < cnt; ++j) {
			getSelectedObject(j).setStance(stance);
		}

		return true;
	}
	return false;
}
// }}}
// {{{ Initialization/Management
ObjectInfoWindow@ win;

Color transparent;
Color opaque;

int fetchFront = 0;
int fetchBack = 0;

void init() {
	// Initialize the skin variables
	initSkin();

	// Initialize constants
	transparent = Color(160, 255, 255, 255);
	opaque = Color(255, 255, 255, 255);
	@smBarTex = getMaterialTexture("objectInfoBar_sm");

	formationID.resize(formations);
	for (uint i = 0; i < formations; ++i) {
		formationID[i] = reserveGuiID();
		bindGuiCallback(formationID[i], "ffButtonPressed");
	}

	stanceID.resize(stances);
	for (uint i = 0; i < stances; ++i) {
		stanceID[i] = reserveGuiID();
		bindGuiCallback(stanceID[i], "stButtonPressed");
	}

	// Fetch locales
	fetchFront = localize("#ORD_Fetch").length();
	fetchBack = localize("#ORD_WhenLow").length();

	@fuelLocale = localize("#RES_Fuel");
	@ammoLocale = localize("#RES_Ammo");
	
	// Create initial window
	int width = getScreenWidth(), height = getScreenHeight();
	@win = ObjectInfoWindow(recti(
		pos2di(width/2 - 232, height - 148),
		dim2di(464, 148)));
}

bool objWinVisible = true;
void setObjWinVisible(bool vis) {
	objWinVisible = vis;
	win.setVisible(vis);
}

void tick(float time) {
	if (win !is null && objWinVisible)
		win.update(time);
}
// }}}
#include "~/Game Data/gui/include/gui_skin.as"

import GuiElement@ getQuickPanel() from "quick_panel";
import bool anchorToMouse(GuiElement@,bool) from "gui_lib";

bool showAllSubsystems = false;
GuiPanel@ subsysPanel;
SubsystemPanel@ panelScript;
GuiScripted@ subsysScripted;
GuiButton@ summaryButton, listButton, layoutButton;
string@ strDamage = "Damage";

const string@ stat_sprite_bank = "layout_icons";
const string[] tags = {"Hull", "Armor", "Weapon", "Control", "Power", "Engine"};
const uint[] tagSpriteIndex = {10, 7, 8, 6, 1, 2};
const uint tagAmount = 6;
string@ offline_str;

const float layout_scale = 32.f;
const float layout_height = 214.f;

string@ strCargoStore = "Storage:Cargo", strFuelStore = "Storage:Fuel", strAmmoStore = "Storage:Ammo", strAsteroidStore = "Storage:Asteroids", strShipBay = "ShipBay", strPowerStore = "Storage:Power";
string@ strFuel = "Fuel", strAmmo = "Ammo", strAsteroids = "Asteroids", strPower = "Power", strWeapon = "Weapon", strChargedWeapon = "ChargedWeapon", strTimedReload = "TimedReload";
string@ strShieldArmor = "ShieldArmor", strShields = "Shields", strShieldTag = "ShieldGen", strH3 = "H3";
string@ strMetalStore = "Storage:Metal", strElecStore = "Storage:Electronics", strAdvPartsStore = "Storage:AdvParts";
string@ strMetal = "Metals", strElec = "Electronics", strAdvParts = "AdvParts", strH3Store = "Storage:H3";
string@ strOreStore = "Storage:Ore", strOre = "Ore";

Color fullColor, damagedColor, heavilyDamagedColor, criticalColor, destroyedColor, offlineColor;

bool bpEnabled = true;
void setBPEnabled(bool enable) {
	bpEnabled = enable;
}
void init() {
	int height = getScreenHeight();
	initSkin();

	@offline_str = " ("+localize("#PL_OFFLINE")+")";

	@subsysPanel = GuiPanel(recti(pos2di(0, height-300), dim2di(266, 300)), false, SBM_Invisible, SBM_Invisible, null);
	subsysPanel.setVisible(false);

	@panelScript = SubsystemPanel();
	@subsysScripted = GuiScripted(recti(pos2di(0, 0), dim2di(266, 300)), panelScript, subsysPanel);
	panelScript.init(subsysScripted);

	@summaryButton = ToggleButton(false, recti(pos2di(23, 0), dim2di(88, 17)), localize("#SW_Summary"), subsysPanel);
	@layoutButton = ToggleButton(true, recti(pos2di(98, 0), dim2di(89, 17)), localize("#SW_Layout"), subsysPanel);
	@listButton = ToggleButton(false, recti(pos2di(173, 0), dim2di(88, 17)), localize("#SW_List"), subsysPanel);

	bindGuiCallback(summaryButton, "setModeButton");
	bindGuiCallback(layoutButton, "setModeButton");
	bindGuiCallback(listButton, "setModeButton");

	fullColor = Color(255, 255, 255, 255);
	damagedColor = Color(255, 200, 200, 128);
	heavilyDamagedColor = Color(255, 255, 200, 0);
	criticalColor = Color(255, 200, 128, 128);
	destroyedColor = Color(255, 255, 0, 0);
	offlineColor = Color(255, 255, 0, 0);
}

bool setModeButton(const GUIEvent@ event) {
	if(event.EventType == GEVT_Clicked) {
		if (event.Caller is summaryButton) {
			summaryButton.setPressed(true);
			listButton.setPressed(false);
			layoutButton.setPressed(false);
			panelScript.mode = SSDM_Summary;
			setGuiFocus(null);
		}
		else if (event.Caller is listButton) {
			summaryButton.setPressed(false);
			listButton.setPressed(true);
			layoutButton.setPressed(false);
			panelScript.mode = SSDM_List;
			setGuiFocus(panelScript.scroll);
		}
		else if (event.Caller is layoutButton) {
			summaryButton.setPressed(false);
			listButton.setPressed(false);
			layoutButton.setPressed(true);
			panelScript.mode = SSDM_Layout;
			setGuiFocus(null);
		}

		showAllSubsystems = panelScript.mode == SSDM_List;
		return true;
	}

	return false;
}

void tick(float time) {
	Object@ selected = getSelectedObject(getSubSelection());
	
	if(@selected != null && selected.isValid() == false)
		@selected = null;

	if (@selected == null || !bpEnabled || !panelScript.update(selected)) {
		subsysPanel.setVisible(false);

		GuiElement@ qp = getQuickPanel();
		dim2di qpSize = qp.getSize();
		qp.setPosition(pos2di(qp.getPosition().x, getScreenHeight()-qpSize.height));
	} else {
		subsysPanel.setPosition(pos2di(getScreenWidth()-panelScript.width-6-7, getScreenHeight()-panelScript.height-7));
		subsysPanel.setSize(dim2di(panelScript.width+6, panelScript.height));

		summaryButton.setPosition(pos2di(7, panelScript.height-17));
		layoutButton.setPosition(pos2di(95, panelScript.height-17));
		listButton.setPosition(pos2di(184, panelScript.height-17));

		GuiElement@ qp = getQuickPanel();
		dim2di qpSize = qp.getSize();
		qp.setPosition(subsysPanel.getPosition() - pos2di(0, qpSize.height-1));

		subsysPanel.setVisible(true);
	}
}

enum SubSysDisplayMode {
	SSDM_Summary,
	SSDM_List,
	SSDM_Layout
};

class SubsystemPanel : ScriptedGuiHandler {
	GuiElement@ element;
	GuiPanel@ mouseOverlay;
	GuiExtText@ mouseOverlayText;
	GuiScrollBar@ scroll;
	Object@ obj;
	int width;
	int height;
	uint curNum;
	bool needScroll;
	SubSysDisplayMode mode;
	float scrollPos;

	float HP;
	float MaxHP;

	float[] tagHP;
	float[] tagMaxHP;
	float[] overlayPerc;
	float[] reloadTime;

	float[] prevHP;
	dim2di[] prevSize;
	string@[] prevText;

	const Texture@ overlayTex;

	SubsystemPanel() {
		@obj = null;
		width = 260;
		height = 0;
		curNum = 0;
		needScroll = false;
		mode = SSDM_Layout;
	}

	void resize(uint num) {
		if (curNum != num+tagAmount+1) {
			tagHP.resize(tagAmount);
			tagMaxHP.resize(tagAmount);

			prevHP.resize(num+tagAmount+1);
			prevText.resize(num+tagAmount+1);
			prevSize.resize(num+tagAmount+1);
			overlayPerc.resize(num);
			reloadTime.resize(num);

			for (uint i = 0; i < num+tagAmount; ++i) {
				prevHP[i] = 0.f;
				@prevText[i] = null;
			}

			curNum = num+tagAmount+1;
		}
	}

	void init(GuiElement@ ele) {
		@element = ele;
		@scroll = GuiScrollBar(recti(pos2di(width-10, 32), dim2di(12, 60)), false, element);

		@overlayTex = getMaterialTexture("SubSysOverlay");

		@mouseOverlay = GuiPanel(recti(pos2di(-1,-1), dim2di(170, 200)), true, SBM_Invisible, SBM_Invisible, null);
		mouseOverlay.setNoclipped(true);
		mouseOverlay.setVisible(false);
		mouseOverlay.setOverrideColor(Color(0xff000000));

		@mouseOverlayText = GuiExtText(recti( pos2di(8,4), dim2di(154, 192)), mouseOverlay);
		mouseOverlayText.setShadow(Color(255,0,0,0));
	}

	Color getPercColor(uint alpha, float perc) {
		Color col(alpha, 255, 255, 255);

		if (perc >= 0.5) {
			col = col.interpolate(Color(alpha, 220, 110, 0), (perc-0.5f)*2.f);
		}
		else {
			col = Color(alpha, 220, 110, 0);
			col = col.interpolate(Color(alpha, 255, 0, 0), perc*2.f);
		}

		return col;
	}

	void drawItem(pos2di pos, dim2di dim, int prevId, string@ name, float hp, float maxhp, float deltahp, float level, uint offset, bool offline) {
		float ratio = maxhp > 0 ? hp/maxhp : 0;
		string@ hptext;
		dim2di size;

		if (@prevText[prevId] == null || prevHP[prevId] != hp) {
			@hptext = standardize(hp)+"/"+standardize(maxhp);
			size = getTextDimension(hptext);

			prevHP[prevId] = hp;
			@prevText[prevId] = hptext;
			prevSize[prevId] = size;
		} else {
			@hptext = prevText[prevId];
			size = prevSize[prevId];
		}

		Color col;
		if (offline && ratio > 0.99f)
			col = offlineColor;
		else
			col = getPercColor(255, ratio);

		if (level > 0)
			name += " L"+ftos_nice(level);

		if (offline)
			name += offline_str;

		drawText(name, recti(pos, dim), col, false, false);

		if (maxhp != 0)
			drawText(hptext, recti(pos+pos2di(this.width-6-size.width-offset, 0), dim), col, false, false);
	}

	void drawSystem(pos2df origin, float scale, float hpPerc, const subSystemDef@ def, bool offline, Color overlayColor, float overlayPerc) {
		const Texture@ img = def.getImage();
		float size = sqrt(scale) * layout_scale;

		uint alpha = offline && hpPerc > 0.001f ? 200 : 255;

		drawTexture(img, recti(pos2di(origin.x-size/2, origin.y-size/2), dim2di(size, size)),
				recti(pos2di(0, 0), img.size), getPercColor(alpha, hpPerc), true);

		if (overlayPerc > 0 && hpPerc > 0.001f) {
			dim2di sz = overlayTex.size;
			float height = floor(overlayPerc * size);
			float texHeight = floor(overlayPerc * sz.height);

			drawTexture(overlayTex, recti(pos2di(origin.x-size/2, origin.y-size/2+size-height), dim2di(size, height)),
					recti(pos2di(0, sz.height-texHeight), dim2di(sz.width, texHeight)), overlayColor, true);
		}
	}

	void updateOverlay(Object@ obj, SysRef@ ref, uint num) {
		const subSystemDef@ def = ref.system.type;
		float val = 0.f, max = 0.f, req = 0.f, cargo = 0.f;
		float perc = 0.f, reload = 0.f;

		obj.toHulledObj().getProgress(ref, val, max);
		if (max > 0.f) {
			perc = val / max;

			if ((def.hasTag(strWeapon) && !def.hasTag(strChargedWeapon)) || def.hasTag(strTimedReload))
				reload = val;
		}
		else if (def.hasTag(strFuelStore)) {
			if (obj.getStateVals(strFuel, val, max, req, cargo) && max > 0.f)
				perc = val / max;
		}
		else if (def.hasTag(strAmmoStore)) {
			if (obj.getStateVals(strAmmo, val, max, req, cargo) && max > 0.f)
				perc = val / max;
		}
		else if (def.hasTag(strAsteroidStore)) {
			if (obj.getStateVals(strAsteroids, val, max, req, cargo) && max > 0.f)
				perc = val / max;
		}
		else if (def.hasTag(strShipBay)) {
			obj.getShipBayVals(val, max);
			if (max > 0.f)
				perc = val / max;
		}
		else if (def.hasTag(strCargoStore)) {
			obj.getCargoVals(val, max);
			if (max > 0.f)
				perc = val / max;
		}
		else if (def.hasTag(strMetalStore)) {
			if (obj.getStateVals(strMetal, val, max, req, cargo) && max > 0.f)
				perc = val / max;
		}
		else if (def.hasTag(strElecStore)) {
			if (obj.getStateVals(strElec, val, max, req, cargo) && max > 0.f)
				perc = val / max;
		}
		else if (def.hasTag(strAdvPartsStore)) {
			if (obj.getStateVals(strAdvParts, val, max, req, cargo) && max > 0.f)
				perc = val / max;
		}
		else if (def.hasTag(strPowerStore)) {
			if (obj.getStateVals(strPower, val, max, req, cargo) && max > 0.f)
				perc = val / max;
		}
		else if (def.hasTag(strShieldArmor)) {
			if (obj.getStateVals(strShieldArmor, val, max, req, cargo) && max > 0.f)
				perc = val / max;
		}
		else if (def.hasTag(strShieldTag)) {
			if (obj.getStateVals(strShields, val, max, req, cargo) && max > 0.f)
				perc = val / max;
		}
		else if (def.hasTag(strH3Store)) {
			if (obj.getStateVals(strH3, val, max, req, cargo) && max > 0.f)
				perc = val / max;
		}
		else if (def.hasTag(strOreStore)) {
			if (obj.getStateVals(strOre, val, max, req, cargo) && max > 0.f)
				perc = val / max;
		}		

		overlayPerc[num] = perc;
		reloadTime[num] = reload;
	}

	void draw(GuiElement@ ele) {
		if (@obj == null) return;
		element.toGuiScripted().setAbsoluteClip();

		recti absPos = ele.getAbsolutePosition();
		const pos2di topLeft = absPos.UpperLeftCorner;
		dim2di lineSize = dim2di(this.width, 21);

		HulledObj@ hulledobj = obj.toHulledObj();
		if (hulledobj is null)
			return;

		uint cnt = hulledobj.getSubSystemCount();
		resize(cnt);

		//Draw background
		const Texture@ tex;
		Color col = Color(255, 255, 255, 255);

		drawDarkArea(recti(
			topLeft + pos2di(7, 7),
			dim2di(width, 22)));
		drawLightArea(recti(
			topLeft + pos2di(7, 34),
			dim2di(width, height - 33)));
		drawWindowBorder(recti(
			absPos.UpperLeftCorner,
			absPos.LowerRightCorner + pos2di(7, 7)));
		drawHSep(recti(topLeft + pos2di(6, 27), dim2di(width+1, 7)));
		drawHSep(recti(pos2di(topLeft.x + 6, topLeft.y + height - 24), dim2di(width+1, 7)));

		element.toGuiScripted().setAbsoluteClip();	
		
		//Draw information
		this.height = 35;

		float wantHeight = 0;
		float getHeight = getScreenHeight()*0.6f;
		bool displayAll = mode == SSDM_List;

		drawItem(topLeft+pos2di(14, 9), lineSize, 0, obj.getName(), HP, MaxHP, 0, 0, 7, false);

		if (mode == SSDM_Layout) {
			pos2df origin = pos2df(topLeft.x+this.width/2, topLeft.y+this.height+layout_height/2);
			wantHeight += layout_height+4;

			setDrawClip(recti(topLeft+pos2di(0, this.height-1), dim2di(width, layout_height)));

			@tex = getMaterialTexture("ship_circle");
			drawTexture(tex, topLeft+pos2di((this.width-tex.size.width)/2, this.height),
					recti(pos2di(0,0), tex.size), col, true);

			const HullLayout@ layout = hulledobj.getHull();
			uint cnt = layout.getSubSysCnt();
			for (uint i = 0; i < cnt; ++i) {
				SysRef@ ref = hulledobj.getSubSystem(i);
				if (ref is null) continue;
				pos2df pos = layout.getSubSysPos(i);

				drawSystem(origin+pos2df(pos.x * layout_scale, pos.y * layout_scale),
						ref.system.scale, ref.HP/ref.system.maxHP, ref.system.type,
						ref.getState() != SS_Active, Color(255, 255, 255, 255), overlayPerc[i]);
			}

			clearDrawClip();
		}
		else {
			this.height += 4;
			if (!displayAll) {
				for (uint j = 0; j < tagAmount; ++j) {
					tagHP[j] = 0;
					tagMaxHP[j] = 0;
				}
			}

			setDrawClip(recti(topLeft+pos2di(0, this.height-1), dim2di(this.width, getHeight)));

			for (uint i = 0; i < cnt; ++i) {
				SysRef@ ref = hulledobj.getSubSystem(i);
				if (ref is null) continue;

				if (displayAll) {
					drawItem(topLeft+pos2di(12, this.height+wantHeight-scrollPos), lineSize, i+1, ref.system.type.getName(),
						ref.HP, ref.system.maxHP, 0, ref.system.level, 7+(needScroll?15:0), ref.getState() != SS_Active);
					wantHeight += 21;
				} else {
					for (uint j = 0; j < tagAmount; ++j) {
						if (ref.system.type.hasTag(tags[j])) {
							tagHP[j] += ref.HP;
							tagMaxHP[j] += ref.system.maxHP;
						}
					}
				}
			}

			if (!displayAll) {
				for (uint j = 0; j < tagAmount; ++j) {
					if (tagMaxHP[j] != 0) {
						drawSprite(stat_sprite_bank, tagSpriteIndex[j], topLeft+pos2di(10-scrollPos,this.height+wantHeight-1));
						drawItem(topLeft+pos2di(34, this.height+wantHeight-scrollPos), lineSize, cnt+j+1, localize("#SW_"+tags[j]),
							tagHP[j], tagMaxHP[j], 0, 0, 30+(needScroll?15:0), false);
						wantHeight += 23;
					}
				}
			}

			clearDrawClip();
		}

		if (height % 2 == 0)
			height += 1;

		this.height += 24;

		if (wantHeight > getHeight && mode != SSDM_Layout) {
			this.height += getHeight+5;

			scroll.setMin(0);
			scroll.setMax(wantHeight-getHeight);

			scroll.setSmallStep((displayAll?21:23));
			scroll.setLargeStep(getHeight);

			scroll.setSize(dim2di(12, this.height-64));
			scroll.setVisible(true);

			scroll.setPageSize(getHeight);

			scrollPos = scroll.getPos();
			needScroll = true;
		} else {
			this.height += wantHeight;
			scrollPos = 0;
			needScroll = false;
			scroll.setVisible(false);
		}

		element.setSize(dim2di(this.width+6, this.height));
	}

	bool update(Object@ Obj) {
		HulledObj@ hulledobj = Obj.toHulledObj();
		Empire@ emp = getActiveEmpire();

		if (hulledobj is null || !(Obj.getOwner() is emp || emp.hasForeignHull(hulledobj.getHull())))
			return false;

		@obj = Obj;
		float val = 0.f, max = 0.f, req = 0.f, cargo = 0.f;
		obj.getStateVals(strDamage, val, max, req, cargo);

		if (max > 0) {
			HP = max-val;
			MaxHP = max;
		} else {
			MaxHP = HP = 0;
		}

		draw(element);
		updateOverlayPercs();

		if (mouseOverlay.isVisible() && mode == SSDM_Layout)
			updateMouseOverlay();
		return true;
	}

	void updateOverlayPercs() {
		HulledObj@ hulledobj = obj.toHulledObj();
		if (hulledobj is null)
			return;

		uint cnt = hulledobj.getSubSystemCount();
		for (uint i = 0; i < cnt; ++i)
			updateOverlay(obj, hulledobj.getSubSystem(i), i);
	}

	void updateMouseOverlay() {
		pos2di mousePos = getMousePosition();
		pos2df mousePos_f = pos2df(mousePos.x, mousePos.y);
		mouseOverlay.setVisible(false);

		HulledObj@ hulledobj = obj.toHulledObj();
		if (hulledobj is null)
			return;

		string@ text = "";
		recti absPos = element.getAbsolutePosition();
		const pos2di topLeft = absPos.UpperLeftCorner;

		pos2df origin = pos2df(topLeft.x+this.width/2, topLeft.y+31+layout_height/2);

		const HullLayout@ layout = hulledobj.getHull();
		uint cnt = layout.getSubSysCnt();
		for (uint i = 0; i < cnt; ++i) {
			SysRef@ ref = hulledobj.getSubSystem(i);
			pos2df pos = layout.getSubSysPos(i);

			float size = sqrt(ref.system.scale) * layout_scale;
			pos2df realPos = origin+pos2df(pos.x * layout_scale, pos.y * layout_scale);

			if (realPos.getDistanceFrom(mousePos_f) < size/2) {
				Color col(255, 0, 220, 0);
				col = col.interpolate(Color(255, 255, 0, 0), ref.HP/ref.system.maxHP);

				string@ load = "";
				if (reloadTime[i] > 0.001f)
					load = f_to_s(reloadTime[i], 1)+"s";
				else if (overlayPerc[i] > 0.001f)
					load = f_to_s(overlayPerc[i]*100.f, 0)+"%";

				mouseOverlay.setVisible(true);
				if (text.length() != 0)
					text += "\n";
				text += combine(
						combine(ref.system.type.getName(), " L", i_to_s(ref.system.level)),
						(load.length() > 0 ? combine("\n#a:right##c:aaa#", load, "#c##tab:60#") : "\n#a:right#"),
						combine("#c:", col.format(), "#"),
						combine(standardize(ref.HP), "/", standardize(ref.system.maxHP)),
						"#c##a#");
			}
		}

		if (mouseOverlay.isVisible()) {
			mouseOverlay.bringToFront();
			anchorToMouse(mouseOverlay, true);
			mouseOverlayText.setText(text);
			mouseOverlay.setSize(dim2di(mouseOverlay.getSize().width, mouseOverlayText.getSize().height));
		}
	}

	EventReturn onKeyEvent(GuiElement@,const KeyEvent&) {
		return ER_Pass;
	}
	
	EventReturn onMouseEvent(GuiElement@ ele, const MouseEvent& evt) {
		switch (evt.EventType) {
			case MET_LEFT_UP:
				if(showAllSubsystems)
					setGuiFocus(scroll);
			break;
			case MET_MOVED: {
				if (mode != SSDM_Layout)
					break;
				updateMouseOverlay();
			} break;
		}
		return ER_Pass;
	}
	
	EventReturn onGUIEvent(GuiElement@ ele,const GUIEvent& evt) {
		switch (evt.EventType) {
			case GEVT_Mouse_Left: {
				mouseOverlay.setVisible(false);

				GuiElement@ focus = getGuiFocus();
				if (focus !is null && focus.isAncestor(ele))
					setGuiFocus(null);
			} break;
		}
		return ER_Pass;
	}
};

#include "~/Game Data/gui/include/gui_sprite.as"
#include "~/Game Data/gui/include/dialog.as"

import void triggerPlanetWin(Planet@ pl, bool bringToFront) from "planet_win";
import void triggerQueueWin(Object@ obj) from "queue_win";
import void triggerUndockWin(Object@ obj) from "undock_win";
import void anchorToMouse(GuiElement@) from "gui_lib";
import void ToggleEconomyReport() from "economy_report";
import void showSystemWindow(System@ sys) from "sys_win";
import void toggleEscapeMenu() from "escape_menu";
import void triggerContextMenu(Object@) from "context_menu";
import bool isContextMenuUp() from "context_menu";
import void createLogWindow() from "log_win";
import void toggleCivilActsWin() from "civil_acts_win";

const float unitsPerAU = 1000.f;
const string@ strOre = "Ore";

GuiExtText@ empireMessages;
GuiImage@ empMsgBG;

//Nearby overlay elements
GuiImage@ glowLine;
GuiExtText@ nrov_name, nrov_hpTag, nrov_shieldTag, nrov_shieldarmTag;
GuiBar@ nrov_hpBar;
GuiBar@ nrov_shieldBar;
GuiBar@ nrov_shieldarmBar;
GuiExtText@ nrov_build, clock;

GuiExtText@ mouseOverlay;
GuiStaticText@ speedIndicator;

GuiExtText@ bankMtl, bankElc, bankAdv, bankFood, bankGoods, bankLux, bankFuel, bankAmmo, bankTrade;
float prevMtl = -1, prevElc = -1, prevAdv = -1, prevFood = -1, prevGoods = -1, prevLux = -1, prevFuel = -1, prevAmmo = -1, prevTrade = -1;
float rateMtl = 0, rateElc = 0, rateAdv = 0, rateFood = 0, rateGoods = 0, rateLux = 0, rateFuel = 0, rateAmmo = 0, rateTrade = 0;
double prevBankUpdate = 0;
float bankCounter = 0, prevSpeed = 0;
bool bankMode = false;
double em_lastMsg = -1;
double em_lastVisMsg = -1;

int gameShipLimit;
GuiImage@ tickerBG;
GuiStaticText@ tickerTop, tickerBottom, tickerBottomRight, tickerTopPercent;
GuiExtText@ shipLimit;

GuiButton@ msgLog, msgExpand, msgShrink, civActs, bankToggle, econReportButton, speedUpButton, slowDownButton, pauseButton;

GuiButton@[] filterButtons;
const string[] filters = {"war", "research", "diplomacy", "build", "misc"};
const bool[] filterState = {true, true, true, false, true};

pos2di msgShrinkPos(0,0);

string@ standardize_nice(float val) {
	if (val > 0.0001f)
		return standardize(val);
	else
		return "0.00";
}

string@ time_to_s(float time) {
	float hours = floor(time / 60.f / 60.f);
	float minutes = floor((time % (60.f * 60.f)) / 60.f);
	float seconds = floor(time % 60.f);

	if (hours > 0) {
		if (minutes > 0) {
			return combine(f_to_s(hours, 0), "h ",f_to_s(minutes, 0), "m");
		}
		else {
			return f_to_s(hours, 0) + "h";
		}
	}
	else if (minutes > 0) {
		return f_to_s(minutes, 0) + "m";
	}
	else {
		return f_to_s(seconds, 0) + "s";
	}
}

void onClick(Object@ obj) {
	// Shift adds to selection
	if (shiftKey) {
		addSelectedObject(obj);
	}
	// Control toggles selection
	else if (ctrlKey) {
		if (isSelected(obj))
			deselectObject(obj);
		else
			addSelectedObject(obj);
	}
	else {
		// If there is a fleet, select the entire fleet first of all
		if (obj.getOwner() is getActiveEmpire()) {
			HulledObj@ ship = obj;
			if (ship !is null) {
				ObjectLock lock(obj);
				Fleet@ fleet = ship.getFleet();

				if (fleet !is null) {
					// If the fleet is already selected, select only this ship
					if (getSelectedObject(getSubSelection()) is obj) {
						selectObject(obj);
						return;
					}

					// If the fleet is not selected, select all ships in it
					uint cnt = fleet.getMemberCount();

					selectObject(null);
					addSelectedObject(fleet.getCommander());
					for (uint i = 0; i < cnt; ++i)
						addSelectedObject(fleet.getMember(i));

					uint selCnt = getSelectedObjectCount();
					for (uint i = 0; i < selCnt; ++i) {
						if (getSelectedObject(i) is obj)
							setSubSelection(i);
					}
					return;
				}
			}
		}

		// If there's no fleet, just select the object
		selectObject(obj);
	}
}

void onDoubleClick(Object@ obj) {
	// If we double-click a fleet leader, select only the fleet leader
	if (obj.getOwner() is getActiveEmpire()) {
		HulledObj@ ship = obj;
		if (ship !is null) {
			ObjectLock lock(obj);
			Fleet@ fleet = ship.getFleet();

			if (fleet !is null && fleet.getCommander() is obj) {
				selectObject(obj);
				return;
			}
		}
	}

	// Open planet window where appropriate
	Planet@ pl = obj;
	if(@pl != null) {
		if (obj.getOwner() is getActiveEmpire())
			triggerPlanetWin(pl, true);
		return;
	}
	

	// Open system window where appropriate
	if(obj.toSystem() !is null) {



		showSystemWindow(obj.toSystem());
		return;
	}
	else if(obj.toStar() !is null) {
		showSystemWindow(obj.getCurrentSystem());
		return;
	}	
	
	// Open the queue management window where appropriate
	HulledObj@ ship = obj;
	if (ship !is null && obj.getOwner() is getActiveEmpire()) {
		if (ship.getHull().hasSystemWithTag("BuildBay")) {
			triggerQueueWin(obj);
			return;
		}
	}
	
	setCameraFocus(obj);
}

void onBoxSelect(Object@ obj) {
	addSelectedObject(obj);
}

void onPaintSelect(Object@ obj) {
	addSelectedObject(obj);
}

void onCycleSelection() {
	uint cnt = getSelectedObjectCount();
	if (cnt == 0)
		return;
	setSubSelection((getSubSelection() + 1) % cnt);
}

void onRightClick(Object@ obj) {
	triggerContextMenu(obj);
}

void onManageQueue(Object@ obj) {
	triggerQueueWin(obj);
}

void onManageDocked(Object@ obj) {
	triggerUndockWin(obj);
}

void onTriggerEscapeMenu() {
	toggleEscapeMenu();
}

void setTicker(string@ top, string@ bottom) {
	tickerTopPercent.setText(top);
	tickerTop.setText(top);
	tickerBottom.setText(bottom);
	tickerBottomRight.setText(null);
}

void setTicker(string@ top, string@ bottom, string@ bottomRight) {
	tickerTopPercent.setText(top);
	tickerTop.setText(top);
	tickerBottom.setText(bottom);
	tickerBottomRight.setText(bottomRight);
}

void setTickerPercent(float perc, Color col) {
	dim2di textSize = getTextDimension(tickerTopPercent.getText());
	tickerTopPercent.setSize(dim2di(perc * textSize.width, tickerTopPercent.getSize().height));
	tickerTopPercent.setColor(col);
}

GuiScripted@[] top_icos(9);

bool speedUp(const GUIEvent@ evt) {
	if (evt.EventType == GEVT_Clicked) {
		float speed = getGameSpeedFactor();

		if (speed == 0) {
			speed = 1.f;
		} 
		else if (speed < 0.99f) {
			speed *= 2.f;
		}
		else if (speed < 1.01f) {
			speed = 2.f;
		}
		else { 
			speed += 2.f;
			speed = floor(speed/2.f)*2.f;
	    }

		setGameSpeedFactor(speed);
	} else if (evt.EventType == GEVT_Right_Clicked) {
		setGameSpeedFactor(10.f);
	}
	return false;
}

bool slowDown(const GUIEvent@ evt) {
	if (evt.EventType == GEVT_Clicked) {
		float speed = getGameSpeedFactor();

		if (speed > 0.06f) {
			if (speed < 1.01f) {
				speed /= 2.f;
			}
			else if (speed < 2.01f) {
				speed = 1.f;
			}
			else { 
				speed -= 2.f;
				speed = ceil(speed/2.f)*2.f;
			}
		}

		setGameSpeedFactor(speed);
	} else if (evt.EventType == GEVT_Right_Clicked) {
		setGameSpeedFactor(0.03f);
	}
	return false;
}

bool doPause(const GUIEvent@ evt) {
	if (evt.EventType == GEVT_Clicked) {
		pauseGame();
	} else if (evt.EventType == GEVT_Right_Clicked) {
		setGameSpeedFactor(1.f);
	}
	return false;
}

void setMessagesVisible(bool visible) {
	empMsgBG.setVisible(visible);
}

void setTickerVisible(bool visible) {
	tickerBG.setVisible(visible);
}

void setTickerResearchVisible(bool visible) {
	tickerTop.setVisible(visible);
	tickerTopPercent.setVisible(visible);
	tickerBottom.setVisible(visible);
	tickerBottomRight.setVisible(visible);
}

void init() {
	int width = getScreenWidth();
	
	@empMsgBG = GuiImage( pos2di(width / 2 - 250, 26), "message_bg", null);
	empMsgBG.setAlignment(EA_Center, EA_Top, EA_Center, EA_Top);
	
	@glowLine = GuiImage( pos2di(0,0), "glow_line", null);
	@nrov_name = GuiExtText( recti(pos2di(0,0), dim2di(115,15)), null ); nrov_name.setShadow(Color(255,0,0,0));
	@nrov_hpTag = GuiExtText( recti(pos2di(0,0), dim2di(46,15)), null); nrov_hpTag.setShadow(Color(255,0,0,0)); nrov_hpTag.setText("#align:right#"+localize("#OIO_HP")+":");
	@nrov_shieldTag = GuiExtText( recti(pos2di(0,0), dim2di(46,15)), null); nrov_shieldTag.setShadow(Color(255,0,0,0)); nrov_shieldTag.setText("#align:right#"+localize("#OIO_SH")+":");
	@nrov_shieldarmTag = GuiExtText( recti(pos2di(0,0), dim2di(46,15)), null); nrov_shieldarmTag.setShadow(Color(255,0,0,0)); nrov_shieldarmTag.setText("#align:right#"+localize("#OIO_SA")+":");
	@nrov_hpBar = GuiBar( recti( pos2di(0,0), dim2di(50,7)), null); nrov_hpBar.set( Color(255,0,255,0), Color(255,255,0,0), true, 1);
	@nrov_shieldBar = GuiBar( recti( pos2di(0,0), dim2di(50,7)), null); nrov_shieldBar.set( Color(255,0,0,255), Color(255,0,0,0), true, 1);
	@nrov_shieldarmBar = GuiBar( recti( pos2di(0,0), dim2di(50,7)), null); nrov_shieldarmBar.set( Color(255,0,255,255), Color(255,0,0,0), true, 1);
	@nrov_build = GuiExtText( recti(pos2di(0,0), dim2di(200,15)), null); nrov_build.setShadow(Color(255,0,0,0));
	hideNearOverlay();
	
	@empireMessages = GuiExtText(recti( pos2di(8,3), dim2di(500 - 38, 18)), empMsgBG);
	@clock = GuiExtText(recti(pos2di(width-125, 4), dim2di(125, 36)), null);
	clock.setAlignment(EA_Right, EA_Top, EA_Right, EA_Top);

	@speedIndicator = GuiStaticText(recti(pos2di(width-125, 39), dim2di(100, 18)), localize("#paused"), false, false, false, null);
		speedIndicator.setFont("stroked");
		speedIndicator.setAlignment(EA_Right, EA_Top, EA_Right, EA_Top);
	@speedUpButton = GuiButton(getSkinnable("Button"), recti(pos2di(width-14, 43), dim2di(10,10)), ">", null);
		speedUpButton.setAlignment(EA_Right, EA_Top, EA_Right, EA_Top);
	@pauseButton = GuiButton(getSkinnable("Button"), recti(pos2di(width-26, 43), dim2di(10,10)), "|", null);
		pauseButton.setAlignment(EA_Right, EA_Top, EA_Right, EA_Top);
	@slowDownButton = GuiButton(getSkinnable("Button"), recti(pos2di(width-38, 43), dim2di(10,10)), "<", null);
		slowDownButton.setAlignment(EA_Right, EA_Top, EA_Right, EA_Top);
		
	gameShipLimit = int(getGameSetting("LIMIT_SHIPS", 0));
	if (gameShipLimit > 0)
		@shipLimit = GuiExtText(recti(8, 108, 174, 132), null);
	bool client = isClient();
	speedUpButton.setVisible(!client);
	slowDownButton.setVisible(!client);
	pauseButton.setVisible(!client);

	bindGuiCallback(speedUpButton, "speedUp");
	bindGuiCallback(slowDownButton, "slowDown");
	bindGuiCallback(pauseButton, "doPause");
	
	msgShrinkPos = pos2di(500 - 18, 4);
	
	@msgLog = GuiButton(recti( pos2di(500 - 18 - 17, 4), dim2di(16,16)), null, empMsgBG);
	msgLog.setImage("msg_box_log");
	msgLog.setAlignment(EA_Right, EA_Bottom, EA_Right, EA_Bottom);
	@msgExpand = GuiButton(recti( pos2di(500 - 18, 4), dim2di(16,16)), null, empMsgBG);
	msgExpand.setImage("msg_box_expand");
	@msgShrink = GuiButton(recti( pos2di(500 - 18, 4), dim2di(16,16)), null, empMsgBG);
	msgShrink.setImage("msg_box_shrink");
	msgShrink.setVisible(false);
	
	msgShrink.setAlignment(EA_Right, EA_Bottom, EA_Right, EA_Bottom);
	filterButtons.resize(filters.length());
	int filterID = reserveGuiID();
	for (uint i = 0; i < filters.length(); ++i) {
		@filterButtons[i] = GuiButton(getSkinnable("ToggleButton"), recti(pos2di(4 + 52 * i, 4), dim2di(48, 16)), localize("#MT_Filter_"+filters[i]), empMsgBG);
		filterButtons[i].setToolTip(localize("#MTTT_Filter_"+filters[i]));
		filterButtons[i].setToggleButton(true);
		filterButtons[i].setPressed(filterState[i]);
		filterButtons[i].setVisible(false);
		filterButtons[i].setID(filterID);
		filterButtons[i].setAlignment(EA_Left, EA_Bottom, EA_Left, EA_Bottom);
	}
	
	bindGuiCallback(filterID, "refreshMsgs");
	bindGuiCallback(msgExpand, "expandMsgBox");
	bindGuiCallback(msgShrink, "shrinkMsgBox");
	bindGuiCallback(msgLog, "openLogWindow");

	@mouseOverlay = GuiExtText(recti( pos2di(-1,-1), dim2di(300, 200)), null);
	mouseOverlay.setNoclipped(true);
	
	
	@tickerBG = GuiImage( pos2di(0,0), "new_ticker_bg", null);
	@tickerTop = GuiStaticText( recti( pos2di(11,8), dim2di(200, 15) ), null, false, false, false, tickerBG);
	@tickerTopPercent = GuiStaticText( recti( pos2di(11,8), dim2di(20, 15) ), null, false, false, false, tickerBG);

	@tickerBottom = GuiStaticText( recti( pos2di(11,16+8+8), dim2di(195, 15) ), null, false, false, false, tickerBG);
	@tickerBottomRight = GuiStaticText( recti( pos2di(11,16+8+8), dim2di(195, 15) ), null, false, false, false, tickerBG);
	
	tickerBottomRight.setTextAlignment(EA_Right, EA_Top);
	tickerTop.setColor( Color(255, 255, 255, 255) );
	tickerBottom.setColor( Color(255, 255, 255, 255) );
	tickerBottomRight.setColor( Color(255, 255, 255, 255) );

	@bankAdv = GuiExtText(recti(pos2di(-35,  60), dim2di(82, 18)), tickerBG);
	@bankElc = GuiExtText(recti(pos2di(25, 60), dim2di(82, 18)), tickerBG);
	@bankMtl = GuiExtText(recti(pos2di(85, 60), dim2di(82, 18)), tickerBG);
	@bankFood = GuiExtText(recti(pos2di(-35, 78), dim2di(82, 18)), tickerBG);
	@bankGoods = GuiExtText(recti(pos2di(25, 78), dim2di(82, 18)), tickerBG);
	@bankLux = GuiExtText(recti(pos2di(85, 78), dim2di(82, 18)), tickerBG);
	@bankFuel = GuiExtText(recti(pos2di(-34, 96), dim2di(82, 18)), tickerBG);
	@bankAmmo = GuiExtText(recti(pos2di(26, 96), dim2di(82, 18)), tickerBG);	
	@bankTrade = GuiExtText(recti(pos2di(86, 96), dim2di(82, 18)), tickerBG);		

	GuiScripted@ ico;
	@ico = GuiScripted(recti(pos2di(50, 63), dim2di(10, 16)), gui_sprite("planet_resource_list", 0) , tickerBG);
	ico.setToolTip(localize("#GBR_advparts"));
	@top_icos[0] = @ico;

	@ico = GuiScripted(recti(pos2di(110, 63), dim2di(10, 16)), gui_sprite("planet_resource_list", 1) , tickerBG);
	ico.setToolTip(localize("#GBR_electronics"));
	@top_icos[1] = @ico;

	@ico = GuiScripted(recti(pos2di(170, 63), dim2di(10, 16)), gui_sprite("planet_resource_list", 2) , tickerBG);
	ico.setToolTip(localize("#GBR_metals"));
	@top_icos[2] = @ico;

	@ico = GuiScripted(recti(pos2di(47, 77), dim2di(17,17)), gui_sprite("planet_topbar_resources", 0), tickerBG);
	ico.setToolTip(localize("#GBR_food"));
	@top_icos[3] = @ico;

	@ico = GuiScripted(recti(pos2di(107, 77), dim2di(17,17)), gui_sprite("planet_topbar_resources", 6), tickerBG);
	ico.setToolTip(localize("#GBR_goods"));
	@top_icos[4] = @ico;

	@ico = GuiScripted(recti(pos2di(167, 77), dim2di(17,17)), gui_sprite("planet_topbar_resources", 7), tickerBG);
	ico.setToolTip(localize("#GBR_luxuries"));
	@top_icos[5] = @ico;
	
	@ico = GuiScripted(recti(pos2di(51, 99), dim2di(10, 16)), gui_sprite("planet_resource_list", 5) , tickerBG);
	ico.setToolTip(localize("#GBR_fuel"));
	@top_icos[6] = @ico;

	@ico = GuiScripted(recti(pos2di(111, 99), dim2di(10, 16)), gui_sprite("planet_resource_list", 6) , tickerBG);
	ico.setToolTip(localize("#GBR_ammo"));
	@top_icos[7] = @ico;
	
	@ico = GuiScripted(recti(pos2di(170, 99), dim2di(10,16)), gui_sprite("planet_resource_list", 4), tickerBG);
	ico.setToolTip(localize("#GBR_trade"));
	@top_icos[8] = @ico;

	@bankToggle = GuiButton(recti(pos2di(190, 68), dim2di(22,16)), null, tickerBG);
	bankToggle.setAppearance(BA_UseAlpha, BA_Background);
	bankToggle.setSprites("economy_btn_mode", 3, 5, 4);
	bankToggle.setToolTip(localize("#TT_bankToggle"));
	bindGuiCallback(bankToggle, "toggleBankDisplay");

	@civActs = GuiButton(recti(pos2di(190, 84), dim2di(22,16)), null, tickerBG);
	civActs.setAppearance(BA_UseAlpha, BA_Background);
	civActs.setSprites("economy_btn_mode", 6, 8, 7);
	civActs.setToolTip(localize("#TT_civActs"));
	bindGuiCallback(civActs, "openCivilActs");

	@econReportButton = GuiButton(recti(pos2di(190, 100), dim2di(22,16)), null, tickerBG);
	econReportButton.setAppearance(BA_UseAlpha, BA_Background);
	econReportButton.setSprites("economy_btn_report", 0, 2, 1);
	econReportButton.setToolTip(localize("#TT_econReport"));
	bindGuiCallback(econReportButton, "openEconReport");

	bindGuiCallback(empMsgBG, "hoverMsgBox");
	bindGuiCallback(empireMessages, "hoverMsgBox");
}

void setBankButtonsVisible(bool vis) {
	econReportButton.setVisible(vis);
	bankToggle.setVisible(vis);
}

void setCivActsButtonVisible(bool vis) {
	civActs.setVisible(vis);
}
uint em_curSize = 0;
bool msgMousedOver = false;

bool hoverMsgBox(const GUIEvent@ evt) {
	if (evt.EventType == GEVT_Mouse_Over)
		msgMousedOver = true;
	else if (evt.EventType == GEVT_Mouse_Left)
		msgMousedOver = false;
	return false;
}

bool refreshMsgs(const GUIEvent@ evt) {
	if(evt.EventType == GEVT_Clicked) {
		em_lastMsg = -1;
	}
	return false;
}

bool openLogWindow(const GUIEvent@ evt) {
	if (evt.EventType == GEVT_Clicked) {
		createLogWindow();
	}
	return false;
}
bool expandMsgBox(const GUIEvent@ evt) {
	if(evt.EventType == GEVT_Clicked) {
		if(em_curSize == 0) {
			empMsgBG.setImage("message_bg_5line");
			empMsgBG.setSize( dim2di(500, 96) );
			empMsgBG.bringToFront();
			empireMessages.setSize( dim2di(500 - 18, 96 - 6) );

			for (uint i = 0; i < filters.length(); ++i)
				filterButtons[i].setVisible(true);

			msgShrink.setVisible(true);
			em_curSize = 1;

			msgLog.setPosition(pos2di(msgLog.getPosition().x, msgShrink.getPosition().y));

			return true;
		}
		else if(em_curSize == 1) {
			empMsgBG.setImage("message_bg_14line");
			empMsgBG.setSize( dim2di(500, 240) );
			empMsgBG.bringToFront();
			empireMessages.setSize( dim2di(500 - 18, 240 - 6) );

			for (uint i = 0; i < filters.length(); ++i)
				filterButtons[i].setVisible(true);
						
			msgShrink.setVisible(true);
			
			msgExpand.setVisible(false);
			em_curSize = 2;
			
			return true;
		}
	}
	return false;
}

bool shrinkMsgBox(const GUIEvent@ evt) {
	if(evt.EventType == GEVT_Clicked) {
		if(em_curSize == 2) {
			empMsgBG.setImage("message_bg_5line");
			empMsgBG.setSize( dim2di(500, 96) );
			empireMessages.setSize( dim2di(500 - 16, 96 - 6) );

			for (uint i = 0; i < filters.length(); ++i)
				filterButtons[i].setVisible(true);
			
			
			msgExpand.setVisible(true);
			em_curSize = 1;
			
			return true;
		}
		else if(em_curSize == 1) {
			empMsgBG.setImage("message_bg");
			empMsgBG.setSize( dim2di(500, 24) );
			empireMessages.setSize( dim2di(500 - 16, 26 - 8) );

			for (uint i = 0; i < filters.length(); ++i)
				filterButtons[i].setVisible(false);
				
			msgShrink.setVisible(false);
			
			msgExpand.setVisible(true);
			em_curSize = 0;
			
			return true;
		}
	}
	return false;
}


uint lastSizeMode = 255;

string@ getStatePrefix(float delta, float amn) {

	if (amn < -0.001f)
		return "#a:r##c:faa#-";
	if (delta > 0)
		return "#a:r##c:aca#";
	else if (delta < 0)
		return "#a:r##c:caa#";
	else
		return "#a:r#";
}

string@ getRatePrefix(float delta) {
	if(delta > 0)
		return "#a:r##c:aca#+";
	else if(delta < 0)
		return "#a:r##c:caa#-";
	else
		return "#a:r#";
}

void updateBankState(float& prev, float now, float& rate, float duration) {
	rate = (now - prev) / duration;
	prev = now;
}

bool openEconReport(const GUIEvent@ evt) {
	if(evt.EventType == GEVT_Clicked) {
		ToggleEconomyReport();
	}
	return false;
}

bool toggleBankDisplay(const GUIEvent@ evt) {
	if(evt.EventType == GEVT_Clicked) {
		bankMode = !bankMode;
		bankCounter = 1.f;

		if (bankMode)
			bankToggle.setSprites("economy_btn_mode", 0, 2, 1);
		else
			bankToggle.setSprites("economy_btn_mode", 3, 5, 4);
	}
	return false;
}

bool openCivilActs(const GUIEvent@ evt) {
	if(evt.EventType == GEVT_Clicked) {
		toggleCivilActsWin();
	}
	return false;
}
int lastMins = -1, lastGameMins = -1;

bool isCategoryActive(string@ cat) {
	int len = filters.length();
	for (int i = 0; i < len; ++i) {
		if (!filterButtons[i].isPressed() && cat == filters[i])
			return false;
	}
	return true;
}

bool isPriorityActive(int prior) {
	return prior >= 0;
}

float msgMouseDelay = 0.f;
uint notifyThrottle = 0;

void tick(float time) {	
	if (notifyThrottle > 0)
		--notifyThrottle;

	Empire@ emp = getActiveEmpire();
	if(emp.lastMessage > em_lastMsg || lastSizeMode != em_curSize) {
		string@ allMsgs = "";
		EmpireMessages msgs;
		msgs.prepare(emp);
		
		if(msgs.getCount() > 0) {		
			uint lines = em_curSize == 0 ? 1 : em_curSize == 1 ? 4 : 13;
		
			do {
				int prior = msgs.getPriority();
				string@ cat = msgs.getCategory();
				if (isCategoryActive(cat) && isPriorityActive(prior)) {
					double time = msgs.getTime();
					if (time > em_lastMsg)
						msgMouseDelay = 0.f;
					if (time > em_lastVisMsg && notifyThrottle == 0) {
						if (em_lastVisMsg > 0)
							playSound("msg_notify");

						em_lastVisMsg = time;
						notifyThrottle = 6;
					}
					allMsgs += (msgs.getMsg() + "\n");
					lines -= 1;
				}
			} while(lines > 0 && msgs.nextMsg());
		}
		
		msgs.prepare(null);
		empireMessages.setText(allMsgs);
		
		em_lastMsg = emp.lastMessage;
		lastSizeMode = em_curSize;
	}
	
	//In one-line mode, fade out older messages
	if(em_curSize == 0 && !msgMousedOver) {

		float delay = msgMouseDelay;
		float fade = 1;

		if(delay > 5.f)
			if(delay >= 7.f)
				fade = 0.6f;
			else
				fade = 0.6f + 0.4f * (7.f - delay) / 2.f;
				
		empireMessages.setAlpha(fade);
	}
	else {
		empireMessages.setAlpha(1);
		msgMouseDelay = 0.f;
	}

	if (getActiveEmpire().hasTraitTag("disable_civil_acts")) {
		civActs.setSprites("economy_btn_mode", 9, 9, 9);
		civActs.setEnabled(false);
	}
	else {
		civActs.setSprites("economy_btn_mode", 6, 8, 7);
		civActs.setEnabled(true);
	}
	msgMouseDelay += time;

	//Update empire bank numbers
	bankCounter += time;

	//Update once per second
	if (bankCounter >= 1.f) {
		//Unless the game is paused
		if(prevBankUpdate != gameTime) {
			float since = float(gameTime - prevBankUpdate);
			prevBankUpdate = gameTime;
			
			updateBankState(prevMtl, emp.getStat("Metals"), rateMtl, since);
			updateBankState(prevElc, emp.getStat("Electronics"), rateElc, since);
			updateBankState(prevAdv, emp.getStat("AdvParts"), rateAdv, since);
			updateBankState(prevFood, emp.getStat("Food"), rateFood, since);
			updateBankState(prevGoods, emp.getStat("Guds"), rateGoods, since);
			updateBankState(prevLux, emp.getStat("Luxs"), rateLux, since);
			updateBankState(prevFuel, emp.getStat("Fuel"), rateFuel, since);
			updateBankState(prevAmmo, emp.getStat("Ammo"), rateAmmo, since);
			updateBankState(prevTrade, emp.getStat("importer"), rateTrade, since);

			if (!bankMode) {
				bankMtl.setText(	getStatePrefix(rateMtl, prevMtl)  +standardize(abs(prevMtl)));
				bankElc.setText(	getStatePrefix(rateElc, prevElc)  +standardize(abs(prevElc)));
				bankAdv.setText(	getStatePrefix(rateAdv, prevAdv)  +standardize(abs(prevAdv)));
				bankFood.setText(	getStatePrefix(rateFood, prevFood) +standardize(abs(prevFood)));
				bankGoods.setText(	getStatePrefix(rateGoods, prevGoods)+standardize(abs(prevGoods)));
				bankLux.setText(	getStatePrefix(rateLux, prevLux)  +standardize(abs(prevLux)));
				bankFuel.setText(	getStatePrefix(rateFuel, prevFuel)  +standardize(abs(prevFuel)));
				bankAmmo.setText(	getStatePrefix(rateAmmo, prevAmmo)  +standardize(abs(prevAmmo)));
				bankTrade.setText(	getStatePrefix(rateTrade, prevTrade)  +standardize(abs(prevTrade)));					
			}
			else {
				bankMtl.setText(	getRatePrefix(rateMtl)  +standardize(abs(rateMtl)));
				bankElc.setText(	getRatePrefix(rateElc)  +standardize(abs(rateElc)));
				bankAdv.setText(	getRatePrefix(rateAdv)  +standardize(abs(rateAdv)));
				bankFood.setText(	getRatePrefix(rateFood) +standardize(abs(rateFood)));
				bankGoods.setText(	getRatePrefix(rateGoods)+standardize(abs(rateGoods)));
				bankLux.setText(	getRatePrefix(rateLux)  +standardize(abs(rateLux)));
				bankFuel.setText(	getRatePrefix(rateFuel)  +standardize(abs(rateFuel)));
				bankAmmo.setText(	getRatePrefix(rateAmmo)  +standardize(abs(rateAmmo)));	
				bankTrade.setText(	getRatePrefix(rateTrade)  +standardize(abs(rateTrade)));					
			}

			rateTrade = rateFuel = rateAmmo = rateMtl = rateElc = rateAdv = rateFood = rateGoods = rateLux = 0.f;
		}
		bankCounter = 0.f;
	}
	// Update ship limit
	if (gameShipLimit > 0) {
		int shipCount = int(emp.getStat("Ship"));

		if (shipCount < gameShipLimit) {
			shipLimit.setText(combine(localize("#NG_ShipLimit"),
						"#tab:100#", i_to_s(shipCount), " / ",
						i_to_s(gameShipLimit)));
		}
		else {
			shipLimit.setText(combine("#c:red#",
				combine(localize("#NG_ShipLimit"), "#tab:100#",
				i_to_s(shipCount), " / ", i_to_s(gameShipLimit)), "#c#"));
		}
	}
	
	if(@curObject != null)
		setMouseOverlayText(curObject);
	
	updateNearbyObject(getCameraFocus());

	//Update clock
	float gt = getCurrentGameTime();
	int gtHours = floor(gt / 3600.0);
	int gtMins = floor((gt-gtHours*3600.0) / 60.0);

	int ttime = getCurrentTime();
	int ttHours = floor(ttime / 60.0);
	int ttMins = (ttime-ttHours*60.0);

	//GAH I WANT SPRINTF (HAH, YOU DON'T GET THE MOST UNSTABLE FUNCTION IN EXISTENCE FOR A SCRIPT LANGUAGE)
	
	if(lastMins != ttMins || lastGameMins != gtMins) {
		lastMins = ttMins;
		lastGameMins = gtMins;
	
		string@ teMins = (ttMins >= 10 ? "" : "0")+ttMins;
		string@ geMins = (gtMins >= 10 ? "" : "0")+gtMins;

		clock.setText(combine("#font:stroked#", localize("#time")+": "+ttHours+":"+teMins+"\n"+localize("#gametime")+": "+gtHours+"h:"+geMins+"m", "#font"));
	}

	//Update pause indicator 
	float speed = getRealGameSpeedFactor();
	if (speed != prevSpeed) {
		prevSpeed = speed;
		if (speed < 0.01f) {
			speedIndicator.setText(localize("#paused"));
			speedIndicator.setColor(Color(255, 200, 200, 50));
		}
		else {
			speedIndicator.setText(standardize(speed)+"x "+localize("#speed"));

			if (speed  > 1.01f)
				speedIndicator.setColor(Color(255, 55, 200, 55));
			else if (speed < 0.99f)
				speedIndicator.setColor(Color(255, 200, 55, 55));
			else
				speedIndicator.setColor(Color(255, 255, 255, 255));
		}
	}
}

Object@ curObject;

pos2di lastTopRight;

string@ formatDistance(float range) {
	if(range < unitsPerAU)
		return ftos_nice(range / unitsPerAU, 3);
	else
		return standardize(range / unitsPerAU);
}

string@ formatValue(float val, float max, string@ name, Color full, Color empty) {
	Color col = full;
	if(max <= 0)
		max = 1.f;
	col = col.interpolate(empty, val/max);

	return combine(
			combine("\n", name, ": "),
			combine("#c:", col.format(), "#"),
			combine(standardize_nice(val), "/", standardize_nice(max)),
			"#c#"
		);
}

string@ formatValue(int val, int max, string@ name, Color full, Color empty) {
	Color col = full;
	if(max <= 0)
		max = 1;
	col = col.interpolate(empty, float(val)/float(max));

	return combine(
			combine("\n", name, ": "),
			combine("#c:", col.format(), "#"),
			combine(i_to_s(val), "/", i_to_s(max)),
			"#c#"
		);
}

string@ formatState(Object@ obj, string@ state, string@ name, Color full, Color empty, bool reverse) {
	float val = 0.f, max = 0.f, req = 0.f, cargo = 0.f;
	if (obj.getStateVals(state, val, max, req, cargo) && max > 0) {
		if (reverse)
			val = max-val;
		return formatValue(val, max, name, full, empty);
	}
	return "";
}

string@ strJumpDrive = "JumpDrive", strMinRange = "vJumpRangeMin", strMaxRange = "vJumpRange", strStargate = "Stargate", strBankAccess = "BankAccess";;
void setMouseOverlayText(Object@ obj) {
	ObjectLock lock(obj);

	@curObject = @obj;
	HulledObj@ hull = obj.toHulledObj();
	Planet@ pl = obj;
	System@ sys = obj;
	System@ curSys = obj.getParent();
	Oddity@ odd = obj;
	
	Star@ star = obj;
	if (star !is null)
		@sys = obj.getParent();
	if (sys !is null)
		@curSys = sys;

	Empire@ emp = getActiveEmpire();
	Empire@ owner = obj.getOwner();

	bool explored = curSys !is null && curSys.hasExplored(emp);
	bool sysVisible = curSys !is null && curSys.isVisibleTo(emp);
	bool visible = obj.isVisibleTo(emp);
	bool owned = owner is emp;
	
	Color ownerColor = Color(255,255,255,255);
	if (sys !is null) {
		ownerColor = sys.getRingColor();
		ownerColor.A = 255;
	}
	else if (owner !is null) {
		ownerColor = owner.color;
	}
	
	string@ mo_text = combine("#c:", ownerColor.format(), "#", obj.getName(), "#c#");	
	
	// Ship scale
	if (@hull != null && @hull.getHull() != null)
		mo_text += " ("+standardize(pow(obj.radius, 2))+")";
		
	// Planet governor	
	if (@pl != null && owned)
		if (!pl.usesGovernor())
			mo_text += " ("+localize("#PG_NoGov")+")";
		else
			mo_text += " ("+localize("#PG_"+pl.getGovernorType())+")";
			
	// Blockaded
	bool blockaded = false;
	if (pl !is null) {
		blockaded = curSys !is null && curSys.isBlockadedFor(owner);
	}
	else if (sys !is null) {
		blockaded = sys.hasPlanets(emp) && sys.isBlockadedFor(emp);
	}
	else if (hull !is null && curSys !is null) {
		if (hull.getHull().hasSystemWithTag(strBankAccess))
			blockaded = curSys.isBlockadedFor(emp);
	}

	if (blockaded)
		mo_text += combine("\n#c:f44#", localize("#MO_Blockade"),"#c#");
	
			
	//Object Hitpoints
	float hpVal = 0.f, hpMax = 0.f, temphp = 0.f;
	if(obj.getStateVals("Damage", hpVal, hpMax, temphp, temphp)) {
		if(hull is null) {
			if(sysVisible)
				mo_text += formatState(obj, "Damage", localize("#MO_HP"), Color(255, 0, 220, 0), Color(255, 255, 0, 0), true);
			else if (explored)
				mo_text += combine("\n", localize("#MO_HP"), ": #c:00DC00#", standardize_nice(hpMax), "#c#");	
		} else {
			mo_text += formatState(obj, "Damage", localize("#MO_HP"), Color(255, 0, 220, 0), Color(255, 255, 0, 0), true);
		}
	}	
	
	//Structure Hitpoints
	if(pl !is null) {
		PlanetStructureList pList;
		pList.prepare(pl); 
		uint structureCount = pList.getCount();
		if(structureCount > 0) {		
			float structureVal = 0, structureMax = 0;
			for(uint i = 0; i < structureCount; i++) {
				const SysRef@ structure = pList.getStructureState(i);
				structureVal += structure.HP;
				if(owned)
					structureMax += structure.system.maxHP;
			}
			if(owned)
				mo_text += formatValue(structureVal, structureMax, localize("#MO_STRUCT_HP"), Color(255, 0, 220, 0), Color(255, 255, 0, 0));
			else if (sysVisible)
				mo_text += combine("\n", localize("#MO_STRUCT_HP"), ": #c:00DC00#", standardize_nice(structureVal), "#c#");
		}
	}	
	
	//Shield hitpoints
	float psVal = 0.f, psMax = 0.f, tempps = 0.f;
	if(hull !is null) {
		mo_text += formatState(obj, "Shields", localize("#MO_SHP"), Color(255, 80, 180, 200), Color(255, 200, 80, 180), false);
	} else if (obj.getStateVals("Shields", psVal, psMax, tempps, tempps) && hull is null) {
		if(sysVisible || owned)
			mo_text += formatState(obj, "Shields", localize("#MO_SHP"), Color(255, 80, 180, 200), Color(255, 200, 80, 180), false);
		else if(explored)
			mo_text += combine("\n", localize("#MO_SHP"), ": #c:00baff#", standardize_nice(psMax), "#c#");
	}			
	mo_text += formatState(obj, "ShieldArmor", localize("#MO_SAHP"), Color(255, 75, 225, 230), Color(200, 195, 125, 210), false);

	//Heatsink
	mo_text += formatState(obj, "Heatsink", localize("#MO_HEATSINK"), Color(255, 255, 0, 0), Color(255, 0, 60, 180), false);
	
	// H3 Amount
	{
		float h3Val = 0.f, h3Max = 0.f, temph3 = 0.f;
		if (obj.getStateVals("H3", h3Val, h3Max, temph3, temph3)) {	
			if(sysVisible) {
				mo_text += formatState(obj, "H3", localize("#MO_H3"), Color(0xffa65296), Color(0xffd23323),false);
			}
			else if(explored) {
				if (h3Max <= 0.1f)
					mo_text += combine("\n", localize("#MO_H3"), ": #c:d23323#0.00#c#");
				else 
					mo_text += combine("\n", localize("#MO_H3"), ": #c:a65296#", standardize_nice(h3Val), "#c#");	
			}			
		}	
	}
	
	// Cargo and Shipbay
	float used, max2;
	obj.getCargoVals(used, max2);
	if(max2 > 0.f)
		mo_text += formatValue(used, max2, localize("#MO_Cargo"), Color(0xffCDCDCD), Color(0xff737373));
	obj.getShipBayVals(used, max2);
	if(max2 > 0.f)
		mo_text += formatValue(used, max2, localize("#MO_ShipBay"), Color(0xff7DA7D9), Color(0xff605CA8));

	//Overheat Warning
	float overheated = 0.f, req = 0.f, cargo = 0.f;
	if(obj.getStateVals("Overheated", overheated, max2, req, cargo)){
		Color heatCol = Color(255, 255, 0, 0);
		if(overheated >= 1.f)
			mo_text += combine("\n",
							   combine("#c:", heatCol.format(), "#"),
							   localize("#MO_OVERHEATED"),
							   "#c#");	
	}
	
	//Repair Status
	float hp = 0.f, dmg = 0.f, shieldHP = 0.f, shieldDMG = 0.f, shieldArmorHP = 0.f, shieldArmorDMG = 0.f, repairTime = 0.f;
	if(obj.hasState("HasRepair")) {
		if(obj.getStateVals("Damage", dmg, hp, req, cargo)){
			obj.getStateVals("DamageTimer", repairTime, max2, req, cargo);
			Color repCol = Color(255, 255, 255, 0);
			Color metCol = Color(255, 255, 0, 0);
			Color noCol = Color(255, 0, 220, 0);
			Color timeCol = Color(255, 255, 180, 0);
			
			float seconds = repairTime - gameTime;
		
			if(dmg <= 0.f)
				mo_text += combine("\n",
								   combine("#c:", noCol.format(), "#"),
								   localize("#MO_DMG"),
								   "#c#");
				//mo_text += "\n"+localize("#MO_DMG");
			else if(seconds > 0.0f && dmg > 0.f && obj.hasState("HasDelRepair"))
				mo_text += combine(combine("\n", localize("#MO_RTimer"), ": "),
								   combine("#c:", timeCol.format(), "#"),
								   standardize(max(0.f, seconds)),
								   "#c#");
				//mo_text += "\n"+localize("#MO_RTimer")+": " + standardize(max(0.f, repairTime - gameTime));
			else if(owner.getStat("Metals") <= 0.f && !owner.hasTraitTag("no_bank"))
				mo_text += combine("\n",
								   combine("#c:", metCol.format(), "#"),
								   localize("#MO_NoMetal"),
								   "#c#");
				//mo_text += "\n"+localize("#MO_NoMetal");
			else if(dmg > 0.f) 
				mo_text += combine("\n",
								   combine("#c:", repCol.format(), "#"),
								   localize("#MO_Repairs"),
								   "#c#");
				//mo_text += "\n"+localize("#MO_Repairs");
		}
	}
	
	//Workers and Slots
	if (pl !is null) {
		if (owned) {
			mo_text += formatState(obj, "Workers", localize("#MO_Population"), Color(0xffa65296), Color(0xffd23323), false);
			mo_text += formatValue(int(pl.getStructureCount()), int(pl.getMaxStructureCount()),
					localize("#MO_Slots"), Color(0xffA67C52), Color(0xff616161));
		}
		else if (explored) {
			mo_text += combine("\n", localize("#MO_Slots"), ": #c:a616161#", f_to_s(pl.getMaxStructureCount(), 0), "#c#");
		}
	}
	
	//Conditions
	if(pl !is null && explored) {
		uint condCnt = pl.getConditionCount();
		if(condCnt > 0) {
			mo_text += combine("\n",localize("#MO_Conditions"),": ");
			for(uint i = 0; i < condCnt; ++i) {
				const PlanetCondition@ cond = pl.getCondition(i);
				if (cond !is null) {
					if(i != 0) {
						if(cond.positive)
							mo_text += combine(", ","#c:72b653#" ,localize("#PC_" + cond.get_id()), "#c#");
						else
							mo_text += combine(", ","#c:f44#" ,localize("#PC_" + cond.get_id()), "#c#");
					}		
					else {
						if(cond.positive)
							mo_text += combine("#c:72b653#" ,localize("#PC_" + cond.get_id()), "#c#");
						else
							mo_text += combine("#c:f44#" ,localize("#PC_" + cond.get_id()), "#c#");
					}
				}	
				else
					error("Planet condition was null: "+i+"/"+condCnt);
			}
		}

	}
	
	//Construction
	if(owned) {
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
	
	//Ore
	if (hull is null) {
		float oreVal = 0.f, oreMax = 0.f, temp = 0.f;
		if (obj.getStateVals("Ore", oreVal, oreMax, temp, temp)) {
			if (pl is null && sysVisible && oreMax > 0) {
				mo_text += formatValue(oreVal, oreMax, localize("#MO_Ore"), Color(255, 0xC6, 0x9C, 0x6D), Color(255, 0x73, 0x63, 0x57));
			}
			else if (pl !is null && owned && oreMax > 0) {
				mo_text += formatValue(oreVal, oreMax, localize("#MO_Ore"), Color(255, 0xC6, 0x9C, 0x6D), Color(255, 0x73, 0x63, 0x57));
			}			
			else if (explored) {
				if (oreMax <= 0.1f)
					mo_text += combine("\n", localize("#MO_Ore"), ": #c:736357#0.00#c#");
				else
					mo_text += combine("\n", localize("#MO_Ore"), ": #c:c69c6d#", standardize_nice(oreVal), "#c#");		
			}
		}
	}
	
	//Fuel and Ammo
	if(owned && pl !is null) {
		mo_text += formatState(obj, "Fuel", localize("#MO_Fuel"), Color(0xffff8500), Color(0xffff8500), false);
		mo_text += formatState(obj, "Ammo", localize("#MO_Ammo"), Color(0xffb54f4a), Color(0xffb54f4a), false);
	}
	
	// System tags
	if (sys !is null) {
		SystemTags tags;
		tags.prepare(sys);

		if (tags.getCount() > 0) {
			string@ conditions = null;
			do {
				string@ tag = tags.getTag();

				if (explored) {
					string@ name = localize(combine("#ST_", tag, "_Name"));
					string@ desc = localize(combine("#ST_", tag, "_Desc"));

					if (name !is null && !name.beginsWith("#ST_")) {
						if (desc !is null && !desc.beginsWith("#ST_"))
							mo_text += combine("\n", name, "\n    ", desc);
						else
							mo_text = combine(mo_text, "\n", name);
					}
				}
			}
			while (tags.next());
		}
		
		if (!sysVisible) {
			float lastIntel = sys.getLastIntel();
			if (lastIntel > 0) {
				lastIntel = gameTime - lastIntel;
				mo_text += combine("\n", localize("#MO_LastIntel"),
							time_to_s(lastIntel), localize("#MO_Ago"));
			}
		}
	}
	
	// Speed
	if (pl is null || obj.thrust > 0) {
		if(star is null) {
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
	}	

	// Distance and range meters
	Object@ selected = getSelectedObject(getSubSelection());
	if(selected !is null && selected !is obj) {
		string@ strAU = localize("#MO_AU");
		float dist = selected.getPosition().getDistanceFrom(obj.getPosition());
		if(dist > 0.01f) {
			mo_text += combine("\n", localize("#MO_Distance"), formatDistance(dist), strAU);
		}

		if (selected.getOwner() is emp && obj.toStar() !is null) {
			HulledObj@ hulled = selected;

			if (hulled !is null && hulled.getHull().hasSystemWithTag(strJumpDrive)) {
				float minRange = -1.f;
				float maxRange = -1.f;

				// Get the jump drive ranges
				uint cnt = hulled.getSubSystemCount();
				for (uint i = 0; i < cnt; ++i) {
					subSystem@ sys = hulled.getSubSystem(i).system;
					if (sys.type.hasTag(strJumpDrive)) {
						float mn = sys.getVariable(strMinRange);
						float mx = sys.getVariable(strMaxRange);

						if (minRange < 0 || mn < minRange)
							minRange = mn;
						if (maxRange < 0 || mx > maxRange)
							maxRange = mx;
					}
				}

				bool inRange = dist > minRange && dist < maxRange;
				mo_text += combine("\n", localize("#MO_JumpRange"),
						inRange ? "#c:00dc00#" : "#c:dc0000#",
						combine(formatDistance(minRange), strAU, " - ",
							    formatDistance(maxRange), strAU),
						"#c#");
			}
		}
		if (selected.getOwner() is emp && obj.toSystem() !is null) {
			HulledObj@ hulled = selected;

			if (hulled !is null && hulled.getHull().hasSystemWithTag(strJumpDrive)) {
				float minRange = -1.f;
				float maxRange = -1.f;

				// Get the jump drive ranges
				uint cnt = hulled.getSubSystemCount();
				for (uint i = 0; i < cnt; ++i) {
					subSystem@ sys = hulled.getSubSystem(i).system;
					if (sys.type.hasTag(strJumpDrive)) {
						float mn = sys.getVariable(strMinRange);
						float mx = sys.getVariable(strMaxRange);

						if (minRange < 0 || mn < minRange)
							minRange = mn;
						if (maxRange < 0 || mx > maxRange)
							maxRange = mx;
					}
				}

				bool inRange = dist > minRange && dist < maxRange;
				mo_text += combine("\n", localize("#MO_JumpRange"),
						inRange ? "#c:00dc00#" : "#c:dc0000#",
						combine(formatDistance(minRange), strAU, " - ",
							    formatDistance(maxRange), strAU),
						"#c#");
			}
		}
		if (selected.getOwner() is emp && obj.toPlanet() !is null) {
			HulledObj@ hulled = selected;

			if (hulled !is null && hulled.getHull().hasSystemWithTag(strJumpDrive)) {
				float minRange = -1.f;
				float maxRange = -1.f;

				// Get the jump drive ranges
				uint cnt = hulled.getSubSystemCount();
				for (uint i = 0; i < cnt; ++i) {
					subSystem@ sys = hulled.getSubSystem(i).system;
					if (sys.type.hasTag(strJumpDrive)) {
						float mn = sys.getVariable(strMinRange);
						float mx = sys.getVariable(strMaxRange);

						if (minRange < 0 || mn < minRange)
							minRange = mn;
						if (maxRange < 0 || mx > maxRange)
							maxRange = mx;
					}
				}

				bool inRange = dist > minRange && dist < maxRange;
				mo_text += combine("\n", localize("#MO_JumpRange"),
						inRange ? "#c:00dc00#" : "#c:dc0000#",
						combine(formatDistance(minRange), strAU, " - ",
							    formatDistance(maxRange), strAU),
						"#c#");
			}
		}
		const string@ strStargate = "Stargate", strRange = "vStargateRange";
		if (selected.getOwner() is emp && hull !is null && hull.getHull().hasSystemWithTag(strStargate)) {
			HulledObj@ hulled = selected;

			if (hulled !is null && hulled.getHull().hasSystemWithTag(strStargate)) {
				float maxRange = -1.f;

				// Get the jump drive ranges
				uint cnt = hulled.getSubSystemCount();
				for (uint i = 0; i < cnt; ++i) {
					subSystem@ sys = hulled.getSubSystem(i).system;
					if (sys.type.hasTag(strStargate)) {
						float mx = sys.getVariable(strRange);

						if (maxRange < 0 || mx > maxRange)
							maxRange = mx;
					}
				}

				bool inRange = dist < maxRange;
				mo_text += combine(localize("#MO_LinkRange"), inRange ? "#c:00dc00#" : "#c:dc0000#",formatDistance(maxRange), strAU,"#c#");
			}
		}		
	}
	
	// Jump drive charge status
	if (@hull != null && @hull.getHull() != null){
		uint count = hull.getSubSystemCount();
		float val = 0.f, max = 0.f;
		//float perc = 0.f, reload = 0.f;
		for (uint i = 0; i < count; ++i) {
			SysRef@ ref = hull.getSubSystem(i);
			if (ref.system.type.hasTag(strJumpDrive)) {
				hull.getProgress(ref, val, max);
				//if (max > 0.f) {
				//	perc = val / max;

				if (val > 0.001f)
					mo_text += combine("\n", "#c:dc0000#",
										localize("#MO_JumpTime"),
										f_to_s(val, 1) + "s",
										"#c#");
				else
					mo_text += combine("\n", "#c:00dc00#",
										localize("#MO_JumpReady"),
										"#c#");
									
				break;
			}
		}
	}
	
	//Superweapon Mouseovers
	if(owned) {
		if(hull !is null && hull.getHull() !is null) {
			if(hull.getHull().hasSystemWithTag("SpatialGen")) {
				uint count = hull.getSubSystemCount();
				float val = 0.f, max = 0.f, perc;				
				for (uint i = 0; i < count; ++i) {
					SysRef@ ref = hull.getSubSystem(i);
					if (ref.system.type.hasTag("SpatialGen")) {
						hull.getProgress(ref, val, max);
						if (max > 0.f)
							perc = 1.f - (val / max);

						if (perc > 0.001f)
							mo_text += combine("\n", "#c:00dc00#",
												localize("#MO_RSGCharge"),
												f_to_s(perc * 100.f, 1) + "%",
												"#c#");
						else
							mo_text += combine("\n", "#c:dc0000#",
												localize("#MO_RSGReady"),
												"#c#");
											
						break;
					}
				}
			}	
			if(hull.getHull().hasSystemWithTag("IonCannon")) {
				uint count = hull.getSubSystemCount();
				float val = 0.f, max = 0.f;
				//float perc = 0.f, reload = 0.f;
				for (uint i = 0; i < count; ++i) {
					SysRef@ ref = hull.getSubSystem(i);
					if (ref.system.type.hasTag("IonCannon")) {
						hull.getProgress(ref, val, max);
						//if (max > 0.f) {
						//	perc = val / max;

						if (val > 0.001f)
							mo_text += combine("\n", "#c:dc0000#",
												localize("#MO_RICTime"),
												f_to_s(val, 1) + "s",
												"#c#");
						else
							mo_text += combine("\n", "#c:00dc00#",
												localize("#MO_RICReady"),
												"#c#");
											
						break;
					}
				}			
			}
		}
	}
	
	if (owned) {
		// Fleet and Orders
		OrderList orders;
		if(orders.prepare(obj)) {
			uint ordCnt = orders.getOrderCount();
			if (hull !is null) {
				Fleet@ fl = hull.getFleet();
				if (fl !is null) {
					if (orders.isFleetCommander())
						mo_text += ("\n" + fl.getName()) + combine(" ",
								localize("#MO_Commander"), "\n  " +
								orders.getFleetSize(), " ",
								localize("#MO_Ships"));
					else
						mo_text += ("\n" + fl.getName());
				}
			}
			for (uint i = 0; i < ordCnt; ++i) {
				Order@ ord = orders.getOrder(i);
				if (!ord.isAutomation()) {
					mo_text += "\n" + orders.getOrder(i).getName();
					break;
				}
			}
		}
	}
	else {
		// Other owner
		HulledObj@ ship = obj;
		if(pl !is null || ship !is null) {
			if(owner !is null) {
				mo_text += "\n";
				mo_text += owner.getName();
				if(emp.isEnemy(owner))
					mo_text += " ("+localize("#MO_Enemy")+")";
				else if(emp.isAllied(owner))
					mo_text += " ("+localize("#MO_Allied")+")";
			}
		}
	}
	
	mouseOverlay.setText(combine("#font:stroked#", mo_text, "#font#"));
}

void hideNearOverlay() {
	if(glowLine.isVisible()) {
		glowLine.setVisible(false);
		nrov_name.setVisible(false);
		nrov_hpTag.setVisible(false);
		nrov_shieldTag.setVisible(false);
		nrov_shieldarmTag.setVisible(false);
		nrov_hpBar.setVisible(false);
		nrov_shieldBar.setVisible(false);
		nrov_shieldarmBar.setVisible(false);
		nrov_build.setVisible(false);
	}
}

void showNearOverlay() {
	if(!glowLine.isVisible()) {	//Show things that are always visible
		glowLine.setVisible(true);
		nrov_name.setVisible(true);
	}
}

bool rebuildPositions = false;

//Updates the state of the overlay that appears when close to an object
//Returns true if the overlay is visible, false otherwise
bool updateNearbyObject(Object@ obj) {
	recti apparentSize;
	if(getApparentPos(apparentSize)) {
		int width = apparentSize.getWidth();
		if(width > 128) {
			bool wasVisible = glowLine.isVisible();
			showNearOverlay();
			
			Empire@ emp = getActiveEmpire();
			
			float val = 0.f, max = 0.f, req = 0.f, cargo = 0.f;
			obj.getStateVals("Damage", val, max, req, cargo);
			pos2di topRight = apparentSize.UpperLeftCorner;
			if(!wasVisible || rebuildPositions ||
				(abs(lastTopRight.x - topRight.x) + abs(lastTopRight.y - topRight.y) > 2)) { //Make sure it's moved at least 3 pixels, to avoid twitching
				rebuildPositions = false;
				lastTopRight = topRight;
				topRight.x += width;
				
				dim2di lineSize = glowLine.getSize();
				pos2di glowTR = topRight + pos2di(lineSize.width / 2, -lineSize.height);
				
				glowLine.setPosition(topRight - pos2di(lineSize.width / 2, lineSize.height));
				nrov_name.setPosition(glowTR - pos2di(118, 15));
				
				uint barOffset = 15;
				
				if(!obj.hasState("Shields")) {
					nrov_shieldTag.setVisible(false); nrov_shieldBar.setVisible(false);
				}
				else {
					nrov_shieldTag.setVisible(true); nrov_shieldBar.setVisible(true);
					nrov_shieldTag.setPosition(glowTR + pos2di(-100, barOffset));
					nrov_shieldBar.setPosition(glowTR + pos2di(-50, barOffset + 5));
					barOffset += 15;
				}	

				if(!obj.hasState("ShieldArmor")) {
					nrov_shieldarmTag.setVisible(false); nrov_shieldarmBar.setVisible(false);
				}
				else {
					nrov_shieldarmTag.setVisible(true); nrov_shieldarmBar.setVisible(true);
					nrov_shieldarmTag.setPosition(glowTR + pos2di(-100, barOffset));
					nrov_shieldarmBar.setPosition(glowTR + pos2di(-50, barOffset + 5));
					barOffset += 15;
				}				
				
				if(!obj.hasState("Damage")) {
					nrov_hpTag.setVisible(false); nrov_hpBar.setVisible(false);
				}
				else {
					nrov_hpTag.setVisible(true); nrov_hpBar.setVisible(true);
					nrov_hpTag.setPosition(glowTR + pos2di(-100, barOffset));
					nrov_hpBar.setPosition(glowTR + pos2di(-50, barOffset + 5));
					barOffset += 15;
				}
				
				if(obj.getConstructionQueueSize() == 0 || @obj.getOwner() != @emp) {
					nrov_build.setVisible(false);
					nrov_build.setText(null);
				}
				else {
					nrov_build.setVisible(true);
					nrov_build.setPosition(glowTR + pos2di(-200, barOffset));
					barOffset += 15;
				}
			}
			
			nrov_name.setText("#align:right#" + obj.getName());
			
			float hp = 0.f, dmg = 0.f, shieldHP = 0.f, shieldDMG = 0.f, shieldArmorHP = 0.f, shieldArmorDMG = 0.f;
			float max2 = 0.f;
			
			obj.getStateVals("Damage", dmg, hp, req, cargo);
			obj.getStateVals("Shields", shieldDMG, shieldHP, req, cargo);
			obj.getStateVals("ShieldArmor", shieldArmorDMG, shieldArmorHP, req, cargo);
			
			if(shieldHP > 0) {
				nrov_shieldBar.setPct((shieldDMG / shieldHP));
				nrov_shieldBar.setToolTip(standardize(shieldDMG) + "/" + standardize(shieldHP));
			}
			
			if(shieldArmorHP > 0) {
				nrov_shieldBar.setPct((shieldArmorDMG / shieldArmorHP));
				nrov_shieldBar.setToolTip(standardize(shieldArmorDMG) + "/" + standardize(shieldArmorHP));
			}
			
			if(hp > 0) {
				nrov_hpBar.setPct(1.f - (dmg / hp));
				nrov_hpBar.setToolTip(standardize(hp - dmg) + "/" + standardize(hp));
			}
			
			uint qSize = obj.getConstructionQueueSize();
			if(qSize == 0) {
				if(nrov_build.isVisible())
					rebuildPositions = true;
			}
			else if(nrov_build.isVisible()) {
				string@ buildName = obj.getConstructionName();
				float buildPct = obj.getConstructionProgress();
				if(@buildName != null) {
					string@ outText = "";
					fitStrToPixels(buildName, 180, outText, null, ": (" + round(buildPct * 100.f) + "%)");
					nrov_build.setText("#align:right##img:obj_building_yes# " + outText);
				}
			}
			else {
				rebuildPositions = true;
			}
		}
		else {
			hideNearOverlay();
		}
	}
	else {
		hideNearOverlay();
	}
	return glowLine.isVisible();
}

void OnMouseOverContext(Object@ obj, pos2di mousePos) {
	// Can't hover while the context menu is up
	if (isContextMenuUp())
		@obj = null;

	GuiElement@ mo_ele = mouseOverlay;
	
	Object@ focus = getCameraFocus();
	
	if (obj is null || !obj.isValid() || (focus is obj && updateNearbyObject(focus))) {
		@curObject = null;
		if(focus is null)
			hideNearOverlay();
		mo_ele.setVisible(false);
	}
	else {		
		mo_ele.setVisible(true);
		mo_ele.bringToFront();
		
		setMouseOverlayText(obj);
		anchorToMouse(mo_ele);
	}
}

int ei_left_margin = 2, ei_margin = 4, ei_top_margin = 2;

int get_ei_top() {
	return ei_top_margin + empMsgBG.getSize().height;
}

GuiElement@ findIndicator(int ID) {
	return getElementByID(ID, empMsgBG);
}

GuiElement@[] eventIndicators;

void showEventIndicator(GuiElement@ ele) {
	ele.setParent(empMsgBG);
	ele.setNoclipped(true);
	
	int left = ei_left_margin, top = ei_top;
	uint ei_count = eventIndicators.length();
	for(uint i = 0; i < ei_count; ++i)
		left += eventIndicators[i].getSize().width + ei_margin;
	
	ele.setPosition( pos2di(left, top) );
	ele.setAlignment(EA_Left, EA_Bottom, EA_Left, EA_Bottom);
	
	eventIndicators.resize(ei_count + 1);
	@eventIndicators[ei_count] = @ele;
}

void hideEventIndicator(GuiElement@ ele) {
	int left = ei_left_margin, top = ei_top;
	uint ei_count = eventIndicators.length();
	
	uint i;
	for(i = 0; i < ei_count; ++i) {
		if(eventIndicators[i] is ele) {
			ele.remove();
			eventIndicators.erase(i);
			ei_count -= 1;
			break;
		}
		left += eventIndicators[i].getSize().width + ei_margin;
	}
	
	for(;i < ei_count; ++i) {
		eventIndicators[i].setPosition( pos2di(left, top) );
		left += eventIndicators[i].getSize().width + ei_margin;
	}
}

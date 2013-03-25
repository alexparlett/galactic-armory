//advisor_win.as
//=================
//A window which displays an Advisor warnings and suggestions
#include "~/Game Data/gui/include/gui_sprite.as"
#include "~/Game Data/gui/include/gui_skin.as"
#include "~/Game Data/gui/include/dialog.as"
#include "/include/advisor_drag.as"
#include "/include/advisor_const.as"
#include "/include/advisor_classes.as"
#include "/include/advisor_gui.as"
#include "/include/advisor_weights.as"
#include "/include/advisor_panels.as"

//IMPORTS
import recti makeScreenCenteredRect(const dim2di &in rectSize) from "gui_lib";
import void anchorToMouse(GuiElement@) from "gui_lib";
import int getPlanetIconIndex(string@ physicalType) from "planet_icons";
import void triggerPlanetWin(Planet@ pl, bool bringToFront) from "planet_win";
import string@ getPlanetContext(Object@ obj) from "advisor_context";
import void triggerContextMenu(Object@) from "context_menu";

// GLOBALS

const bool AUTO_MINIMIZE = true;
const int SHOW_WEIGHT = 20;

const int MIN_WIDTH = 324;
const int MIN_HEIGHT = 127;
const int MAX_WIDTH = 324;
const int MAX_HEIGHT = 500;

const int INFOPANEL_WIDTH = 200;
const int INFOPANEL_HEIGHT = 40;

const float UPDATE_INTERVAL = 0.25f;
const float SYS_UPDATE_INTERVAL = 4.f;

AdvisorWindowHandle@ win;
dim2di defaultSize;

void init() {
	// Initialize some constants
	initSkin();

	defaultSize = dim2di(MAX_WIDTH, 350);

	// Bind toggle key
	bindFuncToKey("F8", "script:ToggleAdvisorWindow_key");
}

void createAdvisorWindow() {
	@win = AdvisorWindowHandle(makeScreenCenteredRect(defaultSize));
	win.bringToFront();
}

void closeAdvisorWindow() {
	win.remove();
	@win = null;
	setGuiFocus(null);
}

void showAdvisorWindow() {
	if (@win == null)
		createAdvisorWindow();
	else
	{
		win.setVisible(true);
		win.bringToFront();
	}
}

void hideAdvisorWindow() {
	win.setVisible(false);
	setGuiFocus(null);
}

GuiElement@ getAdvisorWindow() {
	return win.ele;
}

void toggleAdvisorWindow() {
	if (@win == null || !win.isVisible())
		showAdvisorWindow();
	else
		hideAdvisorWindow();
}

bool ToggleAdvisorWindow(const GUIEvent@ evt) {
	if (evt.EventType == GEVT_Clicked) {
		toggleAdvisorWindow();
		return true;
	}
	return false;
}

bool ToggleAdvisorWindow_key(uint8 flags) {
	if (flags & KF_Pressed != 0) {
		toggleAdvisorWindow();
		return true;
	}
	return false;
}

void tick(float time) {
	if (@win != null)
		win.update(time);
}

/* {{{ Advisor Window Handle */
class AdvisorWindowHandle {
	AdvisorWindow@ script;
	GuiScripted@ ele;

	AdvisorWindowHandle(recti Position) {
		@script = AdvisorWindow();
		@ele = GuiScripted(Position, script, null);

		script.init(ele);
		script.syncPosition(Position.getSize());
	}

	void bringToFront() {
		ele.bringToFront();
		setGuiFocus(ele);
	}

	void setVisible(bool vis) {
		ele.setVisible(vis);
	}

	bool isVisible() {
		return ele.isVisible();
	}

	void update(float time) {
		script.update(time);
		script.position = ele.getPosition();
	}

	void remove() {
		ele.remove();
		script.remove();
		@script = null;
		@ele = null;
	}
};
/* }}} */

/* {{{ Advisor Window Script */
class AdvisorWindow : ScriptedGuiHandler {
	DragResizeInfo drag;
	pos2di position;
	bool removed;

	GuiPanel@ topLeftPanel;
	GuiPanel@ topRightPanel;
	GuiPanel@ bottomPanel;
	GuiPanel@ contextPanel;
	GuiStaticText@ test;

	GuiButton@ close;
	GuiButton@ img;
	GuiImage@ zoom;
	GuiStaticText@ name;
	GuiStaticText@ count;
	GuiExtText@ order;
	GuiExtText@ context;

	System@[] systemList;
	planetItem@[] planetList;

	int planetEntryId;
	planetEntry@[] planetEntries;

	Planet@ planet;
	Planet@ selectedPlanet;

	Object@ contextObj;

	check@[] checks;
	check@ chck;
	check@ selectedCheck;

	infoPanel@ info;

	int elemID;
	int updateElemID;
	int fullUpdateElemID;
	int selectedEntry;

	float nextSysUpdate;
	float nextUpdate;

	bool userMinimized;

	AdvisorWindow() {
		removed = false;
		userMinimized = false;
		selectedEntry = -1;
		nextSysUpdate = 0.f;
		nextUpdate = 0.f;
		elemID = reserveGuiID();
		updateElemID = reserveGuiID();
		fullUpdateElemID = reserveGuiID();
		planetEntryId = reserveGuiID();

		checks.resize(2);
		@checks[0] = econCheck();
		@checks[1] = structureCheck(); //not completed for release

		//checks.resize(1);
		//@checks[0] = econCheck();
	}

	void remove() {
		removed = true;
	}

	void selectEntry(int num) {
		if (selectedEntry != -1 && selectedEntry < int(planetEntries.length()))
			planetEntries[selectedEntry].selected = false;
		selectedEntry = num;
		@selectedPlanet = planetEntries[selectedEntry].pl;
		@selectedCheck = planetEntries[selectedEntry].ch;
		setPlanet(selectedPlanet);
		setCheck(selectedCheck);
	}

	void unselectEntry() {
		if (selectedEntry != -1 && selectedEntry < int(planetEntries.length()))
			planetEntries[selectedEntry].selected = false;
		selectedEntry = -1;
		if (planetEntries.length() > 0) {
			@selectedPlanet = null;
			@selectedCheck = null;
			setPlanet(planetEntries[0].pl);
			setCheck(planetEntries[0].ch);
		}
		else {
			@selectedPlanet = null;
			@planet = null;
		}
	}

	void setPlanet(Planet@ pl) {
		@planet = pl;

		if (pl !is null) {
			int ind = getPlanetIconIndex(pl.getPhysicalType());
			img.setSprites("planet_icons_new", ind, ind, ind);
		}
	}

	void setCheck(check@ ch) {
		@chck = ch;

		if (planet !is null && chck !is null) {
			info.remove();
			@info = chck.createInfoPanel(planet, pos2di(), topRightPanel);
			info.setPosition(pos2di(2,100-42));
			info.setSize();
		}
	}

	void showContext(Object@ obj) {
		@contextObj = obj;
		contextPanel.setVisible(true);
		contextPanel.bringToFront();
	}

	void hideContext() {
		@contextObj = null;
		contextPanel.setVisible(false);
	}

	void init(GuiElement@ ele) {
		// Close button
		@close = CloseButton(recti(), ele);

		/* TopLeft Panel */
		@topLeftPanel = GuiPanel(recti(), false, SBM_Invisible, SBM_Invisible, ele);

		// Planet image
		@img = GuiButton(recti(), null, topLeftPanel);
		img.setAppearance(BA_ScaleImage,BA_Background);
		img.setID(elemID);

		// Zoom button
		@zoom = GuiImage(pos2di(), "clause_edit", topLeftPanel);
		zoom.setClickThrough(false);
		zoom.setScaleImage(true);
		zoom.setColor(transparent);
		zoom.setID(elemID);

		/* TopRight Panel */
		@topRightPanel = GuiPanel(recti(), false, SBM_Invisible, SBM_Invisible, ele);

		// Planet name
		@name = GuiStaticText(recti(), null, false, false, false, topRightPanel);
		name.setFont("stroked");

		// Count
		@count = GuiStaticText(recti(), null, false, false, false, topRightPanel);
		count.setFont("stroked");
		count.setTextAlignment(EA_Right, EA_Bottom);

		// Planet orders
		@order = GuiExtText(recti(), topRightPanel);		

		// Info
		@info = emptyPanel(planet, pos2di(), topRightPanel);

		/* Bottom Panel */
		@bottomPanel = GuiPanel(recti(), false, SBM_Auto, SBM_Invisible, ele);

		/* Context Panel */
		@contextPanel = GuiPanel(recti(), true, SBM_Invisible, SBM_Invisible, null);
		contextPanel.setNoclipped(true);
		contextPanel.setVisible(false);
		contextPanel.setOverrideColor(Color(0xff000000));

		@context = GuiExtText(recti(), contextPanel);

		syncPosition(ele.getSize());
		doUpdate();
	}

	void syncPosition(dim2di size) {
		// Close button
		close.setPosition(pos2di(size.width - 30, 0));
		close.setSize(dim2di(30, 12));

		// TopLeft panel
		topLeftPanel.setPosition(pos2di(7, 20));
		topLeftPanel.setSize(dim2di(100, 100));

		// Planet image
		img.setPosition(pos2di(10, 10));
		img.setSize(dim2di(80, 80));

		// Zoom button
		zoom.setPosition(pos2di(8, 8));
		zoom.setSize(dim2di(16, 16));

		// TopRight panel
		topRightPanel.setPosition(pos2di(7 + 106, 20));
		topRightPanel.setSize(dim2di(size.width-120, 100));

		// Planet name
		recti rName = r(2, 2, topRightPanel.getSize().width-4-60, 15);
		name.setPosition(ul(rName));
		name.setSize(rName.getSize());

		// Count
		recti rCount = r(topRightPanel.getSize().width-4-60, 2, 60, 15);
		count.setPosition(ul(rCount));
		count.setSize(rCount.getSize());

		// Planet orders
		recti rOrder = r(2, 20, topRightPanel.getSize().width-4, 15);
		order.setPosition(ul(rOrder));
		order.setSize(rOrder.getSize());

		// Info
		info.setPosition(pos2di(2,100-42));
		info.setSize();

		// Bottom Panel
		if (size.height >= 160)
		{
			bottomPanel.setVisible(true);
			bottomPanel.setPosition(pos2di(7, 126));
			bottomPanel.setSize(dim2di(size.width-14, size.height-133));
		}
		else
			bottomPanel.setVisible(false);
	}

	void draw(GuiElement@ ele) {
		ele.toGuiScripted().setAbsoluteClip();
		const recti absPos = ele.getAbsolutePosition();
		pos2di topLeft = absPos.UpperLeftCorner;
		pos2di botRight = absPos.LowerRightCorner;
		dim2di size = absPos.getSize();

		drawWindowFrame(absPos);

		/* TopLeft panel */
		recti rTL = r(topLeft.x+7, topLeft.y+20, 100, 100);
		drawLightArea(rTL);
		drawVSep(r(ur(rTL, -1, 0), 7, 100));

		/* TopRight panel */
		recti rTR = r(ur(rTL, 6, 0), width(botRight, ur(rTL, 6, 0))-7, 100);
		drawDarkArea(rTR);

		/* Bottom panel */
		if (size.height > MIN_HEIGHT)
			drawHSep(r(ll(rTL, 0, -1), width(botRight, ll(rTL))-7, 7));
		if (size.height > (MIN_HEIGHT + 6))
		{
			recti rB = r(ll(rTL, 0, 6), width(botRight, ul(rTL))-7, height(botRight, lr(rTL, 0, 6))-7);
			drawDarkArea(rB);
		}

		drawResizeHandle(recti(botRight - pos2di(19, 19), botRight));

		clearDrawClip();
	}

	void update(float time) {
		// Update systems, this is done less often because
		// there are so many systems it's awfully slow.
		if (nextSysUpdate <= 0.f) {
			updateSystemList();
			updatePlanetList();
			nextSysUpdate = SYS_UPDATE_INTERVAL;
		}
		else 
			nextSysUpdate -= time;

		// Update others
		if (nextUpdate <= 0.f) {
			doUpdate();

			nextUpdate = UPDATE_INTERVAL;
		}
		else nextUpdate -= time;
	}

	void doUpdate() {
		updatePlanet();
		updatePlanets();
		updateContext();

		// Calibrate all panel sizes
		topLeftPanel.fitChildren();
		topRightPanel.fitChildren();
		bottomPanel.fitChildren();
	}

	void updateSystemList() {
		Empire@ emp = getActiveEmpire();
		uint systems = getSystemCount();
		systemList.resize(0);
		for (uint i = 0; i < systems; ++i) 
		{
			System@ sys = getSystem(i);
			if (sys.isVisibleTo(emp)) 
			{
				systemList.resize(systemList.length()+1);
				@(systemList[systemList.length()-1]) = sys;
			}
		}
	}

	void updatePlanetList() {
		planetItem@[] newPlanetList;
		for (uint i = 0; i < systemList.length(); ++i) 
		{
			System@ sys = systemList[i];

			SysObjList objects;
			objects.prepare(sys);
			for (uint i = 0; i < objects.childCount; ++i) 
			{
				Object@ obj = objects.getChild(i);
				Planet@ pl = obj.toPlanet();

				if (@pl != null)
				{
					const Empire@ emp = obj.getOwner();
					bool owned = emp is getActiveEmpire();

					if (owned) {
						for (uint c = 0; c < checks.length(); c++)
						{
							check@ ch = checks[c];
							int weight = ch.calcWeight(pl);
							if (weight >= SHOW_WEIGHT) {
								newPlanetList.resize(newPlanetList.length()+1);
								@(newPlanetList[newPlanetList.length()-1]) = planetItem(pl, ch, weight);
							}
						}
					}
				}
			}
		}
		newPlanetList.sort(false);

		// comparing new and old planet lists, if they are same, skipping updatePlanetEntries()
		bool difference = true;
		if (planetList.length() == newPlanetList.length()) {
			difference = false;
			for (uint i = 0; i < planetList.length(); i++) {
				Planet@ pl1 = planetList[i].pl;
				Planet@ pl2 = newPlanetList[i].pl;
				if (@pl1 != @pl2) {
					difference = true;
					break;
				}
			}
		}
		if (difference) {
			planetList.resize(newPlanetList.length());
			for (uint i = 0; i < planetList.length(); i++)
				@(planetList[i]) = @(newPlanetList[i]);
			updatePlanetEntries();
		}
	}

	void updatePlanetEntries() {
		pos2di prevPos = bottomPanel.getScrollPos();
		int prevLength = planetEntries.length();
		for (uint i = 0; i < planetEntries.length(); i++)
			planetEntries[i].remove();
		planetEntries.resize(0);
		bool found = false;
		for (uint i = 0; i < planetList.length(); ++i) 
		{
			Planet@ pl = planetList[i].pl;
			planetEntries.resize(planetEntries.length()+1);
			@(planetEntries[planetEntries.length()-1]) = planetEntry(planetEntries.length()-1, pl, planetList[i].ch, this, bottomPanel);
			if (@selectedPlanet == @pl && @selectedCheck == @(planetList[i].ch)) {
				planetEntries[planetEntries.length()-1].selected = true;
				found = true;
			}
		}
		if (!found)
			unselectEntry();

		bottomPanel.setScrollPos( prevPos );
		if (AUTO_MINIMIZE) {
			if (prevLength > 0 && planetEntries.length() == 0)
				minimize();
			else if (prevLength == 0 && planetEntries.length() > 0 && !userMinimized)
				restore();
		}
	}

	void updatePlanets() {
		for (uint i = 0; i < planetEntries.length(); ++i) 
		{
			planetEntries[i].update();
		}
	}

	void updatePlanet() {
		if (@planet == null) {
			topLeftPanel.setVisible(false);
			topRightPanel.setVisible(false);
			return;
		}
		Object@ obj = planet.toObject();
		if ( obj.getOwner() !is getActiveEmpire() )
		{
			@planet = null;
			topLeftPanel.setVisible(false);
			topRightPanel.setVisible(false);
			return;
		}
		topLeftPanel.setVisible(true);
		topRightPanel.setVisible(true);

		// Planet name
		name.setText(obj.getName());

		// Count
		int n = (selectedEntry != -1) ? selectedEntry : 0;
		count.setText(i_to_s(n+1) + " of " + i_to_s(planetEntries.length()));

		// Planet orders
		if(obj.getConstructionQueueSize() > 0) {
			float pct = obj.getConstructionProgress();
			order.setText("#img:obj_building_yes# "+obj.getConstructionName(0)+": " + f_to_s(pct * 100.f, 0) + "%");
		}
		else
			order.setText(localize("#SY_Idle"));

		// Info
		info.setPlanet(planet);
		info.update();
	}

	void updateContext() {
		if (contextPanel.isVisible()) {
			//contextPanel.setSize(dim2di(500, 500));
			context.setPosition(pos2di(3,2));
			context.setSize(dim2di(300, 500));
			context.setText(getPlanetContext(contextObj));
			contextPanel.setSize(dim2di(context.getSize().width, context.getSize().height+2));
		}
	}

	void minimize() {
		// using maximized for minimizing
		if (!drag.maximized) {
			GuiElement@ ele = getAdvisorWindow();
			drag.origPos = recti(ele.getPosition(), ele.getSize());
			ele.setSize(dim2di(MIN_WIDTH, MIN_HEIGHT));
			drag.maximized = true;
			syncPosition(ele.getSize());
		}
	}

	void restore() {
		// using maximized for minimizing
		if (drag.maximized) {
			GuiElement@ ele = getAdvisorWindow();
			drag.maximized = false;
			ele.setSize(drag.origPos.getSize());
			syncPosition(ele.getSize());
		}
	}

	EventReturn onKeyEvent(GuiElement@ ele, const KeyEvent& evt) {
		return ER_Pass;
	}

	EventReturn onMouseEvent(GuiElement@ ele, const MouseEvent& evt) {
		DragResizeEvent re = handleDragResize2(ele, evt, drag, MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT);
		if (re != RE_None) {
			if (re == RE_Resized) {
				syncPosition(ele.getSize());
				if (evt.EventType == MET_DBL_CLICK && drag.maximized == true) // minimize or maximize && i am using maximized flag for minimized info, so this really means user MINIMIZED window
					userMinimized = true; // using this for keeping window minimized until user changes his mind (even with AUTO_MINIMIZE feature)
				else
					userMinimized = false;
			}
			return ER_Absorb;
		}
		else {
			switch (evt.EventType) {
				case MET_MOVED:
					anchorToMouse(contextPanel);
					return ER_Absorb;
			}
		}
		return ER_Pass;
	}

	EventReturn onGUIEvent(GuiElement@ ele, const GUIEvent& evt) {
		if (evt.EventType == GEVT_Closed) {
			hideAdvisorWindow();
			return ER_Absorb;
		}		
		else
		{
			switch (evt.EventType) // Handle events from the window elements themselves
			{ 
				case GEVT_Clicked:
					if (evt.Caller is close) {
						hideAdvisorWindow();
						return ER_Pass;
					}
					else if (evt.Caller is img) 
					{
						if (ctrlKey) {
							setCameraFocus(planet.toObject());
							setGuiFocus(null);
						}
						else {
							Object@ obj = planet.toObject();
							if (isSelected(obj))
								triggerPlanetWin(planet, true);
							else
								selectObject(obj);
						}
						return ER_Absorb;
					}
				break;
				case GEVT_Right_Clicked:
					if(evt.Caller is img) {
						Object@ obj = planet.toObject();
						triggerContextMenu(obj);
						return ER_Absorb;
					}
				break;
				case GEVT_Focus_Gained:
					if (evt.Caller is zoom) {
						setCameraFocus(planet.toObject().getParent());
						setGuiFocus(null);
						return ER_Absorb;
					}
				break;
				case GEVT_Mouse_Over:
					if (evt.Caller is zoom) {
						zoom.setColor(opaque);
						return ER_Absorb;
					}
					else if (evt.Caller is img) {
						showContext(planet.toObject());
						return ER_Absorb;
					}
				break;
				case GEVT_Mouse_Left:
					if (evt.Caller is zoom) {
						zoom.setColor(transparent);
						return ER_Absorb;
					}
					else if (evt.Caller is img) {
						hideContext();
						return ER_Absorb;
					}
				break;
			}
		}

		return ER_Pass;
	}
};
/* }}} */

/* {{{ Planet Entry Script */
class planetEntry : ScriptedGuiHandler {
	int num;
	bool selected;

	GuiScripted@ scripted;
	AdvisorWindow@ win;
	GuiButton@ img;
	GuiImage@ zoom;
	GuiStaticText@ name;
	GuiExtText@ order;

	infoPanel@ info;

	Planet@ pl;
	check@ ch;

	planetEntry(int num, Planet@ pl, check@ ch, AdvisorWindow@ win, GuiElement@ parent)
	{
		selected = false;
		this.num = num;
		@this.win = win;
		@this.pl = pl;
		@this.ch = ch;

		recti rE = r(2,2+42*num,MIN_WIDTH-35,40);
		@scripted = GuiScripted(rE, this, parent);

		// Planet name
		recti rName = r(2, 1, 70, 15);
		@name = GuiStaticText(rName, null, false, false, false, scripted);
		name.setText(pl.toObject().getName());
		name.setTextAlignment(EA_Left, EA_Bottom);

		// Planet image
		recti rImg = r(2, 17, 20, 20);
		@img = GuiButton(rImg, null, scripted);
		img.setID(win.planetEntryId);
		img.setAppearance(BA_ScaleImage,BA_Background);
		if (pl !is null) {
			int ind = getPlanetIconIndex(pl.getPhysicalType());
			img.setSprites("planet_icons", ind, ind, ind);
		}

		// Zoom button
		@zoom = GuiImage(pos2di(1, 15), "clause_edit", scripted);
		zoom.setClickThrough(false);
		zoom.setScaleImage(true);
		zoom.setSize(dim2di(11, 11));
		zoom.setColor(transparent);

		// Planet order
		recti rOrder(25, 20, 80, 15);
		@order = GuiExtText(rOrder, scripted);

		// Info
		@info = ch.createInfoPanel(pl, pos2di(85,0), scripted);

		update();
	}

	void draw(GuiElement@ ele) {
		ele.toGuiScripted().setAbsoluteClip();
		const recti absPos = ele.getAbsolutePosition();
		pos2di topLeft = absPos.UpperLeftCorner;
		pos2di botRight = absPos.LowerRightCorner;
		dim2di size = absPos.getSize();

		Color col;
		if (selected)
			col = cSelected;
		else
			col = num % 2 == 0 ? cEven : cOdd;

		drawRect(absPos, col);

		clearDrawClip();
	}

	void update() {
		if (@pl == null) 
			return;
		Object@ obj = pl.toObject();

		// Planet orders
		if(obj.getConstructionQueueSize() > 0) {
			float pct = obj.getConstructionProgress();
			order.setText("#img:obj_building_yes# " + f_to_s(pct * 100.f, 0) + "%");
			order.setToolTip(obj.getConstructionName(0));
		}
		else {		
			order.setText(null);
			order.setToolTip(null);
		}

		info.update();
	}

	void remove() {
		info.remove();
		scripted.orphan(true);
		scripted.remove();
		@win = null;
		@pl = null;
	}

	EventReturn onGUIEvent(GuiElement@ ele, const GUIEvent& evt) {
		switch (evt.EventType) // Handle events from the window elements themselves
		{ 
			case GEVT_Clicked:
				if (evt.Caller is img) 
				{
					if (ctrlKey) {
						setCameraFocus(pl.toObject());
						setGuiFocus(null);
					}
					else {
						Object@ obj = pl.toObject();
						if (isSelected(obj))
							triggerPlanetWin(pl, true);
						else
							selectObject(obj);
					}
					return ER_Absorb;
				}
			break;
			case GEVT_Right_Clicked:
				if(evt.Caller is img) {
					Object@ obj = pl.toObject();
					triggerContextMenu(obj);
					return ER_Absorb;
				}
			break;
			case GEVT_Focus_Gained:
				if (evt.Caller is zoom) {
					setCameraFocus(pl.toObject().getParent());
					setGuiFocus(null);
					return ER_Absorb;
				}
			break;
			case GEVT_Mouse_Over:
				if (evt.Caller is zoom) {
					zoom.setColor(opaque);
					return ER_Absorb;
				}
				else if (evt.Caller is img) {
					win.showContext(pl.toObject());
					return ER_Absorb;
				}
			break;
			case GEVT_Mouse_Left:
				if (evt.Caller is zoom) {
					zoom.setColor(transparent);
					return ER_Absorb;
				}
				else if (evt.Caller is img) {
					win.hideContext();
					return ER_Absorb;
				}
			break;
		}

		return ER_Pass;
	}

	EventReturn onMouseEvent(GuiElement@ ele, const MouseEvent& evt) {
		switch (evt.EventType) {
			case MET_LEFT_DOWN: {
				recti re = zoom.getAbsolutePosition();
				if (!re.isPointInside(pos2di(evt.x, evt.y)))
				{
					if (!selected)
					{
						selected = true;
						win.selectEntry(num);
					}
					else
					{
						selected = false;
						win.unselectEntry();
					}
				}
				return ER_Absorb;
			}
		}
		return ER_Pass;
	}

	EventReturn onKeyEvent(GuiElement@ ele, const KeyEvent& evt) {
		return ER_Pass;
	}
}
/* }}} */
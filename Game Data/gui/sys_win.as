#include "~/Game Data/gui/include/gui_skin.as"
#include "~/Game Data/gui/include/str_indicator.as"
#include "~/Game Data/gui/include/gui_sprite.as"
#include "~/Game Data/gui/include/cqueue_saveload.as"
#include "~/Game Data/gui/include/dialog.as"
#include "~/Game Data/gui/include/blueprints_sort.as"

import recti makeScreenCenteredRect(const dim2di &in rectSize) from "gui_lib";
import void triggerPlanetWin(Planet@ pl, bool bringToFront) from "planet_win";
import void triggerQueueWin(Object@ pl) from "queue_win";
import float getObjectWeight(Object@ pl) from "build_on_best";
import int getPlanetIconIndex(string@ physicalType) from "planet_icons";
import void triggerContextMenu(Object@) from "context_menu";

/* {{{ System Window Handle */
class SystemWindowHandle {
	SystemWindow@ script;
	GuiScripted@ ele;

	SystemWindowHandle(recti Position) {
		@script = SystemWindow();
		@ele = GuiScripted(Position, script, null);

		script.init(ele);
		script.syncPosition(Position.getSize());
	}

	void setCurSystem(System@ sys) {
		script.addSystem(sys, false, false);
	}

	System@ getCurSystem() {
		return script.curSys;
	}

	void findSystem() {
		set_int systems;
		script.addedPlanets.clear();
		bool foundSys = false;

		// Find the system of the camera focus
		Object@ selected = getCameraFocus();
		if (selected !is null) {
			System@ sys = selected.getCurrentSystem();
			if(sys !is null && sys !is getGalaxy().toObject().toSystem()) {
				uint id = sys.toObject().uid;
				if (!systems.exists(id)) {
					script.addSystem(sys, true, false);
					systems.insert(id);

					if (!foundSys)
						@script.curSys = sys;
					else
						@script.curSys = null;
					foundSys = true;
				}
			}
		}

		// Add all the systems we have selected objects in
		uint cnt = getSelectedObjectCount();
		for (uint i = 0; i < cnt; ++i) {
			Object@ selected = getSelectedObject(i);
			if (selected !is null) {
				System@ sys = selected.getCurrentSystem();
				if(sys !is null && sys !is getGalaxy().toObject().toSystem()) {
					uint id = sys.toObject().uid;
					if (!systems.exists(id)) {
						script.addSystem(sys, true, false);
						systems.insert(id);

						if (!foundSys)
							@script.curSys = sys;
						else
							@script.curSys = null;
						foundSys = true;
					}
				}
			}
		}

		if (!foundSys) {
			// If all else fails, find the first visible system
			Empire@ emp = getActiveEmpire();
			uint systems = getSystemCount();
			for (uint i = 0; i < systems; ++i) {
				System@ sys = getSystem(i);
				if (sys.isVisibleTo(emp)) {
					script.addSystem(sys, true, false);
					@script.curSys = sys;
					break;
				}
			}
		}

		if (script.curSys !is null)
			script.sysName.setText("#a:center##font:goodtimes_14##c:0d0#"+script.curSys.toObject().getName()+"#c##font##a#");
		else
			script.sysName.setText("#a:center##font:goodtimes_14##c:0d0#"+localize("#EM_Planets")+"#c##font##a#");
	}

	bool isPinned() {
		return script.isPinned();
	}

	void setPinned(bool pin) {
		script.setPinned(pin);
	}

	void bringToFront() {
		ele.bringToFront();
		setGuiFocus(ele);
		bindEscapeEvent(ele);
	}

	void setVisible(bool vis) {
		ele.setVisible(vis);

		if (vis)
			bindEscapeEvent(ele);
		else
			clearEscapeEvent(ele);
	}

	bool isVisible() {
		return ele.isVisible();
	}

	void update(float time) {
		script.update(time);
		script.position = ele.getPosition();
	}

	void remove() {
		clearEscapeEvent(ele);
		ele.remove();
		script.remove();
		@script = null;
		@ele = null;
	}
};

/* }}} */
/* {{{ System Window Script */
int MIN_WIDTH = 484;
int MIN_HEIGHT = 201;

set_int[] groups;
string@[] groupNames;
uint groupNum = 2;

uint plEntryBaseHeight = 54;
uint plEntryBareHeight = 29;
uint plEntrySpacing = 0;
uint plEntryWidth = 448;

uint sysEntryHeight = 26;
uint sysEntrySpacing = 0;

float updateInterval = 0.25f;
float sysUpdateInterval = 4.f;

const string strBuildsShips = "BuildsShips";

enum EventHandleState {
	EHS_Unhandled,
	EHS_Handled,
	EHS_Absorb
};

class SystemMultiBuild : EntryDialogCallback {
	SystemWindow@ win;

	SystemMultiBuild(SystemWindow@ window) {
		@win = window;
	}

	void call(EntryDialog@ dialog, string@ amount) {
		if (win is null || win.removed)
			return;

		uint count = uint(s_to_i(amount));
		win.doBuild(count);
	}
};

class SystemLoadQueue : SingleImportDialogCallback {
	Object@ obj;
	SystemWindow@ win;

	SystemLoadQueue(SystemWindow@ window, Object@ forObj) {
		@win = window;
		@obj = forObj;
	}

	void call(SingleImportDialog@ dialog, string@ text) {
		if (win is null || win.removed)
			return;

		if (obj !is null) {
			// Load for one object
			loadQueue(obj, text);
		}
		else {
			// Load for all selected
			for (uint i = 0; i < win.planetEntries.length(); ++i) {
				Object@ pl = win.planetEntries[i].obj;

				if (pl !is null && pl.getOwner() is getActiveEmpire())
					loadQueue(pl, text);
			}
		}
	}
};

class SystemWindow : ScriptedGuiHandler {
	DragResizeInfo drag;
	pos2di position;
	bool removed;

	sysEntry@[] sysEntries;
	groupEntry@[] groupEntries;
	planetEntry@[] planetEntries;
	set_int addedPlanets;

	GuiPanel@ leftPanel;
	GuiPanel@ centerPanel;
	GuiPanel@ rightPanel;

	GuiPanel@ sysPanel;
	GuiPanel@ grpPanel;
	GuiPanel@ plPanel;

	GuiButton@ close;
	GuiImage@ pinImg;

	GuiExtText@ sysName;
	GuiComboBox@ planetFilter;
	GuiComboBox@ governorFilter;
	GuiComboBox@ orderFilter;
	GuiComboBox@ sysFilter;

	GuiButton@ systemsTab;
	GuiButton@ groupsTab;
	GuiButton@ selectAll;
	GuiButton@ selectNone;
	GuiButton@ createGroupButton;
	GuiEditBox@ groupName;
	GuiButton@ restore_window;
	GuiButton@ showQueue;
	GuiButton@ showResources;
	GuiButton@ showPlanetRes;
	GuiButton@ showLogisticsRes;

	GuiExtText@ globalText;
	GuiComboBox@ buildType;
	GuiListBox@ buildList;
	GuiComboBox@ shipSort;
	GuiExtText@ actText;
	GuiExtText@ selectAllGovsText;
	GuiComboBox@ selectAllGovsBox;
	GuiButton@ selectAllGovsButton;
	GuiButton@ renovateAll;
	GuiButton@ loadQueueAll;
	GuiButton@ clearQueueAll;

	GuiComboBox@ sortType;

	int prevColumns;
	bool pinned;

	int sysPanelID;
	int grpPanelID;
	int plPanelID;

	int updateElemID;
	int fullUpdateElemID;
	int sysUpdateElemID;

	float nextSysUpdate;
	float nextUpdate;

	int empireBuildListCount;
	SortedBlueprintList@ blueprints;

	float syncTimer;
	int syncNum;

	System@ curSys;

	SystemWindow() {
		removed = false;
		pinned = false;
		empireBuildListCount = 0;
		nextSysUpdate = 0.f;
		nextUpdate = 0.f;
		prevColumns = 1;
		sysPanelID = reserveGuiID();
		grpPanelID = reserveGuiID();
		plPanelID = reserveGuiID();
		updateElemID = reserveGuiID();
		fullUpdateElemID = reserveGuiID();
		sysUpdateElemID = reserveGuiID();
		@blueprints = SortedBlueprintList();

		syncTimer = 1.f;
		syncNum = 0;
	}

	void remove() {
		removed = true;
		@blueprints = null;
		for (uint i = 0; i < sysEntries.length(); ++i)
			sysEntries[i].remove();
		sysEntries.resize(0);
		for (uint i = 0; i < groupEntries.length(); ++i)
			groupEntries[i].remove();
		groupEntries.resize(0);
		for (uint i = 0; i < planetEntries.length(); ++i)
			planetEntries[i].remove();
		planetEntries.resize(0);
	}

	void setPinned(bool pin) {
		pinned = pin;
		pinImg.setColor(pin ? pinnedCol : unpinnedCol);
	}

	bool isPinned() {
		return pinned;
	}

	void addSystem(System@ sys, bool additional, bool toggle) {
		// Add planets from system to list
		if (!additional) {
			addedPlanets.clear();
			@curSys = sys;
			sysName.setText("#a:center##font:goodtimes_14##c:0d0#"+sys.toObject().getName()+"#c##font##a#");
		}
		else {
			@curSys = null;
			sysName.setText("#a:center##font:goodtimes_14##c:0d0#"+localize("#EM_Planets")+"#c##font##a#");
		}
		
		SysObjList objects;
		objects.prepare(sys);

		for (uint i = 0; i < objects.childCount; ++i) {
			Object@ obj = objects.getChild(i);
			Planet@ pl = obj.toPlanet();

			if (@pl != null) {
				if (toggle && addedPlanets.exists(obj.uid))
					addedPlanets.erase(obj.uid);
				else
					addedPlanets.insert(obj.uid);
			}
			else if (obj.getOwner() is getActiveEmpire()) {
				HulledObj@ hulled = obj;
				if (hulled !is null) {
					if (hulled.getHull().hasSystemWithTag(strBuildsShips))
						addedPlanets.insert(obj.uid);
				}
			}
		}
	}

	void addSystem(System@ sys, bool additional) {
		addSystem(sys, additional, additional);
	}

	void addGroup(uint num, bool additional) {
		// Add planets from system to list
		if (!additional) {
			addedPlanets.clear();
			sysName.setText("#a:center##font:goodtimes_14##c:0d0#"+groupNames[num]+"#c##font##a#");
		}
		else {
			sysName.setText("#a:center##font:goodtimes_14##c:0d0#"+localize("#EM_Planets")+"#c##font##a#");
		}
		
		@curSys = null;
		groups[num].resetIter();
		while (groups[num].hasNext()) {
			Object@ obj = getObjectByID(groups[num].next());

			if (additional && addedPlanets.exists(obj.uid))
				addedPlanets.erase(obj.uid);
			else
				addedPlanets.insert(obj.uid);
		}
	}

	void init(GuiElement@ ele) {
		// Close button
		@close = CloseButton(recti(), ele);

		/* Left Pane */
		@leftPanel = GuiPanel(recti(), false, SBM_Invisible, SBM_Invisible, ele);

		// List tabs
		@systemsTab = GuiButton(getSkinnable("Button"), recti(0, 1, 91, 21), localize("#SY_Systems"), leftPanel);
		systemsTab.setToggleButton(true);
		systemsTab.setPressed(true);

		@groupsTab = GuiButton(getSkinnable("Button"), recti(94, 1, 180, 21), localize("#SY_Groups"), leftPanel);
		groupsTab.setToggleButton(true);
		groupsTab.setPressed(false);

		// List actions
		@selectAll = GuiButton(getSkinnable("Button"), recti(0, 23, 91, 43), localize("#SY_SelectAll"), leftPanel);
		@selectNone = GuiButton(getSkinnable("Button"), recti(94, 23, 180, 43), localize("#SY_SelectNone"), leftPanel);

		// System list
		@sysPanel = GuiPanel(recti(0, 78, 180, 472), false, SBM_Auto, SBM_Invisible, leftPanel);
		@grpPanel = GuiPanel(recti(0, 50, 180, 472), false, SBM_Auto, SBM_Invisible, leftPanel);
		grpPanel.setVisible(false);

		// System filters
		@sysFilter = GuiComboBox(recti(0, 50, 180, 70), leftPanel);
		sysFilter.addItem(localize("#SY_MySystems"));
		sysFilter.addItem(localize("#SY_ContestedSystems"));
		sysFilter.addItem(localize("#SY_VisibleSystems"));
		sysFilter.addItem(localize("#SY_AllSystems"));
		sysFilter.setID(sysUpdateElemID);

		/* Right Pane */
		@rightPanel = GuiPanel(recti(), false, SBM_Invisible, SBM_Invisible, ele);

		// Global actions
		@globalText = GuiExtText(recti(0, 2, 186, 24), rightPanel);
		globalText.setText("#a:center##font:frank_11#"+localize("#SY_Actions")+"#font##a#");

		// Build menu
		@buildType = GuiComboBox(recti(1, 26, 186, 47), rightPanel);
		@buildList = GuiListBox(recti(0, 54, 184, 271), true, rightPanel);

		buildType.addItem(localize("#SY_BuildBest"));
		buildType.addItem(localize("#SY_BuildAll"));

		@shipSort = GuiComboBox(recti(0, 0, 100, 50), rightPanel);
		shipSort.setID(updateElemID);
		shipSort.addItem("-- "+localize("#asc")+" --");
		shipSort.addItem(localize("#LET_SortName"));
		shipSort.addItem(localize("#LET_SortScale"));

		shipSort.addItem("-- "+localize("#desc")+" --");
		shipSort.addItem(localize("#LET_SortName"));
		shipSort.addItem(localize("#LET_SortScale"));

		shipSort.setSelected(2);

		// Actions
		@actText = GuiExtText(recti(0, 276, 186, 292), rightPanel);
		actText.setText("#a:center#"+localize("#SY_WithAll")+"#a#");
		
		@selectAllGovsText = GuiExtText(recti(1, 431, 189, 446), rightPanel);
		selectAllGovsText.setText("#a:center#"+localize("#SY_AllGovs")+"#a#");

		@renovateAll = GuiButton(getSkinnable("Button"), recti(1, 319, 185, 344), localize("#SY_RenovateAll"), rightPanel);
		@loadQueueAll = GuiButton(getSkinnable("Button"), recti(1, 319, 185, 344), localize("#SY_LoadQueue"), rightPanel);
		@clearQueueAll = GuiButton(getSkinnable("Button"), recti(1, 319, 185, 344), localize("#SY_ClearQueue"), rightPanel);
		
		@selectAllGovsBox = GuiComboBox(recti(1, 453, 140, 474), rightPanel);
		@selectAllGovsButton = GuiButton(getSkinnable("Button"), recti(145, 453, 185, 474), localize("#SY_AllGovsApply"), rightPanel);
		
		/* Center Pane */
		@centerPanel = GuiPanel(recti(), false, SBM_Invisible, SBM_Invisible, ele);

		@sysName = GuiExtText(recti(0, 2, 657, 20), centerPanel);
		sysName.setText("#a:center##font:goodtimes_14##c:0d0#"+localize("#EM_Planets")+"#c##font##a#");

		@pinImg = GuiImage(pos2di(196, 5), "planet_queuepin", centerPanel);
		pinImg.setColor(pinned ? pinnedCol : unpinnedCol);
		pinImg.setClickThrough(false);
		pinImg.setToolTip(localize("#SY_Pin"));

		// Information toggles
		@showQueue = GuiButton(recti(5, 0, 60, 20), null, centerPanel);
		showQueue.setSprites("Sys_Filter_Queue", 0, 2, 1);
		showQueue.setAppearance(BA_ScaleImage, BA_Background);
		showQueue.setToolTip(localize("#SYTT_ShowQueue"));
		showQueue.setToggleButton(true);
		showQueue.setPressed(true);
		showQueue.setID(fullUpdateElemID);

		@showResources = GuiButton(recti(64, 0, 119, 20), null, centerPanel);
		showResources.setSprites("Sys_Filter_Construction", 0, 2, 1);
		showResources.setAppearance(BA_ScaleImage, BA_Background);
		showResources.setToolTip(localize("#SYTT_ShowResources"));
		showResources.setToggleButton(true);
		showResources.setPressed(false);
		showResources.setID(fullUpdateElemID);

		@showPlanetRes = GuiButton(recti(123, 0, 178, 20), null, centerPanel);
		showPlanetRes.setSprites("Sys_Filter_Resources", 0, 2, 1);
		showPlanetRes.setAppearance(BA_ScaleImage, BA_Background);
		showPlanetRes.setToolTip(localize("#SYTT_ShowPlanetRes"));
		showPlanetRes.setToggleButton(true);
		showPlanetRes.setPressed(false);
		showPlanetRes.setID(fullUpdateElemID);

		@showLogisticsRes = GuiButton(recti(182, 0, 237, 20), null, centerPanel);
		showLogisticsRes.setSprites("Sys_Filter_Logistics", 0, 2, 1);
		showLogisticsRes.setAppearance(BA_ScaleImage, BA_Background);
		showLogisticsRes.setToolTip(localize("#SYTT_ShowLogisticsRes"));
		showLogisticsRes.setToggleButton(true);
		showLogisticsRes.setPressed(false);
		showLogisticsRes.setID(fullUpdateElemID);

		// Create group
		@createGroupButton = GuiButton(getSkinnable("Button"), recti(564, 0, 655, 20), localize("#SY_CreateGroup"), centerPanel);
		@groupName = GuiEditBox(recti(440, 0, 560, 20), localize("#SY_Group")+" 1", true, centerPanel);

		@plPanel = GuiPanel(recti(0, 54, 657, 445), false, SBM_Auto, SBM_Invisible, centerPanel);

		// Planet filters
		@planetFilter = GuiComboBox(recti(235, 27, 380, 44), centerPanel);
		@orderFilter = GuiComboBox(recti(384, 27, 494, 44), centerPanel);

		planetFilter.addItem(localize("#SY_AllPlanets"));
		planetFilter.addItem(localize("#SY_MyPlanets"));
		planetFilter.addItem(localize("#SY_MyBoth"));
		planetFilter.addItem(localize("#SY_MyDocks"));
		planetFilter.addItem(localize("#SY_UncolonizedPlanets"));
		planetFilter.addItem(localize("#SY_ColonizedPlanets"));
		planetFilter.setID(fullUpdateElemID);
		planetFilter.setSelected(2);

		orderFilter.addItem(localize("#SY_All"));
		orderFilter.addItem(localize("#SY_Idle"));
		orderFilter.addItem(localize("#SY_Constructing"));
		orderFilter.addItem(localize("#SY_ConsShip"));
		orderFilter.addItem(localize("#SY_ConsStruct"));
		orderFilter.setID(fullUpdateElemID);
		orderFilter.setSelected(0);

		@governorFilter = GuiComboBox(recti(498, 27, 657, 44), centerPanel);
		governorFilter.setID(fullUpdateElemID);

		@sortType = GuiComboBox(recti(384, 27, 494, 44), centerPanel);
		sortType.addItem("-- "+localize("#asc")+" --");
		sortType.addItem(localize("#SYS_Name"));
		sortType.addItem(localize("#SYS_TotalSlots"));
		sortType.addItem(localize("#SYS_BuiltSlots"));
		sortType.addItem(localize("#SYS_FreeSlots"));
		sortType.addItem(localize("#SYS_Governor"));

		sortType.addItem("-- "+localize("#desc")+" --");
		sortType.addItem(localize("#SYS_Name"));
		sortType.addItem(localize("#SYS_TotalSlots"));
		sortType.addItem(localize("#SYS_BuiltSlots"));
		sortType.addItem(localize("#SYS_FreeSlots"));
		sortType.addItem(localize("#SYS_Governor"));

		sortType.setSelected(1);

		syncPosition(ele.getSize());
	}

	void syncPosition(dim2di size) {
		// Center panel
		pos2di cPos = pos2di(7, 20);
		dim2di cSize = size - dim2di(14, 20);

		// Close button
		close.setPosition(pos2di(size.width-30, 0));
		close.setSize(dim2di(30, 12));

		// Left Panel
		if (size.width >= 860) {
			recti lPane = recti(pos2di(7, 20), pos2di(187, size.height-7));
			dim2di lSize = lPane.getSize();

			leftPanel.setVisible(true);
			leftPanel.setPosition(lPane.UpperLeftCorner);
			leftPanel.setSize(lSize);

			sysPanel.setSize(dim2di(lSize.width, lSize.height-78));
			grpPanel.setSize(dim2di(lSize.width, lSize.height-50));

			cPos.x = 193;
			cSize.width -= 186;
		}
		else {
			leftPanel.setVisible(false);
		}

		// Right panel
		if (size.width >= 660) {
			recti rPane = recti(pos2di(size.width-192, 20), pos2di(size.width-7, size.height-7));
			dim2di rSize = rPane.getSize();

			rightPanel.setVisible(true);
			rightPanel.setPosition(rPane.UpperLeftCorner);
			rightPanel.setSize(rSize);

			buildList.setSize(dim2di(185, rSize.height - 47 - 176 - 20 - 6));
			actText.setPosition(pos2di(0, rSize.height - 161));

			shipSort.setPosition(pos2di(0, 54 + buildList.getSize().height + 6));
			shipSort.setSize(dim2di(185, 20));

			renovateAll.setPosition(pos2di(1, rSize.height - 135));
			loadQueueAll.setPosition(pos2di(1, rSize.height - 109));
			clearQueueAll.setPosition(pos2di(1, rSize.height - 83));

			selectAllGovsText.setPosition(pos2di(0, rSize.height - 49));
			selectAllGovsBox.setPosition(pos2di(1, rSize.height - 23));
			selectAllGovsButton.setPosition(pos2di(145, rSize.height - 23));

			cSize.width -= 190;
		}
		else {
			rightPanel.setVisible(false);
		}

		// Center panel
		centerPanel.setPosition(cPos);
		centerPanel.setSize(cSize);

		// Main area
		plPanel.setSize(dim2di(cSize.width, cSize.height - 90));

		sysName.setSize(dim2di(cSize.width, 20));
		pinImg.setPosition(pos2di(cSize.width - 27, 5));

		// Filters
		int region = (cSize.width)*0.26, offset = 0;
		recti rect = recti(pos2di(offset, 28), pos2di(offset + region,  47));
		planetFilter.setPosition(rect.UpperLeftCorner);
		planetFilter.setSize(rect.getSize());

		offset += region; region = (cSize.width)*0.20;
		rect = recti(pos2di(offset, 28), pos2di(offset + region,  47));
		orderFilter.setPosition(rect.UpperLeftCorner);
		orderFilter.setSize(rect.getSize());

		offset += region; region = (cSize.width)*0.30;
		rect = recti(pos2di(offset, 28), pos2di(offset + region,  47));
		governorFilter.setPosition(rect.UpperLeftCorner);
		governorFilter.setSize(rect.getSize());

		offset += region; region = (cSize.width)*0.24;
		rect = recti(pos2di(offset, 28), pos2di(offset + region,  47));
		sortType.setPosition(rect.UpperLeftCorner);
		sortType.setSize(rect.getSize());

		// Content buttons
		showQueue.setPosition(pos2di(showQueue.getPosition().x, cSize.height - 29));
		showResources.setPosition(pos2di(showResources.getPosition().x, cSize.height - 29));
		showPlanetRes.setPosition(pos2di(showPlanetRes.getPosition().x, cSize.height - 29));
		showLogisticsRes.setPosition(pos2di(showLogisticsRes.getPosition().x, cSize.height - 29));

		// Group buttons
		createGroupButton.setPosition(pos2di(cSize.width - 93, cSize.height - 29));
		groupName.setPosition(pos2di(cSize.width - 218, cSize.height - 29));

		// Refresh planet positions if necessary
		int columns = floor(cSize.width / plEntryWidth);
		if (prevColumns != columns) {
			updatePlanets(true);
			prevColumns = columns;
		}
	}

	void draw(GuiElement@ ele) {
		ele.toGuiScripted().setAbsoluteClip();
		const recti absPos = ele.getAbsolutePosition();
		pos2di topLeft = absPos.UpperLeftCorner;
		pos2di botRight = absPos.LowerRightCorner;
		dim2di size = absPos.getSize();

		drawWindowFrame(absPos);
		drawResizeHandle(recti(botRight - pos2di(19, 19), botRight));

		/* Left pane */
		if (size.width >= 860) {
			drawDarkArea(recti(pos2di(topLeft.x+7, topLeft.y+20), pos2di(topLeft.x+187, botRight.y-7)));

			drawVSep(recti(pos2di(topLeft.x+186, topLeft.y+19), pos2di(topLeft.x+193, botRight.y-6)));
			drawHSep(recti(pos2di(topLeft.x+6, topLeft.y+63), pos2di(topLeft.x+188, topLeft.y+70)));

			if (sysFilter.isVisible())
				drawHSep(recti(pos2di(topLeft.x+6, topLeft.y+90), pos2di(topLeft.x+188, topLeft.y+97)));
		}

		/* Right pane */
		if (size.width >= 660) {
			drawVSep(recti(pos2di(botRight.x-198, topLeft.y+19), pos2di(botRight.x-191, botRight.y-6)));
			drawDarkArea(recti(pos2di(botRight.x-191, topLeft.y+20), pos2di(botRight.x-7, botRight.y-7)));

			drawHSep(recti(pos2di(botRight.x-193, topLeft.y+40), pos2di(botRight.x-6, topLeft.y+47)));
			drawHSep(recti(pos2di(botRight.x-193, topLeft.y+67), pos2di(botRight.x-6, topLeft.y+74)));

			drawHSep(recti(pos2di(botRight.x-193, botRight.y-177-27), pos2di(botRight.x-6, botRight.y-170-27)));

			drawHSep(recti(pos2di(botRight.x-193, botRight.y-177), pos2di(botRight.x-6, botRight.y-170)));
			drawHSep(recti(pos2di(botRight.x-193, botRight.y-150), pos2di(botRight.x-6, botRight.y-143)));

			drawHSep(recti(pos2di(botRight.x-193, botRight.y-65), pos2di(botRight.x-6, botRight.y-58)));
			drawHSep(recti(pos2di(botRight.x-193, botRight.y-38), pos2di(botRight.x-6, botRight.y-31)));
		}

		// Calculate correct area for center
		recti centerArea;
		if (size.width < 660)
			centerArea = absPos;
		else if (size.width < 860)
			centerArea = recti(topLeft, pos2di(botRight.x-190, botRight.y));
		else
			centerArea = recti(pos2di(topLeft.x+186, topLeft.y),
							   pos2di(botRight.x-190, botRight.y));

		topLeft = centerArea.UpperLeftCorner;
		botRight = centerArea.LowerRightCorner;
		size = centerArea.getSize();

		/* Center pane */
		drawHSep(recti(pos2di(topLeft.x+6, topLeft.y+40), pos2di(botRight.x-6, topLeft.y+47)));
		drawHSep(recti(pos2di(topLeft.x+6, topLeft.y+67), pos2di(botRight.x-6, topLeft.y+74)));
		drawHSep(recti(pos2di(topLeft.x+6, botRight.y-38), pos2di(botRight.x-6, botRight.y-31)));

		drawDarkArea(recti(pos2di(topLeft.x+7, topLeft.y+20), pos2di(botRight.x-7, topLeft.y+41)));
		drawDarkArea(recti(pos2di(topLeft.x+7, topLeft.y+47), pos2di(botRight.x-7, topLeft.y+68)));
		drawDarkArea(recti(pos2di(topLeft.x+7, botRight.y-31), pos2di(botRight.x-7, botRight.y-7)));

		drawLightArea(recti(pos2di(topLeft.x+7, topLeft.y+74), pos2di(botRight.x-7, botRight.y-37)));

		clearDrawClip();
	}

	void doUpdate() {
		updateGovernors();
		updatePlanets(false);
		updateBuildList();
		updateGroups();

		// Calibrate all panel sizes
		sysPanel.fitChildren();
		plPanel.fitChildren();
		grpPanel.fitChildren();
	}

	void doFullUpdate() {
		updatePlanets(true);
	}

	void update(float time) {
		// Update systems, this is done less often because
		// there are so many systems it's awfully slow.
		if (nextSysUpdate <= 0.f) {
			updateSystems();
			nextSysUpdate = sysUpdateInterval;
		}
		else nextSysUpdate -= time;

		// Update others
		if (nextUpdate <= 0.f) {
			doUpdate();

			nextUpdate = updateInterval;
		}
		else nextUpdate -= time;

		// Check if we should switch systems
		if (!pinned && curSys !is null) {
			Object@ selected = getSelectedObject(getSubSelection());

			if (selected !is null) {
				System@ sys = selected.getCurrentSystem();

				if (sys !is curSys && sys !is null) {
					if (sys.isVisibleTo(getActiveEmpire())) {
						@curSys = sys;
						addSystem(sys, false, false);
						doFullUpdate();
					}
				}
			}
		}

		// Request object syncs periodically
		if(isClient()) {
			syncTimer -= time;
			if(syncTimer < 0) {
				syncTimer = 0.333f;

				uint len = planetEntries.length();
				if (len > 0) {
					syncNum = (syncNum + 1) % len;
					requestObjectSync(planetEntries[syncNum].obj);
				}
			}
		}
	}

	EventReturn onKeyEvent(GuiElement@ ele, const KeyEvent& evt) {
		if (evt.pressed) {
			switch (evt.char) {
				case 91:
					// [ Toggles the action menu
					buildType.setSelected(0);
					return ER_Absorb;
				case 93:
					// ] Toggles the action menu
					buildType.setSelected(1);
					return ER_Absorb;
				case 114:
					// r renovates all
					doRenovateAll();
					return ER_Absorb;
				case 97:
					// a selects all
					selectAllSystems();
					return ER_Absorb;
				case 110:
					// n selects none
					selectNoSystems();
					return ER_Absorb;
				case 112:
					// p toggles pinned
					setPinned(!isPinned());
					return ER_Absorb;
			}
		}
		return ER_Pass;
	}

	EventReturn onMouseEvent(GuiElement@ ele, const MouseEvent& evt) {
		DragResizeEvent re = handleDragResize(ele, evt, drag, MIN_WIDTH, MIN_HEIGHT);
		if (re != RE_None) {
			if (re == RE_Resized)
				syncPosition(ele.getSize());
			return ER_Absorb;
		}
		return ER_Pass;
	}

	void createGroup() {
		if (planetEntries.length() > 0) {
			// Allocate group
			uint num = groups.length();
			groups.resize(num+1);
			groupNames.resize(num+1);

			// Add planets
			groups[num].clear();
			for (uint i = 0; i < planetEntries.length(); ++i) {
				groups[num].insert(planetEntries[i].obj.uid);
			}

			// Get name
			@groupNames[num] = groupName.getText();

			// Fill next name
			groupName.setText(localize("#SY_Group")+" "+groupNum);
			++groupNum;

			doUpdate();
		}
	}

	void showSystems() {
		systemsTab.setPressed(true);
		groupsTab.setPressed(false);

		sysPanel.setVisible(true);
		grpPanel.setVisible(false);
		sysFilter.setVisible(true);
	}

	void showGroups() {
		systemsTab.setPressed(false);
		groupsTab.setPressed(true);

		sysPanel.setVisible(false);
		grpPanel.setVisible(true);
		sysFilter.setVisible(false);
	}

	void selectAllSystems() {
		if (groupsTab.isPressed())
			for (uint i = 0; i < groupEntries.length(); ++i) {
				addGroup(groupEntries[i].num, i > 0);
			}
		else
			for (uint i = 0; i < sysEntries.length(); ++i) {
				addSystem(sysEntries[i].sys, i > 0);
			}

		doUpdate();
	}

	void selectNoSystems() {
		addedPlanets.clear();
		sysName.setText("#a:center##font:goodtimes_14##c:0d0#"+localize("#EM_Planets")+"#c##font##a#");
		@curSys = null;
		
		doUpdate();
	}

	void buildOnSelectedBest(const HullLayout@ layout, uint count) {
		uint len = planetEntries.length();
		const Empire@ emp = getActiveEmpire();

		for (uint n = 0; n < count; ++n) {
			float best = 0.f;
			Object@ pl = null;

			for (uint i = 0; i < len; ++i) {
				Object@ cur = planetEntries[i].obj;
				if (@cur != null && emp is cur.getOwner()) {
					float weight = getObjectWeight(cur);

					if (weight > best) {
						best = weight;
						@pl = @cur;
					}
				}
			}

			if (@pl != null) {
				pl.makeShip(layout);
			}
			else break;
		}
	}

	void buildOnSelectedAll(const HullLayout@ layout, uint count) {
		uint len = planetEntries.length();
		const Empire@ emp = getActiveEmpire();

		for (uint i = 0; i < len; ++i) {
			planetEntry@ ent = planetEntries[i];
			const Empire@ owner = ent.obj.getOwner();
			
			if (@ent.obj != null && emp is owner)
				ent.obj.makeShip(layout, count);
		}
	}

	void doBuild(uint count) {
		uint type = buildType.getSelected();
		uint itemSelected = buildList.getSelected();

		const HullLayout@ hull = blueprints.getLayout(itemSelected);
		if (@hull != null) {
			if (ctrlKey) {
				addEntryDialog(hull.getName()+" "+localize("#PL_QUANTITY")+":",
								"1", localize("#PL_BUILD"), SystemMultiBuild(this));
			}
			else {
				if (type == 0)
					buildOnSelectedBest(hull, count);
				else
					buildOnSelectedAll(hull, count);
			}
		}
	}

	void doRenovateAll() {
		for (uint i = 0; i < planetEntries.length(); ++i) {
			Planet@ pl = planetEntries[i].planet;
			if (pl is null)
				continue;
			int structIndex = pl.getStructureCount();
			for(int j = 0; j < structIndex; ++j)
				pl.rebuildStructure(j);
		}
	}

	void doLoadAll() {
		addSingleImportDialog(localize("#PL_QUEUE")+":",
				localize("#load"), "Queues",
				SystemLoadQueue(this, null));
	}

	void doClearAll() {
		for (uint i = 0; i < planetEntries.length(); ++i) {
			Object@ pl = planetEntries[i].obj;

			if (pl !is null && pl.getOwner() is getActiveEmpire())
				pl.clearBuildQueue();
		}
	}

	void changeAllGovernors() {
		int j = selectAllGovsBox.getSelected() - 4;
		if (j >= 0) {
			// Change governors and enable governors on selected planets
			for (uint i = 0; i < planetEntries.length(); ++i) {
				Planet@ pl = planetEntries[i].planet;
				if (pl is null)
					continue;
				pl.setGovernorType(getActiveEmpire().getBuildList(j));
				pl.setUseGovernor(true);
			}
			selectAllGovsBox.setSelected(0);
		}
		else if (j == -2) {
			// Disable governors on selected planets
			for (uint i = 0; i < planetEntries.length(); ++i) {
				Planet@ pl = planetEntries[i].planet;
				if (pl is null)
					continue;
				pl.setUseGovernor(false);
			}
			selectAllGovsBox.setSelected(0);
		}
		else if (j == -3) {
			// Enable governors on selected planets
			for (uint i = 0; i < planetEntries.length(); ++i) {
				Planet@ pl = planetEntries[i].planet;
				if (pl is null)
					continue;
				pl.setUseGovernor(true);
			}
			selectAllGovsBox.setSelected(0);
		}
	}

	EventReturn onGUIEvent(GuiElement@ ele, const GUIEvent& evt) {
		if (evt.EventType == GEVT_Focus_Gained && evt.Caller.isAncestor(ele)) {
			ele.bringToFront();
			bindEscapeEvent(ele);
		}
		else if (evt.EventType == GEVT_Closed) {
			closeSystemWindow(this);
			return ER_Absorb;
		}

		// Handle events coming from system entries
		if (evt.Caller.getID() == sysPanelID) {
			uint sysCnt = sysEntries.length();
			for (uint i = 0; i < sysCnt; ++i) {
				EventHandleState state = sysEntries[i].OnEvent(evt);
				if (state == EHS_Absorb)
					return ER_Absorb;
				if (state == EHS_Handled)
					return ER_Pass;
			}
		}

		// Handle events coming from group entries
		else if (evt.Caller.getID() == grpPanelID) {
			uint grpCnt = groupEntries.length();
			for (uint i = 0; i < grpCnt; ++i) {
				EventHandleState state = groupEntries[i].OnEvent(evt);
				if (state == EHS_Absorb)
					return ER_Absorb;
				if (state == EHS_Handled)
					return ER_Pass;
			}
		}

		// Handle events coming from planet entries
		else if (evt.Caller.getID() == plPanelID) {
			uint plCnt = planetEntries.length();
			for (uint i = 0; i < plCnt; ++i) {
				EventHandleState state = planetEntries[i].OnEvent(evt);
				if (state == EHS_Absorb)
					return ER_Absorb;
				if (state == EHS_Handled)
					return ER_Pass;
			}
		}

		// Handle events from the window elements themselves
		else switch (evt.EventType) {
			case GEVT_Clicked:
				if (evt.Caller is systemsTab) {
					showSystems();
					return ER_Pass;
				}
				else if (evt.Caller is groupsTab) {
					showGroups();
					return ER_Pass;
				}
				else if (evt.Caller is selectAll) {
					selectAllSystems();
					return ER_Pass;
				}
				else if (evt.Caller is selectNone) {
					selectNoSystems();
					return ER_Pass;
				}
				else if (evt.Caller is createGroupButton) {
					createGroup();
					return ER_Pass;
				}
				else if (evt.Caller is renovateAll) {
					doRenovateAll();
					return ER_Pass;
				}
				else if (evt.Caller is loadQueueAll) {
					doLoadAll();
					return ER_Pass;
				}
				else if (evt.Caller is clearQueueAll) {
					doClearAll();
					return ER_Pass;
				}
				else if (evt.Caller is selectAllGovsButton) {
					changeAllGovernors();
					return ER_Pass;
				}
				else if (evt.Caller is close) {
					closeSystemWindow(this);
					return ER_Pass;
				}
			case GEVT_ComboBox_Changed:
				if (evt.Caller.getID() == updateElemID) {
					doUpdate();
				}
				else if (evt.Caller.getID() == fullUpdateElemID) {
					doFullUpdate();
				}
				else if (evt.Caller.getID() == sysUpdateElemID) {
					updateSystems();
				}
			break;
			case GEVT_Listbox_Selected_Again:
				if (evt.Caller is buildList) {
					doBuild(shiftKey ? 5 : 1);
				}
			break;
			case GEVT_Focus_Gained:
				if (evt.Caller is pinImg) {
					setPinned(!isPinned());
					return ER_Absorb;
				}
			break;
		}

		return ER_Pass;
	}

	void updateSystems() {
		// System Entries
		uint len = sysEntries.length();
		Galaxy@ glx = getGalaxy();

		uint filter = sysFilter.getSelected();

		uint sysCnt = 0;
		uint cnt = getSystemCount();
		Empire@ emp = getActiveEmpire();
		SysPresence pres;
		bool presence = false;
		int numPlanets = -1;

		for (uint i = 0; i < cnt; ++i) {
			System@ sys = getSystem(i);
			Object@ obj = sys;
			presence = false;
			numPlanets = -1;

			if (@sys == null)
				break;

			// Check for planets owned by us
			if (filter == 0) {
				numPlanets = int(obj.getStat(emp, str_planets));

				if (numPlanets < 1)
					continue;
			}

			if (filter == 1 || filter == 2) {
				emp.getSystemPresence(sys, pres);
				presence = true;

				if (pres.us < 1.f)
					continue;

				if (filter == 1 && pres.enemiesStr < 0.001f)
					continue;
			}

			// Check position in array
			if (sysCnt >= len) {
				++len;
				sysEntries.resize(len);

				// Create entry
				uint y = sysCnt*(sysEntryHeight+sysEntrySpacing);
				uint w = sysPanel.getSize().width;
				@sysEntries[sysCnt] = sysEntry(recti(0, y, 167, y+sysEntryHeight), sysPanel, this);
			}

			sysEntries[sysCnt].setSystem(sys);

			if (!presence)
				emp.getSystemPresence(sys, pres);
			if (numPlanets < 0)
				numPlanets = obj.getStat(emp, str_planets);
				

			sysEntries[sysCnt].update(pres, uint(numPlanets));
			++sysCnt;
		}

		for (uint i = sysCnt; i < len; ++i)
			sysEntries[i].remove();

		sysEntries.resize(sysCnt);

		// Finally, after releasing the galaxy lock, update strength indicators
		SystemStats stats;
		stats.prepare(null);

		for (uint i = 0; i < sysCnt; ++i) {
			sysEntries[i].strScript.update(sysEntries[i].sys, stats);
			stats.prepare(null);
		}
	}

	void updateGroups() {
		// System Entries
		uint len = groupEntries.length();
		uint cnt = groups.length();
		uint grCnt = 0;

		Empire@ emp = getActiveEmpire();

		for (uint i = 0; i < cnt; ++i) {
			// Check position in array
			if (grCnt >= len) {
				++len;
				groupEntries.resize(len);

				// Create entry
				uint y = grCnt*(sysEntryHeight+sysEntrySpacing);
				uint w = grpPanel.getSize().width;
				@groupEntries[grCnt] = groupEntry(recti(0, y, 167, y+sysEntryHeight), grpPanel, this);
			}

			groupEntries[grCnt].setGroup(i);
			++grCnt;
		}

		for (uint i = grCnt; i < len; ++i)
			groupEntries[i].remove();

		groupEntries.resize(grCnt);
	}

	void updatePlanets(bool clear) {
		// Update actual added planets
		if (curSys !is null)
			addSystem(curSys, false, false);

		// Planet entries
		uint len = planetEntries.length();

		// Do a full update if we have to
		if (clear) {
			for (uint i = 0; i < len; ++i)
				planetEntries[i].remove();
			planetEntries.resize(0);
			len = 0;
		}

		// Reset selected systems
		set_int systemIDs;

		// Calculate height
		uint plEntryHeight = max(plEntryBaseHeight,
			plEntryBareHeight + (showQueue.isPressed() ? 25 : 0)
							  + (showResources.isPressed() ? 20 : 0)
							  + (showPlanetRes.isPressed() ? 20 : 0)
							  + (showLogisticsRes.isPressed() ? 20 : 0));

		// Create new planet entries
		uint plCnt = 0;
		const Empire@ emp = getActiveEmpire();
		const Empire@ space = getEmpireByID(-1);
		OrderList orders;

		int invalid = 0;
		addedPlanets.resetIter();
		while(addedPlanets.hasNext()) {
			int id = addedPlanets.next();
			Object@ obj = getObjectByID(id);
			Planet@ pl = obj;

			//Skip and remove invalid objects
			if (obj is null || !obj.isValid()) {
				invalid = id;
				continue;
			}

			//Just skip docked objects for now
			if(obj.getParent() is null)
				continue;

			// Check filters
			uint filter = planetFilter.getSelected();
			uint govFilter = governorFilter.getSelected();
			uint ordFilter = orderFilter.getSelected();
			const Empire@ owner = obj.getOwner();

			systemIDs.insert(obj.getParent().uid);

			// Owner filter
			switch (filter) {
				case 0:
					if (pl is null)
						continue;
				break;
				case 1:
					if (owner !is emp || pl is null)
						continue;
				break;
				case 2:
					if (owner !is emp)
						continue;
				break;
				case 3:
					if (owner !is emp || pl !is null)
						continue;
				break;
				case 4:
					if (owner !is space || pl is null)
						continue;
				break;
				case 5:
					if (owner is space || pl is null)
						continue;
				break;
			}

			// Governor filter
			if (govFilter == 1) {
				if (pl is null || pl.usesGovernor())
					continue;
			}
			else if (govFilter == 2) {
				if (pl !is null && !pl.usesGovernor())
					continue;
			}
			else if (govFilter > 3) {
				if (pl is null)
					continue;
				string@ governor = pl.getGovernorType();
				uint num = emp.getBuildListCount();
				bool correct = false;

				for (uint i = 0; i < num; i++) {
					if (emp.getBuildList(i) == governor) {
						if (i+4 == govFilter)
							correct = true;
						break;
					}
				}

				if (!correct) continue;
			}

			// Order filter
			if (ordFilter > 0) {
				if(obj.getConstructionQueueSize() > 0) {
					if (ordFilter == 1)
						continue;

					string@ type = obj.getConstructionType(0);

					if ((ordFilter == 4 && type != "structure") ||
						(ordFilter == 3 && type != "ship"))
						continue;
				}
				else
					if (ordFilter != 1)
						continue;
			}

			// Check position in array
			if (plCnt >= len) {
				// Create new ently
				++len;
				planetEntries.resize(len);
				@planetEntries[plCnt] = planetEntry(recti(pos2di(0, 0), dim2di(plEntryWidth, plEntryHeight)), plPanel, this);
			}

			if (pl !is null)
				planetEntries[plCnt].setPlanet(pl);
			else
				planetEntries[plCnt].setObject(obj);
			++plCnt;
		}

		// Remove invalid id
		if (invalid > 0)
			addedPlanets.erase(invalid);

		// Remove old planet entries
		for (uint i = plCnt; i < len; ++i)
			planetEntries[i].remove();

		// Sort the planet entries
		planetEntries.resize(plCnt);

		planetEntry@[] sorted = planetEntries;
		sorted.sort(sortType.getSelected() < 6);
		
		// Position the planet entries
		int columns = floor(plPanel.getSize().width / plEntryWidth);
		int col = 0;

		for (uint i = 0; i < plCnt; ++i) {
			uint y = floor(i/columns)*(plEntryHeight+plEntrySpacing);
			sorted[i].setPosition(pos2di(col*plEntryWidth, y));
			col = (col + 1) % columns;
		}

		// Highlight selected systems
		for (uint i = 0; i < sysEntries.length(); ++i)
			sysEntries[i].panel.setImage(systemIDs.exists(sysEntries[i].sys.toObject().uid) ? "Sys_Item_HL" :  "Sys_Item");
		orders.prepare(null);
	}

	void updateGovernors() {
		//Update governor lists if buildlist count has changed since last check
		const Empire@ emp = getActiveEmpire();
		int cnt = emp.getBuildListCount();
		
		if(empireBuildListCount == cnt) return;
		empireBuildListCount = cnt;
		
		//Update governor filter and select planet governor lists
		governorFilter.clear();
		selectAllGovsBox.clear();
		
		governorFilter.addItem(localize("#SY_AllGovernors"));
		governorFilter.addItem(localize("#SY_NoGovernor"));
		governorFilter.addItem(localize("#SY_AGovernor"));
		governorFilter.addItem("");
		
		selectAllGovsBox.addItem(localize("#SY_AllGovsSelect"));
		selectAllGovsBox.addItem(localize("#SY_AllGovsOn"));
		selectAllGovsBox.addItem(localize("#SY_AllGovsOff"));
		selectAllGovsBox.addItem("");
		
		for (int i = 0; i < cnt; ++i) {
			governorFilter.addItem(localize("#PG_" + emp.getBuildList(i)));
			selectAllGovsBox.addItem(localize("#PG_" + emp.getBuildList(i)));
		}
		
	}

	void updateBuildList() {
		const Empire@ emp = getActiveEmpire();

		// Figure out the sort mode
		int sel = shipSort.getSelected();
		bool updateNow = false;
		if (sel != -1) {
			int mode = (sel % 3) - 1;
			if (mode < 0)
				mode = 0;

			updateNow = blueprints.setSortMode(BlueprintSortMode(mode), sel < 3);
		}

		// Update layouts
		if(blueprints.update(emp, updateNow)) {
			buildList.clear();
			uint lays = blueprints.length();
			for(uint i = 0; i < lays; ++i)
				buildList.addItem(blueprints.getText(i));
		}
	}
};
/* }}} */
// {{{ System entry
const string@ str_planets = "planets";
class sysEntry {
	GuiImage@ panel;
	GuiExtText@ text;
	GuiExtText@ planets;
	GuiButton@ img;
	GuiScripted@ strBar;
	StrengthBar@ strScript;
	SystemWindow@ win;
	GuiImage@ zoom;

	System@ sys;
	int elemID;

	sysEntry(recti position, GuiElement@ parent, SystemWindow@ window) {
		@win = window;
		elemID = win.sysPanelID;

		@panel = GuiImage(position.UpperLeftCorner, "Sys_Item", parent);
		panel.setSize(dim2di(position.getWidth(), position.getHeight()));
		panel.setScaleImage(true);
		panel.setClickThrough(false);
		panel.setID(elemID);

		const Empire@ emp = getActiveEmpire();
		uint width = position.getWidth();
		uint height = position.getHeight();

		@text = GuiExtText(recti(height+4, 4, width-30, height-8), panel);
		@planets = GuiExtText(recti(width-24, 4, width-6, height-8), panel);

		@img = GuiButton(recti(pos2di(4, 4), dim2di(height-8, height-8)), null, panel);
		img.setImages("sys_list_planet_group", "sys_list_planet_group");
		img.setAppearance(BA_ScaleImage,BA_Background);

		@strScript = StrengthBar();
		@strBar = GuiScripted(recti(height+4, height-6, width-4, height-3), strScript, panel);
		strScript.init(strBar);

		// Zoom button
		@zoom = GuiImage(pos2di(2, 2), "clause_edit", panel);
		zoom.setClickThrough(false);
		zoom.setScaleImage(true);
		zoom.setSize(dim2di(12, 12));
		zoom.setColor(transparent);
		zoom.setID(elemID);

		text.setID(elemID);
		planets.setID(elemID);
		img.setID(elemID);
	}

	void setSystem(System@ system)  {
		@sys = system;
	}

	void update() {
		SysPresence pres;
		getActiveEmpire().getSystemPresence(sys, pres);
		uint numPlanets = sys.toObject().getStat(getActiveEmpire(), str_planets);

		update(pres, numPlanets);
	}

	void update(SysPresence& pres, uint numPlanets) {
		if (numPlanets == 0)
			text.setText("#c:ccc#"+sys.toObject().getName()+"#c#");
		else if (pres.enemies >= 0.1f)
			text.setText("#c:db0#"+sys.toObject().getName()+"#c#");
		else
			text.setText(sys.toObject().getName());

		if (numPlanets > 0)
			planets.setText("#c:6c6##a:right#"+numPlanets+"#a##c#");
		else
			planets.setText("");

		strBar.setVisible(pres.us >= 1.f && (pres.enemies >= 1.f || pres.neutrals >= 1.f || pres.allies >= 1.f));
	}

	void remove() {
		panel.orphan(true);
		panel.remove();
		@sys = null;
		@win = null;
	}

	EventHandleState OnEvent(const GUIEvent@ evt) {
		switch (evt.EventType) {
			case GEVT_Right_Clicked:
				if (evt.Caller is img) {
					Object@ obj = sys.toObject();
					triggerContextMenu(obj);
					return EHS_Absorb;
				}
			break;
			case GEVT_Clicked:
				if (evt.Caller is img) {
					Object@ obj = sys.toObject();
					if (ctrlKey) {
						setCameraFocus(obj);
						setGuiFocus(null);
					}
					else {
						if (isSelected(obj)) {
							win.addSystem(sys, shiftKey);
							win.doUpdate();
						}
						else
							selectObject(obj);
					}
					setGuiFocus(win.sysPanel);
					return EHS_Absorb;
				}
			break;
			case GEVT_Focus_Gained:
				if(evt.Caller is panel || evt.Caller is text || evt.Caller is planets) {
					if (evt.EventType == GEVT_Focus_Gained) {
						Object@ obj = sys.toObject();
						if (ctrlKey) {
							setCameraFocus(obj);
							setGuiFocus(null);
						}
						else {
							win.addSystem(sys, shiftKey);
							win.doUpdate();
							if (!shiftKey)
								selectObject(sys.toObject());
							setGuiFocus(win.sysPanel);
							update();
						}
						return EHS_Absorb;
					}
				}
				else if (evt.Caller is zoom) {
					setCameraFocus(sys.toObject());
					setGuiFocus(null);
					return EHS_Absorb;
				}
			break;
			case GEVT_Mouse_Over:
				if (evt.Caller is zoom) {
					zoom.setColor(opaque);
					return EHS_Absorb;
				}
			break;
			case GEVT_Mouse_Left:
				if (evt.Caller is zoom) {
					zoom.setColor(transparent);
					return EHS_Absorb;
				}
			break;
			default:
				return EHS_Unhandled;
		}
		return EHS_Unhandled;
	}
};
// }}}
// {{{ Group entry
class groupEntry {
	GuiImage@ panel;
	GuiExtText@ text;
	GuiExtText@ planets;
	GuiButton@ img;
	GuiButton@ del;
	uint num;

	SystemWindow@ win;
	int elemID;

	groupEntry(recti position, GuiElement@ parent, SystemWindow@ window) {
		@win = window;
		elemID = win.grpPanelID;

		@panel = GuiImage(position.UpperLeftCorner, "Sys_Item", parent);
		panel.setSize(dim2di(position.getWidth(), position.getHeight()));
		panel.setScaleImage(true);
		panel.setClickThrough(false);

		const Empire@ emp = getActiveEmpire();
		uint width = position.getWidth();
		uint height = position.getHeight();

		@text = GuiExtText(recti(height+4, 4, width-28, height-8), panel);
		@planets = GuiExtText(recti(width-44, 4, width-24, height-8), panel);

		@img = GuiButton(recti(pos2di(4, 4), dim2di(height-8, height-8)), null, panel);
		img.setImages("planet_icon_generic", "planet_icon_generic");
		img.setAppearance(BA_ScaleImage,BA_Background);

		@del = GuiButton(recti(width-20, 4, width-4, 20), "x", panel);
		del.setToolTip(localize("#SY_DeleteGroup"));

		text.setID(elemID);
		planets.setID(elemID);
		del.setID(elemID);
		panel.setID(elemID);
		img.setID(elemID);
	}

	void setGroup(uint group)  {
		num = group;
		this.update();
	}

	void update() {
		if (num < groups.length()) {
			text.setText(groupNames[num]);
			planets.setText("#c:6c6##a:right#"+groups[num].size()+"#a##c#");

			// Check if we should highlight
			panel.setImage("Sys_Item");

			groups[num].resetIter();
			while(groups[num].hasNext()) {
				uint obj = groups[num].next();
				if (win.addedPlanets.exists(obj)) {
					panel.setImage("Sys_Item_HL");
					break;
				}
			}
		}
	}

	void remove() {
		@win = null;
		panel.orphan(true);
		panel.remove();
	}

	EventHandleState OnEvent(const GUIEvent@ evt) {
		if(evt.Caller is panel || evt.Caller is text || evt.Caller is planets || evt.Caller is img) {
			if (evt.EventType == GEVT_Focus_Gained) {
				win.addGroup(num, shiftKey);
				update();
				return EHS_Absorb;
			}
		}
		else if (evt.Caller is del) {
			if (evt.EventType == GEVT_Clicked) {
				uint last = groups.length();

				for (uint i = num; i < last-1; ++i) {
					@groupNames[i] = groupNames[i+1];
					groups[i].clear();
					
					groups[i+1].resetIter();
					while (groups[i+1].hasNext())
						groups[i].insert(groups[i+1].next());
				}

				groups.resize(last-1);
				groupNames.resize(last-1);

				update();
				return EHS_Absorb;
			}
		}
		return EHS_Unhandled;
	}
};
// }}}
// {{{ Planet entry
const string[] stateName = {"Food", "Ore", "Workers", "Mood", "Metals", "Electronics", "AdvParts", "Labr", "ShipBay", "Fuel", "Ammo"};
const string[] spriteName = {"planet_topbar_resources", "planet_topbar_resources", "planet_topbar_resources", "planet_topbar_resources", "planet_resource_list", "planet_resource_list", "planet_resource_list", "planet_topbar_resources", "planet_resource_list", "planet_resource_list", "planet_resource_list"};
string@[] resTooltip;
const int[] spriteInd = {0, 1, 4, 5, 2, 1, 0, 3, 4, 5, 6};
const int stateNum = 11;

class planetEntry {
	GuiImage@ panel;
	GuiImage@ zoom;
	GuiExtText@ text;
	GuiExtText@ order;
	GuiExtText@ slots;
	GuiButton@ img;
	GuiButton@ clear;
	GuiButton@ rem;
	GuiButton@ load;
	GuiButton@ repeat;
	GuiComboBox@ gov;
	GuiCheckBox@ useGov;
	GuiScripted@[] resIcons;
	GuiStaticText@[] resText;

	Planet@ planet;
	Object@ obj;
	string@ governor;
	string@ name;

	SystemWindow@ win;
	int elemID;
	int maxSlots;
	int usedSlots;

	planetEntry(recti position, GuiElement@ parent, SystemWindow@ window) {
		@win = window;
		elemID = win.plPanelID;

		@clear = null;
		@panel = GuiImage(position.UpperLeftCorner, "Sys_Container", parent);
		panel.setScaleImage(true);
		panel.setSize(dim2di(position.getWidth(), position.getHeight()));
		panel.setID(elemID);

		const Empire@ emp = getActiveEmpire();
		uint width = position.getWidth();
		uint height = position.getHeight();

		// Planet image
		@img = GuiButton(recti(pos2di(4, 4), dim2di(46, 46)), null, panel);
		img.setAppearance(BA_ScaleImage,BA_Background);
		img.setID(elemID);

		// Zoom button
		@zoom = GuiImage(pos2di(4, 4), "clause_edit", panel);
		zoom.setClickThrough(false);
		zoom.setScaleImage(true);
		zoom.setSize(dim2di(12, 12));
		zoom.setColor(transparent);
		zoom.setID(elemID);

		// Planet text
		@text = GuiExtText(recti(62, 4, width-198, 28), panel);
		text.setID(elemID);

		// Governors
		@gov = GuiComboBox(recti(width-184, 4, width-4, 24), panel);
		@useGov = GuiCheckBox(false, recti(width-204, 4, width-188, 24), "", panel);
		useGov.setToolTip(localize("#SY_UseGovernor"));

		gov.setID(elemID);
		useGov.setID(elemID);

		uint y = 27;

		// === Resource Rows
		resIcons.resize(stateNum);
		resText.resize(stateNum);

		uint x = 62;

		for (int i = 0; i < stateNum; ++i) {
			if (i < 4 && !win.showPlanetRes.isPressed()) continue;
			if (i >= 4 && i < 8 && !win.showResources.isPressed()) continue;
			if (i >= 8 && i < 12 && !win.showLogisticsRes.isPressed()) continue;

			uint w = i < 8 ? 70 : 100;
			uint offset = spriteName[i] == "planet_resource_list" ? 2 : 0;

			@resIcons[i] = GuiScripted(recti(pos2di(x+offset, y+offset), dim2di(17,17)), gui_sprite(spriteName[i], spriteInd[i]), panel);
			@resText[i] = GuiStaticText(recti(pos2di(x+20, y), dim2di(w, 17)), null, false, false, false, panel);
			resIcons[i].setToolTip(resTooltip[i]);
			resText[i].setToolTip(resTooltip[i]);
			x += w + 25;

			if (i == 3 || i == 7 || i == 10) {
				x = 62;
				y += 20;
			}
		}

		// === Queue Row
		if (win.showQueue.isPressed()) {
			@order = GuiExtText(recti(64, y, width-164, y+23), panel);
			@slots = GuiExtText(recti(width-170, y, width-103, y+23), panel);
			slots.setID(elemID);

			@clear = GuiButton(recti(pos2di(width-27, y+1), dim2di(21, 21)), null, panel);
			clear.setAppearance(BA_UseAlpha, BA_Background);
			clear.setSprites("Sys_Orders", 9, 11, 10);
			clear.setToolTip(localize("#SY_ClearQueue"));
			clear.setID(elemID);

			@rem = GuiButton(recti(pos2di(width-51, y+1), dim2di(21, 21)), null, panel);
			rem.setAppearance(BA_UseAlpha, BA_Background);
			rem.setSprites("Sys_Orders", 6, 8, 7);
			rem.setToolTip(localize("#SY_RemoveQueue"));
			rem.setID(elemID);

			@load = GuiButton(recti(pos2di(width-75, y+1), dim2di(21, 21)), null, panel);
			load.setAppearance(BA_UseAlpha, BA_Background);
			load.setSprites("Sys_Orders", 3, 5, 4);
			load.setToolTip(localize("#SY_LoadQueue"));
			load.setID(elemID);

			@repeat = GuiButton(recti(pos2di(width-99, y+1), dim2di(21, 21)), null, panel);
			repeat.setAppearance(BA_UseAlpha, BA_Background);
			repeat.setSprites("Sys_Orders", 0, 2, 1);
			repeat.setToolTip(localize("#SY_RepeatQueue"));
			repeat.setToggleButton(true);
			repeat.setID(elemID);
		}

		uint len = emp.getBuildListCount();
		for (uint i = 0; i < len; ++i)
			gov.addItem(localize("#PG_" + emp.getBuildList(i)));
	}

	void setPosition(pos2di pos) {
		panel.setPosition(pos);
	}

	int opCmp(planetEntry@ other) const {
		// Find correct sort mode
		int mode = 0;
		if (win !is null)
			mode = win.sortType.getSelected() % 6;
		if (mode < 0)
			mode = 0;

		// Check if we can sort
		int val = 0;
		switch (mode) {
			case 0:
			case 1:
				val = name.opCmp(other.name);
			break;
			case 2: {
				// Sort by total slots
				int myVal = maxSlots;
				int otherVal = other.maxSlots;
				
				if (otherVal < myVal)
					val = 1;
				else if (otherVal > myVal)
					val = -1;
			}
			break;
			case 3: {
				// Sort by total slots
				int myVal = usedSlots;
				int otherVal = other.usedSlots;
				
				if (otherVal < myVal)
					val = 1;
				else if (otherVal > myVal)
					val = -1;
			} break;
			case 4: {
				// Sort by free slots
				int myVal = maxSlots - usedSlots;
				int otherVal = other.maxSlots - other.usedSlots;
				
				if (otherVal < myVal)
					val = 1;
				else if (otherVal > myVal)
					val = -1;
			} break;
			case 5:
				val = governor.opCmp(other.governor);
			break;
		}

		// Sort by id if equal
		if (val == 0) {
			if (other.obj.uid < obj.uid)
				return 1;
			return -1;
		}
		return val;
	}

	void setPlanet(Planet@ pl) {
		@planet = pl;
		@obj = planet;

		// Update data contained
		if (pl !is null) {
			if (pl.hasCondition("ringworld_special")) {
				img.setImages("ringworld_icon", "ringworld_icon");
			}
			else {
				int ind = getPlanetIconIndex(pl.getPhysicalType());
				img.setSprites("planet_icons_new", ind, ind, ind);
			}

			this.update();
		}
	}

	void setObject(Object@ Obj) {
		if (Obj.toPlanet() !is null) {
			setPlanet(Obj);
			return;
		}

		@planet = null;
		@obj = Obj;

		if (obj !is null) {
			string@ bank = "neumon_shipset";
			uint ind = 2;
			obj.toHulledObj().getSpriteIcon(bank, ind);

			img.setSprites(bank, ind, ind, ind);

			this.update();
		}
	}

	void update() {
		if (@obj == null) return;

		const Empire@ emp = obj.getOwner();
		bool owned = emp is getActiveEmpire();

		if (planet is null) {
			maxSlots = 0;
			usedSlots = 0;
			@governor = null;
		}
		else {
			maxSlots = int(planet.getMaxStructureCount());
			usedSlots = int(planet.getStructureCount());
			@governor = planet.getGovernorType();
		}

		@name = obj.getName();

		gov.setVisible(owned && planet !is null);
		useGov.setVisible(owned && planet !is null);

		if (@clear != null) {
			clear.setVisible(owned);
			rem.setVisible(owned);
			load.setVisible(owned);
			repeat.setVisible(owned);
			order.setVisible(owned);
			slots.setVisible(owned);
		}

		if (int(resText.length()) == stateNum) {
			for (int i = 0; i < stateNum; ++i) {
				if (@resText[i] != null) {
					resText[i].setVisible(owned);
					resIcons[i].setVisible(owned);
				}
			}
		}

		if (owned) {
			// Planet text
			text.setText("#font:frank_11#"+obj.getName()+"#font#");

			// Planet governor
			if (planet !is null) {
				int num = gov.getItemCount();
				for (int i = 0; i < num; i++) {
					if (emp.getBuildList(i) == governor) {
						gov.setSelected(i);
						break;
					}
				}

				// Use governor
				useGov.setChecked(planet.usesGovernor());
			}

			if (@clear != null) {
				// Repeat Queue
				repeat.setPressed(obj.getRepeatQueue());

				// Slots
				if (planet !is null)
					slots.setText("#a:right##img:planet_space_full# "+usedSlots+" / "+maxSlots+"#a#");
				else
					slots.setText(null);

				// Planet orders
				if(obj.getConstructionQueueSize() > 0) {
					float pct = obj.getConstructionProgress();
					string@ name = obj.getConstructionName(0);
					if (name !is null)
						order.setText("#img:obj_building_yes# "+name+": " + f_to_s(pct * 100.f, 0) + "%");
				}
				else {
					OrderList orders;
					orders.prepare(obj);
					uint ordCnt = orders.getOrderCount();
					bool foundOrder = false;
					for (uint i = 0; i < ordCnt; ++i) {
						Order@ ord = orders.getOrder(i);
						if (ord.isAutomation())
							continue;
						foundOrder = true;
						order.setText(ord.getName());
					}

					if(!foundOrder)
						order.setText(localize("#SY_Idle"));
					orders.prepare(null);
				}
			}

			// Resource overview
			if (int(resText.length()) == stateNum)
				for (int i = 0; i < stateNum; ++i) {
					if (@resText[i] != null) {
						if (stateName[i] == "ShipBay") {
							float used, capacity;
							obj.getShipBayVals(used, capacity);
							resText[i].setText(standardize(used)+"/"+standardize(capacity));
						}
						else {
							float val = 0.f, max = 0.f, req = 0.f, cargo = 0.f;

							if (obj.getStateVals(stateName[i], val, max, req, cargo) && abs(val) > 0.005f)
								resText[i].setText(standardize(val));
							else
								resText[i].setText("0.00");
						}
					}
				}
		}
		else {
			// Planet text
			if (emp is getEmpireByID(-1)) {
				string@ txt = "#c:bbb##font:frank_11#"+obj.getName()+"#font##c#";
				if (planet !is null)
					txt += "\n#c:999#"+localize("#SY_Uncolonized")+" "+planet.getMaxStructureCount()+" "+localize("#SY_Slots")+"#c#";
				text.setText(txt);
			}
			else {
				string@ txt = "#c:"+emp.color.format()+"##font:frank_11#"+obj.getName()+" ("+emp.getName()+")#font##c#";
				if (planet !is null)
					txt += "\n#c:999#"+planet.getMaxStructureCount()+" "+localize("#SY_Slots")+"#c#";
				text.setText(txt);
			}
		}
	}

	EventHandleState OnEvent(const GUIEvent@ evt) {
		switch (evt.EventType) {
			case GEVT_ComboBox_Changed:
				if (evt.Caller is gov) {
					string@ governor = obj.getOwner().getBuildList(gov.getSelected());

					if (@governor != null)
						planet.setGovernorType(governor);
					return EHS_Absorb;
				}
			break;
			case GEVT_Checkbox_Toggled:
				if (evt.Caller is useGov) {
					planet.setUseGovernor(useGov.isChecked());
					return EHS_Absorb;
				}
			break;
			case GEVT_Right_Clicked:
				if (evt.Caller is img) {
					triggerContextMenu(obj);
					return EHS_Absorb;
				}
			break;
			case GEVT_Clicked:
				if (evt.Caller is img) {
					if (ctrlKey) {
						setCameraFocus(obj);
						setGuiFocus(null);
					}
					else {
						if (isSelected(obj)) {
							if (planet !is null)
								triggerPlanetWin(planet, true);
							else
								triggerQueueWin(obj);
						}
						else
							selectObject(obj);
					}
					return EHS_Handled;
				}
				else if (evt.Caller is rem) {
					obj.removeConstruction(0);
					update();
					return EHS_Handled;
				}
				else if (evt.Caller is clear) {
					obj.clearBuildQueue();
					update();
					return EHS_Handled;
				}
				else if (evt.Caller is load) {
					addSingleImportDialog(localize("#PL_QUEUE")+":",
							localize("#load"), "Queues",
							SystemLoadQueue(win, obj));
					return EHS_Handled;
				}
				else if (evt.Caller is repeat) {
					obj.setRepeatQueue(repeat.isPressed());
					return EHS_Handled;
				}
			break;
			case GEVT_Focus_Gained:
				if (evt.Caller is text || evt.Caller is slots || evt.Caller is order || evt.Caller is panel) {
					if (ctrlKey) {
						setGuiFocus(null);
						win.addedPlanets.erase(obj.uid);
						@win.curSys = null;
						update();
					}
					else {
						setGuiFocus(win.plPanel);
					}
					return EHS_Absorb;
				}
				else if (evt.Caller is zoom) {
					setCameraFocus(obj);
					setGuiFocus(null);
					return EHS_Absorb;
				}
			break;
			case GEVT_Mouse_Over:
				if (evt.Caller is zoom) {
					zoom.setColor(opaque);
					return EHS_Absorb;
				}
				else if (evt.Caller is gov) {
					panel.bringToFront();
					gov.bringToFront();
				}
			break;
			case GEVT_Mouse_Left:
				if (evt.Caller is zoom) {
					zoom.setColor(transparent);
					return EHS_Absorb;
				}
			break;
		}
		return EHS_Unhandled;
	}

	void remove() {
		panel.orphan(true);
		panel.remove();
		@win = null;
	}
};
// }}}

SystemWindowHandle@[] wins;

Color transparent;
Color opaque;

Color pinnedCol;
Color unpinnedCol;

dim2di defaultPinnedSize;
dim2di defaultGlobalSize;

void createSystemWindow(System@ sys) {
	uint n = wins.length();
	wins.resize(n+1);
	@wins[n] = SystemWindowHandle(makeScreenCenteredRect(
				sys is null ? defaultGlobalSize : defaultPinnedSize));
	wins[n].bringToFront();

	if (sys !is null) {
		wins[n].setCurSystem(sys);
		wins[n].setPinned(true);
	}
	else {
		wins[n].findSystem();
	}
}

void showSystemWindow(System@ sys) {
	if (sys is null) {
		createSystemWindow(null);
		return;
	}

	// Try to find a window with this system
	for (uint i = 0; i < wins.length(); ++i) {
		if (wins[i].isPinned() && wins[i].getCurSystem() is sys) {
			wins[i].setVisible(true);
			wins[i].bringToFront();
			return;
		}
		
		if (!wins[i].isPinned() && wins[i].getCurSystem() !is sys) {
			wins[i].setVisible(true);
			wins[i].setCurSystem(sys);
			wins[i].setPinned(true);
			wins[i].bringToFront();
			return;
		}
	}

	// If none found, create a new window
	createSystemWindow(sys);
}

void closeSystemWindow(SystemWindow@ win) {
	int index = findSystemWindow(win);
	if (index < 0) return;

	if (wins.length() > 1) {
		wins[index].remove();
		wins.erase(index);
	}
	else {
		wins[index].setVisible(false);
		wins[index].setPinned(false);
	}
	setGuiFocus(null);
}

GuiElement@ getSystemWindow() {
	if (wins.length() == 0)
		return null;
	return wins[0].ele;
}

void toggleSystemWindow() {
	// Toggle all windows to a particular state
	bool anyVisible = false;
	for (uint i = 0; i < wins.length(); ++i)
		if (wins[i].isVisible())
			anyVisible = true;
	toggleSystemWindow(!anyVisible);
}

void toggleSystemWindow(bool show) {
	if (shiftKey || wins.length() == 0) {
		createSystemWindow(null);
	}
	else {
		for (uint i = 0; i < wins.length(); ++i) {
			wins[i].setVisible(show);
			if (show)
				wins[i].bringToFront();
		}
	}
}

bool ToggleSystemWin(const GUIEvent@ evt) {
	if (evt.EventType == GEVT_Clicked) {
		toggleSystemWindow();
		return true;
	}
	return false;
}

bool ToggleSystemWin_key(uint8 flags) {
	if (flags & KF_Pressed != 0) {
		toggleSystemWindow();
		return true;
	}
	return false;
}

int findSystemWindow(SystemWindow@ win) {
	for (uint i = 0; i < wins.length(); ++i)
		if (wins[i].script is win)
			return i;
	return -1;
}

void setSysVisible(bool vis) {
	topbar_system.setVisible(vis);
}

GuiButton@ topbar_system;

void init() {
	// Initialize some constants
	initSkin();

	defaultGlobalSize = dim2di(860, 481);
	defaultPinnedSize = dim2di(860, 481);

	transparent = Color(218, 255, 255, 255);
	opaque = Color(255, 255, 255, 255);

	unpinnedCol = Color(64, 255, 255, 255);
	pinnedCol = Color(218, 128, 128, 255);

	resTooltip.resize(stateNum);
	for (int i = 0; i < stateNum; ++i)
		@resTooltip[i] = localize("#SYR_"+stateName[i]);

	// Bind toggle key
	bindFuncToKey("F4", "script:ToggleSystemWin_key");

	// Bind topbar button
	int scrWidth = getScreenWidth();
	@topbar_system = GuiButton(recti(pos2di(scrWidth / 2+50, 0), dim2di(100, 25)), null, null);
	topbar_system.setSprites("TB_System", 0, 2, 1);
	topbar_system.setAppearance(BA_UseAlpha, BA_Background);
	topbar_system.setAlignment(EA_Center, EA_Top, EA_Center, EA_Top);

	bindGuiCallback(topbar_system, "ToggleSystemWin");
}

void tick(float time) {
	// Update all windows
	for (uint i = 0; i < wins.length(); ++i) {
		if (wins[i].isVisible()) {
			wins[i].update(time);
		}
	}
}

void deinit() {
	for (uint i = 0; i < wins.length(); ++i)
		wins[i].remove();
	wins.resize(0);
}

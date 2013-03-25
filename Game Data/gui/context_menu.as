#include "~/Game Data/gui/include/blueprints_sort.as"
#include "~/Game Data/gui/include/dialog.as"
#include "~/Game Data/gui/include/order_descriptors.as"

import void triggerQueueWin(Object@) from "queue_win";
import void triggerUndockWin(Object@ obj) from "undock_win";
import void buildOnAll(System@, const HullLayout@, int) from "build_on_best";

/* {{{ Main context menu */
GuiContextMenu@ menu;
Object@ clickedObj;
bool addedAny;
bool hasItems;
bool addSeparatorNext;
int menuID;

void init (){
	menuID = reserveGuiID();
	bindGuiCallback(menuID, "delegateContextMenu");
}

void triggerContextMenu(Object@ obj) {
	// Close existing menu
	if (menu !is null ) {
		clearEscapeEvent(menu);
		menu.remove();

		if (clickedObj is obj) {
			@clickedObj = null;
			@menu = null;
			return;
		}
	}

	// Save the object that was clicked
	@clickedObj = obj;
	addedAny = false;
	hasItems = false;
	addSeparatorNext = false;

	// Create the root context menu
	pos2di mousePos = getMousePosition();
	recti menuPos = recti(mousePos + pos2di(1, 0), dim2di(100, 400));

	@menu = GuiContextMenu(menuPos, null);
	menu.setID(menuID);

	bindEscapeEvent(menu);

	resetManagers();
	addManager(menu);

	// Get the selected object
	Object@ selObj = getSelectedObject(getSubSelection());
	if (selObj is null)
		@selObj = clickedObj;

	// Add all the actions
	addGeneralOrders(menu, selObj, clickedObj);
	addToolMenu(menu, selObj, clickedObj);
	addSeperatorIfNecessary(menu);

	addGalacticCommands(menu, selObj, clickedObj);
	addSeperatorIfNecessary(menu);

	addGovernorMenu(menu, selObj, clickedObj);
	addSeperatorIfNecessary(menu);

	addShipsMenu(menu, selObj, clickedObj);
	addStructuresMenu(menu, selObj, clickedObj);
	addSeperatorIfNecessary(menu);

	addSelectionCommands(menu, selObj, clickedObj);
	addSeperatorIfNecessary(menu);

	addDockingMenu(menu, selObj, clickedObj);
	addSeperatorIfNecessary(menu);

	addJoinFleetMenu(menu, selObj, clickedObj);
	addFleetActions(menu, selObj, clickedObj);
	addSeperatorIfNecessary(menu);

	addAutomationOrders(menu, selObj, clickedObj);
	addSeperatorIfNecessary(menu);

	// If no items were added, don't do anything
	if (!hasItems) {
		clearEscapeEvent(menu);
		menu.remove();

		@menu = null;
		@clickedObj = null;
	}
}

bool isContextMenuUp() {
	return menu !is null;
}

void addItem(GuiContextMenu@ menu, string@ name, ContextClickedAction@ act) {
	addItem(menu, name, ContextClickedActionCallback(act));
}

void addItem(GuiContextMenu@ menu, string@ name, ContextTowardsAction@ act) {
	addItem(menu, name, ContextTowardsActionCallback(act));
}

void addItem(GuiContextMenu@ menu, string@ name, ContextOrderAction@ act) {
	addItem(menu, name, ContextOrderActionCallback(act));
}


void addItem(GuiContextMenu@ menu, string@ name, ContextFleetOrderAction@ act) {
	addItem(menu, name, ContextFleetOrderActionCallback(act));
}

void addItem(GuiContextMenu@ menu, string@ name, ContextCallback@ act) {
	addItem(menu, name, act, false);
}

void addItem(GuiContextMenu@ menu, string@ name, ContextCallback@ act, bool checked) {
	if (addSeparatorNext) {
		addSeparator(menu);
		addSeparatorNext = false;
	}

	menu.addItem(name, 0, true, false, checked);
	addCallback(menu, act);

	addedAny = true;
	hasItems = true;
}

void addSeparator(GuiContextMenu@ menu) {
	menu.addItem(null, 0, true, false, false);
	addCallback(menu, null);
}

void addSeperatorIfNecessary(GuiContextMenu@ menu) {
	if (addedAny)
		addSeparatorNext = true;
	addedAny = false;
}

GuiContextMenu@ addSubMenu(GuiContextMenu@ menu, string@ name, ContextCallbackManager@ manager) {
	if (addSeparatorNext) {
		addSeparator(menu);
		addSeparatorNext = false;
	}

	int i = menu.addItem(name, 0, true, true, false);
	GuiContextMenu@ submenu = menu.getSubMenu(i);
	submenu.setID(menuID);
	if (manager !is null)
		addManager(submenu, manager);
	else
		addManager(submenu);

	addCallback(menu, null);
	addedAny = true;
	hasItems = true;
	return submenu;
}

bool delegateContextMenu(const GUIEvent@ evt) {
	switch (evt.EventType) {
		// Drop pointers when menu is closed
		case GEVT_Closed:
			if (menu !is null) {
				clearEscapeEvent(menu);
				menu.remove();
				@menu = null;
			}
			@clickedObj = null;
		break;
		// Delegate the callback to the right menu
		case GEVT_Menu_Item_Selected:
			doCallback(evt.Caller.toGuiContextMenu(), clickedObj);

			if (menu !is null) {
				clearEscapeEvent(menu);
				menu.remove();
				@menu = null;
			}
			@clickedObj = null;
		break;
	}
	return false;
}
/* }}} */
/* {{{ Action types */
/*   {{{ Action checks */
// Check whether we can attack this empire
bool canAttack(Empire@ emp) {
	if (!emp.isValid()) {
		return true;
	}
	Empire@ us = getActiveEmpire();
	if (emp is us) {
		return true;
	}
	return us.isEnemy(emp);
}

// Check whether this object can construct things
bool canConstruct(Object@ obj) {
	Planet@ planet = obj;
	if (planet !is null)
		return true;

	HulledObj@ ship = obj;
	if (ship !is null) {
		const HullLayout@ layout = ship.getHull();
		return layout.hasSystemWithTag("BuildBay");
	}

	return false;
}

// Check whether this object has weapons
bool hasWeapons(Object@ obj) {
	Planet@ planet = obj;
	if (planet !is null) {
		return planet.hasStructureWithTag("Weapon");
	}

	HulledObj@ ship = obj;
	if (ship !is null) {
		const HullLayout@ layout = ship.getHull();
		return layout.hasSystemWithTag("Weapon");
	}

	return false;
}
/*   }}} */
/*   {{{ General Orders */
// Order an attack
void attack(OrderList& orders, Object@ from, Object@ to, bool activeFleetMember) {
	if (!activeFleetMember || ctrlKey)
		orders.giveAttackOrder(to, ctrlKey, true, shiftKey);
}

// Prompt to force an attack
class GiveForceAttackOrder : SelectedCallback {
	Object@ obj;
	GiveForceAttackOrder(Object@ attack) {
		@obj = attack;
	}

	void act(Object@ selected) {
		OrderList orders;
		if (orders.prepare(selected)) {
			orders.giveAttackOrder(obj, true, true, shiftKey);
		}
	}
}

class ConfirmForceAttack : ConfirmDialogCallback {
	Object@ obj;
	ConfirmForceAttack(Object@ attack) {
		@obj = attack;
	}

	void call(ConfirmDialog@ dialog, bool choice) {
		if (choice)
			doForEachSelectedObject(GiveForceAttackOrder(obj), true);
	}
}

void promptForceAttack(Object@ clicked) {
	if (ctrlKey) {
		doForEachSelectedObject(GiveForceAttackOrder(clicked), true);
	}
	else {
		addConfirmDialog(localize("#RM_PromptForceAttack"),
						 localize("#RM_DoForceAttack"),
						 localize("#cancel"),
						 ConfirmForceAttack(clicked));
	}
}

// Prompt to declare war and attack
class ConfirmDeclareWar : ConfirmDialogCallback {
	Object@ obj;
	ConfirmDeclareWar(Object@ attack) {
		@obj = attack;
	}

	void call(ConfirmDialog@ dialog, bool choice) {
		if (choice) {
			TreatyFactory@ factory = TreatyFactory(getActiveEmpire(),
													obj.getOwner());
			factory.treaty.addClause("war", false);
			factory.propose();

			doForEachSelectedObject(GiveForceAttackOrder(obj), true);
		}
	}
}

void promptDeclareAttack(Object@ clicked) {
	Empire@ other = clicked.getOwner();
	string@ name = combine("#c:", other.color.format(),
			 			   "#", other.getName(), "#c#");

	string@ line = combine(localize("#RM_NotAtWar"), name, ".");
	@line = combine(line, "\n\n", localize("#RM_DeclareWarToAttack"));

	addConfirmDialog(line,
					 localize("#RM_DoDeclareWar"),
					 localize("#cancel"),
					 ConfirmDeclareWar(clicked));
}

// Guard an object
void guard(OrderList& orders, Object@ from, Object@ to, bool activeFleetMember) {
	if (!activeFleetMember || ctrlKey)
		orders.giveGuardOrder(to, shiftKey);
}

// Scuttle here
void scuttle(OrderList& orders, Object@ from, Object@ to, bool activeFleetMember) {
	if (!activeFleetMember || ctrlKey)
		orders.giveScuttleOrder(to, shiftKey);
}

// Retrofit here
void retrofit(OrderList& orders, Object@ from, Object@ to, bool activeFleetMember) {
	if (!activeFleetMember || ctrlKey)
		orders.giveRetrofitOrder(to, shiftKey);
}

// Move to an object
void moveTo(OrderList& orders, Object@ from, Object@ to, bool activeFleetMember) {
	if (!activeFleetMember || ctrlKey)
		orders.giveGotoOrder(to, shiftKey);
}

// Move to a system
void moveToSys(OrderList& orders, Object@ from, Object@ to, bool activeFleetMember) {
	if (!activeFleetMember || ctrlKey)
		orders.giveGotoOrder(to.getCurrentSystem(), shiftKey);
}

// Supply an object
void assignSupply(OrderList& orders, Object@ from, Object@ to, bool activeFleetMember) {
	orders.giveSupplyResourceOrder(to, ctrlKey, shiftKey);
}

const string@ strMtl = "Metals";
void mtlSupply(OrderList& orders, Object@ from, Object@ to, bool activeFleetMember) {
	orders.giveSupplyResourceOrder(to, strMtl, ctrlKey, shiftKey);
}

const string@ strElc = "Electronics";
void elcSupply(OrderList& orders, Object@ from, Object@ to, bool activeFleetMember) {
	orders.giveSupplyResourceOrder(to, strElc, ctrlKey, shiftKey);
}

const string@ strAdv = "AdvParts";
void advSupply(OrderList& orders, Object@ from, Object@ to, bool activeFleetMember) {
	orders.giveSupplyResourceOrder(to, strAdv, ctrlKey, shiftKey);
}

// Build a transfer order
class TransferResources : SelectedCallback {
	Object@ transferTo;
	bool take;
	bool all;
	float amount;
	string@ resource;

	TransferResources(string@ res, float Amount,
			bool Take, bool All, Object@ obj) {
		@resource = res;
		amount = Amount;
		take = Take;
		all = All;
		@transferTo = obj;
	}

	void act(Object@ selected) {
		OrderList list;
		if (list.prepare(selected)) {

			int mode = 0;
			if (take)
				mode = mode | TM_From;
			if (all) {
				mode = mode | TM_Percent;
				amount = 1.f;
			}
			
			if(resource == "Helium 3")
				@resource = "H3";

			list.giveTransferOrder(transferTo, resource,
					mode, amount, shiftKey);
		}
	}
};

class TransferCallback : OptionDialogCallback {
	Object@ transferTo;

	TransferCallback(Object@ to) {
		@transferTo = to;
	}

	void call(OptionDialog@ dialog, bool success) {
		if (!success)
			return;

		// Retrieve options
		string@ resource = dialog.getComboOption(0);
		string@ textAmount = dialog.getTextOption(1);
		bool take = dialog.getCheckBoxOption(2);

		// Parse amount to transfer
		float amount = 0.f;
		bool transferAll = false;
		if (textAmount == "All")
			transferAll = true;
		else
			amount = s_to_f(textAmount);

		// Do the transfer
		TransferResources@ cb =
			TransferResources(resource, amount, take, transferAll, transferTo);
		doForEachSelectedObject(cb, true);
	}
};

void transfer(Object@ clicked) {
	// Create a dialog to enter transfer options
	TransferCallback@ cb = TransferCallback(clicked);
	string@ text = localize("#OC_Transfer");
	OptionDialog@ dialog = addOptionDialog(text, cb);

	dialog.addResourceOption(localize("#OC_Resource"), null, true, false);
	dialog.addTextOption(localize("#OC_Amount"), "All");
	dialog.addCheckBoxOption(localize("#OC_TakeFrom"), false);
	dialog.fitChildren();
}

// Set rally point
void setRallyPoint(Object@ obj, Object@ point) {
	// Don't set rally point for clicked object
	if (obj is null)
		return;

	// Check if this is a system
	System@ sys = obj;
	if (obj.toStar() !is null)
		@sys = obj.getCurrentSystem();

	// Rallies to stars are to systems
	if (point !is null && point.toStar() !is null)
		@point = point.getParent();
	if (sys !is null)
		sys.toObject().setRally(point);
	else
		obj.setRally(point);
}

void setRally(Object@ from, Object@ to) {
	setRallyPoint(from, to);
}

void unRally(Object@ from, Object@ to) {
	setRallyPoint(from, null);
}

void parkHere(OrderList& orders, Object@ from, Object@ to, bool activeFleetMember) {
	if (from !is null && from.canMoveSelf())
		from.setParked(true);
	if (!activeFleetMember || ctrlKey)
		orders.giveGotoOrder(to, shiftKey);
}

void park(Object@ from, Object@ to) {
	if (from !is null && from.canMoveSelf())
		from.setParked(true);
}

void unPark(Object@ from, Object@ to) {
	if (from !is null && from.canMoveSelf())
		from.setParked(false);
}

// Add general order options
void addGeneralOrders(GuiContextMenu@ menu, Object@ from, Object@ to) {
	// General orders can only be given to our own ships and planets
	if (from is null || from.getOwner() !is getActiveEmpire())
		return;

	// Collect some data
	Empire@ us = getActiveEmpire();
	Empire@ them = to.getOwner();

	// Data about the selected object
	bool ship = from.toHulledObj() !is null;
	bool weapons = hasWeapons(from);
	bool canMove = from.canMoveSelf();
	bool construction = canConstruct(from);
	bool same = from is to;

	bool hasResources = false;
	if (from.toPlanet() !is null)
		hasResources = true;
	else
		hasResources = ship && from.toHulledObj().getHull().hasSystemWithTag("Storage:Resources");

	// Data about the targetted object
	bool ours = us is them;
	bool hasConstruction = ours && canConstruct(to);
	bool attackable = canAttack(to.getOwner());
	bool friendly = ours || !us.isEnemy(them);
	bool peace = us.hasTreatyTag(them, "peace");
	bool clickedSystem = to.toSystem() !is null;

	bool resources = false;
	if (to.toPlanet() !is null)
		resources = true;
	else
		resources = to.toHulledObj() !is null && to.toHulledObj().getHull().hasSystemWithTag("Storage:Resources");

	// Offensive actions can only be taken on enemies, space or ourselves
	if (weapons && attackable && !same && !clickedSystem) {
		if (!them.isValid() || ours)
			addItem(menu, localize("#RM_Attack"), promptForceAttack);
		else
			addItem(menu, localize("#RM_Attack"), attack);
	}

	// Attack order that prompts to declare war
	if (weapons && !attackable && friendly && !peace && !same && !clickedSystem) {
		addItem(menu, localize("#RM_Attack"), promptDeclareAttack);
	}

	// Movement actions
	if (canMove && !same) {
		addItem(menu, localize("#RM_MoveTo"), moveTo);
		addItem(menu, localize("#RM_MoveToSys"), moveToSys);

		if (friendly && !clickedSystem) {
			addItem(menu, localize("#RM_Guard"), guard);
		}
	}

	// Transfer order
	if (ours && !same) {
		addItem(menu, localize("#RM_Transfer"), transfer);
	}

	// Construction orders
	if (ship && hasConstruction && !same) {
		addItem(menu, localize("#RM_Retrofit"), retrofit);
		addItem(menu, localize("#RM_Scuttle"), scuttle);
	}

	// Supply repeat order
	if (hasResources && resources && !same && ours) {
		string@ text = localize("#RM_AssignSupply")+"...";
		GuiContextMenu@ supplyMenu = addSubMenu(menu, text, null);

		addItem(supplyMenu, localize("#OI_Construction"), assignSupply);
		addSeparator(supplyMenu);
		addItem(supplyMenu, localize("#metals"), mtlSupply);
		addItem(supplyMenu, localize("#electronics"), elcSupply);
		addItem(supplyMenu, localize("#advparts"), advSupply);
	}

	// Rally point
	if (construction) {
		Object@ rally = from.getRally();

		// Rallies to stars are to systems
		if (to.toStar() !is null && rally is to.getParent())
			@rally = to;

		// Check which rally options to display
		if (from is to) {
			if (rally !is null)

				addItem(menu, localize("#RM_DeRally"), unRally);
		}
		else {
			if (to !is rally)
				addItem(menu, localize("#RM_Rally"), setRally);
			else
				addItem(menu, localize("#RM_DeRally"), unRally);
		}
	}

	// Toggle Parked
	if (canMove) {
		Planet@ otherPlanet = to;
		if (isSelected(to) || otherPlanet is null) {
			bool parked = from.isParked();
			string@ text = localize("#RM_Park");

			if (parked)
				addItem(menu, text, ContextTowardsActionCallback(unPark), true);
			else
				addItem(menu, text, ContextTowardsActionCallback(park), false);
		}
		else if (otherPlanet !is null) {
			string@ text = localize("#RM_ParkHere");
			addItem(menu, text, parkHere);
		}
	}
}
/*   }}} */
/*   {{{ Use Tool Orders */
string@ strTool = "Tool:", strWeapon = "Weapon", strSafeTool = "SafeTool";
void getTools(HulledObj@ from, Object@ target, string@[]& tools, bool[]& needForce) {
	const HullLayout@ layout = from.getHull();

	dictionary toolDict;
	dictionary forcedTools;
	uint subsysCnt = layout.getSubSysCnt();
	for (uint i = 0; i < subsysCnt; ++i) {
		const subSystemDef@ def = layout.getSubSys(i).type;
		uint tagCnt = def.getTagCount();
		for (uint j = 0; j < tagCnt; ++j) {
			string@ tag = def.getTag(j);
			if (tag.find(strTool) == 0) {
				toolDict.set(tag, 1);

				if (def.hasTag(strWeapon) && !def.hasTag(strSafeTool))
					forcedTools.set(tag, 1);
				else
					forcedTools.set(tag, 0);
			}
		}
	}

	toolDict.resetIter();
	uint n = 0;
	string@ cur = "";
	tools.resize(0);
	do {
		if (!toolDict.getCurrentName(cur))
			break;

		string@ tool = cur.substr(strTool.length(), cur.length()-strTool.length());
		if (target !is null && !from.canUseToolOn(tool, target))
			continue;

		int64 force = 0;
		forcedTools.get(cur, force);

		tools.resize(n+1);
		needForce.resize(n+1);
		@tools[n] = tool;
		needForce[n] = force != 0 && !from.willAutoUseToolOn(tool, target);
		++n;
	}
	while (toolDict.advance());
	tools.resize(n);
}

class ContextToolActor : SelectedCallback {
	string@ tool;
	Object@ clicked;

	ContextToolActor(string@ Tool, Object@ Clicked) {
		@clicked = Clicked;
		@tool = Tool;
	}

	void act(Object@ selected) {
		if (selected.getOwner() is getActiveEmpire()) {
			OrderList orders;
			if (orders.prepare(selected))
				orders.giveUseToolOrder(tool, clicked, true, true, shiftKey);
		}
	}
}

class ConfirmForceTool : ConfirmDialogCallback {
	ContextToolActor@ actor;
	ConfirmForceTool(ContextToolActor@ Actor) {
		@actor = Actor;
	}

	void call(ConfirmDialog@ dialog, bool choice) {
		if (choice)
			doForEachSelectedObject(actor, true);
	}
}

class ContextToolActionCallback : ContextCallback {
	string@ tool;
	Object@ clicked;
	bool needForce;

	ContextToolActionCallback(string@ Tool, Object@ Clicked, bool NeedForce) {
		@clicked = Clicked;
		@tool = Tool;
		needForce = NeedForce;
	}


	void act(Object@ clicked) {
		ContextToolActor@ actor = ContextToolActor(tool, clicked);

		if (needForce && !ctrlKey) {
			addConfirmDialog(localize("#RM_PromptForceAttack"),
							 localize("#RM_DoForceAttack"),
							 localize("#cancel"),
							 ConfirmForceTool(actor));
		}
		else {
			doForEachSelectedObject(actor, true);
		}
	}
}

string@ getToolLocalization(string@ tool, bool inMenu) {
	string@ name = localize("#RM_Use_"+tool);
	if (name.beginsWith("#")) {
		name = localize("#TL_"+tool);

		if (name.beginsWith("#"))
			name = tool;

		if (!inMenu)
			name = combine(localize("#RM_UseTool"), " ", name);
	}
	return name;
}

void addToolMenu(GuiContextMenu@ menu, Object@ from, Object@ to) {
	// Only use tools with our ships
	if (from is null || from.getOwner() !is getActiveEmpire())
		return;

	// Only use tools with ships
	HulledObj@ ship = from;
	if (ship is null)
		return;

	string@[] tools;
	bool[] needForce;
	getTools(ship, to, tools, needForce);

	// Check that we have tools
	if (tools.length() == 0)
		return;

	// Single tools are added directly
	if (tools.length() == 1) {
		ContextToolActionCallback@ cb =
			ContextToolActionCallback(tools[0], to, needForce[0]);

		addItem(menu, getToolLocalization(tools[0], false), cb);
	}
	// Multiple tools are added in a menu
	else {
		string@ text = localize("#RM_UseTool");
		GuiContextMenu@ subMenu = addSubMenu(menu, text, null);

		uint cnt = tools.length();
		for (uint i = 0; i < cnt; ++i) {
			ContextToolActionCallback@ cb =
				ContextToolActionCallback(tools[i], to, needForce[i]);

			addItem(subMenu, getToolLocalization(tools[i], true), cb);
		}
	}
}
/*   }}} */
/*   {{{ Galactic Commands */
void autoColonize(Object@ from, Object@ to) {
	// Use the correct object
	Object@ obj = from;
	if (obj is null)
		@obj = to;

	// Find the system
	System@ sys = obj;
	if (obj.toStar() !is null)
		@sys = obj.getCurrentSystem();

	// Colonize the system
	if (sys !is null) {
		getActiveEmpire().autoColonize(sys);
	}
}

void autoColonizePlanet(Object@ clicked) {
	Planet@ pl = clicked;
	Empire@ emp = getActiveEmpire();

	bool colonizing = emp.isColonizing(pl);
	emp.setColonizing(pl, !colonizing);
}

void supplyOnce(Object@ clicked) {
	Empire@ emp = getActiveEmpire();

	// Supply construction projects
	emp.supplyConstruction(clicked, true);

	// Supply essential resources
	if (clicked.toHulledObj() !is null) {
		emp.supplyResource(clicked, "Fuel", true);
		emp.supplyResource(clicked, "Ammo", true);
	}
}

void assaultSystem(Object@ selected, Object@ to) {
	if (selected is null)
		return;

	// Get the system we're ordering
	System@ sys = selected;
	if (selected.toStar() !is null)
		@sys = selected.getCurrentSystem();

	System@ toSys = to;
	if (to.toStar() !is null)
		@toSys = to.getCurrentSystem();

	if (sys is null)
		return;

	// Order all our military ships to attack
	Empire@ emp = getActiveEmpire();

	OrderList orders;
	SysObjList list;
	list.prepare(sys);

	uint cnt = list.childCount;
	for (uint i = 0; i < cnt; ++i) {
		Object@ child = list.getChild(i);
		HulledObj@ ship = child;

		if (ship is null || !ship.isMilitary() || child.getOwner() !is emp)
			continue;
		
		if (orders.prepare(child)) {
			orders.giveGotoOrder(toSys, shiftKey);
			if (!ctrlKey)
				orders.giveGotoOrder(sys, true);
		}
	}
}

void addGalacticCommands(GuiContextMenu@ menu, Object@ from, Object@ to) {
	// Check if this is a system we're ordering
	System@ sys = to;
	if (to.toStar() !is null)
		@sys = to.getCurrentSystem();

	System@ sysFrom = from;
	if (from.toStar() !is null)
		@sysFrom = from.getCurrentSystem();

	Planet@ pl = to;

	// Auto-colonize
	if (sys !is null) {
		addItem(menu, localize("#RM_auto_colony_sys"), autoColonize);
	}

	// Auto-colonize planet
	if (pl !is null && !to.getOwner().isValid()) {
		string@ text = localize("#RM_auto_colony");
		ContextCallback@ cb = ContextClickedActionCallback(autoColonizePlanet);
		bool checked = getActiveEmpire().isColonizing(pl);

		addItem(menu, text, cb, checked);
	}

	// Give Supplies
	if (to.getOwner() is getActiveEmpire() && to.getConstructionQueueSize() > 0) {
		addItem(menu, localize("#RM_Supply"), supplyOnce);
	}

	// System assault
	if (sysFrom !is null && sys !is null && sys !is sysFrom) {
		addItem(menu, localize("#RM_Assault"), assaultSystem);
	}

	// System rally points
	if (sysFrom !is null) {
		if (sysFrom !is sys)
			addItem(menu, localize("#RM_Rally"), setRally);
		addItem(menu, localize("#RM_DeRally"), unRally);
	}
}
/*   }}} */
/*   {{{ Governor Selection */
class GovernorMenu : ContextCallbackManager {
	GuiContextMenu@ menu;
	Planet@ pl;
	string@[] governors;

	GovernorMenu(Planet@ forObj) {
		@pl = forObj;
	}

	void init(GuiContextMenu@ Menu) {
		@menu = Menu;

		// Collect possible governors
		Empire@ emp = getActiveEmpire();
		bool hasGovernor = pl.usesGovernor();
		string@ governor = pl.getGovernorType();

		// Add item for toggling the governor
		menu.addItem(localize("#RM_Enabled"), 0, true, false, hasGovernor);
		menu.addItem(null, 0, true, false, false);

		// Add governors
		int cnt = emp.getBuildListCount();
		governors.resize(cnt);
		for (int i = 0; i < cnt; ++i) {
			// Get build list name
			string@ name = emp.getBuildList(i);
			if (name is null)
				continue;

			// Check if this is selected
			bool selected = governor == name;

			// Add to list
			@governors[i] = name;

			// Localize build list
			string@ text = localize("#PG_"+name);
			if (text.beginsWith("#"))
				@text = name;

			// Add item
			menu.addItem(text, 0, true, false, selected);
		}
	}

	GuiContextMenu@ getMenu() {
		return menu;
	}

	void add(ContextCallback@ cb) {
		// Not supported
	}

	void call(uint i, Object@ clicked) {
		// Check for clicks on "enabled"
		if (i == 0) {
			pl.setUseGovernor(!pl.usesGovernor());
			return;
		}

		// Check for clicked governor
		i -= 2;
		if (i >= governors.length())
			return;

		string@ governor = governors[i];
		pl.setGovernorType(governor);
		pl.setUseGovernor(true);
	}
};

void addGovernorMenu(GuiContextMenu@ menu, Object@ from, Object@ to) {
	// Check we clicked something sensible
	if (to is null)
		return;

	// Can only change governors on owned objects
	if (to.getOwner() !is getActiveEmpire())
		return;

	// Can only change governors on planets
	Planet@ pl = to;
	if (pl is null)
		return;

	// Create the callback
	GovernorMenu@ cb = GovernorMenu(to);

	// Add structures menu
	string@ text = localize("#RM_Governor");
	GuiContextMenu@ buildStructs = addSubMenu(menu, text, cb);
}
/*   }}} */
/*   {{{ Build Ships */
class BuildOnSelected : SelectedCallback {
	const HullLayout@ layout;
	uint amount;
	bool batch;
	bool all;

	BuildOnSelected(const HullLayout@ lay, uint count, bool doBatch, bool All) {
		@layout = lay;
		amount = count;
		batch = doBatch;
		all = All;
	}

	void act(Object@ sel) {
		// Check if this is a system we're ordering
		System@ sys = sel;
		if (sel.toStar() !is null)
			@sys = sel.getCurrentSystem();

		if (sys !is null) {
			if (all)
				buildOnAll(sys, layout, amount);
			else
				buildOnBest(sys, layout, amount);
		}
		else if (sel.getOwner() !is getActiveEmpire()) {
			return;
		}
		else if (canConstruct(sel)) {
			sel.makeShip(layout, amount, batch);
		}
	}
};

class MultibuildSelected : MultibuildCallback {
	bool all;
	MultibuildSelected(bool All) {
		all = All;
	}

	void act(const HullLayout@ layout, uint amount, bool batch) {
		doForEachSelectedObject(BuildOnSelected(layout, amount, batch, all), true);
	}
};

class MultibuildAll : MultibuildCallback {
	System@ sys;
	MultibuildAll(System@ Sys) {
		@sys = Sys;
	}

	void act(const HullLayout@ layout, uint amount, bool batch) {
		buildOnAll(sys, layout, amount);
	}
};

class BuildShipMenu : ContextCallbackManager {
	GuiContextMenu@ menu;
	SortedBlueprintList layouts;
	bool buildAll;

	BuildShipMenu() {
		buildAll = false;
	}

	void init(GuiContextMenu@ Menu) {
		@menu = Menu;

		layouts.update(getActiveEmpire(), true);
		uint cnt = layouts.length();
		for (uint i = 0; i < cnt; ++i) {
			menu.addItem(layouts.getText(i), 0, true, false, false);
		}
	}

	GuiContextMenu@ getMenu() {
		return menu;
	}

	void add(ContextCallback@ cb) {
		// Not supported
	}

	void call(uint i, Object@ clicked) {
		const Empire@ emp = getActiveEmpire();
		// Get the correct layout
		const HullLayout@ lay = layouts.getLayout(i);

		if (lay is null)
			return;
			
		//Dont allow the build if there is not enough rate for import dock
		if(lay.hasSystemWithTag("ImportBay")) {
			const HullStats@ stats = lay.getStats();
			float rate = stats.getHint("Local/ImportTrade");
			float emprate = emp.getStat("importer");
			
			if(rate > emprate)			
				return;
		}				

		// Check if this is a system we're ordering
		System@ sys = clicked;
		if (clicked.toStar() !is null)
			@sys = clicked.getCurrentSystem();

		// Get amount to build
		uint amount = shiftKey ? 5 : 1;

		// Build the correct way
		if ((sys is null) ? !isSelected(clicked) : (!isSelected(sys) && !isSelected(clicked))) {
			if (ctrlKey) {
				if (sys !is null) {
					if (buildAll) {
						multiBuild(MultibuildAll(sys), lay, false);
					}
					else {
						multiBuild(sys, lay);
					}
				}
				else {
					multiBuild(clicked, lay);
				}
			}
			else {
				if (sys !is null) {
					if (buildAll) {
						buildOnAll(sys, lay, amount);
					}
					else {
						buildOnBest(sys, lay, amount);
					}
				}
				else {
					clicked.makeShip(lay, amount);
				}
			}
		}
		else if (ctrlKey) {
			if (sys !is null)
				multiBuild(MultibuildSelected(buildAll), lay, false);
			else
				multiBuild(MultibuildSelected(false), lay, true);
		}
		else {
			doForEachSelectedObject(BuildOnSelected(lay, amount, false, buildAll), true);
		}
	}
};

void manageQueue(Object@ clicked) {
	triggerQueueWin(clicked);
}

void addShipsMenu(GuiContextMenu@ menu, Object@ from, Object@ to) {
	// Check we clicked something sensible
	if (to is null)
		return;

	// Check if this is a system we're ordering
	System@ sys = to;
	if (to.toStar() !is null)
		@sys = to.getCurrentSystem();
		
	// Can only construct on owned objects
	if (sys is null) {
		if (to.getOwner() !is getActiveEmpire())
			return;

		// Check that it has construction capabilities
		if (!canConstruct(to))
			return;
	}
	else {
		// We need planets in here to construct
		if (!sys.hasPlanets(getActiveEmpire()))
			return;
	}

	// Add manage queue item
	if (sys is null) {
		addItem(menu, localize("#RM_ManageQueue"), manageQueue);
	}

	// Get the correct text to use
	string@ text;
	if (sys !is null)
		@text = localize("#RM_BuildShipsBest");
	else
		@text = localize("#RM_BuildShips");

	// Create the callback
	BuildShipMenu@ cb = BuildShipMenu();

	// Add ships menu
	GuiContextMenu@ buildShips = addSubMenu(menu, text, cb);

	// Build ships on all menu
	if (sys !is null) {
		@text = localize("#RM_BuildShipsAll");
		@cb = BuildShipMenu();
		cb.buildAll = true;

		addSubMenu(menu, text, cb);
	}
}
/*   }}} */
/*   {{{ Build Structures */
class BuildStructuresMenu : ContextCallbackManager {
	GuiContextMenu@ menu;
	uint[] buildIDs;
	Object@ obj;

	BuildStructuresMenu(Object@ forObj) {
		@obj = forObj;
	}

	void init(GuiContextMenu@ Menu) {
		@menu = Menu;

		// Collect possible structures
		Empire@ emp = getActiveEmpire();
		uint sysCnt = emp.getSubSysDataCnt();
		buildIDs.resize(sysCnt);
		uint j = 0;

		for (uint i = 0; i < sysCnt; ++i) {
			const subSystemDef@ def = emp.getSubSysData(i).type;
			if (def.canBuildOn(obj)) {
				
				menu.addItem(def.getName(), 0, true, false, false);
				buildIDs[j++] = def.ID;
			}
		}

		buildIDs.resize(j);
	}

	GuiContextMenu@ getMenu() {
		return menu;
	}

	void add(ContextCallback@ cb) {
		// Not supported
	}

	void call(uint i, Object@ clicked) {
		if (i >= buildIDs.length())
			return;

		const subSystemDef@ def = getSubSystemDefByID(buildIDs[i]);
	
		if (ctrlKey) {
			multiBuild(obj.toPlanet(), def);
		}
		else {
			int buildCount = shiftKey ? 5 : 1;
			obj.toPlanet().buildStructure(def, buildCount);
		}
	}
};

void addStructuresMenu(GuiContextMenu@ menu, Object@ from, Object@ to) {
	// Check we clicked something sensible
	if (to is null)
		return;

	// Can only construct on owned objects
	if (to.getOwner() !is getActiveEmpire())
		return;

	// Can only construct on planets
	Planet@ pl = to;
	if (pl is null)
		return;

	// Check that we have any slots left
	if (pl.getStructureCount() >= uint(pl.getMaxStructureCount()))
		return;

	// Create the callback
	BuildStructuresMenu@ cb = BuildStructuresMenu(to);

	// Add structures menu
	string@ text = localize("#RM_BuildStructs");
	GuiContextMenu@ buildStructs = addSubMenu(menu, text, cb);
}
/*   }}} */
/*   {{{ Selection Commands */
void selectSystem(Object@ clicked) {
	if (!shiftKey)
		selectObject(null);
	addSelectedObject(clicked.getCurrentSystem());
}

void selectType(Object@ clicked, bool military) {
	System@ sys = clicked.getCurrentSystem();
	Empire@ emp = getActiveEmpire();

	if (!shiftKey)
		selectObject(null);

	SysObjList list;
	list.prepare(sys);

	uint cnt = list.childCount;
	for (uint i = 0; i < cnt; ++i) {
		Object@ obj = list.getChild(i);
		HulledObj@ ship = obj;

		if (ship is null || obj.getOwner() !is emp)
			continue;

		if (ship.isMilitary() != military)
			continue;

		addSelectedObject(ship);
	}
}

void selectCombat(Object@ clicked) {
	selectType(clicked, true);
}

void selectCivilian(Object@ clicked) {
	selectType(clicked, false);
}

void selectHull(Object@ clicked) {
	HulledObj@ hulled = clicked;
	if (hulled is null)
		return;

	System@ sys = clicked.getCurrentSystem();
	Empire@ emp = getActiveEmpire();
	const HullLayout@ layout = hulled.getHull().getLatestVersion();

	if (!shiftKey)
		selectObject(null);

	SysObjList list;
	list.prepare(sys);

	uint cnt = list.childCount;
	for (uint i = 0; i < cnt; ++i) {
		Object@ obj = list.getChild(i);
		HulledObj@ ship = obj;

		if (ship is null || obj.getOwner() !is emp)
			continue;

		if (ship.getHull().getLatestVersion() !is layout)
			continue;

		addSelectedObject(ship);
	}
}

void addSelectionCommands(GuiContextMenu@ menu, Object@ from, Object@ to) {
	// Check if this is a system we're ordering
	System@ sys = to;
	if (to.toStar() !is null)
		@sys = to.getCurrentSystem();

	// Command to select the system
	if (sys is null || to.toStar() !is null) {
		addItem(menu, localize("#RM_select_sys"), selectSystem);
	}

	// System selection commands
	if (sys !is null) {
		addItem(menu, localize("#RM_select_combat"), selectCombat);
		addItem(menu, localize("#RM_select_civ"), selectCivilian);
	}

	// Check if this is a ship
	HulledObj@ ship = to;
	if (ship !is null && to.getOwner() is getActiveEmpire()) {
		const HullLayout@ lay = ship.getHull().getLatestVersion();
		string@ text = localize("#RM_SelectType")+lay.getName();
		addItem(menu, text, selectHull);
	}
}
/*   }}} */
/*   {{{ Docking Commands */
class DockingMenu : ContextCallbackManager {
	Object@ clicked;
	GuiContextMenu@ menu;
	string[] items;

	DockingMenu(Object@ Clicked) {
		@clicked = Clicked;
	}

	void init(GuiContextMenu@ Menu) {
		@menu = Menu;

		// Static commands
		menu.addItem(localize("#RM_ManageDocked"), 0, true, false, false);
		menu.addItem(localize("#RM_UndockAll"), 0, true, false, false);
		menu.addItem(null, 0, true, false, false);

		// List of docked objects
		dictionary ships;
		ObjDockedList list;
		list.prepare(clicked);

		uint cnt = list.childCount;
		for (uint i = 0; i < cnt; ++i) {
			HulledObj@ docked = list.getChild(i);
			if (docked is null)
				continue;

			const HullLayout@ lay = docked.getHull().getLatestVersion();
			string@ name = lay.getName();

			if (ships.exists(name)) {
				uint num;
				ships.get(name, num);
				ships.set(name, num+1);
			}
			else {
				ships.set(name, 1);
			}
		}

		string@ name = "";
		uint n = 0;
		uint num = 0;
		items.resize(0);
		ships.resetIter();
		do {
			if (!ships.getCurrentName(name))
				break;
			ships.getCurrent(num);

			menu.addItem(num+"x "+name, 0, true, false, false);

			items.resize(n+1);
			items[n] = name;
			++n;
		}
		while (ships.advance());
	}

	GuiContextMenu@ getMenu() {
		return menu;
	}

	void add(ContextCallback@ cb) {
		// Not supported
	}

	void call(uint i, Object@ clicked) {
		if (i == 0) {
			// Manage docked
			triggerUndockWin(clicked);
		}
		else if (i == 1) {
			// Undock all
			// By default, force the undock (removes the auto-dock order so it
			// doesn't immediately redock)
			if (ctrlKey)
				clicked.undockAll();
			else
				clicked.forceUndockAll();
		} 
		else {
			i -= 3;
			if (i >= items.length())
				return;
			string@ name = items[i];
			const HullLayout@ layout = getActiveEmpire().getShipLayout(name);

			ObjDockedList list;
			list.prepare(clicked);
			uint cnt = list.childCount;

			Object@[] undock;
			undock.resize(cnt);
			uint n = 0;

			for (uint i = 0; i < cnt; ++i) {
				HulledObj@ docked = list.getChild(i);
				if (docked is null)
					continue;

				const HullLayout@ lay = docked.getHull().getLatestVersion();
				if (lay is layout) {
					@undock[n++] = docked;
				}
			}

			for (uint i = 0; i < n; ++i) {
				clicked.undock(undock[i]);
			}
		}
	}
};

void giveDockOrder(OrderList& orders, Object@ from, Object@ to) {
	orders.giveDockOrder(to, shiftKey);
}

void addDockingMenu(GuiContextMenu@ menu, Object@ from, Object@ to) {
	float used, space;
	to.getShipBayVals(used, space);

	// Dock command
	if (space > 0 && from !is to) {
		string@ text = localize("#RM_Dock");
		addItem(menu, text, giveDockOrder);
	}

	// Menu for undocking ships
	if (used > 0) {
		// Create the callback
		DockingMenu@ cb = DockingMenu(to);

		// Add menu
		string@ text = localize("#RM_Undock");
		GuiContextMenu@ dockMenu = addSubMenu(menu, text, cb);
	}
}
/*   }}} */
/*   {{{ Join Fleet Menu */
class FleetJoiner : SelectedCallback {
	Object@ commander;

	FleetJoiner(Object@ fl) {
		@commander = fl;
	}

	void act(Object@ obj) {
		// Only fleet our ships
		if (obj is null || obj.getOwner() !is getActiveEmpire())
			return;

		// Only fleet ships
		HulledObj@ ship = obj;
		if (ship is null)
			return;

		// Add to fleet
		OrderList orders;
		if (orders.prepare(obj)) {
			orders.joinFleet(commander);
		}
	}
};

class FleetMenu : ContextCallbackManager {
	GuiContextMenu@ menu;
	Object@[] fleets;

	void init(GuiContextMenu@ Menu) {
		@menu = Menu;

		// Collect possible fleets
		Empire@ emp = getActiveEmpire();
		uint cnt = emp.getFleetCount();
		fleets.resize(cnt);
		uint j = 0;

		for (uint i = 0; i < cnt; ++i) {
			Fleet@ fleet = emp.getFleet(i);
			if (fleet is null)
				continue;

			@fleets[j++] = fleet.getCommander();
			menu.addItem(fleet.getName(), 0, true, false, false);
		}

		fleets.resize(j);
	}

	GuiContextMenu@ getMenu() {
		return menu;
	}

	void add(ContextCallback@ cb) {
		// Not supported
	}

	void call(uint i, Object@ clicked) {
		if (i >= fleets.length())
			return;
		Object@ fl = fleets[i];
		doForEachSelectedObject(FleetJoiner(fl), true);
	}
};

void addJoinFleetMenu(GuiContextMenu@ menu, Object@ from, Object@ to) {
	// Only fleet our ships
	if (from is null || from.getOwner() !is getActiveEmpire())
		return;

	// Only fleet ships
	HulledObj@ ship = from;
	if (ship is null)
		return;

	// Check if we're not already in a fleet
	Fleet@ fleet = ship.getFleet();
	if (fleet !is null)
		return;

	// Check that we have fleets
	if (getActiveEmpire().getFleetCount() == 0)
		return;

	// Create the callback
	FleetMenu@ cb = FleetMenu();

	// Add menu
	string@ text = localize("#RM_JoinFleet");
	GuiContextMenu@ joinFleet = addSubMenu(menu, text, cb);
}
/*   }}} */
/*   {{{ Fleet Commands */
class FleetSelected : SelectedCallback {
	FleetFormer former;

	FleetSelected() {
	}

	void act(Object@ from) {
		// Only fleet our ships
		if (from is null || from.getOwner() !is getActiveEmpire())
			return;

		// Only fleet ships
		HulledObj@ ship = from;
		if (ship is null)
			return;

		former.add(from);
	}

	void create() {
		former.form();
	}
}

void createFleet(Object@ clicked) {
	FleetSelected action;
	doForEachSelectedObject(action, true);
	action.create();
}

void leaveFleet(OrderList& orders, Object@ from, Object@ to) {
	orders.leaveFleet();
}

void disbandFleet(Object@ clicked) {
	// Only disband our ships
	if (clicked is null || clicked.getOwner() !is getActiveEmpire())
		return;

	// Retrieve the ship
	HulledObj@ ship = clicked;
	if (ship is null)
		return;

	// Retrieve the fleet
	Fleet@ fl = ship.getFleet();
	if (fl is null)
		return;

	// Disband fleet
	OrderList orders;
	if (orders.prepare(fl.getCommander())) {
		orders.disbandFleet();
	}
}

void giveUpCommand(Object@ clicked) {
	// Only disband our ships
	if (clicked is null || clicked.getOwner() !is getActiveEmpire())
		return;

	// Retrieve the ship
	HulledObj@ ship = clicked;
	if (ship is null)
		return;

	// Retrieve the fleet
	Fleet@ fl = ship.getFleet();
	if (fl is null)
		return;

	// Forfeit command
	OrderList orders;
	if (orders.prepare(fl.getCommander())) {
		orders.forfeitFleetCommand();
	}
}

void addFleetActions(GuiContextMenu@ menu, Object@ from, Object@ to) {
	// Only fleet our ships
	if (to is null || to.getOwner() !is getActiveEmpire())
		return;

	// Only fleet ships
	HulledObj@ ship = to;
	if (ship is null)
		return;

	// Check if we're already in a fleet
	Fleet@ fleet = ship.getFleet();

	// Commands for ships not in a fleet
	if (fleet is null) {
		addItem(menu, localize("#RM_CreateFleet"), createFleet);
	}
	// Commands for ships in a fleet
	else {
		if (fleet.getCommander() is to) {
			addItem(menu, localize("#RM_Resign"), giveUpCommand);
		}
		addItem(menu, localize("#RM_LeaveFleet"), leaveFleet);
		addItem(menu, localize("#RM_DisbandFleet"), disbandFleet);
	}
}
/*   }}} */
/*   {{{ Automation Orders */
// Shortcut to prompt for order settings
void giveOrder(Object@ clicked, OrderType type) {
	// Generate desc and settings
	OrderDesc@ desc = generateOrderDesc(type);

	if (desc.hasOptions()) {
		GiveOrderCallback@ cb = GiveOrderCallback(clicked, desc);
		string@ text = combine(localize("#OC_Edit"), desc.getName(),
							   localize("#OC_Order"), ":");

		OptionDialog@ dialog = addOptionDialog(text, cb);
		desc.toOptionDialog(dialog);

		// Add tools to work order
		if (type == OrdT_Work) {
			string@[] tools;
			bool[] needsForce;
			getTools(getSelectedObject(getSubSelection()), null, tools, needsForce);

			GuiComboBox@ box = dialog.getOption(0);
			if (box !is null) {
				uint sel = 0;
				for (uint i = 0; i < tools.length(); ++i) {
					string@ tool = tools[i];
					box.addItem(tool);
				}
			}
		}

		dialog.fitChildren();
	}
	else {
		doGiveOrder(clicked, desc);
	}
}

class GiveOrderCallback : OptionDialogCallback {
	OrderDesc@ desc;
	Object@ clicked;

	GiveOrderCallback(Object@ Clicked, OrderDesc@ Desc) {
		@desc = Desc;
		@clicked = Clicked;
	}

	void call(OptionDialog@ dialog, bool success) {
		if (success) {
			desc.fromOptionDialog(dialog);
			doGiveOrder(clicked, desc);
		}
	}
}

void doGiveOrder(Object@ clicked, OrderDesc@ desc) {
	// Create descriptor
	OrderDescriptor@ descriptor = createOrderDescriptor(desc.getType());
	desc.toDescriptor(descriptor);

	// Give order
	AddOrderActor@ actor = AddOrderActor(clicked, descriptor);
	doForEachSelectedObject(actor, true);

	@actor.ignoreObj = null;
	actor.act(clicked);

	freeOrderDescriptor(descriptor);
}

// Give the same order to all selected objects
class AddOrderActor : SelectedCallback {
	OrderDescriptor@ descriptor;
	Object@ ignoreObj;

	AddOrderActor(Object@ ignore, OrderDescriptor@ desc) {
		@ignoreObj = ignore;
		@descriptor = desc;
	}

	void act(Object@ selected) {
		if (selected is null || selected is ignoreObj)
			return;
		if (selected.getOwner() !is getActiveEmpire())
			return;

		OrderList orders;
		if (orders.prepare(selected))
			orders.giveOrder(descriptor, shiftKey);
	}
}

// Shortcut to add items to the automation menu
GuiContextMenu@ automationMenu;
void addAutom(GuiContextMenu@ menu, string@ text, ContextClickedAction@ act) {
	if (automationMenu is null) {
		string@ text = localize("#RM_AutomationMenu");
		@automationMenu = addSubMenu(menu, text, null);
	}
	addItem(automationMenu, text, act);
}
void addAutom(GuiContextMenu@ menu, string@ text, ContextOrderAction@ act) {
	if (automationMenu is null) {
		string@ text = localize("#RM_AutomationMenu");
		@automationMenu = addSubMenu(menu, text, null);
	}
	addItem(automationMenu, text, act);
}

// Clear Orders
void clearOrders(OrderList& orders, Object@ obj, Object@ to) {
	orders.clearOrders(ctrlKey);
}

// Refresh automation
void refreshAutomation(OrderList& orders, Object@ obj, Object@ to) {
	orders.refreshAutomation();
}

// Auto-dock near
void giveAutoDockOrder(Object@ clicked) {
	giveOrder(clicked, OrdT_AutoDock);
}

// Manage docked
void giveAutoUnDockOrder(Object@ clicked) {
	giveOrder(clicked, OrdT_AutoUnDock);
}

// Auto-dock near once
void giveAutoDockOnceOrder(OrderList& orders, Object@ obj, Object@ to) {
	orders.giveOrder("AutoDock:true:", shiftKey);
}

// Defend System
void giveDefendOrder(Object@ clicked) {
	giveOrder(clicked, OrdT_Defend);
}

// Colonize System
void giveColonizeOrder(Object@ clicked) {
	giveOrder(clicked, OrdT_Colonize);
}

// Supply ships
void giveSupplyOrder(Object@ clicked) {
	giveOrder(clicked, OrdT_Supply);
}

// Fetch Resource
void giveFetchOrder(Object@ clicked) {
	giveOrder(clicked, OrdT_Fetch);
}

// Deposit Resource
void giveDepositOrder(Object@ clicked) {
	giveOrder(clicked, OrdT_Deposit);
}

// Automatically Retrofit
void giveAutoRetrofitOrder(Object@ clicked) {
	giveOrder(clicked, OrdT_AutoRetrofit);
}

// Replenish strike craft
void giveReplenishOrder(Object@ clicked) {
	giveOrder(clicked, OrdT_Replenish);
}

// Trade
void giveTradeOrder(Object@ clicked) {
	giveOrder(clicked, OrdT_Trade_Local);
}

// Join fleet
void giveFleetOrder(Object@ clicked) {
	giveOrder(clicked, OrdT_JoinFleet);
}

// Automatically Explore
void giveExploreOrder(Object@ clicked) {
	giveOrder(clicked, OrdT_AutoExplore);
}

// Work with tool
void giveWorkOrder(Object@ clicked) {
	giveOrder(clicked, OrdT_Work);
}

// Add the order items
void addAutomationOrders(GuiContextMenu@ menu, Object@ from, Object@ to) {
	// Can only change automation on our objects
	if (from is null || from.getOwner() !is getActiveEmpire())
		return;

	// Can only change automation on ships
	bool ship = from.toHulledObj() !is null;
	bool weapons = hasWeapons(from);
	bool movement = from.canMoveSelf();
	@automationMenu = null;

	// Check layout tags
	bool colonizer = false;
	bool cargo = false;

	if (ship) {
		const HullLayout@ lay = from.toHulledObj().getHull();
		colonizer = lay.hasSystemWithTag("Colonizer");
		cargo = lay.hasSystemWithTag("CargoBay");
	}

	// Clear orders
	addItem(menu, localize("#RM_ClearOrders"), clearOrders);

	// Refresh automation
	if (ship) {
		addAutom(menu, localize("#RM_Automation"), refreshAutomation);
		addSeparator(automationMenu);
	}

	// Docking automation
	if (ship) {
		addAutom(menu, localize("#RM_AutoDockOnce"), giveAutoDockOnceOrder);
		addAutom(menu, localize("#OR_AutoDock"), giveAutoDockOrder);
	}

	// Undocking automation
	float space, used;
	from.getShipBayVals(used, space);
	if (space > 0) {
		addAutom(menu, localize("#OR_AutoUnDock"), giveAutoUnDockOrder);

		if (ship) {
			addAutom(menu, localize("#OR_Replenish"), giveReplenishOrder);
		}
	}

	// Combat automation
	if (weapons) {
		addAutom(menu, localize("#OR_Defend"), giveDefendOrder);
	}

	// Colonization automation
	if (colonizer) {
		addAutom(menu, localize("#OR_Colonize"), giveColonizeOrder);
	}

	// Exploration automation
	if (movement) {
		addAutom(menu, localize("#OR_AutoExplore"), giveExploreOrder);
	}

	// Resource automation
	if (ship) {
		addAutom(menu, localize("#OR_Fetch"), giveFetchOrder);
		addAutom(menu, localize("#OR_Supply"), giveSupplyOrder);
		addAutom(menu, localize("#OR_Deposit"), giveDepositOrder);
	}

	// Retrofit automation
	if (ship) {
		addAutom(menu, localize("#OR_AutoRetrofit"), giveAutoRetrofitOrder);
	}

	// Trade automation
	if (cargo) {
		addAutom(menu, localize("#OR_Trade"), giveTradeOrder);
	}

	// Fleet automation
	if (ship) {
		addAutom(menu, localize("#OR_JoinFleet"), giveFleetOrder);
	}

	// Work order
	if (ship) {
		string@[] tools;
		bool[] needsForce;
		getTools(from, null, tools, needsForce);

		if (tools.length() != 0)
			addAutom(menu, localize("#OR_Work"), giveWorkOrder);
	}

	@automationMenu = null;
}
/*   }}} */
/* }}} */
/* {{{ Callback management */
// Callback functions
funcdef void ContextClickedAction(Object@ clicked);
funcdef void ContextTowardsAction(Object@ selected, Object@ clicked);
funcdef void ContextOrderAction(OrderList& orders, Object@ selected, Object@ clicked);
funcdef void ContextFleetOrderAction(OrderList& orders, Object@ selected, Object@ clicked, bool activeFleetMember);

// Context callbacks are functions do to various things when an option is chosen
interface ContextCallback {
	void act(Object@ clicked);
};

class ContextClickedActionCallback : ContextCallback {
	ContextClickedAction@ action;

	ContextClickedActionCallback(ContextClickedAction@ Act) {
		@action = Act;
	}

	void act(Object@ clicked) {
		action(clicked);
	}
}

class ContextSelectedActor : SelectedCallback {
	ContextTowardsAction@ action;
	Object@ clicked;

	ContextSelectedActor(ContextTowardsAction@ Act, Object@ Clicked) {
		@clicked = Clicked;
		@action = Act;
	}

	void act(Object@ selected) {
		action(selected, clicked);
	}
}

class ContextTowardsActionCallback : ContextCallback {
	ContextTowardsAction@ action;

	ContextTowardsActionCallback(ContextTowardsAction@ Act) {
		@action = Act;
	}

	void act(Object@ clicked) {
		ContextSelectedActor@ actor = ContextSelectedActor(action, clicked);
		doForEachSelectedObject(actor, true);
		actor.act(null);
	}
}

class ContextOrderActor : SelectedCallback {
	ContextOrderAction@ action;
	Object@ clicked;

	ContextOrderActor(ContextOrderAction@ Act, Object@ Clicked) {
		@clicked = Clicked;
		@action = Act;
	}

	void act(Object@ selected) {
		if (selected.getOwner() is getActiveEmpire()) {
			OrderList orders;
			if (orders.prepare(selected))
				action(orders, selected, clicked);
		}
	}
}

class ContextOrderActionCallback : ContextCallback {
	ContextOrderAction@ action;

	ContextOrderActionCallback(ContextOrderAction@ Act) {
		@action = Act;
	}

	void act(Object@ clicked) {
		ContextOrderActor@ actor = ContextOrderActor(action, clicked);
		doForEachSelectedObject(actor, true);
	}
}

class ContextFleetOrderActor : SelectedCallback {
	ContextFleetOrderAction@ action;
	Object@ clicked;
	set_int fleets;
	bool firstPass;

	ContextFleetOrderActor(ContextFleetOrderAction@ Act, Object@ Clicked) {
		@clicked = Clicked;
		@action = Act;
		firstPass = true;
	}

	void act(Object@ selected) {
		if (selected.getOwner() !is getActiveEmpire())
			return;

		OrderList orders;
		if (!orders.prepare(selected))
			return;

		if (firstPass) {
			// Find the fleet leaders
			if (orders.isFleetCommander())
				fleets.insert(selected.uid);
		}
		else {
			// Check if this is a fleet member
			bool isMember = false;
			HulledObj@ hulled = selected;
			if (hulled !is null) {
				Fleet@ fl = hulled.getFleet();
				if (fl !is null) {
					Object@ comm = fl.getCommander();
					isMember = comm !is selected && fleets.exists(comm.uid);
				}
			}

			action(orders, selected, clicked, isMember);
		}
	}
}

class ContextFleetOrderActionCallback : ContextCallback {
	ContextFleetOrderAction@ action;

	ContextFleetOrderActionCallback(ContextFleetOrderAction@ Act) {
		@action = Act;
	}

	void act(Object@ clicked) {
		ContextFleetOrderActor@ actor = ContextFleetOrderActor(action, clicked);
		doForEachSelectedObject(actor, true);
		actor.firstPass = false;
		doForEachSelectedObject(actor, true);
	}
}

ContextCallbackManager@[] managers;

interface ContextCallbackManager {
	void init(GuiContextMenu@ Menu);
	GuiContextMenu@ getMenu();
	void add(ContextCallback@ cb);
	void call(uint i, Object@ clicked);
}

class SimpleContextCallbackManager : ContextCallbackManager {
	GuiContextMenu@ menu;
	ContextCallback@[] callbacks;

	void init(GuiContextMenu@ Menu) {
		@menu = Menu;
	}

	GuiContextMenu@ getMenu() {
		return menu;
	}

	void add(ContextCallback@ cb) {
		uint n = callbacks.length();
		callbacks.resize(n+1);
		@callbacks[n] = cb;
	}

	void call(uint i, Object@ clicked) {
		if (i >= callbacks.length())
			return;
		if (callbacks[i] !is null)
			callbacks[i].act(clicked);
	}
}

void resetManagers() {
	managers.resize(0);
}

void addManager(GuiContextMenu@ menu) {
	uint n = managers.length();
	managers.resize(n+1);
	@managers[n] = SimpleContextCallbackManager();
	managers[n].init(menu);
}

void addManager(GuiContextMenu@ menu, ContextCallbackManager@ manager) {
	uint n = managers.length();
	managers.resize(n+1);
	@managers[n] = manager;
	managers[n].init(menu);
}

void addCallback(GuiContextMenu@ menu, ContextCallback@ cb) {
	uint cnt = managers.length();
	for (uint i = 0; i < cnt; ++i) {
		if (managers[i].getMenu() is menu) {
			managers[i].add(cb);
			return;
		}
	}
}

void doCallback(GuiContextMenu@ menu, Object@ clicked) {
	if (menu is null)
		return;

	int sel = menu.getSelected();
	uint cnt = managers.length();
	for (uint i = 0; i < cnt; ++i) {
		if (managers[i].getMenu() is menu) {
			managers[i].call(sel, clicked);
			return;
		}
	}
}
/* }}} */

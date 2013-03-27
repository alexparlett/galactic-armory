#include "~/Game Data/gui/include/gui_skin.as"
#include "~/Game Data/gui/include/dialog.as"
#include "~/Game Data/gui/include/gui_sprite.as"
#include "~/Game Data/gui/include/blueprints_sort.as"
#include "/include/resource_grid.as"

import recti makeScreenCenteredRect(const dim2di &in rectSize) from "gui_lib";
import void anchorToMouse(GuiElement@) from "gui_lib";

// GLOBALS
const int MIN_WIDTH = 820;
const int MIN_HEIGHT = 230;
float placeholder_ = 0;

string@ curColEmp = "", curOwnEmp = "", curVisEmp = "", curResRemEmp = "", curResAddEmp = "";
string@ curResRem = "", curResAdd = "", curTechAllEmp = "", curTechEmp = "", curTechSpecEmp = "";
string@ curSingTech = "", curSpecTech = "", curBlueEmp = "", curSpawnEmp = "", curCondAdd = "";
string@ curRingEmp = "", curResourceEmp = "";
Object@ telDest = null, spawnDest = null;

GuiScripted@[] top_icos(9);	

class TestingWinHandle {
	TestingWin@ script;
	GuiScripted@ ele;
	
	TestingWinHandle(recti Position) {
		@script = TestingWin();
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

class TestingWin : ScriptedGuiHandler {
	DragResizeInfo drag;
	pos2di position;
	bool removed;
	
	TestingWin() {
		removed = false;
	}
	
	void remove() {
		removed = true;
	}	
	
	//Main Window
	GuiButton@ close;
	GuiButton@ basicTab;
	GuiButton@ spawnTab;
	GuiButton@ empireTab;
	GuiButton@ aiTab;
	GuiPanel@ topPanel;
	
	//Basic Panel
	GuiPanel@ basicPanel;
	
	GuiStaticText@ ownText;
	GuiStaticText@ desText;
	GuiStaticText@ colText;
	GuiStaticText@ visText;
	GuiStaticText@ telText;
	GuiStaticText@ condAddText;	
	GuiStaticText@ eradicateText;
	GuiStaticText@ damageText;
	
	GuiButton@ ownBut;
	GuiButton@ desBut;
	GuiButton@ colBut;
	GuiButton@ visBut;
	GuiButton@ telBut;
	GuiButton@ telDestBut;
	GuiButton@ condAddBut;
	GuiButton@ condRemBut;
	GuiButton@ eradicateBut;
	GuiButton@ damageBut;
	
	GuiComboBox@ ownComb;
	GuiComboBox@ colComb;
	GuiComboBox@ visComb;
	GuiComboBox@ condAddComb;

	GuiEditBox@ damageNum;
	
	//Spawn Panel
	GuiPanel@ spawnPanel;
	
	SortedBlueprintList layouts;	
	
	GuiComboBox@ blueEmp;
	GuiComboBox@ spawnEmp;
	GuiComboBox@ ringEmp;
	
	GuiButton@ importBut;
	GuiButton@ restoreBut;
	GuiButton@ spawnTarget;
	GuiButton@ spawnBut;
	GuiButton@ ringBut;
	GuiButton@ planetBut;
	GuiButton@ roidBut;
	GuiEditBox@ spawnNum;
	GuiEditBox@ planetNum;	
	GuiEditBox@ roidNum;
	
	GuiListBox@ spawnShipsList;
	
	GuiStaticText@ importText;
	GuiStaticText@ restoreText;
	GuiStaticText@ spawnText;
	GuiStaticText@ ringTex;
	GuiStaticText@ planetText;
	GuiStaticText@ roidText;
	
	//Empire Panel
	GuiPanel@ empirePanel;
	
	GuiStaticText@ resAddText;
	GuiStaticText@ resRemText;
	GuiStaticText@ techSingleText;
	GuiStaticText@ techAllText;
	GuiStaticText@ techSpecText;
	
	GuiButton@ resAmtAdd;
	GuiButton@ resAmtRem;
	GuiButton@ resAddBut;
	GuiButton@ resRemBut;
	GuiButton@ techSingleBut;
	GuiButton@ techAllBut;
	GuiButton@ techSpecBut;
	GuiButton@ techSpecSetBut;
	
	GuiComboBox@ resAddEmpComb;
	GuiComboBox@ resRemEmpComb;
	GuiComboBox@ resAddComb;
	GuiComboBox@ resRemComb;
	GuiComboBox@ techSingleComb;
	GuiComboBox@ techSpecComb;
	GuiComboBox@ techSingleEmp;
	GuiComboBox@ techAllEmp;
	GuiComboBox@ techSpecEmp;
	
	GuiEditBox@ resAddSet;
	GuiEditBox@ resRemSet;
	GuiEditBox@ techAllSet;
	GuiEditBox@ techSpecSet;
	
	//Ai Panel
	GuiPanel@ aiPanel;
	
	GuiStaticText@ empSelect;
	GuiComboBox@ empDetComb;	
	
	GuiExtText@ bankMtl;
	GuiExtText@ bankElc;
	GuiExtText@ bankAdv;
	GuiExtText@	bankFood; 
	GuiExtText@ bankGoods;
	GuiExtText@ bankLux;
	GuiExtText@ bankFuel; 
	GuiExtText@ bankAmmo; 
	GuiExtText@ bankTrade;
	
	GuiStaticText@ textMtl;
	GuiStaticText@ textElc;
	GuiStaticText@ textAdv;
	GuiStaticText@ textFood; 
	GuiStaticText@ textGoods;
	GuiStaticText@ textLux;
	GuiStaticText@ textFuel; 
	GuiStaticText@ textAmmo; 
	GuiStaticText@ textTrade;	
	
	void init(GuiElement@ ele) {
		//Main
		@close = CloseButton(recti(), ele);
		
		@topPanel = GuiPanel(recti(0, 20, 40, 70), false, SBM_Invisible, SBM_Invisible, ele);
		topPanel.fitChildren();
		
		//Tabs
		@basicTab = TabButton(recti(), localize("#TT_BASIC_TOOL"), topPanel);
		@spawnTab = TabButton(recti(), localize("#TT_SPAWN_TOOL"), topPanel);
		@empireTab = TabButton(recti(), localize("#TT_EMPIRE_TOOL"), topPanel);
		@aiTab = TabButton(recti(), localize("#TT_AI_TOOL"), topPanel);
		
		basicTab.setPressed(true);
		
		// Basic Panel
		@basicPanel = GuiPanel(recti(0,45,200,70), false, SBM_Invisible, SBM_Invisible, ele);
		basicPanel.fitChildren();
		
		@ownText = GuiStaticText(recti(0,0,240,20), null, false, false, false, basicPanel);
		ownText.setTextAlignment(EA_Left, EA_Center);
		ownText.setText(localize("#TT_SET_OWNER"));
		@ownComb = GuiComboBox(recti(pos2di(230,20), dim2di(180,20)), basicPanel);
		@ownBut = Button(dim2di(180,20), localize("#TT_SET_OWNER_DO"), basicPanel);
		
		@desText = GuiStaticText(recti(0,0,240,20), null, false, false, false, basicPanel);
		desText.setTextAlignment(EA_Left, EA_Center);
		desText.setText(localize("#TT_DESTROY"));
		@desBut = Button(dim2di(180,20), localize("#TT_DESTROY_DO"), basicPanel);
		
		@colText = GuiStaticText(recti(0,0,240,20), null, false, false, false, basicPanel);
		colText.setTextAlignment(EA_Left, EA_Center);
		colText.setText(localize("#TT_COLONIZE"));
		@colComb = GuiComboBox(recti(pos2di(230,68), dim2di(180,20)), basicPanel);
		@colBut = Button(dim2di(180,20), localize("#TT_COLONIZE_DO"), basicPanel);
		
		@visText = GuiStaticText(recti(0,0,240,20), null, false, false, false, basicPanel);
		visText.setTextAlignment(EA_Left, EA_Center);
		visText.setText(localize("#TT_VISIBILITY"));
		@visComb = GuiComboBox(recti(pos2di(230,92), dim2di(180,20)), basicPanel);
		@visBut = Button(dim2di(180,20), localize("#TT_VISIBILITY_DO"), basicPanel);
		
		@telText = GuiStaticText(recti(0,0,240,20), null, false, false, false, basicPanel);
		telText.setTextAlignment(EA_Left, EA_Center);
		telText.setText(localize("#TT_TELEPORT"));
		@telBut = Button(dim2di(180,20), localize("#TT_TELEPORT_DO"), basicPanel);	
		@telDestBut = Button(dim2di(180,20), localize("#TT_TELEPORT_DESTINATION"), basicPanel);	

		@condAddText = GuiStaticText(recti(0,0,240,20), null, false, false, false, basicPanel);
		condAddText.setTextAlignment(EA_Left, EA_Center);
		condAddText.setText(localize("#TT_ADD_COND"));
		@condAddBut = Button(dim2di(180,20), localize("#TT_ADD_COND_DO"), basicPanel);
		@condAddComb = GuiComboBox(recti(pos2di(230, 140), dim2di(180,20)), basicPanel);
		@condRemBut = Button(dim2di(180,20), localize("#TT_REM_COND_DO"), basicPanel);
		
		@eradicateText = GuiStaticText(recti(0,0,240,20), null, false, false, false, basicPanel);
		eradicateText.setTextAlignment(EA_Left, EA_Center);
		eradicateText.setText(localize("#TT_ERADICATE"));
		@eradicateBut = Button(dim2di(180,20), localize("#TT_ERADICATE_DO"), basicPanel);
		
		@damageText = GuiStaticText(recti(0,0,240,20), null, false, false, false, basicPanel);
		damageText.setTextAlignment(EA_Left, EA_Center);
		damageText.setText(localize("#TT_DAMAGE"));
		@damageNum = GuiEditBox(recti(0,0,180,20),null,true,basicPanel);
		@damageBut = Button(dim2di(180,20), localize("#TT_DAMAGE_DO"), basicPanel);
		
		// Spawn Panel
		@spawnPanel = GuiPanel(recti(0,45,200,70), false, SBM_Invisible, SBM_Invisible, ele);
		spawnPanel.fitChildren();
		spawnPanel.setVisible(false);

		@spawnShipsList = GuiListBox(recti(0, 7, 0, 0), true, spawnPanel);		
	
		@importText = GuiStaticText(recti(0,0,180,20), null, false, false, false, spawnPanel);
		importText.setTextAlignment(EA_Left, EA_Center);
		importText.setText(localize("#TT_SPAWN_IMPORT"));
		@blueEmp = GuiComboBox(recti(pos2di(6,47), dim2di(180,20)), spawnPanel);
		@importBut = Button(dim2di(180,20), localize("#TT_SPAWN_IMPORT_DO"), spawnPanel);
		importBut.setToolTip(localize("#TT_SPAWN_IMPORT_TT"));

		@restoreText = GuiStaticText(recti(0,0,180,20), null, false, false, false, spawnPanel);
		restoreText.setTextAlignment(EA_Left, EA_Center);
		restoreText.setText(localize("#TT_SPAWN_RESTORE"));
		@restoreBut = Button(dim2di(180,20), localize("#TT_SPAWN_RESTORE_DO"), spawnPanel);
		restoreBut.setToolTip(localize("#TT_SPAWN_RESTORE_TT"));
		
		@spawnText = GuiStaticText(recti(0,0,180,20), null, false, false, false, spawnPanel);
		spawnText.setTextAlignment(EA_Left, EA_Center);
		spawnText.setText(localize("#TT_SPAWN_SHIPS"));
		@spawnNum = GuiEditBox(recti(0,0,180,20), null,true,spawnPanel);
		spawnNum.setToolTip(localize("#TT_SPAWN_SHIPS_NUM_TT"));
		@spawnEmp = GuiComboBox(recti(pos2di(417,92), dim2di(180,20)), spawnPanel);
		@spawnTarget = Button(dim2di(180,20), localize("#TT_SPAWN_SHIP_TARG"), spawnPanel);
		@spawnBut = Button(dim2di(180,20), localize("#TT_SPAWN_SHIP_DO"), spawnPanel);
		
		@ringTex = GuiStaticText(recti(0,0,180,20), null, false, false, false, spawnPanel);
		ringTex.setTextAlignment(EA_Left, EA_Center);
		ringTex.setText(localize("#TT_SPAWN_RING"));
		@ringEmp = GuiComboBox(recti(pos2di(417,164), dim2di(180,20)), spawnPanel);
		@ringBut = Button(dim2di(180,20), localize("#TT_SPAWN_RING_DO"), spawnPanel);
		
		@planetText = GuiStaticText(recti(0,0,180,20), null, false, false, false, spawnPanel);
		planetText.setTextAlignment(EA_Left, EA_Center);
		planetText.setText(localize("#TT_SPAWN_PLANET"));
		@planetNum = GuiEditBox(recti(0,0,180,20), null,true,spawnPanel);
		@planetBut = Button(dim2di(180,20), localize("#TT_SPAWN_PLANET_DO"), spawnPanel);
		
		@roidText = GuiStaticText(recti(0,0,180,20), null, false, false, false, spawnPanel);
		roidText.setTextAlignment(EA_Left, EA_Center);
		roidText.setText(localize("#TT_SPAWN_ROID"));
		@roidNum = GuiEditBox(recti(0,0,180,20), null,true,spawnPanel);
		@roidBut = Button(dim2di(180,20), localize("#TT_SPAWN_ROID_DO"), spawnPanel);
		
		// Empire Panel
		@empirePanel = GuiPanel(recti(0,45,200,70), false, SBM_Invisible, SBM_Invisible, ele);
		empirePanel.fitChildren();
		empirePanel.setVisible(false);
		
		@resAddText = GuiStaticText(recti(0,0,240,20), null, false, false, false, empirePanel);
		resAddText.setTextAlignment(EA_Left, EA_Center);
		resAddText.setText(localize("#TT_RES_ADD"));
		@resAddComb = GuiComboBox(recti(pos2di(230, 20), dim2di(180,20)), empirePanel);
		@resAddBut = Button(dim2di(180,20), localize("#TT_RES_ADD_DO"), empirePanel);
		@resAddEmpComb = GuiComboBox(recti(pos2di(20,44), dim2di(180,20)), empirePanel);
		@resAddSet = GuiEditBox(recti(0,0,210,20),null,true,empirePanel);
		@resAmtAdd = Button(dim2di(180,20), localize("#TT_RES_AMT_SET"), empirePanel);
		
		@resRemText = GuiStaticText(recti(0,0,240,20), null, false, false, false, empirePanel);
		resRemText.setTextAlignment(EA_Left, EA_Center);
		resRemText.setText(localize("#TT_RES_REM"));
		@resRemComb = GuiComboBox(recti(pos2di(230, 92), dim2di(180,20)), empirePanel);
		@resRemBut = Button(dim2di(180,20), localize("#TT_RES_REM_DO"), empirePanel);
		@resRemEmpComb = GuiComboBox(recti(pos2di(20,116), dim2di(180,20)), empirePanel);
		@resRemSet = GuiEditBox(recti(0,0,210,20),null,true,empirePanel);
		@resAmtRem = Button(dim2di(180,20), localize("#TT_RES_AMT_SET"), empirePanel);
		
		@techSingleText = GuiStaticText(recti(0,0,240,20), null, false, false, false, empirePanel);
		techSingleText.setTextAlignment(EA_Left, EA_Center);
		techSingleText.setText(localize("#TT_TECH_SINGLE"));
		@techSingleComb = GuiComboBox(recti(pos2di(230, 164), dim2di(180,20)), empirePanel);
		@techSingleEmp = GuiComboBox(recti(pos2di(420, 164), dim2di(180,20)), empirePanel);
		@techSingleBut = Button(dim2di(180,20), localize("#TT_TECH_SINGLE_DO"), empirePanel);
		
		@techAllText = GuiStaticText(recti(0,0,240,20), null, false, false, false, empirePanel);
		techAllText.setTextAlignment(EA_Left, EA_Center);
		techAllText.setText(localize("#TT_TECH_ALL"));		
		@techAllSet = GuiEditBox(recti(0,0,180,20), null, true, empirePanel);
		@techAllEmp = GuiComboBox(recti(pos2di(420,164), dim2di(180,20)), empirePanel);
		@techAllBut = Button(dim2di(180,20), localize("#TT_TECH_ALL_DO"), empirePanel);
		
		@techSpecText = GuiStaticText(recti(0,0,240,20), null, false, false, false, empirePanel);
		techSpecText.setTextAlignment(EA_Left, EA_Center);
		techSpecText.setText(localize("#TT_TECH_SPEC"));
		@techSpecComb = GuiComboBox(recti(pos2di(420, 188), dim2di(180,20)), empirePanel);
		@techSpecEmp = GuiComboBox(recti(pos2di(600,188), dim2di(180,20)), empirePanel);
		@techSpecSet = GuiEditBox(recti(0,0,180,20),null,true,empirePanel);
		@techSpecSetBut = Button(dim2di(180,20), localize("#TT_TECH_SPEC_SET"), empirePanel);
		@techSpecBut = Button(dim2di(180,20), localize("#TT_TECH_SPEC_DO"), empirePanel);
		
		//ai Panel
		
		@aiPanel = GuiPanel(recti(0,45,200,70), false, SBM_Invisible, SBM_Invisible, ele);
		aiPanel.fitChildren();
		aiPanel.setVisible(false);
		
		@empSelect = GuiStaticText(recti(0,0,240,20), null, false, false, false, aiPanel);
		empSelect.setTextAlignment(EA_Left, EA_Center);
		empSelect.setText(localize("#TT_EMP_SELECT"));
		
		@empDetComb = GuiComboBox(recti(pos2di(230, 20), dim2di(180,20)), aiPanel);
		
		@textMtl = GuiStaticText(recti(0,0,180,20), null, false, false, false, aiPanel);
		textMtl.setText("Metal: ");
		@textElc = GuiStaticText(recti(0,0,180,20), null, false, false, false, aiPanel);
		textElc.setText("Electronics: ");
		@textAdv = GuiStaticText(recti(0,0,180,20), null, false, false, false, aiPanel);
		textAdv.setText("Advanced Parts: ");
		@textFood = GuiStaticText(recti(0,0,1800,20), null, false, false, false, aiPanel); 
		textFood.setText("Food: ");
		@textGoods = GuiStaticText(recti(0,0,180,20), null, false, false, false, aiPanel);
		textGoods.setText("Goods: ");
		@textLux = GuiStaticText(recti(0,0,180,20), null, false, false, false, aiPanel);
		textLux.setText("Luxuries: ");
		@textFuel = GuiStaticText(recti(0,0,180,20), null, false, false, false, aiPanel); 
		textFuel.setText("Fuel: ");
		@textAmmo = GuiStaticText(recti(0,0,180,20), null, false, false, false, aiPanel); 
		textAmmo.setText("Ammo: ");
		@textTrade = GuiStaticText(recti(0,0,180,20), null, false, false, false, aiPanel);
		textTrade.setText("Trade: ");
		
		@bankMtl = GuiExtText(recti(pos2di(220,68), dim2di(82, 20)), aiPanel);
		@bankElc = GuiExtText(recti(pos2di(500,68), dim2di(82, 20)), aiPanel);
		@bankAdv = GuiExtText(recti(pos2di(220,92), dim2di(82, 20)), aiPanel);
		@bankFood = GuiExtText(recti(pos2di(500,928), dim2di(82, 20)), aiPanel);
		@bankGoods = GuiExtText(recti(pos2di(220,116), dim2di(82, 20)), aiPanel);
		@bankLux = GuiExtText(recti(pos2di(500,116), dim2di(82, 20)), aiPanel);
		@bankFuel = GuiExtText(recti(pos2di(220,140), dim2di(82, 20)), aiPanel);
		@bankAmmo = GuiExtText(recti(pos2di(500,140), dim2di(82, 20)), aiPanel);	
		@bankTrade = GuiExtText(recti(pos2di(220,168), dim2di(82, 20)), aiPanel);	
			
		syncPosition(ele.getSize());		
	}
	
	void syncPosition(dim2di size) {
		// Close button
		close.setPosition(pos2di(size.width-30, 0));
		close.setSize(dim2di(30, 12));
		
		// Position Top Panel
		topPanel.setPosition(pos2di(7,13));
		topPanel.setSize(dim2di(size.width - 6, 40));
		
		// Position Tabs
		int tabSize = (size.width - 16 - 2*4) / 4;
		
		basicTab.setPosition(pos2di(0, 9));
		spawnTab.setPosition(pos2di(4+tabSize, 9));
		empireTab.setPosition(pos2di(8+tabSize*2, 9));
		aiTab.setPosition(pos2di(12+tabSize*3,9));
		
		basicTab.setSize(dim2di(tabSize, 18));
		spawnTab.setSize(dim2di(tabSize, 18));
		empireTab.setSize(dim2di(tabSize, 18));
		aiTab.setSize(dim2di(tabSize,18));
		
		// Position tab contents
		recti contentRect = recti(pos2di(6, 40), size - dim2di(12, 47));
		pos2di topLeft = contentRect.UpperLeftCorner;
		size = contentRect.getSize();

		// Basic Panel
		basicPanel.setPosition(topLeft);
		basicPanel.setSize(size);
		
		ownText.setPosition(pos2di(20,20));
		ownComb.setPosition(pos2di(230,20));
		ownBut.setPosition(pos2di(420,20));
		
		desText.setPosition(pos2di(20,44));
		desBut.setPosition(pos2di(420,44));

		visText.setPosition(pos2di(20,68));
		visComb.setPosition(pos2di(230,68));
		visBut.setPosition(pos2di(420,68));	

		telText.setPosition(pos2di(20,92));
		telBut.setPosition(pos2di(420,92));
		telDestBut.setPosition(pos2di(230,92));
		
		damageText.setPosition(pos2di(20, 116));
		damageNum.setPosition(pos2di(230,116));
		damageNum.setSize(dim2di(180,20));
		damageBut.setPosition(pos2di(420,116));		
		
		colText.setPosition(pos2di(20,164));
		colComb.setPosition(pos2di(230,164));
		colBut.setPosition(pos2di(420,164));		
		
		condAddText.setPosition(pos2di(20,188));
		condAddComb.setPosition(pos2di(230,188));
		condAddBut.setPosition(pos2di(420,188));
		condRemBut.setPosition(pos2di(610,188));
		
		eradicateText.setPosition(pos2di(20,212));
		eradicateBut.setPosition(pos2di(420,212));
		
		// Spawn Panel
		spawnPanel.setPosition(topLeft);
		spawnPanel.setSize(size);
		
		spawnShipsList.setSize(dim2di(204, size.height - 4));

		importText.setPosition(pos2di(227, 20));
		blueEmp.setPosition(pos2di(417, 20));
		importBut.setPosition(pos2di(607, 20));
		
		restoreText.setPosition(pos2di(227, 44));
		restoreBut.setPosition(pos2di(417, 44));
		
		spawnText.setPosition(pos2di(227, 92));
		spawnNum.setPosition(pos2di(417, 116));
		spawnNum.setSize(dim2di(180,20));
		spawnEmp.setPosition(pos2di(417,92));
		spawnTarget.setPosition(pos2di(607,92));
		spawnBut.setPosition(pos2di(607,116));
		
		ringTex.setPosition(pos2di(227,164));
		ringBut.setPosition(pos2di(607,164));
		ringEmp.setPosition(pos2di(417,164));
		
		planetText.setPosition(pos2di(227,188));
		planetNum.setPosition(pos2di(417,188));
		planetNum.setSize(dim2di(180,20));
		planetBut.setPosition(pos2di(607,188));
		
		roidText.setPosition(pos2di(227,212));
		roidNum.setPosition(pos2di(417,212));
		roidNum.setSize(dim2di(180,20));
		roidBut.setPosition(pos2di(607,212));		
		
		// Empire Panel
		empirePanel.setPosition(topLeft);
		empirePanel.setSize(size);

		resAddText.setPosition(pos2di(20,20));
		resAddEmpComb.setPosition(pos2di(230,20));
		resAddBut.setPosition(pos2di(420,20));
		resAddComb.setPosition(pos2di(230,44));
		resAmtAdd.setPosition(pos2di(420,44));
		resAddSet.setPosition(pos2di(20,44));
		resAddSet.setSize(dim2di(200,20));
		
		resRemText.setPosition(pos2di(20,92));
		resRemEmpComb.setPosition(pos2di(230,92));
		resRemBut.setPosition(pos2di(420,92));
		resRemComb.setPosition(pos2di(230,116));
		resAmtRem.setPosition(pos2di(420,116));		
		resRemSet.setPosition(pos2di(20,116));
		resRemSet.setSize(dim2di(200,20));
		
		techSingleText.setPosition(pos2di(20, 164));
		techSingleComb.setPosition(pos2di(230, 164));
		techSingleEmp.setPosition(pos2di(420, 164));
		techSingleBut.setPosition(pos2di(610, 164));
		
		techAllText.setPosition(pos2di(20, 188));
		techAllSet.setPosition(pos2di(230, 188));
		techAllSet.setSize(dim2di(180,20));
		techAllEmp.setPosition(pos2di(420, 188));
		techAllBut.setPosition(pos2di(610, 188));
		
		techSpecText.setPosition(pos2di(20, 212));
		techSpecSet.setPosition(pos2di(230, 212));
		techSpecSet.setSize(dim2di(180,20));
		techSpecComb.setPosition(pos2di(420,212));
		techSpecEmp.setPosition(pos2di(610,212));		
		techSpecSetBut.setPosition(pos2di(230, 236));
		techSpecBut.setPosition(pos2di(420,236));
		
		// Ai Panel
		aiPanel.setPosition(topLeft);
		aiPanel.setSize(size);
		
		empSelect.setPosition(pos2di(20,20));
		empDetComb.setPosition(pos2di(230,20));	

		textMtl.setPosition(pos2di(20,68));
		textElc.setPosition(pos2di(300,68));
		textAdv.setPosition(pos2di(20,92));
		textFood.setPosition(pos2di(300,92)); 
		textGoods.setPosition(pos2di(20,116));
		textLux.setPosition(pos2di(300,116));
		textFuel.setPosition(pos2di(20,140)); 
		textAmmo.setPosition(pos2di(300,140)); 
		textTrade.setPosition(pos2di(20,164));
		
		bankMtl.setPosition(pos2di(220,68));
		bankElc.setPosition(pos2di(500,68));
		bankAdv.setPosition(pos2di(220,92));
		bankFood.setPosition(pos2di(500,92)); 
		bankGoods.setPosition(pos2di(220,116));
		bankLux.setPosition(pos2di(500,116));
		bankFuel.setPosition(pos2di(220,140)); 
		bankAmmo.setPosition(pos2di(500,140)); 
		bankTrade.setPosition(pos2di(220,164));		
	}	

	void draw(GuiElement@ ele) {
		ele.toGuiScripted().setAbsoluteClip();
		const recti absPos = ele.getAbsolutePosition();
		pos2di topLeft = absPos.UpperLeftCorner;
		pos2di botRight = absPos.LowerRightCorner;
		dim2di size = absPos.getSize();

		//Window Basics
		drawWindowFrame(absPos);
		drawResizeHandle(recti(botRight - pos2di(19, 19), botRight));
		drawDarkArea(recti(topLeft + pos2di(7,13), botRight - pos2di(7,7)));		
		drawHSep(recti(topLeft + pos2di(-3,11), dim2di(size.width + 7, 11)));		
		drawHSep(recti(topLeft + pos2di(6,40), dim2di(size.width-12, 7)));	
		
		if(spawnPanel.isVisible()) {
			drawVSep(recti(topLeft + pos2di(210,44), dim2di(7, size.height - 50)));
		}
		
		if(aiPanel.isVisible()) {
			drawHSep(recti(topLeft + pos2di(5, 92), dim2di(size.width-11, 7)));
		}
		
		clearDrawClip();		
	}
	
	void update(float time) {
		if(ownComb.getItemCount() != int(getEmpireCount()))
			updateEmpireList();
			
		if(basicPanel.isVisible()) {
			if(condAddComb.getItemCount() != int(getPlanetConditionCount()))
				updateConditionList();
		}
		
		if(empirePanel.isVisible()) {
			if(resAddComb.getItemCount() != 6)
				updateResList();
				
			if(techSingleComb.getItemCount() != int(getWebItemDescCount()))
				updateTechList();
		}
		
		if(spawnPanel.isVisible()) {
			updateBuildables();
		}
		
		if(aiPanel.isVisible()) {
			updateResourceList();
		}
	}
	
	void updateResourceList() {
		const Empire@ emp = getEmpire(empDetComb.getSelected());
		if(emp.isValid()) {
			bankMtl.setText(standardize(emp.getStat("Metals") / 1000000.f) + "M");
			bankElc.setText(standardize(emp.getStat("Electronics") / 1000000.f) + "M");
			bankAdv.setText(standardize(emp.getStat("AdvParts") / 1000000.f) + "M");
			bankFood.setText(standardize(emp.getStat("Food") / 1000000.f) + "M");
			bankGoods.setText(standardize(emp.getStat("Guds") / 1000000.f) + "M");
			bankLux.setText(standardize(emp.getStat("Luxs") / 1000000.f) + "M");
			bankFuel.setText(standardize(emp.getStat("Fuel") / 1000000.f) + "M");
			bankAmmo.setText(standardize(emp.getStat("Ammo") / 1000000.f) + "M");
			bankTrade.setText(standardize(emp.getStat("importer") / 1000000.f) + "M");
		}
		else {
			bankMtl.setText("");
			bankElc.setText("");
			bankAdv.setText("");
			bankFood.setText("");
			bankGoods.setText("");
			bankLux.setText("");
			bankFuel.setText("");
			bankAmmo.setText("");
			bankTrade.setText("");
		}	
	}
	
	void updateBuildables() {	
		const Empire@ emp = getActiveEmpire();

		if(layouts.update(emp, false))
			layouts.fill(spawnShipsList);		
	}	
	
	void updateEmpireList() {
		ownComb.clear();
		colComb.clear();
		visComb.clear();
		resRemEmpComb.clear();
		resAddEmpComb.clear();
		techAllEmp.clear();
		techSingleEmp.clear();
		techSpecEmp.clear();
		blueEmp.clear();
		spawnEmp.clear();
		ringEmp.clear();
		empDetComb.clear();
		
		uint cnt = getEmpireCount();
		for (uint i = 0; i < cnt; i++) {
			const Empire@ emp = getEmpire(i);
			
			ownComb.addItem(emp.getName());
			colComb.addItem(emp.getName());
			visComb.addItem(emp.getName());
			resRemEmpComb.addItem(emp.getName());
			resAddEmpComb.addItem(emp.getName());
			techAllEmp.addItem(emp.getName());
			techSingleEmp.addItem(emp.getName());
			techSpecEmp.addItem(emp.getName());
			blueEmp.addItem(emp.getName());
			spawnEmp.addItem(emp.getName());
			ringEmp.addItem(emp.getName());
			empDetComb.addItem(emp.getName());
		}
		
		colComb.setSelected(0);
		ownComb.setSelected(0);
		visComb.setSelected(0);
		resRemEmpComb.setSelected(0);
		resAddEmpComb.setSelected(0);
		techAllEmp.setSelected(0);
		techSingleEmp.setSelected(0);
		techSpecEmp.setSelected(0);
		blueEmp.setSelected(0);
		spawnEmp.setSelected(0);
		ringEmp.setSelected(0);
		empDetComb.setSelected(0);
	}
	
	void updateResList() {
		resAddComb.clear();
		resRemComb.clear();
		
		uint cnt = getResourceCount();
		for(uint i = 0; i < cnt; i++) {
			const Resource@ res = getResource(i);
			string@ name = res.getName();
			
			if (!res.canTransfer)
				continue;
			if(name == "H3" || name == "Ore")
				continue;

			resAddComb.addItem(name);
			resRemComb.addItem(name);
		}
		
		resAddComb.setSelected(0);
		resRemComb.setSelected(0);
	}
	
	void updateTechList() {
		techSingleComb.clear();
		techSpecComb.clear();
		
		uint cnt = getWebItemDescCount();
		
		for(uint i = 0; i < cnt; i++) {
			const WebItemDesc@ desc = getWebItemDesc(i);
			string@ name = desc.get_id();
			
			techSingleComb.addItem(name);
			techSpecComb.addItem(name);
		}
		
		techSingleComb.setSelected(0);
		techSpecComb.setSelected(0);
	}
	
	void updateConditionList() {
		condAddComb.clear();
	
		uint cnt = getPlanetConditionCount();
		
		for(uint i = 0; i < cnt; i++) {
			const PlanetCondition@ cond = getPlanetCondition(i);
			string@ name = cond.get_id();
			
			condAddComb.addItem(name);
		}
		condAddComb.setSelected(0);
	}
	
	void updateAddCond() {
		int item = condAddComb.getSelected();
		string@ prevCond = getPlanetCondition(item).get_id();
		
		if(curCondAdd != prevCond) {
			int num = condAddComb.getItemCount();
			
			for(int i = 0; i < num; i++) {
				if(condAddComb.getItem(i) == curCondAdd) {
					condAddComb.setSelected(i);
					break;
				}
			}
		}
	}
	
	void updateResourceEmpire() {
		int item = empDetComb.getSelected();
		string@ prevEmp = getEmpire(item).getName();
		
		if(curResourceEmp != prevEmp) {
			int num = empDetComb.getItemCount();
			
			for(int i = 0; i < num; i++) {
				if(empDetComb.getItem(i) == curResourceEmp) {
					empDetComb.setSelected(i);
					break;
				}
			}
		}
	}	
	
	void updateRingEmpire() {
		int item = ringEmp.getSelected();
		string@ prevEmp = getEmpire(item).getName();
		
		if(curRingEmp != prevEmp) {
			int num = ringEmp.getItemCount();
			
			for(int i = 0; i < num; i++) {
				if(ringEmp.getItem(i) == curRingEmp) {
					ringEmp.setSelected(i);
					break;
				}
			}
		}
	}	
	
	void updateSpawnEmpire() {
		int item = spawnEmp.getSelected();
		string@ prevEmp = getEmpire(item).getName();
		
		if(curSpawnEmp != prevEmp) {
			int num = spawnEmp.getItemCount();
			
			for(int i = 0; i < num; i++) {
				if(spawnEmp.getItem(i) == curSpawnEmp) {
					spawnEmp.setSelected(i);
					break;
				}
			}
		}
	}
	
	void updateOwnEmpire() {
		int item = ownComb.getSelected();
		string@ prevEmp = getEmpire(item).getName();
		
		if(curOwnEmp != prevEmp) {
			int num = ownComb.getItemCount();
			
			for(int i = 0; i < num; i++) {
				if(ownComb.getItem(i) == curOwnEmp) {
					ownComb.setSelected(i);
					break;
				}
			}
		}
	}
	
	void updateBlueEmpire() {
		int item = blueEmp.getSelected();
		string@ prevEmp = getEmpire(item).getName();
		
		if(curBlueEmp != prevEmp) {
			int num = blueEmp.getItemCount();
			
			for(int i = 0; i < num; i++) {
				if(blueEmp.getItem(i) == curBlueEmp) {
					blueEmp.setSelected(i);
					break;
				}
			}
		}
	}
	
	void updateColEmpire() {
		int item = colComb.getSelected();
		string@ prevEmp = getEmpire(item).getName();
	
		if(curColEmp != prevEmp) {
			int num = colComb.getItemCount();
			
			for(int i = 0; i < num; i++) {
				if(colComb.getItem(i) == curColEmp) {
					colComb.setSelected(i);
					break;
				}
			}
		}
	}
	
	void updateVisEmpire() {
		int item = visComb.getSelected();
		string@ prevEmp = getEmpire(item).getName();
	
		if(curVisEmp != prevEmp) {
			int num = visComb.getItemCount();
			
			for(int i = 0; i < num; i++) {
				if(visComb.getItem(i) == curVisEmp) {
					visComb.setSelected(i);
					break;
				}
			}
		}
	}

	void updateResAddEmpire() {
		int item = resAddEmpComb.getSelected();
		string@ prevEmp = getEmpire(item).getName();
	
		if(curResAddEmp != prevEmp) {
			int num = resAddEmpComb.getItemCount();
			
			for(int i = 0; i < num; i++) {
				if(resAddEmpComb.getItem(i) == curResAddEmp) {
					resAddEmpComb.setSelected(i);
					break;
				}
			}
		}
	}	

	void updateResRemEmpire() {
		int item = resRemEmpComb.getSelected();
		string@ prevEmp = getEmpire(item).getName();
	
		if(curResRemEmp != prevEmp) {
			int num = resRemEmpComb.getItemCount();
			
			for(int i = 0; i < num; i++) {
				if(resRemEmpComb.getItem(i) == curResRemEmp) {
					resRemEmpComb.setSelected(i);
					break;
				}
			}
		}
	}
	
	void updateTechEmpire() {
		int item = techSingleEmp.getSelected();
		string@ prevEmp = getEmpire(item).getName();
	
		if(curTechEmp != prevEmp) {
			int num = techSingleEmp.getItemCount();
			
			for(int i = 0; i < num; i++) {
				if(techSingleEmp.getItem(i) == curTechEmp) {
					techSingleEmp.setSelected(i);
					break;
				}
			}
		}
	}
	
	void updateTechAllEmpire() {
		int item = techAllEmp.getSelected();
		string@ prevEmp = getEmpire(item).getName();
	
		if(curTechAllEmp != prevEmp) {
			int num = techAllEmp.getItemCount();
			
			for(int i = 0; i < num; i++) {
				if(techAllEmp.getItem(i) == curTechAllEmp) {
					techAllEmp.setSelected(i);
					break;
				}
			}
		}
	}
	
	void updateSpecTechEmpire() {
		int item = techSpecEmp.getSelected();
		string@ prevEmp = getEmpire(item).getName();
	
		if(curTechSpecEmp != prevEmp) {
			int num = techSpecEmp.getItemCount();
			
			for(int i = 0; i < num; i++) {
				if(techSpecEmp.getItem(i) == curTechSpecEmp) {
					techSpecEmp.setSelected(i);
					break;
				}
			}
		}
	}

	void updateResAdd() {
		int item = resAddComb.getSelected();
		string@ prevRes = getResource(resAddComb.getItem(item)).getName();
		
		if(curResAdd != prevRes) {
			int num = resAddComb.getItemCount();
			
			for(int i = 0; i < num; i++) {
				if(resAddComb.getItem(i) == curResAdd) {
					resAddComb.setSelected(i);
					break;
				}
			}
		}	
	}
	
	void updateResRem() {
		int item = resRemComb.getSelected();
		string@ prevRes = getResource(resRemComb.getItem(item)).getName();
		
		if(curResRem != prevRes) {
			int num = resRemComb.getItemCount();
			
			for(int i = 0; i < num; i++) {
				if(resRemComb.getItem(i) == curResRem) {
					resRemComb.setSelected(i);
					break;
				}
			}
		}	
	}
	
	void updateSingleTech() {
		int item = techSingleComb.getSelected();
		string@ prevTech = getWebItemDesc(item).get_name();
		
		if(curSingTech != prevTech) {
			int num = techSingleComb.getItemCount();
			
			for(int i = 0; i < num; i++) {
				if(techSingleComb.getItem(i) == curSingTech) {
					techSingleComb.setSelected(i);
					break;
				}
			}
		}	
	}
	
	void updateSpecTech() {
		int item = techSpecComb.getSelected();
		string@ prevTech = getWebItemDesc(item).get_name();
		
		if(curSpecTech != prevTech) {
			int num = techSpecComb.getItemCount();
			
			for(int i = 0; i < num; i++) {
				if(techSpecComb.getItem(i) == curSpecTech) {
					techSpecComb.setSelected(i);
					break;
				}
			}
		}	
	}
	
	void setCondAdd(int num) {
		string@ newCond = getPlanetCondition(num).get_id();
		if(newCond!is null) {
			curCondAdd.opAssign(newCond);
			updateAddCond();	
		}	
	}	
	
	void setSingleTech(int num) {
		string@ newTech = getWebItemDesc(num).get_name();
		if(newTech !is null) {
			curSingTech.opAssign(newTech);
			updateSingleTech();	
		}	
	}
	
	void setSpecTech(int num) {
		string@ newTech = getWebItemDesc(num).get_name();
		if(newTech !is null) {
			curSpecTech.opAssign(newTech);
			updateSpecTech();	
		}	
	}
	
	void setAddRes(int num) {
		string@ newRes = getResource(resAddComb.getItem(num)).getName();
		if(newRes !is null) {
			curResAdd.opAssign(newRes);
			updateResAdd();	
		}	
	}	

	void setRemRes(int num) {
		string@ newRes = getResource(resRemComb.getItem(num)).getName();
		if(newRes !is null) {
			curResRem.opAssign(newRes);
			updateResRem();	
		}	
	}
	
	void setResourceEmpire(int num) {
		string@ newEmp = getEmpire(uint(num)).getName();
		if(newEmp !is null) {
			curResourceEmp.opAssign(newEmp);
			updateResourceEmpire();	
		}	
	}	
	
	void setRingEmpire(int num) {
		string@ newEmp = getEmpire(uint(num)).getName();
		if(newEmp !is null) {
			curRingEmp.opAssign(newEmp);
			updateRingEmpire();	
		}	
	}	

	void setSpawnEmpire(int num) {
		string@ newEmp = getEmpire(uint(num)).getName();
		if(newEmp !is null) {
			curSpawnEmp.opAssign(newEmp);
			updateSpawnEmpire();	
		}	
	}
	
	void setBlueEmpire(int num) {
		string@ newEmp = getEmpire(uint(num)).getName();
		if(newEmp !is null) {
			curBlueEmp.opAssign(newEmp);
			updateBlueEmpire();	
		}	
	}	

	void setTechEmpire(int num) {
		string@ newEmp = getEmpire(uint(num)).getName();
		if(newEmp !is null) {
			curTechEmp.opAssign(newEmp);
			updateTechEmpire();	
		}	
	}

	void setTechAllEmpire(int num) {
		string@ newEmp = getEmpire(uint(num)).getName();
		if(newEmp !is null) {
			curTechAllEmp.opAssign(newEmp);
			updateTechAllEmpire();	
		}	
	}

	void setTechSpecEmpire(int num) {
		string@ newEmp = getEmpire(uint(num)).getName();
		if(newEmp !is null) {
			curTechSpecEmp.opAssign(newEmp);
			updateSpecTechEmpire();	
		}	
	}	
	
	void setVisEmpire(int num) {
		string@ newEmp = getEmpire(uint(num)).getName();
		if(newEmp !is null) {
			curVisEmp.opAssign(newEmp);
			updateVisEmpire();	
		}	
	}
	
	void setResAddEmpire(int num) {
		string@ newEmp = getEmpire(uint(num)).getName();
		if(newEmp !is null) {
			curResAddEmp.opAssign(newEmp);
			updateResAddEmpire();	
		}	
	}
	
	void setResRemEmpire(int num) {
		string@ newEmp = getEmpire(uint(num)).getName();
		if(newEmp !is null) {
			curResRemEmp.opAssign(newEmp);
			updateResRemEmpire();	
		}	
	}
	
	void setColEmpire(int num) {
		string@ newEmp = getEmpire(uint(num)).getName();
		if(newEmp !is null) {
			curColEmp.opAssign(newEmp);
			updateColEmpire();	
		}	
	}
	
	void setOwnEmpire(int num) {
		string@ newEmp = getEmpire(uint(num)).getName();
		if(newEmp !is null) {
			curOwnEmp.opAssign(newEmp);
			updateOwnEmpire();	
		}		
	}
	
	void switchTab(int num) {
		basicTab.setPressed(num == 0);
		spawnTab.setPressed(num == 1);
		empireTab.setPressed(num == 2);
		aiTab.setPressed(num == 3);

		basicPanel.setVisible(num == 0);
		spawnPanel.setVisible(num == 1);
		empirePanel.setVisible(num == 2);
		aiPanel.setVisible(num == 3);
	}	
	
	EventReturn onKeyEvent(GuiElement@ ele, const KeyEvent& evt) {
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

	EventReturn onGUIEvent(GuiElement@ ele, const GUIEvent& evt) {
		if (evt.EventType == GEVT_Focus_Gained && evt.Caller.isAncestor(ele)) {
			ele.bringToFront();
			bindEscapeEvent(ele);
		}
		else if (evt.EventType == GEVT_Closed) {
			hideTestingWindow();
			return ER_Absorb;
		}
		else
		{
			switch (evt.EventType) // Handle events from the window elements themselves
			{ 
				case GEVT_Clicked:
					if (evt.Caller is close) {
						hideTestingWindow();
						return ER_Pass;
					}
					else if (evt.Caller is basicTab) {
						switchTab(0);
						return ER_Pass;
					}
					else if (evt.Caller is spawnTab) {
						switchTab(1);
						return ER_Pass;
					}
					else if (evt.Caller is empireTab) {
						switchTab(2);
						return ER_Pass;
					}
					else if (evt.Caller is aiTab) {
						switchTab(3);
						return ER_Pass;
					}
					else if(basicPanel.isVisible()) {
						if(evt.Caller is ownBut) {
							setSelectionOwner();
							return ER_Pass;
						}
						else if(evt.Caller is desBut) {
							destroySelection();
							return ER_Pass;
						}
						else if(evt.Caller is colBut) {
							colonizeSelection();
							return ER_Pass;
						}
						else if(evt.Caller is visBut) {
							addVisibility();
							return ER_Pass;
						}
						else if(evt.Caller is telBut) {
							teleportSelection();
							return ER_Pass;
						}
						else if(evt.Caller is telDestBut) {
							setTeleportDest();
							return ER_Pass;
						}
						else if(evt.Caller is condAddBut) {
							addPlanetCond();
							return ER_Pass;
						}
						else if(evt.Caller is condRemBut) {
							remPlanetCond();
							return ER_Pass;
						}
						else if(evt.Caller is eradicateBut) {
							eradicatePlanet();
							return ER_Pass;
						}
						else if(evt.Caller is damageBut) {
							damageSelection();
							return ER_Pass;
						}
					}
					else if(empirePanel.isVisible()) {
						if(evt.Caller is resAddBut) {
							addResource();
							return ER_Pass;
						}
						else if(evt.Caller is resRemBut) {
							removeResource();
							return ER_Pass;
						}
						else if(evt.Caller is resAmtAdd) {
							setResAddAmt(resAddSet.getText());
							return ER_Pass;
						}
						else if(evt.Caller is resAmtRem) {
							setResRemAmt(resRemSet.getText());
							return ER_Pass;
						}
						else if(evt.Caller is techSingleBut) {
							singleTechLevel();
							return ER_Pass;
						}
						else if(evt.Caller is techAllBut) {
							allTechLevels();
							return ER_Pass;
						}
						else if(evt.Caller is techSpecSetBut) {
							setTechSpecLevel(techSpecSet.getText());
							return ER_Pass;
						}
						else if(evt.Caller is techSpecBut) {
							specTechLevel();
							return ER_Pass;
						}
					}
					else if(spawnPanel.isVisible()) {
						if(evt.Caller is importBut) {
							importBlueprints();
							return ER_Pass;
						}
						else if(evt.Caller is restoreBut) {
							restoreBlueprints();
							return ER_Pass;
						}
						else if(evt.Caller is spawnTarget) {
							setSpawnTarget();
							return ER_Pass;
						}
						else if(evt.Caller is spawnBut) {
							spawnShips();
							return ER_Pass;
						}
						else if(evt.Caller is ringBut) {
							spawnRingworld();
							return ER_Pass;
						}
						else if(evt.Caller is planetBut) {
							spawnPlanet();
							return ER_Pass;
						}
						else if(evt.Caller is roidBut) {
							spawnAsteroids();
							return ER_Pass;
						}						
					}
				break;
				case GEVT_ComboBox_Changed:
					if (evt.Caller is ownComb) {
						setOwnEmpire(ownComb.getSelected());
					}
					else if(evt.Caller is colComb) {
						setColEmpire(colComb.getSelected());
					}
					else if(evt.Caller is visComb) {
						setVisEmpire(visComb.getSelected());
					}
					else if(evt.Caller is resAddEmpComb) {
						setResAddEmpire(resAddEmpComb.getSelected());
					}
					else if(evt.Caller is resRemEmpComb) {
						setResRemEmpire(resRemEmpComb.getSelected());
					}
					else if(evt.Caller is resRemComb) {
						setRemRes(resRemComb.getSelected());
					}
					else if(evt.Caller is resAddComb) {
						setAddRes(resAddComb.getSelected());
					}
					else if(evt.Caller is techSingleEmp) {
						setTechEmpire(techSingleEmp.getSelected());
					}
					else if(evt.Caller is techAllEmp) {
						setTechAllEmpire(techAllEmp.getSelected());
					}
					else if(evt.Caller is techSpecEmp) {
						setTechSpecEmpire(techSpecEmp.getSelected());
					}
					else if(evt.Caller is techSingleComb) {
						setSingleTech(techSingleComb.getSelected());
					}
					else if(evt.Caller is techSpecComb) {
						setSpecTech(techSpecComb.getSelected());
					}
					else if(evt.Caller is blueEmp) {
						setBlueEmpire(blueEmp.getSelected());
					}
					else if(evt.Caller is spawnEmp) {
						setSpawnEmpire(spawnEmp.getSelected());
					}
					else if(evt.Caller is condAddComb) {
						setCondAdd(condAddComb.getSelected());
					}
					else if(evt.Caller is ringEmp) {
						setRingEmpire(ringEmp.getSelected());
					}
					else if(evt.Caller is empDetComb) {
						setResourceEmpire(empDetComb.getSelected());
					}
				break; 
				case GEVT_Focus_Gained:
					if (evt.Caller is ownComb) {
						ownComb.bringToFront();
						return ER_Pass;
					}
					else if (evt.Caller is colComb) {
						colComb.bringToFront();
						return ER_Pass;
					}
					else if(evt.Caller is visComb) {
						visComb.bringToFront();
						return ER_Pass;
					}
					else if(evt.Caller is resAddComb) {
						resAddComb.bringToFront();
						return ER_Pass;
					}
					else if(evt.Caller is resRemComb) {
						resRemComb.bringToFront();
						return ER_Pass;
					}
					else if(evt.Caller is resAddEmpComb) {
						resAddEmpComb.bringToFront();
						return ER_Pass;
					}
					else if(evt.Caller is resRemEmpComb) {
						resRemEmpComb.bringToFront();
						return ER_Pass;
					}
					else if(evt.Caller is techSingleEmp) {
						techSingleEmp.bringToFront();
						return ER_Pass;
					}
					else if(evt.Caller is techAllEmp) {
						techAllEmp.bringToFront();
						return ER_Pass;
					}
					else if(evt.Caller is techSpecEmp) {
						techSpecEmp.bringToFront();
						return ER_Pass;
					}
					else if(evt.Caller is techSingleComb) {
						techSingleComb.bringToFront();
						return ER_Pass;
					}
					else if(evt.Caller is techSpecComb) {
						techSpecComb.bringToFront();
						return ER_Pass;
					}
					else if(evt.Caller is blueEmp) {
						blueEmp.bringToFront();
						return ER_Pass;
					}
					else if(evt.Caller is spawnEmp) {
						spawnEmp.bringToFront();
						return ER_Pass;
					}
					else if(evt.Caller is condAddComb) {
						condAddComb.bringToFront();
						return ER_Pass;
					}
					else if(evt.Caller is ringEmp) {
						ringEmp.bringToFront();
						return ER_Pass;
					}
				break;				
			}
		}	
		return ER_Pass;
	}
	
	// Basic Tools
	void setSelectionOwner() {
		uint cnt = getSelectedObjectCount();
		for(uint i = 0; i < cnt; i++) {
			Object@ obj = getSelectedObject(i);
			if(obj.toPlanet() is null && obj.toHulledObj() is null)
				continue;
			sendServerMessage("testing_tools", 1, f_to_s(obj.uid), float(ownComb.getSelected()));
		}
	}
	
	void destroySelection() {
		uint cnt = getSelectedObjectCount();
		for(uint i = 0; i < cnt; i++) {
			Object@ obj = getSelectedObject(i);
			sendServerMessage("testing_tools", 2, f_to_s(obj.uid), placeholder_);
		}	
	}
	
	void colonizeSelection() {
		if(colComb.getSelected() <= 2)
			return;	
	
		uint cnt = getSelectedObjectCount();
		for(uint i = 0; i < cnt; i++) {
			Object@ obj = getSelectedObject(i);
			if(obj.toPlanet() !is null)
				sendServerMessage("testing_tools", 3, f_to_s(obj.uid), float(colComb.getSelected()));
		}	
	}
	
	void addVisibility() {
		sendServerMessage("testing_tools", 4, "", float(visComb.getSelected()));
	}
	
	void setTeleportDest() {
		uint cnt = getSelectedObjectCount();
		if(cnt >= 1) {
			@telDest = getSelectedObject(0);
		}
	}
	
	void teleportSelection() {
		if(@telDest is null)
			return;	
	
		uint cnt = getSelectedObjectCount();
		for(uint i = 0; i < cnt; i++) {
			Object@ obj = getSelectedObject(i);
			sendServerMessage("testing_tools", 5, f_to_s(obj.uid), telDest.uid);
		}
	}	
	
	void addPlanetCond() {
		uint cnt = getSelectedObjectCount();
		for(uint i = 0; i < cnt; i++) {
			Object@ obj = getSelectedObject(i);
			if(obj.toPlanet() !is null)
				sendServerMessage("testing_tools", 18, condAddComb.getItem(condAddComb.getSelected()), obj.uid);
		}	
	}
	
	void remPlanetCond() {
		uint cnt = getSelectedObjectCount();
		for(uint i = 0; i < cnt; i++) {
			Object@ obj = getSelectedObject(i);
			if(obj.toPlanet() !is null)
				sendServerMessage("testing_tools", 19, condAddComb.getItem(condAddComb.getSelected()), obj.uid);
		}	
	}
	
	void eradicatePlanet() {
		uint cnt = getSelectedObjectCount();
		for(uint i = 0; i < cnt; i++) {
			Object@ obj = getSelectedObject(i);
			if(obj.toPlanet() !is null)
				sendServerMessage("testing_tools", 20, "", obj.uid);
		}	
	}	
	
	void damageSelection() {
		uint cnt = getSelectedObjectCount();
		for(uint i = 0; i < cnt; i++) {
			Object@ obj = getSelectedObject(i);
			if(obj !is null)
				sendServerMessage("testing_tools", 24, damageNum.getText(), obj.uid);
		}	
	}
	
	// Spawn Tools
	
	void importBlueprints() {
		sendServerMessage("testing_tools", 14, "", float(blueEmp.getSelected()));
	}
	
	void restoreBlueprints() {
		sendServerMessage("testing_tools", 15, "", placeholder_);
	}
	
	void setSpawnTarget() {
		uint cnt = getSelectedObjectCount();
		if(cnt >= 1) {
			@spawnDest = getSelectedObject(0);
		}	
	
		if(@spawnDest !is null)
			sendServerMessage("testing_tools", 16, i_to_s(spawnEmp.getSelected()), spawnDest.uid);
	}
	
	void spawnShips() {
		float cnt = 1;
		
		if(spawnNum.getText() != "")
			cnt = s_to_f(spawnNum.getText());
			
		const HullLayout@ temp = layouts.getDesign(spawnShipsList.getSelected());	
		
		if(cnt > 0 && temp !is null)
			sendServerMessage("testing_tools", 17, temp.getName(), cnt);
	}
	
	void spawnRingworld() {
		Object@ ringDest;	
		uint cnt = getSelectedObjectCount();
		if(cnt >= 1) {
			@ringDest = getSelectedObject(0);
		}	
	
		if(@ringDest !is null)
			sendServerMessage("testing_tools", 21, i_to_s(ringEmp.getSelected()), ringDest.uid);		
	}
	
	void spawnPlanet() {
		Object@ planetDest;	
		uint cnt = getSelectedObjectCount();
		if(cnt >= 1) {
			@planetDest = getSelectedObject(0);
		}	
	
		if(@planetDest !is null)
			sendServerMessage("testing_tools", 22, planetNum.getText(), planetDest.uid);		
	}

	void spawnAsteroids() {
		Object@ roidDest;	
		uint cnt = getSelectedObjectCount();
		if(cnt >= 1) {
			@roidDest = getSelectedObject(0);
		}	
	
		if(@roidDest !is null)
			sendServerMessage("testing_tools", 23, roidNum.getText(), roidDest.uid);		
	}	
	
	// Empire Tools
	void addResource() {
		sendServerMessage("testing_tools", 6, resAddComb.getItem(resAddComb.getSelected()), float(resAddEmpComb.getSelected()));
	}
	
	void removeResource() {
		sendServerMessage("testing_tools", 7, resRemComb.getItem(resRemComb.getSelected()), float(resRemEmpComb.getSelected()));
	}
	
	void setResAddAmt(string@ amount) {
		sendServerMessage("testing_tools", 8, amount, placeholder_);
	}
	
	void setResRemAmt(string@ amount) {
		sendServerMessage("testing_tools", 9, amount, placeholder_);
	}
	
	void specTechLevel() {
		sendServerMessage("testing_tools", 10, techSpecComb.getItem(techSpecComb.getSelected()), float(techSpecEmp.getSelected()));	
	}	
	
	void singleTechLevel() {
		sendServerMessage("testing_tools", 11, techSingleComb.getItem(techSingleComb.getSelected()), float(techSingleEmp.getSelected()));
	}
	
	void allTechLevels() {
		sendServerMessage("testing_tools", 12, techAllSet.getText(), float(techAllEmp.getSelected())); 
	}
	
	void setTechSpecLevel(string@ amount) {
		sendServerMessage("testing_tools", 13, amount, placeholder_);
	}
};

TestingWinHandle@ win;
dim2di defaultSize;

void init() {
	// Initialize some constants
	initSkin();

	defaultSize = dim2di(MIN_WIDTH, 350);

	// Bind toggle key
	bindFuncToKey("F9", "script:ToggleTestingWindow_key");
}

void createTestingWindow() {
	@win = TestingWinHandle(makeScreenCenteredRect(defaultSize));
	win.bringToFront();
}

void closeTestingWindow() {
	win.remove();
	@win = null;
	setGuiFocus(null);
}

void showTestingWindow() {
	if (@win == null)
		createTestingWindow();
	else
	{
		win.setVisible(true);
		win.bringToFront();
	}
}

void hideTestingWindow() {
	win.setVisible(false);
	setGuiFocus(null);
}

GuiElement@ getTestingWindow() {
	return win.ele;
}

void toggleTestingWindow() {
	if (@win == null || !win.isVisible())
		showTestingWindow();
	else
		hideTestingWindow();
}

bool ToggleTestingWindow(const GUIEvent@ evt) {
	if (evt.EventType == GEVT_Clicked) {
		toggleTestingWindow();
		return true;
	}
	return false;
}

bool ToggleTestingWindow_key(uint8 flags) {
	if (flags & KF_Pressed != 0) {
		toggleTestingWindow();
		return true;
	}
	return false;
}

void tick(float time) {
	if (@win != null)
		win.update(time);
}
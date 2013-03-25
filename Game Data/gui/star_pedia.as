
import recti makeScreenCenteredRect(const dim2di &in rectSize) from "gui_lib";

void hideStellarPedia() {
	window.setVisible(false);
	clearEscapeEvent(winName);
}

void showStellarPedia(string@ page) {
	window.setVisible(true);
	window.bringToFront();
	bindEscapeEvent(winName, "esc_sp_close");
	
	if(@page != null) {
		int64 index = -1;
		if(categoryIndices.get(page, index))
			switchToCategory(int(index));
	}
}

const string@ winName = "lyt_win";

void esc_sp_close() {
	window.setVisible(false);
}

bool showSPWin_key(uint8 flags) {
	if(flags & KF_Pressed != 0) {
		if(window.isVisible())
			hideStellarPedia();
		else
			showStellarPedia(null);
		return true;
	}
	return false;
}

//Locales
const string@ locale_requires, locale_with, locale_and, locale_atlevel;

//Elements
GuiButton@ openPedia;

GuiDraggable@ window;
GuiButton@ close;
GuiListBox@ category_list;
GuiButton@ PANIC, win_close;

GuiPanel@ pseudoPage;
GuiExtText@ researchText, pseudoContent, pseudoDescription, pseudoTitle;
GuiImage@ pseudoImage;

int curCategory = -1;
Category@[] categories;
dictionary categoryIndices;

class Category {
	GuiPanel@ panel;
	
	Category(GuiPanel@ Panel) {
		@panel = @Panel;
	}
};

void showResearchDetails(string@ page) {
	window.setVisible(true);
	window.bringToFront();
	
	if(@page != null) {
		int64 index = -1;
		if(curCategory >= 0)
			categories[curCategory].panel.setVisible(false);
		category_list.setSelected(-1);
		curCategory = -1;

		fillResearchDetails(getWebItemDesc(page));
		pseudoPage.setVisible(true);
		setGuiFocus(pseudoPage);
		window.bringToFront();
	}
}

void showSubSystemDetails(uint id) {
	window.setVisible(true);
	window.bringToFront();

	int64 index = -1;
	if(curCategory >= 0)
		categories[curCategory].panel.setVisible(false);
	category_list.setSelected(-1);
	curCategory = -1;

	fillSubSystemDetails(getSubSystemDefByID(id));
	pseudoPage.setVisible(true);
	setGuiFocus(pseudoPage);
}

void showSubSystemDetails(string@ page) {
	window.setVisible(true);
	window.bringToFront();
	
	if(@page != null) {
		int64 index = -1;
		if(curCategory >= 0)
			categories[curCategory].panel.setVisible(false);
		category_list.setSelected(-1);
		curCategory = -1;

		fillSubSystemDetails(getSubSystemDefByName(page));
		pseudoPage.setVisible(true);
		setGuiFocus(pseudoPage);
	}
}

void switchToCategory(int index) {
	if(index >= 0 && index < int(categories.length()) && index != int(curCategory)) {
		if(curCategory >= 0)
			categories[curCategory].panel.setVisible(false);
		categories[index].panel.setVisible(true);
		if(@pseudoPage != null)
			pseudoPage.setVisible(false);
		curCategory = index;
		category_list.setSelected(index);
		setGuiFocus(categories[index].panel);
	}
}

void addCategory(const string@ id, const string@ category_locale, GuiPanel@ panel) {
	uint count = categories.length();
	categories.resize(count + 1);
	@categories[count] = Category(panel);
	
	panel.fitChildren();
	
	int64 index = int64(count);
	categoryIndices.set(id, index);
	
	category_list.addItem(localize(category_locale));
}

string@ docText(string@ tag) {
	string@ res = combine("#font:goodtimes_14##c:0d0#", l(tag+" title"), "\n#hline##c##font#\n");
	res += l(tag+" text");

	for (int i = 0; true; ++i) {
		string@ noteTag = tag+" note"+i;
		string@ title = l(noteTag+" title");
		if (title.beginsWith(tag))
			break;
		res += combine("\n\n#font:frank_11##c:bfb#", title, "#c#\n#hline#\n#font#");
		res += l(noteTag+" text");
	}
	return res;
}

bool pickCategory(const GUIEvent@ evt) {
	if(evt.EventType == GEVT_Listbox_Changed)
		switchToCategory(category_list.getSelected());
	return false;
}

bool closePedia(const GUIEvent@ evt) {
	if(evt.EventType == GEVT_Clicked) {
		hideStellarPedia();
		return true;
	}
	return false;
}

bool onTogglePedia(const GUIEvent@ evt) {
	if(evt.EventType == GEVT_Clicked) {
		if(window.isVisible())
			hideStellarPedia();
		else
			showStellarPedia(null);
		return true;
	}
	return false;
}

bool onWindowEvent(const GUIEvent@ evt) {
	if(evt.EventType == GEVT_Closed) {
		hideStellarPedia();
		return true;
	}
	return false;
}

GuiPanel@ makeFramePanel() {
	GuiPanel@ panel = GuiPanel(recti(160,21,693,493), true, SBM_Auto, SBM_Invisible, window);
	panel.fitChildren();
	panel.setVisible(false);
	panel.orphan(true);
	return panel;
}

GuiExtText@ makeFittingExtendedText(GuiElement@ ele) {
	GuiExtText@ ext = GuiExtText(recti(pos2di(5,4), ele.getSize() + dim2di(-10,3000)), ele);
	ext.orphan(true);
	return ext;
}


//Localize 1-4 items, combining them all
string@ l(const string@ str) {
	return localize(str);
}

string@ l(const string@ str1, const string@ str2) {
	return localize(str1) + localize(str2);
}

string@ l(const string@ str1, const string@ str2, const string@ str3) {
	return (localize(str1) + localize(str2)) + localize(str3);
}

string@ l(const string@ str1, const string@ str2, const string@ str3, const string@ str4) {
	return (localize(str1) + localize(str2)) + (localize(str3) + localize(str4));
}

void setSPVisible(bool vis) {
	openPedia.setVisible(vis);
}

void init() {
	string@ prefix, suffix;

	//Toggle window with F6
	bindFuncToKey("F6", "script:showSPWin_key");

	int width = getScreenWidth();

	GuiPanel@ panel;
	GuiExtText@ text;
	string@ str;
	
	//Setup locales
	@locale_requires = localize("#SP_Requires");
	@locale_with = localize("#RW_With");
	@locale_and = localize("#RW_And");
	@locale_atlevel = localize("#RW_AtLevel");
	
	//Setup links
	hookLink("sp", "showStellarPedia");
	hookLink("sp-rs", "showResearchDetails");
	hookLink("sr-ss", "showSubSystemDetails");
	
	//Top bar button
	@openPedia = GuiButton(recti(pos2di(width / 2 + 254, 2), dim2di(32, 48)), null, null);
	openPedia.setSprites("TB_StellarPedia", 0, 0, 0);
	openPedia.setAppearance(false, BA_Background);
	openPedia.setAlignment(EA_Center, EA_Top, EA_Center, EA_Top);
	bindGuiCallback(openPedia, "onTogglePedia");
	
	//Setup window
	@window = GuiDraggable(getSkinnable("Dialog"), makeScreenCenteredRect(dim2di(700,500)), true, null);
	window.setVisible(false);
	bindGuiCallback(window, "onWindowEvent");

	@category_list = GuiListBox(recti(6,20,160,493), true, window);
	bindGuiCallback(category_list, "pickCategory");

	@close = GuiButton(getSkinnable("CloseButton"), recti(pos2di(670, 0), dim2di(30, 12)), null, window);
	bindGuiCallback(close, "closePedia");

	//Home
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	text.setText(l("#SP_Home_Intro"));
	addCategory("home", "#SP_Cat_Home", panel);
	switchToCategory(0);

	// Camera Controls
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	@str = docText("#doc cam");
	text.setText(str);
	addCategory("doc_cam", "#doc cam title", panel);

	// Selection Controls
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	@str = docText("#doc sel");
	text.setText(str);
	addCategory("doc_sel", "#doc sel title", panel);

	// Resources
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	@str = docText("#doc res");
	text.setText(str);
	addCategory("doc_res", "#doc res title", panel);

	// Economic Principles
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	@str = docText("#doc pri");
	text.setText(str);
	addCategory("doc_pri", "#doc pri title", panel);
	
	//Civil Acts
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	
	@str = l("#SP_CivilActs_Intro"); @prefix = "\n\n#font:frank_11##c:bfb#"; @suffix = "#c#\n#font##hline#\n";
	str += combine(
			combine(prefix, l("#CA_ShrtWrkWk"), suffix, l("#CA_ShrtWrkWk_Desc")),
			combine(prefix, l("#CA_FrcdLabr"),  suffix, l("#CA_FrcdLabr_Desc")),
			combine(prefix, l("#CA_WorkEthic"), suffix, l("#CA_WorkEthic_Desc")),
			combine(prefix, l("#CA_Academic"),  suffix, l("#CA_Academic_Desc")),
			combine(prefix, l("#CA_TaxBrk"),    suffix, l("#CA_TaxBrk_Desc")));
	str += combine(
			combine(prefix, l("#CA_MtlFocus"),  suffix, l("#CA_MtlFocus_Desc")),
			combine(prefix, l("#CA_MtlFrenzy"), suffix, l("#CA_MtlFrenzy_Desc")),
			combine(prefix, l("#CA_ElcFocus"),  suffix, l("#CA_ElcFocus_Desc")),
			combine(prefix, l("#CA_ElcFrenzy"), suffix, l("#CA_ElcFrenzy_Desc")),
			combine(prefix, l("#CA_AdvFocus"),  suffix, l("#CA_AdvFocus_Desc")));
	str +=  combine(prefix, l("#CA_AdvFrenzy"), suffix, l("#CA_AdvFrenzy_Desc"));
	str +=  combine(prefix, l("#CA_Stockpile"), suffix, l("#CA_Stockpile_Desc"));
	text.setText(str);
	panel.fitChildren();
	
	addCategory("civilacts", "#SP_Cat_CivilActs", panel);
	
	// Planets
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	@str = docText("#doc pl");
	text.setText(str);
	addCategory("doc_pl", "#doc pl title", panel);

	//Planet Conditions
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);

	@str = l("#SP_PlanetConditions_Intro");
	uint condcnt = getPlanetConditionCount();
	for (uint i = 0; i < condcnt; ++i) {
		const PlanetCondition@ cond = getPlanetCondition(i);
		if (cond.get_id() == "microcline")
			continue;
		string@ desc = cond.desc;
		str += combine(prefix, l("#PC_"+cond.get_id()), suffix, desc);
	}

	text.setText(str);
	addCategory("planetconditions", "#SP_Cat_PlanetConditions", panel);

	//Planet Governors
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	text.setText(l("#SP_PlanetGovernors"));
	addCategory("governors", "#SP_Cat_PlanetGovernors", panel);
	
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	text.setText(l("#SP_Structures_Intro"));
	fillSubSystems(SS_Structure, panel, text.getSize().height+8, false);
	addCategory("structures", "#SP_Cat_Structures", panel);
	
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	text.setText(l("#SP_Improvements_Intro"));
	fillSubSystems(SS_Improvement, panel, text.getSize().height+8, false);
	addCategory("improvements", "#SP_Cat_Improvements", panel);
	
	// Solar Systems
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	@str = docText("#doc sys");
	text.setText(str);
	addCategory("doc_sys", "#doc sys title", panel);
	
	// System Types
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	@str = l("#SP_SystemTypes_Intro");

	str += combine(prefix, l("#ST_Quasar_Name"), suffix, l("#ST_Quasar_Desc"));	
	str += combine(prefix, l("#ST_ChargedParticles_Name"), suffix, l("#ST_ChargedParticles_Desc"));	
	str += combine(prefix, l("#ST_UnstableStar_Name"), suffix, l("#ST_UnstableStar_Desc"));
	str += combine(prefix, l("#ST_NeutronStar_Name"), suffix, l("#ST_NeutronStar_Desc"));
	str += combine(prefix, l("#ST_IonStorm_Name"), suffix, l("#ST_IonStorm_Desc"));
	str += combine(prefix, l("#ST_JumpSystem_Name"), suffix, l("#ST_JumpSystem_Desc"));
	str += combine(prefix, l("#ST_ImperialSeat_Name"), suffix, l("#ST_ImperialSeat_Desc"));
	str += combine(prefix, l("#ST_GateSystem_Name"), suffix, l("#ST_GateSystem_Desc"));
	str += combine(prefix, l("#ST_ResearchOutpost_Name"), suffix, l("#ST_ResearchOutpost_Desc"));
	str += combine(prefix, l("#ST_SpatialGen_Name"), suffix, l("#ST_SpatialGen_Desc"));
	str += combine(prefix, l("#ST_IonCanon_Name"), suffix, l("#ST_IonCanon_Desc"));
	str += combine(prefix, l("#ST_ZeroPoint_Name"), suffix, l("#ST_ZeroPoint_Desc"));
	
	text.setText(str);
	addCategory("systemtypes", "#SP_Cat_SystemTypes", panel);	
	
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	@str = docText("#doc bridge");
	text.setText(str);
	addCategory("doc_bridge", "#doc bridge title", panel);

	// Blueprints
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	@str = docText("#doc bp");
	text.setText(str);
	addCategory("doc_bp", "#doc bp title", panel);
	
	// Basics
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	text.setText(l("#SP_Blueprint_Intro"));
	addCategory("blueprint", "#SP_Cat_Blueprint", panel);	
	
	// Modifiers
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	@str = l("#SP_Modifiers_Intro");
	str += combine(prefix, l("#SS_COOLANT_NAME"), suffix, l("#SP_CoolantSystem_Info"));
	str += combine(prefix, l("#SS_AIMBOT_NAME"), suffix, l("#SP_TargettingSensors_Info"));
	str += combine(prefix, l("#SS_PMOD_NAME"), suffix, l("#SP_PrecisionMod_Info"));
	str += combine(prefix, l("#SS_MULTIRACK_NAME"), suffix, l("#SP_RackMount_Info"));
	str += combine(prefix, l("#SS_OVRSIZMOUNT_NAME"), suffix, l("#SP_OversizeMount_Info"));
	str += combine(prefix, l("#SS_DAMAGESYS_NAME"), suffix, l("#SP_DamageBooster_Info"));
	str += combine(prefix, l("#SS_MASSMOUNT_NAME"), suffix, l("#SP_MassMount_Info"));
	str += combine(prefix, l("#SS_SPINMOUNTHULL_NAME"), suffix, l("#SP_SpinalMountHull_Info"));
	str += combine(prefix, l("#SS_GARGANTHULL_NAME"), suffix, l("#SP_GargantuanHull_Info"));
	str += combine(prefix, l("#SS_FORTRESSHULL_NAME"), suffix, l("#SP_FortressHull_Info"));
	str += combine(prefix, l("#SS_EXMAG_NAME"), suffix, l("#SP_ExtendedMagazine_Info"));
	
	text.setText(str);
	addCategory("modifiers", "#SP_Cat_Modifiers", panel);		
	
	//Sub Systems
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	text.setText(l("#SP_SubSystems_Intro"));
	addCategory("subsys", "#SP_Cat_SubSystems", panel);
	
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	text.setText(l("#SP_SS_Hulls_Intro"));
	fillSubSystems(SS_Hull, panel, text.getSize().height+8, true);
	addCategory("ss_hulls", "#SP_Cat_SS_Hulls", panel);
	
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	text.setText(l("#SP_SS_Control_Intro"));
	fillSubSystems(SS_Control, panel, text.getSize().height+8, true);
	addCategory("ss_control", "#SP_Cat_SS_Control", panel);
	
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	text.setText(l("#SP_SS_Power_Intro"));
	fillSubSystems(SS_Power, panel, text.getSize().height+8, true);
	addCategory("ss_power", "#SP_Cat_SS_Power", panel);	
	
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	text.setText(l("#SP_SS_Engines_Intro"));
	fillSubSystems(SS_Engine, panel, text.getSize().height+8, true);
	addCategory("ss_engines", "#SP_Cat_SS_Engines", panel);
	
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	text.setText(l("#SP_SS_Support_Intro"));
	fillSubSystems(SS_Support, panel, text.getSize().height+8, true);
	addCategory("ss_support", "#SP_Cat_SS_Support", panel);
	
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	text.setText(l("#SP_SS_Storage_Intro"));
	fillSubSystems(SS_Storage, panel, text.getSize().height+8, true);
	addCategory("ss_storage", "#SP_Cat_SS_Storage", panel);
	
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	text.setText(l("#SP_SS_ProjWeapons_Intro"));
	fillSubSystems(SS_ProjWeapon, panel, text.getSize().height+8, true);
	addCategory("ss_projweapon", "#SP_Cat_SS_ProjWeapons", panel);
	
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	text.setText(l("#SP_SS_BeamEnergyWeapons_Intro"));
	fillSubSystems(SS_BeamEnergyWeapon, panel, text.getSize().height+8, true);
	addCategory("ss_beamenergyweapon", "#SP_Cat_SS_BeamEnergyWeapons", panel);
	
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	text.setText(l("#SP_SS_MissileWeapons_Intro"));
	fillSubSystems(SS_MissileWeapon, panel, text.getSize().height+8, true);
	addCategory("ss_missileweapon", "#SP_Cat_SS_MissileWeapons", panel);

	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	text.setText(l("#SP_SS_SpecWeapons_Intro"));
	fillSubSystems(SS_SpecWeapon, panel, text.getSize().height+8, true);
	addCategory("ss_specweapon", "#SP_Cat_SS_SpecWeapons", panel);
	
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	text.setText(l("#SP_SS_FighterBomberWeapons_Intro"));
	fillSubSystems(SS_FighterBomberWeapon, panel, text.getSize().height+8, true);
	addCategory("ss_fighterbomberweapon", "#SP_Cat_SS_FighterBomberWeapons", panel);
	
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	text.setText(l("#SP_SS_Defense_Intro"));
	fillSubSystems(SS_Defense, panel, text.getSize().height+8, true);
	addCategory("ss_defense", "#SP_Cat_SS_Defense", panel);
	
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	text.setText(l("#SP_SS_Armor_Intro"));
	fillSubSystems(SS_Armor, panel, text.getSize().height+8, true);
	addCategory("ss_armor", "#SP_Cat_SS_Armor", panel);
	
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	text.setText(l("#SP_SS_Shields_Intro"));
	fillSubSystems(SS_Shields, panel, text.getSize().height+8, true);
	addCategory("ss_shields", "#SP_Cat_SS_Shields", panel);
	
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	text.setText(l("#SP_SS_Modifiers_Intro"));
	fillSubSystems(SS_Modifier, panel, text.getSize().height+8, true);
	addCategory("ss_modifiers", "#SP_Cat_SS_Modifiers", panel);
	
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	text.setText(l("#SP_SS_Docks_Intro"));
	fillSubSystems(SS_Docks, panel, text.getSize().height+8, true);
	addCategory("ss_docks", "#SP_Cat_SS_Docks", panel);	
	
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	text.setText(l("#SP_SS_Other_Intro"));
	fillSubSystems(SS_Other, panel, text.getSize().height+8, true);
	addCategory("ss_other", "#SP_Cat_SS_Other", panel);

	// Research
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);
	@str = docText("#doc tech");
	text.setText(str);
	addCategory("doc_tech", "#doc tech title", panel);

	// Research Fields
	@panel = makeFramePanel();
	@text = makeFittingExtendedText(panel);

	@str = l("#SP_Cat_Research_Intro")+"\n\n#c:link#";
	bool leftColumn = true;
	for (uint i = 0; i < getWebItemDescCount(); ++i) {
		const WebItemDesc@ def = getWebItemDesc(i);
		if(leftColumn)
			str += "\n#tab:110##link:h:sp-rs:"+def.id+"#"+def.name+"#link#";
		else
			str += "#tab:310##link:h:sp-rs:"+def.id+"#"+def.name+"#link#";
		leftColumn = !leftColumn;
	}

	text.setText(str);
	addCategory("research", "#SP_Cat_Research", panel);

	//Pseudo-page
	@pseudoPage = makeFramePanel();
	@pseudoTitle = makeFittingExtendedText(pseudoPage);
	@pseudoDescription = makeFittingExtendedText(pseudoPage);
	@pseudoContent = makeFittingExtendedText(pseudoPage);
	@pseudoImage = GuiImage(pos2di(5, 38), "", pseudoPage);

	pseudoDescription.setPosition(pos2di(75, 38));
	
	//Template
	//@panel = makeFramePanel();
	//@text = makeFittingExtendedText(panel);
	//text.setText(l("#SP_Template_Page"));
	//addCategory("template", "#SP_Template", panel);
}

enum SS_Type {
	SS_Hull,
	SS_Control,
	SS_Power,
	SS_Support,
	SS_Storage,
	SS_ProjWeapon,
	SS_BeamEnergyWeapon,
	SS_MissileWeapon,
	SS_SpecWeapon,
	SS_Defense,
	SS_Armor,
	SS_Shields,
	SS_Structure,
	SS_Modifier,
	SS_FighterBomberWeapon,
	SS_Engine,
	SS_Docks,
	SS_Improvement,
	SS_Other,
};

const string@ strControl = "Control", strStorage = "Storage", strStructure = "Structure", strBomberWeapon = "BomberWeapon", strFighterWeapon = "FighterWeapon", strProjWeapon = "ProjWeapon", strBeamEnergyWeapon = "BeamEnergyWeapon", strMissileWeapon = "MissileWeapon", strSpecWeapon = "SpecWeapon", strHull = "Hull", strSupport = "Support", strDefend = "Defense", strArmor = "Armor", strShields = "Shields", strLink = "Link", strEngine = "Engine", strImprovement = "Improvement", strPower = "Power", strBankAccess = "BankAccess";
SS_Type getType(const subSystemDef@ def) {
	if(def.hasTag(strStructure))
		return SS_Structure;
	if(def.hasTag(strHull))
		return SS_Hull;
	if(def.hasTag(strControl))
		return SS_Control;
	if(def.hasTag(strPower))
		return SS_Power;
	if(def.hasTag(strStorage))
		return SS_Storage;
	if(def.hasTag(strSupport))
		return SS_Support;
	if(def.hasTag(strEngine))
		return SS_Engine;
	if(def.hasTag(strProjWeapon))
		return SS_ProjWeapon;
	if(def.hasTag(strBeamEnergyWeapon))
		return SS_BeamEnergyWeapon;
	if(def.hasTag(strMissileWeapon))
		return SS_MissileWeapon;
	if(def.hasTag(strSpecWeapon))
		return SS_SpecWeapon;
	if(def.hasTag(strFighterWeapon) || def.hasTag(strBomberWeapon))
		return SS_FighterBomberWeapon;
	if(def.hasTag(strDefend))
		return SS_Defense;
	if(def.hasTag(strArmor))
		return SS_Armor;
	if(def.hasTag(strShields))
		return SS_Shields;
	if(def.hasTag(strLink))
		return SS_Modifier;
	if(def.hasTag(strImprovement))
		return SS_Improvement;
	if(def.hasTag(strBankAccess) && !def.hasTag(strStructure))
		return SS_Docks;
	return SS_Other;
}

void fillSubSystems(SS_Type type, GuiPanel@ panel, int startY, bool showImages) {
	int y = startY;
	uint sysCount = getSubSystemCount();
	for(uint i = 0; i < sysCount; ++i) {
		const subSystemDef@ def = getSubSystemDef(i);
		if(getType(def) != type)
			continue;

		if (showImages) {
			GuiImage@ img = GuiImage(pos2di(1,y), def.getImage(), panel);
			img.setSize(dim2di(64,64));
			img.setScaleImage(true);
			img.orphan(true);
		}
		
		GuiExtText@ txt = GuiExtText(recti(showImages ? 70 : 5,y,650,y+16), panel);

		if (showImages)
			txt.setText(combine("#font:frank_11#", def.getName(), "\n#hline#"));
		else
			txt.setText(combine("#font:frank_11##c:bfb#", def.getName(), "#c#\n#hline#"));
			
		txt.orphan(true);
		
		GuiExtText@ desc = GuiExtText(recti(showImages ? 70 : 5,y+24,650,y+25), panel);
		if(def.getTieCount() == 0) {
			desc.setText(def.getDescription());
		}
		else {
			string@ txt = def.getDescription()+"#r#"; 
			bool firstTie = true;
			for(uint t = 0; t < def.getTieCount(); ++t) {
				const WebItemDesc@ tech = def.getTie(t);
				if(def.getTieLevel(t) > 0) {
					if(firstTie) {
						txt += combine("\n#c:ccc#", locale_requires, ":#c# ");
						firstTie = false;
					}
					else {
						txt += ", ";
					}

					txt += combine(combine("#c:link##link:h:sp-rs:", tech.id, "#", tech.name, "#link##c# #c:faa#"), i_to_s(def.getTieLevel(t)), "#c#");
				}
			}
			desc.setText(txt);
		}
		desc.orphan(true);
		
		y += 24 + max(64,26 + desc.getSize().height);
	}
}

void fillSubSystemDetails(const subSystemDef@ def) {
	if (def is null)
		return;

	// Image
	pseudoImage.setImage(def.getImage());
	pseudoImage.setScaleImage(true);
	pseudoImage.setSize(dim2di(64, 64));

	// Set the correct text
	pseudoTitle.setText(combine("#font:goodtimes_14##c:0d0#",def.getName(),"\n#hline##c##font#\n"));
	pseudoDescription.setText(def.getDescription());

	if(def.getTieCount() > 0) {
		string@ txt = "";
		bool firstTie = true;
		for(uint t = 0; t < def.getTieCount(); ++t) {
			const WebItemDesc@ tech = def.getTie(t);
			if(def.getTieLevel(t) > 0) {
				if(firstTie) {
					txt += combine("#c:ccc#",locale_requires,":#c# ");
					firstTie = false;
				}
				else {
					txt += ", ";
				}

				txt += combine(combine("#c:link##link:h:sp-rs:", tech.id, "#", tech.name, "#link##c# #c:faa#"), i_to_s(def.getTieLevel(t)), "#c#");
			}
		}

		pseudoContent.setVisible(true);
		pseudoContent.setText(txt);
		pseudoContent.setPosition(pos2di(16, max(pseudoDescription.getSize().height, 64)+48));
	}
	else {
		pseudoContent.setVisible(false);
	}

	pseudoPage.fitChildren();
}

void fillResearchDetails(const WebItemDesc@ def) {
	// Image
	pseudoImage.setImage(def.icon);
	pseudoImage.setScaleImage(true);
	pseudoImage.setSize(dim2di(64, 64));

	// Set the correct text
	pseudoTitle.setText(combine("#c:0d0##font:goodtimes_14#",def.name,"\n#hline##font##c#\n"));
	pseudoDescription.setText(def.desc);

	// Improves and unlocks text
	string@ improves = combine("#c:4f0##font:frank_11#",localize("#SP_Research_Improves"),"#font##c#");
	string@ unlocks = combine("\n\n#c:ff4##font:frank_11#",localize("#SP_Research_Unlocks"),"#font##c#");

	uint tiecnt = def.getTieCount();
	for (uint i = 0; i < tiecnt; ++i) {
		const subSystemDef@ tie = def.getTie(i);
		uint lvl = def.getTieLevel(i);

		improves += "\n#tab:8#"+tie.getName();

		//Check reverse ties
		unlocks += "\n#tab:8#"+tie.getName();
		uint revcnt = tie.getTieCount();
		for (uint j = 0; j < revcnt; ++j) {
			const WebItemDesc@ rev = tie.getTie(j);
			uint revlvl = tie.getTieLevel(j);

			unlocks += combine(combine("\n#tab:8#    #c:ccc#",(j == 0? locale_with : locale_and),"#c# ",
				(rev is def ? "#c:4a0#":"#c:link#"),
				"#link:h:sp-rs:"), combine(rev.id,"#",rev.name,
				"#c# #c:ccc#",locale_atlevel), combine("#c# #c:faa#",i_to_s(revlvl),"#c#"));
		}
	}

	pseudoContent.setText(improves+unlocks);

	// Set correct position
	pseudoContent.setPosition(pos2di(16, max(pseudoDescription.getSize().height, 64)+48));
	pseudoContent.setVisible(true);
	pseudoPage.fitChildren();
}

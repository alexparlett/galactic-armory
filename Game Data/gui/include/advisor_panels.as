//advisor_panels.as
//=================
//panels

/* {{{ Econ Panel Script */
class econPanel : ScriptedGuiHandler, infoPanel {
	GuiScripted@ scripted;

	GuiScripted@ metalIco;
	GuiStaticText@ metalEff;
	GuiStaticText@ metalCargo;
	GuiScripted@ metalIEOpt;
	gui_sprite@ metalIEOpt_h;
	GuiScripted@ metalIE;
	gui_sprite@ metalIE_h;

	GuiScripted@ elecIco;
	GuiStaticText@ elecEff;
	GuiStaticText@ elecCargo;
	GuiScripted@ elecIEOpt;
	gui_sprite@ elecIEOpt_h;
	GuiScripted@ elecIE;
	gui_sprite@ elecIE_h;

	GuiScripted@ advIco;
	GuiStaticText@ advEff;
	GuiStaticText@ advCargo;
	GuiScripted@ advIEOpt;
	gui_sprite@ advIEOpt_h;
	GuiScripted@ advIE;
	gui_sprite@ advIE_h;

	GuiScripted@ labrIco;
	GuiStaticText@ labrAvail;
	GuiStaticText@ tradeCapacity;

	Planet@ pl;

	econPanel(Planet@ pl, pos2di position, GuiElement@ parent) {
		@this.pl = pl;

		recti rE = r(position,INFOPANEL_WIDTH,INFOPANEL_HEIGHT);
		@scripted = GuiScripted(rE, this, parent);

		// Resource column header
		recti rMetalIco = r(10, 2, 10, 10);
		@metalIco = GuiScripted(rMetalIco, gui_sprite("planet_resource_list", 2), scripted);
		recti rElecIco = r(ur(rMetalIco, 45, 0), 10, 10);
		@elecIco = GuiScripted(rElecIco, gui_sprite("planet_resource_list", 1), scripted);
		recti rAdvIco = r(ur(rElecIco, 45, 0), 10, 10);
		@advIco = GuiScripted(rAdvIco, gui_sprite("planet_resource_list", 0), scripted);
		recti rLabrIco = r(ur(rAdvIco, 45, 0), 10, 10);
		@labrIco = GuiScripted(rLabrIco, gui_sprite("planet_resource_list", 3), scripted);

		// Tooltips
		metalIco.setToolTip("Metal production efficiency / Metal cargo");
		elecIco.setToolTip("Electronics production efficiency / Electronics cargo");
		advIco.setToolTip("Adv. Parts production efficiency / Adv. Parts cargo");
		labrIco.setToolTip("Labor capacity / Trade capacity");

		// Resource values
		recti rEff = r(0, 12, 35, 15);
		@metalEff = GuiStaticText(rEff, null, false, false, false, scripted);
		metalEff.setTextAlignment(EA_Center, EA_Top);
		recti rCargo = r(0, 25, 35, 15);
		@metalCargo = GuiStaticText(rCargo, null, false, false, false, scripted);
		metalCargo.setTextAlignment(EA_Center, EA_Top);

		rEff = r(ul(rEff, 55, 0), 35, 15);
		@elecEff = GuiStaticText(rEff, null, false, false, false, scripted);
		elecEff.setTextAlignment(EA_Center, EA_Top);
		rCargo = r(ul(rCargo, 55, 0), 35, 15);
		@elecCargo = GuiStaticText(rCargo, null, false, false, false, scripted);
		elecCargo.setTextAlignment(EA_Center, EA_Top);

		rEff = r(ul(rEff, 55, 0), 35, 15);
		@advEff = GuiStaticText(rEff, null, false, false, false, scripted);
		advEff.setTextAlignment(EA_Center, EA_Top);
		rCargo = r(ul(rCargo, 55, 0), 35, 15);
		@advCargo = GuiStaticText(rCargo, null, false, false, false, scripted);
		advCargo.setTextAlignment(EA_Center, EA_Top);

		rEff = r(ul(rEff, 55, 0), 35, 15);
		@labrAvail = GuiStaticText(rEff, null, false, false, false, scripted);
		labrAvail.setTextAlignment(EA_Center, EA_Top);
		rCargo = r(ul(rCargo, 55, 0), 35, 15);
		@tradeCapacity = GuiStaticText(rCargo, null, false, false, false, scripted);
		tradeCapacity.setTextAlignment(EA_Center, EA_Top);

		// Import / Export indicators
		recti rIEOpt = r(35, 16, 10, 10);
		@metalIEOpt_h = gui_sprite("delta_state", 0);
		@metalIEOpt = GuiScripted(rIEOpt, metalIEOpt_h, scripted);
		recti rIE = r(35, 29, 10, 10);
		@metalIE_h = gui_sprite("delta_state", 0);
		@metalIE = GuiScripted(rIE, metalIE_h, scripted);

		rIEOpt = r(ul(rIEOpt, 55, 0), 10, 10);
		@elecIEOpt_h = gui_sprite("delta_state", 0);
		@elecIEOpt = GuiScripted(rIEOpt, elecIEOpt_h, scripted);
		rIE = r(ul(rIE, 55, 0), 10, 10);
		@elecIE_h = gui_sprite("delta_state", 0);
		@elecIE = GuiScripted(rIE, elecIE_h, scripted);

		rIEOpt = r(ul(rIEOpt, 55, 0), 10, 10);
		@advIEOpt_h = gui_sprite("delta_state", 0);
		@advIEOpt = GuiScripted(rIEOpt, advIEOpt_h, scripted);
		rIE = r(ul(rIE, 55, 0), 10, 10);
		@advIE_h = gui_sprite("delta_state", 0);
		@advIE = GuiScripted(rIE, advIE_h, scripted);

		update();
	}

	void draw(GuiElement@ ele) {
	}

	void update() {
		if (@pl == null) 
			return;
		Object@ obj = pl.toObject();
		if ( obj.getOwner() !is getActiveEmpire() )
		{
			// only return to prevent errors - planet will get removed from list at next list update
			return;
		}
		PlStates@ pls = PlStates(obj);

		updateProd(metalEff, pls.MtlGen.val, pls.MtlGenOpt.val);					// Metals (Production efficiency)
		updateCargo(metalCargo, pls.Mtl, pls.TradeTarget, pls.Cargo, pls.MtlExp);	// Metals (Cargo %)
		updateProd(elecEff, pls.ElcGen.val, pls.ElcGenOpt.val);						// Electronics (Production efficiency)
		updateCargo(elecCargo, pls.Elc, pls.TradeTarget, pls.Cargo, pls.ElcExp);	// Electronics (Cargo %)
		updateProd(advEff, pls.AdvGen.val, pls.AdvGenOpt.val);						// AdvParts (Production efficiency)
		updateCargo(advCargo, pls.Adv, pls.TradeTarget, pls.Cargo, pls.AdvExp);		// AdvParts (Cargo %)
		updateLabor(labrAvail, pls.Labor);											// Labor %
		updateTrade(tradeCapacity, pls.Trade);										// Trade usage / capacity

		updateIE(metalIEOpt, metalIEOpt_h, pls.MtlExp, true);						// Metals (Import / Export Optimal)
		updateIE(metalIE, metalIE_h, pls.MtlGen.cargo, false);						// Metals (Import / Export Real)
		updateIE(elecIEOpt, elecIEOpt_h, pls.ElcExp, true);							// Electronics (Import / Export Optimal)
		updateIE(elecIE, elecIE_h, pls.ElcGen.cargo, false);						// Electronics (Import / Export Real)
		updateIE(advIEOpt, advIEOpt_h, pls.AdvExp, true);							// AdvParts (Import / Export Optimal)
		updateIE(advIE, advIE_h, pls.AdvGen.cargo, false);							// AdvParts (Import / Export Real)
	}

	void setPlanet(Planet@ pl) {
		@this.pl = pl;
	}

	void setPosition(pos2di p) {
		scripted.setPosition(p);
	}

	void setSize() {
		scripted.setSize(dim2di(INFOPANEL_WIDTH, INFOPANEL_HEIGHT));
	}

	void remove() {
		scripted.orphan(true);
		scripted.remove();
		@pl = null;
	}

	EventReturn onGUIEvent(GuiElement@ ele, const GUIEvent& evt) {
		return ER_Pass;
	}

	EventReturn onMouseEvent(GuiElement@ ele, const MouseEvent& evt) {
		return ER_Pass;
	}

	EventReturn onKeyEvent(GuiElement@ ele, const KeyEvent& evt) {
		return ER_Pass;
	}
}
/* }}} */

/* {{{ Structure Panel Script */
class structurePanel : ScriptedGuiHandler, infoPanel {
	GuiScripted@ scripted;

	GuiImage@ planetSpaceIco;
	GuiStaticText@ planetSpace;
	GuiStaticText@ planetSpaceQue;

	GuiImage@ planetFullIco;
	GuiStaticText@ planetFull;
	GuiStaticText@ planetFullQue;

	GuiImage@ workersIco;
	GuiStaticText@ availWorkers;
	GuiStaticText@ availWorkersQue;

	GuiImage@ offIco;
	GuiStaticText@ stOffline;
	GuiStaticText@ stDestroyed;

	Planet@ pl;

	structurePanel(Planet@ pl, pos2di position, GuiElement@ parent) {
		@this.pl = pl;

		recti rE = r(position,INFOPANEL_WIDTH,INFOPANEL_HEIGHT);
		@scripted = GuiScripted(rE, this, parent);

		// Header
		recti rPlanetSpaceIco = r(8, 0, 10, 10);
		@planetSpaceIco = GuiImage(ul(rPlanetSpaceIco), "planet_space_notfull", scripted);
		recti rPlanetFullIco =  r(ul(rPlanetSpaceIco, 40, 0), 10, 10);
		@planetFullIco = GuiImage(ul(rPlanetFullIco), "planet_space_full", scripted);
		recti rWorkersIco =  r(ul(rPlanetFullIco, 65, 2), 10, 10);
		@workersIco = GuiImage(ul(rWorkersIco), "worker_ico", scripted);
		recti rOff =  r(ul(rWorkersIco, 65, 0), 10, 10);
		@offIco = GuiImage(ul(rOff), "labor_ico", scripted);

		// Tooltips
		planetSpaceIco.setToolTip("Empty slots / Empty slots queue included");
		planetFullIco.setToolTip("Buildings / Buildings queue included");
		workersIco.setToolTip("Available workers / Available workers queue included");
		offIco.setToolTip("Buildings offline / Buildings destroyed");

		// Info
		recti rPlSpace = r(0, 12, 30, 15);
		@planetSpace = GuiStaticText(rPlSpace, null, false, false, false, scripted);
		planetSpace.setTextAlignment(EA_Center, EA_Top);
		recti rPlSpaceQue = r(0, 25, 30, 15);
		@planetSpaceQue = GuiStaticText(rPlSpaceQue, null, false, false, false, scripted);
		planetSpaceQue.setTextAlignment(EA_Center, EA_Top);

		rPlSpace = r(ul(rPlSpace, 40, 0), 30, 15);
		@planetFull = GuiStaticText(rPlSpace, null, false, false, false, scripted);
		planetFull.setTextAlignment(EA_Center, EA_Top);
		rPlSpaceQue = r(ul(rPlSpaceQue, 40, 0), 30, 15);
		@planetFullQue = GuiStaticText(rPlSpaceQue, null, false, false, false, scripted);
		planetFullQue.setTextAlignment(EA_Center, EA_Top);

		rPlSpace = r(ul(rPlSpace, 50, 0), 60, 15);
		@availWorkers = GuiStaticText(rPlSpace, null, false, false, false, scripted);
		availWorkers.setTextAlignment(EA_Center, EA_Top);
		rPlSpaceQue = r(ul(rPlSpaceQue, 50, 0), 60, 15);
		@availWorkersQue = GuiStaticText(rPlSpaceQue, null, false, false, false, scripted);
		availWorkersQue.setTextAlignment(EA_Center, EA_Top);

		rPlSpace = r(ul(rPlSpace, 80, 0), 30, 15);
		@stOffline = GuiStaticText(rPlSpace, null, false, false, false, scripted);
		stOffline.setTextAlignment(EA_Center, EA_Top);
		rPlSpaceQue = r(ul(rPlSpaceQue, 80, 0), 30, 15);
		@stDestroyed = GuiStaticText(rPlSpaceQue, null, false, false, false, scripted);
		stDestroyed.setTextAlignment(EA_Center, EA_Top);

		update();
	}

	void draw(GuiElement@ ele) {
	}

	void update() {
		if (@pl == null) 
			return;
		Object@ obj = pl.toObject();
		if ( obj.getOwner() !is getActiveEmpire() )
		{
			// only return to prevent errors - planet will get removed from list at next list update
			return;
		}

		uint[] arrEmpDef = getStructuresWithHousingOrWorkers(obj);

		int cnt = pl.getStructureCount();
		int max = pl.getMaxStructureCount();

		float housing_que = 0;
		float workers_que = 0;
		int queStr = 0;
		uint que = obj.getConstructionQueueSize();
		for (uint i = 0; i < que; ++i) {
			string@ type = obj.getConstructionType(i);
			string@ name = obj.getConstructionName(i);
			if (@type != null && type == "structure")
			{
				SubSystemFactory factory;
				subSystem@ ss = getSubSystemFromName(factory, pl, name, arrEmpDef);
				if (@ss != null) {
					if (ss.hasHint(strHousing))
						housing_que += ss.getHint(strHousing);
					if (ss.hasHint(strWorkers))
						workers_que += ss.getHint(strWorkers);
				}

				++queStr;
			}
		}

		PlanetStructureList list;
		list.prepare(pl);
		uint strCnt = list.getCount();

		float housing = 0;
		float workers = 0;
		int offline = 0;
		int destroyed = 0;
		for(uint i = 0; i < strCnt; ++i) {
			const subSystem@ ss = list.getStructure(i);

			if (ss.hasHint(strHousing))
				housing += ss.getHint(strHousing);
			if (ss.hasHint(strWorkers))
				workers += ss.getHint(strWorkers);

			switch(list.getStructureState(i).getState()) {
				case SS_Disabled:
					offline++;
					break;
				case SS_Destroyed:
					destroyed++;
					break;
			}
		}

		updateStructures(planetSpace, planetSpaceQue, planetFull, planetFullQue, max, cnt, queStr);
		updateOffline(stOffline, stDestroyed, offline, destroyed);
		updateWorkers(availWorkers, availWorkersQue, housing, housing_que, workers, workers_que, queStr);
	}

	void setPlanet(Planet@ pl) {
		@this.pl = pl;
	}

	void setPosition(pos2di p) {
		scripted.setPosition(p);
	}

	void setSize() {
		scripted.setSize(dim2di(INFOPANEL_WIDTH, INFOPANEL_HEIGHT));
	}

	void remove() {
		scripted.orphan(true);
		scripted.remove();
		@pl = null;
	}

	EventReturn onGUIEvent(GuiElement@ ele, const GUIEvent& evt) {
		return ER_Pass;
	}

	EventReturn onMouseEvent(GuiElement@ ele, const MouseEvent& evt) {
		return ER_Pass;
	}

	EventReturn onKeyEvent(GuiElement@ ele, const KeyEvent& evt) {
		return ER_Pass;
	}
}
/* }}} */

/* {{{ Empty Panel Script */
class emptyPanel : ScriptedGuiHandler, infoPanel {
	GuiScripted@ scripted;

	emptyPanel(Planet@ pl, pos2di position, GuiElement@ parent) {
		recti rE = r(position,INFOPANEL_WIDTH,INFOPANEL_HEIGHT);
		@scripted = GuiScripted(rE, this, parent);

		update();
	}

	void draw(GuiElement@ ele) {
	}

	void update() {
	}

	void setPlanet(Planet@ pl) {
	}

	void setPosition(pos2di p) {
		scripted.setPosition(p);
	}

	void setSize() {
		scripted.setSize(dim2di(INFOPANEL_WIDTH, INFOPANEL_HEIGHT));
	}

	void remove() {
		scripted.orphan(true);
		scripted.remove();
	}

	EventReturn onGUIEvent(GuiElement@ ele, const GUIEvent& evt) {
		return ER_Pass;
	}

	EventReturn onMouseEvent(GuiElement@ ele, const MouseEvent& evt) {
		return ER_Pass;
	}

	EventReturn onKeyEvent(GuiElement@ ele, const KeyEvent& evt) {
		return ER_Pass;
	}
}
/* }}} */
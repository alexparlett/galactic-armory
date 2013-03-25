#include "~/Game Data/gui/include/gui_skin.as"
#include "/include/empire_image.as"
#include "~/Game Data/gui/include/dialog.as"

import recti makeScreenCenteredRect(const dim2di &in rectSize) from "gui_lib";

// {{{ Exports
void showTreaty(const Treaty@ treaty) {
	showTradeWindow(treaty);
}

void proposeNewTreaty(const Empire@ other) {
	showTradeWindow(other);
}

void showTreatyWindow() {
	toggleTradeWindow(true);
}
// }}}
/* {{{ Trade Window Handle */
class TradeWindowHandle {
	TradeWindow@ script;
	GuiScripted@ ele;

	TradeWindowHandle(recti Position) {
		@script = TradeWindow();
		@ele = GuiScripted(Position, script, null);

		script.init(ele);
		script.syncPosition(Position.getSize());
	}

	void bringToFront() {
		ele.bringToFront();
		bindEscapeEvent(ele);
	}

	void setVisible(bool vis) {
		ele.setVisible(vis);

		if (vis)
			bindEscapeEvent(ele);
		else
			clearEscapeEvent(ele);
	}

	const Treaty@ getTreaty() {
		return script.getTreaty();
	}

	void setTreaty(const Treaty@ treaty) {
		script.editable = false;
		script.syncPosition(ele.getSize());

		script.viewTreaty(treaty);

		if (treaty.isProposed()) {
			if (treaty.getFromEmpire() is getActiveEmpire()) {
				script.addButton("treaty_buttons2", 0, 1, 0, script.alterButtonID, ele);
				script.addButton("treaty_buttons2", 3, 4, 3, script.retractButtonID, ele);
			}
			else {
				script.addButton("treaty_buttons", 6, 7, 6, script.acceptButtonID, ele);
				script.addButton("treaty_buttons", 9, 10, 9, script.rejectButtonID, ele);
				script.addButton("treaty_buttons2", 0, 1, 0, script.alterButtonID, ele);
			}
		}

		script.syncPosition(ele.getSize());
	}

	void alterTreaty(const Treaty@ treaty) {
		script.duplicateTreaty(treaty);
		script.addButton("treaty_buttons", 0, 1, 0, script.sendButtonID, ele);

		script.syncPosition(ele.getSize());
	}

	void setEmpireTo(const Empire@ other) {
		script.setEmpireTo(other);
		script.addButton("treaty_buttons", 0, 1, 0, script.sendButtonID, ele);

		script.syncPosition(ele.getSize());
	}

	bool isVisible() {
		return ele.isVisible();
	}

	pos2di getPosition() {
		return ele.getPosition();
	}

	void update(float time) {
		script.update(time);
		script.position = ele.getPosition();
	}

	void remove() {
		clearEscapeEvent(ele);
		ele.remove();
		script.removed = true;
	}
};

/* }}} */
/* {{{ Trade Window Script */
const float updateEntryInterval = 1.f;
class ProposeTreatyCallback : ConfirmDialogCallback {
	TradeWindow@ win;

	ProposeTreatyCallback(TradeWindow@ window) {
		@win = window;
	}

	void call(ConfirmDialog@ dialog, bool accept) {
		if (win is null || win.removed)
			return;

		if (accept) {
			win.factory.propose();
			closeTradeWindow(win);
		}
	}
};

class TradeWindow : ScriptedGuiHandler {
	DragResizeInfo drag;
	pos2di position;
	bool removed;

	const Treaty@ treaty;
	const Empire@ empireTo;

	const Empire@ topEmp;
	const Empire@ botEmp;

	TreatyFactory@ factory;
	bool editable;
	bool hasButtons;

	TradeWindow() {
		removed = false;
		editable = true;
		hasButtons = false;
	}

	bool isTreatyEdittable() {
		return editable;
	}

	Treaty@ getEditTreaty() {
		if (factory is null)
			return null;
		return factory.treaty;
	}

	const Treaty@ getReadTreaty() {
		if(editable)
			return factory.treaty;
		else
			return treaty;
	}

	/* {{{ Main interface */
	GuiButton@ close;

	EmpireImage@ topEmpImg;
	EmpireImage@ botEmpImg;

	GuiExtText@ topEmpName;
	GuiExtText@ botEmpName;

	GuiPanel@ leftAddClauseList;
	GuiPanel@ rightAddClauseList;

	ClauseList@ upperClauseList;
	ClauseList@ lowerClauseList;

	AddClause@[] addClauseList;
	AddClause@[] leftAddClause;
	AddClause@[] rightAddClause;

	GuiButton@[] centerButtons;

	int sendButtonID;
	int acceptButtonID;
	int alterButtonID;
	int retractButtonID;
	int rejectButtonID;

	float updateEntryTime;

	void init(GuiElement@ ele) {
		// Reserve button IDs
		sendButtonID = reserveGuiID();
		acceptButtonID = reserveGuiID();
		alterButtonID = reserveGuiID();
		retractButtonID = reserveGuiID();
		rejectButtonID = reserveGuiID();

		updateEntryTime = 0.f;

		// Close button
		@close = CloseButton(recti(), ele);

		// Empire images
		@topEmpImg = EmpireImage(null, recti(0, 0, 215, 160), ele);
		@botEmpImg = EmpireImage(null, recti(0, 0, 215, 160), ele);
		topEmpImg.setMirror(true);

		// Empire names
		@topEmpName = GuiExtText(recti(), ele);
		@botEmpName = GuiExtText(recti(), ele);

		// Add panels
		@leftAddClauseList = GuiPanel(recti(0, 0, 215, 100), false, SBM_Auto, SBM_Invisible, ele);
		leftAddClauseList.fitChildren();

		@rightAddClauseList = GuiPanel(recti(0, 0, 215, 100), false, SBM_Auto, SBM_Invisible, ele);
		rightAddClauseList.fitChildren();

		{ //Fill in the left and right Add Clause lists
			int yOff = 0, index = 0; bool side;
			//Reserve no more than will be added here, to save time
			addClauseList.resize(9);
			
			side = true; //Left side
			//applyAddClause( ClauseSeparator(localize("#TRW_Offensive"), yOff, side, this), index, yOff);
			applyAddClause( ClauseAddButton(getClauseDesc("war"), yOff, side, this), index, yOff);
			//applyAddClause( ClauseSeparator(localize("#TRW_Tools"), yOff, side, this), index, yOff);
			applyAddClause( ClauseAddButton(getClauseDesc("timeout"), yOff, side, this), index, yOff);
			//applyAddClause( ClauseSeparator(localize("#TRW_Normal"), yOff, side, this), index, yOff);
			applyAddClause( ClauseAddButton(getClauseDesc("peace"), yOff, side, this), index, yOff);
			applyAddClause( ClauseAddButton(getClauseDesc("send"), yOff, side, this), index, yOff);
			applyAddClause( ClauseAddButton(getClauseDesc("vision"), yOff, side, this), index, yOff);
			applyAddClause( ClauseAddButton(getClauseDesc("trade"), yOff, side, this), index, yOff);
			applyAddClause( ClauseAddButton(getClauseDesc("research"), yOff, side, this), index, yOff);
			applyAddClause( ClauseAddButton(getClauseDesc("endall"), yOff, side, this), index, yOff);
			applyAddClause( ClauseAddButton(getClauseDesc("failwar"), yOff, side, this), index, yOff);
			
			yOff = 0; side = false; //Right side
			//applyAddClause( ClauseSeparator(localize("#TRW_Normal"), yOff, side, this), index, yOff);
			applyAddClause( ClauseAddButton(getClauseDesc("send"), yOff, side, this), index, yOff);
			applyAddClause( ClauseAddButton(getClauseDesc("vision"), yOff, side, this), index, yOff);
			applyAddClause( ClauseAddButton(getClauseDesc("trade"), yOff, side, this), index, yOff);
			applyAddClause( ClauseAddButton(getClauseDesc("research"), yOff, side, this), index, yOff);
			
			leftAddClauseList.fitChildren();
			rightAddClauseList.fitChildren();
		}	

		// Clause lists
		@upperClauseList = ClauseList(recti(0, 0, 100, 100), this, ele);
		@lowerClauseList = ClauseList(recti(0, 0, 100, 100), this, ele);
	}

	void checkAddClauses() {
		int yOff = 0;
		uint cnt = leftAddClause.length();
		for (uint i = 0; i < cnt; ++i) {
			AddClause@ btn = leftAddClause[i];
			if (btn.canAdd()) {
				btn.setPosition(pos2di(0, yOff));
				btn.setVisible(true);
				yOff += btn.getHeight();
			}
			else {
				btn.setVisible(false);
				btn.setPosition(pos2di(0, 0));
			}
		}
		leftAddClauseList.fitChildren();

		yOff = 0;
		cnt = rightAddClause.length();
		for (uint i = 0; i < cnt; ++i) {
			AddClause@ btn = rightAddClause[i];
			if (btn.canAdd()) {
				btn.setPosition(pos2di(0, yOff));
				btn.setVisible(true);
				yOff += btn.getHeight();
			}
			else {
				btn.setVisible(false);
				btn.setPosition(pos2di(0, 0));
			}
		}
		rightAddClauseList.fitChildren();
	}

	void updateButtonPositions(dim2di size) {
		uint btnCnt = centerButtons.length();
		int x = (size.width - btnCnt * 208) / 2;
		int y = size.height - 36 - 7;

		for (uint i = 0; i < btnCnt; ++i) {
			centerButtons[i].setPosition(pos2di(x, y));
			x += 208;
		}
	}

	void addButton(string@ sprite, int ind1, int ind2, int ind3, int id, GuiElement@ parent) {
		uint n = centerButtons.length();
		centerButtons.resize(n+1);

		GuiButton@ bt = GuiButton(recti(0, 0, 208, 36), null, parent);
		bt.setSprites(sprite, ind1, ind2, ind3);
		bt.setID(id);
		@centerButtons[n] = bt;
		hasButtons = true;
	}

	//Adds the clause to the list, increments index, and increases yOffset by the height of the added clause
	void applyAddClause(AddClause@ clause, int &inout index, int &inout yOffset) {
		if(index >= int(addClauseList.length()))
			addClauseList.resize(index + 1);
		@addClauseList[index] = clause;
		yOffset += clause.getHeight();
		index += 1;

		if (clause.isLeft()) {
			uint n = leftAddClause.length();
			leftAddClause.resize(n+1);
			@leftAddClause[n] = clause;
		}
		else {
			uint n = rightAddClause.length();
			rightAddClause.resize(n+1);
			@rightAddClause[n] = clause;
		}
	}

	ClauseEditBox@ currentBox;
	void openClauseEditBox(Clause@ clause) {
		closeClauseEditBox();
		@currentBox = ClauseEditBox(clause, this);
	}

	void closeClauseEditBox(bool save) {
		if(@currentBox != null) {
			currentBox.close(save);
			@currentBox = null;
		}
	}

	void closeClauseEditBox() {
		if(@currentBox != null) {
			currentBox.close(true);
			@currentBox = null;
		}
	}

	void syncPosition(dim2di size) {
		// Close button
		close.setPosition(pos2di(size.width-30, 0));
		close.setSize(dim2di(30, 12));

		int mainArea = (size.height - (hasButtons ? 43 : 0) - 20 - 14) / 2;

		// Empire Images
		topEmpImg.setPosition(pos2di(size.width - 222, 20));
		topEmpImg.setSize(dim2di(215, mainArea + 1));
		botEmpImg.setPosition(pos2di(7, mainArea + 27));
		botEmpImg.setSize(dim2di(215, mainArea + 1));

		// Clause add lists
		int offset = 0;
		if (editable) {
			leftAddClauseList.setPosition(pos2di(7, 20));
			leftAddClauseList.setSize(dim2di(215, mainArea));
			leftAddClauseList.setVisible(true);
			leftAddClauseList.fitChildren();
			leftAddClauseList.fitChildren();

			rightAddClauseList.setPosition(pos2di(size.width - 222, mainArea + 27));
			rightAddClauseList.setSize(dim2di(215, mainArea));
			rightAddClauseList.setVisible(true);
			rightAddClauseList.fitChildren();
			rightAddClauseList.fitChildren();
			offset = 222;
		}
		else {
			leftAddClauseList.setVisible(false);
			rightAddClauseList.setVisible(false);
		}

		// Empire Names
		topEmpName.setPosition(pos2di(7 + offset, 22));
		topEmpName.setSize(dim2di(size.width - 222 - offset, 19));

		botEmpName.setPosition(pos2di(229, mainArea + 29));
		botEmpName.setSize(dim2di(size.width - 222 - offset, 19));

		// Clause lists
		upperClauseList.setPosition(pos2di(7 + offset, 46));
		upperClauseList.setSize(dim2di(size.width - 234 - offset, mainArea - 25));

		lowerClauseList.setPosition(pos2di(7 + 222, 53 + mainArea));
		lowerClauseList.setSize(dim2di(size.width - 234 - offset, mainArea - 25));
		updateButtonPositions(size);
	}

	void setEmpires(const Empire@ TopEmp, const Empire@ BotEmp) {
		@topEmp = TopEmp;
		@botEmp = BotEmp;

		topEmpImg.setEmpire(topEmp);
		botEmpImg.setEmpire(botEmp);

		topEmpName.setText(combine("#font:title##a:center#", combine(localize("#TRW_The"), combine("#c:", topEmp.color.format(), "#"), topEmp.getName()), "#c#", localize("#TRW_Will"), "#a##font#"));
		botEmpName.setText(combine("#font:title##a:center#", combine(localize("#TRW_The"), combine("#c:", botEmp.color.format(), "#"), botEmp.getName()), "#c#", localize("#TRW_Will"), "#a##font#"));
	}

	const Treaty@ getTreaty() {
		return treaty;
	}

	void viewTreaty(const Treaty@ trty) {
		@treaty = trty;
		@empireTo = null;
		editable = false;

		@factory = null;

		for(uint i = 0; i < treaty.clauseCount; ++i) {
			const Clause@ clause = treaty.getClause(i);
			if(clause.isReversed())
				lowerClauseList.showClause(clause);
			else
				upperClauseList.showClause(clause);
		}

		setEmpires(trty.getFromEmpire(), trty.getToEmpire());
	}

	void duplicateTreaty(const Treaty@ trty) {
		@treaty = null;
		editable = true;

		@factory = TreatyFactory();

		const Empire@ from = trty.getFromEmpire();
		const Empire@ to = trty.getToEmpire();
		bool reverse = false;

		if (to is getActiveEmpire()) {
			reverse = true;
			@empireTo = from;
			setEmpires(getActiveEmpire(), from);
			factory.prepare(getActiveEmpire(), from);
		}
		else {
			@empireTo = to;
			setEmpires(getActiveEmpire(), to);
			factory.prepare(getActiveEmpire(), to);
		}

		for(uint i = 0; i < trty.clauseCount; ++i) {
			const Clause@ clause = trty.getClause(i);
			Clause@ newClause;
			if(reverse) {
				if(clause.isReversed())
					@newClause = upperClauseList.addClause(clause.id, !reverse, false);
				else
					@newClause = lowerClauseList.addClause(clause.id, reverse, false);
			}
			else {
				if(clause.isReversed())
					@newClause = lowerClauseList.addClause(clause.id, !reverse, false);
				else
					@newClause = upperClauseList.addClause(clause.id, reverse, false);
			}
			
			uint optionCount = clause.optionCount;
			for(uint o = 0; o < optionCount; ++o) {
				ClauseOption@ newOption = newClause.getOption(o);
				newOption = clause.getOption(o).toString();
			}
			
		}
		lowerClauseList.updateAllEntries();
		upperClauseList.updateAllEntries();
		checkAddClauses();
	}

	void setEmpireTo(const Empire@ other) {
		@empireTo = other;
		@treaty = null;
		editable = true;

		@factory = TreatyFactory();
		factory.prepare(getActiveEmpire(), other);

		setEmpires(getActiveEmpire(), other);
		checkAddClauses();
	}

	void draw(GuiElement@ ele) {
		ele.toGuiScripted().setAbsoluteClip();
		const recti absPos = ele.getAbsolutePosition();
		pos2di topLeft = absPos.UpperLeftCorner;
		pos2di botRight = absPos.LowerRightCorner;
		dim2di size = absPos.getSize();

		drawWindowFrame(absPos);
		drawResizeHandle(recti(botRight - pos2di(19, 19), botRight));

		int mainArea = (size.height - (hasButtons ? 43 : 0) - 20 - 14) / 2;
		int offset = editable ? 222 : 0;

		// Main area separator
		drawHSep(recti(topLeft + pos2di(6, mainArea + 20), dim2di(size.width - 12, 7)));

		// Button bar
		if (hasButtons) {
			drawHSep(recti(pos2di(topLeft.x + 6, botRight.y - 51), dim2di(size.width - 12, 7)));
			drawDarkArea(recti(pos2di(topLeft.x + 7, botRight.y - 44), botRight - pos2di(7, 7)));
		}

		// Top area
		// * Flag area
		drawDarkArea(recti(recti(pos2di(botRight.x - 222, topLeft.y + 20), dim2di(215, mainArea + 1))));
		drawVSep(recti(pos2di(botRight.x - 228, topLeft.y + 19), dim2di(7, mainArea + 3)));

		// * Add area
		if (editable) {
			drawDarkArea(recti(recti(topLeft + pos2di(7, 20), dim2di(215, mainArea + 1))));
			drawVSep(recti(topLeft + pos2di(221, 19), dim2di(7, mainArea + 3)));
		}

		// * Center area
		drawHSep(recti(topLeft + pos2di(offset + 6, 39), dim2di(size.width - 232 - offset, 7)));
		drawDarkArea(recti(topLeft + pos2di(offset + 6, 20), dim2di(size.width - 233 - offset, 20)));
		drawLightArea(recti(topLeft + pos2di(offset + 6, 46), dim2di(size.width - 233 - offset, mainArea - 25)));

		// Bottom area
		// * Flag Area
		drawDarkArea(recti(recti(topLeft + pos2di(7, mainArea + 27), dim2di(215, mainArea + 1))));
		drawVSep(recti(topLeft + pos2di(221, mainArea + 26), dim2di(7, mainArea + 3)));

		// * Add area
		if (editable) {
			drawDarkArea(recti(recti(pos2di(botRight.x - 222, topLeft.y + mainArea + 27), dim2di(215, mainArea + 1))));
			drawVSep(recti(pos2di(botRight.x - 228, topLeft.y + mainArea + 26), dim2di(7, mainArea + 3)));
		}

		// * Center area
		drawHSep(recti(topLeft + pos2di(222 + 6, 46 + mainArea), dim2di(size.width - 232 - offset, 7)));
		drawDarkArea(recti(topLeft + pos2di(222 + 6, 27 + mainArea), dim2di(size.width - 233 - offset, 20)));
		drawLightArea(recti(topLeft + pos2di(222 + 6, 53 + mainArea), dim2di(size.width - 233 - offset, mainArea - 25)));

		clearDrawClip();
	}

	void update(float time) {
		if (updateEntryTime <= 0.1f) {
			lowerClauseList.updateAllEntries();
			upperClauseList.updateAllEntries();
			updateEntryTime = updateEntryInterval;
		}
		else
			updateEntryTime -= time;
	}

	EventReturn onMouseEvent(GuiElement@ ele, const MouseEvent& evt) {
		int w = 0, h = 0;
		if (editable) {
			w = defaultEditSize.width;
			h = defaultEditSize.height;
		}
		else {
			w = defaultViewSize.width;
			h = defaultViewSize.height;
		}

		DragResizeEvent re = handleDragResize(ele, evt, drag, w, h);
		if (re != RE_None) {
			if (re == RE_Resized) {
				int height = (ele.getSize().height / 4) * 4;
				ele.setSize(dim2di(ele.getSize().width, height));

				syncPosition(ele.getSize());
			}
			return ER_Absorb;
		}
		return ER_Pass;
	}

	bool hasTimeOutClause() {
		if (upperClauseList.hasClause("timeout"))
			return true;
		if (lowerClauseList.hasClause("timeout"))
			return true;
		return false;
	}

	bool hasWarClause() {
		if (upperClauseList.hasClause("war"))
			return true;
		if (lowerClauseList.hasClause("war"))
			return true;
		return false;
	}

	bool hasOnlyOnceClauses() {
		if (!upperClauseList.haveAllTag("once"))
			return false;
		if (!lowerClauseList.haveAllTag("once"))
			return false;
		return true;
	}

	bool isOffensive() {
		if (upperClauseList.isOffensive())
			return true;
		if (lowerClauseList.isOffensive())
			return true;
		return false;
	}

	EventReturn onGUIEvent(GuiElement@ ele, const GUIEvent& evt) {
		if (evt.EventType == GEVT_Focus_Gained && evt.Caller.isAncestor(ele)) {
			ele.bringToFront();
			bindEscapeEvent(ele);
		}

		int callerID = evt.Caller.getID();
		if (callerID == clauseEntryElementID) {
			if(!upperClauseList.OnEvent(evt))
				lowerClauseList.OnEvent(evt);
			return ER_Pass;
		}
		if (callerID == addClauseElementID) {
			uint len = addClauseList.length();
			for(uint i = 0; i < len; ++i)
				if(addClauseList[i].OnEvent(evt))
					return ER_Absorb;
			return ER_Pass;
		}

		switch (evt.EventType) {
			case GEVT_Closed:
				closeTradeWindow(this);
				return ER_Absorb;
			case GEVT_Clicked:
				if (evt.Caller is close) {
					closeTradeWindow(this);
					return ER_Absorb;
				}
				else if (callerID == sendButtonID) {
					if (hasTimeOutClause() || hasWarClause() || hasOnlyOnceClauses()) {
						factory.propose();
						closeTradeWindow(this);
					}
					else {
						addConfirmDialog(localize("#TRW_ConfirmTimeless"), localize("#yes"), localize("#no"), ProposeTreatyCallback(this));
					}
					return ER_Absorb;
				}
				else if (callerID == rejectButtonID) {
					const Empire@ from = getReadTreaty().getFromEmpire();
					
					TreatyList treaties;
					treaties.prepare(getActiveEmpire());
					treaties.setAcceptance(from, false);
					treaties.prepare(null);

					closeTradeWindow(this);
					return ER_Absorb;
				}
				else if (callerID == acceptButtonID) {
					const Empire@ from = getReadTreaty().getFromEmpire();
					
					TreatyList treaties;
					treaties.prepare(getActiveEmpire());
					treaties.setAcceptance(from, true);
					treaties.prepare(null);

					closeTradeWindow(this);
					return ER_Absorb;
				}
				else if (callerID == retractButtonID) {
					const Empire@ to = getReadTreaty().getToEmpire();
					
					TreatyList treaties;
					treaties.prepare(getActiveEmpire());
					treaties.retract(to);
					treaties.prepare(null);

					closeTradeWindow(this);
					return ER_Absorb;
				}
				else if (callerID == alterButtonID) {
					const Treaty@ replace = getReadTreaty();
					const Empire@ toEmp = replace.getToEmpire();
					bool byUs = true;
					if(toEmp is getActiveEmpire()) {
						@toEmp = replace.getFromEmpire();
						byUs = false;
					}

					// Create the new alter window
					dim2di origSize = ele.getSize();

					dim2di size;
					size.width = max(origSize.width, defaultEditSize.width);
					size.height = max(origSize.height, defaultEditSize.height);

					pos2di pos = ele.getPosition();
					pos.x -= (size.width - origSize.width) / 2;
					pos.y -= (size.height - origSize.height) / 2;

					TradeWindowHandle@ handle = createTradeWindow(recti(pos, size));
					handle.alterTreaty(replace);

					// Remove the old treaty
					TreatyList treaties;
					treaties.prepare(getActiveEmpire());
					if (byUs)
						treaties.retract(toEmp);
					else
						treaties.setAcceptance(toEmp, false);
					
					treaties.prepare(null);

					closeTradeWindow(this);
					return ER_Absorb;
				}
			break;
		}

		return ER_Pass;
	}

	EventReturn onKeyEvent(GuiElement@ ele, const KeyEvent& evt) {
		return ER_Pass;
	}

	/* }}} */
};
/* }}} */
/* {{{ Clause add button */
interface AddClause {
	int getHeight();
	bool canAdd();
	bool isLeft();
	void setPosition(pos2di pos);
	void setVisible(bool vis);
	void remove();
	bool OnEvent(const GUIEvent@ evt);
};

class ClauseSeparator : AddClause {
	TradeWindow@ win;
	GuiImage@ bar;
	bool left;
	
	ClauseSeparator(const string@ text, int yOffset, bool left, TradeWindow@ window) {
		this.left = left;
		@win = window;
		@bar = GuiImage( pos2di(0, yOffset), "clause_category", left ? win.leftAddClauseList : win.rightAddClauseList );
		
		GuiStaticText@ txt = GuiStaticText( recti( pos2di(1,0), dim2di(198, 16) ), text, false, false, false, bar);
		txt.orphan(true);
	}

	bool isLeft() { return left; }
	void setVisible(bool vis) { bar.setVisible(vis); }
	void setPosition(pos2di pos) { bar.setPosition(pos); }
	bool canAdd() { return true; }
	int getHeight() { return 16; }
	void remove() { bar.remove(); }
	bool OnEvent(const GUIEvent@ evt) { return false; }
};

const string@ strPeaceTreaty = "peace", strSingle = "single",
	  strSingleSide = "single_side", strWar = "war";
class ClauseAddButton : AddClause {
	TradeWindow@ win;
	GuiImage@ bar;
	GuiButton@ button;
	GuiStaticText@ title;
	GuiStaticText@ desc;
	
	const ClauseDesc@ descriptor;
	
	const string@ id;
	bool leftEmpire;
	
	ClauseAddButton(const ClauseDesc@ desc, int yOffset, bool left, TradeWindow@ window) {
		@descriptor = @desc;
		@win = window;
		leftEmpire = left;
		
		@bar = GuiImage( pos2di(0, yOffset), "trade_clause_select", left ? win.leftAddClauseList : win.rightAddClauseList );
		bar.setID(addClauseElementID);
		
		@id = desc.id;
		
		@button = GuiButton( recti( pos2di(1, 18), dim2di( 48, 48) ), null, bar );
		const string@ ico = desc.icon;
		button.setImage( ico );
		button.setAppearance(BA_ScaleImage, BA_Background);
		button.setID(addClauseElementID);
		
		@title = GuiStaticText( recti( pos2di(3,0), dim2di(148, 15) ), desc.name, false, false, false, bar);
		title.setID(addClauseElementID);
		
		@this.desc = GuiStaticText( recti( pos2di(53, 16), dim2di(145, 50)), desc.summary, true, false, false, bar);
		this.desc.setTextAlignment(EA_Center, EA_Center);
		this.desc.setID(addClauseElementID);
		this.desc.orphan(true);
	}

	bool isLeft() {
		return leftEmpire;
	}

	void setVisible(bool vis) {
		bar.setVisible(vis);
	}

	void setPosition(pos2di pos) {
		bar.setPosition(pos);
	}

	bool canAdd() {
		Treaty@ treaty = win.getEditTreaty();
		if (treaty is null)
			return false;
		if (treaty.clauseCount > 0 && treaty.getClause(0).isOffensive() != descriptor.offensive)
			return false;

		Empire@ us = getActiveEmpire();
		const Empire@ other = win.topEmp is us ? win.botEmp : win.topEmp;

		if (descriptor.offensive && us.hasTreatyTag(other, strPeaceTreaty))
			return false;
		if (descriptor.hasTag(strWar) && us.isEnemy(other))
			return false;
		if (descriptor.hasTag(strSingle)) {
			uint cnt = treaty.clauseCount;
			for (uint i = 0; i < cnt; ++i) {
				Clause@ cl = treaty.getClause(i);
				if (getClauseDesc(cl.get_id()) is descriptor)
					return false;
			}
		}
		else if (descriptor.hasTag(strSingleSide)) {
			uint cnt = treaty.clauseCount;
			for (uint i = 0; i < cnt; ++i) {
				Clause@ cl = treaty.getClause(i);
				if (leftEmpire == !cl.isReversed() && getClauseDesc(cl.get_id()) is descriptor)
					return false;
			}
		}

		return true;
	}
	
	bool OnEvent(const GUIEvent@ evt) {
		if((evt.EventType == GEVT_Clicked && evt.Caller is button) || (evt.EventType == GEVT_Focus_Gained && evt.Caller !is button && evt.Caller.isAncestor(bar))) {
			Treaty@ treaty = win.getEditTreaty();
			if(@treaty != null) {
				if(treaty.clauseCount == 0 || treaty.getClause(0).isOffensive() == descriptor.offensive) {
					if(leftEmpire)
						win.upperClauseList.addClause(id, false);
					else
						win.lowerClauseList.addClause(id, true);
					win.checkAddClauses();
				}
				else {
					if (descriptor.offensive)
						addMessageDialog(localize("#TRW_OffensiveError"), null);
					else
						addMessageDialog(localize("#TRW_NonOffensiveError"), null);
				}
			}
			return true;
		}
		return false;
	}

	int getHeight() { return 67; }
	void remove() { bar.remove(); }
};
/* }}} */
/* {{{ Clause List */
class ClauseList {
	TradeWindow@ win;
	ClauseEntry@[] entries;
	GuiPanel@ region;
	
	ClauseList(const recti &in area, TradeWindow@ window, GuiElement@ parent) {
		@win = window;
		@region = GuiPanel(area, false, SBM_Auto, SBM_Invisible, parent);
		region.fitChildren();
	}

	Clause@ addClause(const string@ id, bool isReversed) {
		return addClause(id, isReversed, true);
	}
	
	Clause@ addClause(const string@ id, bool isReversed, bool interactive) {
		Clause@ clause = win.getEditTreaty().addClause(id, isReversed);
		if(clause is null)
			return null;
		
		uint len = entries.length();
		entries.resize(len + 1);
		@entries[len] = ClauseEntry(clause, len, region, win);

		if (interactive && entries[len].clause.optionCount > 0)
			win.openClauseEditBox(entries[len].clause);
		
		region.fitChildren();
		return clause;
	}

	bool hasClause(string@ id) {
		uint clauseCnt = entries.length();
		for (uint i = 0; i < clauseCnt; ++i) {
			if (entries[i].clause.id == id)
				return true;
		}
		return false;
	}

	bool haveAllTag(string@ tag) {
		uint clauseCnt = entries.length();
		for (uint i = 0; i < clauseCnt; ++i) {
			if (!entries[i].hasTag(tag))
				return false;
		}
		return true;
	}

	bool isOffensive() {
		uint clauseCnt = entries.length();
		for (uint i = 0; i < clauseCnt; ++i) {
			if (entries[i].clause.isOffensive())
				return true;
		}
		return false;
	}
	
	void showClause(const Clause@ clause) {
		if(clause is null)
			return;
		
		uint len = entries.length();
		entries.resize(len + 1);
		@entries[len] = ClauseEntry(len, region, clause, win);
		
		region.fitChildren();
	}

	bool removeClauseEntry(ClauseEntry@ entry) {
		uint count = entries.length();
		bool removed = false;
		for(uint i = 0; i < count; ++i) {
			if(removed) {
				entries[i].updatePosition(i);
			}
			else if(entries[i] is entry) {
				entry.remove();
				entries.erase(i);
				--count; --i;
				removed = true;
			}
		}
		return removed;
	}

	void setPosition(pos2di pos) {
		region.setPosition(pos);
	}
	
	void setSize(dim2di size) {
		region.setSize(size);
		region.fitChildren();
		region.fitChildren();
	}

	void updateAllEntries() {
		uint count = entries.length();
		for(uint i = 0; i < count; ++i)
			entries[i].updateOptionText();
	}
	
	bool updateClauseEntry(Clause@ clause) {
		uint count = entries.length();
		for(uint i = 0; i < count; ++i) {
			if(entries[i].clause is clause) {
				entries[i].updateOptionText();
				return true;
			}
		}
		return false;
	}
	
	bool OnEvent(const GUIEvent@ evt) {
		uint count = entries.length();
		for(uint i = 0; i < count; ++i) {
			if(entries[i].OnEvent(evt))
				return true;
		}
		return false;
	}
	
	void clear() {
		uint cnt = entries.length();
		for(uint i = 0; i < cnt; ++i)
			entries[i].remove();
		entries.resize(0);
	}
};
/* }}} */
/* {{{ Clause Entry */
int clauseSpacing = 48;
class ClauseEntry {
	TradeWindow@ win;

	GuiImage@ bg;
	GuiButton@ delete;
	GuiButton@ examine;
	GuiStaticText@ optionText;
	Clause@ clause;
	const Clause@ reviewClause;
	
	ClauseEntry(Clause@ represent, uint row, GuiElement@ parent, TradeWindow@ window) {
		@win = window;
		@clause = @represent;
		@reviewClause = @represent;
		initialize(row, parent);
	}
	
	ClauseEntry(uint row, GuiElement@ parent, const Clause@ represent, TradeWindow@ window) {
		@win = window;
		@reviewClause = @represent;
		initialize(row, parent);
	}

	bool hasTag(string@ tag) {
		return getClauseDesc(clause.id).hasTag(tag);
	}
	
	void initialize(uint row, GuiElement@ parent) {
		const ClauseDesc@ desc = getClauseDesc(reviewClause.id);
		
		@bg = GuiImage( pos2di(0,row * clauseSpacing), "clause_bg", parent);
		
		GuiImage@ icon = GuiImage( pos2di(4,20), desc.icon, bg);
		icon.setSize( dim2di(24, 24) );
		icon.setScaleImage(true);
		icon.orphan(true);
		
		const string@ name = desc.name;
		
		GuiStaticText@ txt = GuiStaticText( recti( pos2di(3, 0), dim2di(150, 15)), name, false, false, false, bg);
		txt.orphan(true);
		
		@optionText = GuiStaticText( recti( pos2di(35, 23), dim2di(251, 19) ), localize("#CO_None"), true, false, false, bg);
		optionText.orphan(true);
		updateOptionText();
		
		if(win.isTreatyEdittable()) {
			if(clause.optionCount > 0) {
				@examine = GuiButton( recti( pos2di(248, 24), dim2di(16, 16)), null, bg );
				examine.orphan(true);
				examine.setImage("clause_edit");
				examine.setAppearance(0, BA_Background);
				examine.setID(clauseEntryElementID);
			}
			
			@delete = GuiButton( recti( pos2di(266, 24), dim2di(16, 16)), null, bg );
			delete.orphan(true);
			delete.setSprites("treaty_remove", 0, 2, 1);
			delete.setAppearance(0, BA_Background);
			delete.setID(clauseEntryElementID);
		}
	}
	
	void updateOptionText() {
		uint optionCount = reviewClause.optionCount;
		if(optionCount == 0)
			return;
		
		string@ optionValues = "";
		for(uint i = 0; i < optionCount; ++i) {
			const ClauseOption@ option = reviewClause.getOption(i);
			if(i > 0) {
				if(i == 2)
					optionValues += "\n";
				else
					optionValues += ", ";
			}
			
			const string@ name = option.name;
			if(name is null)
				@name = "Unknown";
			else
				@name = localize(name);
			
			float val = option.toFloat();
			if (val >= 10000)
				optionValues += name + ": " + standardize(val);
			else if (val >= 10)
				optionValues += name + ": " + f_to_s(val, 0);
			else if (val > 0)
				optionValues += name + ": " + ftos_nice(val, 2);
			else {
				if (option.name == "Resource" || option.name == "#CO_Resource")
					optionValues += name + ": " + localize_resource(option.toString());
				else
					optionValues += name + ": " + option.toString();
			}
		}
		
		optionText.setText(optionValues);
	}

	bool OnEvent(const GUIEvent@ evt) {
		if(evt.EventType == GEVT_Clicked) {
			if(@delete != null && evt.Caller is delete) {
				win.getEditTreaty().removeClause(clause);
				if(!win.upperClauseList.removeClauseEntry(this))
					win.lowerClauseList.removeClauseEntry(this);
				win.checkAddClauses();
				return true;
			}
			else if(@examine != null && evt.Caller is examine) {
				win.openClauseEditBox(clause);
				return true;
			}
		}
		return false;
	}
	
	void updatePosition(uint row) {
		bg.setPosition( pos2di(0, row * clauseSpacing) );
	}

	void remove() {
		bg.remove();
	}
};

/* }}} */
/* {{{ Clause Edit Box */
interface ClauseOptionEdit {
	string@ get_value();
	void setID(int ID);
	void focus();
};

class COE_Text : ClauseOptionEdit {
	GuiEditBox@ edit;
	
	string@ get_value() {
		return edit.getText();
	}

	void focus() {
		setGuiFocus(edit);
		edit.setMarkPos(0, edit.getText().length());
	}

	void setID(int id) {
		edit.setID(id);
	}

	COE_Text(const string@ name, const string@ value, uint index, GuiElement@ ele) {
		GuiStaticText@ txt = GuiStaticText( recti( pos2di(10,30) + pos2di(0,index * 18), dim2di( 148, 16)), name, false, false, false, ele);
		txt.orphan(true);
		
		@edit = GuiEditBox( recti( pos2di( 122, 30) + pos2di(0, index * 18), dim2di( 148, 16)), value, true, ele);
		edit.orphan(true);
	}
};

string@ localize_resource(const string& res) {
	if (res == "Metals")
		return localize("#metals");
	if (res == "Electronics")
		return localize("#electronics");
	if (res == "AdvParts")
		return localize("#advparts");
	if (res == "Guds")
		return localize("#goods");
	if (res == "Luxs")
		return localize("#luxuries");
	if (res == "Food")
		return localize("#food");
	if (res == "Fuel")
		return localize("#fuel");
	if (res == "Ammo")
		return localize("#ammo");		
	return "";
}

string@[] resource_names;
string@[] resource_internal_names;
class COE_Resource : ClauseOptionEdit {
	GuiComboBox@ list;

	COE_Resource(const string@ name, const string@ value, uint index, GuiElement@ ele) {
		const uint nameCount = 8;
		if(resource_names.length() == 0) {
			resource_names.resize(nameCount);
			@resource_names[0] = localize("#metals");
			@resource_names[1] = localize("#electronics");
			@resource_names[2] = localize("#advancedparts");
			@resource_names[3] = localize("#goods");
			@resource_names[4] = localize("#luxuries");
			@resource_names[5] = localize("#food");
			@resource_names[6] = localize("#fuel");
			@resource_names[7] = localize("#ammo");
			
			resource_internal_names.resize(nameCount);
			@resource_internal_names[0] = "Metals";
			@resource_internal_names[1] = "Electronics";
			@resource_internal_names[2] = "AdvParts";
			@resource_internal_names[3] = "Guds";
			@resource_internal_names[4] = "Luxs";
			@resource_internal_names[5] = "Food";
			@resource_internal_names[6] = "Fuel";
			@resource_internal_names[7] = "Ammo";			
		}
		
		uint selected = 0;
		for(uint i = 0; i < nameCount; ++i) {
			if(resource_internal_names[i] == value) {
				@value = @resource_names[i];
				selected = i;
				break;
			}
		}
		
		GuiStaticText@ txt = GuiStaticText( recti( pos2di(10,30) + pos2di(0,index * 18), dim2di( 148, 16)), name, false, false, false, ele);
		txt.orphan(true);
		
		@list = GuiComboBox( recti( pos2di( 122, 30) + pos2di(0, index * 18), dim2di( 148, 16)), ele);
		list.orphan(true);
		for(uint i = 0; i < nameCount; ++i)
			list.addItem(resource_names[i]);
		list.setSelected(selected);
	}
	
	string@ get_value() {
		return resource_internal_names[list.getSelected()];
	}

	void focus() {
	}
	
	void setID(int id) {
		list.setID(id);
	}
};

class ClauseEditBox : GuiCallback {
	TradeWindow@ win;
	Clause@ clause;
	GuiElement@ bg;
	GuiButton@ accept;
	ClauseOptionEdit@[] values;
	
	ClauseEditBox(Clause@ _clause, TradeWindow@ window) {
		@win = window;
		@clause = @_clause;
		
		@bg = DialogWindow(recti(pos2di(0,0), dim2di(100, 100)));
		int id = bg.getID();
		bg.bringToFront();
		setGuiFocus(bg);
		
		uint optionCount = clause.optionCount;
		values.resize(optionCount);		
		for(uint i = 0; i < optionCount; ++i) {
			ClauseOption@ option = clause.getOption(i);
			const string@ name = option.name;
			if(name == "Resource" || name == "#CO_Resource")
				@values[i] = COE_Resource(localize(name), option.toString(), i, bg);
			else
				@values[i] = COE_Text(localize(name), option.toString(), i, bg);
			if (i == 0)
				values[i].focus();
			values[i].setID(id);
		}

		int height = 70 + 18 * optionCount;
		bg.setSize(dim2di(412, height));
		bg.setPosition(makeScreenCenteredRect(dim2di(412, height)).UpperLeftCorner);
		
		@accept = Button(recti(pos2di(288,height - 30), dim2di(113,19)), localize("#accept"), bg);
		accept.setID(id);
		bindGuiCallback(bg, this);
		accept.orphan(true);
	}

	bool OnEvent(const GUIEvent& evt) {
		if (evt.EventType == GEVT_Clicked || evt.EventType == GEVT_EditBox_Enter_Pressed) {
			win.closeClauseEditBox();
			return true;
		}
		return false;
	}
	
	void close(bool saveValues) {
		if(saveValues) {
			for(uint i = 0; i < values.length(); ++i) {
				ClauseOption@ option = clause.getOption(i);
				option = values[i].value;
			}
			if(!win.upperClauseList.updateClauseEntry(clause))
				win.lowerClauseList.updateClauseEntry(clause);
		}
		clearGuiCallback(bg);
		bg.remove();
	}
};
/* }}} */
/* {{{ Window handling */
TradeWindowHandle@[] wins;

dim2di defaultViewSize;
dim2di defaultEditSize;

TradeWindowHandle@ createTradeWindow(recti pos) {
	uint n = wins.length();
	wins.resize(n+1);
	@wins[n] = TradeWindowHandle(pos);
	wins[n].bringToFront();
	setGuiFocus(wins[n].ele);
	return wins[n];
}

void createTradeWindow(const Treaty@ treaty) {
	recti pos = getTradeWindowPosition(defaultViewSize);
	TradeWindowHandle@ handle = createTradeWindow(pos);
	handle.setTreaty(treaty);
}

void createTradeWindow(const Empire@ emp) {
	recti pos = getTradeWindowPosition(defaultEditSize);
	TradeWindowHandle@ handle = createTradeWindow(pos);
	handle.setEmpireTo(emp);
}

recti getTradeWindowPosition(dim2di size) {
	return makeScreenCenteredRect(size);
}

void showTradeWindow(const Treaty@ treaty) {
	// Try to find a window with this pltem
	for (uint i = 0; i < wins.length(); ++i) {
		if (wins[i].getTreaty() is treaty) {
			wins[i].setVisible(true);
			wins[i].bringToFront();
			setGuiFocus(wins[i].ele);
			return;
		}
	}

	// If none found, create a new window
	createTradeWindow(treaty);
}

void showTradeWindow(const Empire@ emp) {
	// Create a new window
	createTradeWindow(emp);
}

void closeTradeWindow(TradeWindow@ win) {
	int index = findTradeWindow(win);
	if (index < 0) return;

	wins[index].remove();
	wins.erase(index);
	setGuiFocus(null);
}

void toggleTradeWindow() {
	// Toggle all windows to a particular state
	bool anyVisible = false;
	for (uint i = 0; i < wins.length(); ++i)
		if (wins[i].isVisible())
			anyVisible = true;
	toggleTradeWindow(!anyVisible);
}

void toggleTradeWindow(bool show) {
	for (uint i = 0; i < wins.length(); ++i) {
		wins[i].setVisible(show);
		if (show)
			wins[i].bringToFront();
	}
}

bool ToggleTradeWin(const GUIEvent@ evt) {
	if (evt.EventType == GEVT_Clicked) {
		toggleTradeWindow();
		return true;
	}
	return false;
}

bool ToggleTradeWin_key(uint8 flags) {
	if (flags & KF_Pressed != 0) {
		toggleTradeWindow();
		return true;
	}
	return false;
}

int findTradeWindow(TradeWindow@ win) {
	for (uint i = 0; i < wins.length(); ++i)
		if (wins[i].script is win)
			return i;
	return -1;
}

int addClauseElementID, clauseEntryElementID;
void init() {
	// IDs to tell where events come from
	addClauseElementID = reserveGuiID();
	clauseEntryElementID = reserveGuiID();

	// Initialize some constants
	defaultEditSize = dim2di(762, 512);
	defaultViewSize = dim2di(638, 512);

	initSkin();
}

void tick(float time) {
	// Update all windows
	for (uint i = 0; i < wins.length(); ++i) {
		if (wins[i].isVisible()) {
			wins[i].update(time);
		}
	}
}
/* }}} */

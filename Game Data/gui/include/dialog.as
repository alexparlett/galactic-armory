// === dialog.as ===
// Provides an easy way for scripts to display archetypical dialogs
//
// -- Available Dialogs: --
// addMessageDialog(string@ title, string@ msg, DialogCallback@ callback);
//    Creates a dialog with an extText in it.
//
// addOptionDialog(string@ title, string@ msg, OptionDialogCallback@ cb);
//    Creates a dialog that generic option elements can be added to.
//
// addEntryDialog(string@ title, string@ msg, string@ value, string@ button, EntryDialogCallback@ cb);
//    Creates a text entry dialog.
//
// addSingleImportDialog(string@ title, string@ msg, string@ button, string@ folder, SingleImportCallback@ cb);
//    Creates a dialog to import a single xml file in folder.
//
// addMultiImportDialog(string@ title, string@ msg, string@ button, string@ folder, MultiImportCallback@ cb);
//    Creates a dialog to select multiple xml files from folder for import.

import void buildOnBest(System@ system, const HullLayout@ layout, int buildCount) from "build_on_best";

interface Dialog {
	GuiElement@ getRoot();
	void setID(int id);
	int getID();

	bool OnEvent(const GUIEvent@ evt);
	void remove();
};

Dialog@[] dialogs;

// {{{ Dialog general functions
recti windowRect(int width, int height) {
	int screenWidth = getScreenWidth();
	int screenHeight = getScreenHeight();
	int offset = dialogs.length()*16;

	return recti(pos2di((screenWidth - width) / 2 + offset, (screenHeight - height) / 2 + offset), dim2di(width, height));
}

bool delegateDialogEvent(const GUIEvent@ evt) {
	int id = evt.Caller.getID();
	uint dCnt = dialogs.length();
	for (uint i = 0; i < dCnt; ++i) {
		if (dialogs[i].getID() == id)
			return dialogs[i].OnEvent(evt);
	}
	return false;
}

void addDialog(Dialog@ dialog) {
	int id = reserveGuiID();
	dialog.setID(id);

	uint num = dialogs.length();
	dialogs.resize(num+1);

	@dialogs[num] = dialog;
	bindGuiCallback(dialog.getID(), "delegateDialogEvent");
	bindEscapeEvent(dialog.getRoot());
}

void removeDialog(Dialog@ dialog) {
	uint dCnt = dialogs.length();
	for (uint i = 0; i < dCnt; ++i) {
		if (dialog is dialogs[i]) {
			clearGuiCallback(dialog.getID());
			clearEscapeEvent(dialogs[i].getRoot());
			dialogs[i].remove();
			dialogs.erase(i);
			return;
		}
	}
}
// }}}
// {{{ Message Dialog
class MessageDialog : Dialog {
	GuiDraggable@ win;
	GuiPanel@ panel;
	GuiExtText@ text;
	GuiButton@ ok;
	GuiButton@ close;

	MessageDialogCallback@ cb;
	int ID;

	MessageDialog(string@ msg, MessageDialogCallback@ cb) {
		@this.cb = @cb;

		@win = GuiDraggable(getSkinnable("Dialog"), windowRect(400, 250), true, null);
		@ok = GuiButton(getSkinnable("Button"), recti(160, 219, 240, 239), localize("#ok"), win);
		@panel = GuiPanel(recti(12, 22, 392, 222), false, SBM_Auto, SBM_Invisible, win);

		@text = GuiExtText(recti(0, 0, 384, 198), panel);
		text.setText(msg);

		@close = GuiButton(getSkinnable("CloseButton"), recti(pos2di(370, 0), dim2di(30, 12)), null, win);

		// Make the window smaller if we can
		int needHeight = text.getSize().height + 80;
		if (needHeight % 2 == 0)
			needHeight += 1;
		if (win.getSize().height > needHeight) {
			int screenHeight = getScreenHeight();
			win.setSize(dim2di(win.getSize().width, needHeight));
			win.setPosition(pos2di(win.getPosition().x, (screenHeight - needHeight) / 2 ));
			panel.setSize(dim2di(panel.getSize().width, needHeight - 60));
			ok.setPosition(pos2di(ok.getPosition().x, needHeight - 31));
			text.setText(msg);
		}

		panel.fitChildren();
		setGuiFocus(ok);
	}

	bool OnEvent(const GUIEvent@ evt) {
		if (((evt.Caller is ok || evt.Caller is close)
				&& evt.EventType == GEVT_Clicked)
			|| evt.EventType == GEVT_Closed) {
			removeDialog(this);
			if (cb !is null)
				cb(this);
			return true;
		}
		return false;
	}

	void remove() {
		win.remove();
	}

	GuiElement@ getRoot() {
		return win;
	}

	void setID(int id) {
		ID = id;
		win.setID(ID);
		ok.setID(ID);
		close.setID(ID);
	}

	int getID() {
		return ID;
	}
};

funcdef void MessageDialogCallback(MessageDialog@);

MessageDialog@ addMessageDialog(string@ title, string@ msg, MessageDialogCallback@ cb) {
	return addMessageDialog(msg, cb);
}

MessageDialog@ addMessageDialog(string@ msg, MessageDialogCallback@ cb) {
	MessageDialog@ dialog = MessageDialog(msg, cb);
	addDialog(dialog);
	dialog.win.bringToFront();
	return dialog;
}
// }}}
// {{{ Generic option dialog
class OptionDialog : Dialog {
	GuiDraggable@ win;
	GuiExtText@ text;
	GuiButton@ ok;
	GuiButton@ cancel;
	GuiButton@ close;

	GuiElement@[] options;
	GuiElement@[] other;

	OptionDialogCallback@ cb;
	int ID;

	OptionDialog(string@ msg, OptionDialogCallback@ cb) {
		@this.cb = @cb;

		@win = GuiDraggable(getSkinnable("Dialog"), windowRect(450, 250), true, null);
		@cancel = GuiButton(getSkinnable("Button"), recti(140, 226, 220, 246), localize("#cancel"), win);
		@ok = GuiButton(getSkinnable("Button"), recti(230, 226, 310, 246), localize("#ok"), win);
		@text = GuiExtText(recti(12, 22, 392, 67), win);
		text.setText(msg);

		@close = GuiButton(getSkinnable("CloseButton"), recti(pos2di(420, 0), dim2di(30, 12)), null, win);

		setGuiFocus(ok);
	}

	void fitChildren() {
		int needHeight = 60+options.length()*23+30;
		if (needHeight % 2 == 0)
			needHeight += 1;
		if (win.getSize().height > needHeight) {
			int screenHeight = getScreenHeight();
			win.setSize(dim2di(win.getSize().width, needHeight));
			win.setPosition(pos2di(win.getPosition().x, (screenHeight - needHeight) / 2 ));
			ok.setPosition(pos2di(ok.getPosition().x, needHeight - 31));
			cancel.setPosition(pos2di(cancel.getPosition().x, needHeight - 31));
		}
	}

	uint addOption(string@ msg, GuiElement@ ele) {
		uint n = options.length();
		options.resize(n+1);

		uint b = other.length();
		other.resize(b+1);

		ele.setParent(win);
		ele.setPosition(pos2di(205, 50+n*23));
		ele.setID(ID);

		GuiExtText@ text = GuiExtText(recti(pos2di(12, 50+n*23), dim2di(190, 23)), win);
		text.setText(msg);

		@options[n] = ele;
		@other[b] = text;
		return n;
	}

	GuiElement@ getOption(uint n) {
		if (n < options.length())
			return @options[n];
		return null;
	}

	/* {{{ Shortcut option types */
	uint addCheckBoxOption(string@ text, bool def) {
		uint n = options.length();
		options.resize(n+1);

		GuiCheckBox@ ele = GuiCheckBox(def, recti(pos2di(12, 50+n*23), dim2di(300, 20)), text, win);
		ele.setID(ID);

		@options[n] = ele;
		return n;
	}

	bool getCheckBoxOption(uint n) {
		GuiCheckBox@ box = getOption(n);
		if (box !is null)
			return box.isChecked();
		return false;
	}

	uint addComboOption(string@ text) {
		GuiComboBox@ box = GuiComboBox(recti(0, 0, 200, 20), win);
		return addOption(text, box);
	}

	uint addResourceOption(string@ text, string@ def, bool transferOnly, bool cargoOnly) {
		uint n = addComboOption(text);
		GuiComboBox@ box = options[n];
		uint sel = 0, j = 0;
		uint cnt = getResourceCount();
		for (uint i = 0; i < cnt; ++i) {
			const Resource@ res = getResource(i);
			if (transferOnly && !res.canTransfer)
				continue;
			if (cargoOnly && !res.canBeCargo)
				continue;
			string@ name = res.getName();
			if (def !is null && name == def)
				sel = j;
			box.addItem(res.getLocaleName());
			++j;
		}
		box.setSelected(sel);
		return n;
	}

	string@ getResourceOption(uint n) {
		string@ str = getComboOption(n);
		if (str is null)
			return null;
		const Resource@ res = getLocalizedResource(str);
		if (res is null)
			return null;
		return res.getName();
	}

	string@ getComboOption(uint n) {
		GuiComboBox@ box = getOption(n);
		if (box !is null) {
			int sel = box.getSelected();
			if (sel >= 0 && sel < box.getItemCount())
				return box.getItem(sel);
		}
		return null;
	}

	uint addTextOption(string@ text, string@ def) {
		GuiEditBox@ box = GuiEditBox(recti(0, 0, 200, 20), def, true, win);
		box.setText(def);
		return addOption(text, box);
	}

	uint addCaptionedTextOption(string@ msg, string@ caption, string@ def) {
		uint n = options.length();
		uint b = other.length();
		other.resize(b+1);

		GuiExtText@ text = GuiExtText(recti(pos2di(350, 50+n*23), dim2di(40, 23)), win);
		text.setText(caption);
		@other[b] = text;

		n = addTextOption(msg, def);
		options[n].setSize(dim2di(140, 20));
		return n;
	}

	string@ getTextOption(uint n) {
		GuiEditBox@ box = getOption(n);
		if (box !is null)
			return box.getText();
		return null;
	}
	/* }}} */

	bool OnEvent(const GUIEvent@ evt) {
		if (((evt.Caller is ok || evt.Caller is cancel || evt.Caller is close)
					&& evt.EventType == GEVT_Clicked) || (evt.Caller is win &&
						evt.EventType == GEVT_Closed) || evt.EventType ==
				GEVT_EditBox_Enter_Pressed) { removeDialog(this);
			if (cb !is null)
				cb.call(this, evt.Caller is ok || evt.EventType == GEVT_EditBox_Enter_Pressed);
			return true;
		}
		return false;
	}

	GuiElement@ getRoot() {
		return win;
	}

	void remove() {
		win.remove();
	}

	void setID(int id) {
		ID = id;
		win.setID(ID);
		ok.setID(ID);
		cancel.setID(ID);
		close.setID(ID);

		for (uint i = 0; i < options.length(); ++i)
			options[i].setID(ID);
	}

	int getID() {
		return ID;
	}
};

interface OptionDialogCallback {
	void call(OptionDialog@, bool);
};

funcdef void OptionDialogCallbackFunc(OptionDialog@, bool);
class OptionDialogFunc : OptionDialogCallback {
	OptionDialogCallbackFunc@ func;

	OptionDialogFunc(OptionDialogCallbackFunc@ function) {
		@func = function;
	}

	void call(OptionDialog@ dialog, bool choice) {
		func(dialog, choice);
	}
};

OptionDialog@ addOptionDialog(string@ title, string@ msg, OptionDialogCallbackFunc@ cb) {
	return addOptionDialog(msg, OptionDialogFunc(cb));
}

OptionDialog@ addOptionDialog(string@ msg, OptionDialogCallbackFunc@ cb) {
	return addOptionDialog(msg, OptionDialogFunc(cb));
}

OptionDialog@ addOptionDialog(string@ msg, OptionDialogCallback@ cb) {
	OptionDialog@ dialog = OptionDialog(msg, cb);
	addDialog(dialog);
	dialog.win.bringToFront();
	return dialog;
}
// }}}
// {{{ Confirmation dialog
class ConfirmDialog : Dialog {
	GuiDraggable@ win;
	GuiExtText@ text;
	GuiPanel@ panel;
	GuiButton@ confirm;
	GuiButton@ cancel;
	GuiButton@ close;

	ConfirmDialogCallback@ cb;
	int ID;

	ConfirmDialog(string@ msg, string@ confirmText, string@ cancelText, ConfirmDialogCallback@ cb) {
		@this.cb = @cb;

		@win = GuiDraggable(getSkinnable("Dialog"), windowRect(400, 250), true, null);
		@close = GuiButton(getSkinnable("CloseButton"), recti(pos2di(370, 0), dim2di(30, 12)), null, win);
		@panel = GuiPanel(recti(12, 22, 392, 222), false, SBM_Auto, SBM_Invisible, win);

		@cancel = GuiButton(getSkinnable("Button"), recti(205, 226, 285, 246), cancelText, win);
		@confirm = GuiButton(getSkinnable("Button"), recti(115, 226, 195, 246), confirmText, win);

		@text = GuiExtText(recti(0, 0, 384, 198), panel);
		text.setText(msg);

		// Make the window smaller if we can
		int needHeight = text.getSize().height + 60;
		if (needHeight % 2 == 0)
			needHeight += 1;
		if (win.getSize().height > needHeight) {
			int screenHeight = getScreenHeight();
			win.setSize(dim2di(win.getSize().width, needHeight));
			win.setPosition(pos2di(win.getPosition().x, (screenHeight - needHeight) / 2 ));
			panel.setSize(dim2di(panel.getSize().width, needHeight - 60));

			confirm.setPosition(pos2di(confirm.getPosition().x, needHeight - 31));
			cancel.setPosition(pos2di(cancel.getPosition().x, needHeight - 31));
		}

		panel.fitChildren();
		setGuiFocus(confirm);
	}

	bool OnEvent(const GUIEvent@ evt) {
		bool closing = false;
		bool confirmed = true;

		switch (evt.EventType) {
			case GEVT_Clicked:
				if (evt.Caller is confirm) {
					closing = true;
					confirmed = true;
				}
				else if (evt.Caller is cancel || evt.Caller is close) {
					closing = true;
					confirmed = false;
				}
			break;
			case GEVT_Closed:
				closing = true;
				confirmed = false;
			break;
		}

		if (closing) {
			removeDialog(this);
			if (cb !is null)
				cb.call(this, confirmed);
			return true;
		}
		return false;
	}

	GuiElement@ getRoot() {
		return win;
	}

	void remove() {
		win.remove();
	}

	void setID(int id) {
		ID = id;
		win.setID(ID);
		confirm.setID(ID);
		cancel.setID(ID);
		close.setID(ID);
	}

	int getID() {
		return ID;
	}
};

interface ConfirmDialogCallback {
	void call(ConfirmDialog@, bool);
};

funcdef void ConfirmDialogCallbackFunc(ConfirmDialog@, bool);
class ConfirmDialogFunc : ConfirmDialogCallback {
	ConfirmDialogCallbackFunc@ func;

	ConfirmDialogFunc(ConfirmDialogCallbackFunc@ function) {
		@func = function;
	}

	void call(ConfirmDialog@ dialog, bool choice) {
		func(dialog, choice);
	}
};

ConfirmDialog@ addConfirmDialog(string@ msg, string@ confirm, string@ cancel, ConfirmDialogCallbackFunc@ cb) {
	return addConfirmDialog(msg, confirm, cancel, ConfirmDialogFunc(cb));
}

ConfirmDialog@ addConfirmDialog(string@ msg, string@ confirm, string@ cancel, ConfirmDialogCallback@ cb) {
	ConfirmDialog@ dialog = ConfirmDialog(msg, confirm, cancel, cb);
	addDialog(dialog);
	dialog.win.bringToFront();
	return dialog;
}
// }}}
// {{{ Entry dialog
class EntryDialog : Dialog {
	GuiDraggable@ win;
	GuiExtText@ text;
	GuiEditBox@ edit;
	GuiButton@ ok;
	GuiButton@ close;

	EntryDialogCallback@ cb;
	int ID;

	EntryDialog(string@ msg, string@ value, string@ button, EntryDialogCallback@ cb) {
		@this.cb = @cb;

		@win = GuiDraggable(getSkinnable("Dialog"), windowRect(400, 70), true, null);
		@text = GuiExtText(recti(12, 22, 392, 30), win);
		@edit = GuiEditBox(recti(12, 39, 300, 59), value is null ? "" : value, true, win);
		@ok = GuiButton(getSkinnable("Button"), recti(304, 39, 389, 59), button is null ? localize("#ok") : button, win);

		@close = GuiButton(getSkinnable("CloseButton"), recti(pos2di(370, 0), dim2di(30, 12)), null, win);

		text.setText(msg);
		setGuiFocus(edit);

		if (value !is null)
			edit.setMarkPos(0, value.length());
	}

	bool OnEvent(const GUIEvent@ evt) {
		if ((evt.Caller is ok && evt.EventType == GEVT_Clicked) ||
		(evt.Caller is edit && evt.EventType == GEVT_EditBox_Enter_Pressed)) {
			removeDialog(this);
			if (cb !is null)
				cb.call(this, edit.getText());
			return true;
		}
		else if ((evt.Caller is win && evt.EventType == GEVT_Closed) ||
				(evt.Caller is close && evt.EventType == GEVT_Clicked)) {
			removeDialog(this);
			return true;
		}
		return false;
	}

	GuiElement@ getRoot() {
		return win;
	}

	void remove() {
		win.remove();
	}

	void setID(int id) {
		ID = id;
		win.setID(ID);
		ok.setID(ID);
		edit.setID(ID);
		close.setID(ID);
	}

	int getID() {
		return ID;
	}
};

interface EntryDialogCallback {
	void call(EntryDialog@, string@);
};

funcdef void EntryDialogCallbackFunc(EntryDialog@, string@);
class EntryDialogFunc : EntryDialogCallback {
	EntryDialogCallbackFunc@ func;

	EntryDialogFunc(EntryDialogCallbackFunc@ function) {
		@func = function;
	}

	void call(EntryDialog@ dialog, string@ text) {
		func(dialog, text);
	}
};

EntryDialog@ addEntryDialog(string@ title, string@ msg, string@ value, string@ button, EntryDialogCallbackFunc@ cb) {
	return addEntryDialog(msg, value, button, EntryDialogFunc(cb));
}

EntryDialog@ addEntryDialog(string@ msg, string@ value, string@ button, EntryDialogCallbackFunc@ cb) {
	return addEntryDialog(msg, value, button, EntryDialogFunc(cb));
}

EntryDialog@ addEntryDialog(string@ msg, string@ value, string@ button, EntryDialogCallback@ cb) {
	EntryDialog@ dialog = EntryDialog(msg, value, button, cb);
	addDialog(dialog);
	dialog.win.bringToFront();
	return dialog;
}
// }}}
// {{{ Single import dialog
class SingleImportDialog : Dialog {
	GuiDraggable@ win;
	GuiExtText@ text;
	GuiComboBox@ box;
	GuiButton@ ok;
	GuiButton@ del;
	GuiButton@ close;
	string@ folder;

	SingleImportDialogCallback@ cb;
	int ID;

	SingleImportDialog(string@ msg, string@ button, string@ folder, SingleImportDialogCallback@ cb) {
		@this.cb = @cb;
		@this.folder = folder;

		@win = GuiDraggable(getSkinnable("Dialog"), windowRect(450, 55), true, null);
		@text = GuiExtText(recti(14, 24, 90, 44), win);
		@box = GuiComboBox(recti(84, 24, 318, 44), win);

		@del = GuiButton(getSkinnable("Button"), recti(322, 24, 376, 44), localize("#delete"), win);
		@ok = GuiButton(getSkinnable("Button"), recti(381, 24, 438, 44), button is null ? localize("#import") : button, win);

		@close = GuiButton(getSkinnable("CloseButton"), recti(pos2di(420, 0), dim2di(30, 12)), null, win);

		text.setText(msg);
		setGuiFocus(ok);
		refresh();
	}

	void refresh() {
		XMLList@ list = XMLList(folder);
		box.clear();

		for (uint i = 0; i < list.getFileCount(); ++i) {
			string@ filename = list.getFileName(i);
			filename = filename.substr(folder.length()+1, filename.length()-folder.length()-5);
			box.addItem(filename);
		}
	}

	bool OnEvent(const GUIEvent@ evt) {
		if (evt.Caller is ok && evt.EventType == GEVT_Clicked) {
			removeDialog(this);

			uint sel = box.getSelected();
			if (sel >= uint(box.getItemCount()))
				return false;

			if (cb !is null)
				cb.call(this, box.getItem(sel));
		}
		else if (evt.Caller is win && evt.EventType == GEVT_Closed) {
			removeDialog(this);
		}
		else if (evt.Caller is close && evt.EventType == GEVT_Clicked) {
			removeDialog(this);
		}
		else if (evt.Caller is del && evt.EventType == GEVT_Clicked) {
			uint sel = box.getSelected();
			if (sel >= uint(box.getItemCount()))
				return false;

			XMLDelete(folder + "/" + box.getItem(sel));
			refresh();
		}
		return false;
	}

	GuiElement@ getRoot() {
		return win;
	}

	void remove() {
		win.remove();
	}

	void setID(int id) {
		ID = id;
		win.setID(ID);
		ok.setID(ID);
		del.setID(ID);
		box.setID(ID);
		close.setID(ID);
	}

	int getID() {
		return ID;
	}
};

interface SingleImportDialogCallback {
	void call(SingleImportDialog@, string@);
};

funcdef void SingleImportDialogCallbackFunc(SingleImportDialog@, string@);
class SingleImportDialogFunc : SingleImportDialogCallback {
	SingleImportDialogCallbackFunc@ func;

	SingleImportDialogFunc(SingleImportDialogCallbackFunc@ function) {
		@func = function;
	}

	void call(SingleImportDialog@ dialog, string@ text) {
		func(dialog, text);
	}
};

SingleImportDialog@ addSingleImportDialog(string@ title, string@ msg, string@ button, string@ folder, SingleImportDialogCallbackFunc@ cb) {
	return addSingleImportDialog(msg, button, folder, SingleImportDialogFunc(cb));
}

SingleImportDialog@ addSingleImportDialog(string@ msg, string@ button, string@ folder, SingleImportDialogCallbackFunc@ cb) {
	return addSingleImportDialog(msg, button, folder, SingleImportDialogFunc(cb));
}

SingleImportDialog@ addSingleImportDialog(string@ msg, string@ button, string@ folder, SingleImportDialogCallback@ cb) {
	SingleImportDialog@ dialog = SingleImportDialog(msg, button, folder, cb);
	addDialog(dialog);
	dialog.win.bringToFront();
	return dialog;
}
// }}}
// {{{ Multi import dialog
class MultiImportDialog : Dialog {
	GuiDraggable@ win;
	GuiExtText@ text;
	GuiButton@ ok;
	GuiButton@ close;
	GuiButton@ clear;
	GuiButton@ del;
	string@ folder;

	GuiButton@ moveRight;
	GuiButton@ moveLeft;
	GuiButton@ moveAllRight;

	GuiListBox@ store;
	GuiListBox@ chosen;

	MultiImportCallback@ cb;
	int ID;

	MultiImportDialog(string@ title, string@ msg, string@ button, string@ folder, MultiImportCallback@ cb) {
		@this.cb = @cb;
		
		if(!folder.opEquals("Default")) {
			@this.folder = "Layouts/" + folder;
		}
		else {
			@this.folder = "Layouts";
		}	

		@win = GuiDraggable(getSkinnable("Dialog"), windowRect(450, 355), true, null);
		@text = GuiExtText(recti(pos2di(14, 24), dim2di(422, 20)), win);

		@close = GuiButton(getSkinnable("CloseButton"), recti(pos2di(420, 0), dim2di(30, 12)), null, win);

		@store = GuiListBox(recti(pos2di(14, 46), dim2di(190, 265)), true, win);
		@chosen = GuiListBox(recti(pos2di(246, 46), dim2di(190, 265)), true, win);

		@moveRight = GuiButton(getSkinnable("Button"), recti(pos2di(210, 123), dim2di(30, 21)), ">", win);
		@moveLeft = GuiButton(getSkinnable("Button"), recti(pos2di(210, 149), dim2di(30, 21)), "<", win);

		@del = GuiButton(getSkinnable("Button"), recti(pos2di(24, 320), dim2di(80, 20)), localize("#delete"), win);
		@moveAllRight = GuiButton(getSkinnable("Button"), recti(pos2di(114, 320), dim2di(80, 20)), localize("#all")+" >", win);

		@clear = GuiButton(getSkinnable("Button"), recti(pos2di(256, 320), dim2di(80, 20)), "< "+localize("#all"), win);
		@ok = GuiButton(getSkinnable("Button"), recti(pos2di(346, 320), dim2di(80, 20)), button is null ? localize("#import") : button, win);

		text.setText(msg);
		setGuiFocus(ok);
		refresh();
	}

	uint getItemCount() {
		return uint(chosen.getItemCount());
	}

	string@ getItem(uint i) {
		if (i >= uint(chosen.getItemCount()))
			return null;
		return chosen.getItem(i);
	}

	void refresh() {
		XMLList@ list = XMLList(folder);
		store.clear();
		chosen.clear();

		for (uint i = 0; i < list.getFileCount(); ++i) {
			string@ filename = list.getFileName(i);
			filename = filename.substr(folder.length()+1, filename.length()-folder.length()-5);
			store.addItem(filename);
		}
	}

	bool OnEvent(const GUIEvent@ evt) {
		if (evt.Caller is ok && evt.EventType == GEVT_Clicked) {
			removeDialog(this);

			if (cb !is null)
				cb.call(this);
		}
		else if (evt.Caller is win && evt.EventType == GEVT_Closed) {
			removeDialog(this);
		}
		else if (evt.Caller is close && evt.EventType == GEVT_Clicked) {
			removeDialog(this);
		}
		else if (evt.Caller is del && evt.EventType == GEVT_Clicked) {
			uint sel = store.getSelected();
			if (sel >= uint(store.getItemCount()))
				return false;

			XMLDelete(folder + "/" + store.getItem(sel));
			store.removeItem(sel);
			store.setSelected(min(sel, store.getItemCount()-1));
		}
		else if ((evt.Caller is store && evt.EventType == GEVT_Listbox_Selected_Again) ||
				(evt.Caller is moveRight && evt.EventType == GEVT_Clicked)) {

			uint sel = store.getSelected();
			if (sel >= uint(store.getItemCount()))
				return false;

			chosen.addItem(store.getItem(sel));
			store.removeItem(sel);
			store.setSelected(min(sel, store.getItemCount()-1));
		}
		else if ((evt.Caller is chosen && evt.EventType == GEVT_Listbox_Selected_Again) ||
				(evt.Caller is moveLeft && evt.EventType == GEVT_Clicked)) {

			uint sel = chosen.getSelected();
			if (sel >= uint(chosen.getItemCount()))
				return false;

			store.addItem(chosen.getItem(sel));
			chosen.removeItem(sel);
			chosen.setSelected(min(sel, chosen.getItemCount()-1));
		}
		else if (evt.Caller is clear && evt.EventType == GEVT_Clicked) {
			refresh();
		}
		else if (evt.Caller is moveAllRight && evt.EventType == GEVT_Clicked) {
			uint cnt = store.getItemCount();
			for (uint i = 0; i < cnt; ++i) {
				chosen.addItem(store.getItem(i));
			}

			store.clear();
			store.setSelected(-1);
		}
		return false;
	}

	GuiElement@ getRoot() {
		return win;
	}

	void remove() {
		win.remove();
	}

	void setID(int id) {
		ID = id;
		win.setID(ID);
		ok.setID(ID);
		del.setID(ID);
		clear.setID(ID);
		store.setID(ID);
		chosen.setID(ID);
		moveLeft.setID(ID);
		moveRight.setID(ID);
		moveAllRight.setID(ID);
		close.setID(ID);
	}

	int getID() {
		return ID;
	}
};

interface MultiImportCallback {
	void call(MultiImportDialog@);
};

funcdef void MultiImportCallbackFunc(MultiImportDialog@);
class MultiImportFunc : MultiImportCallback {
	MultiImportCallbackFunc@ func;

	MultiImportFunc(MultiImportCallbackFunc@ function) {
		@func = function;
	}

	void call(MultiImportDialog@ dialog) {
		func(dialog);
	}
};

MultiImportDialog@ addMultiImportDialog(string@ title, string@ msg, string@ button, string@ folder, MultiImportCallbackFunc@ cb) {
	return addMultiImportDialog(title, msg, button, folder, MultiImportFunc(cb));
}

MultiImportDialog@ addMultiImportDialog(string@ title, string@ msg, string@ button, string@ folder, MultiImportCallback@ cb) {
	MultiImportDialog@ dialog = MultiImportDialog(title, msg, button, folder, cb);
	addDialog(dialog);
	dialog.win.bringToFront();
	return dialog;
}
// }}}
// {{{ List Selection Dialog
class ListSelectionDialog : Dialog {
	GuiDraggable@ win;
	GuiExtText@ text;

	GuiButton@ ok;
	GuiButton@ close;
	GuiListBox@ chosen;

	ListSelectionCallback@ cb;
	int ID;

	ListSelectionDialog(string@ msg, string@ button, ListSelectionCallback@ cb) {
		@this.cb = @cb;

		@win = GuiDraggable(getSkinnable("Dialog"), windowRect(250, 265), true, null);
		@text = GuiExtText(recti(pos2di(14, 24), dim2di(222, 20)), win);

		@close = GuiButton(getSkinnable("CloseButton"), recti(pos2di(220, 0), dim2di(30, 12)), null, win);

		@chosen = GuiListBox(recti(pos2di(10, 46), dim2di(230, 175)), true, win);
		@ok = GuiButton(getSkinnable("Button"), recti(pos2di(90, 230), dim2di(80, 20)), button is null ? localize("#ok") : button, win);

		text.setText(msg);
		setGuiFocus(ok);
	}

	uint getItemCount() {
		return uint(chosen.getItemCount());
	}

	string@ getItem(uint i) {
		if (i >= uint(chosen.getItemCount()))
			return null;
		return chosen.getItem(i);
	}

	void addItem(string@ item) {
		chosen.addItem(item);
	}

	int getSelected() {
		return chosen.getSelected();
	}

	bool OnEvent(const GUIEvent@ evt) {
		if ((evt.Caller is ok && evt.EventType == GEVT_Clicked) ||
			(evt.Caller is chosen && evt.EventType == GEVT_Listbox_Selected_Again)) {
			removeDialog(this);

			if (cb !is null)
				cb.call(this);
		}
		else if (evt.Caller is win && evt.EventType == GEVT_Closed) {
			removeDialog(this);
		}
		else if (evt.Caller is close && evt.EventType == GEVT_Clicked) {
			removeDialog(this);
		}
		return false;
	}

	GuiElement@ getRoot() {
		return win;
	}

	void remove() {
		win.remove();
	}

	void setID(int id) {
		ID = id;
		win.setID(ID);
		ok.setID(ID);
		chosen.setID(ID);
		close.setID(ID);
	}

	int getID() {
		return ID;
	}
};

interface ListSelectionCallback {
	void call(ListSelectionDialog@);
};

funcdef void ListSelectionCallbackFunc(ListSelectionDialog@);
class ListSelectionFunc : ListSelectionCallback {
	ListSelectionCallbackFunc@ func;

	ListSelectionFunc(ListSelectionCallbackFunc@ function) {
		@func = function;
	}

	void call(ListSelectionDialog@ dialog) {
		func(dialog);
	}
};

ListSelectionDialog@ addListSelectionDialog(string@ msg, string@ button, ListSelectionCallbackFunc@ cb) {
	return addListSelectionDialog(msg, button, ListSelectionFunc(cb));
}

ListSelectionDialog@ addListSelectionDialog(string@ msg, string@ button, ListSelectionCallback@ cb) {
	ListSelectionDialog@ dialog = ListSelectionDialog(msg, button, cb);
	addDialog(dialog);
	dialog.win.bringToFront();
	return dialog;
}
// }}}
// {{{ Multibuild dialogs
Object@ _di_curObj = null;
Planet@ _di_curPl = null;
System@ _di_curSys = null;
const subSystemDef@ _di_buildStruct = null;
const HullLayout@ _di_buildShip = null;
MultibuildCallback@ _di_callback = null;

interface MultibuildCallback {
	void act(const HullLayout@ layout, uint amount, bool batch);
};

void clearMultiBuild() {
	@_di_curObj = null;
	@_di_curPl = null;
	@_di_buildShip = null;
	@_di_buildStruct = null;
	@_di_callback = null;
}

void doMultiBuild(EntryDialog@ dialog, string@ amount) {
	int buildCount = s_to_i(amount);

	if(@_di_curObj != null && @_di_buildShip != null) {
		_di_curObj.makeShip(_di_buildShip, buildCount, true);
	}
	else if(@_di_curSys != null && @_di_buildShip != null) {
		buildOnBest(_di_curSys, _di_buildShip, buildCount);
	}
	else if(@_di_curPl != null && @_di_buildStruct != null) {
		_di_curPl.buildStructure(_di_buildStruct, buildCount);
	}
}

void optMultiBuild(OptionDialog@ dialog, bool success) {
	if (!success)
		return;

	string@ amount = dialog.getTextOption(0);
	bool batch = dialog.getCheckBoxOption(1);
	int buildCount = s_to_i(amount);

	if(_di_buildShip !is null) {
		if(_di_curObj !is null)
			_di_curObj.makeShip(_di_buildShip, buildCount, batch);
		else if (_di_callback !is null)
			_di_callback.act(_di_buildShip, buildCount, batch);
	}
}

void multiBuild(Object@ buildAt, const HullLayout@ ship) {
	clearMultiBuild();
	@_di_curObj = buildAt;
	@_di_buildShip = ship;

	OptionDialog@ dialog = addOptionDialog(localize("#PL_Build")+ship.getName(), optMultiBuild);
	dialog.addTextOption(localize("#PL_Amount"), "1");
	dialog.addCheckBoxOption(localize("#PL_Batch"), false);
	dialog.fitChildren();

	GuiEditBox@ box = dialog.getOption(0);
	setGuiFocus(box);
	box.setMarkPos(0, box.getText().length());
}

void multiBuild(MultibuildCallback@ cb, const HullLayout@ ship, bool showBatch) {
	clearMultiBuild();
	@_di_callback = cb;
	@_di_buildShip = ship;

	OptionDialog@ dialog = addOptionDialog(localize("#PL_Build")+ship.getName(), optMultiBuild);
	dialog.addTextOption(localize("#PL_Amount"), "1");
	if (showBatch)
		dialog.addCheckBoxOption(localize("#PL_Batch"), false);
	dialog.fitChildren();

	GuiEditBox@ box = dialog.getOption(0);
	setGuiFocus(box);
	box.setMarkPos(0, box.getText().length());
}

void multiBuild(System@ buildAt, const HullLayout@ ship) {
	clearMultiBuild();
	@_di_curSys = buildAt;
	@_di_buildShip = ship;

	addEntryDialog(localize("#PL_QUEUE_AMOUNT"), ship.getName()+" "+localize("#PL_QUANTITY")+":",
				    "1", localize("#PL_BUILD"), @doMultiBuild);
}

void multiBuild(Planet@ buildAt, const subSystemDef@ def) {
	clearMultiBuild();
	@_di_curPl = buildAt;
	@_di_buildStruct = def;

	addEntryDialog(localize("#PL_QUEUE_AMOUNT"), def.getName()+" "+localize("#PL_QUANTITY")+":",
				    "1", localize("#PL_BUILD"), @doMultiBuild);
}
// }}}

//layout_stats
//============

const uint stat_line_ht = 21, stat_line_margin = 3, stat_scroll_width = 16, stat_value_offset = 9;

const uint stat_last_order = 12;

const string@ stat_sprite_bank = "new_layout_icons";
const string@ strPointDefense = "PointDefense";

class layout_stats : ScriptedGuiHandler {
	lyt_stat_entry@[] stats;
	dictionary spriteIndices;
	dictionary statOrders;
	GuiScrollBar@ scroll;
	GuiElement@ ele;

	int hovered;
	
	void addStatInfo(const string@ name, int64 sprite, int64 order) {
		spriteIndices.set(name, sprite);
		statOrders.set(name, order);
	}

	void setVisible(bool vis) {
		ele.setVisible(vis);
	}

	bool isVisible() const {
		return ele.isVisible();
	}
	
	layout_stats() {
		addStatInfo("Air",		4, 0);
		addStatInfo("Control",	6, 0);
		addStatInfo("Crew",		5, 0);
		addStatInfo("HP",		9, 1);
		addStatInfo("RegenDelay",	9, 1);
		addStatInfo("Regen",	9, 1);	
		addStatInfo("RegenCost", 9, 1);
		addStatInfo("Power",	1, 2);		
		addStatInfo("Charge",	0, 2);
		addStatInfo("AntimatterGeneration",	13, 2);
		addStatInfo("Heatsink",		12, 2);
		addStatInfo("HeatReleaseRate",	12, 2);
		addStatInfo("WasteHeat",	12, 2);
		addStatInfo("Alpha",		2, 3);
		addStatInfo("DPS",		2, 3);		
		addStatInfo("AoEDmg",	17, 3);
		addStatInfo("SW Max DPS",	17, 3);
		addStatInfo("Armor",	7, 4);
		addStatInfo("ArmorPoints",	7, 4);
		addStatInfo("ArmorRegen",9, 4);
		addStatInfo("ShieldArmor",	4, 5);
		addStatInfo("ShieldArmorRegen",	4, 5);
		addStatInfo("Shields",	4, 5);
		addStatInfo("ShieldBurst",4, 5);
		addStatInfo("ShieldEmitters",	4, 5);
		addStatInfo("ShieldReg",4, 5);
		addStatInfo("Fuel",		3, 6);
		addStatInfo("FuelUse",	2, 6);
		addStatInfo("Thrust",	2, 6);		
		addStatInfo("PointDefense",	16, 7);
		addStatInfo("BoardingDefense",	7, 7);
		addStatInfo("RepOther",	9, 8);
		addStatInfo("PowerVamp",1, 8);
		addStatInfo("ControlDmg",15, 8);
		addStatInfo("StargateRange", 16,8);		
		addStatInfo("DrainRate",10, 8);
		addStatInfo("Salvage",10, 8);		
		addStatInfo("ShipBay",10, 9);		
		addStatInfo("Troops",14, 9);		
		addStatInfo("ExternalMounts",7, 9);	
		addStatInfo("AsteroidUse",11, 10);		
		addStatInfo("AmmoUse",	8, 10);		
		addStatInfo("H3Usage", 3,10);
		addStatInfo("OreUsage", 10,10);
		addStatInfo("AdvCost", 10,10);
		addStatInfo("MetalCost",10,10);		
		addStatInfo("ElecsCost",10,10);	
		addStatInfo("AdvStore",	10, 11);		
		addStatInfo("H3Storage", 3,11);
		addStatInfo("MtlStore",	10, 11);	
		addStatInfo("OreStore", 10 ,11);	
		addStatInfo("Cargo",	10, 11);	
		addStatInfo("EcoStore",	10, 11);
		addStatInfo("ElecStore",10, 11);
		addStatInfo("Ammo",		8,11);	
		addStatInfo("Asteroids",11, 11);	
		addStatInfo("Mass",		10, 12);		
		hovered = -1;
	}
	
	void init(GuiElement@ ele) {
		@this.ele = ele;
		dim2di parentSize = ele.getSize();
		@scroll = GuiScrollBar(recti(), false, ele);
		scroll.setVisible(false);
		syncSize(parentSize);
	}

	void syncSize(dim2di parentSize) {
		recti rect(parentSize.width - stat_scroll_width, 0, parentSize.width, parentSize.height);
		scroll.setPosition(rect.UpperLeftCorner);
		scroll.setSize(rect.getSize());

		scroll.setPageSize(parentSize.height);
		scroll.setSmallStep(stat_line_margin + stat_line_ht);
		scroll.setLargeStep(parentSize.height / 3);
	}
	
	void updateScroll() {
		const uint line_height = stat_line_margin + stat_line_ht;
		const uint totalHeight = (line_height * stats.length()) + stat_line_margin;
		const uint visibleHeight = scroll.getSize().height;
		
		if(visibleHeight >= totalHeight) {
			scroll.setMax(0);
			scroll.setVisible(false);
		}
		else {
			scroll.setMax(totalHeight - visibleHeight);
			scroll.setVisible(true);
		}
	}
	
	void clear() {
		stats.resize(0);
	}
	
	void syncToStats(HullStats@ Stats) {
		stat_data_list[] statData;
		
		uint statCount = Stats.getHintCnt();
		
		//List all values that we'll be needing in the next stage
		statData.resize(statCount);
		uint used = 0;
		for(uint i = 0; i < statCount; ++i) {
			string@ statName = Stats.getHintName(i);
			string@ localized = localizeStatName(statName, localeLayoutHint, false);
			if(localized is null)
				continue;
			stat_data_list@ data = @statData[used];
			@data.name = @statName;
			@data.locale = @localized;
			if (data.name == strPointDefense)
				data.value = min(Stats.getHint(i), 0.8f);
			else
				data.value = Stats.getHint(i);
			//data.value = Stats.getHint(i);
			
			int64 orderIndex = stat_last_order;
			statOrders.get(statName, orderIndex);
			data.order = uint(orderIndex);
			
			++used;
		}
		if(statCount != used) {
			statCount = used;
			statData.resize(statCount);
		}
		stats.resize(statCount);
		
		//Go through all stats, roughly ordering them
		uint outIndex = 0;
		for(uint orderIndex = 0; orderIndex <= stat_last_order; ++orderIndex) {
			for(uint i = 0; i < statCount; ++i) {
				stat_data_list@ data = @statData[i];
				if(data.order != orderIndex)
					continue;
				int64 spriteIndex = -1;
				spriteIndices.get(data.name, spriteIndex);
				@stats[outIndex] = lyt_stat_entry(data.name, data.locale, data.value, int(spriteIndex));
				++outIndex;
			}
		}
		
		updateScroll();
	}
	
	void draw(GuiElement@ ele) {
		ele.toGuiScripted().setAbsoluteClip();
		recti absPos = ele.getAbsolutePosition();
		pos2di topLeft = absPos.UpperLeftCorner;
		dim2di lineSize = dim2di( ele.getSize().width, stat_line_ht);
		
		if(scroll.isVisible()) {
			lineSize.width -= stat_scroll_width + 1;
			topLeft.y -= scroll.getPos();
		}
		
		Color bgCol = Color(255, 30, 30, 30), posCol = Color(255, 30, 255, 30), negCol = Color(255, 255, 30, 30);
		Color lineCol(0xff474747);

		if (topLeft.y >= absPos.UpperLeftCorner.y)
			drawLine(topLeft, topLeft + pos2di(lineSize.width, 0), lineCol);
		
		uint statCount = stats.length();
		for(uint i = 0; i < statCount; ++i) {
			topLeft.y += stat_line_margin;

			lyt_stat_entry@ entry = @stats[i];
			//drawPane( recti(topLeft, lineSize), bgCol, true );
			if(entry.spriteIndex >= 0)
				drawSprite( stat_sprite_bank, uint(entry.spriteIndex), topLeft + pos2di(2,1));
			drawText( entry.name, recti(topLeft + pos2di(6+21,2), lineSize) );

			dim2di textSize = getTextDimension(entry.value);
			drawText( entry.value, recti(topLeft + pos2di(lineSize.width - textSize.width - stat_value_offset,2), lineSize), entry.positive ? posCol : negCol, false, false );
			topLeft.y += stat_line_ht;

			if (topLeft.y > absPos.LowerRightCorner.y)
				break;
			if (topLeft.y > absPos.UpperLeftCorner.y)
				drawLine(topLeft + pos2di(0, 2), topLeft + pos2di(lineSize.width, 2), lineCol);
		}
		
		clearDrawClip();
	}
	
	EventReturn onKeyEvent(GuiElement@,const KeyEvent&) {
		return ER_Pass;
	}
	
	EventReturn onMouseEvent(GuiElement@ ele, const MouseEvent& evt) {
		switch (evt.EventType) {
			case MET_MOVED: {
				pos2di relPos = pos2di(evt.x, evt.y) - ele.getAbsolutePosition().UpperLeftCorner;

				if(scroll.isVisible())
					relPos.y += scroll.getPos();

				hovered = (relPos.y-2) / (stat_line_ht + stat_line_margin);
				if (uint(hovered) >= stats.length())
					hovered = -1;
			} break;
			case MET_LEFT_UP:
				setGuiFocus(scroll);
			break;
		}
		return ER_Pass;
	}
	
	EventReturn onGUIEvent(GuiElement@ ele, const GUIEvent& evt) {
		switch (evt.EventType) {
			case GEVT_Mouse_Left:
				hovered = -1;
			break;
		}
		return ER_Pass;
	}
};

class stat_data_list {
	string@ name;
	string@ locale;
	float value;
	uint order;
};

class lyt_stat_entry {
	string@ stat;
	string@ name;
	string@ value;
	string@ tooltip;
	bool positive;
	bool highlighted;
	uint spriteIndex;
	
	lyt_stat_entry(string@ Stat, string@ statName, float statValue, int SpriteIndex) {
		highlighted = false;
		@name = @statName;
		@stat = @Stat;

		spriteIndex = SpriteIndex;
		
		positive = statValue >= 0;
		@value = standardize(statValue);

		@tooltip = localize("#STT_"+stat);
		if (tooltip.find("#") == 0)
			@tooltip = null;
	}
};

int pageMode = 0;

enum WeaponStats {
	WS_Heat,
	WS_Range,
	WS_DPS,
	WS_ShotDamage,
	WS_ShotDelay,
	WS_AmmoUse,
};

class StatGraphEntry {
	float val;
	string@ text;
	string@ hoverText;
	const Texture@ img;
	recti img_rect;
};

int sg_entryWidth = 44;
class StatGraph : ScriptedGuiHandler {
	float minimum;
	float maximum;
	string@ suffix;
	GuiScrollBar@ scroll;
	GuiStaticText@ hover;
	StatGraphEntry[] stats;
	
	int eleHeight;
	
	StatGraph() {
		minimum = 0.f;
		maximum = 1.f;
	}
	
	void setSuffix(string@ txt) {
		if(suffix is null)
			@suffix = "";
		suffix = txt;
	}
	
	void clear() {
		stats.resize(0);
		scroll.setVisible(false);
		scroll.setPos(0);
	}

	void addStat(float val, const Texture@ img) {
		addStat(val, img, null);
	}
	
	void addStat(float val, const Texture@ img, string@ hoverText) {
		uint cnt = stats.length();
		stats.resize(cnt+1);
		StatGraphEntry@ sge = @stats[cnt];
		sge.val = val;
		@sge.text = standardize(val) + suffix;
		@sge.img = @img;
		@sge.hoverText = hoverText;
		sge.img_rect = img.rect;
		
		int totalHeight = (cnt+1) * 32;
		if(totalHeight > eleHeight) {
			scroll.setVisible(true);
			scroll.setMax(totalHeight - eleHeight);
		}
		else {
			scroll.setVisible(false);
		}
	}
	
	void draw(GuiElement@ ele) {
		ele.toGuiScripted().setAbsoluteClip();
		recti absPos = ele.getAbsolutePosition();
		
		uint statCount = stats.length();
		
		int leftBarWidth = sg_entryWidth;
		int scrolled = 0;

		if(scroll.isVisible()) {
			leftBarWidth += scroll.getSize().width;
			scrolled = scroll.getPos();
		}
		
		{
			recti entryImgRect(absPos.UpperLeftCorner, dim2di(32, 32));
			entryImgRect += pos2di(0, -scrolled);
			for(uint i = 0 ; i < statCount; ++i) {
				StatGraphEntry@ sge = @stats[i];
				drawTexture(sge.img, entryImgRect, sge.img_rect, Color(255,255,255,255), true);
				entryImgRect += pos2di(0,32);
			}
		}
		
		absPos.UpperLeftCorner += pos2di(leftBarWidth, 0);
		
		uint width = absPos.getWidth(), height = absPos.getHeight();
		
		drawRect(absPos, Color(255, 2, 0, 48), Color(255, 0,0,0), false);
		Color lineCol(255, 0, 51, 48);
		for(uint x = 0; x < width; x += 16)
			drawLine(absPos.UpperLeftCorner + pos2di(x,0), absPos.UpperLeftCorner + pos2di(x,height), lineCol);
		for(uint y = 0; y < height; y += 16)
			drawLine(absPos.UpperLeftCorner + pos2di(0,y), absPos.UpperLeftCorner + pos2di(width,y), lineCol);
		
		Color leftMin(255, 126,135,138), rightMin(255, 227, 245, 250), leftMax(255, 0,107,138), rightMax(255, 0,198,255);
		Color negRightMin(255, 138, 120, 100), negLeftMin(255, 250, 200, 150), negRightMax(255, 138, 100, 0), negLeftMax(255, 255, 198, 0);
		
		pos2di topLeft = absPos.UpperLeftCorner + pos2di(0, 6 - scrolled);
		
		if(minimum >= 0) {
			for(uint i = 0; i < statCount; ++i) {
				StatGraphEntry@ sge = @stats[i];
				float stat = sge.val;
				float pct = 1.f - sqr(1.f - (stat / maximum));
				Color left = leftMax.interpolate(leftMin, pct), right = rightMax.interpolate(rightMin, pct);
				
				float right_x = stat * float(width) / maximum;
				
				drawRect(recti(topLeft, dim2di(right_x, 20)), left, right, true);
				drawText(sge.text, strStrokedFont, recti(topLeft + pos2di(right_x + 10, 2), dim2di(60,20)), Color(0xffffffff), false, false);
				topLeft.y += 32;
			}
		}
		else {
			float halfWidth = float(width/2);
			pos2di middle = topLeft + pos2di(width/2,0);
			for(uint i = 0; i < statCount; ++i) {
				StatGraphEntry@ sge = @stats[i];
				float stat = sge.val;
				if(stat > 0) {
					float pct = 1.f - sqr(1.f - (stat / maximum));
					Color left = leftMax.interpolate(leftMin, pct), right = rightMax.interpolate(rightMin, pct);
				
					float right_x = stat * halfWidth / maximum;
					
					drawRect(recti(middle, dim2di(right_x, 20)), left, right, true);
					drawText(sge.text, strStrokedFont, recti(middle + pos2di(right_x + 10, 2), dim2di(60,20)), Color(0xffffffff), false, false);
				}
				else {
					float pct = 1.f - sqr(1.f - (stat / minimum));
					Color left = negLeftMax.interpolate(negLeftMin, pct), right = negRightMax.interpolate(negRightMin, pct);
				
					float left_x = halfWidth - (stat * halfWidth / minimum);
					
					drawRect(recti(topLeft + pos2di(left_x,0), dim2di(halfWidth - left_x, 20)), left, right, true);
					drawText(sge.text, strStrokedFont, recti(topLeft + pos2di(left_x - 70, 2), dim2di(60,20)), Color(0xffffffff), false, false);
				}
				topLeft.y += 32;
				middle.y += 32;
			}
		}
		
		clearDrawClip();
	}

	void setSize(dim2di newSize) {
		eleHeight = newSize.height;
		scroll.setSize(dim2di(16, eleHeight));
		scroll.setPageSize(eleHeight);

		int totalHeight = stats.length() * 32;
		if(totalHeight > eleHeight) {
			scroll.setVisible(true);
			scroll.setMax(totalHeight - eleHeight);
		}
		else {
			scroll.setVisible(false);
		}
	}
	
	void init(GuiElement@ ele) {
		eleHeight = ele.getSize().height;
		@scroll = GuiScrollBar(recti(sg_entryWidth, 0, sg_entryWidth+16, eleHeight), false, ele);
		scroll.setVisible(false);
		scroll.setSmallStep(32/2);
		scroll.setLargeStep(32*3);
		scroll.setPageSize(eleHeight);

		@hover = GuiStaticText(recti(0, 0, 300, 20), null, false, false, false, ele);
		hover.setFont("stroked");
	}
	
	EventReturn onKeyEvent(GuiElement@, const KeyEvent&) { return ER_Pass; }

	EventReturn onMouseEvent(GuiElement@ ele, const MouseEvent& evt) {
		switch (evt.EventType) {
			case MET_MOVED: {
				pos2di mousePos = pos2di(evt.x, evt.y) - ele.getAbsolutePosition().UpperLeftCorner;

				if (mousePos.x < 0 || mousePos.x > sg_entryWidth) {
					hover.setVisible(false);
					return ER_Pass;
				}

				int scrolled = 0;
				if(scroll.isVisible())
					scrolled = scroll.getPos();

				if (mousePos.y < 0 || mousePos.y > 32 * stats.length() - scrolled ) {
					hover.setVisible(false);
					return ER_Pass;
				}

				uint num = floor((mousePos.y - scrolled) / 32);

				if (num < stats.length() && stats[num].hoverText !is null) {
					hover.setPosition(mousePos + pos2di(15, -6));
					hover.setText(stats[num].hoverText);
					hover.setVisible(true);
				}
				else {
					hover.setVisible(false);
				}
			} break;
		}
		return ER_Pass;
	}

	EventReturn onGUIEvent(GuiElement@ ele, const GUIEvent& evt) {
		if (evt.EventType == GEVT_Focus_Gained && evt.Caller !is scroll) {
			setGuiFocus(scroll);
			return ER_Absorb;
		}
		if (evt.EventType == GEVT_Mouse_Left)
			hover.setVisible(false);
		return ER_Pass;
	}
};


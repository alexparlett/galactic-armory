funcdef void EmpireImageCallback(const Empire@);

class EmpireImage : ScriptedGuiHandler {
	const Empire@ emp;
	GuiScripted@ scripted;
	EmpireImageCallback@ cb;
	bool mirror;
	float portraitMagnify;

	EmpireImage(const Empire@ Emp, recti pos, GuiElement@ parent) {
		@emp = Emp;
		@scripted = GuiScripted(pos, this, parent);
		mirror = false;
		portraitMagnify = 1.f;
	}

	void setPortraitMagnify(float val) {
		portraitMagnify = val;
	}
	
	void setMirror(bool Mirror) {
		mirror = Mirror;
	}
	
	void setCallback(EmpireImageCallback@ callback) {
		@cb = callback;
	}

	void setPosition(pos2di pos) {
		scripted.setPosition(pos);
	}

	void setSize(dim2di size) {
		scripted.setSize(size);
	}

	pos2di getPosition() {
		return scripted.getPosition();
	}

	dim2di getSize() {
		return scripted.getSize();
	}

	void setVisible(bool vis) {
		scripted.setVisible(vis);
	}

	bool isVisible() {
		return scripted.isVisible();
	}

	void remove() {
		scripted.remove();
		@scripted = null;
	}

	void setEmpire(const Empire@ Emp) {
		@emp = Emp;
	}

	const Empire@ getEmpire() {
		return emp;
	}

	void draw(GuiElement@ ele) {
		if (emp is null)
			return;

		ele.toGuiScripted().setAbsoluteClip();
		const recti absPos = ele.getAbsolutePosition();
		pos2di topLeft = absPos.UpperLeftCorner;
		pos2di botRight = absPos.LowerRightCorner;
		dim2di size = absPos.getSize();

		Color empCol = emp.color;
		Color darkCol = empCol.interpolate(Color(0xff000000), 0.3f);
		Color lightCol = empCol.interpolate(Color(0x66666666), 0.4f);
		//drawRect(absPos, darkCol, lightCol, false);

		int flagSize = min(size.width * 0.6f, size.height * 0.6f);
		int portraitSize = min(size.width, size.height) * portraitMagnify;
		const Texture@ flag = getFlag(emp.flag);
		const Texture@ portrait = getPortrait(emp.portrait);
		const Texture@ bg = getBackground(emp.background);
		const Texture@ frame = getMaterialTexture("portrait_frame");
		
		if (bg !is null) {
			int texSize = bg.size.width;
			if (size.width > size.height) {
				int heightSize = float(texSize) * (float(size.height) / float(size.width));
				drawTexture(bg, absPos,
						recti(pos2di(0, (texSize - heightSize) / 2),
						dim2di(texSize, heightSize)));
			}
			else {
				int widthSize = float(texSize) * (float(size.width) / float(size.height));
				drawTexture(bg, absPos,
						recti(pos2di((texSize - widthSize) / 2, 0),
						dim2di(widthSize, texSize)));
			}
		}

		if (flag !is null) {
			recti flagRect;

			if (mirror) {
				flagRect = recti(
					topLeft + pos2di(4,4),
					dim2di(flagSize, flagSize));
			}
			else {
				pos2di flagPos(size.width - flagSize - 4, 4);
				dim2di flagDim(flagSize, flagSize);
				flagRect = recti(topLeft + flagPos, flagDim);
			}

			drawTexture(flag, flagRect,
				recti(pos2di(), flag.size), empCol, true);
		}

		if (portrait !is null) {
			recti ptRect;

			if (mirror) {
				ptRect = recti(
					topLeft + pos2di(
						size.width,
						size.height - portraitSize
					),
					topLeft + pos2di(
						size.width - portraitSize,
						size.height
					));
			}
			else {
				pos2di ptPos(0, size.height - portraitSize);
				dim2di ptDim(portraitSize, portraitSize);
				ptRect = recti(topLeft + ptPos, ptDim);
			}

			drawTexture(portrait, ptRect,
				recti(pos2di(), portrait.size), Color(0xffffffff),
				true);
		}

		drawTexture(frame, absPos, recti(pos2di(), frame.size), empCol, true);
		clearDrawClip();
	}
	
	EventReturn onGUIEvent(GuiElement@ ele, const GUIEvent& evt) {
		return ER_Pass;
	}

	EventReturn onMouseEvent(GuiElement@ ele, const MouseEvent& evt) {
		switch (evt.EventType) {
			case MET_LEFT_DOWN:
				if (cb !is null)
					return ER_Absorb;
			break;
			case MET_LEFT_UP:
				if (cb !is null) {
					cb(emp);
					return ER_Absorb;
				}
			break;
		}
		return ER_Pass;
	}

	EventReturn onKeyEvent(GuiElement@ ele, const KeyEvent& evt) {
		return ER_Pass;
	}
};

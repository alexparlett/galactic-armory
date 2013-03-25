//advisor_drag.as
//=================
//drag method

DragResizeEvent handleDragResize2(GuiElement@ ele, const MouseEvent& evt,
		DragResizeInfo& info, int minWidth, int minHeight, int maxWidth, int maxHeight) {
	if (ele is null)
		return RE_None;

	recti absPos = ele.getAbsolutePosition();
	bool vertEven = absPos.getSize().height % 2 == 0;
	bool horizEven = absPos.getSize().width % 2 == 0;
	pos2di mousePos(evt.x, evt.y);

	switch (evt.EventType) {
		case MET_DBL_CLICK: {
			if (evt.y < absPos.UpperLeftCorner.y + 13) {
				info.dragging = false;

				// using maximized for minimizing
				if (info.maximized) {
					info.maximized = false;
					ele.setSize(info.origPos.getSize());
				}
				else {
					info.origPos = recti(ele.getPosition(), ele.getSize());
					ele.setSize(dim2di(minWidth, minHeight));
					info.maximized = true;
				}
				return RE_Resized;
			}
		} break;
		case MET_LEFT_DOWN: {
			int rightDist = absPos.LowerRightCorner.x - mousePos.x;
			int bottomDist = absPos.LowerRightCorner.y - mousePos.y;

			if ((rightDist < 8 && bottomDist < 19) || (rightDist < 19 && bottomDist < 8)) {
				info.horizResize = true;
				info.vertResize = true;
				info.resizing = true;
				info.offset = absPos.LowerRightCorner - mousePos;
				return RE_Handled;
			}
			else if (rightDist < 8) {
				info.horizResize = true;
				info.vertResize = false;
				info.resizing = true;
				info.offset = absPos.LowerRightCorner - mousePos;
				return RE_Handled;
			}
			else if (bottomDist < 8) {
				info.vertResize = true;
				info.horizResize = false;
				info.resizing = true;
				info.offset = absPos.LowerRightCorner - mousePos;
				return RE_Handled;
			}
			else if (true) {
				info.dragging = true;
				info.offset = mousePos - absPos.UpperLeftCorner;
				return RE_Handled;
			}
			return RE_None;
		}
		case MET_MOVED:
			if (info.resizing) {
				dim2di reqSize = absPos.getSize();

				// Limit resize to the edge of the screen
				int screenWidth = getScreenWidth();
				if (mousePos.x > screenWidth)
					mousePos.x = screenWidth;

				int screenHeight = getScreenHeight();
				if (mousePos.y > screenHeight)
					mousePos.y = screenHeight;

				// Check which dimensions to resize
				if (info.horizResize)
					reqSize.width = mousePos.x - absPos.UpperLeftCorner.x + info.offset.x;
				if (info.vertResize)
					reqSize.height = mousePos.y -absPos.UpperLeftCorner.y + info.offset.y;

				if (reqSize.width < minWidth)
					reqSize.width = minWidth;
				if (maxWidth > 0 && reqSize.width > maxWidth)
					reqSize.width = maxWidth;
				if (reqSize.height < minHeight)
					reqSize.height = minHeight;
				if (maxHeight > 0 && reqSize.height > maxHeight)
					reqSize.height = maxHeight;

				reqSize = makeEven(reqSize, vertEven, horizEven);

				if (reqSize != absPos.getSize()) {
					ele.setSize(reqSize);
					return RE_Resized;
				}
				return RE_Handled;
			}
			else if (info.dragging) {
				ele.setPosition(mousePos - info.offset);
				return RE_Handled;
			}
			break;
		case MET_LEFT_UP:
			if (info.resizing) {
				info.resizing = false;
				return RE_Handled;
			}
			else if (info.dragging) {
				info.dragging = false;
				return RE_Handled;
			}
			break;
	}
	return RE_None;
}

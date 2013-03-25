//advisor_gui.as
//=================
//gui related methods
#include "/advisor_const.as"
#include "/advisor_classes.as"

//IMPORTS

//EXPORTS

recti r(int x, int y, int w, int h) {
	return recti(pos2di(x,y), dim2di(w,h));
}

recti r(pos2di p, int w, int h) {
	return recti(p, dim2di(w,h));
}

pos2di ul(recti r) {
	return r.UpperLeftCorner;
}

pos2di ul(recti r, int offx, int offy) {
	return pos2di(r.UpperLeftCorner.x + offx, r.UpperLeftCorner.y + offy);
}

pos2di ll(recti r) {
	return pos2di(r.UpperLeftCorner.x, r.LowerRightCorner.y);
}

pos2di ll(recti r, int offx, int offy) {
	return pos2di(r.UpperLeftCorner.x + offx, r.LowerRightCorner.y + offy);
}

pos2di ur(recti r) {
	return pos2di(r.LowerRightCorner.x, r.UpperLeftCorner.y);
}

pos2di ur(recti r, int offx, int offy) {
	return pos2di(r.LowerRightCorner.x + offx, r.UpperLeftCorner.y + offy);
}

pos2di lr(recti r) {
	return r.LowerRightCorner;
}

pos2di lr(recti r, int offx, int offy) {
	return pos2di(r.LowerRightCorner.x + offx, r.LowerRightCorner.y + offy);
}

int height(pos2di p1, pos2di p2) {
	return p1.y - p2.y;
}

int width(pos2di p1, pos2di p2) {
	return p1.x - p2.x;
}

string@ toString(recti r) {
	return "recti { x: " + i_to_s(r.UpperLeftCorner.x) + ", y: " + i_to_s(r.UpperLeftCorner.y) + ", width: " + i_to_s(r.getWidth()) + ", height: " + i_to_s(r.getHeight()) + " }";
}

string@ toString(pos2di p) {
	return "pos2di { x: " + i_to_s(p.x) + ", y: " + i_to_s(p.y) + " }";
}

string@ toString(dim2di d) {
	return "dim2di { width: " + i_to_s(d.width) + ", height: " + i_to_s(d.height	) + " }";
}

string@ standardize_nice(float val) {
	if (abs(val) > 0.0001f)
		return standardize(val);
	else
		return "0.00";
}

void updateProd(GuiStaticText@ ele, float gen, float opt) {
	if (opt > 0)
	{
		float pct = gen / opt;
												
		if (pct < 0.1f)
			ele.setColor(cR);
		else if (pct < 0.9f)
			ele.setColor(cY);
		else
			ele.setColor(cG);

		ele.setText(f_to_s(pct*100, 0)+"%");
		ele.setToolTip(standardize_nice(gen) + " / " + standardize_nice(opt));
	}
	else
	{
		ele.setText(null);
		ele.setToolTip(null);
	}
}

void updateCargo(GuiStaticText@ ele, St@ st, St@ tt, Crg@ crg, float exp) {
	float gen = st.val + st.cargo;
	float opt = st.max + st.cargo + crg.left;

	if (opt > 0)
	{
		float pct = gen / opt;
												
		if (pct < 0.1f)
			ele.setColor(cR);
		else if (pct < 0.9f)
			ele.setColor(cW);
		else if (pct <= 1.f)
			ele.setColor(cR);
		else
			ele.setColor(cW);

		if (exp > 0) { // special trade behavior is only for exporting resources
			if (pct > (tt.val - 0.05f) && pct < (tt.val + 0.05f))
				ele.setColor(cG);
		}
		else {
			if (pct > 0.45f && pct < 0.55f) // default trade behavior
				ele.setColor(cG);
		}

		ele.setText(f_to_s(pct*100, 0)+"%");

		string@ strToolTip = standardize_nice(gen) + " / " + standardize_nice(opt);
		if (crg.space > 0.f)
			strToolTip += " (" + standardize_nice(st.cargo) + " / " + standardize_nice(crg.space) + " [" + standardize_nice(crg.left) + "])";

		ele.setToolTip(strToolTip);
	}
}

void updateLabor(GuiStaticText@ ele, St@ labor) {
	if (labor.max > 0)
	{
		float pct = labor.val / labor.max;
												
		if (pct < 0.1f)
			ele.setColor(cY);
		else
			ele.setColor(cW);

		ele.setText(f_to_s(pct*100, 0)+"%");
		ele.setToolTip(standardize_nice(labor.val) + " / " + standardize_nice(labor.max));
	}
}

void updateTrade(GuiStaticText@ ele, St@ trade) {
	if (trade.max > 0)
	{
		float pct = trade.req / trade.max;
												
		if (pct < 0.2f)
			ele.setColor(cY);
		else if (pct <= 0.8f)
			ele.setColor(cW);
		else
			ele.setColor(cY);

		ele.setText(f_to_s(pct*100, 0)+"%");
		ele.setToolTip(standardize_nice(trade.req) + " / " + standardize_nice(trade.max));
	}
}

void updateIE(GuiScripted@ ele, gui_sprite@ spr, float exp, bool bOptimal) {
	string strIE;

	if (bOptimal)
		strIE = "Optimal";
	else
		strIE = "Current";

	if (exp != 0.f) {
		ele.setVisible(true);
		if (exp > 0) {
			spr.index = 1;
			strIE += " export";
		}
		else {
			spr.index = 0;
			strIE += " import";
		}
		ele.setToolTip(strIE + ": " + standardize_nice(abs(exp)));
	}
	else
		ele.setVisible(false);
}

void updateStructures(GuiStaticText@ eleSp, GuiStaticText@ eleSpQue, GuiStaticText@ eleFl, GuiStaticText@ eleFlQue, int max, int cnt, int que) {
	int sp = max - cnt;
	int spQue = sp - que;
	int fl = cnt;
	int flQue = fl + que;

	if (sp > 0)
		eleSp.setColor(cY);
	else
		eleSp.setColor(cG);

	if (fl < max)
		eleFl.setColor(cY);
	else
		eleFl.setColor(cG);

	eleSp.setText(i_to_s(sp));
	eleFl.setText(i_to_s(fl));

	if (que > 0) {
		if (spQue > 0)
			eleSpQue.setColor(cY);
		else
			eleSpQue.setColor(cG);
		if (flQue < max)
			eleFlQue.setColor(cY);
		else
			eleFlQue.setColor(cG);

		eleSpQue.setText(i_to_s(spQue));
		eleFlQue.setText(i_to_s(flQue));
	}
	else {
		eleSpQue.setColor(cW);
		eleFlQue.setColor(cW);

		eleSpQue.setText("-");
		eleFlQue.setText("-");
	}

}

void updateWorkers(GuiStaticText@ ele, GuiStaticText@ eleQue, float housing, float housingQue, float workers, float workersQue, int que) {
	float diff = housing + workers;
	float diffQue = diff + housingQue + workersQue;

	if (diff < 0)
		ele.setColor(cR);
	else if (diff < 1000000.f)
		ele.setColor(cY);
	else
		ele.setColor(cG);

	ele.setText(standardize_nice(diff));

	if (que > 0) {
		if (diffQue < 0)
			eleQue.setColor(cR);
		else if (diffQue < 1000000.f)
			eleQue.setColor(cY);
		else
			eleQue.setColor(cG);

		eleQue.setText(standardize_nice(diffQue));
	}
	else {
		eleQue.setColor(cW);
		eleQue.setText("-");
	}

}

void updateOffline(GuiStaticText@ eleOff, GuiStaticText@ eleDest, int offline, int destroyed) {
	if (offline > 0)
		eleOff.setColor(cR);
	else
		eleOff.setColor(cG);

	if (destroyed > 0)
		eleDest.setColor(cR);
	else
		eleDest.setColor(cG);

	eleOff.setText(i_to_s(offline));
	eleDest.setText(i_to_s(destroyed));
}
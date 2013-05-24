void clearOrders(Object@ obj) {
	AIStance old = obj.getStance();
	obj.setStance(AIS_HoldFire);
	obj.setStance(old);

	OrderList orders;
	if(orders.prepare(obj)) {
		orders.clearOrders(true);
		orders.prepare(null);
	}
}
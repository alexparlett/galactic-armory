float BigEnemyShip(const Object@ from, const Object@ to, const Effector@ eff) {
	float distSQ = from.getPosition().getDistanceFromSQ(to.getPosition()) - (from.radius + to.radius);
	float range = eff.range;
	
	if(distSQ <= range * range){
		if(from.getOwner().isEnemy(to.getOwner())){
			float targetScale = to.radius * to.radius;
			float objscale = from.radius * from.radius;
			float compScale = max(objscale / 2.f, 1000.f);
			if(targetScale > compScale){
				const HulledObj@ hulledObj = to.toHulledObj();
				if (@hulledObj !is null)
					return 1.f;
			}
		}
	}
	
	return 0.f;
}
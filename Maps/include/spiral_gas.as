//GALAXY GAS CREATION
// This script generates a spiral-galaxy styled gas

//GAS SETTINGS
//Multiplier to the sprite's size that determines the fade out distance
const float fadeOutFactor = 2.0f;

const float baseSize = 30000.f;

const float endSizeOffset = 0.100f;
//const float endSizeOffsetDark = 1.125f;
const float baseSpriteCount = 200.f;//500

const float baseAngleInc = 30.00f;//8

//Amount of decay in the angle increment due to distance
const float distanceAngleDecay = 60.f;

const float armAngleVariance = randomf(-0.05f, 0.05f);//0.125f;

const float minReachFactor = 0.8f, maxReachFactor = 1.2f;

Color innerCol(10,255,225,160), middleGlowCol(5,192,128,96), outerGlowCol(10,0,64,192), middleCol(15,192,128,96), outerCol(20,0,64,192), galacticGlowCol (255,244,229,208), galacticGlowEdgeCol (64,255,64,12), innerColEye(32,255,255,225), outerColEye(8,255,220,90);

float variedPi = (twoPi * randomf(0.95f, 1.05f));

class galacticArm {
	float reach;
	float startAngle;

}

//Returns the position of the spiral arm at a given angle
//angle: the particular angle to check (in radians, should exceed 2 pi rads to allow more than a full revolution around the galaxy)
//armStart: the angle the arm started at (in radians)
//reach: How far out the arm should reach after 1 revolution
vector spiralArm(float angle, float armStart, float reach) {
	float x = cos(angle + armStart), y = sin(angle + armStart);
	float r = reach * (angle / variedPi);
	return vector(x * r, 0, y * r);
}

//Called after the galaxy has formed
void createEnvironment(vector minBound, vector maxBound) {
	string@ dustSprite = "dust", galacticGlowSprite = "galactic_glow", galacticEyeSprite = "galactic_eye",
			darkDust000 = "darkdust000", darkDust001 = "darkdust001", darkDust002 = "darkdust002", darkDust003 = "darkdust003", 
			darkDust004 = "darkdust004", darkDust005 = "darkdust005", darkDust006 = "darkdust006", darkDust007 = "darkdust007", 
			darkDust008 = "darkdust008", darkDust009 = "darkdust009", darkDust010 = "darkdust010", darkDust011 = "darkdust011", 
			darkDust012 = "darkdust012", darkDust013 = "darkdust013", darkDust014 = "darkdust014", darkDust015 = "darkdust015", 
			darkDust016 = "darkdust016", darkDust017 = "darkdust017", darkDust018 = "darkdust018", darkDust019 = "darkdust019", 
			darkDust020 = "darkdust020", darkDust021 = "darkdust021", darkDust022 = "darkdust022", darkDust023 = "darkdust023", 
			brightDust000 = "darkdust000", brightDust001 = "darkdust001", brightDust002 = "darkdust002", brightDust003 = "darkdust003", 
			brightDust004 = "darkdust004", brightDust005 = "darkdust005", brightDust006 = "darkdust006", brightDust007 = "darkdust007", 
			brightDust008 = "darkdust008", brightDust009 = "darkdust009", brightDust010 = "darkdust010", brightDust011 = "darkdust011", 
			brightDust012 = "darkdust012", brightDust013 = "darkdust013", brightDust014 = "darkdust014", brightDust015 = "darkdust015", 
			brightDust016 = "darkdust016", brightDust017 = "darkdust017", brightDust018 = "darkdust018", brightDust019 = "darkdust019";
	float mbX = maxBound.x * randomf(0.1f, 0.9f); 
	float glxRadius = max(abs(min(minBound.x, minBound.z)), max(maxBound.x, maxBound.z));
	float glxHeight = (maxBound.y - minBound.y) / 2.f;
	
	float spriteSizeMult = baseSize;
	float spriteSizeRingMult = baseSize*25.f;
	float sizeCurve = 0.67f;
	float sizeCurveDark = 1.1f;
	if( getGameSetting("MAP_FLATTEN", 0) == 1) {
		spriteSizeMult = baseSize / 1.35f;
		sizeCurve = 1.f;
		sizeCurveDark = 1.f;
	}
	
	uint armCount = clamp( int(getGameSetting("MAP_GALAXY_ARMS", 4)), 10, 5000 );//1,50
	
	galacticArm[] arms;
	arms.resize( armCount );
	
	float armAngleSeparation = twoPi / float(armCount);

	for(uint i = 0; i < armCount; ++i) {
		arms[i].reach = randomf(glxRadius * minReachFactor, glxRadius * maxReachFactor);
		arms[i].startAngle = (armAngleSeparation * float(i)) + randomf(-armAngleVariance * armAngleSeparation, armAngleVariance * armAngleSeparation);
	}
	
	uint maxSprites = clamp( int(getGameSetting("MAP_BASE_GAS_SPRITES", baseSpriteCount) * sqrt(glxRadius / 35000.f)), armCount, int(getGameSetting("MAP_MAX_GAS_SPRITES", baseSpriteCount * 4.f)) );//*2
	
	float angleInc = baseAngleInc * variedPi / (float(maxSprites) / float(armCount));
	float angle = randomf(0.5);//0.5
	for(uint i = 0; i < maxSprites; i += armCount) {
		float dist;
		for(uint arm = 0; arm < armCount; ++arm) {
			//Get the position on the arm, then randomize the result a bit
			vector spritePos = spiralArm(angle, arms[arm].startAngle, arms[arm].reach);			
			dist = spritePos.getLength() + randomf(-400.f, 400.f);
			float pctTowardCenter = (glxRadius - dist) / glxRadius;
			float pctTowardEdge = 100.f - pctTowardCenter;

			spritePos += vector(randomf(-3.f,3.f), randomf(-3.f,3.f), randomf(-3.f,3.f)) * randomf((1.f - pctTowardCenter) * glxRadius / 40.f);
			

			float spriteSize = spriteSizeMult * range(0.5f , 1.5f, pctTowardCenter + endSizeOffset) * pow(glxRadius / 35000.f, sizeCurve);
			spritePos.y += randomf(-2.f, 2.f) * max((glxHeight * pctTowardCenter * 2.f) - spriteSize, glxHeight / 10.f);

			Color spriteCol = outerCol.interpolate(middleCol, dist / glxRadius);
			Color spriteGlowCol = outerGlowCol.interpolate(middleGlowCol, dist / glxRadius);


			createGalaxyGasSprite(dustSprite, spriteSize, spritePos, spriteGlowCol, spriteSize * fadeOutFactor);
			const float dustroll = randomf(0.f, 20.f);
			if(dustroll <= 1.f){	
				createGalaxyGasSprite(brightDust000, spriteSize, spritePos, spriteCol, spriteSize * fadeOutFactor);
				}
			else if(dustroll <= 2.f){
			createGalaxyGasSprite(brightDust001, spriteSize, spritePos, spriteCol, spriteSize * fadeOutFactor);
				}
			else if(dustroll <= 3.f){
			createGalaxyGasSprite(brightDust002, spriteSize, spritePos, spriteCol, spriteSize * fadeOutFactor);
				}
			else if(dustroll <= 4.f){
			createGalaxyGasSprite(brightDust003, spriteSize, spritePos, spriteCol, spriteSize * fadeOutFactor);
				}
			else if(dustroll <= 5.f){
			createGalaxyGasSprite(brightDust004, spriteSize, spritePos, spriteCol, spriteSize * fadeOutFactor);
				}
			else if(dustroll <= 6.f){
			createGalaxyGasSprite(brightDust005, spriteSize, spritePos, spriteCol, spriteSize * fadeOutFactor);
				}
			else if(dustroll <= 7.f){
			createGalaxyGasSprite(brightDust006, spriteSize, spritePos, spriteCol, spriteSize * fadeOutFactor);
				}
			else if(dustroll <= 8.f){
			createGalaxyGasSprite(brightDust007, spriteSize, spritePos, spriteCol, spriteSize * fadeOutFactor);
				}
			else if(dustroll <= 9.f){
			createGalaxyGasSprite(brightDust008, spriteSize, spritePos, spriteCol, spriteSize * fadeOutFactor);
				}
			else if(dustroll <= 10.f){
			createGalaxyGasSprite(brightDust009, spriteSize, spritePos, spriteCol, spriteSize * fadeOutFactor);
				}
			else if(dustroll <= 11.f){
			createGalaxyGasSprite(brightDust010, spriteSize, spritePos, spriteCol, spriteSize * fadeOutFactor);
				}
			else if(dustroll <= 12.f){
			createGalaxyGasSprite(brightDust011, spriteSize, spritePos, spriteCol, spriteSize * fadeOutFactor);
				}
			else if(dustroll <= 13.f){
			createGalaxyGasSprite(brightDust012, spriteSize, spritePos, spriteCol, spriteSize * fadeOutFactor);
				}
			else if(dustroll <= 14.f){			
			createGalaxyGasSprite(brightDust013, spriteSize, spritePos, spriteCol, spriteSize * fadeOutFactor);
				}
			else if(dustroll <= 15.f){
			createGalaxyGasSprite(brightDust014, spriteSize, spritePos, spriteCol, spriteSize * fadeOutFactor);
				}
			else if(dustroll <= 16.f){
			createGalaxyGasSprite(brightDust015, spriteSize, spritePos, spriteCol, spriteSize * fadeOutFactor);
				}
			else if(dustroll <= 17.f){
			createGalaxyGasSprite(brightDust016, spriteSize, spritePos, spriteCol, spriteSize * fadeOutFactor);
				}
			else if(dustroll <= 18.f){
			createGalaxyGasSprite(brightDust017, spriteSize, spritePos, spriteCol, spriteSize * fadeOutFactor);
				}
			else if(dustroll <= 19.f){
			createGalaxyGasSprite(brightDust018, spriteSize, spritePos, spriteCol, spriteSize * fadeOutFactor);
				}
			else if(dustroll <= 20.f){
			createGalaxyGasSprite(brightDust019, spriteSize, spritePos, spriteCol, spriteSize * fadeOutFactor);
				}
			spritePos.normalize(dist);	
			
			float distDark;
			for(uint arm = 0; arm < armCount; ++arm) {	
			vector darkDustTwirls = spritePos;	
			float distDark = darkDustTwirls.getLength();// + randomf(-400.f, 400.f);//400
			float spriteDarkSizeMult = spriteSizeMult/randomf(3.f, 12.f);//3 12
			float spriteDarkSize;
			if(distDark <= (glxRadius/2.f)){
				spriteDarkSize = spriteDarkSizeMult * range(0.5f , 1.5f, pctTowardCenter + endSizeOffset) * pow(glxRadius / 15000.f, sizeCurve);
				}
			else if (distDark > (glxRadius/2.f)){
				spriteDarkSize = spriteDarkSizeMult * range(0.5f , 1.5f, pctTowardEdge + endSizeOffset) * pow(glxRadius / 15000.f, sizeCurve);				
				}

			Color innerDarkCol(8,32,12,24), outerDarkCol(32,8,6,3);
			Color spriteDarkCol = outerDarkCol.interpolate(innerDarkCol, dist / glxRadius);


			if(darkDustTwirls.y <= -(glxHeight*5.f)){
			darkDustTwirls.y += randomf(-1.f, 2.f) * max((glxHeight * pctTowardEdge * 50.f) - spriteDarkSize, glxHeight / 5.f);
			float xzRoll = randomf(0.f, -1.f);
			if(xzRoll < 0.25f){
			darkDustTwirls.x += randomf(-1.f, 2.f) * max((glxHeight * pctTowardEdge * 50.f) - spriteDarkSize, glxHeight / 5.f);
			darkDustTwirls.z += randomf(-1.f, 2.f) * max((glxHeight * pctTowardEdge * 50.f) - spriteDarkSize, glxHeight / 5.f);
			}
			else if(xzRoll >= 0.5f){
			darkDustTwirls.x += randomf(1.f, -2.f) * max((glxHeight * pctTowardEdge * 50.f) - spriteDarkSize, glxHeight / 5.f);
			darkDustTwirls.z += randomf(1.f, -2.f) * max((glxHeight * pctTowardEdge * 50.f) - spriteDarkSize, glxHeight / 5.f);
			}
			else if(xzRoll >= 0.75f){
			darkDustTwirls.x += randomf(1.f, -2.f) * max((glxHeight * pctTowardEdge * 50.f) - spriteDarkSize, glxHeight / 5.f);
			darkDustTwirls.z += randomf(-1.f, 2.f) * max((glxHeight * pctTowardEdge * 50.f) - spriteDarkSize, glxHeight / 5.f);
			}
			else if(xzRoll >= 1.f){
			darkDustTwirls.x += randomf(-1.f, 2.f) * max((glxHeight * pctTowardEdge * 50.f) - spriteDarkSize, glxHeight / 5.f);
			darkDustTwirls.z += randomf(1.f, -2.f) * max((glxHeight * pctTowardEdge * 50.f) - spriteDarkSize, glxHeight / 5.f);
			}

			}
			else if(darkDustTwirls.y >= (glxHeight*5.f)){
			darkDustTwirls.y += randomf(1.f, -2.f) * max((glxHeight * pctTowardEdge * 50.f) - spriteDarkSize, glxHeight / 5.f);
			float xzRoll = randomf(0.f, 1.f);
			if(xzRoll < 0.25f){
			darkDustTwirls.x += randomf(-1.f, 2.f) * max((glxHeight * pctTowardEdge * 50.f) - spriteDarkSize, glxHeight / 5.f);
			darkDustTwirls.z += randomf(-1.f, 2.f) * max((glxHeight * pctTowardEdge * 50.f) - spriteDarkSize, glxHeight / 5.f);
			}
			else if(xzRoll >= 0.5f){
			darkDustTwirls.x += randomf(1.f, -2.f) * max((glxHeight * pctTowardEdge * 50.f) - spriteDarkSize, glxHeight / 5.f);
			darkDustTwirls.z += randomf(1.f, -2.f) * max((glxHeight * pctTowardEdge * 50.f) - spriteDarkSize, glxHeight / 5.f);
			}
			else if(xzRoll >= 0.75f){
			darkDustTwirls.x += randomf(1.f, -2.f) * max((glxHeight * pctTowardEdge * 50.f) - spriteDarkSize, glxHeight / 5.f);
			darkDustTwirls.z += randomf(-1.f, 2.f) * max((glxHeight * pctTowardEdge * 50.f) - spriteDarkSize, glxHeight / 5.f);
			}
			else if(xzRoll >= 1.f){
			darkDustTwirls.x += randomf(-1.f, 2.f) * max((glxHeight * pctTowardEdge * 50.f) - spriteDarkSize, glxHeight / 5.f);
			darkDustTwirls.z += randomf(1.f, -2.f) * max((glxHeight * pctTowardEdge * 50.f) - spriteDarkSize, glxHeight / 5.f);
			}
			}

darkDustTwirls.normalize(dist);

			const float diceroll = randomf(0.f, 24.f);
			if(diceroll <= 1.f){	
				createGalaxyGasSprite(darkDust000, spriteDarkSize, darkDustTwirls, spriteDarkCol, spriteDarkSize * fadeOutFactor);
				}
			else if(diceroll <= 2.f){
			createGalaxyGasSprite(darkDust001, spriteDarkSize, darkDustTwirls, spriteDarkCol, spriteDarkSize * fadeOutFactor);
				}
			else if(diceroll <= 3.f){
			createGalaxyGasSprite(darkDust002, spriteDarkSize, darkDustTwirls, spriteDarkCol, spriteDarkSize * fadeOutFactor);
				}
			else if(diceroll <= 4.f){
			createGalaxyGasSprite(darkDust003, spriteDarkSize, darkDustTwirls, spriteDarkCol, spriteDarkSize * fadeOutFactor);
				}
			else if(diceroll <= 5.f){
			createGalaxyGasSprite(darkDust004, spriteDarkSize, darkDustTwirls, spriteDarkCol, spriteDarkSize * fadeOutFactor);
				}
			else if(diceroll <= 6.f){
			createGalaxyGasSprite(darkDust005, spriteDarkSize, darkDustTwirls, spriteDarkCol, spriteDarkSize * fadeOutFactor);
				}
			else if(diceroll <= 7.f){
			createGalaxyGasSprite(darkDust006, spriteDarkSize, darkDustTwirls, spriteDarkCol, spriteDarkSize * fadeOutFactor);
				}
			else if(diceroll <= 8.f){
			createGalaxyGasSprite(darkDust007, spriteDarkSize, darkDustTwirls, spriteDarkCol, spriteDarkSize * fadeOutFactor);
				}
			else if(diceroll <= 9.f){
			createGalaxyGasSprite(darkDust008, spriteDarkSize, darkDustTwirls, spriteDarkCol, spriteDarkSize * fadeOutFactor);
				}
			else if(diceroll <= 10.f){
			createGalaxyGasSprite(darkDust009, spriteDarkSize, darkDustTwirls, spriteDarkCol, spriteDarkSize * fadeOutFactor);
				}
			else if(diceroll <= 11.f){
			createGalaxyGasSprite(darkDust010, spriteDarkSize, darkDustTwirls, spriteDarkCol, spriteDarkSize * fadeOutFactor);
				}
			else if(diceroll <= 12.f){
			createGalaxyGasSprite(darkDust011, spriteDarkSize, darkDustTwirls, spriteDarkCol, spriteDarkSize * fadeOutFactor);
				}
			else if(diceroll <= 13.f){
			createGalaxyGasSprite(darkDust012, spriteDarkSize, darkDustTwirls, spriteDarkCol, spriteDarkSize * fadeOutFactor);
				}
			else if(diceroll <= 14.f){			
			createGalaxyGasSprite(darkDust013, spriteDarkSize, darkDustTwirls, spriteDarkCol, spriteDarkSize * fadeOutFactor);
				}
			else if(diceroll <= 15.f){
			createGalaxyGasSprite(darkDust014, spriteDarkSize, darkDustTwirls, spriteDarkCol, spriteDarkSize * fadeOutFactor);
				}
			else if(diceroll <= 16.f){
			createGalaxyGasSprite(darkDust015, spriteDarkSize, darkDustTwirls, spriteDarkCol, spriteDarkSize * fadeOutFactor);
				}
			else if(diceroll <= 17.f){
			createGalaxyGasSprite(darkDust016, spriteDarkSize, darkDustTwirls, spriteDarkCol, spriteDarkSize * fadeOutFactor);
				}
			else if(diceroll <= 18.f){
			createGalaxyGasSprite(darkDust017, spriteDarkSize, darkDustTwirls, spriteDarkCol, spriteDarkSize * fadeOutFactor);
				}
			else if(diceroll <= 19.f){
			createGalaxyGasSprite(darkDust018, spriteDarkSize, darkDustTwirls, spriteDarkCol, spriteDarkSize * fadeOutFactor);
				}
			else if(diceroll <= 20.f){
			createGalaxyGasSprite(darkDust019, spriteDarkSize, darkDustTwirls, spriteDarkCol, spriteDarkSize * fadeOutFactor);
				}
			else if(diceroll <= 21.f){
			createGalaxyGasSprite(darkDust020, spriteDarkSize, darkDustTwirls, spriteDarkCol, spriteDarkSize * fadeOutFactor);
				}
			else if(diceroll <= 22.f){
			createGalaxyGasSprite(darkDust021, spriteDarkSize, darkDustTwirls, spriteDarkCol, spriteDarkSize * fadeOutFactor);
				}
			else if(diceroll <= 23.f){
			createGalaxyGasSprite(darkDust022, spriteDarkSize, darkDustTwirls, spriteDarkCol, spriteDarkSize * fadeOutFactor);
				}
			else if(diceroll <= 24.f){
			createGalaxyGasSprite(darkDust023, spriteDarkSize, darkDustTwirls, spriteDarkCol, spriteDarkSize * fadeOutFactor);
			}

			}
				
			}

		angle += angleInc / ( 1.f + (distanceAngleDecay * dist / glxRadius) );
			}
	float galacticGlowRadius = glxRadius * 2.f;
	float galacticEyeRadius = glxRadius / 5.f;
	const float fadeOutFactorGlow = 0.f;
	{
	vector positionGalacticGlow;
	positionGalacticGlow = vector(0.f,0.f,0.f);
	createGalaxyGasSprite(galacticGlowSprite, galacticGlowRadius, positionGalacticGlow, galacticGlowCol, galacticGlowRadius * fadeOutFactorGlow);
	createGalaxyGasSprite(galacticEyeSprite, galacticEyeRadius, positionGalacticGlow, galacticGlowCol, galacticEyeRadius * fadeOutFactorGlow);
	}	
}


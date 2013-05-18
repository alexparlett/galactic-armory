//empire_ai.as
//Default implementation of the empire AI system
//==============================================
//HOW THIS WORKS:
//
//First: void registerEmpireData(Empire@) is called for every empire in the game - invalids, players, humans
//	This function should call emp.regScriptData(<some class instance>) when it wants to act on behalf of that empire.
//	This informs the engine what callbacks to use later on
//	This can and should be used to manage how the AI reacts to others, recalls what has happened, and plans for the future
//	NOTE: This function is called as the empires are generated. You cannot rely on the existence of other empires during this call.
//
//On every tick of the empire:
//	Internal states are updated automatically. This involves research, dispatching messages, handling the object list updates, and various other things
//
//	If the empire has received diplomatic messages, calls void onDiplomaticMessage(Empire@ receiver, Empire@ sender, <specified class>@, DiplomaticMessage@) for each message
//		This function should manipulate the diplomatic message to indicate how things went, as well as manage its states based on that reaction
//
//	Calls void empireAITick(Empire@, <specified class>@, float tickDuration)
//		This should handle logic that isn't handled by object orders and settings (e.g. Auto-Colonize, planet governors, etc)
//			This typically involves analyzing the situation, and giving orders to objects to fit the situation
//			As well as adjusting empire settings, such as the current research.


#include "/include/empire_lib.as"

bool initialized = false;
float maxAIDifficulty = -1.f;
import void LevelTech (Empire@ emp, string@ techName, float Level) from "Traits";

/* Called for each empire to register any AI or defaults it might need */
void registerEmpireData(Empire@ emp) {
	if(isClient())
		return;

	if(!initialized) {
		loadDefaults(false);
		
		initialized = true;
	}
	
	if(emp.isValid()) {
		if(emp.isAI()){
			if(emp.ID == -2) {
				print("Registering pirate AI for " + emp.getName());
				emp.regScriptData("pirate_ai", "PirateAIData");
			}
			else if(emp.ID == -3) {
				print("Registering remnant AI for " + emp.getName());
				emp.regScriptData("remnant_ai", "RemnantAIData");
			}		
		}
		else {
			// Automatically govern new planets
			emp.setSetting("autoGovern", 1);
			// And choose a best-fit governor based on planet conditions
			emp.setSetting("defaultGovernor", -1);
			// Record that this used to be a player empire
			emp.setSetting("Difficulty", -1.f);
			
			// Create ship layouts
			if(emp.getShipLayoutCnt() == 0) {
				ResearchWeb web;
				web.prepare(emp);

				int designCount = defaultDesigns.length();
				for(int i = 0; i < designCount; ++i)
					if(defaultDesigns[i].forHuman && defaultDesigns[i].canCreate(emp, web))
						defaultDesigns[i].generateForEmpire(emp);
			}
		}

		if(emp.hasTraitTag("automated"))
		{
			LevelTech(emp, "Computers", 1);
			loadDesignsForTrait(emp, "automated");
		}
	}
}

/* Called for all possible combinations of empires within a team */
void registerTeam(Empire@ from, Empire@ to, int team) {
	// Propose treaty
	TreatyFactory@ fact = TreatyFactory(from, to);
	Treaty@ treaty = @fact.get_treaty();

	treaty.addClause("vision", false);
	treaty.addClause("vision", true);
	treaty.addClause("peace", true);

	fact.propose();

	// Accept treaty
	TreatyList treaties;
	treaties.prepare(to);

	@treaty = treaties.getProposedTreaty(from);
	if (treaty is null) {
		error("Error: failed to initialize team treaty for team "+team+".");
		return;
	}

	treaties.setAcceptance(from, true);

	// Set allied state (bidirectional)
	from.setAllied(to, true);
}

/* Called for all empires that should start at war with each other */
void registerHostilities(Empire@ from, Empire@ to) {
	TreatyFactory@ factory = TreatyFactory(from, to);
	factory.treaty.addClause("war", false);
	factory.propose();
}

/* Called to add any 'special' empires to the game.
 *
 * Note:
 *  - Only 32 empires can be in a game at any time. (Including Space)
 *  - The player can add up to 27 AIs.
 *  - Empires created here will not have a homeworld set up automatically.
 */
void registerSpecialEmpires() {
	if(getGameSetting("MAP_PIRATES", 1.f) > 0.5f) {
		// The pirates raid resources from any undefended systems
		Empire@ pirates = addEmpire(-2);
		pirates.setReserved(true);
		pirates.setName(localize("#NM_Pirates"));
		pirates.color = Color(0xff8c0000);
		pirates.setShipSet("terrakin");
	}

	if(getGameSetting("MAP_SPECIAL_SYSTEMS", 1.f) > 0.5f) {	
		// The remnants are leftover guardians of a fallen empire
		Empire@ remnants = addEmpire(-3);
		remnants.setReserved(true);
		remnants.setName(localize("#NM_Remnants"));
		remnants.color = Color(0xffccc5ab);
		remnants.setShipSet("neumon");
	}
}

void loadDesignsForTrait(Empire@ emp, string@ trait)
{
	if (emp.hasTraitTag(trait))
	{
		ResearchWeb web;
		web.prepare(emp);

		int designCount = defaultDesigns.length();
		for(int i = 0; i < designCount; ++i)
		{
			if(defaultDesigns[i].forTrait == trait && defaultDesigns[i].canCreate(emp, web))
			{
				defaultDesigns[i].generateForEmpire(emp);
			}
		}
	}

}
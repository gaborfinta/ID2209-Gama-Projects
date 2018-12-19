/**
* Name: Assignment 2
* Author: Finta, Vartiainen
* Description: Festival scene with hungry guests, bad guests and a security guard
* 
* The project should run without any special measures in gama 1.8
*/

model NewModel
global 
{
	/*
	 * Agent colors
	 */
	 rgb guestColor <- #red;
	 rgb unconsciousColor <- #yellow;
	 rgb zombieColor <- #lime;
	 rgb securityColor <- #black;
	 rgb ambulanceColor <- #teal;
	 rgb barColor <- #purple;
	 rgb infoCenterColor <- #blue;
	 
	/*
	 * Guest configs
	 */
	//int guestNumber <- rnd(20)+20;
	int guestNumber <- 30;
	float guestSpeed <- 0.5;
	
	// the rate at which guests grow hungry / thirsty
	// every reflex we reduce hunger / thirst by rnd(0,rate) * 0.1
	//now if this is -1, guests will use their personal random hunger rate
	// if it is not -1, they use this instead as a global hungerrate
	int globalHungerRate <- -1;
	//they will start looking for food under this value
	int gettingHungry <- 30;
	
	//the global rate at which happiness will be decreased
	float globalHappinessRate <- 0.05;
	
	list<string> guestPersonalitiesEnum <- ["Party", "Chill", "Scientist", "FlatEarther"];
	
	/*
	 * Building configs
	 */
	int approximateDetectionDistance <- 3;
	point infoCenterLocation <- {50,50};
	int barNumber <- rnd(3, 4);
	
	/*
	 * Auction configs
	 */
	point showMasterLocation <- {-10,50};
	//also determines the number of auctions
	//list<string> itemsAvailable <- [];
	list<string> itemsAvailable <- ["branded backpacks","signed shirts","heavenly hats", "posh pants"];
	list<string> auctionTypes <- ["Dutch", "English", "Sealed"];
	int auctionerWaitTime <- 10;
	// The range for the pause between auctions/shows
	int showMasterIntervalMin <- 100;
	int showMasterIntervalMax <- 300;
	
	// Time when auctioneers are created
	int auctionCreationMin <- 150;
	int auctionCreationMax <- 200;
	
	// Guest accepted price range min and max
	int guestAcceptedPriceMin <- 100;
	int guestAcceptedPriceMax <- 1500;
	
	// English auction configs
	// bid raise min and max
	int engAuctionRaiseMin <- 30;
	int engAuctionRaiseMax <- 60;
	// The initial price of the item to sell
	int auctionerEngPriceMin <- 0;
	int auctionerEngPriceMax <-1500;
	
	// Dutch auction configs
	// bid decrease min and max 
	int dutchAuctionDecreaseMin <- 5;
	int dutchAuctionDecreaseMax <- 15;
	// The initial price of the item to sell, set above the max price so that no guest immediately wins
	int auctionerDutchPriceMin <- 1504;
	int auctionerDutchPriceMax <-1600;
	// Minimum price of the item, if the bids go below this the auction fails
	int auctionerMinimumValueMin <- 90;
	int auctionerMinimumValueMax <- 300;
	
	/*
	 * Stage configs
	 */
	int stageNumber <- 4;
	int stageParameterMin <- 1;
	int stageParameterMax <- 100;
	int durationMin <- 400;
	int durationMax <- 700;
	list<string> genresAvailable <- ["sensational synthwave"
									,"trashy techno"
									,"dope darkwave"
									,"80's mega hits"
									,"traditional Russian song techno remixes"
									,"Sandstorm"
									,"incredible Italo Disco"
									,"impressive industrial"
									,"generic German New Wave"
									,"pompous punk rock"
									,"old people rock"
									,"extreme experimental"
									,"rubber chicken Despacito"
									,"ingenious indigenous instrumental"
									,"pungmul"
									,"pansori"
									,"geomungo sanjo"
									];
	//also determines the number of stages
	//list<rgb> stageColors <- [];
	list<rgb> stageColors <- [#lime, #pink, #lightblue, #purple];
	float globalUtility <- 0.0;
	
	/*
	 * Other agent configs
	 */	
	// Robotcop is a bit faster than guests, also used by ambulances
	float roboCopSpeed <- guestSpeed * 1.5;
	// The number of ambulances is propotionate to the amount of guests
	int ambulanceNumber <- max([1, round(guestNumber / 4)]);
	
	// A list of all humans for convenience
	list<Human> allHumans;
	// A list used to keep track of zombies
	list<Human> zombies;
	
	// Zombie config
	// chance of guest being created a zombie
	float zombieChance <- 0.3;
	// Chance of security winning a fight, if lose they get bitten and become zombie
	float securityFightSuccessFactor <- 0.7;
	// chance of a zombie winning a fight, if they lose they pass out
	float zombieFightSuccessFactor <- 0.7;
	
	//Everything happens only once per day
	int currDay <- 0;
	int cyclesPerDay <- 3000;
	
	//LongStayPlace configs
	float longStayPlaceRadius <- 4.0;
	float floatError <- 0.0001;
	int maxNumberOfCyclesAtPlace <- 200;
	int minNumberOfCyclesAtPlace <- 100;
	//under this value, the guests will be disturbed by their nemesis
	float feelingFineValue <- 40.0;
	
	init
	{	
		/*
		 * Number of auctioners is defined above 
		 */
		create ShowMaster number: 1
		{
			location <- showMasterLocation;
		}
		
		/* Create guestNumber (defined above) amount of Guests */
		create Guest number: guestNumber
		{

		}
		
		/*
		 * Number of bars is defined above
		 */
		 
		create Bar number: barNumber
		{

		}
		
		/*
		 * location is 50,50 to put the info center in the middle
		 */
		create InfoCenter number: 1
		{
			location <- infoCenterLocation;
		}
			
		/* Create security */
		create Security number: ambulanceNumber
		{

		}
		
		/* Create hospital */
		create Hospital number: 1
		{
			
		}
		
		/* Create ambulance */
		create Ambulance number: ambulanceNumber
		{
			
		}
		
		//		// This returns all humans, essentially
//	    list<Human> getAllHumans
//	    {
//	    	return Guest.population + Ambulance.population + Security.population;
//	    }
		allHumans <- Guest.population + Ambulance.population + Security.population;
		write allHumans;
	}
	reflex currDay when: time != 0 and mod(time, cyclesPerDay) = 0
	{
		currDay <- currDay + 1;
	}
	
}

/*
 * This covers most non-building agents.
 * All humans have a set of common reflexes and actions, such as eating and wandering etc.
 * 
 * Common functions for all humans:
 * hunger / thirst (ambulances and security hunger rate is 0 for now)
 * going to target building/human
 * 
 * being a zombie
 * 
 * Also zombies use humans as their targets and every human can become a zombie, although they will remember what kind of a role they had before becoming a zombie
 */
species Human skills:[moving]
{
	// Default hunger vars
	float hunger <- 0.0;
	int hungerRate <- rnd(1, 3);
	// even though all humans grow hungry right now, ambulances and security have a *0 modifier
	// they will start growing hungry if zombies
	int hungerModifier <- 1;
	
	// Guests can fall unconscious after their thirst/hunger falls to zero, or the security knocks them unconscious
	bool isConscious <- true;
	
	// White models against a white background -> a lazy way of making the default color mostly invisible
	rgb myColor <- #gray;
	rgb originalColor <- #gray;
	
	bool isZombie <- false;
	
	// This is used when guests stay at longStayPlaces
	pair<float, float> targetOffset <- 0.0 :: 0.0;
	// Default speed of all humans is guestSpeed
	float mySpeed <- guestSpeed;
	float originalSpeed <- guestSpeed;
	
	// A human may have a target of any species, used when moving
	agent target;
	
	// If this is a wandering kind of human. Ambulances aren't.
	// two variables for zombification - zombified ambulances wander, normal ones don't
	// we want to be able to back to the original state (same as original speed/color)
	bool wanderer <- true;
	bool wander <- true;
	
	// Used by security and zombies to pause securitying or zombieing while auctions are running
	bool auctionsRunning <- false;
	
	aspect default
	{
		draw sphere(2) at: location color: myColor;
	}
	
// Human reflexes
	
	/* 
	 * When agent has target, move towards target
	 * note: unconscious guests can still move, just to enable them moving to the hospital
	 */
	reflex moveToTarget when: target != nil and !dead(target)
	{
		do goto target:{target.location.x + targetOffset.key, target.location.y + targetOffset.value} speed: mySpeed;
	}
	
	/*
	 * humans grow hungry over time
	 * hungerModifier is set to 1 with guests and 0 with security and agents
	 * for zombies it will be higher
	 */
	reflex growHunger
	{
		hunger <- hunger - rnd(hungerRate) * 0.1 * hungerModifier;
	}

	/*
	 * it is a universal human quality to wander when they have nothing else to do
	 */	
	reflex wanderRandomly when: target = nil and isConscious and wander
	{
		do wander;
	}
	
	/*
	 * When zombies are hungry they will chase the nearest non-zombie human and fight them.
	 * Zombies have a 10% chance of losing and falling unconscious.
	 * Unconscious zombies don't pick targets
	 */
	reflex beZombie when: isZombie and hunger < gettingHungry and target = nil and isConscious
	{
		//If auctions are running, don't zombie
		ask one_of(ShowMaster)
		{
			if(auctionsRunning)
			{
				myself.auctionsRunning <- true;
			}
			else
			{
				myself.auctionsRunning <- false;
			}
		}
		
		// If auctions are running, we're not gonna do anything here
		// you can't interrupt the march of capitalism
		if(!auctionsRunning)
		{
			list<Human> tempAllHumans <- allHumans;
			Human targetHuman <- nil;
			// pick a random human
			loop while: (target = nil and length(tempAllHumans) > 0)
			{
				targetHuman <- one_of(tempAllHumans);
				if(!targetHuman.isZombie)
				{
					target <- targetHuman;
				}
				else
				{
					tempAllHumans >- targetHuman;
				}
			}
		}		
	}
	
	/*
	 * Whenever a human reaches a target human, they will fight them
	 * This occurs with security and zombies
	 * (even though ambulances head towards humans, they use a separate targetHuman variable, not target and therefore do not try to fight the patients... Luckily)
	 * The SuccessFactors for winning a fight are defined separately for security and zombies in the config at the very top
	 * 
	 * If a zombie wins a fight, the target becomes a zombie
	 * else the zombie falls unconscious
	 *  
	 * if a non-zombie (security) wins a fight, the target falls unconscious
	 * else the non-zombie who initiated the fight becomes a zombie
	 * 
	 * The above process and successFactors usually result in either a gradual zombification of all humans or a gradual extermination of all zombies
	 */
 	reflex fight when: target != nil and contains(allHumans, target) and location distance_to(target.location) < 0.2
	{
		string fightString <- name + " fought " + target + " and ";
		// Zombies use zombieFightSuccessFactor
		if(isZombie)
		{
			// If zombie wins, target becomes zombie
			if(flip(zombieFightSuccessFactor))
			{
				ask Human(target)
				{
					do becomeZombie;
				}
				fightString <- fightString + "took a bite out of them!";
				hunger <- getNewHungerValue();
			}
			// If zombie loses, zombie passes out
			else
			{
				do perish;
				fightString <- fightString + "lost terribly.";
			}
		}
		// non-zombies use securityFightSuccessFactor
		else
		{
			// If security wins, target passes out
			if(flip(securityFightSuccessFactor))
			{
				// cast to human here because target could technically also be a building and those don't have the perish action
				ask Human(target)
				{
					do perish;
				}
				fightString <- fightString + "won!";
			}
			// If security loses, they become zombie
			else
			{
				do becomeZombie;
				fightString <- fightString + "got bitten!";
			}
		}
		target <- nil;
		write fightString;
	}

// Human actions
	
	 /*
	  * Returns a random float between 50-200
	  * Used for resetting hunger and thirst
	  */
	 float getNewHungerValue
	 {
	 	return rnd(150.0) + 50;
	 }
	
	/*
	 * When falling unconscious, most things are reset
	 */
	action perish
	{
		isConscious <- false;
		myColor <- unconsciousColor;
		target <- nil;
		targetOffset <- 0.0 :: 0.0;
	}
	
	/*
	 * When waking up, some things are reset again
	 * Also human waking up is removed from hospital's unconsciousHumans list
	 */
	 action getRevived
	 {
	 	myColor <- originalColor;
	 	hunger <- getNewHungerValue();
	 	isConscious <- true;
	 	target <- nil;
	 	
	 	if(isZombie)
	 	{
	 		do unBecomeZombie;
	 	}
	 }
	
	/*
	 * When a human gets zombified
	 * set isZombie to true, change color and increase hungerModifier
	 */
	action becomeZombie
	{
		isZombie <- true;
		if(isConscious)
		{
			myColor <- zombieColor;	
		}
		mySpeed <- guestSpeed;
		hungerModifier <- 2;
		hunger <- getNewHungerValue();
		target <- nil;
		zombies <+ self;
		wander <- true;
	}
	
	/*
	 * Reverse the above process of zombification
	 */
	 action unBecomeZombie
	 {
	 	isZombie <- false;
	 	myColor <- originalColor;
	 	mySpeed <- originalSpeed;
	 	hungerModifier <- 1;
	 	target <- nil;
	 	zombies >- self;
	 	wander <- wanderer;
	 }	
}

/* 
 * The guests are the oridinary guests to the festival. They participate in auctions, go to stages and to conferences.
 * 
 * Each guest has a random preferred price for merch
 * They will reject offers until their preferred price is reached,
 * upon which moment they accept and buy the merch
 */
species Guest skills:[fipa] parent: Human
{	
	float happiness <- 0.0;
	// This is the price at which the guest will buy merch, set in the configs above
	int guestMaxAcceptedPrice <- rnd(guestAcceptedPriceMin,guestAcceptedPriceMax);
	
	// List of remembered buildings
	list<Building> guestBrain;

	// Which auction is guest participating in
	Auctioner targetAuction;
	
	// Each guest prefers a random item out of the items they do not have
	//it is set in init
	string preferredItem <- [];
	// A list of all the items the guest does not have
	// The list becomes shorter as guests acquire items
	list<string> wishList <- ["branded backpacks","signed shirts","heavenly hats", "posh pants"];
	
	// Each guest as a set of weights for stages
	// These are used to calculate utility when deciding which stage to go to
	float preferenceStageLights <- rnd(stageParameterMin,stageParameterMax) * 0.01;
	float preferenceStageMusic <- rnd(stageParameterMin,stageParameterMax) * 0.01;
	float preferenceStageShow <- rnd(stageParameterMin,stageParameterMax) * 0.01;
	float preferenceStageFashionability <- rnd(stageParameterMin,stageParameterMax) * 0.01;
	float preferenceStageDanceability <- rnd(stageParameterMin,stageParameterMax) * 0.01;
	// the guest's preferred genre and how strongly they prefer it
	string preferenceStageGenre <- genresAvailable[rnd(length(genresAvailable) - 1)];
	float preferenceStageGenreBias <- 1.0 + rnd(0.0,10.0);
	// The max size of the crowd the guest is willing to tolerate
	// If crowd size exceeds crowdSize, multiply by bias
	int preferenceStageCrowdSize <- rnd(1,guestNumber);
	float preferenceStageCrowdSizeBias <- rnd(0.0,1.0);
	// Each guest keeps track of their utility for each stage
	map stageUtilityPairs;
	float highestUtility <- 0.0;
	Stage targetStage <- nil;
	
	//LongStayPlaceConfigs
	int cyclesLeftToStay <- -1;
	
	//Interaction configs
	string personality <- guestPersonalitiesEnum[rnd(length(guestPersonalitiesEnum) - 1)];
	bool isDisturbed <- false;
	
	aspect default
	{		
		draw sphere(2) at: location color: myColor;
		
		if(!contains(wishList, "branded backpacks"))
		{
			//point backPackLocation <- location + point([2.1, 0.0, 2.0]);
			//backPackLocation <- backPackLocation.x + 1; 
			draw cube(1.2) at: location + point([2.1, 0.0, 2.0]) color: #purple;
		}
		if(!contains(wishList, "heavenly hats"))
		{
			//point hatLocation <- location + point([0.0, 0.0, 3.5]);
			draw pyramid(1.2) at: location + point([0.0, 0.0, 3.5]) color: #orange;
		}
		if(!contains(wishList, "signed shirts"))
		{
			//point shirtLocation <- location + point([0.0, 0.0, 1.0]);
			draw cylinder(2.02, 1.5) at: location + point([0.0, 0.0, 1.0]) color: #lime;
		}
		if(!contains(wishList, "posh pants"))
		{
			//point shirtLocation <- location + point([0.0, 0.0, 0.0]);
			draw cylinder(2.01, 1.5) at: location color: #pink;
		}
	}
	
	init
	{
		happiness <- 100.0;
		hunger <- self getNewHungerValue[];
		
		if(globalHungerRate != -1)
		{
			hungerRate <- globalHungerRate;
		}
		
		if(length(itemsAvailable) > 0)
		{
			preferredItem <- itemsAvailable[rnd(length(itemsAvailable) - 1)];	
		}
		
		myColor <- guestColor;
		originalColor <- guestColor;
		
		// Guests have a zombieChance chance of being created as zombies (defined above)
		if(flip(zombieChance))
		{
			do becomeZombie;
		}
	}
		
	/*
	 * This might come up with stages, but not otherwise
	 * If target is dead, remove it from stageUtilityPairs and set target & targetStage to nil
	 */
	reflex isTargetAlive when: target != nil
	{
		if(dead(target))
		{
			target <- nil;
			stageUtilityPairs >- targetStage;
			targetStage <- nil;
		}
	}
	
	/*
	 * Guests will continuously evaluate their utilities for the stages as long as they exist
	 * If no stages exist, targetStage and stageUtilityPairs are emptied
	 */
	reflex calculateUtilities
	{	
		// As long as there are stages left, the guest will evaluate which one has the highest utility
		if (!empty(Stage.population))
		{
			loop stg over: Stage.population
			{
				// Calculate utility by taking the stage's vars and multiplying them by the corresponding preference
				float utility <- stg.stageLights * preferenceStageLights +
								stg.stageMusic * preferenceStageMusic +
								stg.stageShow * preferenceStageShow +
								stg.stageShow * preferenceStageFashionability +
								stg.stageShow * preferenceStageDanceability;
				
				// Zombies prefer techno music with a bias of 1000
				if(isZombie)
				{
					if(stg.stageGenre = "trashy techno" or
						stg.stageGenre = "traditional Russian song techno remixes" or
						stg.stageGenre = "Sandstorm")
					{
						utility <- utility * 1000;
					}
				}
				// If stage genre and guest's preference match, multily by bias (which is 1 + (0.0 to 0.9))				
				else if(stg.stageGenre = preferenceStageGenre)
				{
					utility <- utility * preferenceStageGenreBias;
				}
				// Modify utility based on crowd
				if(length(stg.crowdAtStage) > preferenceStageCrowdSize)
				{
					utility <- utility * preferenceStageCrowdSizeBias;
				}
				// Save the stage::utility pair
				stageUtilityPairs <+ stg::utility;	
			}
		}
		else if(!empty(stageUtilityPairs))
		{
			// If stages is empty, empty stageUtilityPairs and remove targetStage
			stageUtilityPairs <- [];
			targetStage <- nil;
		}
		
		// If targetStage is dead, we'll set that to nil
		if(dead(targetStage))
		{
			targetStage <- nil;
		}
		
		// Check which stage has the highest utility and pick that one
		// This is where the guest will also look at the population of a stage
		highestUtility <- 0.0; 
		loop stgUt over: stageUtilityPairs.pairs
		{
			if(float(stgUt.value) > highestUtility)
			{
				if(!dead(Stage(stgUt.key)))
				{
					highestUtility <- float(stgUt.value);
					// Remove self from current stage's crowd if we have one
					if(targetStage != nil)
					{
						targetStage.crowdAtStage >- self;	
					}
					// Assign new targetStage
					targetStage <- stgUt.key;
					// Add self to new stage's crowd
					targetStage.crowdAtStage <+ self;	
				}
				else
				{
					// If the stage is dead, let's get it off the list
					stageUtilityPairs >- stgUt.key;
				}
			}
		}
	}
	
	reflex lifeMakesMeSoSad
	{
		if(happiness >= 0.0)
		{
			happiness <- happiness - globalHappinessRate;
		}
	}
	
	/* 
	 * Once guest's hunger reaches below gettingHungry (30), they will head towards info/bar
	 */
	reflex alwaysThirstyAlwaysHungry when: targetAuction = nil and !isZombie
	{	
		if(target = nil and hunger < gettingHungry and isConscious)
		{	
			// Only use brain if the guest has locations saved in brain
			// 50% to either use brain or head to info center
			if(length(guestBrain) > 0 and flip(0.5))
			{
				target <- one_of(guestBrain);
			}

			// If no valid store was found in the brain or flip was false, head to info center
			if(target = nil)
			{
				target <- one_of(InfoCenter);	
			}
			
			//write name + " is hungry, heading to " + target;
		}
	}

	/* 
	 * If everything is ok with the guest, they will set their target stage as their target
	 */
	reflex gotoStage when: target = nil and isConscious
	{
		
		// This is probably redundant
		if(targetStage != nil and dead(targetStage))
		{
			targetStage <- nil;
		}
		if(targetStage != nil and location distance_to(targetStage) > approximateDetectionDistance)
		{
			target <- targetStage;
		}
	}
	
	/*
	 * Reached target exactly with 0 distance
	 * 
	 * When the agent reaches a building, it asks what does the store replenish
	 * Guests are foxy, opportunistic beasts and will attempt to refill their parameters at every destination
	 * Yes, guests will even try to eat at the info center
	 * Such ravenous guests
	 */
	reflex reachedTargetExactly when: target != nil and location distance_to(target.location) = 0
	{
		if(LongStayPlace.subspecies contains species(target))
		{
			do longStayPlaceReached;
		}
		if(target = one_of(InfoCenter))
		{
			do infoCenterReached;
		}
	}
	
	/*
	 * Reached the area around the target
	 */
	reflex checkForTargetReachedApproximately when: target != nil and location distance_to(target.location) <= approximateDetectionDistance
	{
		if(Stage = species(target))
		{
			do stageReached;
		}
	}
	
	/*
 * 	 * If the request initiator still exists (i.e. not dead), process their requests
	 * This ensures requests from already expired auctions aren't processed 
	 * Should not happen, but doesn't hurt to be safe
	 */
	reflex listenCFPSMessages when: (!empty(cfps))
	{
		message requestFromInitiator <- (cfps at 0);
		if(Auctioner.population contains requestFromInitiator.sender)
		{
			do processAuctionCFPSMessage(requestFromInitiator);
		}
	}
	
	/*
	 * If the request initiator still exists (i.e. not dead), process their requests
	 * This ensures requests from already expired conferences aren't processed 
	 */
	reflex listenInformMessages when: (!empty(informs))
	{
		message requestFromInitiator <- (informs at 0);
		if(Conference.population contains requestFromInitiator.sender)
		{
			do processConferenceInformMessage(requestFromInitiator);
		}
	}
	
	/*
	 * In Dutch auction, the auctioner proposes and the participant can accept or reject it, based on the price it would pay for it.
	 */
	reflex reply_messages when: (!empty(proposes))
	{
		message requestFromInitiator <- (proposes at 0);
		if(Auctioner.population contains requestFromInitiator.sender)
		{
			do processAuctionProposeMessage(requestFromInitiator);
		}
		else if(Conference.population contains requestFromInitiator.sender)
		{
			do processConferenceProposeMessage(requestFromInitiator);
		}
		
	}
	
	/*
	 * Guest is at a place where want to stay for a while
	 * The long condition ensures that it can be either at the circumference of the stay but also between the center and the circumference
	 * (before this, when the guest fell unconscious at that small area, much weird shit happened)
	 */
	reflex atLongStayPlace when: LongStayPlace.subspecies contains species(target) and 
		self distance_to target <= longStayPlaceRadius + floatError //float calculation error
	{
		if(species(target) = Bar)
		{
			do beingAtBar;
		}
		else if(species(target) = Conference)
		{
			do beingAtConference;
		}
		
		cyclesLeftToStay <- cyclesLeftToStay - 1;
		if(cyclesLeftToStay = 0)
		{
			do leaveLongStayPlace;
		}
	}
	
	/*
	 * if a guest's thirst or hunger <= 0, then the guest faints
	 * only conscious guests can faint
	 */
	reflex thenPerish when: (hunger <= 0) and isConscious and !isZombie
	{
		do perish;
	}
	
	//Guest actions begin
	
	/*
	 * If the guest's wish list does not contain their current preference,
	 * it means they've acquired that item
	 * and that they should pick a new preference from the remaining items
	 */
	action pickNewPreferredItem
	{
		if(!empty(wishList) and !contains(wishList, preferredItem))
		{
			preferredItem <- wishList[rnd(length(wishList) - 1)];
		}
	}
	
	/*
	 * Actions to call when the guest reaches the target where they want to stay for a while
	 * They will pick a random position around the place -> random point on the circumference around the target with a given radius
	 */
	action longStayPlaceReached
	{
		float angle <- rnd(360.0) * #pi * 2.0;
		float x <- cos(angle) * longStayPlaceRadius;
		float y <- sin(angle) * longStayPlaceRadius;
		targetOffset <- x :: y;
		cyclesLeftToStay <- rnd(minNumberOfCyclesAtPlace, maxNumberOfCyclesAtPlace);
		
		if(Bar = species(target))
		{
			do barReached;
		}
	}
	
	/*
	 * Guest arrives at bar. 
	 * Called when arrives
	 * Not sure if needed, I just created this to have it.
	 */
	action barReached
	{
		
	}
	
	/*
	 * Guest does this action at a bar
	 * They can talk, socialize etc
	 * Called with every cycle
	 */
	 
	action beingAtBar
	{
		if(hunger <= gettingHungry)
		{
			hunger <- self getNewHungerValue[];
			happiness <- happiness + 20;
		}
		
		//Implementation of a chill person meeting with a party person
		//If there are nemesis people around at the same place
		if(personality = "Chill" and length(self getNemesisesAtLongStayPlace[nemesisOf::personality, place::LongStayPlace(target)]) > 0)
		{
			//this is to only write it once per bar session
			if(!isDisturbed)
 			{
 				//if happiness is low, it disturbs the chill person, otherwise he is fine with it
 				if(happiness < feelingFineValue)
 				{
					write 'Chill person, ' + name + ': This freaking party person disturbs me in my sophisticated drinking habits! (at: ' + target + ')';
				}
				else
				{
					write "Chill person, " + name + ": This party person is a bit annoying but I feel to good to care about it! (at: " + target + ")";
				}
				isDisturbed <- true;
			}
		}
		//when there are no nemesis people around
		else
		{
			if(isDisturbed)
 			{
				write 'Chill person, ' + name + ': Finally, I got to enjoy my cuppa withour people talking about their morning crap!(at: ' + target + ")" ;

				isDisturbed <- false;
				happiness <- happiness + 10;
			}
		}
	}
	
	action beingAtConference
	{
		if(personality = "Scientist" or personality = "FlatEarther")
		{
			//if there are nemesis people around at the place
			 if(length(self getNemesisesAtLongStayPlace[nemesisOf::personality, place::LongStayPlace(target)]) > 0)
			 {
				//this is to only write it once per bar session
			 	if(!isDisturbed)
				{
				 	if(personality = "Scientist")
					{
						if(hunger < feelingFineValue or happiness < feelingFineValue)
						{
							write "Scientist person, " + name + ": This complete nitwit is wasting my time, I'd rather talk to some dead moths!(at: " + target + ")";
						}
						else
						{
							write "Scientist person, " + name + ": I'm in a good mood, I can talk about fake news and the donut-shaped-Earth theory!(at: " + target + ")";
						}
					}
					if(personality = "FlatEarther")
					{
						if(hunger < feelingFineValue or happiness < feelingFineValue)
						{
							write "FlatEarther dude, " + name + ": Another sheep fooled by the lies of the government and believes in the religion of numbers!(at: " + target + ")";
						}
						else
						{
							write "FlatEarther dude, " + name + ": I can pretend to have positive IQ, I'm in a good mood!(at: " + target + ")";
						}
					}
					isDisturbed <- true;
			 	}
			}
			else
			{
				if(isDisturbed)
				{
					if(personality = "Scientist")
					{
						write "Scientist: Finally, we can talk about science wihtout explaining elementary math!";
						happiness <- happiness + 10;
					}
					if(personality = "FlatEarther")
					{
						write "FlatEarther: Finally, we can have a discussion about real problems without the blind sheep!";
						happiness <- happiness + 10;
					}
					isDisturbed <- false;
				}
			}
		}
	}
	
	/*
	 * Returns a list of Guests containing the nemesis of a given type around a given longstayplace
	 * 
	 */
	 list<Guest> getNemesisesAtLongStayPlace(string nemesisOf, LongStayPlace place)
	 {
	 	string nemesis <- "";
		if(personality = "Chill")
		{
			nemesis <- "Party";
		}
		else if(personality = "Scientist")
		{
			nemesis <- "FlatEarther";
		}
		else if(personality = "FlatEarther")
		{
			nemesis <- "Scientist";
		}
		//guests in the same place with nemesis personality
		list<Guest> nemesises <- Guest.population where (each.personality = nemesis and each.target = place and each distance_to target <= longStayPlaceRadius + floatError);
		
		return nemesises;
	 }
	
	/*
	 * Reset variables when leaving longStayPlace
	 */
	action leaveLongStayPlace
	{
		targetOffset <- 0.0 :: 0.0;
		target <- nil;
		cyclesLeftToStay <- -1;
		
		isDisturbed <- false;
	}
	/* 
	 * Guest arrives to info center and pick a random bar to go to.
	 * If the bar is not already in brain, it will be added to brain so the guest can go there later too
	 */
	action infoCenterReached
	{
		target <- nil;
		target <- one_of(Bar);
		if(!(guestBrain contains target))
		{
			guestBrain <+ Building(target);
		}
	}
	
	action processAuctionCFPSMessage(message requestFromInitiator)
	{
		// the request's format is as follows: [String, auctionType, soldItem, ...]
		if(requestFromInitiator.contents[0] = 'Start' and requestFromInitiator.contents[1] = preferredItem)
		{
			// If the guest receives a message from an auction selling its preferredItem,
			// the guest participates in that auction
			targetAuction <- requestFromInitiator.sender;

			// Send a message to the auctioner telling them the guest will participate
			write name + " joins " + requestFromInitiator.sender + "'s auction for " + preferredItem;
			// Essentially add the guest to the interestedGuests list
			targetAuction.interestedGuests <+ self;
			do joinAuction;
		}
		//End of auction
		else if(requestFromInitiator.contents[0] = 'Stop')
		{
//			write name + ' knows the auction is over.';
			do postAuctionSettings;
		}
		//Time to send bid for sealed bidding
		else if(requestFromInitiator.contents[0] = 'Bid For Sealed')
		{
			do start_conversation (to: requestFromInitiator.sender, protocol: 'fipa-propose', performative: 'propose', contents: ['This is my offer', guestMaxAcceptedPrice]);
			do postAuctionSettings;
		}
		//next round for english bidding
		else if(requestFromInitiator.contents[0] = 'Bid for English')
		{
			int currentBid <- int(requestFromInitiator.contents[1]);
			//can bid more
			if (guestMaxAcceptedPrice > currentBid) 
			{
				int newBid <- currentBid + rnd(engAuctionRaiseMin, engAuctionRaiseMax);
				if(newBid > guestMaxAcceptedPrice)
				{
					newBid <- guestMaxAcceptedPrice;
				}
				//write name + ' sending propose ' + newBid;
				do start_conversation (to: requestFromInitiator.sender, protocol: 'fipa-propose', performative: 'propose', contents: ['This is my offer', newBid]);
			}
			//can't bid more
			else
			{
//				write name + ": Too much for me, I'm out guyzz";
				do reject_proposal (message: requestFromInitiator, contents: ["Too much for me, I'm out guyzz"]);
				do postAuctionSettings;
			}
		}
		else if(requestFromInitiator.contents[0] = 'Winner')
		{
			happiness <- happiness + 80;
			write name + ' won the auction for ' + preferredItem;
			wishList >- preferredItem;
			do pickNewPreferredItem;
			if(preferredItem = "posh pants")
			{
				write "Go Pants !!!";
			}
		}
	}
	
	/*
	 * When the guest has a targetAuction, it is considered participating in that auction
	 * Hunger and thirst are disabled for convenience's sake
	 * Unconscious guests will wake up, capitalism never sleeps
	 * 
	 * A target auction is an auction selling the types of items the guest is interested in
	 */
	action joinAuction
	{
		hunger <- getNewHungerValue();
		isConscious <- true;
		if(!isZombie)
		{
			myColor <- guestColor;	
		}
		else
		{
			myColor <- zombieColor;
		}
		
		// Free any ambulance from getting this guest
		ask Ambulance
		{
			if(targetHuman = myself)
			{
				targetHuman <- nil;
				deliveringGuest <- false;
			}
		}
		// Also remove this guest from the hospital's lists
		ask Hospital
		{
			unconsciousHumans >- myself;
			underTreatment >- myself;
		}
		
		if(location distance_to(targetAuction.location) > 9)
		{
			target <- targetAuction;
		}
		else
		{
			target <- nil;
		}
	
	}
	
	action processAuctionProposeMessage(message requestFromInitiator)
	{
		string auctionType <- requestFromInitiator.contents[1];
		if(auctionType = "Dutch")
		{
			int offer <- int(requestFromInitiator.contents[2]);
			if (guestMaxAcceptedPrice >= offer) {
				do accept_proposal with: (message: requestFromInitiator, contents: ["I, " + name + ", accept your offer of " + offer + ", merchant."]);
			}
			else
			{
				do reject_proposal (message: requestFromInitiator, contents: ["I, " + name + ", already have a house full of crap, you scoundrel!"]);	
				do postAuctionSettings;
			}
		}
	}
	/*
	 * This is a used when auctions end
	 */
	action postAuctionSettings
	{
		target <- nil;
		targetAuction <- nil;
	}
	
	action stageReached
	{
		happiness <- happiness + 1;
		target <- nil;
	}
	
	action processConferenceProposeMessage(message requestFromInitiator)
	{
		if(requestFromInitiator.contents[0] = 'interested?')
		{
			if(target = nil)
			{
				do accept_proposal(message: requestFromInitiator, contents: ["I'd love a great little chitchat"]);	
			}
			else
			{
				do reject_proposal(message: requestFromInitiator, contents: ['lel dude, im here to drink']);
			}
		}
	}
	
	action processConferenceInformMessage(message requestFromInitiator)
	{

		if(requestFromInitiator.contents[0] = 'conference start')
		{
			//everyone loves some intellectual talks, makes people happy
			happiness <- happiness + 20;
		}
		else if(requestFromInitiator.contents[0] = "you're in!")
		{
			target <- requestFromInitiator.sender;
		}
		
	}
	//Guest actions end
	
}// Guest end

// ################ Buildings start ################
/*
 * Parent Building
 * by default buildings do not sell food or drink
 * Unsurprisingly, food and drink stores do.
 * guests will test for this when reaching their target building,
 * guests are foxy beasts and will opportunistically fill whatever parameter they can
 */
species Building
{
	// Placeholder color
	rgb myColor <- #gray;
	aspect default
	{
		draw cube(5) at: location color: myColor;
	}
}

// Infocenter sits at the center of the area, guests sometimes visit it when hungry, but it has no functions
species InfoCenter parent: Building
{
	init
	{
		myColor <- infoCenterColor;
	}
	
}// InfoCenter end

/*
 * Collection of buildings where the guests are supposed to stay for a while
 */

species LongStayPlace parent: Building
{
	
}

/*this sells food and drinks and guests can sit in a bar
* This is used in the final project instead of Food and Drink store
*/
species Bar parent: LongStayPlace
{
	init
	{
		myColor <- barColor;
	}
}

/*
 * The hospital continuously checks all humans in case they are still conscious
 * If not, the unconscious human is added to the unconsciousHumans list
 * Whenever there are humans on the list and ambulances at the hospital,
 * the hospital will dispatch ambulances for the guests
 * 
 * The hospital also checks for any unconscious humans at the hospital and revives them.
 * When reviving a guest, deliveringGuest is set to false for the ambulance that delivered them
 */
species Hospital parent: Building
{	
	init
	{
		myColor <- ambulanceColor;
	}
	
	list<Human> unconsciousHumans <- [];
	list<Human> underTreatment <- [];
	
	reflex checkForUnconsciousGuest
	{
		ask allHumans
		{
			if(isConscious = false)
			{
				if(!(myself.unconsciousHumans contains self) and !(myself.underTreatment contains self))
				{
					myself.unconsciousHumans <+ self;
					//write name + "added to unconsciousHumans";
				}
			}
		}
	}
	
	/*
	 * Whenever there is an ambulance nearby (distance = 0) and it has no target,
	 * give it a target from unconsciousHumans
	 * 
	 * remove from unconsciousHumans, add to underTreatment
	 * this is so that the unconscious guest doesn't get re-added to the list,
	 * while the ambulance is on its way
	 */
	reflex dispatchAmbulance when: length(unconsciousHumans) > length(underTreatment)
	{
		ask Ambulance at_distance 0
		{
			if(targetHuman = nil and isConscious and !isZombie)
			{
				loop tg from: 0 to: length(myself.unconsciousHumans) - 1
				{
					if(myself.unconsciousHumans[tg].isConscious = false and !(myself.underTreatment contains myself.unconsciousHumans[tg]))
					{
						targetHuman <- myself.unconsciousHumans[tg];
						write name + " dispatched for " + myself.unconsciousHumans[tg].name; 
						myself.underTreatment <+ myself.unconsciousHumans[tg];
						break;
					}
				}
			}
		}
	}
	
	/*
	 * Whenever there is an unconscious human near (distance = 0) the hospital, revive them
	 * Also relieve hospitals near (distance = 0) the hospital, which have deliveringGuest = true, from their deliveringGuest status
	 * This frees the ambulances to be dispatched again
	 */
	reflex reviveHumansAtHospital when: length(underTreatment) > 0
	{
		ask allHumans at_distance 0
		{
			if(myself.underTreatment contains self)
			{
				do getRevived;	
				myself.underTreatment >- self;
				myself.unconsciousHumans >- self;
				write name + " revived at hospital";
			}
		}

		// When an ambulance has delivered a guest, set their targetHuman to nil
		ask Ambulance at_distance 0
		{
			if(deliveringGuest = true)
			{
				deliveringGuest <- false;
				targetHuman <- nil;
			}
		}
		
	}
}

/*
 * The ShowMaster creates auctioners and controls Stages, so that they will take turns
 * Also controls conferences
 */
species ShowMaster
{
	rgb myColor <- rnd_color(255);
	int mySize <- 10;
	list<Auctioner> auctioners <- [];
	bool auctionersInPosition <- false;
	
	
	list<Stage> stages <- [];

	
	//the last time when attractions happened
	int lastDayForAction <- -1;
	
	/*
	 * Attraction variables. one for each
	 */
	//the upcoming attraction is true
	bool auctionsNext <- true;
	bool stagesNext <- false;
	bool conferenceNext <- false;
	
	//is created variables
	bool auctionsCreated <- false;
	bool stagesCreated <- false;
	bool conferenceCreated <- false;
	
	//is running variables
	bool auctionsRunning <- false;
	bool stagesRunning <- false;
	bool conferenceRunning <- false;
	
	int nextAttractionStartTime <- rnd(auctionCreationMin, auctionCreationMax);
	
	aspect
	{
		draw pyramid(mySize) color: myColor;
	}
	
	/*
	 * For flashing and changing color
	 */
	reflex casinoLigths
	{
		myColor <- rnd_color(255);
		if(flip(0.5) and mySize < 15)
		{
			mySize <- mySize + 1;
		}
		else if(mySize >= 10)
		{
			mySize <- mySize - 1;
		}
	}
	
	reflex startNewDay when: lastDayForAction < currDay
	{
		auctionsNext <- true;
		stagesNext <- false;
		lastDayForAction <- lastDayForAction + 1;
		nextAttractionStartTime <- int(time + rnd(auctionCreationMin, auctionCreationMax));
	}
	
	/*
	 * Check for available attractions and start them if possible.
	 * The order here determines the order in the simulation
	 */
	reflex createAttractions when: nextAttractionStartTime = time
	{
		if(auctionsNext)
		{
			do createAuctions;
		}
		else if(stagesNext)
		{
			do createStages;
		}
		else if(conferenceNext)
		{
			do createConferences;
		}
	}
	
	/*
	 * Ask if auctioners are done running around
	 * Literally if an auctioneer has targetLocation = nil, it means they've reached their target and are ready to start auction 
	 */
	reflex startAuctions when: auctionsCreated and !auctionsRunning
	{
		bool stillOnTheWay <- false;
		loop auc over: auctioners
		{
			// If any of the auctioners hasn't reached its location yet, return and do nothing.
			if(auc.targetLocation != nil)
			{
				stillOnTheWay <- true;
			}
		}
		if(!stillOnTheWay)
		{
			auctionersInPosition <- true;
			write name + " notified auctioners are in position, starting auctions soon.";
			auctionsRunning <- true;	
		}
	}
	
	/*
	 * When auctioners return, they remove themselves from the auctioner list and do die
	 * When the list is empty and auctions are running, means all the auctioners have returned
	 * 
	 * Start shows and set auctionsCreated and runAuctions to false so they can be created again
	 */
	reflex areThereAnyAuctionersLeft when: empty(auctioners) and auctionsRunning
	{
		auctionsCreated <- false;
		auctionsRunning <- false;
		stagesNext <- true;
		do attractionEnded;
		write name + " knows the auctioners have served their purpose";
	}
	
	/*
	 * When stages' shows are finished, they remove themselves from the stages list and do die
	 * When the list is empty and shows are running, means all the stages have finished
	 * 
	 * set stagesCreated and runShows to false so they can be created again
	 */
	reflex areThereAnystagesLeft when: empty(stages) and stagesRunning
	{
		stagesCreated <- false;
		stagesRunning <- false;
		conferenceNext <- true;
		do attractionEnded;
		write name + " knows the stages have finished";
	}
	
	/*
	 * Showmaster tallies up total utility, it should grow over time 
	 */
	reflex calculateGlobalUtility when: !empty(stages)
	{
		// reset globalUtility, we'll recalculate it now anyway
	 	globalUtility <- 0.0;
	 	loop gst over: Guest.population
	 	{
	 		// We take the guest's current utility and trust they will reassign themselves another stage later
	 		loop staUti over: gst.stageUtilityPairs.pairs
	 		{
	 			if(staUti.key = gst.targetStage)
	 			{
	 				globalUtility <- globalUtility + float(staUti.value);
	 			}
	 		}
	 	}
	 	//write name + " has calculated global utility: " + globalUtility;
	}
	
	/*
	 * This is here just in case
	 * TODO: Either remove or add content
	 */
	reflex conferenceOver when: length(Conference.population) = 0
	{
		
	}
	
	/*
	 * ShowMaster actions
	 */
	action createAuctions
	{
		if(length(itemsAvailable) > 0)
		{
			string genesisString <- name + " creating auctions: ";
			
			loop i from: 0 to: length(itemsAvailable)-1
			{
				create Auctioner
				{
					location <- myself.location;
					soldItem <- itemsAvailable[i];
					genesisString <- genesisString + name + " with " + itemsAvailable[i] + " ";
					targetLocation <- {rnd(100),rnd(100)};
					myself.auctioners <+ self;
				}
			}
			write genesisString;
			
			auctionsCreated <- true;
			auctionsNext <- false;
		}
		
	}
	
	action createStages
	{
		if(length(stageColors) > 0)
		{
			string genesisString <- name + "creating stages: ";
	//		create Stage number: stageNumber
			int counter <- 0;
			create Stage number: length(stageColors)
			{
				myself.stages <+ self;
				myColor <- stageColors[counter];
				genesisString <- genesisString + name + " (" + myColor + ") with " + stageGenre + " ";
				myIndex <- counter;
				counter <- counter + 1;
			}
			write genesisString;
			
			stagesCreated <- true;
			stagesRunning <- true;
			stagesNext <- false;
			
		}
	}
	
	/*
	 * Creates conferences, fairly simple.
	 */
	action createConferences
	{
		string genesisString <- name + " creating conference: ";
		create Conference
		{
			
		}
		conferenceCreated <- true;
		conferenceNext <- false;
	}

	/*
	 * Puts an interval before the start of the next attraction (action, stage, conference) after one has ended
	 */	
	action attractionEnded
	{
		nextAttractionStartTime <- int(time + rnd(showMasterIntervalMin, showMasterIntervalMax));
	}
	
	//End of ShowMaster actions
}

/*
 * There are three types of auctions, Dutch, English and sealed, which are all implemented here
 * Auctioners will, when created, rush to their targetLocation (set randomly upon creation) and then start flashing and pumping according to reflex casinoLights
 * Once in position auctioners will send invitations to guests, using fipa.
 * There are four types of items available and the four auctioners will always have different items.
 * Guests accept invitiations for auctions of their preferred item.
 * If no guest joins an auctioner's auction, they will go back to the show master, otherwise they will wait for the guests to move to their location and start auction.
 * Auction runs according to its type (type is decided randomly upon creation) and once finished, the auctioner informs the winnder of the auction that they've won and all the participants that the auctions are over
 * Then the auctioner rushes back to the showMaster and do die;
 *
 * Guests winning pieces of clothing is not governed here, but rather in the guests themselves.
 */
species Auctioner skills:[fipa, moving] parent: Building
{
	// Auction's initial size and color, location used in the beginning
	int mySize <- 5;
	point targetLocation <- nil;
	
	// price of item to sell
	int auctionerDutchPrice <- rnd(auctionerDutchPriceMin, auctionerDutchPriceMax);
	int auctionerEngPrice <- rnd(auctionerEngPriceMin, auctionerEngPriceMax);
	// minimum price of item to sell. if max bid is lower than this, bid is unsuccessful
	int auctionerMinimumValue <- rnd(auctionerMinimumValueMin, auctionerMinimumValueMax);
	
	// vars related to start and end of auction
	bool auctionRunning <- false;
	bool startAnnounced <- false;
	
	string auctionType <- auctionTypes[rnd(length(auctionTypes) - 1)];
	int currentBid <- 0;
	string currentWinner <- nil;
	message winner <- nil;
	
	// This is for recording how long the auctioner has waited for guests to join interested guests
	float startTime;

	// The kind of an item the merchant is selling
	string soldItem <- "";
	// The guests participating in the auction
	list<Guest> interestedGuests;
	// if the auctioner has announced that it had no interested guests
	bool dieAnnounced <- false;

	aspect
	{
		draw pyramid(mySize) color: myColor;
	}
	
	/*
	 * For flashing and changing size
	 */
	reflex casinoLigths when: targetLocation = nil
	{
		myColor <- rnd_color(255);
		if(flip(0.5) and mySize < 11)
		{
			mySize <- mySize + 1;
		}
		else if(mySize >= 8)
		{
			mySize <- mySize - 1;
		}
	}
	
	/*
	 * For rushing to the field
	 */
	 reflex goToLocation when: targetLocation != nil
	 {
	 	if(location distance_to targetLocation <= 0.1)
	 	{
	 		// If this auctioner has already performed an auction
	 		if(auctionRunning or dieAnnounced)
	 		{
	 			write name + " has served its purpose";
	 			ask ShowMaster
	 			{
	 				auctioners >- myself;
	 			}
	 			do die;
	 		}
	 		write name + " has reached targetLocation";
	 		targetLocation <- nil;
	 	}
	 	else
	 	{
	 		do goto target: targetLocation speed: roboCopSpeed * 2;	
	 		myColor <- #gray;
	 		mySize <- 5;
	 	}
	 }
	 
	 /*
	  * When start has been announced, but there's no guests on the interestedGuests, go home
	  */
	  reflex guessIllDie when: startAnnounced and empty(interestedGuests) and time >= startTime + auctionerWaitTime and !auctionRunning and !dieAnnounced
	  {
	  	write name + " no guests were interested, guess I'll die";
	  	targetLocation <- showMasterLocation;
	  	dieAnnounced <- true;
	  }
	
	/*
	 * Send out the first auction message to all guest after a random amount of time
	 * Interested guests will answer and be added to interestedGuests
	 * The auction will start once the guests have gathered
	 * 
	 * startAnnounced is here to ensure we don't spam the announcement message
	 * 
	 * runAuctions is set to true / false by the showMaster
	 */
	reflex sendStartAuction when: !auctionRunning and one_of(ShowMaster).auctionsRunning and targetLocation = nil and !startAnnounced
	{
		write name + " starting " + auctionType + " soon";
		do start_conversation (to: list(Guest), protocol: 'fipa-propose', performative: 'cfp', contents: ['Start', soldItem]);
		startAnnounced <- true;
		startTime <- time;
	}
	
	/*
	 * sets auctionStarted to true when interestedGuests are within a distance of 13 to the auctioner.
	 */
	reflex guestsAreAround when: !auctionRunning and !empty(interestedGuests) and (interestedGuests max_of (location distance_to(each.location))) <= 13
	{
		write name + " guestsAreAround";
		auctionRunning <- true;
	}

	/*
	 * Dutch auction: auctioner sends a propose message and guests can reply with accept or reject messages. The auction ends with the first accept.
	 */
	reflex receiveAcceptMessages when: auctionRunning and !empty(accept_proposals) and !empty(interestedGuests)
	{
		if(auctionType = "Dutch")
		{
//			write name + ' receives accept messages';
			
			loop a over: accept_proposals {
				write name + ' got accepted by ' + a.sender + ': ' + a.contents;
				do start_conversation (to: a.sender, protocol: 'fipa-propose', performative: 'cfp', contents: ['Winner']);
			}
			targetLocation <- showMasterLocation;
//			auctionRunning <- false;
			//end of auction
			do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ['Stop']);
			interestedGuests <- [];
		}
	}

	/*
	 * In sealed and english auction, the participants send proposes to the auctioner. The auctioner gets them here.
	 * In Sealed, the highest bid wins right away.
	 * In English, this just sets the current highest bid and the auction goes on.
	 */ 
	reflex getProposes when: (!empty(proposes)) and !empty(interestedGuests)
	{
		if(auctionType = "Sealed")
		{
			targetLocation <- showMasterLocation;

			loop p over: proposes {
//				write name + ' got an offer from ' + p.sender + ' of ' + p.contents[1] + ' pesos.';
				if(currentBid < int(p.contents[1]))
				{
					currentBid <- int(p.contents[1]);
					currentWinner <- p.sender;
					winner <- p;
				}
			}
			do start_conversation (to: winner.sender, protocol: 'fipa-propose', performative: 'cfp', contents: ['Winner']);
//			write name + ' bid ended. Sold to ' + currentWinner + ' for: ' + currentBid;
			do accept_proposal with: (message: winner, contents: ['Item is yours']);
			do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ["Stop"]);
			interestedGuests <- [];
		}
		else if(auctionType = "English")
		{
			loop p over: proposes {
//				write name + ' got an offer from ' + p.sender + ' of ' + p.contents[1] + ' pesos.';
				if(currentBid < int(p.contents[1]))
				{
					currentBid <- int(p.contents[1]);
					currentWinner <- p.sender;
					winner <- p;
				}
			}
		}
	}
	/*
	 * Reject messages are used in Dutch and English auctions.
	 * Dutch: Starting from high bid and goes on as long as everybody rejects the proposal. Here, we decrese the price of the item.
	 * If the price goes below the minimum expected price, the auction ends.
	 * English: Reject messages mean that participants don't wish to bid more and are out of the auction.
	 * If everyone is out or just one person left, the auction ends.
	 */
	reflex receiveRejectMessages when: auctionRunning and !empty(reject_proposals) and !empty(interestedGuests)
	{
		if(auctionType = "Dutch")
		{
//			write name + ' receives reject messages';
			
			auctionerDutchPrice <- auctionerDutchPrice - rnd(dutchAuctionDecreaseMin, dutchAuctionDecreaseMax);
			if(auctionerDutchPrice < auctionerMinimumValue)
			{
				targetLocation <- showMasterLocation;
//				auctionRunning <- false;

				write name + ' price went below minimum value (' + auctionerMinimumValue + '). No more auction for thrifty guests!';
				do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ['Stop']);
				interestedGuests <- [];
			}
		}
		else if(auctionType = "English")
		{	
			loop r over: reject_proposals 
			{
				interestedGuests >- r.sender;
			}
			if(length(interestedGuests) < 2)
			{
				targetLocation <- showMasterLocation;
//				auctionRunning <- false;

				if(currentBid < auctionerMinimumValue)
				{
					write name + ' bid ended. No more auctions for poor people!';
				}
				else
				{
					write 'Bid ended. Winner is: ' + currentWinner + ' with a bid of ' + currentBid;	
					do start_conversation (to: winner.sender, protocol: 'fipa-propose', performative: 'cfp', contents: ['Winner']);
				}
				if(!empty(interestedGuests))
				{
					do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ["Stop"]);
				}
				interestedGuests <- [];
			}
		}
	}
	/*
	 * Dutch: every iteration, it sends the decreased price of the item to the participants which they can accept of reject
	 * English: every iteration, tells guests about the current highest bid that they need to outbid
	 * Sealed: Start of the auction which is only one iteration
	 */
	reflex sendAuctionInfo when: auctionRunning and !empty(interestedGuests){
		if(auctionType = "Dutch")
		{
//			write name + ' sends the offer of ' + auctionerDutchPrice +' pesos to participants';
			do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'propose', contents: ['Buy my merch, peasant', auctionType, auctionerDutchPrice]);
		}
		else if(auctionType = "English")
		{
//			write 'Auctioner ' + name + ': current bid is: ' + currentBid + '. Offer more or miss your chance!';
			do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ["Bid for English", currentBid]);
		}
		else if(auctionType = "Sealed")
		{
//			write name + ' time to offer your money!!';
			do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ['Bid For Sealed']);
		}
	}	
}// Auctioner

/*
 * Stages are mostly passive, just playing their concerts for a random time
 */
species Stage parent: Building
{
	float mySize <- 5.0;
	
	bool showExpired <- false;
	float startTime <- time;
	// The duration how long the show will run after starting
	int duration <- rnd(durationMin, durationMax);
	
	// Each guest as a set of preferences for stages
	// These are used to calculate utility when deciding which stage to go to
	int stageLights <- rnd(stageParameterMin,stageParameterMax);
	int stageMusic <- rnd(stageParameterMin,stageParameterMax);
	int stageShow <- rnd(stageParameterMin,stageParameterMax);
	int stageFashionability <- rnd(stageParameterMin,stageParameterMax);
	int stageDanceability <- rnd(stageParameterMin,stageParameterMax);
	string stageGenre <- genresAvailable[rnd(length(genresAvailable) - 1)];
	
	// Stages keep a record of their crowd sizes
	list<Guest> crowdAtStage <-[];
	// Total utility of all guests at stage
//	float totalUtility <- 0.0;
	int myIndex;
	
	aspect default
	{
		draw cylinder(mySize, 0.1) color: myColor at: location;
	}
	
	/*
	 * When the time is greater than the start time + duration, the show has run for long enough and will end
	 */
	reflex showMustNotGoOn when: time >= startTime + duration
	{
		write name + "'s " + stageGenre + " show has finished";
		ask ShowMaster
		{
			stages >- myself;
		}
		do die;
	}	
	
}

/*
 * Conferences will invite guests over and accept until maxParticipants is reached
 */
species Conference skills: [fipa] parent: LongStayPlace
{
	int maxParticipants <- 6;
	
	//number of guests who replied
	int replyCounter <- 0;
	
	list<Guest> participants <- [];
	
	init
	{
		write 'Conference announces it starts soon';
		do start_conversation (to: list(Guest), protocol: 'fipa-propose', performative: 'propose', contents: ["interested?"]);
	}
	
	/*
	 * Guests are accepted to the conference as long as there is space in the conference 
	 */
	reflex receive_accept_messages when: !empty(accept_proposals) 
	{
		replyCounter <- replyCounter + length(accept_proposals);
		loop a over: accept_proposals
		{
			if(maxParticipants > length(participants))
			{
				participants <+ a.sender;
				write "" + a.sender + " joins the scientific conference!";
				do start_conversation (to: participants, protocol: 'no-protocol', performative: 'inform', contents: ["you're in!"]);
			}
		}
	}
	
	//nobody cares about simple-minded individuals
	reflex receive_reject_messages when: !empty(reject_proposals)
	{
		replyCounter <- replyCounter + length(reject_proposals);
	}
	
	/*
	 * start the conference once guests have arrived and informs ShowMaster
	 */
	reflex startConference when: (length(participants) = maxParticipants or replyCounter = length(Guest.population))
	{	
		if(!one_of(ShowMaster).conferenceRunning)
		{
			if(length(participants) > 0 and participants max_of (location distance_to(each.location)) <= longStayPlaceRadius + floatError)
			{
				ask ShowMaster
				{
					conferenceRunning <- true;
				}
				do start_conversation (to: participants, protocol: 'no-protocol', performative: 'inform', contents: ["conference start"]);
			}
			
		}
	}
	
	/*
	 * Checks once guests have left the conference and do die;
	 */
	reflex guestsHaveLeft when: one_of(ShowMaster).conferenceRunning and participants min_of (location distance_to(each.location)) > longStayPlaceRadius + floatError
	{
		write name + " conference ended, guess I'll die";
		do die;
	}
	
	aspect default
	{
		draw cylinder(3.5, 0.1) color: #black at: location;
	}
}

// ################ Buildings end ################
// ################ Non-building agents start ################

/*
 * Ambulances reside in the hospital and will return there they have nothing else to do.
 * When a human falls unconscious, the hospital will give one of the ambulances present at the hospital a targetHuman
 * and the ambulance will go to targetHuman.location and ask the targetHuman to go to the hospital
 * and the ambulance will follow along at guestSpeed to create a dragging effect where the agents move together
 */
species Ambulance skills:[moving] parent: Human
{
	init
	{
		myColor <- ambulanceColor;
		originalColor <- ambulanceColor;
		mySpeed <- roboCopSpeed;
		originalSpeed <- roboCopSpeed;
		wanderer <- false;
		wander <- false;
	}

	Human targetHuman <- nil;
	Building hospital <- one_of(Hospital);
	bool deliveringGuest <- false;

	// Causes ambulance to go to the hospital when no target is set
	reflex idleAtHospital when: targetHuman = nil and isConscious and !isZombie
	{
		mySpeed <- roboCopSpeed;
		do goto target: hospital.location speed: mySpeed;
	}

	reflex gotoFaintedGuest when: targetHuman != nil and isConscious and !isZombie
	{
		mySpeed <- roboCopSpeed;
		do goto target: targetHuman.location speed: mySpeed;
	}
	
	reflex collectFaintedGuest when: targetHuman != nil and isConscious and !isZombie
	{
		deliveringGuest <- true;
		if(location distance_to(targetHuman.location) < 1)
		{	
			// Set's the guest's target to hospital
			// (even unconscious guests can move)
			deliveringGuest <- true;
			ask targetHuman
			{
				target <- myself.hospital;
			}
			mySpeed <- guestSpeed;
			do goto target:(hospital.location) speed: mySpeed;
		}
	}	
}// Ambulance end

/*
 * Security fights zombies and as long as auctions are not running (just to not mess up the auctions),
 * security will pick itself a target from the zombies list and chase them down and fight them.
 * Fighting is implemented under the Human species.
 */
species Security skills:[moving] parent: Human
{
	init
	{
		myColor <- securityColor;
		originalColor <- securityColor;
		mySpeed <- guestSpeed;
		originalSpeed <- guestSpeed;
	}

	/*
	 * As long as security has humans on their list, they will go through them one by one and fight them
	 * fighting zombies stops for the time of auctions
	 */
	reflex fightZombies when: length(zombies) > 0 and isConscious and !isZombie
	{
		ask one_of(ShowMaster)
		{
			if(auctionsRunning)
			{
				myself.auctionsRunning <- true;
			}
			else
			{
				myself.auctionsRunning <- false;
			}
		}
		
		// Only fight zombies while auctions aren't running
		// This is a long standing tradition of letting business go on about its business
		if(!auctionsRunning)
		{
			// No need to beat a dead horse, or an unconscious zombie
			if(target != nil and Human(target) != nil)
			{
				if(!Human(target).isConscious)
				{
					target <- nil;
				}
			}
			if(target = nil)
			{
				target <- one_of(zombies);
				if(!Human(target).isConscious)
				{
					target <- nil;
				}	
			}
		}
		else
		{
			target <- nil;
		}
	}
}//Security end

// ################ Non-building agents end ################

experiment main type: gui
{
	
	output
	{
		display map type: opengl
		{
			species Guest;
			species InfoCenter;
			species Bar;
			
			species Security;
			species Hospital;
			species Ambulance;
			species ShowMaster;
			species Auctioner;
			species Stage;
			species Conference;
		}
	}
}

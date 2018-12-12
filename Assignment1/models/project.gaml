/**
* Name: Assignment 2
* Author: Finta, Vartiainen
* Description: Festival scene with hungry guests, bad guests and a security guard
* 
* TODO:
	debug conferences (Gábor)
	debug stages (Ville)
	add new type of guest (Ville)
	 	parent for all non-building species (Ville)
		also how do agents interact with each other? (3 attributes)
	measure some global value (chaos or amount of population zombified) (Ville)
	
*/

model NewModel
global 
{
	/*
	 * Guest configs
	 */
	//int guestNumber <- rnd(20)+20;
	int guestNumber <- 15;
	float guestSpeed <- 0.5;
	
	// the rate at which guests grow hungry / thirsty
	// every reflex we reduce hunger / thirst by rnd(0,rate) * 0.1
	//now if this is -1, guests will use their personal random hunger rate
	// if it is not -1, they use this instead as a global hungerrate
	int globalHungerRate <- -1;
	//they will start looking for food under this value
	int gettingHungry <- 30;
	
	/*
	 * Building configs
	 */
	int foodStoreNumber <- 0;// rnd(2,3);
	int drinkStoreNumber <- 0;// rnd(2,3);
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
	
	//Everything happens only once per day
	int currDay <- 0;
	int cyclesPerDay <- 3000;
	
	//LongStayPlace configs
	float longStayPlaceRadius <- 4.0;
	int maxNumberOfCyclesAtPlace <- 200;
	int minNumberOfCyclesAtPlace <- 100;
	
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
		 * Number of stores is defined above 
		 */
		create FoodStore number: foodStoreNumber
		{

		}
		
		/*
		 * Number of stores is defined above 
		 */
		create DrinkStore number: drinkStoreNumber
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
		create Security number: 1
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
	}
	reflex currDay when: time != 0 and mod(time, cyclesPerDay) = 0
	{
		currDay <- currDay + 1;
	}
	
}


/*
 * Max value for both thirst and hunger is 100
 * Guests enter with a random value for both between 50 and 100
 * 
 * Each guest gets an id number, which is simply a random number between 1000 and 10 000,
 * technically two guests could have the same id, but given the small number of guests that's unlikely
 * 
 * Guests will wander about until they get either thirsty or hungry, at which point they will start heading towards the info center
 * 
 * Each guest has a random preferred price for merch
 * They will reject offers until their preferred price is reached,
 * upon which moment they accept and buy the merch
 * 
 * Guests have a 5% chance of being created as zombies (previously isBad)
 * zombies can infect nearby guests
 * zombies have a high utility for larger crowds
 * zombies ignore the utility for music, except for techno music
 */
species Guest skills:[moving, fipa]
{
	// Default hunger vars
	float thirst <- 0.0;
	float hunger <- 0.0;
	int hungerRate <- rnd(1, 3);
	bool isConscious <- true;
	
	// Default color of guests
	rgb color <- #red;
	
	// This is the price at which the guest will buy merch, set in the configs above
	int guestMaxAcceptedPrice <- rnd(guestAcceptedPriceMin,guestAcceptedPriceMax);
	
	// List of remembered buildings
	list<Building> guestBrain;
	// Target to move towards
	Building target <- nil;
	//x and y offset of the target
	pair<float, float> targetOffset <- 0.0 :: 0.0;

	// Which auction is guest participating in
	Auctioner targetAuction;
	
	/* Bad apples are colored differently */
	// Some guests are bad apples and are colored differently
	// They will be removed by the security
	bool isBad <- flip(0.2);
	
	// Each guest prefers a random item out of the items they do not have
	//it is set in init
	string preferredItem <- [];
	// A list of all the items the guest does not have
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
	list<float> stageUtilities <- [];
	ShowMaster showMaster <- one_of(ShowMaster);
	Stage targetStage <- nil;
	float highestUtility <- 0.0;
	float currentUtility <- 0.0;
	int highestUtilityIndex;
	bool unsatisfied <- false;
	
	//LongStayPlaceConfigs
	int cyclesLeftToStay <- 0;
	
	aspect default
	{
		if(isBad) {
			color <- #darkred;
		}
		draw sphere(2) at: location color: color;

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
		hunger <- self getNewHungerOrThirstValue[];
		thirst <- self getNewHungerOrThirstValue[];
		
		if(globalHungerRate != -1)
		{
			hungerRate <- globalHungerRate;
		}
		
		if(length(itemsAvailable) > 0)
		{
			preferredItem <- itemsAvailable[rnd(length(itemsAvailable) - 1)];	
		}
	}
		
	/*
	 * This might come up with stages, but not otherwise
	 */
	reflex isTargetAlive when: target != nil
	{
		if(dead(target))
		{
			target <- nil;
			targetStage <- nil;
		}
	}
	
	/*
	 * Guests will continuously evaluate their utilities for the stages
	 * 
	 * Stages have the following attributes:
	 * int stageLights
	 * int stageMusic
	 * int stageShow
	 * int stageFashionability
	 * int stageDanceability
	 * string stageGenre
	 * list<Guest> crowdAtStage
	 * 
	 * Guests have the following attributes:
	 * float preferenceStageLights
	 * float preferenceStageMusic
	 * float preferenceStageShow
	 * float preferenceStageFashionability
	 * float preferenceStageDanceability
	 * 
	 * the guest's preferred genre and how strongly they prefer it
	 * string preferenceStageGenre
	 * float preferenceStageGenreBias
	 * 
	 * The max size of the crowd the guest is willing to tolerate and how strongly they prefer this
	 * int preferenceStageCrowdSize
	 */
	reflex calculateUtilities
	{
		/*
		 * The ShowMaster has a list of the stages
		 * Go through the list and calculate and save utility for each stage, then pick the highest
		 * 
		 * only calculate the general utility once for each stage, crowd utility is calculated every cycle
		 * 
		 * Edit: keep calculating the utility
		 */
		 ask showMaster
		 {
		 	// If stages is empty, do nothing and remove utilities from guest
		 	if(!empty(stages))
		 	{
			 	loop i from: 0 to: length(stages)-1
			 	{
			 		Stage stg <- stages[i];
//			 		if(length(myself.stageUtilities) < length(stages))
//			 		{
			 			// Calculate utility by taking the stage's vars and multiplying them by the corresponding preference
						float utility <- stg.stageLights * myself.preferenceStageLights +
										stg.stageMusic * myself.preferenceStageMusic +
										stg.stageShow * myself.preferenceStageShow +
										stg.stageShow * myself.preferenceStageFashionability +
										stg.stageShow * myself.preferenceStageDanceability;
										
//			 			string preferenceString <- myself.name + " has calculated utility for " + stg.name + ": ";
						
						// if the stage's genre does not match the Guest's preference, multiply by bias
						if(stg.stageGenre = myself.preferenceStageGenre)
						{
							utility <- utility * myself.preferenceStageGenreBias;
//							preferenceString <- preferenceString + " (preferred genre) ";
						}
						// Add stage / utility pair to stageUtilities
						// Couldn't get pairs working, so we'll just keep utilities in a list of floats
						myself.stageUtilities <+ utility;
//						write preferenceString + myself.stageUtilities[i];
//			 		}
			 	}
		 	}
		 	// If stages is empty, remove utilities from guest
		 	else
		 	{
		 		myself.stageUtilities <- [];
		 	}

		 }
	}
	
	/*
	 * Guests will pick a stage when shows are running and when they have calculated utilities
	 */
	 reflex pickStage when: !empty(stageUtilities) and !empty(showMaster.stages) and length(stageUtilities) = length(showMaster.stages) and targetStage = nil
	 {
	 	loop i from: 0 to: length(stageUtilities) - 1
	 	{
	 		if(stageUtilities[i] >= highestUtility)
	 		{
	 			highestUtility <- stageUtilities[i];
	 			targetStage <- showMaster.stages[i];
	 			targetStage.crowdAtStage <+ self;
	 			currentUtility <- highestUtility;
	 		}
	 		//write name + " has picked targetStage " + targetStage + " (" + targetStage.myColor + ") " + targetStage.location;
	 	}
	 }
	
	/* 
	 * Reduce thirst and hunger with a random value between 0 and 0.5
	 * Once agent's thirst or hunger reaches below 50, they will head towards info/Store
	 */
	reflex alwaysThirstyAlwaysHungry when: targetAuction = nil
	{
		/* Reduce thirst and hunger */
		thirst <- thirst - rnd(hungerRate)*0.1;
		hunger <- hunger - rnd(hungerRate)*0.1;
		
		/* 
		 * If agent has no target and either thirst or hunger is less than 50
		 * then either head to info center, or directly to store
		 * 
		 * Once agent visits info center,
		 * the store they're given will be added to guestBrain,
		 * which is a list of stores.
		 * 
		 * The next time the agent is thirsty / hungry,
		 * agent then has 50% chance of either drawing an appropriate store from memory,
		 * or heading to info center as usual.
		 * 
		 * Only conscious agents will react to their thirst/hunger 
		 */
		if(target = nil and (thirst < gettingHungry or hunger < gettingHungry) and isConscious)
		{	
			string destinationMessage <- name; 

			/*
			 * Is agent thirsty, hungry or both.
			 * Guests will prefer drink over food
			 */
			if(thirst < gettingHungry and hunger < gettingHungry)
			{
				destinationMessage <- destinationMessage + " is thirsty and hungry,";
			}
			else if(thirst < gettingHungry)
			{
				destinationMessage <- destinationMessage + " is thirsty,";
			}
			else if(hunger < gettingHungry)
			{
				destinationMessage <- destinationMessage + " is hungry,";
			}
			
			// Guest has 50% chance of using brain or asking from infocenter
			bool useBrain <- flip(0.5);
			
			// Only use brain if the guest has locations saved in brain
			if(length(guestBrain) > 0 and useBrain = true)
			{
				target <- one_of(guestBrain);
				destinationMessage <- destinationMessage + " (brain used)";
			}

			// If no valid store was found in the brain, head to info center
			if(target = nil)
			{
				target <- one_of(InfoCenter);	
			}
			
			destinationMessage <- destinationMessage + " heading to " + target.name;
			//write destinationMessage;
		}
	}

	/* 
	 * If everything is ok with the guest, they will set their target stage as their target
	 * if they have nothing else to do, guests will wander
	 */
	reflex gotoStageOrBeIdle when: target = nil and isConscious
	{
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
	 * When agent has target, move towards target
	 * note: unconscious guests can still move, just to enable them moving to the hospital
	 */
	reflex moveToTarget when: target != nil
	{
		do goto target:{target.location.x + targetOffset.key, target.location.y + targetOffset.value} speed: guestSpeed;
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
		if(Store.subspecies contains species(target))
		{
			do foodDrinkStoreReached;
		}
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
	 * TODO: Document
	 */
	reflex listenCFPSMessages when: (!empty(cfps))
	{
		message requestFromInitiator <- (cfps at 0);
		if(Auctioner.population contains requestFromInitiator.sender)
		{
			do processAuctionCFPSMessage(requestFromInitiator);
		}
	}
	
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
	
	reflex wanderRandomly when: target = nil and isConscious
	{
		do wander;
	}
	
	/*
	 * Guest is at a place where want to stay for a while
	 * The long condition ensures that it can be either at the circumference of the stay but also between the center and the circumference
	 * (before this, when the guest fell unconscious at that small area, much weird shit happened)
	 */
	reflex atLongStayPlace when: LongStayPlace.subspecies contains species(target) and 
		location distance_to({target.location.x + targetOffset.key, target.location.y + targetOffset.value}) <= target.location distance_to({target.location.x + targetOffset.key, target.location.y + targetOffset.value})
	{
		if(species(target) = Bar)
		{
			do beingAtBar;
		}
		
		cyclesLeftToStay <- cyclesLeftToStay - 1;
		if(cyclesLeftToStay <= 0)
		{
			targetOffset <- 0.0 :: 0.0;
			target <- nil;
		}
	}
	
	/*
	 * if a guest's thirst or hunger <= 0, then the guest faints
	 * only conscious guests can faint
	 */
	reflex thenPerish when: (thirst <= 0 or hunger <= 0) and isConscious
	{
		string perishMessage <- name + " fainted";
		
		if(thirst <= 0)
		{
			perishMessage <- perishMessage + " of thirst.";
		}
		else if(hunger <= 0)
		{
			perishMessage <- perishMessage + " of hunger.";
		}
		
		//write perishMessage;
		isConscious <- false;
		color <- #yellow;
		target <- nil;
		targetOffset <- 0.0 :: 0.0;
		
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
	
	action foodDrinkStoreReached
	{
		string replenishString <- name;	
		if(FoodStore = species(target))
		{
			hunger <- self getNewHungerOrThirstValue[];
			replenishString <- replenishString + " ate food at " + target.name;
		}
		else if(DrinkStore = species(target))
		{
			thirst <- self getNewHungerOrThirstValue[];
			replenishString <- replenishString + " had a drink at " + target.name;
		}
		
		//write replenishString;
		target <- nil;
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
			hunger <- self getNewHungerOrThirstValue[];
		}
		if(thirst <= gettingHungry)
		{
			thirst <- self getNewHungerOrThirstValue[];
		}
		
	}
	 
	 float getNewHungerOrThirstValue
	 {
	 	return rnd(150.0) + 50;
	 }
	
	/* 
	 * Guest arrives to info center
	 * It is assumed the guests will only head to the info center when either thirsty or hungry
	 * 
	 * The guests will prioritize the attribute that is lower for them,
	 * if tied then thirst goes first.
	 * This might be different than the reason they decided to head to the info center originally.
	 * 
	 * If the guest's brain has space, it will add the store's information to its brain
	 * This could be the same store it already knows, but the guests are not very smart
	 */
	action infoCenterReached
	{
		string destinationString <- name  + " on its way for "; 
		target <- nil;
		ask InfoCenter at_distance 0
		{
			myself.target <- one_of(Bar);
			if(!(myself.guestBrain contains myself.target))
			{
				myself.guestBrain <+ myself.target;
				destinationString <- destinationString + "(added to brain) ";
			}
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
		hunger <- 100.0;
		thirst <- 100.0;
		isConscious <- true;
		color <- #red;
		
		// Free any ambulance from getting this guest
		ask Ambulance
		{
			if(targetGuest = myself)
			{
				targetGuest <- nil;
				deliveringGuest <- false;
			}
		}
		// Also remove this guest from the hospital's lists
		ask Hospital
		{
			unconsciousGuests >- myself;
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
	
}

/* InfoCenter serves info with the ask function */
species InfoCenter parent: Building
{
	// Get every store within 1000, should be enough	
	list<FoodStore> foodStoreLocs <- (FoodStore at_distance 1000);
	list<DrinkStore> drinkStoreLocs <- (DrinkStore at_distance 1000);
	
	// We only want to querry locations once
	bool hasLocations <- false;
	
	aspect default
	{
		draw cube(5) at: location color: #blue;
	}

	/*
	 * TODO: document
	 */
	reflex checkForBadGuest
	{
		ask Guest at_distance 0
		{
			if(self.isBad)
			{
				Guest badGuest <- self;
				ask Security
				{
					if(!(self.targets contains badGuest))
					{
						self.targets <+ badGuest;	
					}
				}
				//write name + " to Robocop's list";
			}
		}
	}
}// InfoCenter end

species Store parent: Building
{
	
}

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
	aspect default
	{
		draw pyramid(5) at: location color: #purple;
	}
}

/* 
 * These stores replenish guests' hunger. The info center keeps a list of food stores.
 */
species FoodStore parent: Store
{
	bool sellsFood <- true;
	
	aspect default
	{
		draw pyramid(5) at: location color: #green;
	}
}

/* 
 * These stores replenish guests' thirst. The info center keeps a list of drink stores.
 */
species DrinkStore parent: Store
{
	bool sellsDrink <- true;
	
	aspect default
	{
		draw pyramid(5) at: location color: #gold;
	}
}

/*
 * TODO: document
 */
species Hospital parent: Building
{	
	aspect default
	{
		draw cube(5) at: location color: #teal;
	}
	
	list<Guest> unconsciousGuests <- [];
	list<Guest> underTreatment <- [];
	
	reflex checkForUnconsciousGuest
	{
		ask Guest
		{
			if(isConscious = false)
			{
				if(!(myself.unconsciousGuests contains self) and !(myself.underTreatment contains self))
				{
					myself.unconsciousGuests <+ self;
					//write name + "added to unconsciousGuests";
				}
			}
		}
	}
	
	/*
	 * Whenever there is an ambulance nearby and it has no target,
	 * give it a target from unconsciousGuests
	 * 
	 * remove from unconsciousGuests, add to underTreatment
	 * this is so that the unconscious guest doesn't get re-added to the list,
	 * while the ambulance is on its way
	 */
	reflex dispatchAmbulance when: length(unconsciousGuests) > length(underTreatment)
	{
		ask Ambulance at_distance 0
		{
			if(targetGuest = nil)
			{
				loop tg from: 0 to: length(myself.unconsciousGuests) - 1
				{
					if(myself.unconsciousGuests[tg].isConscious = false and !(myself.underTreatment contains myself.unconsciousGuests[tg]))
					{
						targetGuest <- myself.unconsciousGuests[tg];
						write name + " dispatched for " + myself.unconsciousGuests[tg].name; 
						myself.underTreatment <+ myself.unconsciousGuests[tg];
						break;
					}
				}
			}
		}
	}
	
	/*
	 * TODO: document
	 */
	reflex reviveGuest when: length(underTreatment) > 0
	{
		ask Guest at_distance 0
		{
			if(myself.underTreatment contains self)
			{
				if(isBad)
				{
					color <- #darkred;	
				}
				else
				{
					color <- #red;	
				}
				hunger <- 100.0;
				thirst <- 100.0;
				isConscious <- true;
				target <- nil;
				
				myself.underTreatment >- self;
				myself.unconsciousGuests >- self;
				//write name + " removed from underTreatment";
			}
		}

		ask Ambulance at_distance 0
		{
			if(deliveringGuest = true)
			{
				deliveringGuest <- false;
				targetGuest <- nil;
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
	 * TODO: document auctioneers returning and being sent out again
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
		
		// reset unsatisfied for all guests
		ask Guest
		{
			unsatisfied <- false;
		}
	}
	
	/*
	 * The ShowMaster will coordinate guests around to the stages 
	 */
	 reflex coordinateGuests when: stagesRunning// and length(stageColors) = length(stages)
	 {
	 	// reset globalUtility, we'll recalculate it now anyway
	 	globalUtility <- 0.0;
	 	// Ask guests that have picked a targetStage (means they have calculated utility)
	 	// if the crowd at the stage exceeds crowdSize
		//if yes, are there stages where the crowd is smaller than maxCrowd?
		//if yes, does changing increase global utility?s
		//if yes, assign new stage
		//ask Guest
		loop guest over: Guest
		{
			if(guest.targetStage != nil)
			{
				// if the show has expired
				// TODO: this seems to cause bugs in the long run - maybe make all shows expire at the same time?
				if(dead(guest.targetStage))
				{
					guest.targetStage <- nil;
					guest.target <- nil;
				}
				else if(length(guest.targetStage.crowdAtStage) > guest.preferenceStageCrowdSize)
				{
					write guest.name + " crowd at " + guest.targetStage + " is too big (" + length(guest.targetStage.crowdAtStage) + " vs. " + guest.preferenceStageCrowdSize + ") at " + guest.targetStage + " current utility " + guest.currentUtility * guest.preferenceStageCrowdSizeBias;
					loop i from: 0 to: length(stages)-1
					{
						Stage stg <- stages[i];
						// is there a stage with a smaller crowd than preferenceCrowdSize (+1 because this guest wants to join)
						// also is the utility of changing there greater than current utility * crowdSizeBias
						if(length(stg.crowdAtStage) + 1 < guest.preferenceStageCrowdSize)
						{
							if(guest.stageUtilities[i] > guest.currentUtility * guest.preferenceStageCrowdSizeBias)
							{
								guest.targetStage.crowdAtStage >- self;
								guest.targetStage <- stg;
								// cancel the guest's current target (probably stage)
								guest.target <- nil;
								write guest.name + " changes targetStage to " + guest.targetStage + " new utility: " + guest.stageUtilities[i];
								break;
							}
							// If changing the stage would not increase global utility, just stick with this one
							else
							{
//								guest.currentUtility <- guest.currentUtility * guest.preferenceStageCrowdSizeBias;
								guest.currentUtility <- guest.stageUtilities[index_of(stages,guest.targetStage)] * guest.preferenceStageCrowdSizeBias;
								write guest.name + " currentUtility: " + guest.currentUtility + " is best available";
							}
						}
					}
				}
				else
				{
					// If the guest is satisfied right now, just add their utility to global utility
					globalUtility <- globalUtility + guest.currentUtility;
				}
			}
		}
		if(globalUtility != 0.0)
		{
	 		//write name + " calculated global utility: " + globalUtility;
	 		
	 	}
	}
	
	reflex conferenceOver when: length(Conference.population) = 0
	{
		
	}
	
	/*
	 * ShowMaster actions
	 */
	
	action createAuctions
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
	
	action createStages
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
	
	action createConferences
	{
		string genesisString <- name + " creating conference: ";
		create Conference
		{
			
		}
		
		conferenceCreated <- true;
		conferenceNext <- false;
		
	}
	
	action attractionEnded
	{
		nextAttractionStartTime <- int(time + rnd(showMasterIntervalMin, showMasterIntervalMax));
	}
	
	//End of ShowMaster actions
}

/*
 * TODO: document
 */
species Auctioner skills:[fipa, moving] parent: Building
{
	// Auction's initial size and color, location used in the beginning
	int mySize <- 5;
	rgb myColor <- #gray;
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
	rgb myColor <- #gray;
	
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

species Conference skills: [fipa] parent: LongStayPlace
{
	int maxParticipants <- 3;
	
	//number of guests who replied
	int replyCounter <- 0;
	
	list<Guest> participants <- [];
	
	init
	{
		write 'Conference announces it starts soon';
		do start_conversation (to: list(Guest), protocol: 'fipa-propose', performative: 'propose', contents: ["interested?"]);
	}
	
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
	
	//nobody cares about simple-minden individuals
	reflex receive_reject_messages when: !empty(reject_proposals)
	{
		replyCounter <- replyCounter + length(reject_proposals);
	}
	
	reflex startConference when: (length(participants) = maxParticipants or replyCounter = length(Guest.population))
	{	
		if(!one_of(ShowMaster).conferenceRunning)
		{
			if(length(participants) > 0 and participants max_of (location distance_to(each.location)) <= longStayPlaceRadius)
			{
				ask ShowMaster
				{
					conferenceRunning <- true;
				}
				do start_conversation (to: participants, protocol: 'no-protocol', performative: 'inform', contents: ["conference start"]);
			}
			
		}
	}
	
	reflex guestsHaveLeft when: one_of(ShowMaster).conferenceRunning and participants min_of (location distance_to(each.location)) > longStayPlaceRadius
	{
		write "conference ended, guess I'll die";
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
 * TODO: document  
 */
species Ambulance skills:[moving]
{
	Guest targetGuest <- nil;
	Building hospital <- one_of(Hospital);
	bool deliveringGuest <- false;
	
	aspect default
	{
		draw sphere(2) at: location color: #teal;
	}

	// Causes ambulance to go to the hospital when no target is set
	reflex idleAtHospital when: targetGuest = nil
	{
		do goto target:(hospital.location) speed: roboCopSpeed;
	}

	reflex gotoFaintedGuest when: targetGuest != nil
	{
		do goto target:(targetGuest.location) speed: roboCopSpeed;
	}
	
	reflex collectFaintedGuest when: targetGuest != nil
	{
		deliveringGuest <- true;
		if(location distance_to(targetGuest.location) < 1)
		{	
			// Set's the guest's target to hospital
			// (even unconscious guests can move)
			deliveringGuest <- true;
			ask targetGuest
			{
				target <- myself.hospital;
			}
			do goto target:(hospital.location) speed: guestSpeed;
		}
	}	
}// Ambulance end

/*
 * This is the bouncer that goes around killing bad agents
 */
species Security skills:[moving]
{
	list<Guest> targets;
	aspect default
	{
		draw cube(5) at: location color: #black;
	}
	
	reflex catchBadGuest when: length(targets) > 0
	{
		// If a guest is in an auction, wait until they visit the info center again
		if(targets[0].targetAuction != nil)
		{
			targets >- first(targets);
		}
		else
		{
			do goto target:(targets[0].location) speed: roboCopSpeed;
		}
	}
	
	reflex badGuestCaught when: length(targets) > 0 and location distance_to(targets[0].location) < 0.2
	{
		ask targets[0]
		{
			write myself.name + " took away " + name + "s' bad feeling.";
			hunger <- -1.0;
			thirst <- -1.0;
			isBad <- false;
		}
		targets >- first(targets);
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
			species FoodStore;
			species DrinkStore;
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

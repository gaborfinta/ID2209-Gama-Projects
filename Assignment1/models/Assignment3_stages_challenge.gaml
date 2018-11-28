/**
* Name: Assignment 2
* Author: Finta, Vartiainen
* Description: Festival scene with hungry guests, bad guests and a security guard
*/

model NewModel
global 
{
	/*
	 * Guest configs
	 */
	int guestNumber <- rnd(20)+20;
	//int guestNumber <- 1;
	float guestSpeed <- 0.5;
	
	// the rate at which guests grow hungry / thirsty
	// every reflex we reduce hunger / thirst by rnd(0,rate) * 0.1
	int hungerRate <- 1;
	
	/*
	 * Building configs
	 */
	int foodStoreNumber <- rnd(2,3);
	int drinkStoreNumber <- rnd(2,3);
	int infoCenterDetectionDistance <- 0;
	point infoCenterLocation <- {50,50};
	
	/*
	 * Auction configs
	 */
	point showMasterLocation <- {-10,50};
	list<string> itemsAvailable <- ["branded backpacks","signed shirts","heavenly hats", "posh pants"];
	list<string> auctionTypes <- ["Dutch", "English", "Sealed"];
	int auctionerWaitTime <- 10;
	// This is managed by the ShowMaster
	bool runAuctions <- false;
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
	bool runShows <- false;
	list<rgb> stageColors <- [#lime, #pink, #lightblue, #purple];
	
	/*
	 * Other agent configs
	 */	
	// Robotcop is a bit faster than guests, also used by ambulances
	float roboCopSpeed <- guestSpeed * 1.5;
	// The number of ambulances is propotionate to the amount of guests
	int ambulanceNumber <- round(guestNumber / 4);
	
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
		 * Number of stores id defined above 
		 */
		create DrinkStore number: drinkStoreNumber
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
	float thirst <- rnd(50)+50.0;
	float hunger <- rnd(50)+50.0;
	bool isConscious <- true;
	
	// Default color of guests
	rgb color <- #red;
	
	// This is the price at which the guest will buy merch, set in the configs above
	int guestMaxAcceptedPrice <- rnd(guestAcceptedPriceMin,guestAcceptedPriceMax);
	
	// List of remembered buildings
	list<Building> guestBrain;
	// Target to move towards
	Building target <- nil;

	// Which auction is guest participating in
	Auctioner targetAuction;
	
	/* Bad apples are colored differently */
	// Some guests are bad apples and are colored differently
	// They will be removed by the security
	bool isBad <- flip(0.2);
	
	// Each guest prefers a random item out of the items they do not have
		string preferredItem <- itemsAvailable[rnd(length(itemsAvailable) - 1)];
	
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
	int preferenceStageCrowdSize <- rnd(1,guestNumber);
//	float preferenceStageCrowdSizeBias <- 1.0 + rnd(0.0,1.0);
	list<float> stageUtilities <- [];
	ShowMaster showMaster <- one_of(ShowMaster);
	Stage targetStage <- nil;
	
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
	 * common reflex for reaching target
	 * could be stage or store
	 */
	 reflex targetReached when: target != nil and location distance_to(target.location) <= infoCenterDetectionDistance
	 {
	 	target <- nil;
	 }
	
	/*
	 * If the guest's wish list does not contain their current preference,
	 * it means they've acquired that item
	 * and that they should pick a new preference from the remaining items
	 */
	reflex getNewPreference when: !empty(wishList) and !contains(wishList, preferredItem)
	{
		preferredItem <- wishList[rnd(length(wishList) - 1)];
	}
	
	/*
	 * When the guest has a targetAuction, it is considered participating in that auction
	 * Hunger and thirst are disabled for convenience's sake
	 * Unconscious guests will wake up, capitalism never sleeps
	 * 
	 * A target auction is an auction selling the types of items the guest is interested in
	 * TODO: Document
	 */
	reflex inAuction when: targetAuction != nil
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
		 */
		 ask showMaster
		 {
		 	// If stages is empty, remove utilities from guest
		 	if(!empty(stages))
		 	{
			 	loop i from: 0 to: length(stages)-1
			 	{
			 		Stage stg <- stages[i];
			 		if(length(myself.stageUtilities) < length(stages))
			 		{
			 			// Calculate utility by taking the stage's vars and multiplying them by the corresponding preference
						float utility <- stg.stageLights * myself.preferenceStageLights +
										stg.stageMusic * myself.preferenceStageMusic +
										stg.stageShow * myself.preferenceStageShow +
										stg.stageShow * myself.preferenceStageFashionability +
										stg.stageShow * myself.preferenceStageDanceability;
										
			 			string preferenceString <- myself.name + " has calculated utility for " + stg.name + ": ";
						
						// if the stage's genre does not match the Guest's preference, multiply by bias
						if(stg.stageGenre = myself.preferenceStageGenre)
						{
							utility <- utility * myself.preferenceStageGenreBias;
							preferenceString <- preferenceString + " (preferred genre) ";
						}
						// Add stage / utility pair to stageUtilities
						// Couldn't get pairs working, so we'll just keep utilities in a list of floats
						myself.stageUtilities <+ utility;
						write preferenceString + myself.stageUtilities[i];
			 		}
			 	}
			 	
		 		// also look at the crowd size
		 		/*
			 	loop i from: 0 to: length(stages)-1
			 	{
			 		Stage stg <- stages[i];
			 		// if the crowd is bigger than the preferred crowd size, multiply utility by bias
		 			if(length(stg.crowdAtStage) > myself.preferenceStageCrowdSize)
		 			{
		 				write myself.name + " thinks crowd at " + stg.name + " is too big - utilty is " + myself.stageUtilities[i];
		 				myself.stageUtilities[i] <- myself.stageUtilities[i] * myself.preferenceStageCrowdSizeBias;
		 			}
		 		}
		 		*/
		 		
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
/*	 reflex pickStage when: !empty(stageUtilities) and !empty(showMaster.stages) and length(stageUtilities) = length(showMaster.stages) and targetStage = nil
	 {
	 	float highestUtility <- 0.0;
	 	loop i from: 0 to: length(stageUtilities)-1
	 	{
	 		if(stageUtilities[i] >= highestUtility)
	 		{
	 			highestUtility <- stageUtilities[i];
	 			targetStage <- showMaster.stages[i];
	 		}
	 	}
	 	write name + " has picked targetStage " + targetStage;
	 }*/
	
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
		 * Agents can hold two stores in memory
		 * (typically these will be 1 drink and 1 food due to how the agents' grow thirsty/hungry),
		 * and will check if the stores in their memory hace the thing they want (food/drink)
		 * 
		 * Only conscious agents will react to their thirst/hunger 
		 */
		if(target = nil and (thirst < 50 or hunger < 50) and isConscious)
		{	
			string destinationMessage <- name; 

			/*
			 * Is agent thirsty, hungry or both.
			 * Guests will prefer drink over food
			 */
			if(thirst < 50 and hunger < 50)
			{
				destinationMessage <- destinationMessage + " is thirsty and hungry,";
			}
			else if(thirst < 50)
			{
				destinationMessage <- destinationMessage + " is thirsty,";
			}
			else if(hunger < 50)
			{
				destinationMessage <- destinationMessage + " is hungry,";
			}
			
			// Guest has 50% chance of using brain or asking from infocenter
			bool useBrain <- flip(0.5);
			
			// Only use brain if the guest has locations saved in brain
			if(length(guestBrain) > 0 and useBrain = true)
			{

				loop i from: 0 to: length(guestBrain)-1
				{
					// If user is hungry, ask guestBrain for food stores,
					// in the case of draw and otherwise ask for drink stores
					if(thirst > hunger and guestBrain[i].sellsFood = true)
					{
						target <- guestBrain[i];
						destinationMessage <- destinationMessage + " (brain used)";
						break;
					}
					else if(thirst <= hunger and guestBrain[i].sellsDrink = true)
					{
						target <- guestBrain[i];
						destinationMessage <- destinationMessage + " (brain used)";
						break;
					}
				}
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
	}

	/* 
	 * If everything is ok with the guest, they will set their target stage as their target
	 * if they have nothing else to do, guests will wander
	 */
	reflex gotoStageOrBeIdle when: target = nil and isConscious
	{
		if(dead(targetStage))
		{
			targetStage <- nil;
		}
		if(targetStage != nil and location distance_to(targetStage) > 13)
		{
			target <- targetStage;
		}
		else
		{
			do wander;	
		}
	}

	/* 
	 * Agent's default behavior when target not set and they are conscious
	 */
//	reflex beIdle when: target = nil and isConscious
//	{
//		do wander;
//	}
	
	/* 
	 * When agent has target, move towards target
	 * note: unconscious guests can still move, just to enable them moving to the hospital
	 */
	reflex moveToTarget when: target != nil
	{
		do goto target:target.location speed: guestSpeed;
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
	reflex infoCenterReached when: target != nil and target.location = infoCenterLocation and location distance_to(target.location) <= infoCenterDetectionDistance
	{
		string destinationString <- name  + " getting "; 
		ask InfoCenter at_distance infoCenterDetectionDistance
		{
			if(myself.thirst <= myself.hunger)
			{
				myself.target <- drinkStoreLocs[rnd(length(drinkStoreLocs)-1)];
				destinationString <- destinationString + "drink at ";
			}
			else
			{
				myself.target <- foodStoreLocs[rnd(length(foodStoreLocs)-1)];
				destinationString <- destinationString + "food at ";
			}
			
			if(length(myself.guestBrain) < 2)
			{
				myself.guestBrain <+ myself.target;
				destinationString <- destinationString + "(added to brain) ";
			}
			
			//write destinationString + myself.target.name;
		}
	}
	
	/*
	 * When the agent reaches a building, it asks what does the store replenish
	 * Guests are foxy, opportunistic beasts and will attempt to refill their parameters at every destination
	 * Yes, guests will even try to eat at the info center
	 * Such ravenous guests
	 */
	reflex isThisAStore when: target != nil and location distance_to(target.location) < 2
	{
		ask target
		{
			string replenishString <- myself.name;	
			if(sellsFood = true)
			{
				myself.hunger <- 100.0;
				replenishString <- replenishString + " ate food at " + name;
			}
			else if(sellsDrink = true)
			{
				myself.thirst <- 100.0;
				replenishString <- replenishString + " had a drink at " + name;
			}
			
			//write replenishString;
		}
		
		target <- nil;
	}
	
	/*
	 * TODO: Document
	 */
	reflex listen_messages when: (!empty(cfps))
	{
		message requestFromInitiator <- (cfps at 0);
		// the request's format is as follows: [String, auctionType, soldItem, ...]
		if(requestFromInitiator.contents[0] = 'Start' and requestFromInitiator.contents[1] = preferredItem)
		{
			// If the guest receives a message from an auction selling its preferredItem,
			// the guest participates in that auction
			targetAuction <- requestFromInitiator.sender;

			// Send a message to the auctioner telling them the guest will participate
			write name + " joins " + requestFromInitiator.sender + "'s auction for " + preferredItem;
			// TODO: handle this better
			// Essentially add the guest to the interestedGuests list
			targetAuction.interestedGuests <+ self;
		}
		//End of auction
		else if(requestFromInitiator.contents[0] = 'Stop')
		{
//			write name + ' knows the auction is over.';
			targetAuction <- nil;
			target <- nil;
		}
		//Time to send bid for sealed bidding
		else if(requestFromInitiator.contents[0] = 'Bid For Sealed')
		{
			do start_conversation (to: requestFromInitiator.sender, protocol: 'fipa-propose', performative: 'propose', contents: ['This is my offer', guestMaxAcceptedPrice]);
			targetAuction <- nil;
			target <- nil;
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
				targetAuction <- nil;
				target <- nil;
			}
		}
		else if(requestFromInitiator.contents[0] = 'Winner')
		{
			write name + ' won the auction for ' + preferredItem;
			wishList >- preferredItem;
			if(preferredItem = "posh pants")
			{
				write "Go Pants !!!";
			}
		}
	}
	
	/*
	 * In Dutch auction, the auctioner proposes and the participant can accept or reject it, based on the price it would pay for it.
	 */
	reflex reply_messages when: (!empty(proposes))
	{
		message requestFromInitiator <- (proposes at 0);
		// TODO: maybe define message contents somewhere, rn this works
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
				targetAuction <- nil;
				target <- nil;
			}
		}
	}
	
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
	bool sellsFood <- false;
	bool sellsDrink <- false;
	
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
		ask Guest at_distance infoCenterDetectionDistance
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

/* 
 * These stores replenish guests' hunger. The info center keeps a list of food stores.
 */
species FoodStore parent: Building
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
species DrinkStore parent: Building
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
		ask Ambulance at_distance infoCenterDetectionDistance
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
		ask Guest at_distance infoCenterDetectionDistance
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
		
		/*
		 * TODO: document
		 */
		ask Ambulance at_distance infoCenterDetectionDistance
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
 */
species ShowMaster
{
	rgb myColor <- rnd_color(255);
	int mySize <- 10;
	bool auctionersCreated <- false;
	list<Auctioner> auctioners <- [];
	bool auctionersInPosition <- false;
	
	bool stagesCreated <- false;
	list<Stage> stages <- [];
	
	//For tracking when did the last auction/show end
	float endTime <- 0.0;
	
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
	
	/*
	 * This creates the auctioners within the set time limits from the beginning.
	 * auctionCreationMin and auctionCreationMax set at the top
	 */
	reflex createAuctioners when: !auctionersCreated and !runShows and time > endTime + rnd(showMasterIntervalMin, showMasterIntervalMax)
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
		auctionersCreated <- true;
	}
	
	/*
	 * Ask if auctioners are done running around
	 * TODO: document auctioneers returning and being sent out again
	 */
	reflex startAuctions when: auctionersCreated and !runAuctions and !runShows
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
			runAuctions <- true;	
		}
	}
	
	/*
	 * When auctioners return, they remove themselves from the auctioner list and do die
	 * When the list is empty and auctions are running, means all the auctioners have returned
	 * 
	 * Start shows and set auctionersCreated and runAuctions to false so they can be created again
	 */
	reflex areThereAnyAuctionersLeft when: empty(auctioners) and runAuctions
	{
		auctionersCreated <- false;
		runAuctions <- false;
		runShows <- true;
		endTime <- time;
		write name + " knows the auctioners have served their purpose at " + endTime;
	}
	
	/*
	 * This creates the stages within the set time limits from the beginning.
	 * auctionCreationMin and auctionCreationMax set at the top
	 */
	reflex createStages when: !stagesCreated and runShows and time > endTime + rnd(showMasterIntervalMin, showMasterIntervalMax)
	{
		string genesisString <- name + "creating stages: ";
//		create Stage number: stageNumber
		int counter <- 0;
		create Stage number: length(stageColors)
		{
			myself.stages <+ self;
			myColor <- stageColors[counter];
			genesisString <- genesisString + name + " (" + myColor + ") with " + stageGenre + " ";
			counter <- counter + 1;
		}
		stagesCreated <- true;
		write genesisString;
	}

	/*
	 * When stages' shows are finished, they remove themselves from the stages list and do die
	 * When the list is empty and shows are running, means all the stages have finished
	 * 
	 * set stagesCreated and runShows to false so they can be created again
	 */
	reflex areThereAnystagesLeft when: empty(stages) and runShows and stagesCreated
	{
		stagesCreated <- false;
		runShows <- false;
		endTime <- time;
		write name + " knows the stages have finished at " + endTime;
	}
	
	/*
	 * The ShowMaster will coordinate guests around to the stages 
	 */
	 reflex coordinateGuests when: runShows and stagesCreated
	 {
	 	ask Guest
	 	{
	 		if(!empty(stageUtilities) and target = nil)
	 		{
		 		float highestUtility <- 0.0;
			 	loop i from: 0 to: length(stageUtilities)-1
			 	{
			 		if(stageUtilities[i] >= highestUtility)
			 		{
			 			highestUtility <- stageUtilities[i];
			 			target <- myself.stages[i];
			 			write name + " heading to " + target;
			 		}
			 	}	
	 		}
	 	}
	 }
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
	reflex sendStartAuction when: !auctionRunning and runAuctions and targetLocation = nil and !startAnnounced
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
	float mySize <- 10.0;
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
	
	aspect default
	{
		if(!runShows)
		{
			mySize <- 10.0;
			myColor <- #gray;
		}
		draw cylinder(mySize,3.0) color: myColor size: mySize;
	}
	
	/*
	 * If a show is on, flash colors and size
	 */
/*	reflex casinoLigths when: runShows and !showExpired
	{
		myColor <- rnd_color(255);
		if(flip(0.5) and mySize < 15)
		{
			mySize <- mySize + 1;
		}
		else if(mySize >= 13)
		{
			mySize <- mySize - 1;
		}
	}*/
	
	/*
	 * The stage includes all the guests in the vicinity and doesn't care if they are actually following the show
	 * i.e. just a large crowd of passerbys could influence a guest's choice of stage
	 */
	reflex calculateCrowdSize
	{
		// First empty the list
		crowdAtStage <- [];
		// Include any Guest at_distance 13 to crowd list if not already included on the list
		ask Guest at_distance 13
		{
			if(!contains(myself.crowdAtStage, self))
			{
				myself.crowdAtStage <+ self;
			}
		}
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
			
			species Security;
			species Hospital;
			species Ambulance;
			species ShowMaster;
			species Auctioner;
			species Stage;
		}
	}
}

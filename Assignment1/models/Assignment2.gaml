/**
* Name: Assignment 2
* Author: Finta, Vartiainen
* Description: Festival scene with hungry guests, bad guests and a security guard
*/

model NewModel
global 
{
	/*
	 * Configs
	 */
	int GuestNumber <- rnd(10)+10;
	//int GuestNumber <- 1;
	int FoodStoreNumber <- rnd(2,3);
	int DrinkStoreNumber <- rnd(2,3);
	int ambulanceNumber <- 2;
	int infoCenterSize <- 5;
	point infoCenterLocation <- {50,50};
	float guestSpeed <- 0.5;
	// the rate at which guests grow hungry / thirsty
	// every reflex we reduce hunger / thirst by rnd(0,rate) * 0.1
	int hungerRate <- 5;
	//float roboCopSpeed <- 1.8;
	// Robotcop is a bit faster than guests
	float roboCopSpeed <- guestSpeed * 1.5;
	
	// Set in variable so the ambulances can be created next to it
	point hospitalLocation <- {rnd(50),rnd(50)};
	
	
	init
	{
		/* Create GuestNumber (defined above) amount of Guests */
		create Guest number: GuestNumber
		{
			
		}
		
				
		/*
		 * Number of stores is defined above 
		 */
		create FoodStore number: FoodStoreNumber
		{

		}
		
		/*
		 * Number of stores id defined above 
		 */
		create DrinkStore number: DrinkStoreNumber
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
		
		/*
		 * Number of auctioners is defined above 
		 */
		create Auctioner number: 1
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
 * They will reject offers until their preferred price is reached
 * Upon which they accept
 */
species Guest skills:[moving, fipa]
{
	float thirst <- rnd(50)+50.0;
	float hunger <- rnd(50)+50.0;

	// Bad apples are removed by robocop and are darker in color
	bool isBad <- flip(0.2);
	rgb color <- #red;
		
	bool isConscious <- true;
	int acceptedPrice <- 100;
	
	list<Building> guestBrain;
	
	/* Default target to move towards */
	Building target <- nil;
	
	/* Bad apples are colored differently */
	aspect default
	{
		if(isBad) {
			color <- #darkred;
		}
		draw sphere(2) at: location color: color;
	}
	
	/* 
	 * Reduce thirst and hunger with a random value between 0 and 0.5
	 * Once agent's thirst or hunger reaches below 50, they will head towards info/Store
	 */
	reflex alwaysThirstyAlwaysHungry
	{
		/* Reduce thirst and hunger */
		thirst <- thirst - rnd(hungerRate)*0.1;
		hunger <- hunger - rnd(hungerRate)*0.1;
		
		// This is used to decide which store to prefer in case of draw. Default is drink.
		bool getFood <- false;
		
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
			 * If hungry, getFood will be set to true,
			 * otherwise the agent will prefer drink.
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
				getFood <- true;
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
					if(getFood = true and guestBrain[i].sellsFood = true)
					{
						target <- guestBrain[i];
						destinationMessage <- destinationMessage + " (brain used)";
						
						// Set getFood back to false, so we'll continue to prefer drink in the future too
						getFood <- false;
						break;
					}
					else if(getFood = false and guestBrain[i].sellsDrink = true)
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
			write destinationMessage;
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
		
		write perishMessage;
		isConscious <- false;
		color <- #yellow;
		target <- nil;
		
		//do die;
	}

	/* 
	 * Agent's default behavior when target not set and they are conscious
	 * TODO: Do something more exciting here maybe
	 */
	reflex beIdle when: target = nil and isConscious
	{
		do wander;
	}
	
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
	reflex infoCenterReached when: target != nil and target.location = infoCenterLocation and location distance_to(target.location) < infoCenterSize
	{
		string destinationString <- name  + " getting "; 
		ask InfoCenter at_distance infoCenterSize
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
			
			write destinationString + myself.target.name;
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
			
			write replenishString;
		}
		
		target <- nil;
	}
	
	reflex reply_messages when: (!empty(requests))
	{
		message requestFromInitiator <- (requests at 0);
		// TODO: maybe define message contents somewhere, rn this works
		int offer <- int(requestFromInitiator.contents[1]);
		
		if (acceptedPrice > offer) {
			do agree with: (message: requestFromInitiator, contents: ["I, " + name + ", accept your offer of " + offer + ", merchant."]);
		}
		else
		{
			do failure (message: requestFromInitiator, contents: ["I, " + name + ", already have a house full of crap, you scoundrel!"]);	
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
	
	reflex listStoreLocations when: hasLocations = false
	{
		ask foodStoreLocs
		{
			write "Food store at:" + location; 
		}	
		ask drinkStoreLocs
		{
			write "Drink store at:" + location; 
		}
		
		hasLocations <- true;
	}
	
	aspect default
	{
		draw cube(5) at: location color: #blue;
	}

	reflex checkForBadGuest
	{
		ask Guest at_distance infoCenterSize
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
				write 'InfoCenter found a bad guest, sending RoboCop after it';
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
					write "added to unconsciousGuests";
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
	reflex dispatchAmbulance when: length(unconsciousGuests) > 0
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
	
	reflex reviveGuest when: length(underTreatment) > 0
	{
		ask Guest at_distance 0
		{
			if(isConscious = false)
			{
				color <- #red;
				hunger <- 100.0;
				thirst <- 100.0;
				isConscious <- true;
				target <- nil;
				write name + " revived!";
				
				myself.underTreatment >- self;
				myself.unconsciousGuests >- self;
				write name + " removed from underTreatment";
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
 * 
 * TODO:
 * TODO: maybe auctioners buy their own wares from a central storage - use the other auctions for this?
 */
species Auctioner skills:[fipa]
{
	int price <- 50;
	
	aspect
	{
		draw pyramid(10) at: location color: #pink;
	}
		
	reflex send_request when: (time = 50) {
		//list<participant> participants <- list(participant);
		
		write "" + time + ": " + name + ' sends a cfp message to all guests';
		do start_conversation (to: list(Guest), protocol: 'fipa-request', performative: 'request', contents: ['Buy my merch, peasant',price]);
	}

	reflex receive_agree_messages when: !empty(agrees) {
		write '(Time ' + time + '): ' + name + ' receives agree messages';
		
		loop r over: agrees {
			write name + ' got agree from ' + r.sender + ': ' + r.contents ;
		}
	}
	
	reflex receive_failure_messages when: !empty(failures) {
		write '(Time ' + time + '): ' + name + ' receives failure messages';
		
		loop r over: failures {
			write '\t' + name + ' receives a failure message from ' + r.sender + ' with content ' + r.contents ;
		}
	}

/*
	reflex receive_refuse_messages when: !empty(refuses) {
		write '(Time ' + time + '): ' + name + ' receives refuse messages';
		
		loop r over: refuses {
			write '\t' + name + ' receives a refuse message from ' + r.sender + ' with content ' + r.contents ;
		}
	}
*/	
}// Auctioner

// ################ Buildings end ################
// ################ Non-building agents start ################

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
		if(location distance_to(targetGuest.location) < 1)
		{	
			// Set's the guest's target to hospital
			// (even unconscious guests can move)
			ask targetGuest
			{
				target <- myself.hospital;
			}
			do goto target:(hospital.location) speed: guestSpeed;
			deliveringGuest <- true;
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
		//this is needed in case the guest dies before robocop catches them
		if(dead(targets[0]))
		{
			targets >- first(targets);
		}
		else
		{
			do goto target:(targets[0].location) speed: roboCopSpeed;
		}
	}
	
	reflex badGuestCaught when: length(targets) > 0 and !dead(targets[0]) and location distance_to(targets[0].location) < 0.2
	{
		ask targets[0]
		{
			write name + ': exterminated by Robocop!';
			do die;
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
			species Auctioner;
		}
	}
}

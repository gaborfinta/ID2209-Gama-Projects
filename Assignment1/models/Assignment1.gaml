/**
* Name: Assignment 1
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
	int FoodStoreNumber <- rnd(2,3);
	int DrinkStoreNumber <- rnd(2,3);
	int infoCenterSize <- 5;
	point infoCenterLocation <- {50,50};
	// the rate at which guests grow hungry / thirsty
	int hungerRate <- 2;
	
	init
	{
		/* Create GuestNumber (defined above) amount of Guests */
		create Guest number: GuestNumber
		{
			
		}
		
				
		/*
		 * Number of stores id defined above 
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
 */
species Guest skills:[moving]
{
	int thirst <- rnd(50)+50;
	int hunger <- rnd(50)+50;
	int guestId <- rnd(1000,10000);
	
	bool isBad <- flip(0.2);
	rgb color <- #red;
	
	/* Default target to move towards */
	point targetPoint <- nil;
	
	/* Bad agents are colored differently */
	aspect default
	{
		if(isBad) {
			color <- #darkred;
		}
		draw sphere(2) at: location color: color;
	}
	
	/* 
	 * Reduce thirst and hunger with a random value between 0 and 5
	 * Once agent's thirst or hunger reaches below 50, they will head towards info/Store
	 */
	reflex alwaysThirstyAlwaysHungry
	{
		thirst <- (thirst - rnd(hungerRate));
		hunger <- (hunger - rnd(hungerRate));
		
		/* 
		 * If agent has no target and either thirst or hunger is less than 50
		 * then set targetPoint to infoCenterLocation
		 * 
		 * Despite the log messages being different here,
		 * the agent actually decides where to head once it reaches the info center
		 * 
		 * TODO: if agent knows location of store, set that as the targetPoint 
		 */
		if(targetPoint = nil and (thirst < 50 or hunger < 50))
		{
			targetPoint <- infoCenterLocation;
			string destinationMessage <- name + "heading to " + targetPoint;
			
			if(thirst < 50 and hunger < 50)
			{
				destinationMessage <- destinationMessage + " I'm thirsty and hungry.";	
			}
			else if(thirst < 50)
			{
				destinationMessage <- destinationMessage + " I'm thirsty.";
			}
			else if(hunger < 50)
			{
				destinationMessage <- destinationMessage + " I'm hungry.";
			}
			write destinationMessage;
		}
	}
	
	/*
	 * if a guest's thirst or hunger <= 0, then the guest dies 
	 */
	reflex thenPerish when: (thirst <= 0 or hunger <= 0)
	{
		string perishMessage <- name + " perished";
		
		if(thirst <= 0)
		{
			perishMessage <- perishMessage + " of thirst.";
		}
		else if(hunger <= 0)
		{
			perishMessage <- perishMessage + " of hunger.";
		}
		
		write perishMessage;
		do die;
	}

	/* 
	 * Agent's default behavior when target not set
	 * TODO: Do something more exciting here
	 */
	reflex beIdle when: targetPoint = nil
	{
		do wander;
	}
	
	/* When agent has target, move towards target */
	reflex moveToTarget when: targetPoint != nil
	{
		do goto target:targetPoint speed: 3.0;
	}
	
	/* 
	 * Guest arrives to info center
	 * It is assumed the guests will only head to the info center when either thirsty or hungry
	 * 
	 * The guests will prioritize the attribute that is lower for them,
	 * if tied then thirst goes first
	 */
	reflex infoCenterReached when: targetPoint = infoCenterLocation and location distance_to(targetPoint) < 3 
	{
		ask InfoCenter at_distance infoCenterSize
		{
			if(myself.thirst <= myself.hunger)
			{
				myself.targetPoint <- drinkStoreLocs[rnd(length(drinkStoreLocs)-1)].location;
			}
			else
			{
				myself.targetPoint <- foodStoreLocs[rnd(length(foodStoreLocs)-1)].location;
			}
			
			write myself.name + "heading to " + myself.targetPoint;	
		}
	}
	
}// Guest end

/* InfoCenter serves info with the ask function */
species InfoCenter {
	// Get every store within 1000, should be enough	
	list<FoodStore> foodStoreLocs <- (FoodStore at_distance 1000);
	list<DrinkStore> drinkStoreLocs <- (DrinkStore at_distance 1000);
	
	// We only want to querry locations once
	bool hasLocations <- false;
	
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
					self.target <- badGuest;
				}
			}
		}
	}
}// InfoCenter end

/* 
 * These stores replenish guests' hunger. The info center keeps a list of food stores.
 */
species FoodStore
{
	aspect default
	{
		draw pyramid(5) at: location color: #green;
	}
}

/* 
 * These stores replenish guests' thirst. The info center keeps a list of drink stores.
 */
species DrinkStore
{	
	aspect default
	{
		draw pyramid(5) at: location color: #gold;
	}
}

/*
 * This is the bouncer that goes around killing bad agents
 */
species Security skills:[moving]
{
	Guest target <- nil;
	aspect default
	{
		draw cube(3) at: location color: #black;
	}
	
	reflex catchBadGuest when: target != nil
	{
		do goto target:target.location speed: 4.0;
	}
	
	reflex badGuestCaught when: target != nil and location distance_to(target) < 0.5
	{
		target <- nil;
		ask Guest at_distance 0.5
		{
			write name + ': exterminated by Robocop!';
			do die;
		}
	}	
}

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
		}
	}
}

/* Insert your model definition here */


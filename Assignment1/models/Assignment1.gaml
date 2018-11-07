/**
* Name: Assignment 1
* Author: Finta, Vartiainen
* Description: Hello world
*/

model NewModel
global 
{
	int GuestNumber <- rnd(10)+10;
	int infoCenterSize <- 5;
	
	init
	{
		/* Create GuestNumber (defined above) amount of Guests */
		create Guest number: GuestNumber
		{
			
		}
		
		/*
		 * location is 50,50 to put the info center in the middle
		 */
		create InfoCenter number: 1
		{
			location <- {50,50};
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
 * TODO: Once guests reach info center, they will ask for the location of either the 
 */
species Guest skills:[moving]
{
	int thirst <- rnd(50)+50;
	int hunger <- rnd(50)+50;
	int guestId <- rnd(1000,10000);
	
	/* Default target to move towards */
	point targetPoint <- nil;
	
	aspect default
	{
		draw sphere(2) at: location color: #red;
	}
	
	/* Reduce thirst and hunger with a random value between 0 and 5
	 * Once agent's thirst or hunger reaches below 50, they will head towards info/shop
	 * TODO: if thirst/hunger is zero agent dies
	 */
	reflex alwaysThirstyAlwaysHungry {
		thirst <- (thirst - rnd(5));
		hunger <- (hunger - rnd(5));
		
		/* If agent has no target and either thirst or hunger is less than 50
		 * then set targetPoint to info
		 * TODO: if agent knows location of store, set that as the targetPoint 
		 */
		if(targetPoint = nil and (thirst < 50 or hunger < 50)) {
			targetPoint <- {50,50};
			string destinationMessage <- name + "heading to " + targetPoint;
			//write name + " heading to " + targetPoint;
			if(thirst < 50 and hunger < 50) {
				destinationMessage <- destinationMessage + " I'm thirsty and hungry.";	
			}
			else if(thirst < 50) {
				destinationMessage <- destinationMessage + " I'm thirsty.";
			}
			else if(hunger < 50) {
				destinationMessage <- destinationMessage + " I'm hungry.";
			}
			write destinationMessage;
		}
	}

	/* Agent's default behavior when target not set
	 * TODO: Do something more exciting here
	 */
	reflex beIdle when: targetPoint = nil {
		do wander;
	}
	
	/* When agent has target, move towards target */
	reflex moveToTarget when: targetPoint != nil {
		do goto target:targetPoint;
	}
	
	/*Guest arrives to infocenter */
	reflex infoCenterReached when: targetPoint != nil and location distance_to(targetPoint) < 3 
	{
		ask InfoCenter at_distance infoCenterSize
		{
			//Set targetpoint to the correct target
			//Hungry but not thirsty
			if(myself.hunger < 50 and myself.thirst >= 50)
			{
				//targetPoint <- get locaion from infocenter
			}
			//Thirsty but not hungry
			else if(myself.thirst < 50 and myself.hunger >= 50)
			{
				
			}
			//Hungry and thirsty
			else
			{
				
			}
			
		}
		
	}
}

/* InfoCenter serves info with the ask function */
species InfoCenter
{
	aspect default
	{
		draw sphere(2) at: location color: #blue;
	}
}

/* Shops can sell either food or drink */
species Shop
{
	aspect default
	{
		draw sphere(2) at: location color: #green;
	}
}

/* This is the bouncer that goes around killing bad agents */
species Security
{
	aspect default
	{
		draw sphere(3) at: location color: #black;
	}
}

experiment main type: gui
{
	
	output
	{
		display map type: opengl
		{
			species Guest;
			species InfoCenter;
		}
	}
}

/* Insert your model definition here */


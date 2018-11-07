/**
* Name: NewModel
* Author: Finta, Vartiainen
* Description: Hello world
* Tags: Tag1, Tag2, TagN
*/

model NewModel
global 
{
	int GuestNumber <- rnd(10)+10;
	int StoreNumber <- rnd(4,6);
	
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
		
		/*
		 * Number of stores id defined above 
		 */
		create Store number: StoreNumber
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
 * TODO: Once guests reach info center, they will ask for the location of either the 
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
	
	/* Reduce thirst and hunger with a random value between 0 and 5
	 * Once agent's thirst or hunger reaches below 50, they will head towards info/Store
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
	/*
	 * if a guest's thirst or hunger <= 0, then the guest dies 
	 */
	reflex thenPerish when: (thirst <= 0 or hunger <= 0) {
		string perishMessage <- name + " perished";
		if(thirst <= 0) {
			perishMessage <- perishMessage + " of thirst.";
		}
		else if(hunger <= 0) {
			perishMessage <- perishMessage + " of hunger.";
		}
		write perishMessage;
		do die;
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
		ask InfoCenter at_distance 3
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
		draw cube(5) at: location color: #blue;
	}
}

/* 
 * All stores sell drinks, a store has a 50% chance of selling food.
 * Stores selling food are golden
 */
species Store
{
	bool sellsFood <- flip(0.5);
	
	rgb color <- #green;
	
	aspect default
	{
		if(sellsFood) {
			color <- #gold;	
		}
		
	draw pyramid(5) at: location color: color;
	}
	
}

/* This is the bouncer that goes around killing bad agents */
species Security
{
	aspect default
	{
		draw cross(4) at: location color: #orange;
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
			species Store;
		}
	}
}

/* Insert your model definition here */


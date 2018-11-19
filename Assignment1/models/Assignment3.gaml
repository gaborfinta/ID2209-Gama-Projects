/**
* Name: Assignment 3
* Author: Finta, Vartiainen
* Description: Festival scene with the N Queen stages
*/

model NewModel
global 
{
	/*
	 * Put configs here
	 */
	// N is the number of Queens
	// Same number also defines how many squares there should be for the floor
	int N <- 8;
	float tileSize <- 100 / (N);

	init
	{
		create YasQueen number: N
		{

		}
	}
}

/*
 * The queens have to find spots in a way they don't interfere with the other queens.
 */
species YasQueen skills: [moving, fipa]
{
	rgb myColor <- #blue;
	point targetLocation <- nil;
	bool inPosition <- false;
	
	// The queen can only talk to their predecessor and succesor in the list of queens
	bool neighborsFound <- false;
	YasQueen preceedingQueen <- nil;
	YasQueen succeedingQueen <- nil;
	
	// These are for seeing how the queens align while they're finding their spot
	bool drawThreatenLines <- true;
	
	/*
	 * Identify the queen's neighbors only if they haven't been found yet
	 */
	reflex findNeighbors when: neighborsFound != true
	{
		int ownIndex <- index_of(YasQueen, self);
		// If this is the first agent, then set the last agent as preceeding
		if(ownIndex != 0)
		{
			preceedingQueen <- YasQueen[ownIndex-1];
		}
		else
		{
			preceedingQueen <- YasQueen[length(YasQueen)-1];
		}
		// If this is the last agent, then set the first agent as succeeding
		if(ownIndex != length(YasQueen)-1)
		{
			succeedingQueen <- YasQueen[ownIndex+1];
		}
		else
		{
			succeedingQueen <- YasQueen[0];
		}
		
		write name + " previous: " + preceedingQueen + " and succeeding: " + succeedingQueen;
		neighborsFound <- true;
	}

	aspect default
	{
		draw square(10) color: myColor size: 100/N;
		if(drawThreatenLines != false)
		{
			// these are just for visualizing if the queens threaten each other
			draw line([{0,0},{100,100}]) at: location + {0,0,-0.05} color: myColor;
			draw line([{100,0},{0,100}]) at: location + {0,0,-0.05} color: myColor;
			draw line([{0,0},{100,0}]) at: location + {0,0,-0.05} color: myColor;
			draw line([{0,0},{0,100}]) at: location + {0,0,-0.05} color: myColor;
		}
	}
	
	// while the queen has a target, move towards target
	reflex goToLocation when: targetLocation != nil
	{
		do goto target: targetLocation speed: 3.0;
	}
	
	
}

experiment main type: gui
{
	
	output
	{
		display map type: opengl
		{
        	species YasQueen;	
			
			graphics "blackLayer" {
                loop i from: 0 to: N * N - 1
				{
					// The squares are drawn at -0.1 depth to make sure they're below everything else
					draw square(tileSize) at:{tileSize / 2 + mod(floor(i / N), 2) * tileSize + tileSize * mod((i + i), N),tileSize / 2 + tileSize * floor((i / N)),-0.1} color:#gray;
				}
            }
		}
	}
}

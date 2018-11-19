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
	
	// The queen can only talk to their predecessor and succesor in the list of queens
	YasQueen preceedingQueen <- nil;
	YasQueen succeedingQueen <- nil;
	
//	reflex findNeighbors
	
	aspect default
	{
		draw square(10) color: myColor;
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

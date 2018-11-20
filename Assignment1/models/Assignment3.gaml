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
	
	matrix availableCells <- 1 as_matrix({N, N});
	list<pair<int, int>> placedQueenPositions;
	
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
	int ownIndex <- index_of(YasQueen, self);
	int column <- -1;
	int row <- ownIndex;
	
	// These are for seeing how the queens align while they're finding their spot
	bool drawThreatenLines <- false;
	
	init constructor
	{
		do updateLocation;
	}
	
	/*
	 * Identify the queen's neighbors only if they haven't been found yet
	 */
	reflex findNeighbors when: neighborsFound != true
	{
		// If this is the first agent, then set the last agent as preceeding
		if(ownIndex != 0)
		{
			preceedingQueen <- YasQueen[ownIndex-1];
		}
		else
		{
			//preceedingQueen <- YasQueen[length(YasQueen)-1];
		}
		// If this is the last agent, then set the first agent as succeeding
		if(ownIndex != length(YasQueen)-1)
		{
			//succeedingQueen <- YasQueen[ownIndex+1];
		}
		else
		{
			succeedingQueen <- YasQueen[0];
		}
		
		write name + " previous: " + preceedingQueen + " and succeeding: " + succeedingQueen;
		neighborsFound <- true;
	}
	
	
	/*
	 * This is supposed to trigger when the previous queen is set and the new one needs to be placed
	 */
	reflex placeMySelf when: length(placedQueenPositions) = ownIndex
	{
		if(ownIndex = 0)
		{
			column <- 0;
		}
		else
		{
			column <- first_with(range(N - 1), availableCells[each, row] = 1);
			
		}
		placedQueenPositions <+ column :: row;
		do updateBoardInfo;
	}
	
	reflex updateLocaton
	{
		do updateLocation;
	}
	
	/*
	 * Updates loction according to new X and Y coordinates
	 */
	action updateLocation
	{
		location <- {column * tileSize + tileSize / 2, row * tileSize + tileSize / 2};
	}
	
	
	/*
	 * Update the avilableCells matrix with the newly placed queen.
	 * This puts zeroes to the unavailable places.
	 * 
	 */
	action updateBoardInfo
	{
		loop i from: 0 to: N - 1
		{
			//fill row with zeroes
			availableCells[i, row] <- 0;
			//fill column with zeroes
			availableCells[column, i] <- 0;
			//fill left to right diagonal with zeroes
			if(column + i < N and row + i < N)
			{
				availableCells[column + i, row + i] <- 0;
			}
			//fill right to left diagonal with zeroes
			if(column - i >= 0 and row + i < N)
			{
				availableCells[column - i, row + i] <- 0;
			}
			
		}
		
		loop queenPos over: placedQueenPositions
		{
			availableCells[queenPos.key, queenPos.value] <- 9;
		}
		
		write "QUEEN: " + row;
		write "placedQueenPositions "  + placedQueenPositions;
		write "availableCells: \n" + availableCells;
	}
	

	aspect default
	{
		draw circle(100 / (N * 3.5)) color: myColor at: location;
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
	/*reflex goToLocation when: targetLocation != nil
	{
		do goto target: targetLocation speed: 3.0;
	}*/	
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

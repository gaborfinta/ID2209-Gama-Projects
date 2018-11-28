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
	int N <- 16;
	float tileSize <- 100 / (N);
	
	//matrix availableCells <- 1 as_matrix({N, N});
	
	//list containing the index of column corresponsing to the queen. placedQueens[2] = 1 means second queen is placed in first column
	list<int> placedQueens;
	
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
	YasQueen preceedingQueen <- nil;
	YasQueen succeedingQueen <- nil;
	int ownIndex <- index_of(YasQueen, self);
	int column <- -1;
	int row <- ownIndex;
	bool needsToStep <- false;
	
	// These are for seeing how the queens align while they're finding their spot
	bool drawThreatenLines <- false;
	
	init constructor
	{
		do findNeighbors;
		if(ownIndex = 0)
		{
			column <- 0;
			placedQueens <+ column;
			do updateBoardInfo;
		}
		do updateLocation;
	}
	
	/*
	 * Identify the queen's neighbors only if they haven't been found yet
	 */
	action findNeighbors
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
			succeedingQueen <- YasQueen[ownIndex+1];
		}
		else
		{
			//succeedingQueen <- YasQueen[0];
		}
		
		write name + " previous: " + preceedingQueen + " and succeeding: " + succeedingQueen;
	}
	/*
	 * Predecessor queen will place the next one if predecessor is the last one placed 
	 */
	reflex placeNextQueen when: ownIndex < N - 1 and length(placedQueens) = ownIndex + 1 and !needsToStep and empty(requests)
	{
		do placeNextQueen;
	}
	
	/*
	 * Queens get fipa messages here
	 * place: predecessor asks current queen to place herself to the position given
	 * cancel: predecessor asks current queen to cancel itself, delete from lists, because predecessor needs to be replaced
	 * step me: current queen asks predecessor to step her to the next available place. Her current position is the second element
	 */
	reflex listenToRequests when: (!empty(requests))
	{
		message request <- requests[0];
		write 'Queen ' + ownIndex + ' reveived message: ' + request.contents;
		if(request.contents[0] = 'place')
		{
			needsToStep <- false;
			column <- int(request.contents[1]);
			placedQueens <+ column;
			do updateBoardInfo;
		}
		else if(request.contents[0] = 'cancel')
		{
			write 'placedQueens: ' + placedQueens;
			write 'removing last element: ' + column + ' if it was in the placed queens list';
			if(length(placedQueens) = row + 1)
			{
				placedQueens[] >- row;
			}
			write 'placedQueenPositions: ' + placedQueens;
			column <- -1;
			do updateBoardInfo(false);
		}
		else if(request.contents[0] = 'step me')
		{
			do stepNextQueen(int(request.contents[1]));
		}
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
	 * If current queen can't place next queen, tells her to cancel herself and asks for a step from the predecessor
	 */
	action cantPlaceNextQueen
	{
		write 'Queen ' + ownIndex + ' cant place next queen';
		do start_conversation (to: [succeedingQueen], protocol: 'fipa-request', performative: 'request', contents: ['cancel']);
		do askForStep;
	}
	
	/*
	 * Current queen asks predecessing one to step her
	 * The first one is not that lazy, it will step itself
	 */
	action askForStep
	{
		if(ownIndex != 0)
		{
			needsToStep <- true;
			write 'Queen ' + ownIndex + ' asks preceeding one to step her';
			int currCol <- column;
			placedQueens[] >- row;
			do updateBoardInfo(false);
			do start_conversation (to: [preceedingQueen], protocol: 'fipa-request', performative: 'request', contents: ['step me', currCol]);	
		}
		else
		{
			placedQueens[] >- row;
			column <- column + 1;
			placedQueens <+ column;
			do updateBoardInfo(false);
		}
	}
	
	/*
	 * Current queen places the next one to the first available place
	 * If can't, calls cantPlaceNextQueen
	 */
	action placeNextQueen
	{
		int toStep <- self findAvailableColumn[];
		
		if(toStep = -1)
		{
			do cantPlaceNextQueen;			
		}
		else
		{
			write 'Queen ' + ownIndex + ' requesting next queen to place itself to: ' + toStep;
			do start_conversation (to: [succeedingQueen], protocol: 'fipa-request', performative: 'request', contents: ['place', toStep]);
		}
	}
	
	int findAvailableColumn(int startColumn <- 0)
	{
		bool foundPotentialColumn <- false;
		int potentialColumn <- startColumn;
		loop while: !foundPotentialColumn and potentialColumn < N
		{
			bool foundThreateningQueen <- false;
			int i <- 0;
			loop while: !foundThreateningQueen and i < length(placedQueens)
			{
				//check for same column and diagonal
				//write 'row - i = ' + row + ' ' + i + ' ' + (row - i);
				//write 'potentialColumn - placedQueens[i] = ' + potentialColumn + ' ' + placedQueens[i] + ' ' + (potentialColumn - placedQueens[i]);
				foundThreateningQueen <- placedQueens[i] = potentialColumn or abs(row + 1 - i) = abs(potentialColumn - placedQueens[i]);
				i <- i + 1;
			}
			foundPotentialColumn <- !foundThreateningQueen;
			if(foundThreateningQueen)
			{
				potentialColumn <- potentialColumn + 1;
			}
		}
		if(!foundPotentialColumn)
		{
			return -1;
		}
		else
		{
			return potentialColumn;
		}
		
	}
	
	/*
	 * Current queen steps the succeeding one to the next available place.
	 * If can't, calls cantPlaceNextQueen
	 */
	action stepNextQueen(int currPos)
	{
		write 'Queen ' + ownIndex + ' trying to step next queen';
		
		int toStep <- self findAvailableColumn[startColumn:: currPos + 1];
		
		if(toStep = -1)
		{
			do cantPlaceNextQueen;			
		}
		else
		{
				do start_conversation (to: [succeedingQueen], protocol: 'fipa-request', performative: 'request', contents: ['place', toStep]);
		}
	}
	
	/*
	 * Update the avilableCells matrix with the newly placed queen.
	 * This puts zeroes to the unavailable places.
	 * If a queen is added, add new zeroes to the unavailable spaces
	 * If a queen is removed, recaulculate the whole matrix
	 */
	action updateBoardInfo(bool queenAdded <- true)
	{
		/*write 'called updateBoardInfo with queenAdded: ' + queenAdded;
		if(queenAdded)
		{
			if(column = -1)
			{
				return;
			}
			do calculateZeroesByQueenPosition(column, row);
		}
		else
		{
			availableCells <- 1 as_matrix({N, N});
			loop queenPos over: placedQueenPositions
			{
				do calculateZeroesByQueenPosition(queenPos.key, queenPos.value);
			}
		}
		
		loop queenPos over: placedQueenPositions
		{
			availableCells[queenPos.key, queenPos.value] <- 9;
		}
		
		write "placedQueenPositions "  + placedQueenPositions;
		write "availableCells: \n" + availableCells;*/
	}
	
	action calculateZeroesByQueenPosition(int c, int r)
	{
		//write 'calling calculateZeroesByQueenPosition with c: ' + c + ', r: ' + r;
			/*loop i from: 0 to: N - 1
			{
				//fill row with zeroes
				availableCells[i, r] <- 0;
				//fill column with zeroes
				availableCells[c, i] <- 0;
				//fill left to right diagonal with zeroes
				if(c + i < N and r + i < N)
				{
					availableCells[c + i, r + i] <- 0;
				}
				//fill right to left diagonal with zeroes
				if(c - i >= 0 and r + i < N)
				{
					availableCells[c - i, r + i] <- 0;
				}
			}*/
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
				
				loop j from: 0 to: N - 1
				{
					loop i from: 0 to: N - 1
					{
						if(mod(j, 2) = 0)
						{
							if(mod(i, 2) = 0)
							{
								draw square(tileSize) at: {tileSize / 2 + i * tileSize, tileSize / 2 + j * tileSize, -0.1} color: #gray;
							}
						}
						if(mod(j, 2) = 1)
						{
							if(mod(i, 2) = 1)
							{
								draw square(tileSize) at: {tileSize / 2 + i * tileSize, tileSize / 2 + j * tileSize, -0.1} color: #gray;
							}
						} 
					}
				}
				
                /*loop i from: 0 to: N * N - 1
				{
					// The squares are drawn at -0.1 depth to make sure they're below everything else
					draw square(tileSize) at:{tileSize / 2 + mod(floor(i / N), 2) * tileSize + tileSize * mod((i + i), N),tileSize / 2 + tileSize * floor((i / N)),-0.1} color:#gray;
				}*/
            }
		}
	}
}

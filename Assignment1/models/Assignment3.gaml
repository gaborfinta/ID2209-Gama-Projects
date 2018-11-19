/**
* Name: Assignment 2
* Author: Finta, Vartiainen
* Description: Festival scene with hungry guests, bad guests and a security guard
*/

model NewModel



global 
{
	int N <- 8;
	float tileSize <- 100 / (N);

	init
	{

	}
	
}

experiment main type: gui
{
	
	output
	{
		display map type: opengl
		{

			
			graphics "blackLayer" {
                
                loop i from: 0 to: N * N - 1
				{
					draw square(tileSize) at:{tileSize / 2 + mod(floor(i / N), 2) * tileSize + tileSize * mod((i + i), N),tileSize / 2 + tileSize * floor((i / N))} color:#black;
				}
            }
		}
	}
}

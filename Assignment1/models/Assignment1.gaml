/**
* Name: NewModel
* Author: Finta
* Description: Hello world
* Tags: Tag1, Tag2, TagN
*/

model NewModel
global 
{
	init
	{
		create HelloAgent number: 2
		{
			
		}
		
	}
	
}


species HelloAgent
{
	aspect default
	{
		draw sphere(2) at: location color: #red;
	}
}

experiment main type: gui
{
	
	output
	{
		display map type: opengl
		{
			species HelloAgent;
		}
	}
}

/* Insert your model definition here */


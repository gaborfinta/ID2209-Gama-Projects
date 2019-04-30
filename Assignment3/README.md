# Assignment 3
This assignment is built on top of assignment 2. In this readme file, only the new features are discussed.
In this assignment stages are introduced to the festival area. They have concerts from time to time and guests want to attend the ones they like the most. Each guest has a music preference and chooses the right stage according to this and some other variables. 

## Species

### ShowMaster
This agent creates Auctioneers and controls Stages. This controls them so that they can take turns. Furthermore, it is responsible for coordinating guests. When guests need to choose stages, it will tell them where to go so it works as a central controller. It takes the necessary variables from the guests, such as their music preference and if they like big crowds or not and calculates the best possible distribution of guests.

### Stages
Stages don’t have much actions to do. Showmaster tells them to start the show and they keep the party going on for a while. When finished, they return. The stages have some variables that helps the guests decide if they want to go there or not.

### Guests
The guests now only attend auctions if they have some missing items yet that they want to acquire. They choose the right stage based on their utility function. There are many different preferences which influence the decisions. These are:
- Stage lighting
- Music
- How good the show is
- Fashionability
- Danceability
- Preferred genre
- How strong the preference is for the genre
- Preferred crowd size

# Assignment 3 - Task 2
Since the stages are introduced in this assignment their placement is important. The task says that to avoid collision of the sounds and ruining the experience, the stages need to be placed as the solutions of the <b> N Queen problem </b>.
The Assignment3.gaml contains an implementation that solves the N Queen problem where N is a configuration variable at the top of the file. Important to note, that there is no central controller here, the queens comminucate to their preceeding and succeeding neighbors and that's how they figure out the next step. 

## Algorithm
We used backtracking algorithm. The first queen is placed at the start position and then finds an available position for the next queen in the next row. Then the next queen starts looking for an available position in the succeeding row. This goes on as long as there are available cells. When a row’s all position has been tried without luck / there are no more available cells, the queen ask the next one to remove itself from the board and also tells the preceding queen that it needs to be replaced. Here it start looking for an available position again and this goes on. The algorithm stops when a good board setup has been found.

## Communication
The queens communicate using the FIPA protocol. All messages are sent with the FIPA propose protocol and request performative.

This picture shows an example final setup for N=10

<img src="https://user-images.githubusercontent.com/31373135/55143743-a7b5a680-513f-11e9-900f-b4102ffd2abd.png" height="400"/>

## Assignment files
The model folder contains three files. In this assignment, the challenges implemented can be found in the *Assignment3_stages_challenge.gaml*. This implements stages on the festival area.
The creative part of the assignment can be found in the file *Assignment3_zombies.gaml* and introduces zombies.

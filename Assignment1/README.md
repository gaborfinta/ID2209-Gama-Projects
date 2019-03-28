# Assignment 1
This is the base implementation of a festival area. The first picture is an example photo.
![casual_guests](https://user-images.githubusercontent.com/31373135/55077302-adf04800-5097-11e9-9242-4149280dc7f4.png)


## Species

### Guest
This is agent is very simple. It wanders around randomly as long as its hunger and thirst values don’t fall below 50 (out of a total 100). Hunger and thirst are floating point values and decrease by 0 - 0.5 every cycle. Once below 50, the agent will either seek the info center to find out the location of a store to refill its needs or use its small memory to revisit a previously visited store if it contains such. If either the hunger or thirst reaches 0, the guest passes out and needs to be "revived". These agents are represented by red spheres.

### Building
The parent species to all buildings. Has two booleans sellsFood and sellsDrink, both of which are false by default. The guests can have Buildings as their target to go to. Having the target as a building allows the guest to both know the location, as well as what kind of a building is it - i.e. check for sellsFood and sellsDrink.

#### InfoCenter
The info center sits at the middle of the simulation area {50,50}. In the beginning it queries the stores and saves them in two different lists for food and drink stores. Guests visit this Building to get info about stores. It also checks for bad guests in around and immediately reports them to the security guard. This agent is represented by a blue cube.

#### FoodStore and DrinkStore
A building with sellsFood or sellsDrink member variable set to true. Whenever a guest has a target (any building can be a target), the guest agent will check if it is within range of its target building (a common detection range for the info center, guests and stores etc. is set with the infoCenterDistance variable) and if yes, then it will also check if the target building sells food or drink. I.e. guests will attempt to eat and drink at the info center when visiting it. In case the target building does sell either food or drink, the guest will replenish the appropriate need. These agents are represented by pyramids.

#### Hospital
The hospital searches the area for unconscious guests in every iteration. If it finds one, it adds it to the unconsciousGuests list where they will be kept until an ambulance starts processing them. Whenever this happens, they are removed from this list and added to the underTreatment list. Guests who are in this list will be taken to the hospital by the ambulance where the hospital replenishes their food and drink variables. After this, the revived guests are free to do whatever they were doing before. This agent is represented as a blue cube.

### Security
The security guard is responsible for killing bad agents when the infocenter spots them. Whenever the InfoCenter spots one, it is added to the security guard’s target list. Then, in every iteration the security guard checks the list of naughty guests and kills them one by one. It is faster than a regular guest to ensure that it is caught quickly before they would actually do something bad. Whenever it gets close enough, it asks the guest agent to die. This agent is represented as a black cube. In this picture, the security guard (black cube) is chasing down Guest9 which is dining at a FoodStore(green pyramid).

<img src= https://user-images.githubusercontent.com/31373135/55077543-50a8c680-5098-11e9-9028-bfe965014936.png height=200 border=1>

### Ambulance
In their idle state, the ambulances will head to the hospital and wait for instructions. Upon being issued a target by the hospital, the ambulances will head to the target and bring it to the hospital. These agents are represented as blue spheres.
First picture shows ambulances (blue sphere) in the field, while the second one shows them during work, dragging unconscious (yellow spheres) people around.

<img src=https://user-images.githubusercontent.com/31373135/55077542-50a8c680-5098-11e9-9699-d44d83795bc0.png height="200" border="1"> <img src=https://user-images.githubusercontent.com/31373135/55077541-50a8c680-5098-11e9-92dd-80c8eda2cf0c.png height="200" border="1">

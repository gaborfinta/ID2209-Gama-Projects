# Final Project
The final project was a bigger assignment which is built on top of the first 3 assignments. Only the extra features are discussed in this readme. On a general, the simulation contains a variety of human agents and buildings the humans may interact with. The Humans also interact with each other much more than before. Specific places for this are introduced as well.

As a challenge for the project, zombies are added to the festival area. They chase down humans and turn them into zombies. If security is alive, it tries to kill the zombies. After tweaking the configurations, we could achieve that in some simulations everyone turns into zombies while in others the security can kill all of them.

## Species

### Humans and zombies
Humans are the most numerous agents, mostly thanks to the Guest agents being humans. Other humans include the Ambulance and Security agents. All humans may become zombies (via fighting an already zombified human), which changes several of the agent’s behavior and stops them from performing some or all of their assigned functions, such as being a Guest, Security or  an Ambulance, but most importantly when a zombified Human becomes hungry, they will chase down another human and attempt to fight them. A zombie that wins a fight against another human causes their target human to also become a zombie. While the Security and Ambulance agents will work to counteract the zombification of the whole Human population of the simulation, most simulations either see all the Humans either become zombies, or all zombies removed.

#### Guest personalities 
Guest personalities can have an effect of the interaction of the guests. Each personality has a nemesis who they hate and will make them annoyed if they are not happy enough to tolerate them. If a Guest’s happiness is high enough, they don’t mind their nemesis being around. Otherwise, they start yelling. 

##### Scientist and Flat Earthers
Scientists are smart people who like to engage in intellectual conversations.
Flat earthers are people who think they are smart and like to engage in “intellectual” conversations.
When these two people meet at a conference they start annoying each other and can’t enjoy themselves.

##### Party and Chill people
Party people like to party, obviously.
Chill people prefer having a few drinks in a bar and not being too noisy while enjoying their friends. Chill people can get annoyed if party people are at the same Bar.

### Bars
The Bars come in place of food and drink stores. Here, Guests can eat and drink but they will also stay for a long period of time and they can interact with each other. This is a frequent place where guests with Party and Chill personalities can meet.

### Conferences
The Conference is a place where guests can go if they want to have an intellectual conversation. They can stay here for a longer period of time and interact with each other. It pops up once every day. This is a frequent place where flat earthers and scientists can meet.

## Global happiness
We implemented happiness for the Guests which is affected by comsuming food or drinks, winning at auctions, dancing at stages or having nice conversations at bars conferences.
Letting the simulation run for three virtual days, where auctions, stages, conferences all pop up once a day, we can see the happiness increase. Gama provides a tool to monitor variables in the simulation. We extracted these values and plotted it in MatLab. 
<img src="https://user-images.githubusercontent.com/31373135/55144685-abe2c380-5141-11e9-9d7d-30b3f6dd6c1f.png" height="400"/>

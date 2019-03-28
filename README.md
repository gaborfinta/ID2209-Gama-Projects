# Course project for Distributed AI and Intelligent Agents course in KTH University

Exercises for the course are focused around the festival topic. Agents in this scenario communicate with each other and try to act in a way to fulfill their goals. The assignments were built on top of each other. More details about the tasks can be found in the corresponding folders.

The tasks were solved with GAMA which is a simulation platform focused on agent simulations in 3D space. More info: https://gama-platform.github.io/

## How to run

We used GAMA 1.8 and to run the code, it needs to be installed on the system. The .gaml file should go in the ../models directory of the workspace in use. The simulation should run by running the model main as usual. There are some configurations available at the top of the file (such as guestSpeed for guest walking speed and hungerRate for the rate at which guests grow thirsty/hungry), but it is recommended to run the simulation with the default values. As the complexity of tasks increase, the impact of the configurations increase as well. 

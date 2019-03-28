# Assignment 2
This assignment is built on top of assignment 1. In this readme file, only the new features are discussed.
In this assignment, auctions are introduced to the festival area. Auctioneers come to the venue from time to time, offering their merch that the guests can bid for. Multiple auction types are implemented.
The guests have some "money" with them that they can use to bid and the winner can wear the merch.

## Species

### AuctionMaster
This agent is responsible for creating and sending out the auctioneers to the festival area. It is also responsible for grabbing the attention of the guests by being fabulous and colourful. It is placed outside of the festival area and is represented by a big pyramid, constantly changing colors.

### Auctioneer
This agent runs the actual auction. It can run three different auction types: Dutch, English and Sealed. In the beginning, they pick a random location and go to that place from the master. When they reach it, they start announcing the start of the auction, which is a message to the guests with fipa-propose protocol and cfp performative with the content of “Start” and the name of the sold item. After this, the auctioneer waits for the guests to gather around them and starts the auction. Then the different auctions happen is different ways. Finally, the auctions end with a cfp message with the content of “Stop”.
#### Dutch:
In this type of auction, after the guests approached the auctioneer, it sends a propose message to the participants with the price as the content. The participants listen to these messages and send an accept or rejects the proposal based on the price of the item. If it gets rejects only, it decreases the price by a small enough random amount and repeats the process.
The first time the auctioneer gets an accept message as a reply, the item is sold.
#### English:
This is the classical auction, participants always have to yell higher bids then previously and when nobody increases it, the current highest one wins. The auctioneer has a minimum value it wants to get for the item so if the bid does not reach it, the auction is unsuccessful. 
#### Sealed:
In this case, the auctioneer sends a cfp message to the participants that it is time to bid. After this the guests send a propose message which contains their highest possible offer. The auctioneer picks the bid with the highest offer and notifies the guests about the winner. No multiple rounds, only one bid is available.

An example dutch auction looks like this:\
<i> <sub>Auctioner0 sends the offer of 232 pesos to participants\
Auctioner0 receives reject messages\
Auctioner0 sends the offer of 223 pesos to participants\
Auctioner0 receives reject messages\
Auctioner0 sends the offer of 208 pesos to participants\
Auctioner0 receives reject messages\
Auctioner0 sends the offer of 201 pesos to participants\
Auctioner0 receives reject messages\
Auctioner0 sends the offer of 190 pesos to participants\
Auctioner0 receives reject messages\
Auctioner0 sends the offer of 176 pesos to participants\
Auctioner0 receives reject messages\
Auctioner0 sends the offer of 171 pesos to participants\
Auctioner0 receives reject messages\
Auctioner0 sends the offer of 156 pesos to participants\
Auctioner0 receives reject messages\
Auctioner0 sends the offer of 148 pesos to participants\
Auctioner0 receives reject messages\
Auctioner0 sends the offer of 134 pesos to participants\
Auctioner0 receives <b>accept</b> messages\
Auctioner0 got accepted by Guest(1): \['I, Guest1, accept your offer of 134, merchant.'] </sub></i>

The first picture shows an example sealed bidding. In this case, Auctioneer 3 offers "posh pants" and Guest4 wins the auction.
<img src="https://user-images.githubusercontent.com/31373135/55141614-15ab9f00-513b-11e9-842c-a955e9f55f1a.png" height="350"/>


This picture shows how the merch is visualized. On the left of the picture, we can see a hat, at the bottom a backpack on a passed out guest being dragged by an ambulance, a t-shirt in the middle, next to the InfoCenter and a pair of pants on a bad guest being hunted by the Security.
<img src="https://user-images.githubusercontent.com/31373135/55141612-15ab9f00-513b-11e9-8a35-38582cafdcc2.png" height="350"/>


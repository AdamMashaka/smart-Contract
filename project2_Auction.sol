// SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;

contract AuctionCreator{

Auction[] public auctions;

function createAuction() public{
 Auction  newAuction = new Auction(payable(msg.sender));
 auctions.push(newAuction);
 
}

}

contract Auction{

address payable public owner;

    string public IpfsHash;     //uniquely identifies the info
    uint public startBlock;    //use block number to calculate time
    uint public endBlock;
    

//saving the state of aution
//enum variable implicitly converted to an interger variable
enum State{
    Started,
    Running,
    Ended,
    Cancelled
}

State public auctionState;

mapping(address=>uint) public bids;

uint public HighestBindingBid;    //selling price

bool public ownerFinalized = false;

///@notice payable here -->receive back all the funds,if aution is cancelled or its outbid
address payable public HighestBidder; // addr wins the aution pay for product or service

uint bidIncrement;                           //contract will automatically bid up to given amt in steps of this increment

constructor (address payable EOA){
    owner = EOA;            //owner is declared as payable
    auctionState = State.Running;
    startBlock = block.number;              //assigning current block
    endBlock = startBlock + 40320;              //aution must be valid for a week,so in a week 40320 block wil be generated 
    IpfsHash ="";                           //initalizing with empty string
    bidIncrement = 1000000000000000000;                     //1 ether in wei
}

function getBalance()  onlyOwner public view returns(uint) {
   return address(this).balance;

}
modifier onlyOwner (){                     //function modifier same as normal function using keyword modifier instead of func

 require(owner == msg.sender);    
 _;                                         //owner calls this func, func wil executed otherwise an exception is thrown

}

modifier notOwner (){                     
 require(owner != msg.sender);             //Here not allowing owner to place bid becoz he can increase the price artifically
 _;                                         
}

modifier afterStart (){                     
 require(block.number>=startBlock);             
_;
}

modifier beforeEnd (){                     
 require(block.number<=endBlock);            
_;
}

function cancelAuction() public onlyOwner {        //
    auctionState = State.Cancelled;
}

//func is pure,it neither alters the bc nor it reads from the bc
function min(uint a , uint b)  pure internal returns(uint){      //Helper function
    if(a<=b){
        return a;
    }
    else{
        return b;
    }
}


function placeBid()  payable public notOwner afterStart beforeEnd { 

    require(auctionState == State.Running);
   
    require(msg.value>=1000000000000000000);

//bids[msg.sender] --> value the current user already sent
//msg.value --> the value sent with tis transaction 
//currentBid --> local variable

    uint currentBid = bids[msg.sender] + msg.value;     
 
require(currentBid > HighestBindingBid); 

   bids[msg.sender] = currentBid;                //updating bids variable for current user

   //NOw there are 2 possibilities

   if(currentBid <= bids[HighestBidder]){
//minimum b/w current bid plus bid increment and bids[HighestBidder]
    HighestBindingBid = min(currentBid + bidIncrement,bids[HighestBidder]); //gets error becoz in solidity there is no func that returns the minimum of 2 values,so we using the helper function
   
   }
   else{
    
    HighestBindingBid = min(currentBid ,bids[HighestBidder] + bidIncrement);

//changing highestBidder bcoz currentBidder become highestBidder

    HighestBidder = payable(msg.sender);          //current addr converted to payable one

   }

}

function finalizeAuction()  public{

    require(auctionState == State.Cancelled || block.number > endBlock); //logical ops returns true if any of two condition is true
    require(msg.sender == owner || bids[msg.sender]>0);  // either the owner or bidder can finalize the auction

//finding the addr that wil receive the funds sent in auction

address payable recepient;
uint value;

if (auctionState == State.Cancelled){
    recepient = payable(msg.sender);    //every bidder request and get there own money
    value = bids[msg.sender];           //value the bidder already sent in the auction
}
else{                                   //auction ended

 if (msg.sender == owner && ownerFinalized == false){

recepient = owner;
value = HighestBindingBid;

 }

 else{                                //not owner but bidder who request his own funds

if (msg.sender == HighestBidder){

recepient = HighestBidder;
value = bids[HighestBidder] - HighestBindingBid;

}
 
 else{                               //neither the owner nor the highest bidder
 recepient = payable(msg.sender);    
    value = bids[msg.sender];   

 }

}

}

    ownerFinalized = true;  //the owner can finalize the auction and get the highestBindingBid only once
    bids[recepient] = 0; //resetting the bids of recepient to zero

   recepient.transfer(value);
  
}



}






















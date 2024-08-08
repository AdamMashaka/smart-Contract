// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Lottery{

address payable[] public players;
address public owner;
address payable public winner ;

constructor (){

owner = msg.sender;

  // adding the manager to the lottery
      //   players.push(payable(owner));
        

}
///@notice receive-->without keyword function -->becoz func runs automatically when contract receive ETH
/// players array consist of payable addressed so convert msg.sender to payable(msg.sender)
///Thus by converting plain address to payable one 

receive() external payable{

// the manager can not participate in the lottery
     //   require(msg.sender != owner);
require (msg.value == 0.001 ether);
players.push(payable(msg.sender));

}

function getBalance () public view returns(uint){
   require(owner==msg.sender);
    return address(this).balance;
}


function random() public view returns(uint){
     return uint (keccak256(abi.encodePacked(block.prevrandao,block.timestamp,players.length)));

}

function PickWinner() public {
 
 require(owner == msg.sender,"Transaction fail,You are not the owner");
 require (players.length>=3);

uint r = random();
uint index = r % players.length;


winner = players[index];

uint amount = getBalance();

winner.transfer(amount);

//initalizing players state variable to empty in-m/y dynamic array,zero-->size of new dynamic array
players = new address payable [](0);  //resetting the lottery for next round

}

}






















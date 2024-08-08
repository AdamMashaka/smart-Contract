pragma solidity >=0.8.2 <0.9.0;

contract Ownable{

   address public owner;

   constructor(){
    owner = msg.sender;
   }

   modifier onlyOwner (){                     //function modifier same as normal function using keyword modifier instead of func

 require(isOwner(),"you are not the owner");    
 _;                                         //owner calls this func, func wil executed otherwise an exception is thrown

}

function isOwner() public view returns(bool){
    return (owner == msg.sender);
}
}
pragma solidity >=0.8.2 <0.9.0;

import "./ItemManager.sol";

contract Item {
uint public priceInWei;
uint public pricePaid;
uint public index;
ItemManager public parentContract;

constructor (ItemManager _parentContract,uint _priceInWei,uint _index)  {
priceInWei = _priceInWei;
index = _index;
parentContract = _parentContract;

}
//Here we using receive rather than fallback coz we are sending only money without any msg data populated 
receive() external payable {

require(pricePaid == 0 ,"Item is paid already"); //checking if tis item is paid already
require(priceInWei == msg.value ,"Only full payments allowed"); 
pricePaid += msg.value;
(bool success,)= address(parentContract).call{value:msg.value}(abi.encodeWithSignature("triggerPayment(uint256)",index));
require (success ,"Transaction wasnt successful,canceling..");

}
fallback() external {} 

}
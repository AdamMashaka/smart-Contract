// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract CrowdFunding{

address  public admin;

mapping(address => uint) public contributors;

uint public NoOfContributors;   //Holds number of contributors there are 

uint public minimumContribution; //amt in wei
uint public deadline;            //timestamp
uint public goal;
uint public raisedAmount;        //to know at any moment hw much money the campaign has raised til that point

struct request{
  string description;
  address payable recepient;
  uint value;
  bool completed;  //at begining spending req considered not completed,once contributor voted and payment has done,then marked as completed
  uint NoOfVoters;
  mapping(address => bool) voters;

}
// admin can create more than one spending req
mapping(uint => request) public requests;     //requests variable stores all spending req

//NOte:u cant store the request in dynamic array becoz latest version of solidity,assignment to array in storage dont wrk if they contain mapping
uint public numRequest; //its necessary becoz mapping doesnt use or increment indexes automatically (like array does)


//when these func are called spl structure saved on bc in JS app that listen for the event can update an interface with info such as spending req,the payments  that were made and so on
// events to emit
    event ContributeEvent(address _sender, uint _value);
    event CreateRequestEvent(string _description, address _recipient, uint _value);
    event MakePaymentEvent(address _recipient, uint _value);
    
   

constructor(uint _goal, uint _deadline){          //wil set both goal and deadline of campaign

admin = msg.sender;

//user give the date in human format and front end app wil translate into timestamp
deadline = block.timestamp + _deadline;           //this is current time and deadline in seconds

goal = _goal;

minimumContribution = 100;

}

receive() external payable{

contribute();                 //calling contribute func
}

//usually this is done using front end app and sending Eth with wallet
function contribute()  public payable{           //called when someone wants to send money to contract
    
    require(block.timestamp < deadline, "Deadline has passed");
    require(msg.value >= minimumContribution, "Minimum contribution not met");

 //this is first time this addr sends eth to tis contract,user could send Ether many times to contract bt being a same user we are incrementing only once   
    if(contributors[msg.sender]==0){
    
        NoOfContributors ++;
    }

   contributors[msg.sender] += msg.value;  //adding the value sent with trans to mapping contributors
   raisedAmount +=msg.value;               //adding current value received by contract to total raisedamt 

   emit ContributeEvent(msg.sender, msg.value);
}

function getBalance() public view returns(uint){

   return address(this).balance;

}


//If goal is not reached within the deadline the campaign or project cant be executed successfuly n each user req back money

function getRefund() payable public {
  
  require(block.timestamp > deadline && raisedAmount < goal); //2 cond :deadline of campaign not passed,goal not reached 
  require(contributors[msg.sender]>0); //current addr has already sent money to contract in past,Has +ve balance

  
   address payable recepient = payable(msg.sender);
   uint value = contributors[msg.sender];
  
  contributors[recepient] = 0; //resetting the funds of recepient to zero in mapping variable

   recepient.transfer(value);
   

}


modifier onlyAdmin(){

    require(admin == msg.sender);
    _;
} 

function createRequest(string memory _description,address payable _recepient,uint _value) public onlyAdmin{

//if u dont specify data location or specified as m/y u get error becoz struct contains nested mapping n must declared in storage
 request storage newRequest = requests[numRequest]; //newReq stored in storage and assigned as an element of req mapping
 numRequest++;

newRequest.description = _description;
newRequest.recepient = _recepient;
newRequest.value = _value;
newRequest.completed = false;
newRequest.NoOfVoters = 0;

 emit CreateRequestEvent(_description, _recepient, _value);


}

//spending req saved in mapping and each req has index 
function voting(uint _numRequest) public{

require(contributors[msg.sender] >0,"you must be contributor to vote");

//picking from request mapping the spending req,users votes for 
request storage newRequest = requests[_numRequest]; //contributors vote for request at specific number and saved in storage

require(newRequest.voters[msg.sender]==false , "You have already voted");

newRequest.voters[msg.sender]= true;

newRequest.NoOfVoters++;

}


//called by admin to transfer the money of spending req to suppiler or vendors
function makePayment(uint _numRequest) public onlyAdmin{

require (raisedAmount >= goal); //admin can make a payment only if goal has reached

request storage newRequest = requests[_numRequest];

require(newRequest.completed == false ,"The request has been completed");

require(newRequest.NoOfVoters > NoOfContributors/2); //50% vote for this req

newRequest.recepient.transfer(newRequest.value);

newRequest.completed = true;

emit MakePaymentEvent(newRequest.recepient, newRequest.value);

}


}

























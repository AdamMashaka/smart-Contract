// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
    
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

//state variable name used here are most of them are standard try to follow same
//function with the same names as the public variable will be created 
contract Cryptos is ERC20Interface{
    string public name = 'Cryptos';
    string public symbol = 'CRPT' ;   //Each token or crytocurrency has own symbol like BTC or ETH .usually 3 to 4 character long but no restriction on its size
   
   //decimal value are no.of digits that comes after the decimal place 
    uint public decimal = 0;//18      //It refer to hw divisible the token can be ,in general it range from 0 to 18

    ///notice there is already a func called totalsupply in interface so we must override it using override keyword
    uint public override totalSupply; //represents total no.of tokens,here override keyword required becoz in fact it creates a getter func brcoz variable is public
    
    address public founder ;          //founder and his address that deploys the contract and has all the tokens in first place 
    
    mapping (address => uint) public balances;//In this variable wil be stored the no.of tokens of each addr

//keys (address of token holder =>values are other mapping representing the address that allowed to transfer from holder blc => amt allowed to be transfered)
   mapping (address => mapping(address => uint)) allowed;


constructor (){

    founder = msg.sender;
    totalSupply = 1000000;
    balances[founder] = totalSupply;  //addr wil own the total token supply,once deployed founder wil hv one million token
}


    function balanceOf(address tokenOwner) public view override returns (uint balance){

    return balances[tokenOwner];  //returning blcs of addr
    }

//the founder has all the tokens any other addr to get tokens transfer func should be called

    function transfer(address to, uint tokens) public virtual override returns (bool success){  //func make token transferable
      
 //func should throw it if the sender's account blc does not hv enough tokens to transfer to recepient     
      require(balances[msg.sender] >= tokens); //no.of tokens owner wants to transfer
 
 //NOTE according to std ,transfer of zero values must be treated as normal transfer and fire the transfer event
 //If the recepient  addr called here had no tokens ,the value in mapping  would be zero and value sent wil be added to zero
      balances[to] += tokens; 

//subtracting the sent tokens from sender blc 
    balances[msg.sender] -= tokens;

//after updating the blcs of sender and recepient ,the function should emit an event,this is log msg that is saved on bc

    emit Transfer(msg.sender,to,tokens);

    return true;

//NOTE we hv followed the general guidelines that funcs revert instead of returning false on failure
//On failure of require condition it wil revert and on success it wil return true
    }

//tis func returns hw many tokens hv the token owner allowed the spender to withdraw
    function allowance(address tokenOwner, address spender) public view override returns (uint remaining){

        return allowed[tokenOwner][spender];
    }

//tis func called by tokenowner to set the allowance,which is the amt that can be spent by the spender from his account
    function approve(address spender, uint tokens) public override returns (bool success){

      require(balances[msg.sender] >= tokens);
      require(tokens > 0); 

      allowed[msg.sender][spender] = tokens;  //updating allowed mapping

      emit Approval(msg.sender,spender , tokens); //approval event should be triggered on successful call to approve

//NOte : some implementation also define another 2 func increase approval ,decrease approval ie to increase or decrease the allowance .our func only sets the allowance for a spender to fixed value
     return true;
    }


//tis func allows the spender to withdraw or transfer from the owners account multiple times upto the allowance,tis func also change the current allowance 
//tis func only called by the account that was allowed to transfer tokens from holder account to his own or another account 
   function transferFrom(address from, address to, uint tokens) public virtual override returns (bool success){

  require(allowed[from][msg.sender] >= tokens);
  require(balances[from] >= tokens); 

   balances[from]-=tokens;  //subtracting the tokens from owners blc 

  allowed[from][msg.sender] -= tokens;  //updating allowance of user

  balances[to]+= tokens;  //adding tokens to recepient addr to which spender wants to send money (tis can be any addr)

  emit Transfer(from,to,tokens);

  return true;

   }

}

contract CryptosICO is Cryptos{

address public admin;

//investor wil send Eth to contract addr,ether wil automatically transferred to deposit addr and cryptos added to blc of investor
address payable public deposit; //addr that gets transferred Ether sent to contract 

uint public tokenPrice = 0.001 ether; //1 Eth = 1000 CRPT,1CRPT = 0.001Eth (investor get)

uint public hardCap = 300 ether;

uint public raisedAmount; //holds total amt of ether sent to ICO,value in wei

uint public SaleStart = block.timestamp; //ie it start while deploying if we want to start in one hr means add no of secs in mins like this block.timestamp + 3600 -->ico start in one hr after deployment 

uint public SaleEnd = block.timestamp + 604800; // Ico ends in one week

//common for ICO to lock the tokens for amt of time ,I want the tokens to be transferable only after a time after ico ends so the early investors cant dump the tokens on the market ,causing the price to collapse

uint public tokenTradeStart = SaleEnd + 604800; //transferable in a week after the sales

uint public minInvestment =0.1 ether;

uint public maxInvestment =5 ether;

enum State {                    // These are the possible state of ico
   BeforeStart,
   Running,
   AfterEnd,
   halted
}
State public IcoState;

constructor(address payable _deposit){

    admin = msg.sender;
    deposit = _deposit;                 //deposit addr-> where the ether wil be transfered can also be hardcoded
    IcoState = State.BeforeStart;       //Ico wil start after the deployment not right away

}

///notice : admin can stop the ico in case of emergency eg if deposit addr gets compromised or security vulnerability is found in contract 

modifier onlyAdmin() {

    require(msg.sender == admin);
    _;
}

function halt() public onlyAdmin{     //tis func called only by the admin to stop the ico at any moment,Its a case when somethng bad happens or there is an emergency

   IcoState = State.halted;
}

//admin should be able to restart the ico after the prblm is solved  

function resume() public onlyAdmin{     
   IcoState = State.Running;
}

function changeDepositAddress(address payable newDeposit) public onlyAdmin{     //In tis case when its get compromised and must be changed
   deposit = newDeposit;
}

function getCurrentState() public view returns(State){  //returns the states of ico
   
  if(IcoState == State.halted){
    return State.halted;
    }
    else if(block.timestamp < SaleStart){
        return State.BeforeStart;
    }
    else if (block.timestamp>=SaleStart && block.timestamp<=SaleEnd){
         return State.Running;
    }
  else{
    return State.AfterEnd;     //ICO ended
  }

}

event Invest(address investor , uint value,uint tokens);
//tis is main func of ico and investor can buy cryptos by calling tis func using front end app and sending it with wallet or sending eth directly to ICO addr 
//tis func called when somebody sends eth to contract and receives cryptos in turn
function invest() payable public returns(bool){

   IcoState = getCurrentState();

   require(IcoState == State.Running);

   require(msg.value >= minInvestment && msg.value <= maxInvestment);
   
   raisedAmount += msg.value;
  
  require(raisedAmount <= hardCap);

  //calculate the no of tokens the user get for the ether he has sent

uint tokens = msg.value / tokenPrice;  //divide the number of wei the user has sent by the token price in wei

balances[msg.sender] += tokens;  //blcs is mapping variable declared in erc20 token contract and inherited by ICO contract
balances[founder] -= tokens;

//transfer to deposit addr the amt of wei sent to the contract 

deposit.transfer(msg.value);

//emitting an event which is log msg written to bc that can be processed by front ends 

emit Invest(msg.sender,msg.value,tokens);

return true;

}

receive() external payable{         //tis func automatically called when somebody sends eth directly to contract addr

invest();

}

 function transfer(address to, uint tokens) public  override returns (bool success){

 require(block.timestamp > tokenTradeStart); //so current trans date is greater than tokentradestart

//calling the transfer func of base contract called cryptos 

Cryptos.transfer(to,tokens);

return true;

 }



 function transferFrom(address from, address to, uint tokens) public  override returns (bool success){
require(block.timestamp > tokenTradeStart); //so current trans date is greater than tokentradestart

//calling the transfer func of base contract called cryptos 

super.transferFrom(from,to,tokens); //same as Cryptos.transfer instead cryptos name we using super

return true;
 }

// burning unsold tokens
function burn() public returns (bool){       //func can be called by anyone ,not only by admin 

IcoState = getCurrentState();               //current state of ICO,token wil be burned only after the ICO ends 
 
require(IcoState == State.AfterEnd);

balances[founder] = 0;                     //tokens hv just vanished 

return true;

//there is no code in the contract that could create the tokens again 
}




}



















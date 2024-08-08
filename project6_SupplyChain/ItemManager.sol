pragma solidity >=0.8.2 <0.9.0;

import "./Ownable.sol";
import "./Item.sol"; 

contract ItemManager is Ownable{

    enum SupplyChainState {created,paid,delivered}

    struct S_Items{
        Item item;                      //create item in our struct space
        string identifier;
        uint price;
        SupplyChainState State;

    }

event SupplyChainStep(uint _itemIndex,uint _step,address _itemAddress);

  mapping (uint => S_Items) public Items;
     uint itemIndex;

     
    function createItem (string memory _identifier,uint _price) onlyOwner public{
         Item _item = new Item(this,_price,itemIndex);
         Items[itemIndex].item = _item;
            Items[itemIndex].identifier = _identifier;
            Items[itemIndex].price = _price;
          Items[itemIndex].State = SupplyChainState.created;
          emit SupplyChainStep(itemIndex,uint(Items[itemIndex].State),address(_item));
          itemIndex++;
    }

    function triggerPayment (uint _itemIndex) payable public{
require(Items[_itemIndex].price == msg.value ,"Only full payment is accepted");
require(Items[_itemIndex].State == SupplyChainState.created);


Items[_itemIndex].State = SupplyChainState.paid;

emit SupplyChainStep(_itemIndex,uint(Items[_itemIndex].State),address(Items[_itemIndex].item));

    }

    function triggerDelivery (uint _itemIndex) onlyOwner public{
      require(Items[_itemIndex].State == SupplyChainState.paid);

Items[_itemIndex].State = SupplyChainState.delivered;  

emit SupplyChainStep(_itemIndex,uint(Items[_itemIndex].State),address(Items[_itemIndex].item));
        
    }
}
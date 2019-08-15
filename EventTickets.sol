pragma solidity ^0.5.0;

    /*
        The EventTickets contract keeps track of the details and ticket sales of one event.
     */

contract EventTickets {
     
    address payable owner;
    uint   TICKET_PRICE = 100 wei;
    
    struct Event {
        string description;
        string website;
        uint totalTickets;
        uint sales;
        mapping (address => uint) buyers;
        bool isOpen;
    }

    Event myEvent;

    event LogBuyTickets (address purchaser, uint ticket);
    event LogGetRefund (address refundRequester, uint ticket);
    event LogEndSale (address contractOwner, uint balance);

    modifier OnlyOwner{
        require(owner == msg.sender, "you are not the owner");
        _;
    }
    
    constructor (string memory _description, string memory _URL, uint _totalTickets) public {
        owner = msg.sender;
        myEvent.description = _description;
        myEvent.website = _URL;
        myEvent.totalTickets = _totalTickets;
        myEvent.sales = 0;
        myEvent.isOpen = true;
    }

    function readEvent() view
        public
        returns(string memory description, string memory website, uint totalTickets, uint sales, bool isOpen)
    {
        return (myEvent.description, myEvent.website, myEvent.totalTickets, myEvent.sales, myEvent.isOpen);
    }

    function getBuyerTicketCount(address _buyer) public view  returns(uint){
        return (myEvent.buyers[_buyer]);
    }

    function buyTickets(uint _tickets) payable public {
        require(myEvent.isOpen == true, "The event is not open yet");
        require(msg.value >= (_tickets*TICKET_PRICE), "Not enough transaction value");
        require(myEvent.totalTickets >= _tickets, "Not enough tickets available");
        
        myEvent.sales += _tickets;
        myEvent.buyers[msg.sender] += _tickets;
        myEvent.totalTickets -= _tickets;
        
        if(msg.value > (_tickets*TICKET_PRICE)){
            uint change = msg.value - (_tickets*TICKET_PRICE);
            msg.sender.transfer(change);
        }
        
        emit LogBuyTickets(msg.sender, _tickets);
    }

    function getRefund() payable public returns(uint, uint) {
        require(myEvent.buyers[msg.sender] != 0, "You have not purchased any tickets.");
        
        uint refund;
        uint refundPrice;
        
        myEvent.totalTickets += refund;
        myEvent.buyers[msg.sender] = 0;
        
        refundPrice = refund*TICKET_PRICE;
        msg.sender.transfer(refundPrice);
        
        emit LogGetRefund(msg.sender, refund);
        
        return(refund, refundPrice);
    }

    function endSale() public OnlyOwner {
        myEvent.isOpen = false;
        
        owner.transfer(address(this).balance);
        
        emit LogEndSale(owner, address(this).balance);
    }
}
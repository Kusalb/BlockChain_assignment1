pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    address payable owner;
    uint   PRICE_TICKET = 100 wei;
    
    constructor () public {
        //creator of the contract is the owner
        owner = msg.sender;
    }

    uint public eventCount = 0;
    uint public idGenerator = 0;

    struct Event {
        string description;
        string website;
        uint totalTickets;
        uint sales;
        mapping (address => uint) buyers;
        bool isOpen;
    }

    mapping (uint => Event) events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier onlyOwner {
        require(owner == msg.sender, "You are not the owner.");
        _;
    }
    Event myEvent;
    function addEvent(string memory _description, string memory _URL, uint _tickets) public onlyOwner returns(uint) {
        myEvent.description = _description;
        myEvent.website = _URL;
        myEvent.totalTickets = _tickets;
        myEvent.isOpen = true;
        
        //calculating event ID
        idGenerator++;
        events[idGenerator] = myEvent;
        eventCount++;
        
        emit LogEventAdded(_description,_URL,_tickets,idGenerator);
        
        return(idGenerator);
    }

    function readEvent(uint _id) public view returns(string memory, string memory, uint, uint, bool) {
        return (events[_id].description,events[_id].website, events[_id].totalTickets, events[_id].sales, events[_id].isOpen);
    }

    function buyTickets(uint _eventID, uint _tickets) payable public {
        require(events[_eventID].isOpen == true, "The event is not yet open.");
        require(msg.value >= (_tickets*PRICE_TICKET), "Not enough value");
        require(events[_eventID].totalTickets >= _tickets,"Out of stock.");
        
        events[_eventID].buyers[msg.sender] += _tickets;
        events[_eventID].sales += _tickets;
        events[_eventID].totalTickets -= _tickets;
        
        if(msg.value > (_tickets*PRICE_TICKET)) {
            uint change = msg.value-(_tickets*PRICE_TICKET);
            msg.sender.transfer(change);
        }
        
        emit LogBuyTickets(msg.sender, _eventID, _tickets);
    }

    function getRefund(uint _eventID) payable public {
        require(events[_eventID].buyers[msg.sender] != 0, "You have not bought any tickets.");
        
        uint refund = events[_eventID].buyers[msg.sender];
        uint refundValue = refund*PRICE_TICKET;
        
        events[_eventID].totalTickets += refund;
        
        msg.sender.transfer(refundValue);
        
        emit LogGetRefund(msg.sender, _eventID, refund);
    }

    function getBuyerNumberTickets(uint _eventID) public view returns(uint) {
        return events[_eventID].buyers[msg.sender];
    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint _eventID) public onlyOwner {
        events[_eventID].isOpen = false;
        
        owner.transfer(address(this).balance);
        
        emit LogEndSale(owner, address(this).balance, _eventID);
    }
}
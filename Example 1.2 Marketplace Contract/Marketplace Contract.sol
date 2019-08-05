pragma solidity >=0.5.1 <0.6.0;

/** @title Marketplace */
contract Marketplace {                                              // Declaration of Auction contract
    
    address owner;                                                  // Specifies the owner of the contract
    uint servicePrice;                                              // Set price for the service
    uint timeStamp;                                                 // Sets the time for the service buy
    uint maximumWithdraw;                                           // Maximum withdraw amount for the contract
    uint lastWithdraw;                                              // Sets the last time a withdraw has been made
    
    mapping(address => uint) balances;
    
    event ServiceBought(address buyer);
    event ReturnExcess(uint amount);
    
    constructor() public {
        owner = msg.sender;
        servicePrice = 1 ether;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can execute this function.");
        _;
    }
    modifier onlyNotOwner() {
        require(msg.sender != owner, "The owner is not allowed to bid.");
        _;
    }
    modifier timeRestriction {
        require((timeStamp + 2 minutes) < now, "2 minutes must pass after someone bought the service. Please wait.");
        _;
    }
    modifier withdrawLock() {
        require(maximumWithdraw <= 5 ether && lastWithdraw + 1 hours < now, 
        "You can only withdraw once per hour and a maximum of 5 ETH.");
        _;
    }
    
    /** @dev                    Buy service function. 
     *                          Msg.value must me minimum 1 ether.
     *                          Contract owner is not allowed to buy the service.
     *                          There is a time restriction of 2 minutes after someone buys the service.
     *                          If more than 1 ETH is sent to buy the function the excess is sent back to the buyer.
     */
    function buyService() 
    public 
    payable 
    onlyNotOwner 
    timeRestriction 
    {
        require(msg.value >= servicePrice, "Service price is 1 ETH.");
        timeStamp = now;
        if(msg.value > servicePrice) {
            uint excess = msg.value - servicePrice;
            balances[msg.sender] = excess;
            msg.sender.transfer(excess);
            
            emit ReturnExcess(excess);
        }
        
        emit ServiceBought(msg.sender);
    }
    /** @dev                    Withdraw fucntion
     *                          Only owner is allowed to withdraw once per hour with a maximum of 5 ETH.
     */ 
    function withdraw() 
    public 
    onlyOwner 
    withdrawLock 
    {
        uint contractBalance = address(this).balance;
        msg.sender.transfer(contractBalance);
        lastWithdraw = now;
    }
    /** @dev                    Fallback function
     */
    function() external {
        revert();
    }
}
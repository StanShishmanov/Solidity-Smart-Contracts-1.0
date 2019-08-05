pragma solidity >=0.5.1 <0.6.0;

/** @title Auction */
contract Auction {                                              // Declaration of Auction contract
    
    address owner;                                              // Specifies the owner of the contract
    address highestBidder;                                      // Current address of the highest bidder
    uint highestBid;                                            // Current amount of the highest bid   
    uint bidMargin;                                             // Current minimum bid
    uint startTime;                                             // Starting time of the auction
    uint endTime;                                               // Expiry time of the auction
    bool canceled;                                              // Determines whether the contract is canceled or not
    
    mapping(address => uint) balances;                          // Keeps track of all bidders' balances
    mapping(address => bool) isBidder;                          // Keeps track whether an address is a bidder
    mapping(address => uint) lastBidTime;
    
    
    event BidPlaced(address bidder, uint bid);                   
    event AuctionCanceled(string cancel);
    event Withdraw(address bidder, uint amount);
    
    /** @dev                        Sets the owner of the contract
     *                              
     *  @param _startTime           Sets the starting time of the auction
     *  @param _endTime             Sets the expiry time of the auction
     *  @param _bidMargin           Sets the margin of the bids
     */
    constructor(uint _startTime, uint _endTime, uint _bidMargin) public {
        owner = msg.sender;
        startTime = _startTime;
        endTime = _endTime;
        bidMargin = _bidMargin;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can execute this function.");
        _;
    }
    modifier onlyNotOwner() {
        require(msg.sender != owner, "The owner is not allowed to bid.");
        _;
    }
    modifier notCanceled() {
        require(!canceled, "The auction has been canceled by the owner.");
        _;
    }
    modifier notExpired() {
        require(endTime >= now, "This auction has expired.");
        _;
    }
    modifier expiredOrCanceled() {
        require(canceled || endTime < now, "This auction has been canceled or has expired.");
        _;
    }
    modifier minimumEntry {
        require(msg.value >= bidMargin + highestBid, "Minimum entry should be greater than the bid margin + the highest bid.");
        _;
    }
    modifier timeRestriction() {
        require(lastBidTime[msg.sender] + 1 minutes < now , "There is a 1 hour time restriction after a successful bid.");
        _;
    }
    
    /** @dev                Places a bid. The bid should be greater than zero and than the highest bid.
     *                      The owner is not allowed to place bids.
     *                      Bidders are only allowed to bid once per hour.
     *                      There is a minimum entry consisted of the bid margin plus the highest bid.
     */
    function placeBid() 
    public 
    payable 
    notCanceled 
    notExpired 
    onlyNotOwner
    minimumEntry
    timeRestriction
    {
        require(msg.value > 0 wei, "Bid should be greater than 0.");
        highestBid = msg.value;
        highestBidder = msg.sender;
        lastBidTime[msg.sender] = now;
        if (!isBidder[msg.sender]) {
            isBidder[msg.sender] = true;
            balances[msg.sender] += msg.value;
        }
        
        emit BidPlaced(msg.sender, msg.value);
    }
    
    /** @dev                        Checks the highest bid and highest bidder.
     *  @return _highestBidder      Returns the address of the highest bidder.
     *  @return _highestBid         Returns the highest bid amount.
     */
    function checkHighestBidAndBidder() 
    public 
    view 
    returns(address _highestBidder, uint _highestBid) 
    {
        return (highestBidder, highestBid);
    }
    
    /** @dev                Only the contract owner is able to cancel the auction.
     */
    function cancelAuction() 
    public 
    onlyOwner 
    {
        canceled = true;

        emit AuctionCanceled("This auction has been canceled by the owner.");
    } 
    
    /** @dev                Withdraw function favoring pull vs push.
     *                      All bidders should be able to withdraw their bids if auction was canceled.
     *                      All bidders but the highest bidder should be able to 
     *                      withdraw their bids if auction has expired.
     *                      Owner should be able to withdraw the highest bid if the auction has expired.
     *  @param _amount      The amount to be withdrawn
     *  @return _balance    Returns the remaining balance of the bidder.            
     */
    function withdraw(uint _amount) 
    public 
    expiredOrCanceled 
    returns (uint _balance)
    {
        require(balances[msg.sender] >= _amount || msg.sender == owner, "Not enough balance.");
        if (canceled) {
            balances[msg.sender] -= _amount;
            msg.sender.transfer(_amount);
        } else if (!canceled && endTime < now) {
            if (msg.sender == owner) {
                _amount = highestBid;
                highestBid = 0;
                balances[highestBidder] -= _amount;
                msg.sender.transfer(_amount);
            } else {
            require(msg.sender != highestBidder, "You have won the auction therefore you cannot withdraw your funds");
            balances[msg.sender] -= _amount;
            msg.sender.transfer(_amount);
            }
        } 
        return balances[msg.sender];
        
        emit Withdraw(msg.sender, _amount);
    }
    /** @dev       Fallback function
     */
    function() external payable {
        revert();
    }
}
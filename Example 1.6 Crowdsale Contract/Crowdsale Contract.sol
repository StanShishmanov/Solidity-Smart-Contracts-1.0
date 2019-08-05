pragma solidity >=0.5.1 <0.6.0;
/** @title Crowdsale */
contract Crowdsale {                                                // Declaration of Crowdsale contract
    
    address payable owner;                                          // Specifies the owner of the contract
    uint crowdsaleStart;                                            // Specifies contract starting time
    uint minimum = 1 ether;                                         // Specifies minimum investment
    uint tokens;                                                    // Value for sold tokens
    
    enum State {Crowdsale, OpenExchange}                            // Contract state enumerator
    
    State crowdsaleState;
    
    mapping(address => uint) public balances;                       // Keeps track of users' tokens balances
    
    mapping(address => bool) public heldTokens;                     // Keeps track of who owns or owned tokens
    
    address[] tokenOwners;                                          // A list with all token owners' addresses
    
    event LogTokenBought(address user, uint totalTokens, uint time);
    event LogTokenTransfer(address _from, address _to, uint tokens);
    event LogOwnerWithdrawal(uint _amount, uint time);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can execute this function.");
        _;
    }
    modifier onlyRound() {
        require(msg.value%minimum == 0, "Only round numbers are accepted.");
        _;
    }
    modifier minimumInvestment() {
        require(msg.value >= 1 ether, "Minimum investment is 1 ETH");
        _;
    }
    
    modifier ownerWithdrawLimit() {
        require(msg.sender == owner, "Only contract owner can execute this function.");
        require(now > (crowdsaleStart + 365 days), 
        "Dear owner, you are allowed to withdraw after 1 year since the beginning of the crowdsale. Be patient.");
        _;
    }
    
    modifier TransferOpen() {
        require((crowdsaleStart + 5 minutes) < now, "Transfer is allowed 5 minutes after crowdsale has started.");
        _;
    }
    /** @dev                Sets the owner of this contract
     *                      Sets the contract starting time
     *                      Sets the contract starting state
     */
    constructor() public {
        owner = msg.sender;
        crowdsaleStart = now;
        crowdsaleState = State(0);
    }
    
    /** @dev                Function for buying tokens. 
     *                      Minimum investment is 1 ether.
     *                      If contract state is at Crowdsale, buyers get 5 tokens for each 1 ether they send.
     *                      If contract state is at OpenExchange, 1 ether equals 1 token.
     *                      Buyers must specify only round numbers when buying tokens.
     */
    function buyTokens() public payable minimumInvestment onlyRound {
        if((crowdsaleStart + 5 minutes) > now) {
            tokens = 5 * msg.value;
            balances[msg.sender] += tokens;
            if(!heldTokens[msg.sender]) {
                heldTokens[msg.sender] = true;
                tokenOwners.push(msg.sender);
            }
        } else {
            crowdsaleState = State(1);
            tokens = msg.value;
            balances[msg.sender] += tokens;
            if(!heldTokens[msg.sender]) {
                heldTokens[msg.sender] = true;
                tokenOwners.push(msg.sender);
            }
        }
        emit LogTokenBought(msg.sender, tokens, now);
    } 
    
    /** @dev                Funtion to show all time token owners.
     *  @return             Returns an array of all token owners.
     */
    function getTokenHolders() public view onlyOwner returns (address[] memory) {
        return tokenOwners;
    }
    
    /** @dev                Transfer tokens function.
     *                      Token owners are allowed to use this function 5 minutes after the crowdsale has started.
     *  @param _to          The address which shall receive the tokens.
     *  @param _amount      Amount of tokens to be transfered.
     */
    function transferTokens(address _to, uint _amount) public TransferOpen {
        require(balances[msg.sender] >= _amount, "Amount should be equal or less than the balance of this contract.");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        
        emit LogTokenTransfer(msg.sender, _to, _amount);
    }
    
    /** @dev                Withdraw function.
     *                      Only owner is allowed to use it and only after 365 since the start of the crowdsale.
     *  @param _amount      Amount of ether the owner would like to withdraw.
     */
    function withdraw(uint _amount) public ownerWithdrawLimit {
        require(_amount <= address(this).balance);
        address myAddress = address(this);
        uint etherBalance = myAddress.balance;
        uint amountToTransfer = etherBalance - _amount;
        owner.transfer(amountToTransfer);
        
        emit LogOwnerWithdrawal(amountToTransfer, now);
    }
    
    /** Fallback function */
    function() external payable {
        revert();
    }
}
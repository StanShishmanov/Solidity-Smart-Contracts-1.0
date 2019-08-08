pragma solidity >=0.5.1 <0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";
/** @title ICO Contract */
contract ICO {
    
    using SafeMath for uint256;
    
    event LogBoughtTokens(address _buyer, uint256 amount);
    event LogTransfer(address _from, address _to, uint256 amount);
    
    enum Stages { Presale, ICOSale, SaleEnded }
    
    address owner;                                              // Contract owner
    bool initialized;                                           // Used to initialize the contract
    uint256 tokenPrice;                                         // Price of token
    uint256 ICOStart;                                           // Keeps track of ICO start time
    Stages stage;
    
    mapping(address => uint256) public tokenBalances;           // Token balances of buyers
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier runningICO() {
        if (now > ICOStart + 1 minutes) {
            stage = Stages.SaleEnded;
        } else if (now > ICOStart + 30 seconds) {
            stage = Stages.ICOSale;
            tokenPrice = 2 ether;
        }
        require(stage == Stages(0) || stage == Stages(1), "Presale and ICO has ended.");
        _;
    }
    
    modifier endedICO() {
        if (now > ICOStart + 1 minutes) {
            stage = Stages.SaleEnded;
        } else if (now > ICOStart + 30 seconds) {
            stage = Stages.ICOSale;
            tokenPrice = 2 ether;
        }
        require(stage == Stages(2), "Presale or ICO has not ended.");
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    /** Initialization function */
    function init() public onlyOwner {
        require(owner == msg.sender);
        require(!initialized);
        stage = Stages.Presale;
        tokenPrice = 1 ether;
        ICOStart = now;
        initialized = true;
    }
    /** Buy tokens function. Can only be called if the current contract 
     *  stage is either at "Presale" or "ICOSale". 
     *  During "Presale" stage 1 token costs 1 ether.
     *  During "ICOSale" stage 1 token costs 2 ether.
     */
    function buyTokens() public payable runningICO {
        if (stage == Stages.Presale) {
            require(msg.value >= 1 ether, 
            "Minimum entry for presale stage is 1 ether. Only round numbers are accepted.");
            tokenBalances[msg.sender] = tokenBalances[msg.sender].add(msg.value);
            
            emit LogBoughtTokens(msg.sender, msg.value);
            
        } else if (stage == Stages.ICOSale) {
            require(msg.value >= 2 ether, 
            "Minimum entry for ICO stage is 2 ethers. Only round numbers are accepted.");
            tokenBalances[msg.sender] = tokenBalances[msg.sender].add(msg.value.div(2));
            
            emit LogBoughtTokens(msg.sender, msg.value);
        }
    }
    
    /** @dev Token transfer function. 
     * Can only be used if the current contract stage is at "SaleEnded".
     * 
     * @param _account      The address towards the tokens will be transfered.
     * @param _amount       The amount of tokens to be transfered.
     */
    function transfer(address _account, uint256 _amount) public endedICO {
        require(tokenBalances[msg.sender] > 0, "You have no funds to withdraw.");
        
        tokenBalances[msg.sender] = tokenBalances[msg.sender].sub(_amount);
        tokenBalances[_account] = tokenBalances[_account].add(_amount);
        
        emit LogTransfer(msg.sender, _account, _amount);
    }
    
}
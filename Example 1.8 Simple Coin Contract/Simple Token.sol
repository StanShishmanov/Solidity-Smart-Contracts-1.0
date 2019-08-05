pragma solidity >=0.5.1 <0.6.0;
/** @title  SimpleToken Contract */
contract SimpleToken {                                          // Contract title
    address owner;                                              // Creator and owner of the contract
    
    string myToken = "myToken";                                 // Token name
    string tokenSymbol = "MT";                                  // Token symbol
    uint tokenDecimals = 2;                                     // Token decimal value
    uint totalSupply;                                           // Token total supply
    
    mapping(address => uint) public balances;                   // Mapping, keeps track of users' token balances
    
    event LogTransfer(address _from, address _to, uint _amount);
    event LogPenalty(address _who);
    
    /** @dev                Constructor function. 
     *                      Assigns msg.sender as the contract owner.
     *                      Assigns the token's total supply to the contract owner.
     */
    constructor(uint _totalSupply) public {
        owner = msg.sender;
        totalSupply = _totalSupply / 10**tokenDecimals;
        balances[owner] = totalSupply;
    }
    
    /** @dev                Transfer token function.
     * 
     *  @param _to          The address that will receive the tokens
     *  @param _amount      The amount of tokens to be transfered.
     */
    function transferToken(address _to, uint _amount) public {
        require(balances[msg.sender] >= _amount, "You do not have enough tokens.");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        
        emit LogTransfer(msg.sender, _to, _amount);
    }
    
    /**                     Penalizer function. 
     *                      Consumes all gas of whoever tries to send gas to the contract. 
     */
    function() external {
        assert(false);
        
        emit LogPenalty(msg.sender);
    }
}
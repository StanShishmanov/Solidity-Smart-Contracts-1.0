pragma solidity >=0.5.1 <0.6.0;
/** @title */
contract Ownership {                                                    // Declaration of Ownership contract
    
    address owner;                                                      // Specifies the owner of the contract
    address newOwner;                                                   // Specifies the new owner of the contract
    uint timer = now;                                                   // Keeps track of time
    
    event ChangeOfOwnership(address lastOwner, address newOwner);
    event Transaction(address sender, uint value);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    /** @dev                            Sets the owner of the contract */
    constructor() public {
        owner = msg.sender;
    }
    
    /** @dev                            Changes the current contract owner
     *  @param _newOwner                Takes the address of the new owner.
     */
    function changeOwner(address _newOwner) 
    public 
    onlyOwner 
    {
        address lastOwner = owner;
        newOwner = _newOwner;
        timer = now + 30 seconds;
        emit ChangeOfOwnership(lastOwner, _newOwner);
    }
    
    /** @dev                            Accepts the new owner's address and replaces it with the old owner's address
     *                                  Checks the current time limit ( 30 seconds)
     */
    function acceptOwnership() 
    public 
    {
        require(timer >= now);
        require(msg.sender == newOwner);
        owner = newOwner;
    }
    /** @dev Fallback function */
    function () external payable {
        emit Transaction(msg.sender, msg.value);
    }
}
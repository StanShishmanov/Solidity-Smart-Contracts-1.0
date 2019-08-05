pragma solidity >=0.5.1 <0.6.0;

/** @title State Contract */
contract StateContract {                                                // Declaration of Auction contract
    
    address owner;                                                      // Specifies the owner of the contract
    uint counter;                                                       // Keeps track of the structs
    enum ContractState {Locked, Unlocked, Restricted}                   // Enumerator for changing the contract state
    
    ContractState public newState = ContractState.Unlocked;
    
    struct MyStructure {                                                
        address user;                                                   // Address of the user
        uint counter;                                                   // Used to increment the number of structures
        uint timestamp;                                                 // Keeps track of time
    }
    mapping (uint => MyStructure) public structs;                       // A mapping of the structures count and the structures
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, 
        "Only the contract owner is allowed to execute this function at the moment.");
        _;
    }
    
    /** @dev                    Sets the state of the Contract State
     *                          Only the contract owner is allowed to change the state
     *  @return                 Returns the current state of the contract
     */
    function setState(uint num) public onlyOwner returns (ContractState currentState) {
        require(num == 0 || num == 1 || num == 2, "Number should be 0, 1 or 2.");
        if(num == 0) {
            newState = ContractState.Locked;
        } else if (num == 1) {
            newState = ContractState.Unlocked;
        } else {
            newState = ContractState.Restricted;
        }
        return newState;
    }
    
    /** @dev                    Sets a new structure
     *                          Checks whether the contract state is locked, unlocked or restricted.
     */
    function setStructure() public {
        if (newState == ContractState(0)) {
            revert();
        } else if (newState == ContractState(2)) {
            require(msg.sender == owner);
            counter++;
            MyStructure memory structure = MyStructure(msg.sender,counter, now);
            structs[counter] = structure;
        } else {
            counter++;
            MyStructure memory structure = MyStructure(msg.sender,counter, now);
            structs[counter] = structure;
        }
        
    }
    /** Fallback function */
    function() external {
        revert();
    }
}
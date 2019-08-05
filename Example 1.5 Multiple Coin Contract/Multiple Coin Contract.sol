pragma solidity >=0.5.0 <0.6.0;

/** @title MultipleCoins */
contract MultipleCoins {                                            // Declaration of MultipleCoins contract
    
    address public owner;                                           // Specifies the owner of the contract
    
    struct MultiCoins {                                             // A struct holding all coin types
        uint RedCoin;
        uint GreenCoin;
        uint BlueCoin;
        uint YellowCoin;
    }
    
    mapping(address => MultiCoins) balances;                        // Mapping to hold all users' balances 
    
    /** @dev                Sets the contract owner
     *                      Sets the owner's coin balances
     */
    constructor() public {
        owner = msg.sender;
        balances[owner].RedCoin = 10000;
        balances[owner].GreenCoin = 10000;
        balances[owner].BlueCoin = 10000;
        balances[owner].YellowCoin = 10000;
    }
    
    /** @dev                Function to send coins to other addresses.
     *                      
     *  @param _coin        Checks which coin to transfer
     *  @param _amount      The amount of coins to transfer
     *  @param _account     The addres to receive the coins
     */ 
    function sendCoins(uint _coin, uint _amount, address _account) public {
        require(_coin >= 0 && _coin <= 3);
        
        if(_coin == 0) {
            require(balances[msg.sender].RedCoin >= _amount);
            balances[msg.sender].RedCoin -= _amount;
            balances[_account].RedCoin += _amount;
        } else if(_coin == 1) {
            require(balances[msg.sender].GreenCoin >= _amount);
            balances[msg.sender].GreenCoin -= _amount;
            balances[_account].GreenCoin += _amount;
        } else if(_coin == 2) {
            require(balances[msg.sender].GreenCoin >= _amount);
            balances[msg.sender].BlueCoin -= _amount;
            balances[_account].BlueCoin += _amount;
        } else if(_coin == 3) {
            require(balances[msg.sender].GreenCoin >= _amount);
            balances[msg.sender].YellowCoin -= _amount;
            balances[_account].YellowCoin += _amount;
        }
    }
}
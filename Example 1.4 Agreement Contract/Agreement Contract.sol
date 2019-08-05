pragma solidity >=0.5.1 <0.6.0;

/** @title Agreement */
contract Agreement {                                            // Declaration of Agreement contract
    
    address[] public owners;                                    // A list to hold all owners' addresses
    uint counter = 0;                                           // Counter used to count the number of owners in functions.
    
    struct Proposal {
        uint amount;
        address payable account;
        uint atTime;
    }
    
    Proposal public proposal;
    
    event NewProposalMade(uint amount, address towardsAddress, uint time);
    event ProposalAccepted(uint amountSent, address towardsAddress);
    
    modifier canPropose {
        for(uint i = 0; i <= owners.length; i++) {
            if(owners[i] == msg.sender) {
                _;
                break;
            }
        }
    }
    /** @dev                Constructor function.
     * 
     *  @param _owners      Sets all contract owners.
     */
    constructor(address[] memory _owners) public {
        owners = _owners;
    }
    
    /** @dev                An owner makes a proposal.
     *  
     *  @param _amount      The proposed amount to be sent if all owners aggree on the proposal.
     *  @param _account     The proposed address which will receive the proposed amount.
     */
    function propose(uint _amount, address payable _account) public payable canPropose {
        proposal = Proposal(_amount, _account, now);
        counter = 0;
        
        emit NewProposalMade(_amount, _account, now);
    }
    
    /** @dev                Accepts a proposal. 
     *                      Every owner must accept in the order he was defined in the constructor.
     *                      Must be accepted by all owners within 5 minutes after a proposal has been made.
     *                      If all aggree, a transfer with the proposed amount is sent towards the proposed address.
     */
    function acceptProposal() public canPropose {
        require(owners[counter] == msg.sender);
        require(now <= proposal.atTime + 5 minutes);
        counter++;
        
        if(counter == owners.length) {
            proposal.account.transfer(proposal.amount);
            
            emit ProposalAccepted(proposal.amount, proposal.account);
        }
    }
    /** Fallback function*/ 
    function() external payable {}
}
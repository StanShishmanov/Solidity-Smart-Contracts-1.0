pragma solidity >=0.5.1 <0.6.0;

/** @title Voting Library */
library Voting {
    
    event VotingEnded(address _account);
    
    struct Member {                                         
        uint importance;                                                // Level of importance
        address adr;                                                    // Member address
    }
    
    struct Maps {
        uint totalImportance;                                           // Sum of importance levels
        uint totalVotes;                                                // Sum of all votes
        mapping(address => Member) members;                             // Keeps track of all members
        mapping(address => bool) isMember;                              // Checks whether an address is a member
        mapping(address => uint) proposedAccount;                       // Addresses proposed by the owner
        mapping(address => bool) canWithdraw;                           // Locks/Unlocks withdrawal for an account
        mapping(address => mapping(address => bool)) hasVoted;          // Keeps track of which member has voted.
    }
    
    /** @dev                        A proposal for an account. Can be made only by the owner.
     *
     *  @param _account             The proposed address.
     */
    function proposeAccount(Maps storage _self, address _account) internal {
        _self.proposedAccount[_account] = msg.value;
    }
    
    /** @dev                        Voting function.
     *
     *  @param _account             The address to be voted for.
     */
    function voting(Maps storage _self, address _account) internal {
        uint totVot;
        totVot += _self.members[msg.sender].importance;
        _self.totalVotes += totVot;
        _self.hasVoted[_account][msg.sender] = true;
        if (_self.totalVotes > _self.totalImportance / 2) {
            _self.canWithdraw[_account] = true;
            _self.totalVotes = 0;
            
            emit VotingEnded(_account);
        }
    }
}


contract FundDistribution {

    event AccountProposed(address _account, uint _amount);
    event LogWithdrawal(address _account, uint amount);

    using Voting for Voting.Member;
    using Voting for Voting.Maps;                                                
    
    Voting.Member Member;
    Voting.Maps Maps;
    
    bool initialized;                               // Keeps track of initialized contract
    address owner;                                  // Contract owner address
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyMember() {
        require(Maps.isMember[msg.sender], "You are not a member.");
        _;
    }
    
    /** @dev                Initialization function.
     * 
     *  @param addresses    The addresses which the owner must enter.
     */
    function init(address[] memory addresses) public {
        require(owner == msg.sender, "You are not the contract owner.");
        require(!initialized, "This contract has already been initialized.");
        uint totImp;
        for(uint i = 0; i < addresses.length; i++) {
            Maps.members[addresses[i]] = Voting.Member(i , addresses[i]);
            Maps.isMember[addresses[i]] = true;
            totImp += i;
            
        }
        Maps.totalImportance = totImp;
        initialized = true;
    }
    
    /** @dev    Proposal function. Uses the Voting Lib's proposeAccount function*/
    function makeProposal(address _account) public payable {
        require(msg.sender == owner, "Only owner can make a proposal.");
        require(msg.value > 0 ether, "Amount should be greater than 0 ether.");
        Maps.proposeAccount(_account);
        
        emit AccountProposed(_account, msg.value);
    }
    
    /** @dev    Voting function. the Voting Lib's voting function*/
    function vote(address _account) public onlyMember {
        require(!Maps.hasVoted[_account][msg.sender], "You have already voted for this account.");
        Maps.voting(_account);
        
    }
    
    /** @dev    Withdrawal function. Favors push over pull pattern. */
    function withdrawRefund() public {
        require(Maps.canWithdraw[msg.sender], "You are not allowed to withdraw.");
        require(Maps.proposedAccount[msg.sender] > 0, "You have no funds to withdraw.");
        
        uint amount = Maps.proposedAccount[msg.sender];
        Maps.proposedAccount[msg.sender] = 0;
        msg.sender.transfer(amount);
        Maps.canWithdraw[msg.sender] = false;
        
        emit LogWithdrawal(msg.sender, amount);
    }
    /** Fallback function. Accepts all funds transfered towards this contract. */
    function() external payable {}
}
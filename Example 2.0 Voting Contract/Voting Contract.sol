pragma solidity >=0.5.1 <0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/ownership/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";

/* @title       Member Actions Library*/
library MemberActions {
    
    using SafeMath for uint256;
    
    struct Member {
        uint256 ethDonated;                                                 // Total donation value
        uint256 lastDonationTime;                                           // Donation timestamp
        uint256 lastDonationValue;                                          // Last donation value
    }
    
    struct Maps {
        uint256 totalMembers;                                               // Keeps track of the total amount of members.
        mapping(address => Member) members;                                 // Keeps track of all members.
        mapping(address => uint) totalVotes;                                // Keeps track of the total votes for a new member.
        mapping(address => mapping(address => bool)) hasVoted;              // Keeps track whether a member has voted for a new member.
        mapping(address => bool) isMember;                                  // Keeps track whether an address is a member.
    }
    
    event NewMemberAdded(address _newMember, uint time);
    event MemberRemoved(address _member, uint time);
    event LogDonation(address _member, uint _amount, uint time);
    
    /** @dev                    Adds a new member automatically once more than 50% 
     *                          of all members have voted to agree.
     *                          Uses SafeMath for addition.
     * 
     *  @param _self            Instance of the Maps struct.
     *  @param _newMember       Proposed address to be added.
     */
    function addMember(Maps storage _self, address _newMember) internal {
        _self.isMember[_newMember] = true;
        _self.totalMembers.add(1);
        
        emit NewMemberAdded(_newMember, now);
    }
    
    /** @dev                    Voting funtion used only members. 
     *                          Decides whether a new member can be added. 
     *                          Uses SafeMath for addition.
     * 
     *  @param _self            Instance of the Maps struct.
     *  @param _newMember       Proposed address to be added.
     *  @param _vote            A boolean used for voting.
     */
    function voting(Maps storage _self, address _newMember, bool _vote) internal {
        require(_self.isMember[msg.sender]);
        require(!_self.hasVoted[_newMember][msg.sender], "You have already voted for this member.");
        if(_vote) {
            _self.totalVotes[_newMember] = _self.totalVotes[_newMember].add(1);
            _self.hasVoted[_newMember][msg.sender] = true;
        }
        if(_self.totalVotes[_newMember] > _self.totalMembers / 2) {
            addMember(_self, _newMember);
        }
    }
    
    /** @dev                    Donation function used by members.
     *                          Donation must be more than 0 ether.
     *  @param _self            Instance of the Maps struct.
     */
    function donation(Maps storage _self) internal {
        require(_self.isMember[msg.sender], "Only members can donate.");
        require(msg.value > 0, "You must donate more than 0 eth.");
        
        _self.members[msg.sender].ethDonated = msg.value;
        _self.members[msg.sender].lastDonationTime = now;
        _self.members[msg.sender].lastDonationValue += msg.value;
        _self.isMember[msg.sender] = true;
        
        emit LogDonation(msg.sender, _self.members[msg.sender].ethDonated, now);
    }
    
    /** @dev                    Function used only by the owner to remove an existing member.
     *                          The member must have not donated any ether in the last hour.
     *                          Uses SafeMath for subtraction.
     * 
     *  @param _self            Instance of the Maps struct.
     *  @param _member          The address to be removed.
     */
    function removeMem(Maps storage _self, address _member) internal {
        require(_self.members[_member].lastDonationTime + 1 hours < now, "This member has donated recently.");
        _self.isMember[_member] = false;
        delete _self.members[_member];
        _self.totalMembers.sub(1);
        
        emit MemberRemoved(_member, now);
    }
}

/* @title           Voting Contract */
contract Voting is Ownable {
    
    using MemberActions for MemberActions.Member;
    using MemberActions for MemberActions.Maps;
    using SafeMath for uint256;                                                 
    
    MemberActions.Member Members;
    MemberActions.Maps Maps;
    
    event NewMemberAdded(address _newMember, uint time);
    event MemberRemoved(address _member, uint time);
    event LogDonation(address _member, uint _amount, uint time);
    
    /** @dev Constructor function, initiates the contract owner as the first member. */
    constructor() public payable {
        Maps.members[msg.sender].ethDonated += msg.value;
        Maps.members[msg.sender].lastDonationTime = now;
        Maps.members[msg.sender].lastDonationValue = msg.value;
        Maps.isMember[msg.sender] = true;
        Maps.totalMembers.add(1);
    }
    /** @dev                    Voting function, uses MemberActions' function voting.
     *                          Only members are allowed to vote.
     */
    function vote(address _newMember, bool _vote) public {
        require(Maps.isMember[msg.sender], "You are not a member.");
        Maps.voting(_newMember, _vote);
    }
    /** @dev                    Donation function, uses MemberActions' function donate.
     */
    function donate() public payable {
        Maps.donation();
    }
    /** @dev                    Remove member function, uses MemberActions' function removeMem.
     *                          Only contract owner is allowed to remove members.
     */
    function removeMember(address _member) public onlyOwner {
        Maps.removeMem(_member);
    }
    /** Destruction of contract function. */
    function kill() public onlyOwner {
        selfdestruct(msg.sender);
    }
}
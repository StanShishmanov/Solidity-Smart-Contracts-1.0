pragma solidity >=0.5.1 <0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";

contract BountyHunters{
    
    using SafeMath for uint256;
    
    event LogBountyCreated(address _from, uint256 _bountyId, uint256 _amount, bool _paid, string _desc, BountyState bountyState);
    event LogProposalSubmitted(address _from, uint256 _bountyId, uint256 _subId, string _desc);
    event LogBountyAccepted(address _submitter, uint256 _bountyId, uint256 _subId);
    event LogBountyRejected(address _submitter, uint256 _bountyId, uint256 _subId);
    event LogBountyClaimed(address _submitter, uint _bountyId, uint256 _subId, uint256 _amount);
    event Paused(address _account);
    event Unpaused(address _account);
    
    enum SubState {Pending, Accepted, Rejected}
    enum BountyState {Open, Closed}
    
    uint256 public bountyId;                                    // Bounty Ids
    uint256 public submissionId;                                // Submission Ids
    bool public _paused;                                        // Used for pausing/unpausing the contract
    bool private initialized;                                   // Used for contract initialization
    address owner;                                              // Address of the contract owner
    
    struct Bounty {
        address adr;                                            // Address of the bounty owner
        uint256 bntId;                                          // Bounty Id
        uint256 amount;                                         // Bounty amount
        bool claimed;                                           // Checks if a bounty has been claimed
        string desc;                                            // Bounty description
        uint256[] subIds;                                       // All submissions Ids
        mapping(uint256 => Submission) submissions;             // All submission for a bounty
        BountyState bountyState;                                // Current state of the bounty
    }
    
    struct Submission {
        address payable submitter;                              // Address of submitter
        uint256 subId;                                          // Id of the submission
        string proposal;                                        // A bounty proposal
        SubState subState;                                      // Current state of the submission
    }
    
    mapping(address => uint256[]) public personalBounties;      // Keeps track of each poster's bounties
    mapping(uint256 => Bounty) bounties;                        // Keeps track of all bounties
    
    modifier onlyOwner() {
        require(msg.sender == owner, 
        "You are not the contract owner.");
        _;
    }
    
    modifier onlyJobPoster(uint256 _bountyId) {
        require(bounties[_bountyId].adr == msg.sender, 
        "You are not the owner of this bounty.");
        _;
    }
    
    modifier onlyInitialized() {
        require(initialized == true, 
        "This contract is not initialized.");
        _;
    }
    
    modifier onlySubmitter(uint256 _bountyId, uint256 _subId) {
        require(bounties[_bountyId].submissions[_subId].submitter == msg.sender, 
        "You are not the owner of this submission.");
        _;
    }
    
    modifier onlyOpenBounty(uint256 _bountyId) {
        require(bounties[_bountyId].bountyState == BountyState.Open,
        "This bounty is now closed.");
        _;
    }
    
    modifier onlyNotPaid(uint256 _bountyId) {
        require(bounties[_bountyId].claimed == false,
        "This bounty has been paid.");
        _;
    }
    
    modifier onlyPendingSub(uint256 _bountyId, uint256 _subId) {
        require(bounties[_bountyId].submissions[_subId].subState == SubState(0),
        "What the hell ???");
        _;
    }
    
    modifier onlyAcceptedSub(uint256 _bountyId, uint256 _subId) {
        require(bounties[_bountyId].submissions[_subId].subState == SubState(1), 
        "This submission has not been accepted.");
        _;
    }
    
    modifier checkBounty(uint256 _bountyId) {
        require(bountyId >= _bountyId, 
        "This bounty does not exist yet.");
        _;
    }
    
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }
    
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    /** @dev Fallback function */
    function() external {
        revert();
    }
    
    /** @dev Used for setting the pausable variable to false */
    function init() public onlyOwner {
        require(!initialized, "This contract has been already initialized.");
        _paused = false;
        initialized = true;
    }
    
    /** @dev Creates a new bounty.
     *  @param _desc The bounty description.
     */
    function createBounty(string memory _desc) 
    public 
    payable 
    onlyInitialized 
    whenNotPaused 
    {
        require(msg.value > 0 ether, "You must include an amount.");
        
        uint _bountyId = bountyId;
        _bountyId = _bountyId.add(1);
        bounties[_bountyId].adr = msg.sender;
        bounties[_bountyId].amount = msg.value;
        bounties[_bountyId].desc = _desc;
        bounties[_bountyId].bountyState = BountyState(0);
        bounties[_bountyId].claimed = false;
        personalBounties[msg.sender].push(_bountyId);
        bountyId = _bountyId;
        
        emit LogBountyCreated(
            msg.sender, 
            _bountyId, 
            msg.value, 
            bounties[_bountyId].claimed, 
            _desc, 
            bounties[_bountyId].bountyState
            );
    }
    
    /** @dev    Submits a new proposal.
     *  @param _bountyId    The id of the bounty.
     *  @param _proposal    The proposal of the submission.
     * 
     */
    function submitProposal(uint256 _bountyId, string memory _proposal) 
    public 
    onlyInitialized
    whenNotPaused
    checkBounty(_bountyId)
    onlyOpenBounty(_bountyId)
    {
        uint256 _subId = submissionId;  
        _subId = _subId.add(1);
        Submission memory newSubmission = Submission(msg.sender, _subId, _proposal, SubState(0));
        bounties[_bountyId].submissions[_subId] = newSubmission; 
        bounties[_bountyId].subIds.push(_subId) - 1; 
        submissionId = _subId;
        
        emit LogProposalSubmitted(
            msg.sender, 
            _bountyId, 
            _subId, 
            _proposal
            );
    }
    
    /** @dev    Accepts a proposed submission - 
     *          changes the bounty state to "Closed" and the submission state to "Accepted".
     *  @param _bountyId    The Id of the bounty.
     *  @param _subId       The id of the submission.
     */
    function acceptSubmission(uint256 _bountyId, uint _subId) 
    public 
    onlyInitialized
    whenNotPaused
    onlyJobPoster(_bountyId)
    onlyOpenBounty(_bountyId)
    onlyPendingSub(_bountyId, _subId) 
    {
        bounties[_bountyId].submissions[_subId].subState = SubState(1);
        bounties[_bountyId].bountyState = BountyState(1);
        
        emit LogBountyAccepted(bounties[_bountyId].submissions[_subId].submitter, _bountyId, _subId);
    }
    
    /** @dev    Rejects a submission by changing its state to "Rejected".
     *  @param _bountyId    The Id of the bounty.
     *  @param _subId       The id of the submission.
     */
    function rejectSubmission(uint256 _bountyId, uint _subId) 
    public 
    onlyInitialized
    whenNotPaused
    onlyJobPoster(_bountyId) 
    onlyOpenBounty(_bountyId)
    onlyPendingSub(_bountyId, _subId)
    {
        bounties[_bountyId].submissions[_subId].subState = SubState(2);
        
        emit LogBountyRejected(bounties[_bountyId].submissions[_subId].submitter, _bountyId, _subId);
    }
    
    /**
     * @dev Called by the contract owner to pause, triggers stopped state.
     */
    function pause() public onlyOwner onlyInitialized whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by the contract owner to unpause, returns to normal state.
     */
    function unpause() public onlyOwner onlyInitialized whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
    function checkSubmissions(uint256 _bountyId) 
    public
    view
    onlyInitialized
    whenNotPaused
    onlyJobPoster(_bountyId)
    returns (uint[] memory) {
        return bounties[_bountyId].subIds;
    }
    
    /** @dev    Used for viewing all personal bounties of a poster.
     *  @return Returns a list of a poster's bounties.
     */
    function viewMyBounties() 
    public 
    view 
    onlyInitialized
    whenNotPaused
    returns (uint[] memory) {
        return personalBounties[msg.sender];
    }
    
    /** @dev    Used for transfering the funds of a bounty after the bounty owner has accepted a submission.
     *  @param _bountyId    The id of the bounty
     *  @param _subId       The id of the submission
     */
    function claimBounty(uint256 _bountyId, uint256 _subId) 
    public 
    onlyInitialized
    whenNotPaused
    onlySubmitter(_bountyId, _subId)
    onlyAcceptedSub(_bountyId, _subId)
    onlyNotPaid(_bountyId)
    {
        uint256 transferAmount = bounties[_bountyId].amount;
        bounties[_bountyId].claimed = true;
        bounties[_bountyId].amount = bounties[_bountyId].amount.sub(transferAmount);
        bounties[_bountyId].submissions[_subId].submitter.transfer(transferAmount);
        
        emit LogBountyClaimed
        (
            bounties[_bountyId].submissions[_subId].submitter, 
            _bountyId, 
            _subId, 
            transferAmount
        );
    }
}
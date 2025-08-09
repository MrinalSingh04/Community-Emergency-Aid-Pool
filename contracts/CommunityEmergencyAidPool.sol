// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract CommunityEmergencyAidPool {
    struct Member {
        bool isMember;
        uint256 lastContribution;
    }

    struct EmergencyRequest {
        address payable requester;
        uint256 amount;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        mapping(address => bool) voted;
    }

    address public admin;
    uint256 public monthlyContribution;
    uint256 public requestCount;
    mapping(address => Member) public members;
    mapping(uint256 => EmergencyRequest) public requests;

    event MemberJoined(address indexed member);
    event ContributionMade(address indexed member, uint256 amount);
    event EmergencyRequested(uint256 indexed requestId, address indexed requester, uint256 amount);
    event Voted(uint256 indexed requestId, address indexed voter, bool support);
    event RequestExecuted(uint256 indexed requestId, address indexed requester, uint256 amount);

    modifier onlyMember() {
        require(members[msg.sender].isMember, "Not a member");
        _;
    }

    constructor(uint256 _monthlyContribution) {
        admin = msg.sender;
        monthlyContribution = _monthlyContribution;
    }

    function joinPool() external payable {
        require(!members[msg.sender].isMember, "Already a member");
        require(msg.value == monthlyContribution, "Must pay monthly contribution");

        members[msg.sender] = Member(true, block.timestamp);
        emit MemberJoined(msg.sender);
        emit ContributionMade(msg.sender, msg.value);
    }

    function contribute() external payable onlyMember {
        require(msg.value == monthlyContribution, "Incorrect contribution");
        members[msg.sender].lastContribution = block.timestamp;
        emit ContributionMade(msg.sender, msg.value);
    }

    function requestEmergencyFunds(uint256 _amount) external onlyMember {
        EmergencyRequest storage req = requests[requestCount];
        req.requester = payable(msg.sender);
        req.amount = _amount;
        emit EmergencyRequested(requestCount, msg.sender, _amount);
        requestCount++;
    }

    function voteOnRequest(uint256 _requestId, bool support) external onlyMember {
        EmergencyRequest storage req = requests[_requestId];
        require(!req.executed, "Request already executed");
        require(!req.voted[msg.sender], "Already voted");

        req.voted[msg.sender] = true;
        if (support) {
            req.votesFor++;
        } else {
            req.votesAgainst++;
        }

        emit Voted(_requestId, msg.sender, support);
    }

    function executeRequest(uint256 _requestId) external onlyMember {
        EmergencyRequest storage req = requests[_requestId];
        require(!req.executed, "Already executed");
        require(req.votesFor > req.votesAgainst, "Not enough support");
        require(address(this).balance >= req.amount, "Insufficient funds");

        req.executed = true;
        req.requester.transfer(req.amount);
        emit RequestExecuted(_requestId, req.requester, req.amount);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

// src/StandaloneCompliance.sol
pragma solidity ^0.8.24;

contract StandaloneCompliance {
    address public owner;
    mapping(address => bool) public verifiedUsers;
    mapping(address => uint256) public riskScores;

    event UserVerified(address indexed user, uint256 riskScore);

    constructor() {
        owner = msg.sender;
    }

    function verifyUser(address user, uint256 riskScore) external {
        require(msg.sender == owner, "Not owner");
        require(riskScore <= 100, "Invalid risk score");
        verifiedUsers[user] = true;
        riskScores[user] = riskScore;
        emit UserVerified(user, riskScore);
    }

    function isCompliant(address user) external view returns (bool) {
        return verifiedUsers[user] && riskScores[user] <= 70;
    }
}

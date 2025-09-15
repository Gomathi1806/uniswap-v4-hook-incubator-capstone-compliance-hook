pragma solidity ^0.8.24;

import "forge-std/console.sol";

contract BasicHook {
    address public owner;
    mapping(address => bool) public verifiedUsers;
    mapping(address => uint256) public riskScores;
    
    event UserVerified(address indexed user, uint256 riskScore);
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    function verifyUser(address user, uint256 riskScore) external onlyOwner {
        require(riskScore <= 100, "Invalid risk score");
        verifiedUsers[user] = true;
        riskScores[user] = riskScore;
        emit UserVerified(user, riskScore);
    }
    
    function isCompliant(address user) external view returns (bool) {
        return verifiedUsers[user] && riskScores[user] <= 70;
    }
    
    function getUserRiskScore(address user) external view returns (uint256) {
        return riskScores[user];
    }
}

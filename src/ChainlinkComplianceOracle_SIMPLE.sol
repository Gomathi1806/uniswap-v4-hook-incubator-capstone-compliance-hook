// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ChainlinkComplianceOracle - Simple Version
 * @dev Compliance oracle without external Chainlink dependencies
 */
contract ChainlinkComplianceOracle is Ownable {
    
    struct ComplianceData {
        uint256 kycScore;
        uint256 amlScore;
        uint256 sanctionsScore;
        uint256 reputationScore;
        uint256 timestamp;
        bool verified;
        bool sanctioned;
        bool dataReceived;
    }
    
    mapping(address => ComplianceData) public complianceRecords;
    mapping(address => bool) public authorizedCallers;
    address public riskCalculatorAddress;
    
    event ComplianceDataUpdated(address indexed user, uint256 kycScore, uint256 amlScore, uint256 timestamp);
    event SanctionStatusUpdated(address indexed user, bool sanctioned);
    event KYCVerified(address indexed user, bool verified);
    
    error Unauthorized();
    error InvalidAddress();
    error InvalidScore();
    
    modifier onlyAuthorized() {
        if (!authorizedCallers[msg.sender] && msg.sender != owner()) revert Unauthorized();
        _;
    }
    
    constructor() Ownable(msg.sender) {
        authorizedCallers[msg.sender] = true;
    }
    
    function setComplianceData(
        address user,
        uint256 kycScore,
        uint256 amlScore,
        uint256 sanctionsScore,
        uint256 reputationScore,
        bool verified,
        bool sanctioned
    ) external onlyAuthorized {
        if (user == address(0)) revert InvalidAddress();
        if (kycScore > 100 || amlScore > 100 || sanctionsScore > 100 || reputationScore > 100) {
            revert InvalidScore();
        }
        
        ComplianceData storage data = complianceRecords[user];
        data.kycScore = kycScore;
        data.amlScore = amlScore;
        data.sanctionsScore = sanctionsScore;
        data.reputationScore = reputationScore;
        data.timestamp = block.timestamp;
        data.verified = verified;
        data.sanctioned = sanctioned;
        data.dataReceived = true;
        
        emit ComplianceDataUpdated(user, kycScore, amlScore, block.timestamp);
        emit KYCVerified(user, verified);
        if (sanctioned) emit SanctionStatusUpdated(user, true);
    }
    
    function quickScreen(address user) external onlyAuthorized returns (bool) {
        if (user == address(0)) revert InvalidAddress();
        
        uint256 seed = uint256(keccak256(abi.encodePacked(user, block.timestamp, block.prevrandao)));
        uint256 kycScore = 50 + (seed % 50);
        uint256 amlScore = 50 + ((seed >> 8) % 50);
        uint256 sanctionsScore = 60 + ((seed >> 16) % 40);
        uint256 reputationScore = 60 + ((seed >> 24) % 40);
        
        bool verified = kycScore >= 70;
        bool sanctioned = sanctionsScore < 70;
        
        ComplianceData storage data = complianceRecords[user];
        data.kycScore = kycScore;
        data.amlScore = amlScore;
        data.sanctionsScore = sanctionsScore;
        data.reputationScore = reputationScore;
        data.timestamp = block.timestamp;
        data.verified = verified;
        data.sanctioned = sanctioned;
        data.dataReceived = true;
        
        emit ComplianceDataUpdated(user, kycScore, amlScore, block.timestamp);
        return !sanctioned;
    }
    
    function getComplianceData(address user) external view returns (
        uint256 kycScore,
        uint256 amlScore,
        uint256 sanctionsScore,
        uint256 reputationScore,
        uint256 timestamp,
        bool verified,
        bool sanctioned,
        bool dataReceived
    ) {
        ComplianceData memory data = complianceRecords[user];
        return (
            data.kycScore,
            data.amlScore,
            data.sanctionsScore,
            data.reputationScore,
            data.timestamp,
            data.verified,
            data.sanctioned,
            data.dataReceived
        );
    }
    
    function getAggregatedRiskScore(address user) external view returns (uint256) {
        ComplianceData memory data = complianceRecords[user];
        if (!data.dataReceived) return 50;
        
        return (
            (data.kycScore * 30) +
            (data.amlScore * 30) +
            (data.sanctionsScore * 25) +
            (data.reputationScore * 15)
        ) / 100;
    }
    
    function isHighRisk(address user) external view returns (bool) {
        ComplianceData memory data = complianceRecords[user];
        if (!data.dataReceived) return false;
        
        return data.sanctioned || 
               data.kycScore < 50 || 
               data.amlScore < 50 || 
               data.sanctionsScore < 50;
    }
    
    function setRiskCalculatorAddress(address _riskCalculator) external onlyOwner {
        if (_riskCalculator == address(0)) revert InvalidAddress();
        riskCalculatorAddress = _riskCalculator;
        authorizedCallers[_riskCalculator] = true;
    }
    
    function setAuthorizedCaller(address caller, bool status) external onlyOwner {
        if (caller == address(0)) revert InvalidAddress();
        authorizedCallers[caller] = status;
    }
    
    function isScreened(address user) external view returns (bool) {
        return complianceRecords[user].dataReceived;
    }
}

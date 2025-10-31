// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AutomatedRiskCalculator - PRODUCTION VERSION
 * @dev Automated risk calculation with cross-chain support
 */
contract AutomatedRiskCalculator is Ownable {
    
    struct RiskProfile {
        uint256 complianceScore;
        uint256 transactionHistoryScore;
        uint256 walletAgeScore;
        uint256 volumeScore;
        uint256 sanctionsScore;
        uint256 reputationScore;
        uint256 overallRiskScore;
        uint256 lastUpdated;
        bool isActive;
    }
    
    struct RiskWeights {
        uint256 compliance;
        uint256 transactionHistory;
        uint256 walletAge;
        uint256 volume;
        uint256 sanctions;
        uint256 reputation;
    }
    
    mapping(address => RiskProfile) public riskProfiles;
    mapping(address => bool) public authorizedOracles;
    mapping(address => uint256) public transactionCount;
    mapping(address => uint256) public totalVolume;
    mapping(address => uint256) public firstSeenBlock;
    
    RiskWeights public weights;
    
    uint256 public constant MIN_ACCEPTABLE_SCORE = 30;
    
    address public chainlinkOracle;
    address public fhenixFHE;
    address public crossChainBridge;
    
    event RiskProfileUpdated(address indexed user, uint256 overallScore, uint256 timestamp);
    event OracleAuthorized(address indexed oracle, bool status);
    event ProfileAssessed(address indexed user, uint256 overallScore, bool success);
    event CrossChainDataReceived(address indexed user, uint256 sanctionsScore);
    
    constructor() Ownable(msg.sender) {
        weights = RiskWeights({
            compliance: 35,
            transactionHistory: 25,
            walletAge: 15,
            volume: 10,
            sanctions: 10,
            reputation: 5
        });
        
        authorizedOracles[msg.sender] = true;
    }
    
    function setOracleAddresses(address _chainlinkOracle, address _fhenixFHE) external onlyOwner {
        chainlinkOracle = _chainlinkOracle;
        fhenixFHE = _fhenixFHE;
        
        authorizedOracles[_chainlinkOracle] = true;
        authorizedOracles[_fhenixFHE] = true;
    }
    
    function setCrossChainBridge(address _bridge) external onlyOwner {
        crossChainBridge = _bridge;
        authorizedOracles[_bridge] = true;
    }
    
    function assessProfile(address user) external returns (bool) {
        if (firstSeenBlock[user] == 0) {
            firstSeenBlock[user] = block.number;
        }
        
        if (transactionCount[user] == 0) {
            transactionCount[user] = 1;
            totalVolume[user] = 0.1 ether;
        }
        
        RiskProfile storage profile = riskProfiles[user];
        
        profile.transactionHistoryScore = analyzeTransactionHistory(user);
        profile.walletAgeScore = calculateWalletAgeScore(user);
        profile.volumeScore = analyzeVolume(user);
        
        if (profile.complianceScore == 0) {
            profile.complianceScore = 50;
        }
        if (profile.sanctionsScore == 0) {
            profile.sanctionsScore = 95;
        }
        if (profile.reputationScore == 0) {
            profile.reputationScore = 60;
        }
        
        profile.isActive = true;
        profile.lastUpdated = block.timestamp;
        profile.overallRiskScore = calculateRiskScore(user);
        
        emit ProfileAssessed(user, profile.overallRiskScore, true);
        emit RiskProfileUpdated(user, profile.overallRiskScore, block.timestamp);
        
        return true;
    }
    
    function calculateRiskScore(address user) public view returns (uint256) {
        RiskProfile memory profile = riskProfiles[user];
        
        if (!profile.isActive) {
            return 0;
        }
        
        uint256 score = (
            (profile.complianceScore * weights.compliance) +
            (profile.transactionHistoryScore * weights.transactionHistory) +
            (profile.walletAgeScore * weights.walletAge) +
            (profile.volumeScore * weights.volume) +
            (profile.sanctionsScore * weights.sanctions) +
            (profile.reputationScore * weights.reputation)
        ) / 100;
        
        return score;
    }
    
    function getRiskProfile(address user) external view returns (
        uint256 overall,
        uint256 compliance,
        uint256 txHistory,
        uint256 sanctions
    ) {
        RiskProfile memory profile = riskProfiles[user];
        
        return (
            profile.overallRiskScore,
            profile.complianceScore,
            profile.transactionHistoryScore,
            profile.sanctionsScore
        );
    }
    
    function getFullRiskProfile(address user) external view returns (RiskProfile memory) {
        return riskProfiles[user];
    }
    
    function getComplianceScore(address user) external view returns (uint256) {
        return riskProfiles[user].complianceScore;
    }
    
    function getRiskLevel(address user) public view returns (uint256) {
        uint256 score = calculateRiskScore(user);
        
        if (score == 0) return 0;
        if (score >= 80) return 3;
        if (score >= 50) return 2;
        return 1;
    }
    
    function meetsMinimumRisk(address user) public view returns (bool) {
        uint256 score = calculateRiskScore(user);
        return score >= MIN_ACCEPTABLE_SCORE;
    }
    
    function setComplianceData(
        address user,
        uint256 complianceScore,
        uint256 sanctionsScore,
        uint256 reputationScore
    ) external {
        require(authorizedOracles[msg.sender], "Not authorized oracle");
        require(complianceScore <= 100, "Invalid score");
        require(sanctionsScore <= 100, "Invalid score");
        require(reputationScore <= 100, "Invalid score");
        
        RiskProfile storage profile = riskProfiles[user];
        
        profile.complianceScore = complianceScore;
        profile.sanctionsScore = sanctionsScore;
        profile.reputationScore = reputationScore;
        profile.lastUpdated = block.timestamp;
        profile.isActive = true;
        
        profile.overallRiskScore = calculateRiskScore(user);
        
        emit RiskProfileUpdated(user, profile.overallRiskScore, block.timestamp);
    }
    
    function updateCrossChainSanctionsData(
        address user,
        uint256 sanctionsScore
    ) external {
        require(msg.sender == crossChainBridge || authorizedOracles[msg.sender], "Not authorized");
        
        RiskProfile storage profile = riskProfiles[user];
        profile.sanctionsScore = sanctionsScore;
        profile.lastUpdated = block.timestamp;
        profile.overallRiskScore = calculateRiskScore(user);
        
        emit CrossChainDataReceived(user, sanctionsScore);
        emit RiskProfileUpdated(user, profile.overallRiskScore, block.timestamp);
    }
    
    function recordTransaction(address user, uint256 amount) external {
        require(authorizedOracles[msg.sender] || msg.sender == owner(), "Not authorized");
        
        if (firstSeenBlock[user] == 0) {
            firstSeenBlock[user] = block.number;
        }
        
        transactionCount[user]++;
        totalVolume[user] += amount;
        
        updateOnChainScores(user);
    }
    
    function updateOnChainScores(address user) public {
        RiskProfile storage profile = riskProfiles[user];
        
        profile.transactionHistoryScore = analyzeTransactionHistory(user);
        profile.walletAgeScore = calculateWalletAgeScore(user);
        profile.volumeScore = analyzeVolume(user);
        profile.lastUpdated = block.timestamp;
        
        if (!profile.isActive) {
            profile.isActive = true;
        }
        
        profile.overallRiskScore = calculateRiskScore(user);
        
        emit RiskProfileUpdated(user, profile.overallRiskScore, block.timestamp);
    }
    
    function analyzeTransactionHistory(address user) public view returns (uint256) {
        uint256 txCount = transactionCount[user];
        
        if (txCount == 0) return 0;
        if (txCount < 10) return 30;
        if (txCount < 50) return 50;
        if (txCount < 100) return 70;
        if (txCount < 500) return 85;
        return 95;
    }
    
    function calculateWalletAgeScore(address user) public view returns (uint256) {
        if (firstSeenBlock[user] == 0) {
            return 20;
        }
        
        uint256 age = block.number - firstSeenBlock[user];
        
        if (age < 7200) return 20;
        if (age < 50400) return 40;
        if (age < 216000) return 60;
        if (age < 1080000) return 80;
        return 95;
    }
    
    function analyzeVolume(address user) public view returns (uint256) {
        uint256 volume = totalVolume[user];
        
        if (volume == 0) return 0;
        if (volume < 0.1 ether) return 30;
        if (volume < 1 ether) return 50;
        if (volume < 10 ether) return 70;
        if (volume < 100 ether) return 85;
        return 95;
    }
    
    function setAuthorizedOracle(address oracle, bool status) external onlyOwner {
        authorizedOracles[oracle] = status;
        emit OracleAuthorized(oracle, status);
    }
    
    function updateWeights(
        uint256 _compliance,
        uint256 _transactionHistory,
        uint256 _walletAge,
        uint256 _volume,
        uint256 _sanctions,
        uint256 _reputation
    ) external onlyOwner {
        require(
            _compliance + _transactionHistory + _walletAge + 
            _volume + _sanctions + _reputation == 100,
            "Weights must sum to 100"
        );
        
        weights = RiskWeights({
            compliance: _compliance,
            transactionHistory: _transactionHistory,
            walletAge: _walletAge,
            volume: _volume,
            sanctions: _sanctions,
            reputation: _reputation
        });
    }
    
    function pauseProfile(address user) external onlyOwner {
        riskProfiles[user].isActive = false;
    }
    
    function resumeProfile(address user) external onlyOwner {
        riskProfiles[user].isActive = true;
    }
}
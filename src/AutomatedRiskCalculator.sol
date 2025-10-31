// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AutomatedRiskCalculator
 * @dev Automated risk calculation with on-chain data
 */
contract AutomatedRiskCalculator is Ownable {
    
    struct RiskProfile {
        uint256 complianceScore;        // 0-100
        uint256 transactionHistoryScore; // 0-100
        uint256 walletAgeScore;         // 0-100
        uint256 volumeScore;            // 0-100
        uint256 sanctionsScore;         // 0-100
        uint256 reputationScore;        // 0-100
        uint256 overallRiskScore;       // 0-100
        uint256 lastUpdated;
        bool isActive;
    }
    
    struct RiskWeights {
        uint256 compliance;             // Default: 35
        uint256 transactionHistory;     // Default: 25
        uint256 walletAge;             // Default: 15
        uint256 volume;                // Default: 10
        uint256 sanctions;             // Default: 10
        uint256 reputation;            // Default: 5
    }
    
    mapping(address => RiskProfile) public riskProfiles;
    mapping(address => bool) public authorizedOracles;
    mapping(address => uint256) public transactionCount;
    mapping(address => uint256) public totalVolume;
    mapping(address => uint256) public firstSeenBlock;
    
    RiskWeights public weights;
    
    uint256 public constant MIN_ACCEPTABLE_SCORE = 30;
    
    event RiskProfileUpdated(address indexed user, uint256 overallScore, uint256 timestamp);
    event OracleAuthorized(address indexed oracle, bool status);
    
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
    
    /**
     * @dev Calculate overall risk score
     */
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
    
    /**
     * @dev Get risk level (0=Not Scored, 1=High, 2=Medium, 3=Low)
     */
    function getRiskLevel(address user) public view returns (uint256) {
        uint256 score = calculateRiskScore(user);
        
        if (score == 0) return 0;
        if (score >= 80) return 3;
        if (score >= 50) return 2;
        return 1;
    }
    
    /**
     * @dev Check if user meets minimum acceptable risk
     */
    function meetsMinimumRisk(address user) public view returns (bool) {
        uint256 score = calculateRiskScore(user);
        return score >= MIN_ACCEPTABLE_SCORE;
    }
    
    /**
     * @dev Set compliance data from authorized oracle
     */
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
    
    /**
     * @dev Record transaction for on-chain analysis
     */
    function recordTransaction(address user, uint256 amount) external {
        require(authorizedOracles[msg.sender], "Not authorized");
        
        if (firstSeenBlock[user] == 0) {
            firstSeenBlock[user] = block.number;
        }
        
        transactionCount[user]++;
        totalVolume[user] += amount;
        
        updateOnChainScores(user);
    }
    
    /**
     * @dev Update on-chain derived scores
     */
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
    
    /**
     * @dev Analyze transaction history
     */
    function analyzeTransactionHistory(address user) public view returns (uint256) {
        uint256 txCount = transactionCount[user];
        
        if (txCount == 0) return 0;
        if (txCount < 10) return 30;
        if (txCount < 50) return 50;
        if (txCount < 100) return 70;
        if (txCount < 500) return 85;
        return 95;
    }
    
    /**
     * @dev Calculate wallet age score
     */
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
    
    /**
     * @dev Analyze volume
     */
    function analyzeVolume(address user) public view returns (uint256) {
        uint256 volume = totalVolume[user];
        
        if (volume == 0) return 0;
        if (volume < 0.1 ether) return 30;
        if (volume < 1 ether) return 50;
        if (volume < 10 ether) return 70;
        if (volume < 100 ether) return 85;
        return 95;
    }
    
    /**
     * @dev Authorize oracle
     */
    function setAuthorizedOracle(address oracle, bool status) external onlyOwner {
        authorizedOracles[oracle] = status;
        emit OracleAuthorized(oracle, status);
    }
    
    /**
     * @dev Get complete risk profile
     */
    function getRiskProfile(address user) external view returns (RiskProfile memory) {
        return riskProfiles[user];
    }
}
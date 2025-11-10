// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFhenixFHECompliance {
    function checkSanctionsList(address user) external view returns (bool);
    function isProfileScreened(address user) external view returns (bool);
}

interface IChainlinkComplianceOracle {
    function getAggregatedRiskScore(address user) external view returns (uint256);
    function isHighRisk(address user) external view returns (bool);
    function isScreened(address user) external view returns (bool);
}

/**
 * @title CrossChainRiskCalculator
 * @dev Aggregates risk from FhenixFHE and Chainlink Oracle
 */
contract CrossChainRiskCalculator is Ownable {
    
    IFhenixFHECompliance public fhenixCompliance;
    IChainlinkComplianceOracle public chainlinkOracle;
    
    mapping(address => bool) public authorizedCallers;
    mapping(address => uint256) public userRiskScores;
    mapping(address => uint256) public lastCalculationTime;
    
    uint256 public riskThreshold = 50; // Users below this score are blocked
    bool public paused;
    
    event RiskCalculated(address indexed user, uint256 riskScore, uint256 timestamp);
    event RiskThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);
    event UserBlocked(address indexed user, uint256 riskScore);
    
    error Unauthorized();
    error InvalidAddress();
    error Paused();
    error InvalidThreshold();
    
    modifier onlyAuthorized() {
        if (!authorizedCallers[msg.sender] && msg.sender != owner()) revert Unauthorized();
        _;
    }
    
    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }
    
    constructor(
        address _fhenixCompliance,
        address _chainlinkOracle
    ) Ownable(msg.sender) {
        if (_fhenixCompliance == address(0) || _chainlinkOracle == address(0)) {
            revert InvalidAddress();
        }
        
        fhenixCompliance = IFhenixFHECompliance(_fhenixCompliance);
        chainlinkOracle = IChainlinkComplianceOracle(_chainlinkOracle);
        authorizedCallers[msg.sender] = true;
    }
    
    /**
     * @dev Calculate aggregated risk score for a user
     * Combines FHE sanctions data with Chainlink compliance scores
     */
    function calculateRisk(address user) external onlyAuthorized whenNotPaused returns (uint256) {
        if (user == address(0)) revert InvalidAddress();
        
        uint256 riskScore = 100; // Start with clean score
        
        // Check Fhenix FHE sanctions (50% weight)
        bool onSanctionsList = fhenixCompliance.checkSanctionsList(user);
        if (onSanctionsList) {
            riskScore = riskScore * 50 / 100; // Cut score in half if sanctioned
        }
        
        // Check Chainlink oracle data (50% weight)
        bool isScreened = chainlinkOracle.isScreened(user);
        if (isScreened) {
            uint256 oracleScore = chainlinkOracle.getAggregatedRiskScore(user);
            riskScore = (riskScore + oracleScore) / 2; // Average the two scores
        }
        
        // Store result
        userRiskScores[user] = riskScore;
        lastCalculationTime[user] = block.timestamp;
        
        emit RiskCalculated(user, riskScore, block.timestamp);
        
        if (riskScore < riskThreshold) {
            emit UserBlocked(user, riskScore);
        }
        
        return riskScore;
    }
    
    /**
     * @dev Check if user should be blocked from trading
     */
    function shouldBlockUser(address user) external view returns (bool) {
        // Block if sanctioned on Fhenix
        if (fhenixCompliance.checkSanctionsList(user)) {
            return true;
        }
        
        // Block if high risk on Chainlink
        if (chainlinkOracle.isHighRisk(user)) {
            return true;
        }
        
        // Block if calculated risk score is below threshold
        if (userRiskScores[user] > 0 && userRiskScores[user] < riskThreshold) {
            return true;
        }
        
        return false;
    }
    
    /**
     * @dev Get user's current risk score
     */
    function getUserRiskScore(address user) external view returns (uint256 score, uint256 timestamp) {
        return (userRiskScores[user], lastCalculationTime[user]);
    }
    
    /**
     * @dev Batch calculate risk for multiple users
     */
    function batchCalculateRisk(address[] calldata users) external onlyAuthorized whenNotPaused {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] != address(0)) {
                this.calculateRisk(users[i]);
            }
        }
    }
    
    /**
     * @dev Update risk threshold
     */
    function setRiskThreshold(uint256 newThreshold) external onlyOwner {
        if (newThreshold > 100) revert InvalidThreshold();
        
        uint256 oldThreshold = riskThreshold;
        riskThreshold = newThreshold;
        
        emit RiskThresholdUpdated(oldThreshold, newThreshold);
    }
    
    /**
     * @dev Set authorized caller
     */
    function setAuthorizedCaller(address caller, bool status) external onlyOwner {
        if (caller == address(0)) revert InvalidAddress();
        authorizedCallers[caller] = status;
    }
    
    /**
     * @dev Emergency pause
     */
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }
    
    /**
     * @dev Update contract addresses
     */
    function updateContracts(address _fhenixCompliance, address _chainlinkOracle) external onlyOwner {
        if (_fhenixCompliance != address(0)) {
            fhenixCompliance = IFhenixFHECompliance(_fhenixCompliance);
        }
        if (_chainlinkOracle != address(0)) {
            chainlinkOracle = IChainlinkComplianceOracle(_chainlinkOracle);
        }
    }
}

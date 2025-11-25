// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Phase1_SimpleCompliance
 * @notice Simplified compliance oracle with real data structure (manual input for now)
 * @dev Start with this, then upgrade to full Chainlink integration later
 */
contract Phase1_SimpleCompliance is AccessControl, ReentrancyGuard {
    
    // ====== ROLES ======
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // ====== ENUMS ======
    enum RiskLevel { 
        LOW,        // Score 70-100
        MEDIUM,     // Score 40-69
        HIGH,       // Score 0-39
        SANCTIONED  // On sanctions list
    }

    enum DataSource {
        MANUAL_ADMIN,
        OFAC_SDN,
        CHAINALYSIS,
        TRM_LABS
    }

    // ====== STRUCTS ======
    struct ComplianceRecord {
        RiskLevel riskLevel;
        uint256 riskScore;
        uint256 kycScore;
        uint256 amlScore;
        uint256 sanctionsScore;
        bool isOnOFACList;
        bool verified;
        uint256 lastChecked;
        uint256 lastUpdated;
        DataSource dataSource;
        string country;
    }

    // ====== STATE VARIABLES ======
    
    mapping(address => ComplianceRecord) public complianceRecords;
    mapping(address => bool) public blacklistedAddresses;
    mapping(address => bool) public whitelistedAddresses;
    mapping(address => string) public blacklistReasons;
    
    // Statistics
    uint256 public totalChecksPerformed;
    uint256 public totalSanctionedFound;
    uint256 public totalHighRiskFound;
    
    bool public paused;

    // ====== COMPREHENSIVE EVENTS ======
    
    event ComplianceCheck(
        address indexed user, 
        bool passed, 
        RiskLevel riskLevel,
        string reason,
        uint256 timestamp
    );
    
    event SanctionedAddressBlocked(
        address indexed blockedAddress,
        DataSource source,
        string details,
        uint256 timestamp
    );
    
    event HighRiskTransactionPrevented(
        address indexed user, 
        uint256 amount,
        RiskLevel riskLevel,
        string reason,
        uint256 timestamp
    );
    
    event RiskLevelUpdated(
        address indexed user,
        RiskLevel oldLevel,
        RiskLevel newLevel,
        string reason,
        uint256 timestamp
    );
    
    event RiskScoreCalculated(
        address indexed user,
        uint256 score,
        uint256 kycScore,
        uint256 amlScore,
        uint256 sanctionsScore,
        uint256 timestamp
    );
    
    event ManualOverride(
        address indexed admin,
        address indexed user,
        RiskLevel newLevel,
        string reason,
        uint256 timestamp
    );
    
    event AddressWhitelisted(
        address indexed admin,
        address indexed user,
        string reason,
        uint256 timestamp
    );
    
    event AddressBlacklisted(
        address indexed admin,
        address indexed user,
        string reason,
        uint256 timestamp
    );
    
    event BatchComplianceUpdate(
        uint256 count,
        DataSource source,
        uint256 timestamp
    );
    
    event EmergencyPause(
        address indexed admin,
        string reason,
        uint256 timestamp
    );
    
    event EmergencyUnpause(
        address indexed admin,
        uint256 timestamp
    );

    // ====== ERRORS ======
    error Paused();
    error Unauthorized();
    error InvalidAddress();
    error InvalidScore();

    // ====== MODIFIERS ======
    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier onlyOperator() {
        if (!hasRole(OPERATOR_ROLE, msg.sender)) revert Unauthorized();
        _;
    }

    // ====== CONSTRUCTOR ======
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
    }

    // ====== COMPLIANCE CHECK FUNCTIONS ======

    /**
     * @notice Perform compliance check on address
     */
    function checkCompliance(address user) 
        external 
        whenNotPaused 
        returns (bool passed) 
    {
        if (user == address(0)) revert InvalidAddress();
        
        // Check whitelist
        if (whitelistedAddresses[user]) {
            emit ComplianceCheck(user, true, RiskLevel.LOW, "Whitelisted", block.timestamp);
            return true;
        }
        
        // Check blacklist
        if (blacklistedAddresses[user]) {
            emit ComplianceCheck(user, false, RiskLevel.SANCTIONED, "Blacklisted", block.timestamp);
            return false;
        }
        
        ComplianceRecord storage record = complianceRecords[user];
        record.lastChecked = block.timestamp;
        totalChecksPerformed++;
        
        // Check sanctions
        if (record.isOnOFACList || record.riskLevel == RiskLevel.SANCTIONED) {
            emit ComplianceCheck(user, false, RiskLevel.SANCTIONED, "On sanctions list", block.timestamp);
            return false;
        }
        
        // Check risk level
        if (record.riskLevel == RiskLevel.HIGH) {
            emit ComplianceCheck(user, false, RiskLevel.HIGH, "High risk", block.timestamp);
            return false;
        }
        
        // Pass for LOW and MEDIUM risk
        emit ComplianceCheck(user, true, record.riskLevel, "Passed", block.timestamp);
        return true;
    }

    /**
     * @notice Check if swap should be allowed
     */
    function beforeSwap(
        address sender, 
        address recipient,
        uint256 amount
    ) external whenNotPaused returns (bool allowed) {
        // Check whitelist
        if (whitelistedAddresses[sender] && whitelistedAddresses[recipient]) {
            return true;
        }
        
        // Check blacklist
        if (blacklistedAddresses[sender] || blacklistedAddresses[recipient]) {
            emit HighRiskTransactionPrevented(
                sender,
                amount,
                RiskLevel.SANCTIONED,
                "Blacklisted address",
                block.timestamp
            );
            return false;
        }
        
        ComplianceRecord memory senderRecord = complianceRecords[sender];
        ComplianceRecord memory recipientRecord = complianceRecords[recipient];
        
        // Block sanctioned
        if (senderRecord.riskLevel == RiskLevel.SANCTIONED || 
            recipientRecord.riskLevel == RiskLevel.SANCTIONED) {
            emit HighRiskTransactionPrevented(
                sender,
                amount,
                RiskLevel.SANCTIONED,
                "Sanctioned address",
                block.timestamp
            );
            return false;
        }
        
        // Block high risk
        if (senderRecord.riskLevel == RiskLevel.HIGH || 
            recipientRecord.riskLevel == RiskLevel.HIGH) {
            emit HighRiskTransactionPrevented(
                sender,
                amount,
                RiskLevel.HIGH,
                "High risk address",
                block.timestamp
            );
            return false;
        }
        
        return true;
    }

    // ====== ADMIN FUNCTIONS ======

    /**
     * @notice Set compliance data for user (simulates OFAC API result)
     */
    function setComplianceData(
        address user,
        uint256 kycScore,
        uint256 amlScore,
        uint256 sanctionsScore,
        bool isOnOFACList,
        string calldata country
    ) external onlyRole(OPERATOR_ROLE) {
        if (user == address(0)) revert InvalidAddress();
        if (kycScore > 100 || amlScore > 100 || sanctionsScore > 100) revert InvalidScore();
        
        ComplianceRecord storage record = complianceRecords[user];
        RiskLevel oldLevel = record.riskLevel;
        
        record.kycScore = kycScore;
        record.amlScore = amlScore;
        record.sanctionsScore = sanctionsScore;
        record.isOnOFACList = isOnOFACList;
        record.country = country;
        record.verified = kycScore >= 70;
        record.lastUpdated = block.timestamp;
        record.dataSource = DataSource.MANUAL_ADMIN;
        
        _updateRiskLevel(user);
        
        emit RiskScoreCalculated(
            user,
            record.riskScore,
            kycScore,
            amlScore,
            sanctionsScore,
            block.timestamp
        );
        
        if (oldLevel != record.riskLevel) {
            emit RiskLevelUpdated(
                user,
                oldLevel,
                record.riskLevel,
                "Compliance data updated",
                block.timestamp
            );
        }
        
        if (isOnOFACList) {
            totalSanctionedFound++;
            emit SanctionedAddressBlocked(
                user,
                DataSource.MANUAL_ADMIN,
                "Added to sanctions list",
                block.timestamp
            );
        }
    }

    /**
     * @notice Calculate and update risk level
     */
    function _updateRiskLevel(address user) internal {
        ComplianceRecord storage record = complianceRecords[user];
        
        // Sanctioned overrides everything
        if (record.isOnOFACList) {
            record.riskLevel = RiskLevel.SANCTIONED;
            record.riskScore = 0;
            return;
        }
        
        // Calculate weighted average
        uint256 totalScore = (
            record.kycScore * 30 +
            record.amlScore * 40 +
            record.sanctionsScore * 30
        ) / 100;
        
        record.riskScore = totalScore;
        
        // Classify
        if (totalScore >= 70) {
            record.riskLevel = RiskLevel.LOW;
        } else if (totalScore >= 40) {
            record.riskLevel = RiskLevel.MEDIUM;
        } else {
            record.riskLevel = RiskLevel.HIGH;
            totalHighRiskFound++;
        }
    }

    /**
     * @notice Batch update compliance
     */
    function batchUpdateCompliance(
        address[] calldata users,
        uint256[] calldata kycScores,
        uint256[] calldata amlScores,
        bool[] calldata sanctioned
    ) external onlyRole(OPERATOR_ROLE) {
        require(
            users.length == kycScores.length && 
            users.length == amlScores.length &&
            users.length == sanctioned.length,
            "Array length mismatch"
        );
        
        for (uint256 i = 0; i < users.length; i++) {
            ComplianceRecord storage record = complianceRecords[users[i]];
            record.kycScore = kycScores[i];
            record.amlScore = amlScores[i];
            record.isOnOFACList = sanctioned[i];
            record.sanctionsScore = sanctioned[i] ? 0 : 100;
            record.lastUpdated = block.timestamp;
            
            _updateRiskLevel(users[i]);
        }
        
        emit BatchComplianceUpdate(users.length, DataSource.MANUAL_ADMIN, block.timestamp);
    }

    /**
     * @notice Admin override
     */
    function adminOverride(
        address user,
        RiskLevel newLevel,
        string calldata reason
    ) external onlyRole(ADMIN_ROLE) {
        ComplianceRecord storage record = complianceRecords[user];
        RiskLevel oldLevel = record.riskLevel;
        
        record.riskLevel = newLevel;
        record.lastUpdated = block.timestamp;
        record.dataSource = DataSource.MANUAL_ADMIN;
        
        emit ManualOverride(msg.sender, user, newLevel, reason, block.timestamp);
        emit RiskLevelUpdated(user, oldLevel, newLevel, reason, block.timestamp);
    }

    /**
     * @notice Add to whitelist
     */
    function addToWhitelist(address user, string calldata reason) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        whitelistedAddresses[user] = true;
        emit AddressWhitelisted(msg.sender, user, reason, block.timestamp);
    }

    /**
     * @notice Add to blacklist
     */
    function addToBlacklist(address user, string calldata reason) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        blacklistedAddresses[user] = true;
        blacklistReasons[user] = reason;
        
        complianceRecords[user].riskLevel = RiskLevel.SANCTIONED;
        
        emit AddressBlacklisted(msg.sender, user, reason, block.timestamp);
        emit SanctionedAddressBlocked(user, DataSource.MANUAL_ADMIN, reason, block.timestamp);
    }

    /**
     * @notice Emergency pause
     */
    function pause(string calldata reason) external onlyRole(ADMIN_ROLE) {
        paused = true;
        emit EmergencyPause(msg.sender, reason, block.timestamp);
    }

    /**
     * @notice Unpause
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        paused = false;
        emit EmergencyUnpause(msg.sender, block.timestamp);
    }

    // ====== VIEW FUNCTIONS ======

    function getRiskLevel(address user) external view returns (RiskLevel) {
        return complianceRecords[user].riskLevel;
    }

    function getRiskLevelString(address user) external view returns (string memory) {
        RiskLevel level = complianceRecords[user].riskLevel;
        if (level == RiskLevel.SANCTIONED) return "Sanctioned";
        if (level == RiskLevel.HIGH) return "High Risk";
        if (level == RiskLevel.MEDIUM) return "Medium Risk";
        return "Low Risk";
    }

    function getComplianceRecord(address user) external view returns (ComplianceRecord memory) {
        return complianceRecords[user];
    }

    function isCompliant(address user) external view returns (bool) {
        if (whitelistedAddresses[user]) return true;
        if (blacklistedAddresses[user]) return false;
        
        RiskLevel level = complianceRecords[user].riskLevel;
        return level == RiskLevel.LOW || level == RiskLevel.MEDIUM;
    }

    function getRiskScore(address user) external view returns (uint256) {
        return complianceRecords[user].riskScore;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Phase1_OFACOracleReady
 * @notice OFAC compliance with oracle-ready architecture (no Chainlink Functions dependency)
 * @dev Start with this, can upgrade to real Chainlink Functions later
 */
contract Phase1_OFACOracleReady is AccessControl, ReentrancyGuard {
    
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    enum RiskLevel { LOW, MEDIUM, HIGH, SANCTIONED }
    enum DataSource { MANUAL_ADMIN, OFAC_SDN, CHAINALYSIS, TRM_LABS, ORACLE }

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
        bytes32 requestId;  // For oracle tracking
    }

    struct OracleRequest {
        address user;
        uint256 timestamp;
        bool fulfilled;
        DataSource source;
    }

    // State
    mapping(address => ComplianceRecord) public complianceRecords;
    mapping(address => bool) public blacklistedAddresses;
    mapping(address => bool) public whitelistedAddresses;
    mapping(bytes32 => OracleRequest) public oracleRequests;
    
    // Oracle configuration
    address public oracleAddress;
    uint256 public oracleFee;
    
    // Statistics
    uint256 public totalChecksPerformed;
    uint256 public totalSanctionedFound;
    uint256 public totalHighRiskFound;
    uint256 public totalOracleRequests;
    uint256 public totalOracleFulfillments;
    
    bool public paused;

    // COMPREHENSIVE EVENTS
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
    
    event OracleRequestCreated(
        bytes32 indexed requestId,
        address indexed user,
        DataSource source,
        uint256 timestamp
    );
    
    event OracleRequestFulfilled(
        bytes32 indexed requestId,
        address indexed user,
        bool isOnOFACList,
        uint256 riskScore,
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
    
    event OracleAddressUpdated(
        address indexed oldOracle,
        address indexed newOracle,
        uint256 timestamp
    );

    error Paused();
    error Unauthorized();
    error InvalidAddress();
    error InvalidScore();
    error OracleNotSet();

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        _grantRole(ORACLE_ROLE, msg.sender);
    }

    // ====== COMPLIANCE CHECK FUNCTIONS ======

    /**
     * @notice Check compliance
     */
    function checkCompliance(address user) 
        external 
        whenNotPaused 
        returns (bool passed) 
    {
        if (user == address(0)) revert InvalidAddress();
        
        if (whitelistedAddresses[user]) {
            emit ComplianceCheck(user, true, RiskLevel.LOW, "Whitelisted", block.timestamp);
            return true;
        }
        
        if (blacklistedAddresses[user]) {
            emit ComplianceCheck(user, false, RiskLevel.SANCTIONED, "Blacklisted", block.timestamp);
            return false;
        }
        
        ComplianceRecord storage record = complianceRecords[user];
        record.lastChecked = block.timestamp;
        totalChecksPerformed++;
        
        if (record.isOnOFACList || record.riskLevel == RiskLevel.SANCTIONED) {
            emit ComplianceCheck(user, false, RiskLevel.SANCTIONED, "On sanctions list", block.timestamp);
            return false;
        }
        
        if (record.riskLevel == RiskLevel.HIGH) {
            emit ComplianceCheck(user, false, RiskLevel.HIGH, "High risk", block.timestamp);
            return false;
        }
        
        emit ComplianceCheck(user, true, record.riskLevel, "Passed", block.timestamp);
        return true;
    }

    /**
     * @notice Request OFAC check via oracle
     * @dev Creates oracle request, oracle fulfills later
     */
    function requestOFACCheck(address user) 
        external 
        whenNotPaused 
        returns (bytes32 requestId) 
    {
        if (oracleAddress == address(0)) revert OracleNotSet();
        
        requestId = keccak256(abi.encodePacked(user, block.timestamp, totalOracleRequests));
        
        oracleRequests[requestId] = OracleRequest({
            user: user,
            timestamp: block.timestamp,
            fulfilled: false,
            source: DataSource.ORACLE
        });
        
        totalOracleRequests++;
        
        emit OracleRequestCreated(requestId, user, DataSource.ORACLE, block.timestamp);
        
        return requestId;
    }

    /**
     * @notice Oracle fulfills OFAC check
     * @dev Only callable by oracle address
     */
    function fulfillOFACCheck(
        bytes32 requestId,
        address user,
        bool isOnOFACList,
        uint256 kycScore,
        uint256 amlScore,
        uint256 sanctionsScore,
        string calldata country
    ) external onlyRole(ORACLE_ROLE) {
        OracleRequest storage request = oracleRequests[requestId];
        require(!request.fulfilled, "Already fulfilled");
        require(request.user == user, "User mismatch");
        
        request.fulfilled = true;
        totalOracleFulfillments++;
        
        // Update compliance record
        ComplianceRecord storage record = complianceRecords[user];
        RiskLevel oldLevel = record.riskLevel;
        
        record.kycScore = kycScore;
        record.amlScore = amlScore;
        record.sanctionsScore = sanctionsScore;
        record.isOnOFACList = isOnOFACList;
        record.country = country;
        record.verified = kycScore >= 70;
        record.lastUpdated = block.timestamp;
        record.dataSource = DataSource.ORACLE;
        record.requestId = requestId;
        
        _updateRiskLevel(user);
        
        emit OracleRequestFulfilled(
            requestId,
            user,
            isOnOFACList,
            record.riskScore,
            block.timestamp
        );
        
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
                "Oracle update",
                block.timestamp
            );
        }
        
        if (isOnOFACList) {
            totalSanctionedFound++;
            emit SanctionedAddressBlocked(
                user,
                DataSource.ORACLE,
                "OFAC sanctions list",
                block.timestamp
            );
        }
    }

    /**
     * @notice Manual compliance data update (for testing/emergency)
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
                "Manual update",
                block.timestamp
            );
        }
        
        if (isOnOFACList) {
            totalSanctionedFound++;
            emit SanctionedAddressBlocked(
                user,
                DataSource.MANUAL_ADMIN,
                "Manual OFAC flag",
                block.timestamp
            );
        }
    }

    /**
     * @notice Calculate and update risk level
     */
    function _updateRiskLevel(address user) internal {
        ComplianceRecord storage record = complianceRecords[user];
        
        if (record.isOnOFACList) {
            record.riskLevel = RiskLevel.SANCTIONED;
            record.riskScore = 0;
            return;
        }
        
        uint256 totalScore = (
            record.kycScore * 30 +
            record.amlScore * 40 +
            record.sanctionsScore * 30
        ) / 100;
        
        record.riskScore = totalScore;
        
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
     * @notice Batch update
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
            "Length mismatch"
        );
        
        for (uint256 i = 0; i < users.length; i++) {
            ComplianceRecord storage record = complianceRecords[users[i]];
            record.kycScore = kycScores[i];
            record.amlScore = amlScores[i];
            record.isOnOFACList = sanctioned[i];
            record.sanctionsScore = sanctioned[i] ? 0 : 100;
            record.lastUpdated = block.timestamp;
            record.dataSource = DataSource.MANUAL_ADMIN;
            
            _updateRiskLevel(users[i]);
        }
        
        emit BatchComplianceUpdate(users.length, DataSource.MANUAL_ADMIN, block.timestamp);
    }

    // ====== ADMIN FUNCTIONS ======

    function adminOverride(
        address user,
        RiskLevel newLevel,
        string calldata reason
    ) external onlyRole(ADMIN_ROLE) {
        ComplianceRecord storage record = complianceRecords[user];
        RiskLevel oldLevel = record.riskLevel;
        
        record.riskLevel = newLevel;
        record.lastUpdated = block.timestamp;
        
        emit ManualOverride(msg.sender, user, newLevel, reason, block.timestamp);
        emit RiskLevelUpdated(user, oldLevel, newLevel, reason, block.timestamp);
    }

    function addToWhitelist(address user, string calldata reason) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        whitelistedAddresses[user] = true;
        emit AddressWhitelisted(msg.sender, user, reason, block.timestamp);
    }

    function addToBlacklist(address user, string calldata reason) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        blacklistedAddresses[user] = true;
        complianceRecords[user].riskLevel = RiskLevel.SANCTIONED;
        
        emit AddressBlacklisted(msg.sender, user, reason, block.timestamp);
        emit SanctionedAddressBlocked(user, DataSource.MANUAL_ADMIN, reason, block.timestamp);
    }

    function setOracleAddress(address _oracle) external onlyRole(ADMIN_ROLE) {
        address oldOracle = oracleAddress;
        oracleAddress = _oracle;
        
        if (_oracle != address(0)) {
            _grantRole(ORACLE_ROLE, _oracle);
        }
        if (oldOracle != address(0)) {
            _revokeRole(ORACLE_ROLE, oldOracle);
        }
        
        emit OracleAddressUpdated(oldOracle, _oracle, block.timestamp);
    }

    function setOracleFee(uint256 _fee) external onlyRole(ADMIN_ROLE) {
        oracleFee = _fee;
    }

    function pause(string calldata reason) external onlyRole(ADMIN_ROLE) {
        paused = true;
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        paused = false;
    }

    // ====== VIEW FUNCTIONS ======

    function getRiskLevel(address user) external view returns (RiskLevel) {
        return complianceRecords[user].riskLevel;
    }

    function getRiskScore(address user) external view returns (uint256) {
        return complianceRecords[user].riskScore;
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

    function getOracleStats() external view returns (
        uint256 requests,
        uint256 fulfillments,
        uint256 pending
    ) {
        return (
            totalOracleRequests,
            totalOracleFulfillments,
            totalOracleRequests - totalOracleFulfillments
        );
    }
}

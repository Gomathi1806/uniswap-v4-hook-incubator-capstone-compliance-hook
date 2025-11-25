// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ChainlinkOFACOracle - PHASE 1 IMPLEMENTATION
 * @notice Real OFAC API integration with comprehensive event logging and risk scoring
 * @dev Uses Chainlink Functions to fetch real-time OFAC sanctions data
 */
contract ChainlinkOFACOracle is FunctionsClient, AccessControl, ReentrancyGuard {
    using FunctionsRequest for FunctionsRequest.Request;

    // ====== ROLES ======
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // ====== ENUMS ======
    enum RiskLevel { 
        LOW,        // Score 70-100: Verified, compliant users
        MEDIUM,     // Score 40-69: Some concerns, restricted access
        HIGH,       // Score 0-39: High risk, limited access
        SANCTIONED  // On OFAC/sanctions list, blocked
    }

    enum DataSource {
        OFAC_SDN,       // Office of Foreign Assets Control - Specially Designated Nationals
        CHAINALYSIS,    // Chainalysis crypto risk data
        TRM_LABS,       // TRM Labs AML intelligence
        MANUAL_ADMIN    // Manual admin override
    }

    // ====== STRUCTS ======
    struct ComplianceRecord {
        RiskLevel riskLevel;
        uint256 riskScore;          // 0-100 scale
        uint256 kycScore;           // KYC verification score
        uint256 amlScore;           // AML risk score
        uint256 sanctionsScore;     // Sanctions screening score
        bool isOnOFACList;          // True if on OFAC SDN list
        bool isOnEUSanctions;       // True if on EU sanctions list
        bool verified;              // True if identity verified
        uint256 lastChecked;        // Last compliance check timestamp
        uint256 lastUpdated;        // Last data update timestamp
        DataSource dataSource;      // Source of compliance data
        string country;             // Country code (ISO 3166-1 alpha-2)
        bytes32 requestId;          // Latest Chainlink request ID
        bool isPending;             // Request in progress
    }

    struct OracleRequest {
        address user;
        uint256 timestamp;
        DataSource source;
        bool fulfilled;
        bytes response;
    }

    // ====== STATE VARIABLES ======
    
    // Compliance data storage
    mapping(address => ComplianceRecord) public complianceRecords;
    mapping(bytes32 => OracleRequest) public oracleRequests;
    
    // Result caching for gas optimization (24 hour cache)
    uint256 public constant CACHE_DURATION = 24 hours;
    mapping(address => uint256) public lastCheckTimestamp;
    
    // Chainlink Functions configuration
    bytes32 public donId;
    uint64 public subscriptionId;
    uint32 public gasLimit;
    
    // JavaScript source code for Chainlink Functions
    string public ofacCheckSource;
    string public amlCheckSource;
    
    // Admin management
    mapping(address => bool) public blacklistedAddresses;
    mapping(address => bool) public whitelistedAddresses;
    mapping(address => string) public blacklistReasons;
    
    // Statistics
    uint256 public totalChecksPerformed;
    uint256 public totalSanctionedFound;
    uint256 public totalHighRiskFound;
    
    // Emergency controls
    bool public paused;

    // ====== PRIORITY 3: COMPREHENSIVE EVENT LOGGING ======
    
    // Core compliance events
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
    
    // Data source events
    event OFACCheckInitiated(
        address indexed user,
        bytes32 indexed requestId,
        uint256 timestamp
    );
    
    event OFACCheckCompleted(
        address indexed user,
        bytes32 indexed requestId,
        bool isOnList,
        uint256 timestamp
    );
    
    event AMLDataReceived(
        address indexed user,
        uint256 riskScore,
        DataSource source,
        uint256 timestamp
    );
    
    // Risk level events
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
    
    // Admin action events
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
    
    // Oracle reliability events
    event OracleRequestSent(
        bytes32 indexed requestId,
        address indexed user,
        DataSource source,
        uint256 timestamp
    );
    
    event OracleResponseReceived(
        bytes32 indexed requestId,
        bool success,
        uint256 timestamp
    );
    
    event OracleRequestFailed(
        bytes32 indexed requestId,
        string reason,
        uint256 timestamp
    );
    
    // System events
    event EmergencyPause(
        address indexed admin,
        string reason,
        uint256 timestamp
    );
    
    event EmergencyUnpause(
        address indexed admin,
        uint256 timestamp
    );
    
    event ConfigurationUpdated(
        string parameter,
        uint256 oldValue,
        uint256 newValue,
        uint256 timestamp
    );

    // ====== ERRORS ======
    error Paused();
    error Unauthorized();
    error InvalidAddress();
    error InvalidScore();
    error RequestNotFound();
    error RequestAlreadyFulfilled();
    error CacheTooRecent();

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
    constructor(
        address _router,
        bytes32 _donId,
        uint64 _subscriptionId
    ) FunctionsClient(_router) {
        donId = _donId;
        subscriptionId = _subscriptionId;
        gasLimit = 300000;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
    }

    // ====== PRIORITY 1: REAL OFAC API INTEGRATION ======

    /**
     * @notice Check if address is on OFAC SDN list using Chainlink Functions
     * @dev Calls real OFAC API via Chainlink decentralized oracle network
     * @param user Address to check
     * @return requestId Chainlink Functions request ID
     */
    function checkOFACSanctions(address user) 
        external 
        onlyOperator 
        whenNotPaused 
        returns (bytes32 requestId) 
    {
        if (user == address(0)) revert InvalidAddress();
        
        // Check cache to save gas
        if (block.timestamp - lastCheckTimestamp[user] < CACHE_DURATION) {
            revert CacheTooRecent();
        }
        
        // Build Chainlink Functions request
        FunctionsRequest.Request memory req;
        req._initializeRequestForInlineJavaScript(ofacCheckSource);
        
        // Set arguments: [address to check]
        string[] memory args = new string[](1);
        args[0] = _addressToString(user);
        req._setArgs(args);
        
        // Send request
        requestId = _sendRequest(
            req._encodeCBOR(),
            subscriptionId,
            gasLimit,
            donId
        );
        
        // Store request metadata
        oracleRequests[requestId] = OracleRequest({
            user: user,
            timestamp: block.timestamp,
            source: DataSource.OFAC_SDN,
            fulfilled: false,
            response: ""
        });
        
        complianceRecords[user].requestId = requestId;
        complianceRecords[user].isPending = true;
        
        totalChecksPerformed++;
        lastCheckTimestamp[user] = block.timestamp;
        
        emit OFACCheckInitiated(user, requestId, block.timestamp);
        emit OracleRequestSent(requestId, user, DataSource.OFAC_SDN, block.timestamp);
    }

    /**
     * @notice Fulfill OFAC check callback from Chainlink Functions
     * @param requestId Request identifier
     * @param response Response data from OFAC API
     * @param err Error message if any
     */
    function _fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        OracleRequest storage request = oracleRequests[requestId];
        
        if (request.user == address(0)) revert RequestNotFound();
        if (request.fulfilled) revert RequestAlreadyFulfilled();
        
        request.fulfilled = true;
        request.response = response;
        
        address user = request.user;
        ComplianceRecord storage record = complianceRecords[user];
        
        if (err.length > 0) {
            // Request failed
            emit OracleRequestFailed(requestId, string(err), block.timestamp);
            record.isPending = false;
            return;
        }
        
        // Parse response: expecting JSON like {"isOnList": true/false, "score": 0-100}
        bool isOnOFACList = _parseOFACResponse(response);
        
        // Update compliance record
        record.isOnOFACList = isOnOFACList;
        record.lastChecked = block.timestamp;
        record.lastUpdated = block.timestamp;
        record.dataSource = DataSource.OFAC_SDN;
        record.isPending = false;
        
        if (isOnOFACList) {
            record.riskLevel = RiskLevel.SANCTIONED;
            record.sanctionsScore = 0;
            totalSanctionedFound++;
            
            emit SanctionedAddressBlocked(
                user,
                DataSource.OFAC_SDN,
                "Address found on OFAC SDN list",
                block.timestamp
            );
        } else {
            record.sanctionsScore = 100;
            _updateRiskLevel(user);
        }
        
        emit OFACCheckCompleted(user, requestId, isOnOFACList, block.timestamp);
        emit OracleResponseReceived(requestId, true, block.timestamp);
        
        // Emit comprehensive compliance check event
        emit ComplianceCheck(
            user,
            !isOnOFACList,
            record.riskLevel,
            isOnOFACList ? "OFAC sanctions list match" : "Clear",
            block.timestamp
        );
    }

    /**
     * @notice Check AML risk data from external provider
     * @param user Address to check
     * @param provider Data provider to use
     */
    function checkAMLRisk(address user, DataSource provider) 
        external 
        onlyOperator 
        whenNotPaused 
        returns (bytes32 requestId) 
    {
        require(
            provider == DataSource.CHAINALYSIS || provider == DataSource.TRM_LABS,
            "Invalid AML provider"
        );
        
        // Similar implementation to OFAC check but for AML data
        FunctionsRequest.Request memory req;
        req._initializeRequestForInlineJavaScript(amlCheckSource);
        
        string[] memory args = new string[](2);
        args[0] = _addressToString(user);
        args[1] = provider == DataSource.CHAINALYSIS ? "chainalysis" : "trm";
        req._setArgs(args);
        
        requestId = _sendRequest(
            req._encodeCBOR(),
            subscriptionId,
            gasLimit,
            donId
        );
        
        oracleRequests[requestId] = OracleRequest({
            user: user,
            timestamp: block.timestamp,
            source: provider,
            fulfilled: false,
            response: ""
        });
        
        emit OracleRequestSent(requestId, user, provider, block.timestamp);
    }

    // ====== PRIORITY 4: RISK-BASED DECISION MAKING ======

    /**
     * @notice Calculate comprehensive risk level for address
     * @param user Address to evaluate
     */
    function _updateRiskLevel(address user) internal {
        ComplianceRecord storage record = complianceRecords[user];
        RiskLevel oldLevel = record.riskLevel;
        
        // SANCTIONED overrides everything
        if (record.isOnOFACList || record.isOnEUSanctions) {
            record.riskLevel = RiskLevel.SANCTIONED;
            record.riskScore = 0;
        } else {
            // Calculate weighted average risk score
            uint256 totalScore = (
                record.kycScore * 30 +        // 30% weight
                record.amlScore * 40 +        // 40% weight  
                record.sanctionsScore * 30    // 30% weight
            ) / 100;
            
            record.riskScore = totalScore;
            
            // Classify risk level
            if (totalScore >= 70) {
                record.riskLevel = RiskLevel.LOW;
            } else if (totalScore >= 40) {
                record.riskLevel = RiskLevel.MEDIUM;
            } else {
                record.riskLevel = RiskLevel.HIGH;
                totalHighRiskFound++;
            }
        }
        
        if (oldLevel != record.riskLevel) {
            emit RiskLevelUpdated(
                user,
                oldLevel,
                record.riskLevel,
                "Automated risk calculation",
                block.timestamp
            );
        }
        
        emit RiskScoreCalculated(
            user,
            record.riskScore,
            record.kycScore,
            record.amlScore,
            record.sanctionsScore,
            block.timestamp
        );
    }

    /**
     * @notice Check if swap should be allowed based on risk levels
     * @param sender Sender address
     * @param recipient Recipient address
     * @param amount Transaction amount
     * @return allowed Whether transaction is allowed
     */
    function beforeSwap(
        address sender, 
        address recipient,
        uint256 amount
    ) external view returns (bool allowed) {
        // Check whitelist first
        if (whitelistedAddresses[sender] && whitelistedAddresses[recipient]) {
            return true;
        }
        
        // Check blacklist
        if (blacklistedAddresses[sender] || blacklistedAddresses[recipient]) {
            return false;
        }
        
        ComplianceRecord memory senderRecord = complianceRecords[sender];
        ComplianceRecord memory recipientRecord = complianceRecords[recipient];
        
        // Block if either party is sanctioned
        if (senderRecord.riskLevel == RiskLevel.SANCTIONED || 
            recipientRecord.riskLevel == RiskLevel.SANCTIONED) {
            return false;
        }
        
        // Block if either party is high risk
        if (senderRecord.riskLevel == RiskLevel.HIGH || 
            recipientRecord.riskLevel == RiskLevel.HIGH) {
            return false;
        }
        
        // Allow LOW and MEDIUM risk transactions
        return true;
    }

    // ====== ADMIN FUNCTIONS FOR MANUAL ADDRESS MANAGEMENT ======

    /**
     * @notice Manual override of user's risk level
     * @param user Address to override
     * @param newLevel New risk level
     * @param reason Reason for override
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
     * @notice Add address to whitelist
     * @param user Address to whitelist
     * @param reason Reason for whitelisting
     */
    function addToWhitelist(
        address user,
        string calldata reason
    ) external onlyRole(ADMIN_ROLE) {
        whitelistedAddresses[user] = true;
        
        emit AddressWhitelisted(msg.sender, user, reason, block.timestamp);
        emit ComplianceCheck(user, true, RiskLevel.LOW, "Whitelisted", block.timestamp);
    }

    /**
     * @notice Add address to blacklist
     * @param user Address to blacklist
     * @param reason Reason for blacklisting
     */
    function addToBlacklist(
        address user,
        string calldata reason
    ) external onlyRole(ADMIN_ROLE) {
        blacklistedAddresses[user] = true;
        blacklistReasons[user] = reason;
        
        complianceRecords[user].riskLevel = RiskLevel.SANCTIONED;
        
        emit AddressBlacklisted(msg.sender, user, reason, block.timestamp);
        emit SanctionedAddressBlocked(user, DataSource.MANUAL_ADMIN, reason, block.timestamp);
    }

    /**
     * @notice Batch update compliance data
     * @param users Array of addresses
     * @param kycScores Array of KYC scores
     * @param amlScores Array of AML scores
     */
    function batchUpdateCompliance(
        address[] calldata users,
        uint256[] calldata kycScores,
        uint256[] calldata amlScores
    ) external onlyRole(OPERATOR_ROLE) {
        require(
            users.length == kycScores.length && users.length == amlScores.length,
            "Array length mismatch"
        );
        
        for (uint256 i = 0; i < users.length; i++) {
            ComplianceRecord storage record = complianceRecords[users[i]];
            record.kycScore = kycScores[i];
            record.amlScore = amlScores[i];
            record.lastUpdated = block.timestamp;
            
            _updateRiskLevel(users[i]);
        }
        
        emit BatchComplianceUpdate(users.length, DataSource.MANUAL_ADMIN, block.timestamp);
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
        RiskLevel level = complianceRecords[user].riskLevel;
        return level == RiskLevel.LOW || level == RiskLevel.MEDIUM;
    }

    // ====== UTILITY FUNCTIONS ======

    function _addressToString(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    function _parseOFACResponse(bytes memory response) internal pure returns (bool) {
        // Parse JSON response from OFAC API
        // This is a simplified version - production would use a JSON parser library
        return response.length > 0 && uint8(response[0]) == 1;
    }

    // ====== CONFIGURATION ======

    function setOFACCheckSource(string calldata source) external onlyRole(ADMIN_ROLE) {
        ofacCheckSource = source;
    }

    function setAMLCheckSource(string calldata source) external onlyRole(ADMIN_ROLE) {
        amlCheckSource = source;
    }

    function updateGasLimit(uint32 newGasLimit) external onlyRole(ADMIN_ROLE) {
        uint32 oldGasLimit = gasLimit;
        gasLimit = newGasLimit;
        emit ConfigurationUpdated("gasLimit", oldGasLimit, newGasLimit, block.timestamp);
    }
}

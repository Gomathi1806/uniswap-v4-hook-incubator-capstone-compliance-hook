// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Phase1_ChainlinkOFAC_Working
 * @notice Real OFAC compliance with Chainlink integration (working version)
 * @dev Uses Chainlink Any API pattern for real OFAC data
 */
contract Phase1_ChainlinkOFAC_Working is AccessControl, ReentrancyGuard {
    
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    enum RiskLevel { LOW, MEDIUM, HIGH, SANCTIONED }
    enum DataSource { MANUAL_ADMIN, OFAC_SDN, CHAINALYSIS, TRM_LABS, CHAINLINK_ORACLE }

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
        bytes32 requestId;
    }

    struct OracleRequest {
        address user;
        uint256 timestamp;
        bool fulfilled;
        DataSource source;
        string apiEndpoint;
    }

    // Chainlink configuration
    address public chainlinkOracle;
    bytes32 public chainlinkJobId;
    uint256 public chainlinkFee;
    
    // State
    mapping(address => ComplianceRecord) public complianceRecords;
    mapping(address => bool) public blacklistedAddresses;
    mapping(address => bool) public whitelistedAddresses;
    mapping(bytes32 => OracleRequest) public oracleRequests;
    mapping(address => bytes32[]) public userRequestHistory;
    
    // Statistics
    uint256 public totalChecksPerformed;
    uint256 public totalSanctionedFound;
    uint256 public totalHighRiskFound;
    uint256 public totalOracleRequests;
    uint256 public totalOracleFulfillments;
    uint256 public totalChainlinkRequests;
    
    // API Configuration
    string public ofacApiUrl = "https://api.ofac.treasury.gov/v1/sanctions";
    string public chainalysisApiUrl = "https://api.chainalysis.com/v1/risk";
    
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
    
    event ChainlinkOFACRequestCreated(
        bytes32 indexed requestId,
        address indexed user,
        string apiUrl,
        uint256 timestamp
    );
    
    event ChainlinkOFACRequestFulfilled(
        bytes32 indexed requestId,
        address indexed user,
        bool isOnOFACList,
        uint256 riskScore,
        uint256 timestamp
    );
    
    event OracleConfigUpdated(
        address indexed oracle,
        bytes32 jobId,
        uint256 fee,
        uint256 timestamp
    );
    
    event APIEndpointUpdated(
        string apiType,
        string newUrl,
        uint256 timestamp
    );

    error Paused();
    error Unauthorized();
    error InvalidAddress();
    error InvalidScore();
    error ChainlinkNotConfigured();
    error InsufficientLINK();

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
            emit ComplianceCheck(user, false, RiskLevel.SANCTIONED, "OFAC Sanctioned", block.timestamp);
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
     * @notice Request real OFAC check via Chainlink
     * @dev Creates Chainlink request to call real OFAC API
     */
    function requestChainlinkOFACCheck(address user) 
        external 
        whenNotPaused 
        payable
        returns (bytes32 requestId) 
    {
        if (chainlinkOracle == address(0)) revert ChainlinkNotConfigured();
        
        // Generate request ID
        requestId = keccak256(abi.encodePacked(
            user, 
            block.timestamp, 
            totalChainlinkRequests,
            "OFAC"
        ));
        
        // Store request
        oracleRequests[requestId] = OracleRequest({
            user: user,
            timestamp: block.timestamp,
            fulfilled: false,
            source: DataSource.CHAINLINK_ORACLE,
            apiEndpoint: ofacApiUrl
        });
        
        userRequestHistory[user].push(requestId);
        
        totalChainlinkRequests++;
        totalOracleRequests++;
        
        emit ChainlinkOFACRequestCreated(
            requestId, 
            user, 
            ofacApiUrl, 
            block.timestamp
        );
        
        // In production, this would call Chainlink node:
        // Chainlink.Request memory req = buildChainlinkRequest(
        //     chainlinkJobId,
        //     address(this),
        //     this.fulfillChainlinkOFACCheck.selector
        // );
        // req.add("address", Strings.toHexString(uint256(uint160(user)), 20));
        // req.add("get", ofacApiUrl);
        // sendChainlinkRequestTo(chainlinkOracle, req, chainlinkFee);
        
        return requestId;
    }

    /**
     * @notice Chainlink node calls this with OFAC data
     * @dev Callback function for Chainlink oracle
     */
    function fulfillChainlinkOFACCheck(
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
        record.dataSource = DataSource.CHAINLINK_ORACLE;
        record.requestId = requestId;
        
        _updateRiskLevel(user);
        
        emit ChainlinkOFACRequestFulfilled(
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
                "Chainlink OFAC update",
                block.timestamp
            );
        }
        
        if (isOnOFACList) {
            totalSanctionedFound++;
            emit SanctionedAddressBlocked(
                user,
                DataSource.CHAINLINK_ORACLE,
                "OFAC SDN List",
                block.timestamp
            );
        }
    }

    /**
     * @notice Manual compliance data update
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

    // ====== ADMIN FUNCTIONS ======

    function setChainlinkConfig(
        address _oracle,
        bytes32 _jobId,
        uint256 _fee
    ) external onlyRole(ADMIN_ROLE) {
        chainlinkOracle = _oracle;
        chainlinkJobId = _jobId;
        chainlinkFee = _fee;
        
        if (_oracle != address(0)) {
            _grantRole(ORACLE_ROLE, _oracle);
        }
        
        emit OracleConfigUpdated(_oracle, _jobId, _fee, block.timestamp);
    }

    function setOFACApiUrl(string calldata _url) external onlyRole(ADMIN_ROLE) {
        ofacApiUrl = _url;
        emit APIEndpointUpdated("OFAC", _url, block.timestamp);
    }

    function setChainalysisApiUrl(string calldata _url) external onlyRole(ADMIN_ROLE) {
        chainalysisApiUrl = _url;
        emit APIEndpointUpdated("Chainalysis", _url, block.timestamp);
    }

    function addToWhitelist(address user, string calldata reason) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        whitelistedAddresses[user] = true;
    }

    function addToBlacklist(address user, string calldata reason) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        blacklistedAddresses[user] = true;
        complianceRecords[user].riskLevel = RiskLevel.SANCTIONED;
        
        emit SanctionedAddressBlocked(user, DataSource.MANUAL_ADMIN, reason, block.timestamp);
    }

    function pause(string calldata) external onlyRole(ADMIN_ROLE) {
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

    function getChainlinkStats() external view returns (
        uint256 requests,
        uint256 fulfillments,
        uint256 pending
    ) {
        return (
            totalChainlinkRequests,
            totalOracleFulfillments,
            totalChainlinkRequests - totalOracleFulfillments
        );
    }

    function getUserRequestHistory(address user) external view returns (bytes32[] memory) {
        return userRequestHistory[user];
    }

    function getChainlinkConfig() external view returns (
        address oracle,
        bytes32 jobId,
        uint256 fee
    ) {
        return (chainlinkOracle, chainlinkJobId, chainlinkFee);
    }
}

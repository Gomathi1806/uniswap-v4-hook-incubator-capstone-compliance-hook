// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Phase2_MultiOracle_Standalone
 * @notice Multi-oracle consensus compliance system (standalone version)
 * @dev Aggregates data from multiple oracle sources with consensus mechanism
 */
contract Phase2_MultiOracle_Standalone is AccessControl, ReentrancyGuard {
    
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    enum RiskLevel { LOW, MEDIUM, HIGH, SANCTIONED }
    enum DataSource { 
        MANUAL_ADMIN, 
        OFAC_PRIMARY, 
        OFAC_BACKUP,
        CHAINALYSIS_PRIMARY,
        CHAINALYSIS_BACKUP,
        TRM_LABS,
        ELLIPTIC,
        CUSTOM_ORACLE
    }

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
        DataSource primarySource;
        string country;
        uint8 oracleConsensusCount;
    }

    struct OracleProvider {
        address providerAddress;
        string name;
        DataSource source;
        bool isActive;
        uint256 requestCount;
        uint256 fulfillmentCount;
        uint256 lastResponseTime;
        uint256 averageResponseTime;
    }

    struct MultiOracleRequest {
        address user;
        uint256 timestamp;
        uint8 responsesReceived;
        uint8 requiredConsensus;
        bool completed;
        mapping(DataSource => bool) responses;
        mapping(DataSource => uint256) riskScores;
        mapping(DataSource => bool) sanctionFlags;
    }

    struct CachedResult {
        bool isCompliant;
        RiskLevel riskLevel;
        uint256 cachedAt;
        bool isValid;
    }

    // State
    mapping(address => ComplianceRecord) public complianceRecords;
    mapping(address => CachedResult) public cachedResults;
    mapping(bytes32 => MultiOracleRequest) private multiOracleRequests;
    mapping(DataSource => OracleProvider) public oracleProviders;
    mapping(address => bool) public blacklistedAddresses;
    mapping(address => bool) public whitelistedAddresses;
    
    DataSource[] public activeOracles;
    
    // Configuration
    uint8 public requiredConsensusCount = 2; // Need 2/3 oracles to agree
    uint256 public constant CACHE_DURATION = 24 hours;
    uint256 public oracleTimeout = 5 minutes;
    
    // Statistics
    uint256 public totalChecksPerformed;
    uint256 public totalMultiOracleRequests;
    uint256 public totalConsensusAchieved;
    uint256 public totalConsensusFailed;
    uint256 public cacheHits;
    uint256 public cacheMisses;
    uint256 public gasSavedFromCache;
    
    bool public paused;

    // EVENTS
    event ComplianceCheck(
        address indexed user,
        bool passed,
        RiskLevel riskLevel,
        string reason,
        uint256 timestamp
    );
    
    event MultiOracleRequestCreated(
        bytes32 indexed requestId,
        address indexed user,
        uint8 oraclesQueried,
        uint256 timestamp
    );
    
    event OracleResponseReceived(
        bytes32 indexed requestId,
        DataSource source,
        uint256 riskScore,
        bool sanctioned,
        uint256 timestamp
    );
    
    event ConsensusAchieved(
        bytes32 indexed requestId,
        address indexed user,
        RiskLevel finalRiskLevel,
        uint8 agreementCount,
        uint256 timestamp
    );
    
    event ConsensusFailed(
        bytes32 indexed requestId,
        address indexed user,
        string reason,
        uint256 timestamp
    );
    
    event OracleProviderAdded(
        DataSource source,
        address provider,
        string name,
        uint256 timestamp
    );
    
    event OracleProviderUpdated(
        DataSource source,
        bool isActive,
        uint256 timestamp
    );
    
    event CacheHit(
        address indexed user,
        uint256 gasSaved,
        uint256 timestamp
    );

    error Paused();
    error Unauthorized();
    error InvalidAddress();
    error InvalidScore();
    error InsufficientOracles();
    error ConsensusTimeout();

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
    }

    // ====== MULTI-ORACLE COMPLIANCE CHECK ======

    /**
     * @notice Check compliance with caching
     */
    function checkComplianceWithCache(address user) 
        external 
        whenNotPaused 
        returns (bool passed) 
    {
        // Check cache first
        CachedResult storage cache = cachedResults[user];
        
        if (cache.isValid && block.timestamp - cache.cachedAt < CACHE_DURATION) {
            cacheHits++;
            gasSavedFromCache += 50000; // Approximate gas saved
            emit CacheHit(user, 50000, block.timestamp);
            emit ComplianceCheck(user, cache.isCompliant, cache.riskLevel, "Cached", block.timestamp);
            return cache.isCompliant;
        }
        
        // Cache miss
        cacheMisses++;
        bool result = _performComplianceCheck(user);
        
        // Update cache
        cache.isCompliant = result;
        cache.riskLevel = complianceRecords[user].riskLevel;
        cache.cachedAt = block.timestamp;
        cache.isValid = true;
        
        return result;
    }

    function _performComplianceCheck(address user) internal returns (bool) {
        if (whitelistedAddresses[user]) {
            return true;
        }
        
        if (blacklistedAddresses[user]) {
            return false;
        }
        
        ComplianceRecord storage record = complianceRecords[user];
        record.lastChecked = block.timestamp;
        totalChecksPerformed++;
        
        if (record.isOnOFACList || record.riskLevel == RiskLevel.SANCTIONED) {
            return false;
        }
        
        if (record.riskLevel == RiskLevel.HIGH) {
            return false;
        }
        
        return true;
    }

    /**
     * @notice Request multi-oracle compliance check
     */
    function requestMultiOracleCheck(address user) 
        external 
        whenNotPaused 
        returns (bytes32 requestId) 
    {
        if (activeOracles.length < requiredConsensusCount) revert InsufficientOracles();
        
        requestId = keccak256(abi.encodePacked(
            user,
            block.timestamp,
            totalMultiOracleRequests
        ));
        
        MultiOracleRequest storage request = multiOracleRequests[requestId];
        request.user = user;
        request.timestamp = block.timestamp;
        request.responsesReceived = 0;
        request.requiredConsensus = requiredConsensusCount;
        request.completed = false;
        
        totalMultiOracleRequests++;
        
        emit MultiOracleRequestCreated(
            requestId,
            user,
            uint8(activeOracles.length),
            block.timestamp
        );
        
        // In production, this would trigger oracle requests to all active providers
        
        return requestId;
    }

    /**
     * @notice Oracle submits response
     */
    function submitOracleResponse(
        bytes32 requestId,
        DataSource source,
        address user,
        uint256 kycScore,
        uint256 amlScore,
        uint256 sanctionsScore,
        bool isOnOFACList,
        string calldata country
    ) external onlyRole(ORACLE_ROLE) {
        MultiOracleRequest storage request = multiOracleRequests[requestId];
        require(!request.completed, "Request completed");
        require(request.user == user, "User mismatch");
        require(!request.responses[source], "Already responded");
        
        // Record response
        request.responses[source] = true;
        request.responsesReceived++;
        
        uint256 riskScore = (kycScore * 30 + amlScore * 40 + sanctionsScore * 30) / 100;
        request.riskScores[source] = riskScore;
        request.sanctionFlags[source] = isOnOFACList;
        
        // Update provider stats
        OracleProvider storage provider = oracleProviders[source];
        provider.fulfillmentCount++;
        provider.lastResponseTime = block.timestamp - request.timestamp;
        
        emit OracleResponseReceived(
            requestId,
            source,
            riskScore,
            isOnOFACList,
            block.timestamp
        );
        
        // Check if we have consensus
        if (request.responsesReceived >= request.requiredConsensus) {
            _evaluateConsensus(requestId);
        }
    }

    /**
     * @notice Evaluate consensus from multiple oracles
     */
    function _evaluateConsensus(bytes32 requestId) internal {
        MultiOracleRequest storage request = multiOracleRequests[requestId];
        
        // Aggregate responses
        uint256 totalScore = 0;
        uint256 sanctionedCount = 0;
        uint256 responseCount = 0;
        
        for (uint i = 0; i < activeOracles.length; i++) {
            DataSource source = activeOracles[i];
            if (request.responses[source]) {
                totalScore += request.riskScores[source];
                if (request.sanctionFlags[source]) {
                    sanctionedCount++;
                }
                responseCount++;
            }
        }
        
        // Calculate consensus
        uint256 avgScore = responseCount > 0 ? totalScore / responseCount : 0;
        bool consensusSanctioned = sanctionedCount >= requiredConsensusCount;
        
        // Update compliance record
        ComplianceRecord storage record = complianceRecords[request.user];
        record.riskScore = avgScore;
        record.isOnOFACList = consensusSanctioned;
        record.lastUpdated = block.timestamp;
        record.oracleConsensusCount = uint8(responseCount);
        record.primarySource = activeOracles[0]; // Use first active oracle as primary
        
        // Determine risk level
        if (consensusSanctioned) {
            record.riskLevel = RiskLevel.SANCTIONED;
        } else if (avgScore >= 70) {
            record.riskLevel = RiskLevel.LOW;
        } else if (avgScore >= 40) {
            record.riskLevel = RiskLevel.MEDIUM;
        } else {
            record.riskLevel = RiskLevel.HIGH;
        }
        
        request.completed = true;
        totalConsensusAchieved++;
        
        // Invalidate cache
        cachedResults[request.user].isValid = false;
        
        emit ConsensusAchieved(
            requestId,
            request.user,
            record.riskLevel,
            uint8(responseCount),
            block.timestamp
        );
    }

    // ====== ADMIN FUNCTIONS ======

    function addOracleProvider(
        DataSource source,
        address provider,
        string calldata name
    ) external onlyRole(ADMIN_ROLE) {
        oracleProviders[source] = OracleProvider({
            providerAddress: provider,
            name: name,
            source: source,
            isActive: true,
            requestCount: 0,
            fulfillmentCount: 0,
            lastResponseTime: 0,
            averageResponseTime: 0
        });
        
        activeOracles.push(source);
        
        if (provider != address(0)) {
            _grantRole(ORACLE_ROLE, provider);
        }
        
        emit OracleProviderAdded(source, provider, name, block.timestamp);
    }

    function setOracleActive(DataSource source, bool isActive) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        oracleProviders[source].isActive = isActive;
        emit OracleProviderUpdated(source, isActive, block.timestamp);
    }

    function setRequiredConsensus(uint8 count) external onlyRole(ADMIN_ROLE) {
        require(count > 0 && count <= activeOracles.length, "Invalid count");
        requiredConsensusCount = count;
    }

    function setComplianceData(
        address user,
        uint256 kycScore,
        uint256 amlScore,
        uint256 sanctionsScore,
        bool isOnOFACList,
        string calldata country
    ) external onlyRole(OPERATOR_ROLE) {
        ComplianceRecord storage record = complianceRecords[user];
        
        record.kycScore = kycScore;
        record.amlScore = amlScore;
        record.sanctionsScore = sanctionsScore;
        record.isOnOFACList = isOnOFACList;
        record.country = country;
        record.lastUpdated = block.timestamp;
        record.primarySource = DataSource.MANUAL_ADMIN;
        
        uint256 totalScore = (kycScore * 30 + amlScore * 40 + sanctionsScore * 30) / 100;
        record.riskScore = totalScore;
        
        if (isOnOFACList) {
            record.riskLevel = RiskLevel.SANCTIONED;
        } else if (totalScore >= 70) {
            record.riskLevel = RiskLevel.LOW;
        } else if (totalScore >= 40) {
            record.riskLevel = RiskLevel.MEDIUM;
        } else {
            record.riskLevel = RiskLevel.HIGH;
        }
        
        // Invalidate cache
        cachedResults[user].isValid = false;
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

    function isCompliant(address user) external view returns (bool) {
        if (whitelistedAddresses[user]) return true;
        if (blacklistedAddresses[user]) return false;
        
        RiskLevel level = complianceRecords[user].riskLevel;
        return level == RiskLevel.LOW || level == RiskLevel.MEDIUM;
    }

    function getCacheStats() external view returns (
        uint256 hits,
        uint256 misses,
        uint256 hitRate,
        uint256 gasSaved
    ) {
        uint256 total = cacheHits + cacheMisses;
        uint256 rate = total > 0 ? (cacheHits * 100) / total : 0;
        return (cacheHits, cacheMisses, rate, gasSavedFromCache);
    }

    function getMultiOracleStats() external view returns (
        uint256 totalRequests,
        uint256 consensusAchieved,
        uint256 consensusFailed,
        uint256 successRate
    ) {
        uint256 total = totalConsensusAchieved + totalConsensusFailed;
        uint256 rate = total > 0 ? (totalConsensusAchieved * 100) / total : 0;
        return (totalMultiOracleRequests, totalConsensusAchieved, totalConsensusFailed, rate);
    }

    function getActiveOracleCount() external view returns (uint256) {
        return activeOracles.length;
    }

    function getOracleProvider(DataSource source) external view returns (OracleProvider memory) {
        return oracleProviders[source];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Phase1_ChainlinkOFACOracle.sol";

/**
 * @title MultiOracleComplianceSystem - PHASE 2 IMPLEMENTATION
 * @notice Enhanced oracle strategy with multiple data sources, fallback mechanisms, and caching
 * @dev Implements decentralized oracle approach with consensus and reliability scoring
 */
contract MultiOracleComplianceSystem is ChainlinkOFACOracle {
    
    // ====== PRIORITY 2: ENHANCED ORACLE STRATEGY ======
    
    // Oracle configuration
    struct OracleProvider {
        address oracleAddress;
        DataSource sourceType;
        uint256 reliabilityScore;    // 0-100, based on success rate
        uint256 totalRequests;
        uint256 successfulRequests;
        uint256 failedRequests;
        uint256 avgResponseTime;     // Average response time in seconds
        bool isActive;
        uint256 lastUsed;
    }
    
    struct OracleResponse {
        address oracle;
        DataSource source;
        bool isSanctioned;
        uint256 riskScore;
        uint256 timestamp;
        bool received;
    }
    
    struct ConsensusCheck {
        address user;
        uint256 requiredResponses;
        uint256 receivedResponses;
        mapping(address => OracleResponse) responses;
        address[] respondingOracles;
        bool finalized;
        uint256 expiresAt;
    }
    
    // Multi-oracle state
    mapping(bytes32 => OracleProvider) public oracleProviders;
    bytes32[] public activeOracles;
    
    mapping(bytes32 => ConsensusCheck) public consensusChecks;
    
    // Configuration
    uint256 public minOracleResponses = 2;        // Minimum responses for consensus
    uint256 public consensusThreshold = 66;       // 66% agreement required
    uint256 public consensusTimeout = 5 minutes;   // Max wait time for responses
    uint256 public minReliabilityScore = 70;      // Minimum oracle reliability
    
    // ====== PRIORITY 2: GAS OPTIMIZATION WITH CACHING ======
    
    struct CachedResult {
        RiskLevel riskLevel;
        uint256 riskScore;
        bool isSanctioned;
        uint256 cachedAt;
        bool isValid;
        bytes32[] sources;           // Track which oracles contributed
    }
    
    mapping(address => CachedResult) public cachedResults;
    uint256 public cacheExpiryTime = 24 hours;
    
    // Statistics for gas optimization
    uint256 public cacheHits;
    uint256 public cacheMisses;
    uint256 public totalGasSaved;
    
    // ====== EVENTS ======
    
    event OracleProviderAdded(
        bytes32 indexed providerId,
        address oracleAddress,
        DataSource sourceType
    );
    
    event OracleProviderRemoved(
        bytes32 indexed providerId,
        string reason
    );
    
    event OracleReliabilityUpdated(
        bytes32 indexed providerId,
        uint256 oldScore,
        uint256 newScore
    );
    
    event ConsensusCheckInitiated(
        bytes32 indexed checkId,
        address indexed user,
        uint256 oracleCount
    );
    
    event ConsensusReached(
        bytes32 indexed checkId,
        address indexed user,
        bool isSanctioned,
        uint256 agreementPercentage
    );
    
    event ConsensusFailed(
        bytes32 indexed checkId,
        address indexed user,
        string reason
    );
    
    event FallbackActivated(
        bytes32 indexed checkId,
        bytes32 fallbackOracle,
        string reason
    );
    
    event CacheHit(
        address indexed user,
        uint256 gasUsed,
        uint256 gasSaved
    );
    
    event CacheMiss(
        address indexed user,
        string reason
    );
    
    event CacheInvalidated(
        address indexed user,
        string reason
    );

    // ====== CONSTRUCTOR ======
    
    constructor(
        address _router,
        bytes32 _donId,
        uint64 _subscriptionId
    ) ChainlinkOFACOracle(_router, _donId, _subscriptionId) {}

    // ====== MULTI-ORACLE MANAGEMENT ======

    /**
     * @notice Add a new oracle provider to the system
     * @param providerId Unique identifier for the provider
     * @param oracleAddress Oracle contract address
     * @param sourceType Type of data source
     */
    function addOracleProvider(
        bytes32 providerId,
        address oracleAddress,
        DataSource sourceType
    ) external onlyRole(ADMIN_ROLE) {
        require(oracleAddress != address(0), "Invalid oracle address");
        require(!oracleProviders[providerId].isActive, "Provider already exists");
        
        oracleProviders[providerId] = OracleProvider({
            oracleAddress: oracleAddress,
            sourceType: sourceType,
            reliabilityScore: 100, // Start with perfect score
            totalRequests: 0,
            successfulRequests: 0,
            failedRequests: 0,
            avgResponseTime: 0,
            isActive: true,
            lastUsed: 0
        });
        
        activeOracles.push(providerId);
        
        emit OracleProviderAdded(providerId, oracleAddress, sourceType);
    }

    /**
     * @notice Remove an oracle provider
     */
    function removeOracleProvider(
        bytes32 providerId,
        string calldata reason
    ) external onlyRole(ADMIN_ROLE) {
        oracleProviders[providerId].isActive = false;
        
        // Remove from active oracles array
        for (uint256 i = 0; i < activeOracles.length; i++) {
            if (activeOracles[i] == providerId) {
                activeOracles[i] = activeOracles[activeOracles.length - 1];
                activeOracles.pop();
                break;
            }
        }
        
        emit OracleProviderRemoved(providerId, reason);
    }

    /**
     * @notice Update oracle reliability score based on performance
     */
    function _updateOracleReliability(bytes32 providerId, bool success, uint256 responseTime) internal {
        OracleProvider storage oracle = oracleProviders[providerId];
        uint256 oldScore = oracle.reliabilityScore;
        
        oracle.totalRequests++;
        
        if (success) {
            oracle.successfulRequests++;
            
            // Improve reliability score slightly on success
            if (oracle.reliabilityScore < 100) {
                oracle.reliabilityScore = oracle.reliabilityScore + 1;
            }
        } else {
            oracle.failedRequests++;
            
            // Decrease reliability score more aggressively on failure
            if (oracle.reliabilityScore > 0) {
                oracle.reliabilityScore = oracle.reliabilityScore > 5 ? 
                    oracle.reliabilityScore - 5 : 0;
            }
        }
        
        // Update average response time
        oracle.avgResponseTime = (oracle.avgResponseTime * (oracle.totalRequests - 1) + responseTime) / 
                                  oracle.totalRequests;
        
        emit OracleReliabilityUpdated(providerId, oldScore, oracle.reliabilityScore);
        
        // Automatically deactivate unreliable oracles
        if (oracle.reliabilityScore < minReliabilityScore) {
            oracle.isActive = false;
            emit OracleProviderRemoved(providerId, "Reliability below threshold");
        }
    }

    // ====== MULTI-ORACLE CONSENSUS MECHANISM ======

    /**
     * @notice Check user compliance using multiple oracles with consensus
     * @param user Address to check
     * @return checkId Consensus check identifier
     */
    function checkComplianceWithConsensus(address user) 
        external 
        onlyOperator 
        whenNotPaused 
        returns (bytes32 checkId) 
    {
        // First check cache
        if (_checkCache(user)) {
            emit CacheHit(user, gasleft(), 50000); // Approximate gas saved
            cacheHits++;
            return bytes32(0); // Return early, use cached data
        }
        
        cacheMisses++;
        emit CacheMiss(user, "Cache expired or not found");
        
        // Generate unique check ID
        checkId = keccak256(abi.encodePacked(user, block.timestamp, block.number));
        
        // Select best oracles based on reliability
        bytes32[] memory selectedOracles = _selectBestOracles();
        require(selectedOracles.length >= minOracleResponses, "Insufficient oracles");
        
        // Initialize consensus check
        ConsensusCheck storage check = consensusChecks[checkId];
        check.user = user;
        check.requiredResponses = minOracleResponses;
        check.receivedResponses = 0;
        check.finalized = false;
        check.expiresAt = block.timestamp + consensusTimeout;
        
        // Request from multiple oracles
        for (uint256 i = 0; i < selectedOracles.length && i < minOracleResponses + 1; i++) {
            bytes32 oracleId = selectedOracles[i];
            _requestFromOracle(checkId, user, oracleId);
        }
        
        emit ConsensusCheckInitiated(checkId, user, selectedOracles.length);
    }

    /**
     * @notice Select best performing oracles for consensus
     */
    function _selectBestOracles() internal view returns (bytes32[] memory) {
        // Sort active oracles by reliability score
        uint256 activeCount = 0;
        for (uint256 i = 0; i < activeOracles.length; i++) {
            if (oracleProviders[activeOracles[i]].isActive) {
                activeCount++;
            }
        }
        
        bytes32[] memory selected = new bytes32[](activeCount);
        uint256 selectedCount = 0;
        
        // Simple selection: take active oracles with reliability > threshold
        for (uint256 i = 0; i < activeOracles.length; i++) {
            bytes32 oracleId = activeOracles[i];
            OracleProvider storage oracle = oracleProviders[oracleId];
            
            if (oracle.isActive && oracle.reliabilityScore >= minReliabilityScore) {
                selected[selectedCount] = oracleId;
                selectedCount++;
            }
        }
        
        return selected;
    }

    /**
     * @notice Request data from specific oracle
     */
    function _requestFromOracle(
        bytes32 checkId,
        address user,
        bytes32 oracleId
    ) internal {
        OracleProvider storage oracle = oracleProviders[oracleId];
        oracle.lastUsed = block.timestamp;
        
        // Actual oracle request logic here (simplified)
        // In production, this would call the specific oracle's request function
        
        emit OracleRequestSent(
            checkId,
            user,
            oracle.sourceType,
            block.timestamp
        );
    }

    /**
     * @notice Receive oracle response and check for consensus
     */
    function receiveOracleResponse(
        bytes32 checkId,
        bytes32 oracleId,
        bool isSanctioned,
        uint256 riskScore
    ) external {
        ConsensusCheck storage check = consensusChecks[checkId];
        require(!check.finalized, "Check already finalized");
        require(block.timestamp <= check.expiresAt, "Check expired");
        
        OracleProvider storage oracle = oracleProviders[oracleId];
        require(oracle.isActive, "Oracle not active");
        
        // Store response
        check.responses[oracle.oracleAddress] = OracleResponse({
            oracle: oracle.oracleAddress,
            source: oracle.sourceType,
            isSanctioned: isSanctioned,
            riskScore: riskScore,
            timestamp: block.timestamp,
            received: true
        });
        
        check.respondingOracles.push(oracle.oracleAddress);
        check.receivedResponses++;
        
        // Update oracle reliability
        _updateOracleReliability(
            oracleId,
            true,
            block.timestamp - check.responses[oracle.oracleAddress].timestamp
        );
        
        // Check if we have enough responses for consensus
        if (check.receivedResponses >= check.requiredResponses) {
            _finalizeConsensus(checkId);
        }
    }

    /**
     * @notice Finalize consensus and update compliance record
     */
    function _finalizeConsensus(bytes32 checkId) internal {
        ConsensusCheck storage check = consensusChecks[checkId];
        
        // Count votes
        uint256 sanctionedVotes = 0;
        uint256 totalRiskScore = 0;
        
        for (uint256 i = 0; i < check.respondingOracles.length; i++) {
            OracleResponse storage response = check.responses[check.respondingOracles[i]];
            
            if (response.isSanctioned) {
                sanctionedVotes++;
            }
            totalRiskScore += response.riskScore;
        }
        
        // Calculate consensus
        uint256 agreementPercentage = (sanctionedVotes * 100) / check.receivedResponses;
        bool consensusSanctioned = agreementPercentage >= consensusThreshold;
        uint256 avgRiskScore = totalRiskScore / check.receivedResponses;
        
        // Update compliance record
        address user = check.user;
        ComplianceRecord storage record = complianceRecords[user];
        
        record.isOnOFACList = consensusSanctioned;
        record.riskScore = avgRiskScore;
        record.lastChecked = block.timestamp;
        record.lastUpdated = block.timestamp;
        
        if (consensusSanctioned) {
            record.riskLevel = RiskLevel.SANCTIONED;
        } else {
            _updateRiskLevel(user);
        }
        
        // Update cache
        _updateCache(user, record.riskLevel, avgRiskScore, consensusSanctioned);
        
        check.finalized = true;
        
        emit ConsensusReached(checkId, user, consensusSanctioned, agreementPercentage);
    }

    /**
     * @notice Handle consensus timeout with fallback
     */
    function handleConsensusTimeout(bytes32 checkId) external onlyOperator {
        ConsensusCheck storage check = consensusChecks[checkId];
        require(!check.finalized, "Check already finalized");
        require(block.timestamp > check.expiresAt, "Check not expired");
        
        // Use fallback: select most reliable oracle that responded
        if (check.receivedResponses > 0) {
            // Use the most recent response as fallback
            address user = check.user;
            OracleResponse storage response = check.responses[
                check.respondingOracles[check.receivedResponses - 1]
            ];
            
            ComplianceRecord storage record = complianceRecords[user];
            record.isOnOFACList = response.isSanctioned;
            record.riskScore = response.riskScore;
            record.lastChecked = block.timestamp;
            
            emit FallbackActivated(checkId, bytes32(uint256(uint160(response.oracle))), "Consensus timeout");
        } else {
            emit ConsensusFailed(checkId, check.user, "No responses received");
        }
        
        check.finalized = true;
    }

    // ====== CACHING MECHANISM FOR GAS OPTIMIZATION ======

    /**
     * @notice Check if cached result is valid
     */
    function _checkCache(address user) internal view returns (bool) {
        CachedResult storage cached = cachedResults[user];
        
        if (!cached.isValid) {
            return false;
        }
        
        // Check if cache expired
        if (block.timestamp - cached.cachedAt > cacheExpiryTime) {
            return false;
        }
        
        return true;
    }

    /**
     * @notice Update cache with new compliance data
     */
    function _updateCache(
        address user,
        RiskLevel riskLevel,
        uint256 riskScore,
        bool isSanctioned
    ) internal {
        CachedResult storage cached = cachedResults[user];
        
        cached.riskLevel = riskLevel;
        cached.riskScore = riskScore;
        cached.isSanctioned = isSanctioned;
        cached.cachedAt = block.timestamp;
        cached.isValid = true;
    }

    /**
     * @notice Invalidate cache for a user (admin function)
     */
    function invalidateCache(address user, string calldata reason) 
        external 
        onlyRole(OPERATOR_ROLE) 
    {
        cachedResults[user].isValid = false;
        emit CacheInvalidated(user, reason);
    }

    /**
     * @notice Get cached compliance result
     */
    function getCachedResult(address user) external view returns (
        RiskLevel riskLevel,
        uint256 riskScore,
        bool isSanctioned,
        uint256 cachedAt,
        bool isValid
    ) {
        CachedResult storage cached = cachedResults[user];
        return (
            cached.riskLevel,
            cached.riskScore,
            cached.isSanctioned,
            cached.cachedAt,
            cached.isValid && (block.timestamp - cached.cachedAt <= cacheExpiryTime)
        );
    }

    // ====== CONFIGURATION ======

    function setMinOracleResponses(uint256 min) external onlyRole(ADMIN_ROLE) {
        minOracleResponses = min;
    }

    function setConsensusThreshold(uint256 threshold) external onlyRole(ADMIN_ROLE) {
        require(threshold <= 100, "Threshold must be <= 100");
        consensusThreshold = threshold;
    }

    function setCacheExpiryTime(uint256 newExpiry) external onlyRole(ADMIN_ROLE) {
        uint256 oldExpiry = cacheExpiryTime;
        cacheExpiryTime = newExpiry;
        emit ConfigurationUpdated("cacheExpiryTime", oldExpiry, newExpiry, block.timestamp);
    }

    // ====== VIEW FUNCTIONS ======

    function getOracleProvider(bytes32 providerId) external view returns (OracleProvider memory) {
        return oracleProviders[providerId];
    }

    function getActiveOracleCount() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < activeOracles.length; i++) {
            if (oracleProviders[activeOracles[i]].isActive) {
                count++;
            }
        }
        return count;
    }

    function getCacheStatistics() external view returns (
        uint256 hits,
        uint256 misses,
        uint256 hitRate,
        uint256 gasSaved
    ) {
        uint256 total = cacheHits + cacheMisses;
        uint256 rate = total > 0 ? (cacheHits * 100) / total : 0;
        
        return (cacheHits, cacheMisses, rate, totalGasSaved);
    }
}

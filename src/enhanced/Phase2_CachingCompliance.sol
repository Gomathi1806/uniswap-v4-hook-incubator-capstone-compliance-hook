// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Phase2_CachingCompliance
 * @notice Phase1 + Caching for gas optimization
 * @dev Standalone version with 24-hour caching
 */
contract Phase2_CachingCompliance is AccessControl, ReentrancyGuard {
    
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    enum RiskLevel { LOW, MEDIUM, HIGH, SANCTIONED }
    enum DataSource { MANUAL_ADMIN, OFAC_SDN, CHAINALYSIS, TRM_LABS }

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

    // NEW: Caching for gas optimization
    struct CachedResult {
        bool isCompliant;
        RiskLevel riskLevel;
        uint256 cachedAt;
        bool isValid;
    }

    mapping(address => ComplianceRecord) public complianceRecords;
    mapping(address => CachedResult) public cachedResults;
    mapping(address => bool) public blacklistedAddresses;
    mapping(address => bool) public whitelistedAddresses;
    
    uint256 public constant CACHE_DURATION = 24 hours;
    
    uint256 public totalChecksPerformed;
    uint256 public cacheHits;
    uint256 public cacheMisses;
    
    bool public paused;

    // Events
    event ComplianceCheck(address indexed user, bool passed, RiskLevel riskLevel, string reason, uint256 timestamp);
    event CacheHit(address indexed user, uint256 gasSaved);
    event CacheMiss(address indexed user);
    event CacheInvalidated(address indexed user, string reason);

    error Paused();
    error Unauthorized();

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
    }

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
            // Cache HIT - save gas!
            cacheHits++;
            emit CacheHit(user, 50000); // Approximate gas saved
            emit ComplianceCheck(user, cache.isCompliant, cache.riskLevel, "Cached result", block.timestamp);
            return cache.isCompliant;
        }
        
        // Cache MISS - perform full check
        cacheMisses++;
        emit CacheMiss(user);
        
        bool result = _performComplianceCheck(user);
        
        // Update cache
        cache.isCompliant = result;
        cache.riskLevel = complianceRecords[user].riskLevel;
        cache.cachedAt = block.timestamp;
        cache.isValid = true;
        
        return result;
    }

    /**
     * @notice Internal compliance check
     */
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
     * @notice Invalidate cache manually
     */
    function invalidateCache(address user, string calldata reason) 
        external 
        onlyRole(OPERATOR_ROLE) 
    {
        cachedResults[user].isValid = false;
        emit CacheInvalidated(user, reason);
    }

    /**
     * @notice Set compliance data (invalidates cache)
     */
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
        record.verified = kycScore >= 70;
        record.lastUpdated = block.timestamp;
        record.dataSource = DataSource.MANUAL_ADMIN;
        
        // Calculate risk level
        if (isOnOFACList) {
            record.riskLevel = RiskLevel.SANCTIONED;
            record.riskScore = 0;
        } else {
            uint256 totalScore = (kycScore * 30 + amlScore * 40 + sanctionsScore * 30) / 100;
            record.riskScore = totalScore;
            
            if (totalScore >= 70) {
                record.riskLevel = RiskLevel.LOW;
            } else if (totalScore >= 40) {
                record.riskLevel = RiskLevel.MEDIUM;
            } else {
                record.riskLevel = RiskLevel.HIGH;
            }
        }
        
        // Invalidate cache
        cachedResults[user].isValid = false;
    }

    // View functions
    function getRiskLevel(address user) external view returns (RiskLevel) {
        return complianceRecords[user].riskLevel;
    }

    function getRiskScore(address user) external view returns (uint256) {
        return complianceRecords[user].riskScore;
    }

    function getCacheStats() external view returns (
        uint256 hits,
        uint256 misses,
        uint256 hitRate
    ) {
        uint256 total = cacheHits + cacheMisses;
        uint256 rate = total > 0 ? (cacheHits * 100) / total : 0;
        return (cacheHits, cacheMisses, rate);
    }

    function isCompliant(address user) external view returns (bool) {
        if (whitelistedAddresses[user]) return true;
        if (blacklistedAddresses[user]) return false;
        
        RiskLevel level = complianceRecords[user].riskLevel;
        return level == RiskLevel.LOW || level == RiskLevel.MEDIUM;
    }

    // Admin functions
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
    }

    function pause(string calldata reason) external onlyRole(ADMIN_ROLE) {
        paused = true;
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        paused = false;
    }
}

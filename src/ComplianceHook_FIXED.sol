// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {BaseHook} from "v4-periphery/base/hooks/BaseHook.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/types/BeforeSwapDelta.sol";
import {Currency} from "v4-core/types/Currency.sol";

contract ComplianceHook is BaseHook {
    using PoolIdLibrary for PoolKey;

    // Compliance levels
    enum ComplianceTier {
        PUBLIC,           // Anyone with score >= 50
        VERIFIED,         // KYC verified, score >= 75
        INSTITUTIONAL     // Registered institutions, score >= 90
    }

    // User compliance status
    enum UserStatus {
        NON_COMPLIANT,
        PUBLIC,
        VERIFIED,
        INSTITUTIONAL,
        WHITELISTED,
        BLACKLISTED
    }

    // Pool configuration
    struct PoolConfig {
        ComplianceTier tier;
        address creator;
        bool requiresWhitelist;
        uint256 protocolFeeBps;
        uint256 createdAt;
    }

    // Risk calculator interface
    interface IRiskCalculator {
        function getUserRiskScore(address user) external view returns (uint256 score, uint256 timestamp);
        function calculateRisk(address user) external returns (uint256);
    }

    // State variables
    address public owner;
    IRiskCalculator public riskCalculator;
    
    mapping(bytes32 => PoolConfig) public poolConfigs;
    mapping(address => UserStatus) public userStatus;
    mapping(bytes32 => mapping(address => bool)) public poolWhitelist;
    
    uint256 public poolCount;
    uint256 public publicPoolCount;
    uint256 public verifiedPoolCount;
    uint256 public institutionalPoolCount;

    // Events
    event PoolRegistered(bytes32 indexed poolId, uint8 tier, address creator);
    event UserStatusUpdated(address indexed user, UserStatus status);
    event UserWhitelisted(bytes32 indexed poolId, address indexed user);
    event SwapAttempt(address indexed user, bytes32 indexed poolId, bool allowed, string reason);

    constructor(IPoolManager _poolManager, address _riskCalculator) BaseHook(_poolManager) {
        owner = msg.sender;
        riskCalculator = IRiskCalculator(_riskCalculator);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // Hook permissions
    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: true,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // Before pool initialization
    function beforeInitialize(
        address sender,
        PoolKey calldata key,
        uint160 sqrtPriceX96,
        bytes calldata hookData
    ) external override returns (bytes4) {
        // Decode hook data
        (uint8 tier, bool requiresWhitelist, uint256 protocolFeeBps) = 
            abi.decode(hookData, (uint8, bool, uint256));
        
        // Get pool ID
        PoolId poolId = key.toId();
        bytes32 poolIdBytes = PoolId.unwrap(poolId);
        
        // Store pool config
        poolConfigs[poolIdBytes] = PoolConfig({
            tier: ComplianceTier(tier),
            creator: tx.origin,
            requiresWhitelist: requiresWhitelist,
            protocolFeeBps: protocolFeeBps,
            createdAt: block.timestamp
        });
        
        // Update counts
        poolCount++;
        if (tier == 0) publicPoolCount++;
        else if (tier == 1) verifiedPoolCount++;
        else if (tier == 2) institutionalPoolCount++;
        
        // Emit event
        emit PoolRegistered(poolIdBytes, tier, tx.origin);
        
        return BaseHook.beforeInitialize.selector;
    }

    // Before swap - compliance check
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata hookData
    ) external override returns (bytes4, BeforeSwapDelta, uint24) {
        PoolId poolId = key.toId();
        bytes32 poolIdBytes = PoolId.unwrap(poolId);
        PoolConfig memory config = poolConfigs[poolIdBytes];
        
        // Get user status
        address user = tx.origin;
        UserStatus status = getUserComplianceLevel(user);
        
        // Check if blacklisted
        if (status == UserStatus.BLACKLISTED) {
            emit SwapAttempt(user, poolIdBytes, false, "Blacklisted");
            revert("User blacklisted");
        }
        
        // Check whitelist if required
        if (config.requiresWhitelist && !poolWhitelist[poolIdBytes][user]) {
            emit SwapAttempt(user, poolIdBytes, false, "Not whitelisted");
            revert("Not whitelisted");
        }
        
        // Check tier requirements
        bool allowed = checkTierAccess(status, config.tier);
        
        if (!allowed) {
            emit SwapAttempt(user, poolIdBytes, false, "Insufficient tier");
            revert("Compliance failed: insufficient tier");
        }
        
        emit SwapAttempt(user, poolIdBytes, true, "Approved");
        
        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    // Get user compliance level
    function getUserComplianceLevel(address user) public view returns (UserStatus) {
        // Check if manually set
        if (userStatus[user] != UserStatus.NON_COMPLIANT) {
            return userStatus[user];
        }
        
        // Check risk score
        try riskCalculator.getUserRiskScore(user) returns (uint256 score, uint256) {
            if (score >= 90) return UserStatus.INSTITUTIONAL;
            if (score >= 75) return UserStatus.VERIFIED;
            if (score >= 50) return UserStatus.PUBLIC;
        } catch {
            // If risk calculator fails, default to non-compliant
        }
        
        return UserStatus.NON_COMPLIANT;
    }

    // Check if user can access pool tier
    function checkTierAccess(UserStatus userTier, ComplianceTier poolTier) internal pure returns (bool) {
        if (userTier == UserStatus.WHITELISTED) return true;
        if (userTier == UserStatus.BLACKLISTED) return false;
        
        if (poolTier == ComplianceTier.PUBLIC) {
            return uint8(userTier) >= uint8(UserStatus.PUBLIC);
        } else if (poolTier == ComplianceTier.VERIFIED) {
            return uint8(userTier) >= uint8(UserStatus.VERIFIED);
        } else if (poolTier == ComplianceTier.INSTITUTIONAL) {
            return uint8(userTier) >= uint8(UserStatus.INSTITUTIONAL);
        }
        
        return false;
    }

    // Admin functions
    function setUserStatus(address user, UserStatus status) external onlyOwner {
        userStatus[user] = status;
        emit UserStatusUpdated(user, status);
    }

    function whitelistUser(bytes32 poolId, address user) external onlyOwner {
        poolWhitelist[poolId][user] = true;
        emit UserWhitelisted(poolId, user);
    }

    function getPoolStats() external view returns (
        uint256 total,
        uint256 publicPools,
        uint256 verifiedPools,
        uint256 institutionalPools
    ) {
        return (poolCount, publicPoolCount, verifiedPoolCount, institutionalPoolCount);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
}

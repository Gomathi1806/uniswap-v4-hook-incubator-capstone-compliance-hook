// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {SwapParams, ModifyLiquidityParams} from "v4-core/src/types/PoolOperation.sol";

contract TieredComplianceHook is IHooks {
    using PoolIdLibrary for PoolKey;

    enum ComplianceTier { PUBLIC, VERIFIED, INSTITUTIONAL }
    
    struct PoolConfig {
        ComplianceTier tier;
        address creator;
        bool requiresWhitelist;
        uint256 protocolFeeBps;
        uint256 createdAt;
    }

    IPoolManager public immutable poolManager;
    address public constant RISK_CALCULATOR = 0xa78751349D496a726dCfde91bec2C5BE9b52f31E;
    address public constant CHAINLINK_ORACLE = 0xF2bDcA9B4776f7d2752E33b98513D4a284736818;
    address public constant FHENIX_FHE = 0xEae8DE4CFDFdEfe892180F54A8Fa0639F3A7A08e;
    
    mapping(PoolId => PoolConfig) public poolConfigs;
    mapping(PoolId => mapping(address => bool)) public poolWhitelist;
    mapping(ComplianceTier => uint256) public minimumScore;
    mapping(address => bool) public kycVerified;
    mapping(address => uint256) public kycExpiry;
    mapping(address => bool) public institutionalEntity;
    mapping(address => string) public entityName;
    mapping(address => bool) public globalWhitelist;
    mapping(address => bool) public globalBlacklist;
    address public owner;
    address public feeCollector;
    uint256 public totalPools;
    mapping(ComplianceTier => uint256) public poolsByTier;
    mapping(address => uint256) public swapCount;

    event PoolCreated(PoolId indexed poolId, ComplianceTier tier, address indexed creator, bool requiresWhitelist, uint256 protocolFeeBps);
    event SwapApproved(PoolId indexed poolId, address indexed user, ComplianceTier tier, uint256 riskScore);

    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }
    modifier onlyPoolManager() { require(msg.sender == address(poolManager), "Not pool manager"); _; }

    constructor(IPoolManager _poolManager, address _feeCollector) {
        poolManager = _poolManager;
        owner = msg.sender;
        feeCollector = _feeCollector;
        minimumScore[ComplianceTier.PUBLIC] = 50;
        minimumScore[ComplianceTier.VERIFIED] = 75;
        minimumScore[ComplianceTier.INSTITUTIONAL] = 90;
    }

    function getHookPermissions() external pure returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: true, afterInitialize: false, beforeAddLiquidity: true, afterAddLiquidity: false,
            beforeRemoveLiquidity: true, afterRemoveLiquidity: false, beforeSwap: true, afterSwap: true,
            beforeDonate: false, afterDonate: false, beforeSwapReturnDelta: false, afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false, afterRemoveLiquidityReturnDelta: false
        });
    }

    // Match exact IHooks signatures from error messages
    function beforeInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96) external onlyPoolManager returns (bytes4) {
        // Decode tier from pool key or use default
        // For now, default to PUBLIC - you can encode tier in key.hooks or elsewhere
        PoolId poolId = key.toId();
        poolConfigs[poolId] = PoolConfig(ComplianceTier.PUBLIC, sender, false, 0, block.timestamp);
        totalPools++;
        poolsByTier[ComplianceTier.PUBLIC]++;
        emit PoolCreated(poolId, ComplianceTier.PUBLIC, sender, false, 0);
        return IHooks.beforeInitialize.selector;
    }

    function afterInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96, int24 tick) external pure returns (bytes4) {
        return IHooks.afterInitialize.selector;
    }

    function beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external onlyPoolManager returns (bytes4) {
        require(checkCompliance(sender, key.toId(), poolConfigs[key.toId()].tier), "Compliance failed");
        return IHooks.beforeAddLiquidity.selector;
    }

    function afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) external pure returns (bytes4, BalanceDelta) {
        return (IHooks.afterAddLiquidity.selector, BalanceDelta.wrap(0));
    }

    function beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external onlyPoolManager returns (bytes4) {
        require(checkCompliance(sender, key.toId(), poolConfigs[key.toId()].tier), "Compliance failed");
        return IHooks.beforeRemoveLiquidity.selector;
    }

    function afterRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) external pure returns (bytes4, BalanceDelta) {
        return (IHooks.afterRemoveLiquidity.selector, BalanceDelta.wrap(0));
    }

    function beforeSwap(address sender, PoolKey calldata key, SwapParams calldata params, bytes calldata hookData)
        external onlyPoolManager returns (bytes4, BeforeSwapDelta, uint24)
    {
        PoolId poolId = key.toId();
        if (globalBlacklist[sender]) revert("Blacklisted");
        if (!checkCompliance(sender, poolId, poolConfigs[poolId].tier)) revert("Compliance failed");
        (uint256 score,) = IRiskCalculator(RISK_CALCULATOR).getUserRiskScore(sender);
        swapCount[sender]++;
        emit SwapApproved(poolId, sender, poolConfigs[poolId].tier, score);
        return (IHooks.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external pure returns (bytes4, int128) {
        return (IHooks.afterSwap.selector, 0);
    }

    function beforeDonate(address sender, PoolKey calldata key, uint256 amount0, uint256 amount1, bytes calldata hookData)
        external pure returns (bytes4)
    {
        return IHooks.beforeDonate.selector;
    }

    function afterDonate(address sender, PoolKey calldata key, uint256 amount0, uint256 amount1, bytes calldata hookData)
        external pure returns (bytes4)
    {
        return IHooks.afterDonate.selector;
    }

    function checkCompliance(address user, PoolId poolId, ComplianceTier tier) internal view returns (bool) {
        if (globalWhitelist[user]) return true;
        if (tier == ComplianceTier.PUBLIC) return checkPublicCompliance(user);
        if (tier == ComplianceTier.VERIFIED) return checkVerifiedCompliance(user);
        return checkInstitutionalCompliance(user, poolId);
    }

    function checkPublicCompliance(address user) internal view returns (bool) {
        (uint256 score,) = IRiskCalculator(RISK_CALCULATOR).getUserRiskScore(user);
        if (score < minimumScore[ComplianceTier.PUBLIC]) return false;
        if (IChainlinkOracle(CHAINLINK_ORACLE).isHighRisk(user)) return false;
        try IFhenixFHE(FHENIX_FHE).checkSanctionsList(user) returns (bool s) { if (s) return false; } catch {}
        return true;
    }

    function checkVerifiedCompliance(address user) internal view returns (bool) {
        if (!checkPublicCompliance(user)) return false;
        (uint256 score,) = IRiskCalculator(RISK_CALCULATOR).getUserRiskScore(user);
        return score >= minimumScore[ComplianceTier.VERIFIED] && kycVerified[user] && block.timestamp <= kycExpiry[user];
    }

    function checkInstitutionalCompliance(address user, PoolId poolId) internal view returns (bool) {
        if (!checkVerifiedCompliance(user)) return false;
        (uint256 score,) = IRiskCalculator(RISK_CALCULATOR).getUserRiskScore(user);
        if (score < minimumScore[ComplianceTier.INSTITUTIONAL] || !institutionalEntity[user]) return false;
        return !poolConfigs[poolId].requiresWhitelist || poolWhitelist[poolId][user];
    }

    function registerInstitution(address entity, string calldata name) external onlyOwner {
        institutionalEntity[entity] = true; entityName[entity] = name;
        kycVerified[entity] = true; kycExpiry[entity] = block.timestamp + 365 days;
    }

    function verifyKYC(address user, uint256 validityDays) external onlyOwner {
        kycVerified[user] = true; kycExpiry[user] = block.timestamp + (validityDays * 1 days);
    }

    function addToPoolWhitelist(PoolId poolId, address user) external {
        require(msg.sender == poolConfigs[poolId].creator || msg.sender == owner, "Not authorized");
        poolWhitelist[poolId][user] = true;
    }

    function addToGlobalWhitelist(address user) external onlyOwner { globalWhitelist[user] = true; }
    function addToGlobalBlacklist(address user) external onlyOwner { globalBlacklist[user] = true; }
    function setTierRequirement(ComplianceTier tier, uint256 score) external onlyOwner { minimumScore[tier] = score; }
    function transferOwnership(address newOwner) external onlyOwner { owner = newOwner; }

    function getUserComplianceLevel(address user) external view returns (string memory) {
        if (globalBlacklist[user]) return "BLACKLISTED";
        if (globalWhitelist[user]) return "WHITELISTED";
        (uint256 score,) = IRiskCalculator(RISK_CALCULATOR).getUserRiskScore(user);
        if (score >= 90 && institutionalEntity[user] && kycVerified[user] && block.timestamp <= kycExpiry[user]) return "INSTITUTIONAL";
        if (score >= 75 && kycVerified[user] && block.timestamp <= kycExpiry[user]) return "VERIFIED";
        if (score >= 50) return "PUBLIC";
        return "NON_COMPLIANT";
    }

    function getPoolStats() external view returns (uint256, uint256, uint256, uint256) {
        return (totalPools, poolsByTier[ComplianceTier.PUBLIC], poolsByTier[ComplianceTier.VERIFIED], poolsByTier[ComplianceTier.INSTITUTIONAL]);
    }
}

interface IRiskCalculator { function getUserRiskScore(address) external view returns (uint256, uint256); }
interface IChainlinkOracle { function isHighRisk(address) external view returns (bool); }
interface IFhenixFHE { function checkSanctionsList(address) external view returns (bool); }

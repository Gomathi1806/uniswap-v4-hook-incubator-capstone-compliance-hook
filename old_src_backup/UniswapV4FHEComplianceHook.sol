
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Hooks} from "v4-core/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "v4-core/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/types/BeforeSwapDelta.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/types/PoolId.sol";
interface ICrossChainRiskCalculator {
    function shouldBlockUser(address user) external view returns (bool);
    function calculateRisk(address user) external returns (uint256);
    function getUserRiskScore(address user) external view returns (uint256 score, uint256 timestamp);
}

interface IFhenixFHECompliance {
    function checkSanctionsList(address user) external view returns (bool);
    function isProfileScreened(address user) external view returns (bool);
    function screenAddress(address user) external returns (bool);
}

interface IChainlinkComplianceOracle {
    function isHighRisk(address user) external view returns (bool);
    function getAggregatedRiskScore(address user) external view returns (uint256);
    function quickScreen(address user) external returns (bool);
}

/**
 * @title UniswapV4FHEComplianceHook
 * @notice Production compliance hook with FHE + Chainlink + Risk Calculator
 */
contract UniswapV4FHEComplianceHook {
    using PoolIdLibrary for PoolKey;
    
    IPoolManager public immutable poolManager;
    ICrossChainRiskCalculator public riskCalculator;
    IFhenixFHECompliance public fhenixCompliance;
    IChainlinkComplianceOracle public chainlinkOracle;
    
    address public owner;
    mapping(address => bool) public whitelisted;
    mapping(address => bool) public blacklisted;
    mapping(address => uint256) public lastCheckTime;
    mapping(address => uint256) public swapCount;
    mapping(address => uint256) public lastSwapTime;
    mapping(PoolId => bool) public poolEnforcement;
    mapping(PoolId => uint256) public poolRiskThreshold;
    
    uint256 public globalRiskThreshold = 50;
    uint256 public checkInterval = 1 hours;
    uint256 public maxSwapsPerHour = 10;
    bool public paused;
    bool public autoScreening = true;
    
    event SwapBlocked(address indexed user, PoolId indexed poolId, string reason, uint256 riskScore);
    event SwapAllowed(address indexed user, PoolId indexed poolId, uint256 riskScore);
    event UserScreened(address indexed user, uint256 chainlinkScore, uint256 aggregatedScore);
    event EmergencyPause(bool paused);
    event PoolInitialized(PoolId indexed poolId);
    
    error UserIsBlacklisted();
    error UserIsHighRisk(uint256 riskScore);
    error UserIsSanctioned();
    error RateLimitExceeded();
    error HookPaused();
    error Unauthorized();
    
    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }
    
    modifier whenNotPaused() {
        if (paused) revert HookPaused();
        _;
    }
    
    modifier onlyPoolManager() {
        if (msg.sender != address(poolManager)) revert Unauthorized();
        _;
    }
    
    constructor(
        IPoolManager _poolManager,
        address _riskCalculator,
        address _fhenixCompliance,
        address _chainlinkOracle
    ) {
        require(address(_poolManager) != address(0), "Invalid PoolManager");
        require(_riskCalculator != address(0), "Invalid RiskCalculator");
        require(_fhenixCompliance != address(0), "Invalid FhenixCompliance");
        require(_chainlinkOracle != address(0), "Invalid ChainlinkOracle");
        
        poolManager = _poolManager;
        riskCalculator = ICrossChainRiskCalculator(_riskCalculator);
        fhenixCompliance = IFhenixFHECompliance(_fhenixCompliance);
        chainlinkOracle = IChainlinkComplianceOracle(_chainlinkOracle);
        owner = msg.sender;
    }
    
    function getHookPermissions() public pure returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: true,
            afterInitialize: false,
            beforeAddLiquidity: true,
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
    
    function beforeInitialize(
        address,
        PoolKey calldata key,
        uint160,
        bytes calldata
    ) external onlyPoolManager returns (bytes4) {
        PoolId poolId = key.toId();
        poolEnforcement[poolId] = true;
        poolRiskThreshold[poolId] = globalRiskThreshold;
        emit PoolInitialized(poolId);
        return this.beforeInitialize.selector;
    }
    
    function beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        bytes calldata,
        bytes calldata
    ) external view onlyPoolManager whenNotPaused returns (bytes4) {
        if (!whitelisted[sender]) {
            _quickComplianceCheck(sender, key.toId());
        }
        return this.beforeAddLiquidity.selector;
    }
    
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        bytes calldata,
        bytes calldata
    ) external onlyPoolManager whenNotPaused returns (bytes4, BeforeSwapDelta, uint24) {
        PoolId poolId = key.toId();
        
        if (!poolEnforcement[poolId] || whitelisted[sender]) {
            emit SwapAllowed(sender, poolId, 100);
            return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
        }
        
        if (blacklisted[sender]) {
            emit SwapBlocked(sender, poolId, "Blacklisted", 0);
            revert UserIsBlacklisted();
        }
        
        _checkRateLimit(sender);
        uint256 riskScore = _comprehensiveComplianceCheck(sender, poolId);
        
        if (riskScore < poolRiskThreshold[poolId]) {
            emit SwapBlocked(sender, poolId, "High Risk", riskScore);
            revert UserIsHighRisk(riskScore);
        }
        
        swapCount[sender]++;
        lastSwapTime[sender] = block.timestamp;
        
        emit SwapAllowed(sender, poolId, riskScore);
        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }
    
    // ============ Compliance Logic ============
    
    function _comprehensiveComplianceCheck(address user, PoolId poolId)
        internal returns (uint256)
    {
        _checkFhenixSanctions(user, poolId);
        _checkChainlinkRisk(user, poolId);
        _autoScreenIfNeeded(user);
        return _finalRiskAssessment(user, poolId);
    }
    
    function _checkFhenixSanctions(address user, PoolId poolId) internal {
        if (fhenixCompliance.checkSanctionsList(user)) {
            emit SwapBlocked(user, poolId, "FHE Sanctioned", 0);
            revert UserIsSanctioned();
        }
    }
    
    function _checkChainlinkRisk(address user, PoolId poolId) internal {
        if (chainlinkOracle.isHighRisk(user)) {
            emit SwapBlocked(user, poolId, "Chainlink High Risk", chainlinkOracle.getAggregatedRiskScore(user));
            revert UserIsHighRisk(chainlinkOracle.getAggregatedRiskScore(user));
        }
    }
    
    function _autoScreenIfNeeded(address user) internal {
        if (autoScreening && block.timestamp - lastCheckTime[user] > checkInterval) {
            if (!fhenixCompliance.isProfileScreened(user)) {
                try fhenixCompliance.screenAddress(user) {} catch {}
            }
            try chainlinkOracle.quickScreen(user) {} catch {}
            try riskCalculator.calculateRisk(user) {} catch {}
            lastCheckTime[user] = block.timestamp;
        }
    }
    
    function _finalRiskAssessment(address user, PoolId poolId) internal returns (uint256) {
        (uint256 calculatedScore,) = riskCalculator.getUserRiskScore(user);
        uint256 riskScore = calculatedScore == 0 ? 50 : calculatedScore;
        
        if (riskCalculator.shouldBlockUser(user)) {
            emit SwapBlocked(user, poolId, "Risk Calculator Block", riskScore);
            revert UserIsHighRisk(riskScore);
        }
        
        emit UserScreened(user, chainlinkOracle.getAggregatedRiskScore(user), riskScore);
        return riskScore;
    }
    
    function _quickComplianceCheck(address user, PoolId /* poolId */) internal view {
        if (blacklisted[user]) revert UserIsBlacklisted();
        if (fhenixCompliance.checkSanctionsList(user)) revert UserIsSanctioned();
        if (chainlinkOracle.isHighRisk(user)) revert UserIsHighRisk(0);
    }
    
    function _checkRateLimit(address user) internal view {
        if (block.timestamp - lastSwapTime[user] < 1 hours && swapCount[user] >= maxSwapsPerHour) {
            revert RateLimitExceeded();
        }
    }
    
    // ============ Admin Functions ============
    
    function setWhitelisted(address user, bool status) external onlyOwner {
        whitelisted[user] = status;
    }
    
    function setBlacklisted(address user, bool status) external onlyOwner {
        blacklisted[user] = status;
    }
    
    function setGlobalRiskThreshold(uint256 threshold) external onlyOwner {
        require(threshold <= 100, "Invalid threshold");
        globalRiskThreshold = threshold;
    }
    
    function setPoolEnforcement(PoolId poolId, bool enforce) external onlyOwner {
        poolEnforcement[poolId] = enforce;
    }
    
    function setAutoScreening(bool enabled) external onlyOwner {
        autoScreening = enabled;
    }
    
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit EmergencyPause(_paused);
    }
    
    function updateContracts(
        address _riskCalculator,
        address _fhenixCompliance,
        address _chainlinkOracle
    ) external onlyOwner {
        if (_riskCalculator != address(0)) riskCalculator = ICrossChainRiskCalculator(_riskCalculator);
        if (_fhenixCompliance != address(0)) fhenixCompliance = IFhenixFHECompliance(_fhenixCompliance);
        if (_chainlinkOracle != address(0)) chainlinkOracle = IChainlinkComplianceOracle(_chainlinkOracle);
    }
    
    function isCompliant(address user) external view returns (bool) {
        if (whitelisted[user]) return true;
        if (blacklisted[user]) return false;
        if (fhenixCompliance.checkSanctionsList(user)) return false;
        if (chainlinkOracle.isHighRisk(user)) return false;
        return !riskCalculator.shouldBlockUser(user);
    }
    
    function getUserInfo(address user) external view returns (
        bool isWhitelisted,
        bool isBlacklisted,
        bool isSanctioned,
        bool isHighRisk,
        uint256 riskScore,
        uint256 totalSwaps
    ) {
        (uint256 score,) = riskCalculator.getUserRiskScore(user);
        return (
            whitelisted[user],
            blacklisted[user],
            fhenixCompliance.checkSanctionsList(user),
            chainlinkOracle.isHighRisk(user),
            score,
            swapCount[user]
        );
    }
}


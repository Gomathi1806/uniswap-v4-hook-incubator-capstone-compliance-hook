// src/SimpleComplianceHook.sol
pragma solidity ^0.8.26;

import {BaseHook} from "v4-periphery/base/hooks/BaseHook.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/types/BeforeSwapDelta.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleComplianceHook is BaseHook, Ownable {
    // Events
    event UserVerified(address indexed user, uint256 timestamp);
    event ComplianceCheckPassed(address indexed user);
    event SwapBlocked(address indexed user, string reason);

    // State variables
    mapping(address => bool) public verifiedUsers;
    mapping(address => uint256) public verificationTimestamp;
    mapping(address => uint256) public riskScores; // 0-100, lower is better

    // Compliance thresholds
    uint256 public maxRiskScore = 70;

    // Errors
    error UserNotVerified();
    error RiskScoreTooHigh();
    error Unauthorized();

    constructor(
        IPoolManager _poolManager
    ) BaseHook(_poolManager) Ownable(msg.sender) {}

    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        return
            Hooks.Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: true,
                afterAddLiquidity: false,
                beforeRemoveLiquidity: true,
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

    // Manual verification function (replace with World ID later)
    function verifyUser(address user, uint256 riskScore) external onlyOwner {
        require(riskScore <= 100, "Invalid risk score");

        verifiedUsers[user] = true;
        verificationTimestamp[user] = block.timestamp;
        riskScores[user] = riskScore;

        emit UserVerified(user, block.timestamp);
    }

    // Remove user verification
    function revokeVerification(address user) external onlyOwner {
        verifiedUsers[user] = false;
        riskScores[user] = 100; // Set to max risk
    }

    // Update risk score
    function updateRiskScore(
        address user,
        uint256 newRiskScore
    ) external onlyOwner {
        require(verifiedUsers[user], "User not verified");
        require(newRiskScore <= 100, "Invalid risk score");
        riskScores[user] = newRiskScore;
    }

    // Update compliance threshold
    function updateMaxRiskScore(uint256 newMaxRiskScore) external onlyOwner {
        require(newMaxRiskScore <= 100, "Invalid risk score");
        maxRiskScore = newMaxRiskScore;
    }

    // Internal compliance check
    function _checkCompliance(address user) internal view {
        if (!verifiedUsers[user]) {
            revert UserNotVerified();
        }

        if (riskScores[user] > maxRiskScore) {
            revert RiskScoreTooHigh();
        }
    }

    // Hook functions
    function beforeSwap(
        address sender,
        PoolKey calldata,
        IPoolManager.SwapParams calldata,
        bytes calldata
    )
        external
        override
        onlyPoolManager
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        _checkCompliance(sender);
        emit ComplianceCheckPassed(sender);
        return (
            BaseHook.beforeSwap.selector,
            BeforeSwapDeltaLibrary.ZERO_DELTA,
            0
        );
    }

    function beforeAddLiquidity(
        address sender,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external override onlyPoolManager returns (bytes4) {
        _checkCompliance(sender);
        emit ComplianceCheckPassed(sender);
        return BaseHook.beforeAddLiquidity.selector;
    }

    function beforeRemoveLiquidity(
        address sender,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external override onlyPoolManager returns (bytes4) {
        _checkCompliance(sender);
        emit ComplianceCheckPassed(sender);
        return BaseHook.beforeRemoveLiquidity.selector;
    }

    // View functions
    function isUserCompliant(address user) external view returns (bool) {
        return verifiedUsers[user] && riskScores[user] <= maxRiskScore;
    }

    function getUserInfo(
        address user
    )
        external
        view
        returns (
            bool isVerified,
            uint256 verificationTime,
            uint256 riskScore,
            bool isCompliant
        )
    {
        isVerified = verifiedUsers[user];
        verificationTime = verificationTimestamp[user];
        riskScore = riskScores[user];
        isCompliant = isVerified && riskScore <= maxRiskScore;
    }
}

// src/ComplianceHook.sol
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta} from "v4-core/src/types/BeforeSwapDelta.sol";

import {IWorldID} from "./interfaces/IWorldID.sol";
import {WorldIDVerifier} from "./libraries/WorldIDVerifier.sol";
import {FHEOperations} from "./libraries/FHEOperations.sol";
import {EncryptedComplianceRegistry} from "./registry/EncryptedComplianceRegistry.sol";

contract ComplianceHook is BaseHook {
    using WorldIDVerifier for *;
    using FHEOperations for *;

    // State variables
    IWorldID public immutable worldID;
    EncryptedComplianceRegistry public immutable complianceRegistry;

    // World ID verifications storage
    mapping(uint256 => WorldIDVerifier.VerificationData)
        public worldIDVerifications;

    // Address to World ID nullifier mapping
    mapping(address => uint256) public addressToNullifier;

    // Compliance thresholds
    uint32 public maxRiskScore = 70; // Max allowed risk score (0-100)
    uint32 public minAmlStatus = 3; // Min AML clearance level (1-5)

    // Events
    event UserVerified(address indexed user, uint256 nullifierHash);
    event ComplianceCheckPassed(address indexed user, uint256 nullifierHash);
    event ComplianceCheckFailed(address indexed user, uint256 nullifierHash);
    event SwapBlocked(address indexed user, string reason);

    error UserNotWorldIDVerified();
    error ComplianceCheckFailed();
    error InvalidVerificationLevel();

    constructor(
        IPoolManager _poolManager,
        IWorldID _worldID,
        EncryptedComplianceRegistry _complianceRegistry
    ) BaseHook(_poolManager) {
        worldID = _worldID;
        complianceRegistry = _complianceRegistry;
    }

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
                afterSwap: true,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false,
                afterSwapReturnDelta: false,
                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            });
    }

    // World ID verification function
    function verifyWorldID(
        uint256 root,
        uint256 signalHash,
        uint256 nullifierHash,
        uint256 externalNullifierHash,
        uint256[8] calldata proof
    ) external {
        // Verify and store World ID proof
        WorldIDVerifier.verifyAndStore(
            worldID,
            root,
            signalHash,
            nullifierHash,
            externalNullifierHash,
            proof,
            worldIDVerifications
        );

        // Link address to nullifier
        addressToNullifier[msg.sender] = nullifierHash;

        emit UserVerified(msg.sender, nullifierHash);
    }

    // Before swap compliance check
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata hookData
    ) external override returns (bytes4, BeforeSwapDelta, uint24) {
        _performComplianceCheck(sender);

        // Process transaction for monitoring
        uint256 amount = params.amountSpecified > 0
            ? uint256(params.amountSpecified)
            : uint256(-params.amountSpecified);

        complianceRegistry.processTransaction(sender, amount, 1);

        return (
            BaseHook.beforeSwap.selector,
            BeforeSwapDeltaLibrary.ZERO_DELTA,
            0
        );
    }

    // After swap monitoring
    function afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external override returns (bytes4, int128) {
        // Additional post-swap monitoring can be added here
        return (BaseHook.afterSwap.selector, 0);
    }

    // Before add liquidity compliance check
    function beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external override returns (bytes4) {
        _performComplianceCheck(sender);
        return BaseHook.beforeAddLiquidity.selector;
    }

    // Before remove liquidity compliance check
    function beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external override returns (bytes4) {
        _performComplianceCheck(sender);
        return BaseHook.beforeRemoveLiquidity.selector;
    }

    // Internal compliance check function
    function _performComplianceCheck(address user) internal view {
        // Check World ID verification
        uint256 nullifierHash = addressToNullifier[user];
        if (nullifierHash == 0) {
            revert UserNotWorldIDVerified();
        }

        if (!WorldIDVerifier.isVerified(nullifierHash, worldIDVerifications)) {
            revert UserNotWorldIDVerified();
        }

        // Check encrypted compliance data using FHE
        ebool complianceStatus = complianceRegistry.checkCompliance(
            nullifierHash,
            maxRiskScore,
            minAmlStatus
        );

        // The compliance check result is encrypted, but we can use it in conditional logic
        // This is a simplified example - in practice, you'd need more sophisticated FHE operations
        require(FHE.decrypt(complianceStatus), "Compliance check failed");
    }

    // Admin functions
    function updateComplianceThresholds(
        uint32 newMaxRiskScore,
        uint32 newMinAmlStatus
    ) external onlyOwner {
        maxRiskScore = newMaxRiskScore;
        minAmlStatus = newMinAmlStatus;
    }

    // View functions
    function isUserCompliant(address user) external view returns (bool) {
        uint256 nullifierHash = addressToNullifier[user];
        if (nullifierHash == 0) return false;

        if (!WorldIDVerifier.isVerified(nullifierHash, worldIDVerifications)) {
            return false;
        }

        ebool complianceStatus = complianceRegistry.checkCompliance(
            nullifierHash,
            maxRiskScore,
            minAmlStatus
        );

        return FHE.decrypt(complianceStatus);
    }

    function getUserWorldIDStatus(
        address user
    )
        external
        view
        returns (
            bool isVerified,
            uint256 nullifierHash,
            uint256 verificationTimestamp
        )
    {
        nullifierHash = addressToNullifier[user];
        if (nullifierHash != 0) {
            WorldIDVerifier.VerificationData memory data = worldIDVerifications[
                nullifierHash
            ];
            isVerified = data.isActive;
            verificationTimestamp = data.timestamp;
        }
    }
}

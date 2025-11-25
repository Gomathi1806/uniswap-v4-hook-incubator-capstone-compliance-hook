// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Minimal PoolManager that ACTUALLY calls hooks!

interface IHooks {
    function beforeInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96, bytes calldata hookData) external returns (bytes4);
    function beforeSwap(address sender, PoolKey calldata key, SwapParams calldata params, bytes calldata hookData) external returns (bytes4, int256, uint24);
}

struct PoolKey {
    address currency0;
    address currency1;
    uint24 fee;
    int24 tickSpacing;
    address hooks;
}

struct SwapParams {
    bool zeroForOne;
    int256 amountSpecified;
    uint160 sqrtPriceLimitX96;
}

contract SimplePoolManager {
    mapping(bytes32 => bool) public pools;
    
    event Initialize(address indexed currency0, address indexed currency1, uint24 fee, int24 tickSpacing, address indexed hooks);
    
    function initialize(
        PoolKey memory key,
        uint160 sqrtPriceX96,
        bytes calldata hookData
    ) external returns (int24) {
        bytes32 poolId = keccak256(abi.encode(key));
        
        require(!pools[poolId], "Pool already initialized");
        pools[poolId] = true;
        
        // ✅ ACTUALLY CALL THE HOOK!
        if (key.hooks != address(0)) {
            IHooks(key.hooks).beforeInitialize(msg.sender, key, sqrtPriceX96, hookData);
        }
        
        emit Initialize(key.currency0, key.currency1, key.fee, key.tickSpacing, key.hooks);
        
        return 0;
    }
    
    function swap(
        PoolKey memory key,
        SwapParams memory params,
        bytes calldata hookData
    ) external returns (int256) {
        bytes32 poolId = keccak256(abi.encode(key));
        require(pools[poolId], "Pool not initialized");
        
        // ✅ ACTUALLY CALL THE HOOK!
        if (key.hooks != address(0)) {
            IHooks(key.hooks).beforeSwap(msg.sender, key, params, hookData);
        }
        
        // Mock swap logic
        return params.amountSpecified;
    }
}

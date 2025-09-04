// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import "./interfaces/ITRMComplianceOracle.sol";
import "./interfaces/IGitcoinPassport.sol";

// Remove this line: import "./mocks/MockGitcoinPassport.sol";

contract EnhancedComplianceHook {
    using PoolIdLibrary for PoolKey;

    // ... rest of your working contract
}

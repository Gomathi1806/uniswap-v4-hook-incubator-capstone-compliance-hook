// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../../src/interfaces/ITRMComplianceOracle.sol";

contract MockTRMOracle is ITRMComplianceOracle {
    mapping(address => TRMRiskData) private riskData;

    function setRiskData(address wallet, TRMRiskData calldata data) external {
        riskData[wallet] = data;
    }

    function getRiskData(
        address wallet
    ) external view override returns (TRMRiskData memory) {
        return riskData[wallet];
    }

    function isSanctioned(
        address wallet
    ) external view override returns (bool) {
        return riskData[wallet].isSanctioned;
    }

    function updateRiskData(
        address wallet,
        TRMRiskData calldata data
    ) external override {
        riskData[wallet] = data;
    }
}

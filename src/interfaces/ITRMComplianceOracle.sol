// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ITRMComplianceOracle {
    struct TRMRiskData {
        uint256 riskScore; // 0-100 risk score
        bool isSanctioned; // OFAC/sanctions check
        bool hasHighRiskActivity; // Mixing, darknet exposure
        uint256 lastUpdated; // Timestamp of last check
        bytes32 riskCategory; // Risk category identifier
    }

    function getRiskData(
        address wallet
    ) external view returns (TRMRiskData memory);

    function isSanctioned(address wallet) external view returns (bool);

    function updateRiskData(address wallet, TRMRiskData calldata data) external;
}

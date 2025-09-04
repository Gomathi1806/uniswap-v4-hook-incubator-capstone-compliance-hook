// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../interfaces/IOpenComplianceOracle.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OpenComplianceOracle is IOpenComplianceOracle, Ownable {
    mapping(address => RiskData) private riskData;
    mapping(address => bool) public sanctionedAddresses;

    // Known high-risk addresses (can be updated via governance)
    mapping(address => bool) public knownHighRiskAddresses;

    // Events
    event RiskDataUpdated(address indexed wallet, uint256 riskScore);
    event AddressSanctioned(address indexed wallet);
    event AddressUnsanctioned(address indexed wallet);

    constructor() Ownable(msg.sender) {}

    function getRiskData(
        address wallet
    ) external view override returns (RiskData memory) {
        return riskData[wallet];
    }

    function updateRiskData(
        address wallet,
        RiskData calldata data
    ) external override onlyOwner {
        riskData[wallet] = data;
        emit RiskDataUpdated(wallet, data.riskScore);
    }

    function calculateRiskScore(
        address wallet
    ) external view override returns (uint256) {
        // Simple risk calculation based on available data
        uint256 score = 0;

        // Check if sanctioned
        if (sanctionedAddresses[wallet]) {
            return 100; // Maximum risk
        }

        // Check if known high-risk
        if (knownHighRiskAddresses[wallet]) {
            score += 50;
        }

        // Add transaction volume based risk
        RiskData memory data = riskData[wallet];
        if (data.totalVolume > 1000 ether) {
            score += 20;
        }

        // Transaction frequency risk
        if (data.transactionCount > 1000) {
            score += 15;
        }

        // Age of data (stale data increases risk)
        if (block.timestamp - data.lastUpdated > 7 days) {
            score += 10;
        }

        return score > 100 ? 100 : score;
    }

    // Admin functions
    function addSanctionedAddress(address wallet) external onlyOwner {
        sanctionedAddresses[wallet] = true;
        emit AddressSanctioned(wallet);
    }

    function removeSanctionedAddress(address wallet) external onlyOwner {
        sanctionedAddresses[wallet] = false;
        emit AddressUnsanctioned(wallet);
    }

    function addHighRiskAddress(address wallet) external onlyOwner {
        knownHighRiskAddresses[wallet] = true;
    }

    function removeHighRiskAddress(address wallet) external onlyOwner {
        knownHighRiskAddresses[wallet] = false;
    }

    // Batch operations for efficiency
    function batchUpdateSanctions(
        address[] calldata addresses,
        bool[] calldata statuses
    ) external onlyOwner {
        require(addresses.length == statuses.length, "Array length mismatch");

        for (uint256 i = 0; i < addresses.length; i++) {
            sanctionedAddresses[addresses[i]] = statuses[i];
            if (statuses[i]) {
                emit AddressSanctioned(addresses[i]);
            } else {
                emit AddressUnsanctioned(addresses[i]);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IGitcoinPassport {
    struct PassportData {
        uint256 humanityScore; // 0-100 humanity score
        uint256 trustScore; // Community trust score
        uint256 lastUpdated; // Last verification timestamp
        bool isVerified; // Basic verification status
        uint256 stakingAmount; // GTC staked for reputation
    }

    function getPassportData(
        address user
    ) external view returns (PassportData memory);

    function getHumanityScore(address user) external view returns (uint256);

    function isHuman(
        address user,
        uint256 minimumScore
    ) external view returns (bool);
}

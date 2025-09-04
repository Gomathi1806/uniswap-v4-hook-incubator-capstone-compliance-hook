// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../../src/interfaces/IGitcoinPassport.sol";

contract MockGitcoinPassport is IGitcoinPassport {
    mapping(address => PassportData) private passportData;

    function setPassportData(
        address user,
        PassportData calldata data
    ) external {
        passportData[user] = data;
    }

    function getPassportData(
        address user
    ) external view override returns (PassportData memory) {
        return passportData[user];
    }

    function getHumanityScore(
        address user
    ) external view override returns (uint256) {
        return passportData[user].humanityScore;
    }

    function isHuman(
        address user,
        uint256 minimumScore
    ) external view override returns (bool) {
        return passportData[user].humanityScore >= minimumScore;
    }
}

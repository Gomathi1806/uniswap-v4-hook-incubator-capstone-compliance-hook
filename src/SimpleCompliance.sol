// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract SimpleCompliance {
    mapping(address => bool) public isCompliant;
    address public owner;

    event ComplianceUpdated(address indexed user, bool status);

    constructor() {
        owner = msg.sender;
        isCompliant[msg.sender] = true;
    }

    function setCompliance(address user, bool status) external {
        require(msg.sender == owner, "Only owner");
        isCompliant[user] = status;
        emit ComplianceUpdated(user, status);
    }

    function checkCompliance(address user) external view returns (bool) {
        return isCompliant[user];
    }
}

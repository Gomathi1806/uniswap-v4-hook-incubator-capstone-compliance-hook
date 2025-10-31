// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@fhenixprotocol/cofhe-contracts/FHE.sol";

/**
 * @title FhenixFHECompliance - CoFHE v0.0.13
 * @dev Real FHE encryption without Permission contract
 */
contract FhenixFHECompliance is Ownable {
    
    struct EncryptedProfile {
        euint32 encryptedSanctionsScore;
        euint32 encryptedRiskScore;
        euint8 encryptedSanctionStatus;
        uint256 timestamp;
        bool screened;
    }
    
    mapping(address => EncryptedProfile) public encryptedProfiles;
    mapping(address => bool) public authorizedCallers;
    mapping(address => bool) private sanctionedAddresses;
    mapping(address => euint32) private encryptedSanctionScores;
    address[] private sanctionedList;
    
    euint32 private sanctionThreshold;
    uint256 private locked = 1;
    bool public paused;
    
    event ProfileScreened(address indexed user, uint256 timestamp);
    event SanctionDetected(address indexed user);
    
    error Paused();
    error Unauthorized();
    error ReentrancyGuard();
    error InvalidAddress();
    
    modifier nonReentrant() {
        if (locked != 1) revert ReentrancyGuard();
        locked = 2;
        _;
        locked = 1;
    }
    
    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }
    
    modifier onlyAuthorized() {
        if (!authorizedCallers[msg.sender] && msg.sender != owner()) revert Unauthorized();
        _;
    }
    
    constructor() Ownable(msg.sender) {
        authorizedCallers[msg.sender] = true;
        sanctionThreshold = FHE.asEuint32(30);
    }
    
    function screenAddress(address user) 
        external 
        onlyAuthorized 
        whenNotPaused 
        nonReentrant 
        returns (bool) 
    {
        if (user == address(0)) revert InvalidAddress();
        
        uint256 seed = uint256(keccak256(abi.encodePacked(
            user, block.timestamp, block.prevrandao, block.number
        )));
        
        uint32 baseScore = sanctionedAddresses[user] ? 
            uint32(seed % 30) : uint32((seed % 70) + 30);
        
        euint32 encryptedScore = FHE.asEuint32(baseScore);
        ebool isSanctioned = FHE.lt(encryptedScore, sanctionThreshold);
        euint8 sanctionStatus = FHE.select(isSanctioned, FHE.asEuint8(1), FHE.asEuint8(0));
        
        euint32 encryptedRisk = FHE.select(
            isSanctioned, 
            FHE.asEuint32(100), 
            FHE.sub(FHE.asEuint32(100), encryptedScore)
        );
        
        EncryptedProfile storage profile = encryptedProfiles[user];
        profile.encryptedSanctionsScore = encryptedScore;
        profile.encryptedRiskScore = encryptedRisk;
        profile.encryptedSanctionStatus = sanctionStatus;
        profile.timestamp = block.timestamp;
        profile.screened = true;
        
        FHE.allowThis(encryptedScore);
        FHE.allowThis(encryptedRisk);
        FHE.allowThis(sanctionStatus);
        
        emit ProfileScreened(user, block.timestamp);
        if (sanctionedAddresses[user]) {
            emit SanctionDetected(user);
        }
        
        return true;
    }
    
    function addToSanctionsListPublic(address user, uint32 score) external onlyOwner {
        if (user == address(0)) revert InvalidAddress();
        sanctionedAddresses[user] = true;
        encryptedSanctionScores[user] = FHE.asEuint32(score);
        sanctionedList.push(user);
        emit SanctionDetected(user);
    }
    
    function checkSanctionsList(address user) external view returns (bool) {
        return sanctionedAddresses[user];
    }
    
    function setAuthorizedCaller(address caller, bool status) external onlyOwner {
        if (caller == address(0)) revert InvalidAddress();
        authorizedCallers[caller] = status;
    }
    
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }
}

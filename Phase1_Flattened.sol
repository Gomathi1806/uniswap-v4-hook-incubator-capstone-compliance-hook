// SPDX-License-Identifier: MIT
pragma solidity >=0.4.16 >=0.8.4 ^0.8.20;

// node_modules/@openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// node_modules/@openzeppelin/contracts/access/IAccessControl.sol

// OpenZeppelin Contracts (last updated v5.4.0) (access/IAccessControl.sol)

/**
 * @dev External interface of AccessControl declared to support ERC-165 detection.
 */
interface IAccessControl {
    /**
     * @dev The `account` is missing a role.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /**
     * @dev The caller of a function is not the expected one.
     *
     * NOTE: Don't confuse with {AccessControlUnauthorizedAccount}.
     */
    error AccessControlBadConfirmation();

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted to signal this.
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call. This account bears the admin role (for the granted role).
     * Expected in cases where the role was granted using the internal {AccessControl-_grantRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     */
    function renounceRole(bytes32 role, address callerConfirmation) external;
}

// node_modules/@openzeppelin/contracts/utils/introspection/IERC165.sol

// OpenZeppelin Contracts (last updated v5.4.0) (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// node_modules/@openzeppelin/contracts/utils/ReentrancyGuard.sol

// OpenZeppelin Contracts (last updated v5.1.0) (utils/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If EIP-1153 (transient storage) is available on the chain you're deploying at,
 * consider using {ReentrancyGuardTransient} instead.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// node_modules/@openzeppelin/contracts/utils/introspection/ERC165.sol

// OpenZeppelin Contracts (last updated v5.4.0) (utils/introspection/ERC165.sol)

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC-165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165 is IERC165 {
    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// node_modules/@openzeppelin/contracts/access/AccessControl.sol

// OpenZeppelin Contracts (last updated v5.4.0) (access/AccessControl.sol)

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }

    mapping(bytes32 role => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with an {AccessControlUnauthorizedAccount} error including the required role.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return _roles[role].hasRole[account];
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `_msgSender()`
     * is missing `role`. Overriding this function changes the behavior of the {onlyRole} modifier.
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `account`
     * is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address callerConfirmation) public virtual {
        if (callerConfirmation != _msgSender()) {
            revert AccessControlBadConfirmation();
        }

        _revokeRole(role, callerConfirmation);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Attempts to grant `role` to `account` and returns a boolean indicating if `role` was granted.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual returns (bool) {
        if (!hasRole(role, account)) {
            _roles[role].hasRole[account] = true;
            emit RoleGranted(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Attempts to revoke `role` from `account` and returns a boolean indicating if `role` was revoked.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual returns (bool) {
        if (hasRole(role, account)) {
            _roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }
}

// src/enhanced/Phase1_SimpleCompliance.sol

/**
 * @title Phase1_SimpleCompliance
 * @notice Simplified compliance oracle with real data structure (manual input for now)
 * @dev Start with this, then upgrade to full Chainlink integration later
 */
contract Phase1_SimpleCompliance is AccessControl, ReentrancyGuard {
    
    // ====== ROLES ======
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // ====== ENUMS ======
    enum RiskLevel { 
        LOW,        // Score 70-100
        MEDIUM,     // Score 40-69
        HIGH,       // Score 0-39
        SANCTIONED  // On sanctions list
    }

    enum DataSource {
        MANUAL_ADMIN,
        OFAC_SDN,
        CHAINALYSIS,
        TRM_LABS
    }

    // ====== STRUCTS ======
    struct ComplianceRecord {
        RiskLevel riskLevel;
        uint256 riskScore;
        uint256 kycScore;
        uint256 amlScore;
        uint256 sanctionsScore;
        bool isOnOFACList;
        bool verified;
        uint256 lastChecked;
        uint256 lastUpdated;
        DataSource dataSource;
        string country;
    }

    // ====== STATE VARIABLES ======
    
    mapping(address => ComplianceRecord) public complianceRecords;
    mapping(address => bool) public blacklistedAddresses;
    mapping(address => bool) public whitelistedAddresses;
    mapping(address => string) public blacklistReasons;
    
    // Statistics
    uint256 public totalChecksPerformed;
    uint256 public totalSanctionedFound;
    uint256 public totalHighRiskFound;
    
    bool public paused;

    // ====== COMPREHENSIVE EVENTS ======
    
    event ComplianceCheck(
        address indexed user, 
        bool passed, 
        RiskLevel riskLevel,
        string reason,
        uint256 timestamp
    );
    
    event SanctionedAddressBlocked(
        address indexed blockedAddress,
        DataSource source,
        string details,
        uint256 timestamp
    );
    
    event HighRiskTransactionPrevented(
        address indexed user, 
        uint256 amount,
        RiskLevel riskLevel,
        string reason,
        uint256 timestamp
    );
    
    event RiskLevelUpdated(
        address indexed user,
        RiskLevel oldLevel,
        RiskLevel newLevel,
        string reason,
        uint256 timestamp
    );
    
    event RiskScoreCalculated(
        address indexed user,
        uint256 score,
        uint256 kycScore,
        uint256 amlScore,
        uint256 sanctionsScore,
        uint256 timestamp
    );
    
    event ManualOverride(
        address indexed admin,
        address indexed user,
        RiskLevel newLevel,
        string reason,
        uint256 timestamp
    );
    
    event AddressWhitelisted(
        address indexed admin,
        address indexed user,
        string reason,
        uint256 timestamp
    );
    
    event AddressBlacklisted(
        address indexed admin,
        address indexed user,
        string reason,
        uint256 timestamp
    );
    
    event BatchComplianceUpdate(
        uint256 count,
        DataSource source,
        uint256 timestamp
    );
    
    event EmergencyPause(
        address indexed admin,
        string reason,
        uint256 timestamp
    );
    
    event EmergencyUnpause(
        address indexed admin,
        uint256 timestamp
    );

    // ====== ERRORS ======
    error Paused();
    error Unauthorized();
    error InvalidAddress();
    error InvalidScore();

    // ====== MODIFIERS ======
    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier onlyOperator() {
        if (!hasRole(OPERATOR_ROLE, msg.sender)) revert Unauthorized();
        _;
    }

    // ====== CONSTRUCTOR ======
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
    }

    // ====== COMPLIANCE CHECK FUNCTIONS ======

    /**
     * @notice Perform compliance check on address
     */
    function checkCompliance(address user) 
        external 
        whenNotPaused 
        returns (bool passed) 
    {
        if (user == address(0)) revert InvalidAddress();
        
        // Check whitelist
        if (whitelistedAddresses[user]) {
            emit ComplianceCheck(user, true, RiskLevel.LOW, "Whitelisted", block.timestamp);
            return true;
        }
        
        // Check blacklist
        if (blacklistedAddresses[user]) {
            emit ComplianceCheck(user, false, RiskLevel.SANCTIONED, "Blacklisted", block.timestamp);
            return false;
        }
        
        ComplianceRecord storage record = complianceRecords[user];
        record.lastChecked = block.timestamp;
        totalChecksPerformed++;
        
        // Check sanctions
        if (record.isOnOFACList || record.riskLevel == RiskLevel.SANCTIONED) {
            emit ComplianceCheck(user, false, RiskLevel.SANCTIONED, "On sanctions list", block.timestamp);
            return false;
        }
        
        // Check risk level
        if (record.riskLevel == RiskLevel.HIGH) {
            emit ComplianceCheck(user, false, RiskLevel.HIGH, "High risk", block.timestamp);
            return false;
        }
        
        // Pass for LOW and MEDIUM risk
        emit ComplianceCheck(user, true, record.riskLevel, "Passed", block.timestamp);
        return true;
    }

    /**
     * @notice Check if swap should be allowed
     */
    function beforeSwap(
        address sender, 
        address recipient,
        uint256 amount
    ) external whenNotPaused returns (bool allowed) {
        // Check whitelist
        if (whitelistedAddresses[sender] && whitelistedAddresses[recipient]) {
            return true;
        }
        
        // Check blacklist
        if (blacklistedAddresses[sender] || blacklistedAddresses[recipient]) {
            emit HighRiskTransactionPrevented(
                sender,
                amount,
                RiskLevel.SANCTIONED,
                "Blacklisted address",
                block.timestamp
            );
            return false;
        }
        
        ComplianceRecord memory senderRecord = complianceRecords[sender];
        ComplianceRecord memory recipientRecord = complianceRecords[recipient];
        
        // Block sanctioned
        if (senderRecord.riskLevel == RiskLevel.SANCTIONED || 
            recipientRecord.riskLevel == RiskLevel.SANCTIONED) {
            emit HighRiskTransactionPrevented(
                sender,
                amount,
                RiskLevel.SANCTIONED,
                "Sanctioned address",
                block.timestamp
            );
            return false;
        }
        
        // Block high risk
        if (senderRecord.riskLevel == RiskLevel.HIGH || 
            recipientRecord.riskLevel == RiskLevel.HIGH) {
            emit HighRiskTransactionPrevented(
                sender,
                amount,
                RiskLevel.HIGH,
                "High risk address",
                block.timestamp
            );
            return false;
        }
        
        return true;
    }

    // ====== ADMIN FUNCTIONS ======

    /**
     * @notice Set compliance data for user (simulates OFAC API result)
     */
    function setComplianceData(
        address user,
        uint256 kycScore,
        uint256 amlScore,
        uint256 sanctionsScore,
        bool isOnOFACList,
        string calldata country
    ) external onlyRole(OPERATOR_ROLE) {
        if (user == address(0)) revert InvalidAddress();
        if (kycScore > 100 || amlScore > 100 || sanctionsScore > 100) revert InvalidScore();
        
        ComplianceRecord storage record = complianceRecords[user];
        RiskLevel oldLevel = record.riskLevel;
        
        record.kycScore = kycScore;
        record.amlScore = amlScore;
        record.sanctionsScore = sanctionsScore;
        record.isOnOFACList = isOnOFACList;
        record.country = country;
        record.verified = kycScore >= 70;
        record.lastUpdated = block.timestamp;
        record.dataSource = DataSource.MANUAL_ADMIN;
        
        _updateRiskLevel(user);
        
        emit RiskScoreCalculated(
            user,
            record.riskScore,
            kycScore,
            amlScore,
            sanctionsScore,
            block.timestamp
        );
        
        if (oldLevel != record.riskLevel) {
            emit RiskLevelUpdated(
                user,
                oldLevel,
                record.riskLevel,
                "Compliance data updated",
                block.timestamp
            );
        }
        
        if (isOnOFACList) {
            totalSanctionedFound++;
            emit SanctionedAddressBlocked(
                user,
                DataSource.MANUAL_ADMIN,
                "Added to sanctions list",
                block.timestamp
            );
        }
    }

    /**
     * @notice Calculate and update risk level
     */
    function _updateRiskLevel(address user) internal {
        ComplianceRecord storage record = complianceRecords[user];
        
        // Sanctioned overrides everything
        if (record.isOnOFACList) {
            record.riskLevel = RiskLevel.SANCTIONED;
            record.riskScore = 0;
            return;
        }
        
        // Calculate weighted average
        uint256 totalScore = (
            record.kycScore * 30 +
            record.amlScore * 40 +
            record.sanctionsScore * 30
        ) / 100;
        
        record.riskScore = totalScore;
        
        // Classify
        if (totalScore >= 70) {
            record.riskLevel = RiskLevel.LOW;
        } else if (totalScore >= 40) {
            record.riskLevel = RiskLevel.MEDIUM;
        } else {
            record.riskLevel = RiskLevel.HIGH;
            totalHighRiskFound++;
        }
    }

    /**
     * @notice Batch update compliance
     */
    function batchUpdateCompliance(
        address[] calldata users,
        uint256[] calldata kycScores,
        uint256[] calldata amlScores,
        bool[] calldata sanctioned
    ) external onlyRole(OPERATOR_ROLE) {
        require(
            users.length == kycScores.length && 
            users.length == amlScores.length &&
            users.length == sanctioned.length,
            "Array length mismatch"
        );
        
        for (uint256 i = 0; i < users.length; i++) {
            ComplianceRecord storage record = complianceRecords[users[i]];
            record.kycScore = kycScores[i];
            record.amlScore = amlScores[i];
            record.isOnOFACList = sanctioned[i];
            record.sanctionsScore = sanctioned[i] ? 0 : 100;
            record.lastUpdated = block.timestamp;
            
            _updateRiskLevel(users[i]);
        }
        
        emit BatchComplianceUpdate(users.length, DataSource.MANUAL_ADMIN, block.timestamp);
    }

    /**
     * @notice Admin override
     */
    function adminOverride(
        address user,
        RiskLevel newLevel,
        string calldata reason
    ) external onlyRole(ADMIN_ROLE) {
        ComplianceRecord storage record = complianceRecords[user];
        RiskLevel oldLevel = record.riskLevel;
        
        record.riskLevel = newLevel;
        record.lastUpdated = block.timestamp;
        record.dataSource = DataSource.MANUAL_ADMIN;
        
        emit ManualOverride(msg.sender, user, newLevel, reason, block.timestamp);
        emit RiskLevelUpdated(user, oldLevel, newLevel, reason, block.timestamp);
    }

    /**
     * @notice Add to whitelist
     */
    function addToWhitelist(address user, string calldata reason) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        whitelistedAddresses[user] = true;
        emit AddressWhitelisted(msg.sender, user, reason, block.timestamp);
    }

    /**
     * @notice Add to blacklist
     */
    function addToBlacklist(address user, string calldata reason) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        blacklistedAddresses[user] = true;
        blacklistReasons[user] = reason;
        
        complianceRecords[user].riskLevel = RiskLevel.SANCTIONED;
        
        emit AddressBlacklisted(msg.sender, user, reason, block.timestamp);
        emit SanctionedAddressBlocked(user, DataSource.MANUAL_ADMIN, reason, block.timestamp);
    }

    /**
     * @notice Emergency pause
     */
    function pause(string calldata reason) external onlyRole(ADMIN_ROLE) {
        paused = true;
        emit EmergencyPause(msg.sender, reason, block.timestamp);
    }

    /**
     * @notice Unpause
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        paused = false;
        emit EmergencyUnpause(msg.sender, block.timestamp);
    }

    // ====== VIEW FUNCTIONS ======

    function getRiskLevel(address user) external view returns (RiskLevel) {
        return complianceRecords[user].riskLevel;
    }

    function getRiskLevelString(address user) external view returns (string memory) {
        RiskLevel level = complianceRecords[user].riskLevel;
        if (level == RiskLevel.SANCTIONED) return "Sanctioned";
        if (level == RiskLevel.HIGH) return "High Risk";
        if (level == RiskLevel.MEDIUM) return "Medium Risk";
        return "Low Risk";
    }

    function getComplianceRecord(address user) external view returns (ComplianceRecord memory) {
        return complianceRecords[user];
    }

    function isCompliant(address user) external view returns (bool) {
        if (whitelistedAddresses[user]) return true;
        if (blacklistedAddresses[user]) return false;
        
        RiskLevel level = complianceRecords[user].riskLevel;
        return level == RiskLevel.LOW || level == RiskLevel.MEDIUM;
    }

    function getRiskScore(address user) external view returns (uint256) {
        return complianceRecords[user].riskScore;
    }
}


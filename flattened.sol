// SPDX-License-Identifier: MIT
pragma solidity <0.9.0 >=0.8.19 >=0.8.25 ^0.8.20 ^0.8.25;

// lib/openzeppelin-contracts/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

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
}

// lib/cofhe-contracts/contracts/ICofhe.sol

struct EncryptedInput {
    uint256 ctHash;
    uint8 securityZone;
    uint8 utype;
    bytes signature;
}

struct InEbool {
    uint256 ctHash;
    uint8 securityZone;
    uint8 utype;
    bytes signature;
}

struct InEuint8 {
    uint256 ctHash;
    uint8 securityZone;
    uint8 utype;
    bytes signature;
}

struct InEuint16 {
    uint256 ctHash;
    uint8 securityZone;
    uint8 utype;
    bytes signature;
}

struct InEuint32 {
    uint256 ctHash;
    uint8 securityZone;
    uint8 utype;
    bytes signature;
}

struct InEuint64 {
    uint256 ctHash;
    uint8 securityZone;
    uint8 utype;
    bytes signature;
}

struct InEuint128 {
    uint256 ctHash;
    uint8 securityZone;
    uint8 utype;
    bytes signature;
}

struct InEuint256 {
    uint256 ctHash;
    uint8 securityZone;
    uint8 utype;
    bytes signature;
}
struct InEaddress {
    uint256 ctHash;
    uint8 securityZone;
    uint8 utype;
    bytes signature;
}

// Order is set as in fheos/precompiles/types/types.go
enum FunctionId {
    _0,             // 0 - GetNetworkKey
    _1,             // 1 - Verify
    cast,           // 2
    sealoutput,     // 3
    select,         // 4 - select
    _5,             // 5 - req
    decrypt,        // 6
    sub,            // 7
    add,            // 8
    xor,            // 9
    and,            // 10
    or,             // 11
    not,            // 12
    div,            // 13
    rem,            // 14
    mul,            // 15
    shl,            // 16
    shr,            // 17
    gte,            // 18
    lte,            // 19
    lt,             // 20
    gt,             // 21
    min,            // 22
    max,            // 23
    eq,             // 24
    ne,             // 25
    trivialEncrypt, // 26
    random,         // 27
    rol,            // 28
    ror,            // 29
    square,         // 30
    _31             // 31
}

interface ITaskManager {
    function createTask(uint8 returnType, FunctionId funcId, uint256[] memory encryptedInputs, uint256[] memory extraInputs) external returns (uint256);
    function createRandomTask(uint8 returnType, uint256 seed, int32 securityZone) external returns (uint256);

    function createDecryptTask(uint256 ctHash, address requestor) external;
    function verifyInput(EncryptedInput memory input, address sender) external returns (uint256);

    function allow(uint256 ctHash, address account) external;
    function isAllowed(uint256 ctHash, address account) external returns (bool);
    function allowGlobal(uint256 ctHash) external;
    function allowTransient(uint256 ctHash, address account) external;
    function getDecryptResultSafe(uint256 ctHash) external view returns (uint256, bool);
    function getDecryptResult(uint256 ctHash) external view returns (uint256);
}

library Utils {
    // Values used to communicate types to the runtime.
    // Must match values defined in warp-drive protobufs for everything to
    uint8 internal constant EUINT8_TFHE = 2;
    uint8 internal constant EUINT16_TFHE = 3;
    uint8 internal constant EUINT32_TFHE = 4;
    uint8 internal constant EUINT64_TFHE = 5;
    uint8 internal constant EUINT128_TFHE = 6;
    uint8 internal constant EUINT256_TFHE = 8;
    uint8 internal constant EADDRESS_TFHE = 7;
    uint8 internal constant EBOOL_TFHE = 0;

    function functionIdToString(FunctionId _functionId) internal pure returns (string memory) {
        if (_functionId == FunctionId.cast) return "cast";
        if (_functionId == FunctionId.sealoutput) return "sealOutput";
        if (_functionId == FunctionId.select) return "select";
        if (_functionId == FunctionId.decrypt) return "decrypt";
        if (_functionId == FunctionId.sub) return "sub";
        if (_functionId == FunctionId.add) return "add";
        if (_functionId == FunctionId.xor) return "xor";
        if (_functionId == FunctionId.and) return "and";
        if (_functionId == FunctionId.or) return "or";
        if (_functionId == FunctionId.not) return "not";
        if (_functionId == FunctionId.div) return "div";
        if (_functionId == FunctionId.rem) return "rem";
        if (_functionId == FunctionId.mul) return "mul";
        if (_functionId == FunctionId.shl) return "shl";
        if (_functionId == FunctionId.shr) return "shr";
        if (_functionId == FunctionId.gte) return "gte";
        if (_functionId == FunctionId.lte) return "lte";
        if (_functionId == FunctionId.lt) return "lt";
        if (_functionId == FunctionId.gt) return "gt";
        if (_functionId == FunctionId.min) return "min";
        if (_functionId == FunctionId.max) return "max";
        if (_functionId == FunctionId.eq) return "eq";
        if (_functionId == FunctionId.ne) return "ne";
        if (_functionId == FunctionId.trivialEncrypt) return "trivialEncrypt";
        if (_functionId == FunctionId.random) return "random";
        if (_functionId == FunctionId.rol) return "rol";
        if (_functionId == FunctionId.ror) return "ror";
        if (_functionId == FunctionId.square) return "square";

        return "";
    }

    function inputFromEbool(InEbool memory input) internal pure returns (EncryptedInput memory) {
        return EncryptedInput({
            ctHash: input.ctHash,
            securityZone: input.securityZone,
            utype: EBOOL_TFHE,
            signature: input.signature
        });
    }

    function inputFromEuint8(InEuint8 memory input) internal pure returns (EncryptedInput memory) {
        return EncryptedInput({
            ctHash: input.ctHash,
            securityZone: input.securityZone,
            utype: EUINT8_TFHE,
            signature: input.signature
        });
    }

    function inputFromEuint16(InEuint16 memory input) internal pure returns (EncryptedInput memory) {
        return EncryptedInput({
            ctHash: input.ctHash,
            securityZone: input.securityZone,
            utype: EUINT16_TFHE,
            signature: input.signature
        });
    }

    function inputFromEuint32(InEuint32 memory input) internal pure returns (EncryptedInput memory) {
        return EncryptedInput({
            ctHash: input.ctHash,
            securityZone: input.securityZone,
            utype: EUINT32_TFHE,
            signature: input.signature
        });
    }

    function inputFromEuint64(InEuint64 memory input) internal pure returns (EncryptedInput memory) {
        return EncryptedInput({
            ctHash: input.ctHash,
            securityZone: input.securityZone,
            utype: EUINT64_TFHE,
            signature: input.signature
        });
    }

    function inputFromEuint128(InEuint128 memory input) internal pure returns (EncryptedInput memory) {
        return EncryptedInput({
            ctHash: input.ctHash,
            securityZone: input.securityZone,
            utype: EUINT128_TFHE,
            signature: input.signature
        });
    }

    function inputFromEuint256(InEuint256 memory input) internal pure returns (EncryptedInput memory) {
        return EncryptedInput({
            ctHash: input.ctHash,
            securityZone: input.securityZone,
            utype: EUINT256_TFHE,
            signature: input.signature
        });
    }

    function inputFromEaddress(InEaddress memory input) internal pure returns (EncryptedInput memory) {
        return EncryptedInput({
            ctHash: input.ctHash,
            securityZone: input.securityZone,
            utype: EADDRESS_TFHE,
            signature: input.signature
        });
    }
}

// lib/openzeppelin-contracts/contracts/utils/math/Math.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// lib/openzeppelin-contracts/contracts/utils/math/SignedMath.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// lib/openzeppelin-contracts/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// lib/openzeppelin-contracts/contracts/utils/Strings.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// lib/cofhe-contracts/contracts/FHE.sol

// solhint-disable one-contract-per-file

type ebool is uint256;
type euint8 is uint256;
type euint16 is uint256;
type euint32 is uint256;
type euint64 is uint256;
type euint128 is uint256;
type euint256 is uint256;
type eaddress is uint256;

// ================================
// \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/
// TODO : CHANGE ME AFTER DEPLOYING
// /\ /\ /\ /\ /\ /\ /\ /\ /\ /\ /\
// ================================
//solhint-disable const-name-snakecase
address constant TASK_MANAGER_ADDRESS = 0xeA30c4B8b44078Bbf8a6ef5b9f1eC1626C7848D9;

library Common {
    error InvalidHexCharacter(bytes1 char);
    error SecurityZoneOutOfBounds(int32 value);

    // Default value for temp hash calculation in unary operations
    string private constant DEFAULT_VALUE = "0";

    function convertInt32ToUint256(int32 value) internal pure returns (uint256) {
        if (value < 0) {
            revert SecurityZoneOutOfBounds(value);
        }
        return uint256(uint32(value));
    }

    function isInitialized(uint256 hash) internal pure returns (bool) {
        return hash != 0;
    }

    // Return true if the encrypted integer is initialized and false otherwise.
    function isInitialized(ebool v) internal pure returns (bool) {
        return isInitialized(ebool.unwrap(v));
    }

    // Return true if the encrypted integer is initialized and false otherwise.
    function isInitialized(euint8 v) internal pure returns (bool) {
        return isInitialized(euint8.unwrap(v));
    }

    // Return true if the encrypted integer is initialized and false otherwise.
    function isInitialized(euint16 v) internal pure returns (bool) {
        return isInitialized(euint16.unwrap(v));
    }

    // Return true if the encrypted integer is initialized and false otherwise.
    function isInitialized(euint32 v) internal pure returns (bool) {
        return isInitialized(euint32.unwrap(v));
    }

    // Return true if the encrypted integer is initialized and false otherwise.
    function isInitialized(euint64 v) internal pure returns (bool) {
        return isInitialized(euint64.unwrap(v));
    }

    // Return true if the encrypted integer is initialized and false otherwise.
    function isInitialized(euint128 v) internal pure returns (bool) {
        return isInitialized(euint128.unwrap(v));
    }

    // Return true if the encrypted integer is initialized and false otherwise.
    function isInitialized(euint256 v) internal pure returns (bool) {
        return isInitialized(euint256.unwrap(v));
    }

    function isInitialized(eaddress v) internal pure returns (bool) {
        return isInitialized(eaddress.unwrap(v));
    }

    function createUint256Inputs(uint256 input1) internal pure returns (uint256[] memory) {
        uint256[] memory inputs = new uint256[](1);
        inputs[0] = input1;
        return inputs;
    }

    function createUint256Inputs(uint256 input1, uint256 input2) internal pure returns (uint256[] memory) {
        uint256[] memory inputs = new uint256[](2);
        inputs[0] = input1;
        inputs[1] = input2;
        return inputs;
    }

    function createUint256Inputs(uint256 input1, uint256 input2, uint256 input3) internal pure returns (uint256[] memory) {
        uint256[] memory inputs = new uint256[](3);
        inputs[0] = input1;
        inputs[1] = input2;
        inputs[2] = input3;
        return inputs;
    }
}

library Impl {
    function trivialEncrypt(uint256 value, uint8 toType, int32 securityZone) internal returns (uint256) {
        return ITaskManager(TASK_MANAGER_ADDRESS).createTask(toType, FunctionId.trivialEncrypt, new uint256[](0), Common.createUint256Inputs(value, toType, Common.convertInt32ToUint256(securityZone)));
    }

    function cast(uint256 key, uint8 toType) internal returns (uint256) {
        return ITaskManager(TASK_MANAGER_ADDRESS).createTask(toType, FunctionId.cast, Common.createUint256Inputs(key), Common.createUint256Inputs(toType));
    }

    function select(uint8 returnType, ebool control, uint256 ifTrue, uint256 ifFalse) internal returns (uint256 result) {
        return ITaskManager(TASK_MANAGER_ADDRESS).createTask(returnType,
            FunctionId.select,
            Common.createUint256Inputs(ebool.unwrap(control), ifTrue, ifFalse),
            new uint256[](0));
    }

    function mathOp(uint8 returnType, uint256 lhs, uint256 rhs, FunctionId functionId) internal returns (uint256) {
        return ITaskManager(TASK_MANAGER_ADDRESS).createTask(returnType, functionId, Common.createUint256Inputs(lhs, rhs), new uint256[](0));
    }

    function decrypt(uint256 input) internal returns (uint256) {
        ITaskManager(TASK_MANAGER_ADDRESS).createDecryptTask(input, msg.sender);
        return input;
    }

    function getDecryptResult(uint256 input) internal view returns (uint256) {
        return ITaskManager(TASK_MANAGER_ADDRESS).getDecryptResult(input);
    }

    function getDecryptResultSafe(uint256 input) internal view returns (uint256 result, bool decrypted) {
        return ITaskManager(TASK_MANAGER_ADDRESS).getDecryptResultSafe(input);
    }

    function not(uint8 returnType, uint256 input) internal returns (uint256) {
        return ITaskManager(TASK_MANAGER_ADDRESS).createTask(returnType, FunctionId.not, Common.createUint256Inputs(input), new uint256[](0));
    }

    function square(uint8 returnType, uint256 input) internal returns (uint256) {
        return ITaskManager(TASK_MANAGER_ADDRESS).createTask(returnType, FunctionId.square, Common.createUint256Inputs(input), new uint256[](0));
    }

    function verifyInput(EncryptedInput memory input) internal returns (uint256) {
        return ITaskManager(TASK_MANAGER_ADDRESS).verifyInput(input, msg.sender);
    }

    /// @notice Generates a random value of a given type with the given seed, for the provided securityZone
    /// @dev Calls the desired function
    /// @param uintType the type of the random value to generate
    /// @param seed the seed to use to create a random value from
    /// @param securityZone the security zone to use for the random value
    function random(uint8 uintType, uint256 seed, int32 securityZone) internal returns (uint256) {
        return ITaskManager(TASK_MANAGER_ADDRESS).createRandomTask(uintType, seed, securityZone);
    }

    /// @notice Generates a random value of a given type with the given seed
    /// @dev Calls the desired function
    /// @param uintType the type of the random value to generate
    /// @param seed the seed to use to create a random value from
    function random(uint8 uintType, uint256 seed) internal returns (uint256) {
        return random(uintType, seed, 0);
    }

    /// @notice Generates a random value of a given type
    /// @dev Calls the desired function
    /// @param uintType the type of the random value to generate
    function random(uint8 uintType) internal returns (uint256) {
        return random(uintType, 0, 0);
    }
}

library FHE {

    error InvalidEncryptedInput(uint8 got, uint8 expected);
    /// @notice Perform the addition operation on two parameters of type euint8
    /// @dev Verifies that inputs are initialized, performs encrypted addition
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return result of type euint8 containing the addition result
    function add(euint8 lhs, euint8 rhs) internal returns (euint8) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint8(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint8(0);
        }

        return euint8.wrap(Impl.mathOp(Utils.EUINT8_TFHE, euint8.unwrap(lhs), euint8.unwrap(rhs), FunctionId.add));
    }

    /// @notice Perform the addition operation on two parameters of type euint16
    /// @dev Verifies that inputs are initialized, performs encrypted addition
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return result of type euint16 containing the addition result
    function add(euint16 lhs, euint16 rhs) internal returns (euint16) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint16(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint16(0);
        }

        return euint16.wrap(Impl.mathOp(Utils.EUINT16_TFHE, euint16.unwrap(lhs), euint16.unwrap(rhs), FunctionId.add));
    }

    /// @notice Perform the addition operation on two parameters of type euint32
    /// @dev Verifies that inputs are initialized, performs encrypted addition
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return result of type euint32 containing the addition result
    function add(euint32 lhs, euint32 rhs) internal returns (euint32) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint32(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint32(0);
        }

        return euint32.wrap(Impl.mathOp(Utils.EUINT32_TFHE, euint32.unwrap(lhs), euint32.unwrap(rhs), FunctionId.add));
    }

    /// @notice Perform the addition operation on two parameters of type euint64
    /// @dev Verifies that inputs are initialized, performs encrypted addition
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return result of type euint64 containing the addition result
    function add(euint64 lhs, euint64 rhs) internal returns (euint64) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint64(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint64(0);
        }

        return euint64.wrap(Impl.mathOp(Utils.EUINT64_TFHE, euint64.unwrap(lhs), euint64.unwrap(rhs), FunctionId.add));
    }

    /// @notice Perform the addition operation on two parameters of type euint128
    /// @dev Verifies that inputs are initialized, performs encrypted addition
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return result of type euint128 containing the addition result
    function add(euint128 lhs, euint128 rhs) internal returns (euint128) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint128(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint128(0);
        }

        return euint128.wrap(Impl.mathOp(Utils.EUINT128_TFHE, euint128.unwrap(lhs), euint128.unwrap(rhs), FunctionId.add));
    }

    /// @notice Perform the addition operation on two parameters of type euint256
    /// @dev Verifies that inputs are initialized, performs encrypted addition
    /// @param lhs input of type euint256
    /// @param rhs second input of type euint256
    /// @return result of type euint256 containing the addition result
    function add(euint256 lhs, euint256 rhs) internal returns (euint256) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint256(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint256(0);
        }

        return euint256.wrap(Impl.mathOp(Utils.EUINT256_TFHE, euint256.unwrap(lhs), euint256.unwrap(rhs), FunctionId.add));
    }

    /// @notice Perform the less than or equal to operation on two parameters of type euint8
    /// @dev Verifies that inputs are initialized, performs encrypted comparison
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return result of type ebool containing the comparison result
    function lte(euint8 lhs, euint8 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint8(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint8(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT8_TFHE, euint8.unwrap(lhs), euint8.unwrap(rhs), FunctionId.lte));
    }

    /// @notice Perform the less than or equal to operation on two parameters of type euint16
    /// @dev Verifies that inputs are initialized, performs encrypted comparison
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return result of type ebool containing the comparison result
    function lte(euint16 lhs, euint16 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint16(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint16(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT16_TFHE, euint16.unwrap(lhs), euint16.unwrap(rhs), FunctionId.lte));
    }

    /// @notice Perform the less than or equal to operation on two parameters of type euint32
    /// @dev Verifies that inputs are initialized, performs encrypted comparison
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return result of type ebool containing the comparison result
    function lte(euint32 lhs, euint32 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint32(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint32(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT32_TFHE, euint32.unwrap(lhs), euint32.unwrap(rhs), FunctionId.lte));
    }

    /// @notice Perform the less than or equal to operation on two parameters of type euint64
    /// @dev Verifies that inputs are initialized, performs encrypted comparison
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return result of type ebool containing the comparison result
    function lte(euint64 lhs, euint64 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint64(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint64(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT64_TFHE, euint64.unwrap(lhs), euint64.unwrap(rhs), FunctionId.lte));
    }

    /// @notice Perform the less than or equal to operation on two parameters of type euint128
    /// @dev Verifies that inputs are initialized, performs encrypted comparison
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return result of type ebool containing the comparison result
    function lte(euint128 lhs, euint128 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint128(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint128(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT128_TFHE, euint128.unwrap(lhs), euint128.unwrap(rhs), FunctionId.lte));
    }

    /// @notice Perform the less than or equal to operation on two parameters of type euint256
    /// @dev Verifies that inputs are initialized, performs encrypted comparison
    /// @param lhs input of type euint256
    /// @param rhs second input of type euint256
    /// @return result of type ebool containing the comparison result
    function lte(euint256 lhs, euint256 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint256(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint256(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT256_TFHE, euint256.unwrap(lhs), euint256.unwrap(rhs), FunctionId.lte));
    }

    /// @notice Perform the subtraction operation on two parameters of type euint8
    /// @dev Verifies that inputs are initialized, performs encrypted subtraction
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return result of type euint8 containing the subtraction result
    function sub(euint8 lhs, euint8 rhs) internal returns (euint8) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint8(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint8(0);
        }

        return euint8.wrap(Impl.mathOp(Utils.EUINT8_TFHE, euint8.unwrap(lhs), euint8.unwrap(rhs), FunctionId.sub));
    }

    /// @notice Perform the subtraction operation on two parameters of type euint16
    /// @dev Verifies that inputs are initialized, performs encrypted subtraction
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return result of type euint16 containing the subtraction result
    function sub(euint16 lhs, euint16 rhs) internal returns (euint16) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint16(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint16(0);
        }

        return euint16.wrap(Impl.mathOp(Utils.EUINT16_TFHE, euint16.unwrap(lhs), euint16.unwrap(rhs), FunctionId.sub));
    }

    /// @notice Perform the subtraction operation on two parameters of type euint32
    /// @dev Verifies that inputs are initialized, performs encrypted subtraction
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return result of type euint32 containing the subtraction result
    function sub(euint32 lhs, euint32 rhs) internal returns (euint32) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint32(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint32(0);
        }

        return euint32.wrap(Impl.mathOp(Utils.EUINT32_TFHE, euint32.unwrap(lhs), euint32.unwrap(rhs), FunctionId.sub));
    }

    /// @notice Perform the subtraction operation on two parameters of type euint64
    /// @dev Verifies that inputs are initialized, performs encrypted subtraction
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return result of type euint64 containing the subtraction result
    function sub(euint64 lhs, euint64 rhs) internal returns (euint64) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint64(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint64(0);
        }

        return euint64.wrap(Impl.mathOp(Utils.EUINT64_TFHE, euint64.unwrap(lhs), euint64.unwrap(rhs), FunctionId.sub));
    }

    /// @notice Perform the subtraction operation on two parameters of type euint128
    /// @dev Verifies that inputs are initialized, performs encrypted subtraction
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return result of type euint128 containing the subtraction result
    function sub(euint128 lhs, euint128 rhs) internal returns (euint128) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint128(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint128(0);
        }

        return euint128.wrap(Impl.mathOp(Utils.EUINT128_TFHE, euint128.unwrap(lhs), euint128.unwrap(rhs), FunctionId.sub));
    }

    /// @notice Perform the subtraction operation on two parameters of type euint256
    /// @dev Verifies that inputs are initialized, performs encrypted subtraction
    /// @param lhs input of type euint256
    /// @param rhs second input of type euint256
    /// @return result of type euint256 containing the subtraction result
    function sub(euint256 lhs, euint256 rhs) internal returns (euint256) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint256(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint256(0);
        }

        return euint256.wrap(Impl.mathOp(Utils.EUINT256_TFHE, euint256.unwrap(lhs), euint256.unwrap(rhs), FunctionId.sub));
    }

    /// @notice Perform the multiplication operation on two parameters of type euint8
    /// @dev Verifies that inputs are initialized, performs encrypted multiplication
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return result of type euint8 containing the multiplication result
    function mul(euint8 lhs, euint8 rhs) internal returns (euint8) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint8(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint8(0);
        }

        return euint8.wrap(Impl.mathOp(Utils.EUINT8_TFHE, euint8.unwrap(lhs), euint8.unwrap(rhs), FunctionId.mul));
    }

    /// @notice Perform the multiplication operation on two parameters of type euint16
    /// @dev Verifies that inputs are initialized, performs encrypted multiplication
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return result of type euint16 containing the multiplication result
    function mul(euint16 lhs, euint16 rhs) internal returns (euint16) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint16(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint16(0);
        }

        return euint16.wrap(Impl.mathOp(Utils.EUINT16_TFHE, euint16.unwrap(lhs), euint16.unwrap(rhs), FunctionId.mul));
    }

    /// @notice Perform the multiplication operation on two parameters of type euint32
    /// @dev Verifies that inputs are initialized, performs encrypted multiplication
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return result of type euint32 containing the multiplication result
    function mul(euint32 lhs, euint32 rhs) internal returns (euint32) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint32(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint32(0);
        }

        return euint32.wrap(Impl.mathOp(Utils.EUINT32_TFHE, euint32.unwrap(lhs), euint32.unwrap(rhs), FunctionId.mul));
    }

    /// @notice Perform the multiplication operation on two parameters of type euint64
    /// @dev Verifies that inputs are initialized, performs encrypted multiplication
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return result of type euint64 containing the multiplication result
    function mul(euint64 lhs, euint64 rhs) internal returns (euint64) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint64(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint64(0);
        }

        return euint64.wrap(Impl.mathOp(Utils.EUINT64_TFHE, euint64.unwrap(lhs), euint64.unwrap(rhs), FunctionId.mul));
    }

    /// @notice Perform the multiplication operation on two parameters of type euint128
    /// @dev Verifies that inputs are initialized, performs encrypted multiplication
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return result of type euint128 containing the multiplication result
    function mul(euint128 lhs, euint128 rhs) internal returns (euint128) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint128(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint128(0);
        }

        return euint128.wrap(Impl.mathOp(Utils.EUINT128_TFHE, euint128.unwrap(lhs), euint128.unwrap(rhs), FunctionId.mul));
    }

    /// @notice Perform the multiplication operation on two parameters of type euint256
    /// @dev Verifies that inputs are initialized, performs encrypted multiplication
    /// @param lhs input of type euint256
    /// @param rhs second input of type euint256
    /// @return result of type euint256 containing the multiplication result
    function mul(euint256 lhs, euint256 rhs) internal returns (euint256) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint256(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint256(0);
        }

        return euint256.wrap(Impl.mathOp(Utils.EUINT256_TFHE, euint256.unwrap(lhs), euint256.unwrap(rhs), FunctionId.mul));
    }

    /// @notice Perform the less than operation on two parameters of type euint8
    /// @dev Verifies that inputs are initialized, performs encrypted comparison
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return result of type ebool containing the comparison result
    function lt(euint8 lhs, euint8 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint8(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint8(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT8_TFHE, euint8.unwrap(lhs), euint8.unwrap(rhs), FunctionId.lt));
    }

    /// @notice Perform the less than operation on two parameters of type euint16
    /// @dev Verifies that inputs are initialized, performs encrypted comparison
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return result of type ebool containing the comparison result
    function lt(euint16 lhs, euint16 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint16(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint16(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT16_TFHE, euint16.unwrap(lhs), euint16.unwrap(rhs), FunctionId.lt));
    }

    /// @notice Perform the less than operation on two parameters of type euint32
    /// @dev Verifies that inputs are initialized, performs encrypted comparison
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return result of type ebool containing the comparison result
    function lt(euint32 lhs, euint32 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint32(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint32(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT32_TFHE, euint32.unwrap(lhs), euint32.unwrap(rhs), FunctionId.lt));
    }

    /// @notice Perform the less than operation on two parameters of type euint64
    /// @dev Verifies that inputs are initialized, performs encrypted comparison
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return result of type ebool containing the comparison result
    function lt(euint64 lhs, euint64 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint64(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint64(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT64_TFHE, euint64.unwrap(lhs), euint64.unwrap(rhs), FunctionId.lt));
    }

    /// @notice Perform the less than operation on two parameters of type euint128
    /// @dev Verifies that inputs are initialized, performs encrypted comparison
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return result of type ebool containing the comparison result
    function lt(euint128 lhs, euint128 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint128(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint128(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT128_TFHE, euint128.unwrap(lhs), euint128.unwrap(rhs), FunctionId.lt));
    }

    /// @notice Perform the less than operation on two parameters of type euint256
    /// @dev Verifies that inputs are initialized, performs encrypted comparison
    /// @param lhs input of type euint256
    /// @param rhs second input of type euint256
    /// @return result of type ebool containing the comparison result
    function lt(euint256 lhs, euint256 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint256(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint256(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT256_TFHE, euint256.unwrap(lhs), euint256.unwrap(rhs), FunctionId.lt));
    }

    /// @notice Perform the division operation on two parameters of type euint8
    /// @dev Verifies that inputs are initialized, performs encrypted division
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return result of type euint8 containing the division result
    function div(euint8 lhs, euint8 rhs) internal returns (euint8) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint8(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint8(0);
        }

        return euint8.wrap(Impl.mathOp(Utils.EUINT8_TFHE, euint8.unwrap(lhs), euint8.unwrap(rhs), FunctionId.div));
    }

    /// @notice Perform the division operation on two parameters of type euint16
    /// @dev Verifies that inputs are initialized, performs encrypted division
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return result of type euint16 containing the division result
    function div(euint16 lhs, euint16 rhs) internal returns (euint16) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint16(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint16(0);
        }

        return euint16.wrap(Impl.mathOp(Utils.EUINT16_TFHE, euint16.unwrap(lhs), euint16.unwrap(rhs), FunctionId.div));
    }

    /// @notice Perform the division operation on two parameters of type euint32
    /// @dev Verifies that inputs are initialized, performs encrypted division
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return result of type euint32 containing the division result
    function div(euint32 lhs, euint32 rhs) internal returns (euint32) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint32(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint32(0);
        }

        return euint32.wrap(Impl.mathOp(Utils.EUINT32_TFHE, euint32.unwrap(lhs), euint32.unwrap(rhs), FunctionId.div));
    }

    /// @notice Perform the division operation on two parameters of type euint64
    /// @dev Verifies that inputs are initialized, performs encrypted division
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return result of type euint64 containing the division result
    function div(euint64 lhs, euint64 rhs) internal returns (euint64) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint64(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint64(0);
        }

        return euint64.wrap(Impl.mathOp(Utils.EUINT64_TFHE, euint64.unwrap(lhs), euint64.unwrap(rhs), FunctionId.div));
    }

    /// @notice Perform the division operation on two parameters of type euint128
    /// @dev Verifies that inputs are initialized, performs encrypted division
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return result of type euint128 containing the division result
    function div(euint128 lhs, euint128 rhs) internal returns (euint128) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint128(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint128(0);
        }

        return euint128.wrap(Impl.mathOp(Utils.EUINT128_TFHE, euint128.unwrap(lhs), euint128.unwrap(rhs), FunctionId.div));
    }

    /// @notice Perform the division operation on two parameters of type euint256
    /// @dev Verifies that inputs are initialized, performs encrypted division
    /// @param lhs input of type euint256
    /// @param rhs second input of type euint256
    /// @return result of type euint256 containing the division result
    function div(euint256 lhs, euint256 rhs) internal returns (euint256) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint256(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint256(0);
        }

        return euint256.wrap(Impl.mathOp(Utils.EUINT256_TFHE, euint256.unwrap(lhs), euint256.unwrap(rhs), FunctionId.div));
    }

    /// @notice Perform the greater than operation on two parameters of type euint8
    /// @dev Verifies that inputs are initialized, performs encrypted comparison
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return result of type ebool containing the comparison result
    function gt(euint8 lhs, euint8 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint8(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint8(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT8_TFHE, euint8.unwrap(lhs), euint8.unwrap(rhs), FunctionId.gt));
    }

    /// @notice Perform the greater than operation on two parameters of type euint16
    /// @dev Verifies that inputs are initialized, performs encrypted comparison
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return result of type ebool containing the comparison result
    function gt(euint16 lhs, euint16 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint16(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint16(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT16_TFHE, euint16.unwrap(lhs), euint16.unwrap(rhs), FunctionId.gt));
    }

    /// @notice Perform the greater than operation on two parameters of type euint32
    /// @dev Verifies that inputs are initialized, performs encrypted comparison
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return result of type ebool containing the comparison result
    function gt(euint32 lhs, euint32 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint32(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint32(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT32_TFHE, euint32.unwrap(lhs), euint32.unwrap(rhs), FunctionId.gt));
    }

    /// @notice Perform the greater than operation on two parameters of type euint64
    /// @dev Verifies that inputs are initialized, performs encrypted comparison
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return result of type ebool containing the comparison result
    function gt(euint64 lhs, euint64 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint64(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint64(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT64_TFHE, euint64.unwrap(lhs), euint64.unwrap(rhs), FunctionId.gt));
    }

    /// @notice Perform the greater than operation on two parameters of type euint128
    /// @dev Verifies that inputs are initialized, performs encrypted comparison
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return result of type ebool containing the comparison result
    function gt(euint128 lhs, euint128 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint128(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint128(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT128_TFHE, euint128.unwrap(lhs), euint128.unwrap(rhs), FunctionId.gt));
    }

    /// @notice Perform the greater than operation on two parameters of type euint256
    /// @dev Verifies that inputs are initialized, performs encrypted comparison
    /// @param lhs input of type euint256
    /// @param rhs second input of type euint256
    /// @return result of type ebool containing the comparison result
    function gt(euint256 lhs, euint256 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint256(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint256(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT256_TFHE, euint256.unwrap(lhs), euint256.unwrap(rhs), FunctionId.gt));
    }

    /// @notice Perform the greater than or equal to operation on two parameters of type euint8
    /// @dev Verifies that inputs are initialized, performs encrypted comparison
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return result of type ebool containing the comparison result
    function gte(euint8 lhs, euint8 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint8(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint8(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT8_TFHE, euint8.unwrap(lhs), euint8.unwrap(rhs), FunctionId.gte));
    }

    /// @notice Perform the greater than or equal to operation on two parameters of type euint16
    /// @dev Verifies that inputs are initialized, performs encrypted comparison
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return result of type ebool containing the comparison result
    function gte(euint16 lhs, euint16 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint16(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint16(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT16_TFHE, euint16.unwrap(lhs), euint16.unwrap(rhs), FunctionId.gte));
    }

    /// @notice Perform the greater than or equal to operation on two parameters of type euint32
    /// @dev Verifies that inputs are initialized, performs encrypted comparison
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return result of type ebool containing the comparison result
    function gte(euint32 lhs, euint32 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint32(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint32(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT32_TFHE, euint32.unwrap(lhs), euint32.unwrap(rhs), FunctionId.gte));
    }

    /// @notice Perform the greater than or equal to operation on two parameters of type euint64
    /// @dev Verifies that inputs are initialized, performs encrypted comparison
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return result of type ebool containing the comparison result
    function gte(euint64 lhs, euint64 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint64(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint64(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT64_TFHE, euint64.unwrap(lhs), euint64.unwrap(rhs), FunctionId.gte));
    }

    /// @notice Perform the greater than or equal to operation on two parameters of type euint128
    /// @dev Verifies that inputs are initialized, performs encrypted comparison
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return result of type ebool containing the comparison result
    function gte(euint128 lhs, euint128 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint128(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint128(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT128_TFHE, euint128.unwrap(lhs), euint128.unwrap(rhs), FunctionId.gte));
    }

    /// @notice Perform the greater than or equal to operation on two parameters of type euint256
    /// @dev Verifies that inputs are initialized, performs encrypted comparison
    /// @param lhs input of type euint256
    /// @param rhs second input of type euint256
    /// @return result of type ebool containing the comparison result
    function gte(euint256 lhs, euint256 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint256(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint256(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT256_TFHE, euint256.unwrap(lhs), euint256.unwrap(rhs), FunctionId.gte));
    }

    /// @notice Perform the remainder operation on two parameters of type euint8
    /// @dev Verifies that inputs are initialized, performs encrypted remainder calculation
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return result of type euint8 containing the remainder result
    function rem(euint8 lhs, euint8 rhs) internal returns (euint8) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint8(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint8(0);
        }

        return euint8.wrap(Impl.mathOp(Utils.EUINT8_TFHE, euint8.unwrap(lhs), euint8.unwrap(rhs), FunctionId.rem));
    }

    /// @notice Perform the remainder operation on two parameters of type euint16
    /// @dev Verifies that inputs are initialized, performs encrypted remainder calculation
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return result of type euint16 containing the remainder result
    function rem(euint16 lhs, euint16 rhs) internal returns (euint16) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint16(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint16(0);
        }

        return euint16.wrap(Impl.mathOp(Utils.EUINT16_TFHE, euint16.unwrap(lhs), euint16.unwrap(rhs), FunctionId.rem));
    }

    /// @notice Perform the remainder operation on two parameters of type euint32
    /// @dev Verifies that inputs are initialized, performs encrypted remainder calculation
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return result of type euint32 containing the remainder result
    function rem(euint32 lhs, euint32 rhs) internal returns (euint32) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint32(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint32(0);
        }

        return euint32.wrap(Impl.mathOp(Utils.EUINT32_TFHE, euint32.unwrap(lhs), euint32.unwrap(rhs), FunctionId.rem));
    }

    /// @notice Perform the remainder operation on two parameters of type euint64
    /// @dev Verifies that inputs are initialized, performs encrypted remainder calculation
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return result of type euint64 containing the remainder result
    function rem(euint64 lhs, euint64 rhs) internal returns (euint64) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint64(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint64(0);
        }

        return euint64.wrap(Impl.mathOp(Utils.EUINT64_TFHE, euint64.unwrap(lhs), euint64.unwrap(rhs), FunctionId.rem));
    }

    /// @notice Perform the remainder operation on two parameters of type euint128
    /// @dev Verifies that inputs are initialized, performs encrypted remainder calculation
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return result of type euint128 containing the remainder result
    function rem(euint128 lhs, euint128 rhs) internal returns (euint128) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint128(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint128(0);
        }

        return euint128.wrap(Impl.mathOp(Utils.EUINT128_TFHE, euint128.unwrap(lhs), euint128.unwrap(rhs), FunctionId.rem));
    }

    /// @notice Perform the remainder operation on two parameters of type euint256
    /// @dev Verifies that inputs are initialized, performs encrypted remainder calculation
    /// @param lhs input of type euint256
    /// @param rhs second input of type euint256
    /// @return result of type euint256 containing the remainder result
    function rem(euint256 lhs, euint256 rhs) internal returns (euint256) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint256(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint256(0);
        }

        return euint256.wrap(Impl.mathOp(Utils.EUINT256_TFHE, euint256.unwrap(lhs), euint256.unwrap(rhs), FunctionId.rem));
    }

    /// @notice Perform the bitwise AND operation on two parameters of type ebool
    /// @dev Verifies that inputs are initialized, performs encrypted bitwise AND
    /// @param lhs input of type ebool
    /// @param rhs second input of type ebool
    /// @return result of type ebool containing the AND result
    function and(ebool lhs, ebool rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEbool(true);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEbool(true);
        }

        return ebool.wrap(Impl.mathOp(Utils.EBOOL_TFHE, ebool.unwrap(lhs), ebool.unwrap(rhs), FunctionId.and));
    }

    /// @notice Perform the bitwise AND operation on two parameters of type euint8
    /// @dev Verifies that inputs are initialized, performs encrypted bitwise AND
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return result of type euint8 containing the AND result
    function and(euint8 lhs, euint8 rhs) internal returns (euint8) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint8(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint8(0);
        }

        return euint8.wrap(Impl.mathOp(Utils.EUINT8_TFHE, euint8.unwrap(lhs), euint8.unwrap(rhs), FunctionId.and));
    }

    /// @notice Perform the bitwise AND operation on two parameters of type euint16
    /// @dev Verifies that inputs are initialized, performs encrypted bitwise AND
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return result of type euint16 containing the AND result
    function and(euint16 lhs, euint16 rhs) internal returns (euint16) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint16(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint16(0);
        }

        return euint16.wrap(Impl.mathOp(Utils.EUINT16_TFHE, euint16.unwrap(lhs), euint16.unwrap(rhs), FunctionId.and));
    }

    /// @notice Perform the bitwise AND operation on two parameters of type euint32
    /// @dev Verifies that inputs are initialized, performs encrypted bitwise AND
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return result of type euint32 containing the AND result
    function and(euint32 lhs, euint32 rhs) internal returns (euint32) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint32(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint32(0);
        }

        return euint32.wrap(Impl.mathOp(Utils.EUINT32_TFHE, euint32.unwrap(lhs), euint32.unwrap(rhs), FunctionId.and));
    }

    /// @notice Perform the bitwise AND operation on two parameters of type euint64
    /// @dev Verifies that inputs are initialized, performs encrypted bitwise AND
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return result of type euint64 containing the AND result
    function and(euint64 lhs, euint64 rhs) internal returns (euint64) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint64(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint64(0);
        }

        return euint64.wrap(Impl.mathOp(Utils.EUINT64_TFHE, euint64.unwrap(lhs), euint64.unwrap(rhs), FunctionId.and));
    }

    /// @notice Perform the bitwise AND operation on two parameters of type euint128
    /// @dev Verifies that inputs are initialized, performs encrypted bitwise AND
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return result of type euint128 containing the AND result
    function and(euint128 lhs, euint128 rhs) internal returns (euint128) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint128(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint128(0);
        }

        return euint128.wrap(Impl.mathOp(Utils.EUINT128_TFHE, euint128.unwrap(lhs), euint128.unwrap(rhs), FunctionId.and));
    }

    /// @notice Perform the bitwise AND operation on two parameters of type euint256
    /// @dev Verifies that inputs are initialized, performs encrypted bitwise AND
    /// @param lhs input of type euint256
    /// @param rhs second input of type euint256
    /// @return result of type euint256 containing the AND result
    function and(euint256 lhs, euint256 rhs) internal returns (euint256) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint256(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint256(0);
        }

        return euint256.wrap(Impl.mathOp(Utils.EUINT256_TFHE, euint256.unwrap(lhs), euint256.unwrap(rhs), FunctionId.and));
    }

    /// @notice Perform the bitwise OR operation on two parameters of type ebool
    /// @dev Verifies that inputs are initialized, performs encrypted bitwise OR
    /// @param lhs input of type ebool
    /// @param rhs second input of type ebool
    /// @return result of type ebool containing the OR result
    function or(ebool lhs, ebool rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEbool(true);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEbool(true);
        }

        return ebool.wrap(Impl.mathOp(Utils.EBOOL_TFHE, ebool.unwrap(lhs), ebool.unwrap(rhs), FunctionId.or));
    }

    /// @notice Perform the bitwise OR operation on two parameters of type euint8
    /// @dev Verifies that inputs are initialized, performs encrypted bitwise OR
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return result of type euint8 containing the OR result
    function or(euint8 lhs, euint8 rhs) internal returns (euint8) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint8(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint8(0);
        }

        return euint8.wrap(Impl.mathOp(Utils.EUINT8_TFHE, euint8.unwrap(lhs), euint8.unwrap(rhs), FunctionId.or));
    }

    /// @notice Perform the bitwise OR operation on two parameters of type euint16
    /// @dev Verifies that inputs are initialized, performs encrypted bitwise OR
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return result of type euint16 containing the OR result
    function or(euint16 lhs, euint16 rhs) internal returns (euint16) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint16(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint16(0);
        }

        return euint16.wrap(Impl.mathOp(Utils.EUINT16_TFHE, euint16.unwrap(lhs), euint16.unwrap(rhs), FunctionId.or));
    }

    /// @notice Perform the bitwise OR operation on two parameters of type euint32
    /// @dev Verifies that inputs are initialized, performs encrypted bitwise OR
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return result of type euint32 containing the OR result
    function or(euint32 lhs, euint32 rhs) internal returns (euint32) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint32(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint32(0);
        }

        return euint32.wrap(Impl.mathOp(Utils.EUINT32_TFHE, euint32.unwrap(lhs), euint32.unwrap(rhs), FunctionId.or));
    }

    /// @notice Perform the bitwise OR operation on two parameters of type euint64
    /// @dev Verifies that inputs are initialized, performs encrypted bitwise OR
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return result of type euint64 containing the OR result
    function or(euint64 lhs, euint64 rhs) internal returns (euint64) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint64(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint64(0);
        }

        return euint64.wrap(Impl.mathOp(Utils.EUINT64_TFHE, euint64.unwrap(lhs), euint64.unwrap(rhs), FunctionId.or));
    }

    /// @notice Perform the bitwise OR operation on two parameters of type euint128
    /// @dev Verifies that inputs are initialized, performs encrypted bitwise OR
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return result of type euint128 containing the OR result
    function or(euint128 lhs, euint128 rhs) internal returns (euint128) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint128(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint128(0);
        }

        return euint128.wrap(Impl.mathOp(Utils.EUINT128_TFHE, euint128.unwrap(lhs), euint128.unwrap(rhs), FunctionId.or));
    }

    /// @notice Perform the bitwise OR operation on two parameters of type euint256
    /// @dev Verifies that inputs are initialized, performs encrypted bitwise OR
    /// @param lhs input of type euint256
    /// @param rhs second input of type euint256
    /// @return result of type euint256 containing the OR result
    function or(euint256 lhs, euint256 rhs) internal returns (euint256) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint256(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint256(0);
        }

        return euint256.wrap(Impl.mathOp(Utils.EUINT256_TFHE, euint256.unwrap(lhs), euint256.unwrap(rhs), FunctionId.or));
    }

    /// @notice Perform the bitwise XOR operation on two parameters of type ebool
    /// @dev Verifies that inputs are initialized, performs encrypted bitwise XOR
    /// @param lhs input of type ebool
    /// @param rhs second input of type ebool
    /// @return result of type ebool containing the XOR result
    function xor(ebool lhs, ebool rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEbool(true);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEbool(true);
        }

        return ebool.wrap(Impl.mathOp(Utils.EBOOL_TFHE, ebool.unwrap(lhs), ebool.unwrap(rhs), FunctionId.xor));
    }

    /// @notice Perform the bitwise XOR operation on two parameters of type euint8
    /// @dev Verifies that inputs are initialized, performs encrypted bitwise XOR
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return result of type euint8 containing the XOR result
    function xor(euint8 lhs, euint8 rhs) internal returns (euint8) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint8(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint8(0);
        }

        return euint8.wrap(Impl.mathOp(Utils.EUINT8_TFHE, euint8.unwrap(lhs), euint8.unwrap(rhs), FunctionId.xor));
    }

    /// @notice Perform the bitwise XOR operation on two parameters of type euint16
    /// @dev Verifies that inputs are initialized, performs encrypted bitwise XOR
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return result of type euint16 containing the XOR result
    function xor(euint16 lhs, euint16 rhs) internal returns (euint16) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint16(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint16(0);
        }

        return euint16.wrap(Impl.mathOp(Utils.EUINT16_TFHE, euint16.unwrap(lhs), euint16.unwrap(rhs), FunctionId.xor));
    }

    /// @notice Perform the bitwise XOR operation on two parameters of type euint32
    /// @dev Verifies that inputs are initialized, performs encrypted bitwise XOR
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return result of type euint32 containing the XOR result
    function xor(euint32 lhs, euint32 rhs) internal returns (euint32) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint32(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint32(0);
        }

        return euint32.wrap(Impl.mathOp(Utils.EUINT32_TFHE, euint32.unwrap(lhs), euint32.unwrap(rhs), FunctionId.xor));
    }

    /// @notice Perform the bitwise XOR operation on two parameters of type euint64
    /// @dev Verifies that inputs are initialized, performs encrypted bitwise XOR
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return result of type euint64 containing the XOR result
    function xor(euint64 lhs, euint64 rhs) internal returns (euint64) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint64(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint64(0);
        }

        return euint64.wrap(Impl.mathOp(Utils.EUINT64_TFHE, euint64.unwrap(lhs), euint64.unwrap(rhs), FunctionId.xor));
    }

    /// @notice Perform the bitwise XOR operation on two parameters of type euint128
    /// @dev Verifies that inputs are initialized, performs encrypted bitwise XOR
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return result of type euint128 containing the XOR result
    function xor(euint128 lhs, euint128 rhs) internal returns (euint128) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint128(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint128(0);
        }

        return euint128.wrap(Impl.mathOp(Utils.EUINT128_TFHE, euint128.unwrap(lhs), euint128.unwrap(rhs), FunctionId.xor));
    }

    /// @notice Perform the bitwise XOR operation on two parameters of type euint256
    /// @dev Verifies that inputs are initialized, performs encrypted bitwise XOR
    /// @param lhs input of type euint256
    /// @param rhs second input of type euint256
    /// @return result of type euint256 containing the XOR result
    function xor(euint256 lhs, euint256 rhs) internal returns (euint256) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint256(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint256(0);
        }

        return euint256.wrap(Impl.mathOp(Utils.EUINT256_TFHE, euint256.unwrap(lhs), euint256.unwrap(rhs), FunctionId.xor));
    }

    /// @notice Perform the equality operation on two parameters of type ebool
    /// @dev Verifies that inputs are initialized, performs encrypted equality check
    /// @param lhs input of type ebool
    /// @param rhs second input of type ebool
    /// @return result of type ebool containing the equality result
    function eq(ebool lhs, ebool rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEbool(true);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEbool(true);
        }

        return ebool.wrap(Impl.mathOp(Utils.EBOOL_TFHE, ebool.unwrap(lhs), ebool.unwrap(rhs), FunctionId.eq));
    }

    /// @notice Perform the equality operation on two parameters of type euint8
    /// @dev Verifies that inputs are initialized, performs encrypted equality check
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return result of type ebool containing the equality result
    function eq(euint8 lhs, euint8 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint8(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint8(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT8_TFHE, euint8.unwrap(lhs), euint8.unwrap(rhs), FunctionId.eq));
    }

    /// @notice Perform the equality operation on two parameters of type euint16
    /// @dev Verifies that inputs are initialized, performs encrypted equality check
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return result of type ebool containing the equality result
    function eq(euint16 lhs, euint16 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint16(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint16(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT16_TFHE, euint16.unwrap(lhs), euint16.unwrap(rhs), FunctionId.eq));
    }

    /// @notice Perform the equality operation on two parameters of type euint32
    /// @dev Verifies that inputs are initialized, performs encrypted equality check
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return result of type ebool containing the equality result
    function eq(euint32 lhs, euint32 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint32(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint32(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT32_TFHE, euint32.unwrap(lhs), euint32.unwrap(rhs), FunctionId.eq));
    }

    /// @notice Perform the equality operation on two parameters of type euint64
    /// @dev Verifies that inputs are initialized, performs encrypted equality check
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return result of type ebool containing the equality result
    function eq(euint64 lhs, euint64 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint64(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint64(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT64_TFHE, euint64.unwrap(lhs), euint64.unwrap(rhs), FunctionId.eq));
    }

    /// @notice Perform the equality operation on two parameters of type euint128
    /// @dev Verifies that inputs are initialized, performs encrypted equality check
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return result of type ebool containing the equality result
    function eq(euint128 lhs, euint128 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint128(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint128(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT128_TFHE, euint128.unwrap(lhs), euint128.unwrap(rhs), FunctionId.eq));
    }

    /// @notice Perform the equality operation on two parameters of type euint256
    /// @dev Verifies that inputs are initialized, performs encrypted equality check
    /// @param lhs input of type euint256
    /// @param rhs second input of type euint256
    /// @return result of type ebool containing the equality result
    function eq(euint256 lhs, euint256 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint256(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint256(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT256_TFHE, euint256.unwrap(lhs), euint256.unwrap(rhs), FunctionId.eq));
    }

    /// @notice Perform the equality operation on two parameters of type eaddress
    /// @dev Verifies that inputs are initialized, performs encrypted equality check
    /// @param lhs input of type eaddress
    /// @param rhs second input of type eaddress
    /// @return result of type ebool containing the equality result
    function eq(eaddress lhs, eaddress rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEaddress(address(0));
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEaddress(address(0));
        }

        return ebool.wrap(Impl.mathOp(Utils.EADDRESS_TFHE, eaddress.unwrap(lhs), eaddress.unwrap(rhs), FunctionId.eq));
    }

    /// @notice Perform the inequality operation on two parameters of type ebool
    /// @dev Verifies that inputs are initialized, performs encrypted inequality check
    /// @param lhs input of type ebool
    /// @param rhs second input of type ebool
    /// @return result of type ebool containing the inequality result
    function ne(ebool lhs, ebool rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEbool(true);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEbool(true);
        }

        return ebool.wrap(Impl.mathOp(Utils.EBOOL_TFHE, ebool.unwrap(lhs), ebool.unwrap(rhs), FunctionId.ne));
    }

    /// @notice Perform the inequality operation on two parameters of type euint8
    /// @dev Verifies that inputs are initialized, performs encrypted inequality check
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return result of type ebool containing the inequality result
    function ne(euint8 lhs, euint8 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint8(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint8(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT8_TFHE, euint8.unwrap(lhs), euint8.unwrap(rhs), FunctionId.ne));
    }

    /// @notice Perform the inequality operation on two parameters of type euint16
    /// @dev Verifies that inputs are initialized, performs encrypted inequality check
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return result of type ebool containing the inequality result
    function ne(euint16 lhs, euint16 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint16(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint16(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT16_TFHE, euint16.unwrap(lhs), euint16.unwrap(rhs), FunctionId.ne));
    }

    /// @notice Perform the inequality operation on two parameters of type euint32
    /// @dev Verifies that inputs are initialized, performs encrypted inequality check
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return result of type ebool containing the inequality result
    function ne(euint32 lhs, euint32 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint32(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint32(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT32_TFHE, euint32.unwrap(lhs), euint32.unwrap(rhs), FunctionId.ne));
    }

    /// @notice Perform the inequality operation on two parameters of type euint64
    /// @dev Verifies that inputs are initialized, performs encrypted inequality check
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return result of type ebool containing the inequality result
    function ne(euint64 lhs, euint64 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint64(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint64(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT64_TFHE, euint64.unwrap(lhs), euint64.unwrap(rhs), FunctionId.ne));
    }

    /// @notice Perform the inequality operation on two parameters of type euint128
    /// @dev Verifies that inputs are initialized, performs encrypted inequality check
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return result of type ebool containing the inequality result
    function ne(euint128 lhs, euint128 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint128(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint128(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT128_TFHE, euint128.unwrap(lhs), euint128.unwrap(rhs), FunctionId.ne));
    }

    /// @notice Perform the inequality operation on two parameters of type euint256
    /// @dev Verifies that inputs are initialized, performs encrypted inequality check
    /// @param lhs input of type euint256
    /// @param rhs second input of type euint256
    /// @return result of type ebool containing the inequality result
    function ne(euint256 lhs, euint256 rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint256(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint256(0);
        }

        return ebool.wrap(Impl.mathOp(Utils.EUINT256_TFHE, euint256.unwrap(lhs), euint256.unwrap(rhs), FunctionId.ne));
    }

    /// @notice Perform the inequality operation on two parameters of type eaddress
    /// @dev Verifies that inputs are initialized, performs encrypted inequality check
    /// @param lhs input of type eaddress
    /// @param rhs second input of type eaddress
    /// @return result of type ebool containing the inequality result
    function ne(eaddress lhs, eaddress rhs) internal returns (ebool) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEaddress(address(0));
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEaddress(address(0));
        }

        return ebool.wrap(Impl.mathOp(Utils.EADDRESS_TFHE, eaddress.unwrap(lhs), eaddress.unwrap(rhs), FunctionId.ne));
    }

    /// @notice Perform the minimum operation on two parameters of type euint8
    /// @dev Verifies that inputs are initialized, performs encrypted minimum comparison
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return result of type euint8 containing the minimum value
    function min(euint8 lhs, euint8 rhs) internal returns (euint8) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint8(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint8(0);
        }

        return euint8.wrap(Impl.mathOp(Utils.EUINT8_TFHE, euint8.unwrap(lhs), euint8.unwrap(rhs), FunctionId.min));
    }

    /// @notice Perform the minimum operation on two parameters of type euint16
    /// @dev Verifies that inputs are initialized, performs encrypted minimum comparison
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return result of type euint16 containing the minimum value
    function min(euint16 lhs, euint16 rhs) internal returns (euint16) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint16(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint16(0);
        }

        return euint16.wrap(Impl.mathOp(Utils.EUINT16_TFHE, euint16.unwrap(lhs), euint16.unwrap(rhs), FunctionId.min));
    }

    /// @notice Perform the minimum operation on two parameters of type euint32
    /// @dev Verifies that inputs are initialized, performs encrypted minimum comparison
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return result of type euint32 containing the minimum value
    function min(euint32 lhs, euint32 rhs) internal returns (euint32) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint32(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint32(0);
        }

        return euint32.wrap(Impl.mathOp(Utils.EUINT32_TFHE, euint32.unwrap(lhs), euint32.unwrap(rhs), FunctionId.min));
    }

    /// @notice Perform the minimum operation on two parameters of type euint64
    /// @dev Verifies that inputs are initialized, performs encrypted minimum comparison
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return result of type euint64 containing the minimum value
    function min(euint64 lhs, euint64 rhs) internal returns (euint64) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint64(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint64(0);
        }

        return euint64.wrap(Impl.mathOp(Utils.EUINT64_TFHE, euint64.unwrap(lhs), euint64.unwrap(rhs), FunctionId.min));
    }

    /// @notice Perform the minimum operation on two parameters of type euint128
    /// @dev Verifies that inputs are initialized, performs encrypted minimum comparison
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return result of type euint128 containing the minimum value
    function min(euint128 lhs, euint128 rhs) internal returns (euint128) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint128(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint128(0);
        }

        return euint128.wrap(Impl.mathOp(Utils.EUINT128_TFHE, euint128.unwrap(lhs), euint128.unwrap(rhs), FunctionId.min));
    }

    /// @notice Perform the minimum operation on two parameters of type euint256
    /// @dev Verifies that inputs are initialized, performs encrypted minimum comparison
    /// @param lhs input of type euint256
    /// @param rhs second input of type euint256
    /// @return result of type euint256 containing the minimum value
    function min(euint256 lhs, euint256 rhs) internal returns (euint256) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint256(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint256(0);
        }

        return euint256.wrap(Impl.mathOp(Utils.EUINT256_TFHE, euint256.unwrap(lhs), euint256.unwrap(rhs), FunctionId.min));
    }

    /// @notice Perform the maximum operation on two parameters of type euint8
    /// @dev Verifies that inputs are initialized, performs encrypted maximum calculation
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return result of type euint8 containing the maximum result
    function max(euint8 lhs, euint8 rhs) internal returns (euint8) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint8(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint8(0);
        }

        return euint8.wrap(Impl.mathOp(Utils.EUINT8_TFHE, euint8.unwrap(lhs), euint8.unwrap(rhs), FunctionId.max));
    }

    /// @notice Perform the maximum operation on two parameters of type euint16
    /// @dev Verifies that inputs are initialized, performs encrypted maximum calculation
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return result of type euint16 containing the maximum result
    function max(euint16 lhs, euint16 rhs) internal returns (euint16) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint16(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint16(0);
        }

        return euint16.wrap(Impl.mathOp(Utils.EUINT16_TFHE, euint16.unwrap(lhs), euint16.unwrap(rhs), FunctionId.max));
    }

    /// @notice Perform the maximum operation on two parameters of type euint32
    /// @dev Verifies that inputs are initialized, performs encrypted maximum calculation
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return result of type euint32 containing the maximum result
    function max(euint32 lhs, euint32 rhs) internal returns (euint32) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint32(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint32(0);
        }

        return euint32.wrap(Impl.mathOp(Utils.EUINT32_TFHE, euint32.unwrap(lhs), euint32.unwrap(rhs), FunctionId.max));
    }

    /// @notice Perform the maximum operation on two parameters of type euint64
    /// @dev Verifies that inputs are initialized, performs encrypted maximum comparison
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return result of type euint64 containing the maximum value
    function max(euint64 lhs, euint64 rhs) internal returns (euint64) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint64(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint64(0);
        }

        return euint64.wrap(Impl.mathOp(Utils.EUINT64_TFHE, euint64.unwrap(lhs), euint64.unwrap(rhs), FunctionId.max));
    }

    /// @notice Perform the maximum operation on two parameters of type euint128
    /// @dev Verifies that inputs are initialized, performs encrypted maximum comparison
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return result of type euint128 containing the maximum value
    function max(euint128 lhs, euint128 rhs) internal returns (euint128) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint128(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint128(0);
        }

        return euint128.wrap(Impl.mathOp(Utils.EUINT128_TFHE, euint128.unwrap(lhs), euint128.unwrap(rhs), FunctionId.max));
    }

    /// @notice Perform the maximum operation on two parameters of type euint256
    /// @dev Verifies that inputs are initialized, performs encrypted maximum comparison
    /// @param lhs input of type euint256
    /// @param rhs second input of type euint256
    /// @return result of type euint256 containing the maximum value
    function max(euint256 lhs, euint256 rhs) internal returns (euint256) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint256(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint256(0);
        }

        return euint256.wrap(Impl.mathOp(Utils.EUINT256_TFHE, euint256.unwrap(lhs), euint256.unwrap(rhs), FunctionId.max));
    }

    /// @notice Perform the shift left operation on two parameters of type euint8
    /// @dev Verifies that inputs are initialized, performs encrypted left shift
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return result of type euint8 containing the left shift result
    function shl(euint8 lhs, euint8 rhs) internal returns (euint8) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint8(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint8(0);
        }

        return euint8.wrap(Impl.mathOp(Utils.EUINT8_TFHE, euint8.unwrap(lhs), euint8.unwrap(rhs), FunctionId.shl));
    }

    /// @notice Perform the shift left operation on two parameters of type euint16
    /// @dev Verifies that inputs are initialized, performs encrypted left shift
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return result of type euint16 containing the left shift result
    function shl(euint16 lhs, euint16 rhs) internal returns (euint16) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint16(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint16(0);
        }

        return euint16.wrap(Impl.mathOp(Utils.EUINT16_TFHE, euint16.unwrap(lhs), euint16.unwrap(rhs), FunctionId.shl));
    }

    /// @notice Perform the shift left operation on two parameters of type euint32
    /// @dev Verifies that inputs are initialized, performs encrypted left shift
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return result of type euint32 containing the left shift result
    function shl(euint32 lhs, euint32 rhs) internal returns (euint32) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint32(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint32(0);
        }

        return euint32.wrap(Impl.mathOp(Utils.EUINT32_TFHE, euint32.unwrap(lhs), euint32.unwrap(rhs), FunctionId.shl));
    }

    /// @notice Perform the shift left operation on two parameters of type euint64
    /// @dev Verifies that inputs are initialized, performs encrypted left shift
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return result of type euint64 containing the left shift result
    function shl(euint64 lhs, euint64 rhs) internal returns (euint64) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint64(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint64(0);
        }

        return euint64.wrap(Impl.mathOp(Utils.EUINT64_TFHE, euint64.unwrap(lhs), euint64.unwrap(rhs), FunctionId.shl));
    }

    /// @notice Perform the shift left operation on two parameters of type euint128
    /// @dev Verifies that inputs are initialized, performs encrypted left shift
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return result of type euint128 containing the left shift result
    function shl(euint128 lhs, euint128 rhs) internal returns (euint128) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint128(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint128(0);
        }

        return euint128.wrap(Impl.mathOp(Utils.EUINT128_TFHE, euint128.unwrap(lhs), euint128.unwrap(rhs), FunctionId.shl));
    }

    /// @notice Perform the shift left operation on two parameters of type euint256
    /// @dev Verifies that inputs are initialized, performs encrypted left shift
    /// @param lhs input of type euint256
    /// @param rhs second input of type euint256
    /// @return result of type euint256 containing the left shift result
    function shl(euint256 lhs, euint256 rhs) internal returns (euint256) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint256(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint256(0);
        }

        return euint256.wrap(Impl.mathOp(Utils.EUINT256_TFHE, euint256.unwrap(lhs), euint256.unwrap(rhs), FunctionId.shl));
    }

    /// @notice Perform the shift right operation on two parameters of type euint8
    /// @dev Verifies that inputs are initialized, performs encrypted right shift
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return result of type euint8 containing the right shift result
    function shr(euint8 lhs, euint8 rhs) internal returns (euint8) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint8(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint8(0);
        }

        return euint8.wrap(Impl.mathOp(Utils.EUINT8_TFHE, euint8.unwrap(lhs), euint8.unwrap(rhs), FunctionId.shr));
    }

    /// @notice Perform the shift right operation on two parameters of type euint16
    /// @dev Verifies that inputs are initialized, performs encrypted right shift
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return result of type euint16 containing the right shift result
    function shr(euint16 lhs, euint16 rhs) internal returns (euint16) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint16(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint16(0);
        }

        return euint16.wrap(Impl.mathOp(Utils.EUINT16_TFHE, euint16.unwrap(lhs), euint16.unwrap(rhs), FunctionId.shr));
    }

    /// @notice Perform the shift right operation on two parameters of type euint32
    /// @dev Verifies that inputs are initialized, performs encrypted right shift
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return result of type euint32 containing the right shift result
    function shr(euint32 lhs, euint32 rhs) internal returns (euint32) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint32(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint32(0);
        }

        return euint32.wrap(Impl.mathOp(Utils.EUINT32_TFHE, euint32.unwrap(lhs), euint32.unwrap(rhs), FunctionId.shr));
    }

    /// @notice Perform the shift right operation on two parameters of type euint64
    /// @dev Verifies that inputs are initialized, performs encrypted right shift
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return result of type euint64 containing the right shift result
    function shr(euint64 lhs, euint64 rhs) internal returns (euint64) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint64(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint64(0);
        }

        return euint64.wrap(Impl.mathOp(Utils.EUINT64_TFHE, euint64.unwrap(lhs), euint64.unwrap(rhs), FunctionId.shr));
    }

    /// @notice Perform the shift right operation on two parameters of type euint128
    /// @dev Verifies that inputs are initialized, performs encrypted right shift
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return result of type euint128 containing the right shift result
    function shr(euint128 lhs, euint128 rhs) internal returns (euint128) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint128(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint128(0);
        }

        return euint128.wrap(Impl.mathOp(Utils.EUINT128_TFHE, euint128.unwrap(lhs), euint128.unwrap(rhs), FunctionId.shr));
    }

    /// @notice Perform the shift right operation on two parameters of type euint256
    /// @dev Verifies that inputs are initialized, performs encrypted right shift
    /// @param lhs input of type euint256
    /// @param rhs second input of type euint256
    /// @return result of type euint256 containing the right shift result
    function shr(euint256 lhs, euint256 rhs) internal returns (euint256) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint256(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint256(0);
        }

        return euint256.wrap(Impl.mathOp(Utils.EUINT256_TFHE, euint256.unwrap(lhs), euint256.unwrap(rhs), FunctionId.shr));
    }

    /// @notice Perform the rol operation on two parameters of type euint8
    /// @dev Verifies that inputs are initialized, performs encrypted left rotation
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return result of type euint8 containing the left rotation result
    function rol(euint8 lhs, euint8 rhs) internal returns (euint8) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint8(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint8(0);
        }

        return euint8.wrap(Impl.mathOp(Utils.EUINT8_TFHE, euint8.unwrap(lhs), euint8.unwrap(rhs), FunctionId.rol));
    }

    /// @notice Perform the rotate left operation on two parameters of type euint16
    /// @dev Verifies that inputs are initialized, performs encrypted left rotation
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return result of type euint16 containing the left rotation result
    function rol(euint16 lhs, euint16 rhs) internal returns (euint16) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint16(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint16(0);
        }

        return euint16.wrap(Impl.mathOp(Utils.EUINT16_TFHE, euint16.unwrap(lhs), euint16.unwrap(rhs), FunctionId.rol));
    }

    /// @notice Perform the rotate left operation on two parameters of type euint32
    /// @dev Verifies that inputs are initialized, performs encrypted left rotation
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return result of type euint32 containing the left rotation result
    function rol(euint32 lhs, euint32 rhs) internal returns (euint32) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint32(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint32(0);
        }

        return euint32.wrap(Impl.mathOp(Utils.EUINT32_TFHE, euint32.unwrap(lhs), euint32.unwrap(rhs), FunctionId.rol));
    }

    /// @notice Perform the rotate left operation on two parameters of type euint64
    /// @dev Verifies that inputs are initialized, performs encrypted left rotation
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return result of type euint64 containing the left rotation result
    function rol(euint64 lhs, euint64 rhs) internal returns (euint64) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint64(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint64(0);
        }

        return euint64.wrap(Impl.mathOp(Utils.EUINT64_TFHE, euint64.unwrap(lhs), euint64.unwrap(rhs), FunctionId.rol));
    }

    /// @notice Perform the rotate left operation on two parameters of type euint128
    /// @dev Verifies that inputs are initialized, performs encrypted left rotation
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return result of type euint128 containing the left rotation result
    function rol(euint128 lhs, euint128 rhs) internal returns (euint128) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint128(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint128(0);
        }

        return euint128.wrap(Impl.mathOp(Utils.EUINT128_TFHE, euint128.unwrap(lhs), euint128.unwrap(rhs), FunctionId.rol));
    }

    /// @notice Perform the rotate left operation on two parameters of type euint256
    /// @dev Verifies that inputs are initialized, performs encrypted left rotation
    /// @param lhs input of type euint256
    /// @param rhs second input of type euint256
    /// @return result of type euint256 containing the left rotation result
    function rol(euint256 lhs, euint256 rhs) internal returns (euint256) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint256(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint256(0);
        }

        return euint256.wrap(Impl.mathOp(Utils.EUINT256_TFHE, euint256.unwrap(lhs), euint256.unwrap(rhs), FunctionId.rol));
    }

    /// @notice Perform the rotate right operation on two parameters of type euint8
    /// @dev Verifies that inputs are initialized, performs encrypted right rotation
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return result of type euint8 containing the right rotation result
    function ror(euint8 lhs, euint8 rhs) internal returns (euint8) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint8(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint8(0);
        }

        return euint8.wrap(Impl.mathOp(Utils.EUINT8_TFHE, euint8.unwrap(lhs), euint8.unwrap(rhs), FunctionId.ror));
    }

    /// @notice Perform the rotate right operation on two parameters of type euint16
    /// @dev Verifies that inputs are initialized, performs encrypted right rotation
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return result of type euint16 containing the right rotation result
    function ror(euint16 lhs, euint16 rhs) internal returns (euint16) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint16(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint16(0);
        }

        return euint16.wrap(Impl.mathOp(Utils.EUINT16_TFHE, euint16.unwrap(lhs), euint16.unwrap(rhs), FunctionId.ror));
    }

    /// @notice Perform the rotate right operation on two parameters of type euint32
    /// @dev Verifies that inputs are initialized, performs encrypted right rotation
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return result of type euint32 containing the right rotation result
    function ror(euint32 lhs, euint32 rhs) internal returns (euint32) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint32(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint32(0);
        }

        return euint32.wrap(Impl.mathOp(Utils.EUINT32_TFHE, euint32.unwrap(lhs), euint32.unwrap(rhs), FunctionId.ror));
    }

    /// @notice Perform the rotate right operation on two parameters of type euint64
    /// @dev Verifies that inputs are initialized, performs encrypted right rotation
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return result of type euint64 containing the right rotation result
    function ror(euint64 lhs, euint64 rhs) internal returns (euint64) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint64(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint64(0);
        }

        return euint64.wrap(Impl.mathOp(Utils.EUINT64_TFHE, euint64.unwrap(lhs), euint64.unwrap(rhs), FunctionId.ror));
    }

    /// @notice Perform the rotate right operation on two parameters of type euint128
    /// @dev Verifies that inputs are initialized, performs encrypted right rotation
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return result of type euint128 containing the right rotation result
    function ror(euint128 lhs, euint128 rhs) internal returns (euint128) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint128(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint128(0);
        }

        return euint128.wrap(Impl.mathOp(Utils.EUINT128_TFHE, euint128.unwrap(lhs), euint128.unwrap(rhs), FunctionId.ror));
    }

    /// @notice Perform the rotate right operation on two parameters of type euint256
    /// @dev Verifies that inputs are initialized, performs encrypted right rotation
    /// @param lhs input of type euint256
    /// @param rhs second input of type euint256
    /// @return result of type euint256 containing the right rotation result
    function ror(euint256 lhs, euint256 rhs) internal returns (euint256) {
        if (!Common.isInitialized(lhs)) {
            lhs = asEuint256(0);
        }
        if (!Common.isInitialized(rhs)) {
            rhs = asEuint256(0);
        }

        return euint256.wrap(Impl.mathOp(Utils.EUINT256_TFHE, euint256.unwrap(lhs), euint256.unwrap(rhs), FunctionId.ror));
    }

    /// @notice Performs the async decrypt operation on a ciphertext
    /// @dev The decrypted output should be asynchronously handled by the IAsyncFHEReceiver implementation
    /// @param input1 the input ciphertext
    function decrypt(ebool input1) internal {
        if (!Common.isInitialized(input1)) {
            input1 = asEbool(false);
        }

        ebool.wrap(Impl.decrypt(ebool.unwrap(input1)));
    }
    /// @notice Performs the async decrypt operation on a ciphertext
    /// @dev The decrypted output should be asynchronously handled by the IAsyncFHEReceiver implementation
    /// @param input1 the input ciphertext
    function decrypt(euint8 input1) internal {
        if (!Common.isInitialized(input1)) {
            input1 = asEuint8(0);
        }

        euint8.wrap(Impl.decrypt(euint8.unwrap(input1)));
    }
    /// @notice Performs the async decrypt operation on a ciphertext
    /// @dev The decrypted output should be asynchronously handled by the IAsyncFHEReceiver implementation
    /// @param input1 the input ciphertext
    function decrypt(euint16 input1) internal {
        if (!Common.isInitialized(input1)) {
            input1 = asEuint16(0);
        }

        euint16.wrap(Impl.decrypt(euint16.unwrap(input1)));
    }
    /// @notice Performs the async decrypt operation on a ciphertext
    /// @dev The decrypted output should be asynchronously handled by the IAsyncFHEReceiver implementation
    /// @param input1 the input ciphertext
    function decrypt(euint32 input1) internal {
        if (!Common.isInitialized(input1)) {
            input1 = asEuint32(0);
        }

        euint32.wrap(Impl.decrypt(euint32.unwrap(input1)));
    }
    /// @notice Performs the async decrypt operation on a ciphertext
    /// @dev The decrypted output should be asynchronously handled by the IAsyncFHEReceiver implementation
    /// @param input1 the input ciphertext
    function decrypt(euint64 input1) internal {
        if (!Common.isInitialized(input1)) {
            input1 = asEuint64(0);
        }

        euint64.wrap(Impl.decrypt(euint64.unwrap(input1)));
    }
    /// @notice Performs the async decrypt operation on a ciphertext
    /// @dev The decrypted output should be asynchronously handled by the IAsyncFHEReceiver implementation
    /// @param input1 the input ciphertext
    function decrypt(euint128 input1) internal {
        if (!Common.isInitialized(input1)) {
            input1 = asEuint128(0);
        }

        euint128.wrap(Impl.decrypt(euint128.unwrap(input1)));
    }
    /// @notice Performs the async decrypt operation on a ciphertext
    /// @dev The decrypted output should be asynchronously handled by the IAsyncFHEReceiver implementation
    /// @param input1 the input ciphertext
    function decrypt(euint256 input1) internal {
        if (!Common.isInitialized(input1)) {
            input1 = asEuint256(0);
        }

        euint256.wrap(Impl.decrypt(euint256.unwrap(input1)));
    }
    /// @notice Performs the async decrypt operation on a ciphertext
    /// @dev The decrypted output should be asynchronously handled by the IAsyncFHEReceiver implementation
    /// @param input1 the input ciphertext
    function decrypt(eaddress input1) internal {
        if (!Common.isInitialized(input1)) {
            input1 = asEaddress(address(0));
        }

        Impl.decrypt(eaddress.unwrap(input1));
    }

    /// @notice Gets the decrypted value from a previously decrypted ebool ciphertext
    /// @dev This function will revert if the ciphertext is not yet decrypted. Use getDecryptResultSafe for a non-reverting version.
    /// @param input1 The ebool ciphertext to get the decrypted value from
    /// @return The decrypted boolean value
    function getDecryptResult(ebool input1) internal view returns (bool) {
        uint256 result = Impl.getDecryptResult(ebool.unwrap(input1));
        return result != 0;
    }

    /// @notice Gets the decrypted value from a previously decrypted euint8 ciphertext
    /// @dev This function will revert if the ciphertext is not yet decrypted. Use getDecryptResultSafe for a non-reverting version.
    /// @param input1 The euint8 ciphertext to get the decrypted value from
    /// @return The decrypted uint8 value
    function getDecryptResult(euint8 input1) internal view returns (uint8) {
        return uint8(Impl.getDecryptResult(euint8.unwrap(input1)));
    }

    /// @notice Gets the decrypted value from a previously decrypted euint16 ciphertext
    /// @dev This function will revert if the ciphertext is not yet decrypted. Use getDecryptResultSafe for a non-reverting version.
    /// @param input1 The euint16 ciphertext to get the decrypted value from
    /// @return The decrypted uint16 value
    function getDecryptResult(euint16 input1) internal view returns (uint16) {
        return uint16(Impl.getDecryptResult(euint16.unwrap(input1)));
    }

    /// @notice Gets the decrypted value from a previously decrypted euint32 ciphertext
    /// @dev This function will revert if the ciphertext is not yet decrypted. Use getDecryptResultSafe for a non-reverting version.
    /// @param input1 The euint32 ciphertext to get the decrypted value from
    /// @return The decrypted uint32 value
    function getDecryptResult(euint32 input1) internal view returns (uint32) {
        return uint32(Impl.getDecryptResult(euint32.unwrap(input1)));
    }

    /// @notice Gets the decrypted value from a previously decrypted euint64 ciphertext
    /// @dev This function will revert if the ciphertext is not yet decrypted. Use getDecryptResultSafe for a non-reverting version.
    /// @param input1 The euint64 ciphertext to get the decrypted value from
    /// @return The decrypted uint64 value
    function getDecryptResult(euint64 input1) internal view returns (uint64) {
        return uint64(Impl.getDecryptResult(euint64.unwrap(input1)));
    }

    /// @notice Gets the decrypted value from a previously decrypted euint128 ciphertext
    /// @dev This function will revert if the ciphertext is not yet decrypted. Use getDecryptResultSafe for a non-reverting version.
    /// @param input1 The euint128 ciphertext to get the decrypted value from
    /// @return The decrypted uint128 value
    function getDecryptResult(euint128 input1) internal view returns (uint128) {
        return uint128(Impl.getDecryptResult(euint128.unwrap(input1)));
    }

    /// @notice Gets the decrypted value from a previously decrypted euint256 ciphertext
    /// @dev This function will revert if the ciphertext is not yet decrypted. Use getDecryptResultSafe for a non-reverting version.
    /// @param input1 The euint256 ciphertext to get the decrypted value from
    /// @return The decrypted uint256 value
    function getDecryptResult(euint256 input1) internal view returns (uint256) {
        return uint256(Impl.getDecryptResult(euint256.unwrap(input1)));
    }

    /// @notice Gets the decrypted value from a previously decrypted eaddress ciphertext
    /// @dev This function will revert if the ciphertext is not yet decrypted. Use getDecryptResultSafe for a non-reverting version.
    /// @param input1 The eaddress ciphertext to get the decrypted value from
    /// @return The decrypted address value
    function getDecryptResult(eaddress input1) internal view returns (address) {
        return address(uint160(Impl.getDecryptResult(eaddress.unwrap(input1))));
    }

    /// @notice Gets the decrypted value from a previously decrypted raw ciphertext
    /// @dev This function will revert if the ciphertext is not yet decrypted. Use getDecryptResultSafe for a non-reverting version.
    /// @param input1 The raw ciphertext to get the decrypted value from
    /// @return The decrypted uint256 value
    function getDecryptResult(uint256 input1) internal view returns (uint256) {
        return Impl.getDecryptResult(input1);
    }

    /// @notice Safely gets the decrypted value from an ebool ciphertext
    /// @dev Returns the decrypted value and a flag indicating whether the decryption has finished
    /// @param input1 The ebool ciphertext to get the decrypted value from
    /// @return result The decrypted boolean value
    /// @return decrypted Flag indicating if the value was successfully decrypted
    function getDecryptResultSafe(ebool input1) internal view returns (bool result, bool decrypted) {
        (uint256 _result, bool _decrypted) = Impl.getDecryptResultSafe(ebool.unwrap(input1));
        return (_result != 0, _decrypted);
    }

    /// @notice Safely gets the decrypted value from a euint8 ciphertext
    /// @dev Returns the decrypted value and a flag indicating whether the decryption has finished
    /// @param input1 The euint8 ciphertext to get the decrypted value from
    /// @return result The decrypted uint8 value
    /// @return decrypted Flag indicating if the value was successfully decrypted
    function getDecryptResultSafe(euint8 input1) internal view returns (uint8 result, bool decrypted) {
        (uint256 _result, bool _decrypted) = Impl.getDecryptResultSafe(euint8.unwrap(input1));
        return (uint8(_result), _decrypted);
    }

    /// @notice Safely gets the decrypted value from a euint16 ciphertext
    /// @dev Returns the decrypted value and a flag indicating whether the decryption has finished
    /// @param input1 The euint16 ciphertext to get the decrypted value from
    /// @return result The decrypted uint16 value
    /// @return decrypted Flag indicating if the value was successfully decrypted
    function getDecryptResultSafe(euint16 input1) internal view returns (uint16 result, bool decrypted) {
        (uint256 _result, bool _decrypted) = Impl.getDecryptResultSafe(euint16.unwrap(input1));
        return (uint16(_result), _decrypted);
    }

    /// @notice Safely gets the decrypted value from a euint32 ciphertext
    /// @dev Returns the decrypted value and a flag indicating whether the decryption has finished
    /// @param input1 The euint32 ciphertext to get the decrypted value from
    /// @return result The decrypted uint32 value
    /// @return decrypted Flag indicating if the value was successfully decrypted
    function getDecryptResultSafe(euint32 input1) internal view returns (uint32 result, bool decrypted) {
        (uint256 _result, bool _decrypted) = Impl.getDecryptResultSafe(euint32.unwrap(input1));
        return (uint32(_result), _decrypted);
    }

    /// @notice Safely gets the decrypted value from a euint64 ciphertext
    /// @dev Returns the decrypted value and a flag indicating whether the decryption has finished
    /// @param input1 The euint64 ciphertext to get the decrypted value from
    /// @return result The decrypted uint64 value
    /// @return decrypted Flag indicating if the value was successfully decrypted
    function getDecryptResultSafe(euint64 input1) internal view returns (uint64 result, bool decrypted) {
        (uint256 _result, bool _decrypted) = Impl.getDecryptResultSafe(euint64.unwrap(input1));
        return (uint64(_result), _decrypted);
    }

    /// @notice Safely gets the decrypted value from a euint128 ciphertext
    /// @dev Returns the decrypted value and a flag indicating whether the decryption has finished
    /// @param input1 The euint128 ciphertext to get the decrypted value from
    /// @return result The decrypted uint128 value
    /// @return decrypted Flag indicating if the value was successfully decrypted
    function getDecryptResultSafe(euint128 input1) internal view returns (uint128 result, bool decrypted) {
        (uint256 _result, bool _decrypted) = Impl.getDecryptResultSafe(euint128.unwrap(input1));
        return (uint128(_result), _decrypted);
    }

    /// @notice Safely gets the decrypted value from a euint256 ciphertext
    /// @dev Returns the decrypted value and a flag indicating whether the decryption has finished
    /// @param input1 The euint256 ciphertext to get the decrypted value from
    /// @return result The decrypted uint256 value
    /// @return decrypted Flag indicating if the value was successfully decrypted
    function getDecryptResultSafe(euint256 input1) internal view returns (uint256 result, bool decrypted) {
        (uint256 _result, bool _decrypted) = Impl.getDecryptResultSafe(euint256.unwrap(input1));
        return (uint256(_result), _decrypted);
    }

    /// @notice Safely gets the decrypted value from an eaddress ciphertext
    /// @dev Returns the decrypted value and a flag indicating whether the decryption has finished
    /// @param input1 The eaddress ciphertext to get the decrypted value from
    /// @return result The decrypted address value
    /// @return decrypted Flag indicating if the value was successfully decrypted
    function getDecryptResultSafe(eaddress input1) internal view returns (address result, bool decrypted) {
        (uint256 _result, bool _decrypted) = Impl.getDecryptResultSafe(eaddress.unwrap(input1));
        return (address(uint160(_result)), _decrypted);
    }

    /// @notice Safely gets the decrypted value from a raw ciphertext
    /// @dev Returns the decrypted value and a flag indicating whether the decryption has finished
    /// @param input1 The raw ciphertext to get the decrypted value from
    /// @return result The decrypted uint256 value
    /// @return decrypted Flag indicating if the value was successfully decrypted
    function getDecryptResultSafe(uint256 input1) internal view returns (uint256 result, bool decrypted) {
        (uint256 _result, bool _decrypted) = Impl.getDecryptResultSafe(input1);
        return (_result, _decrypted);
    }

    /// @notice Performs a multiplexer operation between two ebool values based on a selector
    /// @dev If input1 is true, returns input2, otherwise returns input3. All inputs are initialized to defaults if not set.
    /// @param input1 The selector of type ebool
    /// @param input2 First choice of type ebool
    /// @param input3 Second choice of type ebool
    /// @return result of type ebool containing the selected value
    function select(ebool input1, ebool input2, ebool input3) internal returns (ebool) {
        if (!Common.isInitialized(input1)) {
            input1 = asEbool(false);
        }
        if (!Common.isInitialized(input2)) {
            input2 = asEbool(false);
        }
        if (!Common.isInitialized(input3)) {
            input3 = asEbool(false);
        }

        return ebool.wrap(Impl.select(Utils.EBOOL_TFHE, input1, ebool.unwrap(input2), ebool.unwrap(input3)));
    }

    /// @notice Performs a multiplexer operation between two euint8 values based on a selector
    /// @dev If input1 is true, returns input2, otherwise returns input3. All inputs are initialized to defaults if not set.
    /// @param input1 The selector of type ebool
    /// @param input2 First choice of type euint8
    /// @param input3 Second choice of type euint8
    /// @return result of type euint8 containing the selected value
    function select(ebool input1, euint8 input2, euint8 input3) internal returns (euint8) {
        if (!Common.isInitialized(input1)) {
            input1 = asEbool(false);
        }
        if (!Common.isInitialized(input2)) {
            input2 = asEuint8(0);
        }
        if (!Common.isInitialized(input3)) {
            input3 = asEuint8(0);
        }

        return euint8.wrap(Impl.select(Utils.EUINT8_TFHE, input1, euint8.unwrap(input2), euint8.unwrap(input3)));
    }

    /// @notice Performs a multiplexer operation between two euint16 values based on a selector
    /// @dev If input1 is true, returns input2, otherwise returns input3. All inputs are initialized to defaults if not set.
    /// @param input1 The selector of type ebool
    /// @param input2 First choice of type euint16
    /// @param input3 Second choice of type euint16
    /// @return result of type euint16 containing the selected value
    function select(ebool input1, euint16 input2, euint16 input3) internal returns (euint16) {
        if (!Common.isInitialized(input1)) {
            input1 = asEbool(false);
        }
        if (!Common.isInitialized(input2)) {
            input2 = asEuint16(0);
        }
        if (!Common.isInitialized(input3)) {
            input3 = asEuint16(0);
        }

        return euint16.wrap(Impl.select(Utils.EUINT16_TFHE, input1, euint16.unwrap(input2), euint16.unwrap(input3)));
    }

    /// @notice Performs a multiplexer operation between two euint32 values based on a selector
    /// @dev If input1 is true, returns input2, otherwise returns input3. All inputs are initialized to defaults if not set.
    /// @param input1 The selector of type ebool
    /// @param input2 First choice of type euint32
    /// @param input3 Second choice of type euint32
    /// @return result of type euint32 containing the selected value
    function select(ebool input1, euint32 input2, euint32 input3) internal returns (euint32) {
        if (!Common.isInitialized(input1)) {
            input1 = asEbool(false);
        }
        if (!Common.isInitialized(input2)) {
            input2 = asEuint32(0);
        }
        if (!Common.isInitialized(input3)) {
            input3 = asEuint32(0);
        }

        return euint32.wrap(Impl.select(Utils.EUINT32_TFHE, input1, euint32.unwrap(input2), euint32.unwrap(input3)));
    }

    /// @notice Performs a multiplexer operation between two euint64 values based on a selector
    /// @dev If input1 is true, returns input2, otherwise returns input3. All inputs are initialized to defaults if not set.
    /// @param input1 The selector of type ebool
    /// @param input2 First choice of type euint64
    /// @param input3 Second choice of type euint64
    /// @return result of type euint64 containing the selected value
    function select(ebool input1, euint64 input2, euint64 input3) internal returns (euint64) {
        if (!Common.isInitialized(input1)) {
            input1 = asEbool(false);
        }
        if (!Common.isInitialized(input2)) {
            input2 = asEuint64(0);
        }
        if (!Common.isInitialized(input3)) {
            input3 = asEuint64(0);
        }

        return euint64.wrap(Impl.select(Utils.EUINT64_TFHE, input1, euint64.unwrap(input2), euint64.unwrap(input3)));
    }

    /// @notice Performs a multiplexer operation between two euint128 values based on a selector
    /// @dev If input1 is true, returns input2, otherwise returns input3. All inputs are initialized to defaults if not set.
    /// @param input1 The selector of type ebool
    /// @param input2 First choice of type euint128
    /// @param input3 Second choice of type euint128
    /// @return result of type euint128 containing the selected value
    function select(ebool input1, euint128 input2, euint128 input3) internal returns (euint128) {
        if (!Common.isInitialized(input1)) {
            input1 = asEbool(false);
        }
        if (!Common.isInitialized(input2)) {
            input2 = asEuint128(0);
        }
        if (!Common.isInitialized(input3)) {
            input3 = asEuint128(0);
        }

        return euint128.wrap(Impl.select(Utils.EUINT128_TFHE, input1, euint128.unwrap(input2), euint128.unwrap(input3)));
    }

    /// @notice Performs a multiplexer operation between two euint256 values based on a selector
    /// @dev If input1 is true, returns input2, otherwise returns input3. All inputs are initialized to defaults if not set.
    /// @param input1 The selector of type ebool
    /// @param input2 First choice of type euint256
    /// @param input3 Second choice of type euint256
    /// @return result of type euint256 containing the selected value
    function select(ebool input1, euint256 input2, euint256 input3) internal returns (euint256) {
        if (!Common.isInitialized(input1)) {
            input1 = asEbool(false);
        }
        if (!Common.isInitialized(input2)) {
            input2 = asEuint256(0);
        }
        if (!Common.isInitialized(input3)) {
            input3 = asEuint256(0);
        }

        return euint256.wrap(Impl.select(Utils.EUINT256_TFHE, input1, euint256.unwrap(input2), euint256.unwrap(input3)));
    }

    /// @notice Performs a multiplexer operation between two eaddress values based on a selector
    /// @dev If input1 is true, returns input2, otherwise returns input3. All inputs are initialized to defaults if not set.
    /// @param input1 The selector of type ebool
    /// @param input2 First choice of type eaddress
    /// @param input3 Second choice of type eaddress
    /// @return result of type eaddress containing the selected value
    function select(ebool input1, eaddress input2, eaddress input3) internal returns (eaddress) {
        if (!Common.isInitialized(input1)) {
            input1 = asEbool(false);
        }
        if (!Common.isInitialized(input2)) {
            input2 = asEaddress(address(0));
        }
        if (!Common.isInitialized(input3)) {
            input3 = asEaddress(address(0));
        }

        return eaddress.wrap(Impl.select(Utils.EADDRESS_TFHE, input1, eaddress.unwrap(input2), eaddress.unwrap(input3)));
    }

    /// @notice Performs the not operation on a ciphertext
    /// @dev Verifies that the input value matches a valid ciphertext.
    /// @param input1 the input ciphertext
    function not(ebool input1) internal returns (ebool) {
        if (!Common.isInitialized(input1)) {
            input1 = asEbool(false);
        }

        return ebool.wrap(Impl.not(Utils.EBOOL_TFHE, ebool.unwrap(input1)));
    }

    /// @notice Performs the not operation on a ciphertext
    /// @dev Verifies that the input value matches a valid ciphertext.
    /// @param input1 the input ciphertext
    function not(euint8 input1) internal returns (euint8) {
        if (!Common.isInitialized(input1)) {
            input1 = asEuint8(0);
        }

        return euint8.wrap(Impl.not(Utils.EUINT8_TFHE, euint8.unwrap(input1)));
    }
    /// @notice Performs the not operation on a ciphertext
    /// @dev Verifies that the input value matches a valid ciphertext.
    /// @param input1 the input ciphertext
    function not(euint16 input1) internal returns (euint16) {
        if (!Common.isInitialized(input1)) {
            input1 = asEuint16(0);
        }

        return euint16.wrap(Impl.not(Utils.EUINT16_TFHE, euint16.unwrap(input1)));
    }
    /// @notice Performs the not operation on a ciphertext
    /// @dev Verifies that the input value matches a valid ciphertext.
    /// @param input1 the input ciphertext
    function not(euint32 input1) internal returns (euint32) {
        if (!Common.isInitialized(input1)) {
            input1 = asEuint32(0);
        }

        return euint32.wrap(Impl.not(Utils.EUINT32_TFHE, euint32.unwrap(input1)));
    }

    /// @notice Performs the bitwise NOT operation on an encrypted 64-bit unsigned integer
    /// @dev Verifies that the input is initialized, defaulting to 0 if not.
    ///      The operation inverts all bits of the input value.
    /// @param input1 The input ciphertext to negate
    /// @return An euint64 containing the bitwise NOT of the input
    function not(euint64 input1) internal returns (euint64) {
        if (!Common.isInitialized(input1)) {
            input1 = asEuint64(0);
        }

        return euint64.wrap(Impl.not(Utils.EUINT64_TFHE, euint64.unwrap(input1)));
    }

    /// @notice Performs the bitwise NOT operation on an encrypted 128-bit unsigned integer
    /// @dev Verifies that the input is initialized, defaulting to 0 if not.
    ///      The operation inverts all bits of the input value.
    /// @param input1 The input ciphertext to negate
    /// @return An euint128 containing the bitwise NOT of the input
    function not(euint128 input1) internal returns (euint128) {
        if (!Common.isInitialized(input1)) {
            input1 = asEuint128(0);
        }

        return euint128.wrap(Impl.not(Utils.EUINT128_TFHE, euint128.unwrap(input1)));
    }

    /// @notice Performs the bitwise NOT operation on an encrypted 256-bit unsigned integer
    /// @dev Verifies that the input is initialized, defaulting to 0 if not.
    ///      The operation inverts all bits of the input value.
    /// @param input1 The input ciphertext to negate
    /// @return An euint256 containing the bitwise NOT of the input
    function not(euint256 input1) internal returns (euint256) {
        if (!Common.isInitialized(input1)) {
            input1 = asEuint256(0);
        }

        return euint256.wrap(Impl.not(Utils.EUINT256_TFHE, euint256.unwrap(input1)));
    }

    /// @notice Performs the square operation on an encrypted 8-bit unsigned integer
    /// @dev Verifies that the input is initialized, defaulting to 0 if not.
    ///      Note: The result may overflow if input * input exceeds 8 bits.
    /// @param input1 The input ciphertext to square
    /// @return An euint8 containing the square of the input
    function square(euint8 input1) internal returns (euint8) {
        if (!Common.isInitialized(input1)) {
            input1 = asEuint8(0);
        }

        return euint8.wrap(Impl.square(Utils.EUINT8_TFHE, euint8.unwrap(input1)));
    }

    /// @notice Performs the square operation on an encrypted 16-bit unsigned integer
    /// @dev Verifies that the input is initialized, defaulting to 0 if not.
    ///      Note: The result may overflow if input * input exceeds 16 bits.
    /// @param input1 The input ciphertext to square
    /// @return An euint16 containing the square of the input
    function square(euint16 input1) internal returns (euint16) {
        if (!Common.isInitialized(input1)) {
            input1 = asEuint16(0);
        }

        return euint16.wrap(Impl.square(Utils.EUINT16_TFHE, euint16.unwrap(input1)));
    }

    /// @notice Performs the square operation on an encrypted 32-bit unsigned integer
    /// @dev Verifies that the input is initialized, defaulting to 0 if not.
    ///      Note: The result may overflow if input * input exceeds 32 bits.
    /// @param input1 The input ciphertext to square
    /// @return An euint32 containing the square of the input
    function square(euint32 input1) internal returns (euint32) {
        if (!Common.isInitialized(input1)) {
            input1 = asEuint32(0);
        }

        return euint32.wrap(Impl.square(Utils.EUINT32_TFHE, euint32.unwrap(input1)));
    }

    /// @notice Performs the square operation on an encrypted 64-bit unsigned integer
    /// @dev Verifies that the input is initialized, defaulting to 0 if not.
    ///      Note: The result may overflow if input * input exceeds 64 bits.
    /// @param input1 The input ciphertext to square
    /// @return An euint64 containing the square of the input
    function square(euint64 input1) internal returns (euint64) {
        if (!Common.isInitialized(input1)) {
            input1 = asEuint64(0);
        }

        return euint64.wrap(Impl.square(Utils.EUINT64_TFHE, euint64.unwrap(input1)));
    }

    /// @notice Performs the square operation on an encrypted 128-bit unsigned integer
    /// @dev Verifies that the input is initialized, defaulting to 0 if not.
    ///      Note: The result may overflow if input * input exceeds 128 bits.
    /// @param input1 The input ciphertext to square
    /// @return An euint128 containing the square of the input
    function square(euint128 input1) internal returns (euint128) {
        if (!Common.isInitialized(input1)) {
            input1 = asEuint128(0);
        }

        return euint128.wrap(Impl.square(Utils.EUINT128_TFHE, euint128.unwrap(input1)));
    }

    /// @notice Performs the square operation on an encrypted 256-bit unsigned integer
    /// @dev Verifies that the input is initialized, defaulting to 0 if not.
    ///      Note: The result may overflow if input * input exceeds 256 bits.
    /// @param input1 The input ciphertext to square
    /// @return An euint256 containing the square of the input
    function square(euint256 input1) internal returns (euint256) {
        if (!Common.isInitialized(input1)) {
            input1 = asEuint256(0);
        }

        return euint256.wrap(Impl.square(Utils.EUINT256_TFHE, euint256.unwrap(input1)));
    }
    /// @notice Generates a random value of a euint8 type for provided securityZone
    /// @dev Generates a cryptographically secure random 8-bit unsigned integer in encrypted form.
    ///      The generated value is fully encrypted and cannot be predicted by any party.
    /// @param securityZone The security zone identifier to use for random value generation.
    /// @return A randomly generated encrypted 8-bit unsigned integer (euint8)
    function randomEuint8(int32 securityZone) internal returns (euint8) {
        return euint8.wrap(Impl.random(Utils.EUINT8_TFHE, 0, securityZone));
    }
    /// @notice Generates a random value of a euint8 type
    /// @dev Generates a cryptographically secure random 8-bit unsigned integer in encrypted form
    ///      using the default security zone (0). The generated value is fully encrypted and
    ///      cannot be predicted by any party.
    /// @return A randomly generated encrypted 8-bit unsigned integer (euint8)
    function randomEuint8() internal returns (euint8) {
        return randomEuint8(0);
    }
    /// @notice Generates a random value of a euint16 type for provided securityZone
    /// @dev Generates a cryptographically secure random 16-bit unsigned integer in encrypted form.
    ///      The generated value is fully encrypted and cannot be predicted by any party.
    /// @param securityZone The security zone identifier to use for random value generation.
    /// @return A randomly generated encrypted 16-bit unsigned integer (euint16)
    function randomEuint16(int32 securityZone) internal returns (euint16) {
        return euint16.wrap(Impl.random(Utils.EUINT16_TFHE, 0, securityZone));
    }
    /// @notice Generates a random value of a euint16 type
    /// @dev Generates a cryptographically secure random 16-bit unsigned integer in encrypted form
    ///      using the default security zone (0). The generated value is fully encrypted and
    ///      cannot be predicted by any party.
    /// @return A randomly generated encrypted 16-bit unsigned integer (euint16)
    function randomEuint16() internal returns (euint16) {
        return randomEuint16(0);
    }
    /// @notice Generates a random value of a euint32 type for provided securityZone
    /// @dev Generates a cryptographically secure random 32-bit unsigned integer in encrypted form.
    ///      The generated value is fully encrypted and cannot be predicted by any party.
    /// @param securityZone The security zone identifier to use for random value generation.
    /// @return A randomly generated encrypted 32-bit unsigned integer (euint32)
    function randomEuint32(int32 securityZone) internal returns (euint32) {
        return euint32.wrap(Impl.random(Utils.EUINT32_TFHE, 0, securityZone));
    }
    /// @notice Generates a random value of a euint32 type
    /// @dev Generates a cryptographically secure random 32-bit unsigned integer in encrypted form
    ///      using the default security zone (0). The generated value is fully encrypted and
    ///      cannot be predicted by any party.
    /// @return A randomly generated encrypted 32-bit unsigned integer (euint32)
    function randomEuint32() internal returns (euint32) {
        return randomEuint32(0);
    }
    /// @notice Generates a random value of a euint64 type for provided securityZone
    /// @dev Generates a cryptographically secure random 64-bit unsigned integer in encrypted form.
    ///      The generated value is fully encrypted and cannot be predicted by any party.
    /// @param securityZone The security zone identifier to use for random value generation.
    /// @return A randomly generated encrypted 64-bit unsigned integer (euint64)
    function randomEuint64(int32 securityZone) internal returns (euint64) {
        return euint64.wrap(Impl.random(Utils.EUINT64_TFHE, 0, securityZone));
    }
    /// @notice Generates a random value of a euint64 type
    /// @dev Generates a cryptographically secure random 64-bit unsigned integer in encrypted form
    ///      using the default security zone (0). The generated value is fully encrypted and
    ///      cannot be predicted by any party.
    /// @return A randomly generated encrypted 64-bit unsigned integer (euint64)
    function randomEuint64() internal returns (euint64) {
        return randomEuint64(0);
    }
    /// @notice Generates a random value of a euint128 type for provided securityZone
    /// @dev Generates a cryptographically secure random 128-bit unsigned integer in encrypted form.
    ///      The generated value is fully encrypted and cannot be predicted by any party.
    /// @param securityZone The security zone identifier to use for random value generation.
    /// @return A randomly generated encrypted 128-bit unsigned integer (euint128)
    function randomEuint128(int32 securityZone) internal returns (euint128) {
        return euint128.wrap(Impl.random(Utils.EUINT128_TFHE, 0, securityZone));
    }
    /// @notice Generates a random value of a euint128 type
    /// @dev Generates a cryptographically secure random 128-bit unsigned integer in encrypted form
    ///      using the default security zone (0). The generated value is fully encrypted and
    ///      cannot be predicted by any party.
    /// @return A randomly generated encrypted 128-bit unsigned integer (euint128)
    function randomEuint128() internal returns (euint128) {
        return randomEuint128(0);
    }
    /// @notice Generates a random value of a euint256 type for provided securityZone
    /// @dev Generates a cryptographically secure random 256-bit unsigned integer in encrypted form.
    ///      The generated value is fully encrypted and cannot be predicted by any party.
    /// @param securityZone The security zone identifier to use for random value generation.
    /// @return A randomly generated encrypted 256-bit unsigned integer (euint256)
    function randomEuint256(int32 securityZone) internal returns (euint256) {
        return euint256.wrap(Impl.random(Utils.EUINT256_TFHE, 0, securityZone));
    }
    /// @notice Generates a random value of a euint256 type
    /// @dev Generates a cryptographically secure random 256-bit unsigned integer in encrypted form
    ///      using the default security zone (0). The generated value is fully encrypted and
    ///      cannot be predicted by any party.
    /// @return A randomly generated encrypted 256-bit unsigned integer (euint256)
    function randomEuint256() internal returns (euint256) {
        return randomEuint256(0);
    }

    /// @notice Verifies and converts an inEbool input to an ebool encrypted type
    /// @dev Verifies the input signature and security parameters before converting to the encrypted type
    /// @param value The input value containing hash, type, security zone and signature
    /// @return An ebool containing the verified encrypted value
    function asEbool(InEbool memory value) internal returns (ebool) {
        uint8 expectedUtype = Utils.EBOOL_TFHE;
        if (value.utype != expectedUtype) {
            revert InvalidEncryptedInput(value.utype, expectedUtype);
        }

        return ebool.wrap(Impl.verifyInput(Utils.inputFromEbool(value)));
    }

    /// @notice Verifies and converts an InEuint8 input to an euint8 encrypted type
    /// @dev Verifies the input signature and security parameters before converting to the encrypted type
    /// @param value The input value containing hash, type, security zone and signature
    /// @return An euint8 containing the verified encrypted value
    function asEuint8(InEuint8 memory value) internal returns (euint8) {
        uint8 expectedUtype = Utils.EUINT8_TFHE;
        if (value.utype != expectedUtype) {
            revert InvalidEncryptedInput(value.utype, expectedUtype);
        }

        return euint8.wrap(Impl.verifyInput(Utils.inputFromEuint8(value)));
    }

    /// @notice Verifies and converts an InEuint16 input to an euint16 encrypted type
    /// @dev Verifies the input signature and security parameters before converting to the encrypted type
    /// @param value The input value containing hash, type, security zone and signature
    /// @return An euint16 containing the verified encrypted value
    function asEuint16(InEuint16 memory value) internal returns (euint16) {
        uint8 expectedUtype = Utils.EUINT16_TFHE;
        if (value.utype != expectedUtype) {
            revert InvalidEncryptedInput(value.utype, expectedUtype);
        }

        return euint16.wrap(Impl.verifyInput(Utils.inputFromEuint16(value)));
    }

    /// @notice Verifies and converts an InEuint32 input to an euint32 encrypted type
    /// @dev Verifies the input signature and security parameters before converting to the encrypted type
    /// @param value The input value containing hash, type, security zone and signature
    /// @return An euint32 containing the verified encrypted value
    function asEuint32(InEuint32 memory value) internal returns (euint32) {
        uint8 expectedUtype = Utils.EUINT32_TFHE;
        if (value.utype != expectedUtype) {
            revert InvalidEncryptedInput(value.utype, expectedUtype);
        }

        return euint32.wrap(Impl.verifyInput(Utils.inputFromEuint32(value)));
    }

    /// @notice Verifies and converts an InEuint64 input to an euint64 encrypted type
    /// @dev Verifies the input signature and security parameters before converting to the encrypted type
    /// @param value The input value containing hash, type, security zone and signature
    /// @return An euint64 containing the verified encrypted value
    function asEuint64(InEuint64 memory value) internal returns (euint64) {
        uint8 expectedUtype = Utils.EUINT64_TFHE;
        if (value.utype != expectedUtype) {
            revert InvalidEncryptedInput(value.utype, expectedUtype);
        }

        return euint64.wrap(Impl.verifyInput(Utils.inputFromEuint64(value)));
    }

    /// @notice Verifies and converts an InEuint128 input to an euint128 encrypted type
    /// @dev Verifies the input signature and security parameters before converting to the encrypted type
    /// @param value The input value containing hash, type, security zone and signature
    /// @return An euint128 containing the verified encrypted value
    function asEuint128(InEuint128 memory value) internal returns (euint128) {
        uint8 expectedUtype = Utils.EUINT128_TFHE;
        if (value.utype != expectedUtype) {
            revert InvalidEncryptedInput(value.utype, expectedUtype);
        }

        return euint128.wrap(Impl.verifyInput(Utils.inputFromEuint128(value)));
    }

    /// @notice Verifies and converts an InEuint256 input to an euint256 encrypted type
    /// @dev Verifies the input signature and security parameters before converting to the encrypted type
    /// @param value The input value containing hash, type, security zone and signature
    /// @return An euint256 containing the verified encrypted value
    function asEuint256(InEuint256 memory value) internal returns (euint256) {
        uint8 expectedUtype = Utils.EUINT256_TFHE;
        if (value.utype != expectedUtype) {
            revert InvalidEncryptedInput(value.utype, expectedUtype);
        }

        return euint256.wrap(Impl.verifyInput(Utils.inputFromEuint256(value)));
    }

    /// @notice Verifies and converts an InEaddress input to an eaddress encrypted type
    /// @dev Verifies the input signature and security parameters before converting to the encrypted type
    /// @param value The input value containing hash, type, security zone and signature
    /// @return An eaddress containing the verified encrypted value
    function asEaddress(InEaddress memory value) internal returns (eaddress) {
        uint8 expectedUtype = Utils.EADDRESS_TFHE;
        if (value.utype != expectedUtype) {
            revert InvalidEncryptedInput(value.utype, expectedUtype);
        }

        return eaddress.wrap(Impl.verifyInput(Utils.inputFromEaddress(value)));
    }

    // ********** TYPE CASTING ************* //
    /// @notice Converts a ebool to an euint8
    function asEuint8(ebool value) internal returns (euint8) {
        return euint8.wrap(Impl.cast(ebool.unwrap(value), Utils.EUINT8_TFHE));
    }
    /// @notice Converts a ebool to an euint16
    function asEuint16(ebool value) internal returns (euint16) {
        return euint16.wrap(Impl.cast(ebool.unwrap(value), Utils.EUINT16_TFHE));
    }
    /// @notice Converts a ebool to an euint32
    function asEuint32(ebool value) internal returns (euint32) {
        return euint32.wrap(Impl.cast(ebool.unwrap(value), Utils.EUINT32_TFHE));
    }
    /// @notice Converts a ebool to an euint64
    function asEuint64(ebool value) internal returns (euint64) {
        return euint64.wrap(Impl.cast(ebool.unwrap(value), Utils.EUINT64_TFHE));
    }
    /// @notice Converts a ebool to an euint128
    function asEuint128(ebool value) internal returns (euint128) {
        return euint128.wrap(Impl.cast(ebool.unwrap(value), Utils.EUINT128_TFHE));
    }
    /// @notice Converts a ebool to an euint256
    function asEuint256(ebool value) internal returns (euint256) {
        return euint256.wrap(Impl.cast(ebool.unwrap(value), Utils.EUINT256_TFHE));
    }

    /// @notice Converts a euint8 to an ebool
    function asEbool(euint8 value) internal returns (ebool) {
        return ne(value, asEuint8(0));
    }
    /// @notice Converts a euint8 to an euint16
    function asEuint16(euint8 value) internal returns (euint16) {
        return euint16.wrap(Impl.cast(euint8.unwrap(value), Utils.EUINT16_TFHE));
    }
    /// @notice Converts a euint8 to an euint32
    function asEuint32(euint8 value) internal returns (euint32) {
        return euint32.wrap(Impl.cast(euint8.unwrap(value), Utils.EUINT32_TFHE));
    }
    /// @notice Converts a euint8 to an euint64
    function asEuint64(euint8 value) internal returns (euint64) {
        return euint64.wrap(Impl.cast(euint8.unwrap(value), Utils.EUINT64_TFHE));
    }
    /// @notice Converts a euint8 to an euint128
    function asEuint128(euint8 value) internal returns (euint128) {
        return euint128.wrap(Impl.cast(euint8.unwrap(value), Utils.EUINT128_TFHE));
    }
    /// @notice Converts a euint8 to an euint256
    function asEuint256(euint8 value) internal returns (euint256) {
        return euint256.wrap(Impl.cast(euint8.unwrap(value), Utils.EUINT256_TFHE));
    }

    /// @notice Converts a euint16 to an ebool
    function asEbool(euint16 value) internal returns (ebool) {
        return ne(value, asEuint16(0));
    }
    /// @notice Converts a euint16 to an euint8
    function asEuint8(euint16 value) internal returns (euint8) {
        return euint8.wrap(Impl.cast(euint16.unwrap(value), Utils.EUINT8_TFHE));
    }
    /// @notice Converts a euint16 to an euint32
    function asEuint32(euint16 value) internal returns (euint32) {
        return euint32.wrap(Impl.cast(euint16.unwrap(value), Utils.EUINT32_TFHE));
    }
    /// @notice Converts a euint16 to an euint64
    function asEuint64(euint16 value) internal returns (euint64) {
        return euint64.wrap(Impl.cast(euint16.unwrap(value), Utils.EUINT64_TFHE));
    }
    /// @notice Converts a euint16 to an euint128
    function asEuint128(euint16 value) internal returns (euint128) {
        return euint128.wrap(Impl.cast(euint16.unwrap(value), Utils.EUINT128_TFHE));
    }
    /// @notice Converts a euint16 to an euint256
    function asEuint256(euint16 value) internal returns (euint256) {
        return euint256.wrap(Impl.cast(euint16.unwrap(value), Utils.EUINT256_TFHE));
    }

    /// @notice Converts a euint32 to an ebool
    function asEbool(euint32 value) internal returns (ebool) {
        return ne(value, asEuint32(0));
    }
    /// @notice Converts a euint32 to an euint8
    function asEuint8(euint32 value) internal returns (euint8) {
        return euint8.wrap(Impl.cast(euint32.unwrap(value), Utils.EUINT8_TFHE));
    }
    /// @notice Converts a euint32 to an euint16
    function asEuint16(euint32 value) internal returns (euint16) {
        return euint16.wrap(Impl.cast(euint32.unwrap(value), Utils.EUINT16_TFHE));
    }
    /// @notice Converts a euint32 to an euint64
    function asEuint64(euint32 value) internal returns (euint64) {
        return euint64.wrap(Impl.cast(euint32.unwrap(value), Utils.EUINT64_TFHE));
    }
    /// @notice Converts a euint32 to an euint128
    function asEuint128(euint32 value) internal returns (euint128) {
        return euint128.wrap(Impl.cast(euint32.unwrap(value), Utils.EUINT128_TFHE));
    }
    /// @notice Converts a euint32 to an euint256
    function asEuint256(euint32 value) internal returns (euint256) {
        return euint256.wrap(Impl.cast(euint32.unwrap(value), Utils.EUINT256_TFHE));
    }

    /// @notice Converts a euint64 to an ebool
    function asEbool(euint64 value) internal returns (ebool) {
        return ne(value, asEuint64(0));
    }
    /// @notice Converts a euint64 to an euint8
    function asEuint8(euint64 value) internal returns (euint8) {
        return euint8.wrap(Impl.cast(euint64.unwrap(value), Utils.EUINT8_TFHE));
    }
    /// @notice Converts a euint64 to an euint16
    function asEuint16(euint64 value) internal returns (euint16) {
        return euint16.wrap(Impl.cast(euint64.unwrap(value), Utils.EUINT16_TFHE));
    }
    /// @notice Converts a euint64 to an euint32
    function asEuint32(euint64 value) internal returns (euint32) {
        return euint32.wrap(Impl.cast(euint64.unwrap(value), Utils.EUINT32_TFHE));
    }
    /// @notice Converts a euint64 to an euint128
    function asEuint128(euint64 value) internal returns (euint128) {
        return euint128.wrap(Impl.cast(euint64.unwrap(value), Utils.EUINT128_TFHE));
    }
    /// @notice Converts a euint64 to an euint256
    function asEuint256(euint64 value) internal returns (euint256) {
        return euint256.wrap(Impl.cast(euint64.unwrap(value), Utils.EUINT256_TFHE));
    }

    /// @notice Converts a euint128 to an ebool
    function asEbool(euint128 value) internal returns (ebool) {
        return ne(value, asEuint128(0));
    }
    /// @notice Converts a euint128 to an euint8
    function asEuint8(euint128 value) internal returns (euint8) {
        return euint8.wrap(Impl.cast(euint128.unwrap(value), Utils.EUINT8_TFHE));
    }
    /// @notice Converts a euint128 to an euint16
    function asEuint16(euint128 value) internal returns (euint16) {
        return euint16.wrap(Impl.cast(euint128.unwrap(value), Utils.EUINT16_TFHE));
    }
    /// @notice Converts a euint128 to an euint32
    function asEuint32(euint128 value) internal returns (euint32) {
        return euint32.wrap(Impl.cast(euint128.unwrap(value), Utils.EUINT32_TFHE));
    }
    /// @notice Converts a euint128 to an euint64
    function asEuint64(euint128 value) internal returns (euint64) {
        return euint64.wrap(Impl.cast(euint128.unwrap(value), Utils.EUINT64_TFHE));
    }
    /// @notice Converts a euint128 to an euint256
    function asEuint256(euint128 value) internal returns (euint256) {
        return euint256.wrap(Impl.cast(euint128.unwrap(value), Utils.EUINT256_TFHE));
    }

    /// @notice Converts a euint256 to an ebool
    function asEbool(euint256 value) internal returns (ebool) {
        return ne(value, asEuint256(0));
    }
    /// @notice Converts a euint256 to an euint8
    function asEuint8(euint256 value) internal returns (euint8) {
        return euint8.wrap(Impl.cast(euint256.unwrap(value), Utils.EUINT8_TFHE));
    }
    /// @notice Converts a euint256 to an euint16
    function asEuint16(euint256 value) internal returns (euint16) {
        return euint16.wrap(Impl.cast(euint256.unwrap(value), Utils.EUINT16_TFHE));
    }
    /// @notice Converts a euint256 to an euint32
    function asEuint32(euint256 value) internal returns (euint32) {
        return euint32.wrap(Impl.cast(euint256.unwrap(value), Utils.EUINT32_TFHE));
    }
    /// @notice Converts a euint256 to an euint64
    function asEuint64(euint256 value) internal returns (euint64) {
        return euint64.wrap(Impl.cast(euint256.unwrap(value), Utils.EUINT64_TFHE));
    }
    /// @notice Converts a euint256 to an euint128
    function asEuint128(euint256 value) internal returns (euint128) {
        return euint128.wrap(Impl.cast(euint256.unwrap(value), Utils.EUINT128_TFHE));
    }
    /// @notice Converts a euint256 to an eaddress
    function asEaddress(euint256 value) internal returns (eaddress) {
        return eaddress.wrap(Impl.cast(euint256.unwrap(value), Utils.EADDRESS_TFHE));
    }

    /// @notice Converts a eaddress to an ebool
    function asEbool(eaddress value) internal returns (ebool) {
        return ne(value, asEaddress(address(0)));
    }
    /// @notice Converts a eaddress to an euint8
    function asEuint8(eaddress value) internal returns (euint8) {
        return euint8.wrap(Impl.cast(eaddress.unwrap(value), Utils.EUINT8_TFHE));
    }
    /// @notice Converts a eaddress to an euint16
    function asEuint16(eaddress value) internal returns (euint16) {
        return euint16.wrap(Impl.cast(eaddress.unwrap(value), Utils.EUINT16_TFHE));
    }
    /// @notice Converts a eaddress to an euint32
    function asEuint32(eaddress value) internal returns (euint32) {
        return euint32.wrap(Impl.cast(eaddress.unwrap(value), Utils.EUINT32_TFHE));
    }
    /// @notice Converts a eaddress to an euint64
    function asEuint64(eaddress value) internal returns (euint64) {
        return euint64.wrap(Impl.cast(eaddress.unwrap(value), Utils.EUINT64_TFHE));
    }
    /// @notice Converts a eaddress to an euint128
    function asEuint128(eaddress value) internal returns (euint128) {
        return euint128.wrap(Impl.cast(eaddress.unwrap(value), Utils.EUINT128_TFHE));
    }
    /// @notice Converts a eaddress to an euint256
    function asEuint256(eaddress value) internal returns (euint256) {
        return euint256.wrap(Impl.cast(eaddress.unwrap(value), Utils.EUINT256_TFHE));
    }
    /// @notice Converts a plaintext boolean value to a ciphertext ebool
    /// @dev Privacy: The input value is public, therefore the resulting ciphertext should be considered public until involved in an fhe operation
    /// @return A ciphertext representation of the input
    function asEbool(bool value) internal returns (ebool) {
        return asEbool(value, 0);
    }
    /// @notice Converts a plaintext boolean value to a ciphertext ebool, specifying security zone
    /// @dev Privacy: The input value is public, therefore the resulting ciphertext should be considered public until involved in an fhe operation
    /// @return A ciphertext representation of the input
    function asEbool(bool value, int32 securityZone) internal returns (ebool) {
        uint256 sVal = 0;
        if (value) {
            sVal = 1;
        }
        uint256 ct = Impl.trivialEncrypt(sVal, Utils.EBOOL_TFHE, securityZone);
        return ebool.wrap(ct);
    }
    /// @notice Converts a uint256 to an euint8
    /// @dev Privacy: The input value is public, therefore the resulting ciphertext should be considered public until involved in an fhe operation
    function asEuint8(uint256 value) internal returns (euint8) {
        return asEuint8(value, 0);
    }
    /// @notice Converts a uint256 to an euint8, specifying security zone
    /// @dev Privacy: The input value is public, therefore the resulting ciphertext should be considered public until involved in an fhe operation
    function asEuint8(uint256 value, int32 securityZone) internal returns (euint8) {
        uint256 ct = Impl.trivialEncrypt(value, Utils.EUINT8_TFHE, securityZone);
        return euint8.wrap(ct);
    }
    /// @notice Converts a uint256 to an euint16
    /// @dev Privacy: The input value is public, therefore the resulting ciphertext should be considered public until involved in an fhe operation
    function asEuint16(uint256 value) internal returns (euint16) {
        return asEuint16(value, 0);
    }
    /// @notice Converts a uint256 to an euint16, specifying security zone
    /// @dev Privacy: The input value is public, therefore the resulting ciphertext should be considered public until involved in an fhe operation
    function asEuint16(uint256 value, int32 securityZone) internal returns (euint16) {
        uint256 ct = Impl.trivialEncrypt(value, Utils.EUINT16_TFHE, securityZone);
        return euint16.wrap(ct);
    }
    /// @notice Converts a uint256 to an euint32
    /// @dev Privacy: The input value is public, therefore the resulting ciphertext should be considered public until involved in an fhe operation
    function asEuint32(uint256 value) internal returns (euint32) {
        return asEuint32(value, 0);
    }
    /// @notice Converts a uint256 to an euint32, specifying security zone
    /// @dev Privacy: The input value is public, therefore the resulting ciphertext should be considered public until involved in an fhe operation
    function asEuint32(uint256 value, int32 securityZone) internal returns (euint32) {
        uint256 ct = Impl.trivialEncrypt(value, Utils.EUINT32_TFHE, securityZone);
        return euint32.wrap(ct);
    }
    /// @notice Converts a uint256 to an euint64
    /// @dev Privacy: The input value is public, therefore the resulting ciphertext should be considered public until involved in an fhe operation
    function asEuint64(uint256 value) internal returns (euint64) {
        return asEuint64(value, 0);
    }
    /// @notice Converts a uint256 to an euint64, specifying security zone
    /// @dev Privacy: The input value is public, therefore the resulting ciphertext should be considered public until involved in an fhe operation
    function asEuint64(uint256 value, int32 securityZone) internal returns (euint64) {
        uint256 ct = Impl.trivialEncrypt(value, Utils.EUINT64_TFHE, securityZone);
        return euint64.wrap(ct);
    }
    /// @notice Converts a uint256 to an euint128
    /// @dev Privacy: The input value is public, therefore the resulting ciphertext should be considered public until involved in an fhe operation
    function asEuint128(uint256 value) internal returns (euint128) {
        return asEuint128(value, 0);
    }
    /// @notice Converts a uint256 to an euint128, specifying security zone
    /// @dev Privacy: The input value is public, therefore the resulting ciphertext should be considered public until involved in an fhe operation
    function asEuint128(uint256 value, int32 securityZone) internal returns (euint128) {
        uint256 ct = Impl.trivialEncrypt(value, Utils.EUINT128_TFHE, securityZone);
        return euint128.wrap(ct);
    }
    /// @notice Converts a uint256 to an euint256
    /// @dev Privacy: The input value is public, therefore the resulting ciphertext should be considered public until involved in an fhe operation
    function asEuint256(uint256 value) internal returns (euint256) {
        return asEuint256(value, 0);
    }
    /// @notice Converts a uint256 to an euint256, specifying security zone
    /// @dev Privacy: The input value is public, therefore the resulting ciphertext should be considered public until involved in an fhe operation
    function asEuint256(uint256 value, int32 securityZone) internal returns (euint256) {
        uint256 ct = Impl.trivialEncrypt(value, Utils.EUINT256_TFHE, securityZone);
        return euint256.wrap(ct);
    }
    /// @notice Converts a address to an eaddress
    /// @dev Privacy: The input value is public, therefore the resulting ciphertext should be considered public until involved in an fhe operation
    /// Allows for a better user experience when working with eaddresses
    function asEaddress(address value) internal returns (eaddress) {
        return asEaddress(value, 0);
    }
    /// @notice Converts a address to an eaddress, specifying security zone
    /// @dev Privacy: The input value is public, therefore the resulting ciphertext should be considered public until involved in an fhe operation
    /// Allows for a better user experience when working with eaddresses
    function asEaddress(address value, int32 securityZone) internal returns (eaddress) {
        uint256 ct = Impl.trivialEncrypt(uint256(uint160(value)), Utils.EADDRESS_TFHE, securityZone);
        return eaddress.wrap(ct);
    }

    /// @notice Grants permission to an account to operate on the encrypted boolean value
    /// @dev Allows the specified account to access the ciphertext
    /// @param ctHash The encrypted boolean value to grant access to
    /// @param account The address being granted permission
    function allow(ebool ctHash, address account) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allow(ebool.unwrap(ctHash), account);
    }

    /// @notice Grants permission to an account to operate on the encrypted 8-bit unsigned integer
    /// @dev Allows the specified account to access the ciphertext
    /// @param ctHash The encrypted uint8 value to grant access to
    /// @param account The address being granted permission
    function allow(euint8 ctHash, address account) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allow(euint8.unwrap(ctHash), account);
    }

    /// @notice Grants permission to an account to operate on the encrypted 16-bit unsigned integer
    /// @dev Allows the specified account to access the ciphertext
    /// @param ctHash The encrypted uint16 value to grant access to
    /// @param account The address being granted permission
    function allow(euint16 ctHash, address account) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allow(euint16.unwrap(ctHash), account);
    }

    /// @notice Grants permission to an account to operate on the encrypted 32-bit unsigned integer
    /// @dev Allows the specified account to access the ciphertext
    /// @param ctHash The encrypted uint32 value to grant access to
    /// @param account The address being granted permission
    function allow(euint32 ctHash, address account) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allow(euint32.unwrap(ctHash), account);
    }

    /// @notice Grants permission to an account to operate on the encrypted 64-bit unsigned integer
    /// @dev Allows the specified account to access the ciphertext
    /// @param ctHash The encrypted uint64 value to grant access to
    /// @param account The address being granted permission
    function allow(euint64 ctHash, address account) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allow(euint64.unwrap(ctHash), account);
    }

    /// @notice Grants permission to an account to operate on the encrypted 128-bit unsigned integer
    /// @dev Allows the specified account to access the ciphertext
    /// @param ctHash The encrypted uint128 value to grant access to
    /// @param account The address being granted permission
    function allow(euint128 ctHash, address account) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allow(euint128.unwrap(ctHash), account);
    }

    /// @notice Grants permission to an account to operate on the encrypted 256-bit unsigned integer
    /// @dev Allows the specified account to access the ciphertext
    /// @param ctHash The encrypted uint256 value to grant access to
    /// @param account The address being granted permission
    function allow(euint256 ctHash, address account) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allow(euint256.unwrap(ctHash), account);
    }

    /// @notice Grants permission to an account to operate on the encrypted address
    /// @dev Allows the specified account to access the ciphertext
    /// @param ctHash The encrypted address value to grant access to
    /// @param account The address being granted permission
    function allow(eaddress ctHash, address account) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allow(eaddress.unwrap(ctHash), account);
    }

    /// @notice Grants global permission to operate on the encrypted boolean value
    /// @dev Allows all accounts to access the ciphertext
    /// @param ctHash The encrypted boolean value to grant global access to
    function allowGlobal(ebool ctHash) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allowGlobal(ebool.unwrap(ctHash));
    }

    /// @notice Grants global permission to operate on the encrypted 8-bit unsigned integer
    /// @dev Allows all accounts to access the ciphertext
    /// @param ctHash The encrypted uint8 value to grant global access to
    function allowGlobal(euint8 ctHash) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allowGlobal(euint8.unwrap(ctHash));
    }

    /// @notice Grants global permission to operate on the encrypted 16-bit unsigned integer
    /// @dev Allows all accounts to access the ciphertext
    /// @param ctHash The encrypted uint16 value to grant global access to
    function allowGlobal(euint16 ctHash) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allowGlobal(euint16.unwrap(ctHash));
    }

    /// @notice Grants global permission to operate on the encrypted 32-bit unsigned integer
    /// @dev Allows all accounts to access the ciphertext
    /// @param ctHash The encrypted uint32 value to grant global access to
    function allowGlobal(euint32 ctHash) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allowGlobal(euint32.unwrap(ctHash));
    }

    /// @notice Grants global permission to operate on the encrypted 64-bit unsigned integer
    /// @dev Allows all accounts to access the ciphertext
    /// @param ctHash The encrypted uint64 value to grant global access to
    function allowGlobal(euint64 ctHash) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allowGlobal(euint64.unwrap(ctHash));
    }

    /// @notice Grants global permission to operate on the encrypted 128-bit unsigned integer
    /// @dev Allows all accounts to access the ciphertext
    /// @param ctHash The encrypted uint128 value to grant global access to
    function allowGlobal(euint128 ctHash) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allowGlobal(euint128.unwrap(ctHash));
    }

    /// @notice Grants global permission to operate on the encrypted 256-bit unsigned integer
    /// @dev Allows all accounts to access the ciphertext
    /// @param ctHash The encrypted uint256 value to grant global access to
    function allowGlobal(euint256 ctHash) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allowGlobal(euint256.unwrap(ctHash));
    }

    /// @notice Grants global permission to operate on the encrypted address
    /// @dev Allows all accounts to access the ciphertext
    /// @param ctHash The encrypted address value to grant global access to
    function allowGlobal(eaddress ctHash) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allowGlobal(eaddress.unwrap(ctHash));
    }

    /// @notice Checks if an account has permission to operate on the encrypted boolean value
    /// @dev Returns whether the specified account can access the ciphertext
    /// @param ctHash The encrypted boolean value to check access for
    /// @param account The address to check permissions for
    /// @return True if the account has permission, false otherwise
    function isAllowed(ebool ctHash, address account) internal returns (bool) {
        return ITaskManager(TASK_MANAGER_ADDRESS).isAllowed(ebool.unwrap(ctHash), account);
    }

    /// @notice Checks if an account has permission to operate on the encrypted 8-bit unsigned integer
    /// @dev Returns whether the specified account can access the ciphertext
    /// @param ctHash The encrypted uint8 value to check access for
    /// @param account The address to check permissions for
    /// @return True if the account has permission, false otherwise
    function isAllowed(euint8 ctHash, address account) internal returns (bool) {
        return ITaskManager(TASK_MANAGER_ADDRESS).isAllowed(euint8.unwrap(ctHash), account);
    }

    /// @notice Checks if an account has permission to operate on the encrypted 16-bit unsigned integer
    /// @dev Returns whether the specified account can access the ciphertext
    /// @param ctHash The encrypted uint16 value to check access for
    /// @param account The address to check permissions for
    /// @return True if the account has permission, false otherwise
    function isAllowed(euint16 ctHash, address account) internal returns (bool) {
        return ITaskManager(TASK_MANAGER_ADDRESS).isAllowed(euint16.unwrap(ctHash), account);
    }

    /// @notice Checks if an account has permission to operate on the encrypted 32-bit unsigned integer
    /// @dev Returns whether the specified account can access the ciphertext
    /// @param ctHash The encrypted uint32 value to check access for
    /// @param account The address to check permissions for
    /// @return True if the account has permission, false otherwise
    function isAllowed(euint32 ctHash, address account) internal returns (bool) {
        return ITaskManager(TASK_MANAGER_ADDRESS).isAllowed(euint32.unwrap(ctHash), account);
    }

    /// @notice Checks if an account has permission to operate on the encrypted 64-bit unsigned integer
    /// @dev Returns whether the specified account can access the ciphertext
    /// @param ctHash The encrypted uint64 value to check access for
    /// @param account The address to check permissions for
    /// @return True if the account has permission, false otherwise
    function isAllowed(euint64 ctHash, address account) internal returns (bool) {
        return ITaskManager(TASK_MANAGER_ADDRESS).isAllowed(euint64.unwrap(ctHash), account);
    }

    /// @notice Checks if an account has permission to operate on the encrypted 128-bit unsigned integer
    /// @dev Returns whether the specified account can access the ciphertext
    /// @param ctHash The encrypted uint128 value to check access for
    /// @param account The address to check permissions for
    /// @return True if the account has permission, false otherwise
    function isAllowed(euint128 ctHash, address account) internal returns (bool) {
        return ITaskManager(TASK_MANAGER_ADDRESS).isAllowed(euint128.unwrap(ctHash), account);
    }

    /// @notice Checks if an account has permission to operate on the encrypted 256-bit unsigned integer
    /// @dev Returns whether the specified account can access the ciphertext
    /// @param ctHash The encrypted uint256 value to check access for
    /// @param account The address to check permissions for
    /// @return True if the account has permission, false otherwise
    function isAllowed(euint256 ctHash, address account) internal returns (bool) {
        return ITaskManager(TASK_MANAGER_ADDRESS).isAllowed(euint256.unwrap(ctHash), account);
    }

    /// @notice Checks if an account has permission to operate on the encrypted address
    /// @dev Returns whether the specified account can access the ciphertext
    /// @param ctHash The encrypted address value to check access for
    /// @param account The address to check permissions for
    /// @return True if the account has permission, false otherwise
    function isAllowed(eaddress ctHash, address account) internal returns (bool) {
        return ITaskManager(TASK_MANAGER_ADDRESS).isAllowed(eaddress.unwrap(ctHash), account);
    }

    /// @notice Grants permission to the current contract to operate on the encrypted boolean value
    /// @dev Allows this contract to access the ciphertext
    /// @param ctHash The encrypted boolean value to grant access to
    function allowThis(ebool ctHash) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allow(ebool.unwrap(ctHash), address(this));
    }

    /// @notice Grants permission to the current contract to operate on the encrypted 8-bit unsigned integer
    /// @dev Allows this contract to access the ciphertext
    /// @param ctHash The encrypted uint8 value to grant access to
    function allowThis(euint8 ctHash) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allow(euint8.unwrap(ctHash), address(this));
    }

    /// @notice Grants permission to the current contract to operate on the encrypted 16-bit unsigned integer
    /// @dev Allows this contract to access the ciphertext
    /// @param ctHash The encrypted uint16 value to grant access to
    function allowThis(euint16 ctHash) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allow(euint16.unwrap(ctHash), address(this));
    }

    /// @notice Grants permission to the current contract to operate on the encrypted 32-bit unsigned integer
    /// @dev Allows this contract to access the ciphertext
    /// @param ctHash The encrypted uint32 value to grant access to
    function allowThis(euint32 ctHash) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allow(euint32.unwrap(ctHash), address(this));
    }

    /// @notice Grants permission to the current contract to operate on the encrypted 64-bit unsigned integer
    /// @dev Allows this contract to access the ciphertext
    /// @param ctHash The encrypted uint64 value to grant access to
    function allowThis(euint64 ctHash) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allow(euint64.unwrap(ctHash), address(this));
    }

    /// @notice Grants permission to the current contract to operate on the encrypted 128-bit unsigned integer
    /// @dev Allows this contract to access the ciphertext
    /// @param ctHash The encrypted uint128 value to grant access to
    function allowThis(euint128 ctHash) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allow(euint128.unwrap(ctHash), address(this));
    }

    /// @notice Grants permission to the current contract to operate on the encrypted 256-bit unsigned integer
    /// @dev Allows this contract to access the ciphertext
    /// @param ctHash The encrypted uint256 value to grant access to
    function allowThis(euint256 ctHash) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allow(euint256.unwrap(ctHash), address(this));
    }

    /// @notice Grants permission to the current contract to operate on the encrypted address
    /// @dev Allows this contract to access the ciphertext
    /// @param ctHash The encrypted address value to grant access to
    function allowThis(eaddress ctHash) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allow(eaddress.unwrap(ctHash), address(this));
    }

    /// @notice Grants permission to the message sender to operate on the encrypted boolean value
    /// @dev Allows the transaction sender to access the ciphertext
    /// @param ctHash The encrypted boolean value to grant access to
    function allowSender(ebool ctHash) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allow(ebool.unwrap(ctHash), msg.sender);
    }

    /// @notice Grants permission to the message sender to operate on the encrypted 8-bit unsigned integer
    /// @dev Allows the transaction sender to access the ciphertext
    /// @param ctHash The encrypted uint8 value to grant access to
    function allowSender(euint8 ctHash) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allow(euint8.unwrap(ctHash), msg.sender);
    }

    /// @notice Grants permission to the message sender to operate on the encrypted 16-bit unsigned integer
    /// @dev Allows the transaction sender to access the ciphertext
    /// @param ctHash The encrypted uint16 value to grant access to
    function allowSender(euint16 ctHash) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allow(euint16.unwrap(ctHash), msg.sender);
    }

    /// @notice Grants permission to the message sender to operate on the encrypted 32-bit unsigned integer
    /// @dev Allows the transaction sender to access the ciphertext
    /// @param ctHash The encrypted uint32 value to grant access to
    function allowSender(euint32 ctHash) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allow(euint32.unwrap(ctHash), msg.sender);
    }

    /// @notice Grants permission to the message sender to operate on the encrypted 64-bit unsigned integer
    /// @dev Allows the transaction sender to access the ciphertext
    /// @param ctHash The encrypted uint64 value to grant access to
    function allowSender(euint64 ctHash) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allow(euint64.unwrap(ctHash), msg.sender);
    }

    /// @notice Grants permission to the message sender to operate on the encrypted 128-bit unsigned integer
    /// @dev Allows the transaction sender to access the ciphertext
    /// @param ctHash The encrypted uint128 value to grant access to
    function allowSender(euint128 ctHash) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allow(euint128.unwrap(ctHash), msg.sender);
    }

    /// @notice Grants permission to the message sender to operate on the encrypted 256-bit unsigned integer
    /// @dev Allows the transaction sender to access the ciphertext
    /// @param ctHash The encrypted uint256 value to grant access to
    function allowSender(euint256 ctHash) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allow(euint256.unwrap(ctHash), msg.sender);
    }

    /// @notice Grants permission to the message sender to operate on the encrypted address
    /// @dev Allows the transaction sender to access the ciphertext
    /// @param ctHash The encrypted address value to grant access to
    function allowSender(eaddress ctHash) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allow(eaddress.unwrap(ctHash), msg.sender);
    }

    /// @notice Grants temporary permission to an account to operate on the encrypted boolean value
    /// @dev Allows the specified account to access the ciphertext for the current transaction only
    /// @param ctHash The encrypted boolean value to grant temporary access to
    /// @param account The address being granted temporary permission
    function allowTransient(ebool ctHash, address account) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allowTransient(ebool.unwrap(ctHash), account);
    }

    /// @notice Grants temporary permission to an account to operate on the encrypted 8-bit unsigned integer
    /// @dev Allows the specified account to access the ciphertext for the current transaction only
    /// @param ctHash The encrypted uint8 value to grant temporary access to
    /// @param account The address being granted temporary permission
    function allowTransient(euint8 ctHash, address account) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allowTransient(euint8.unwrap(ctHash), account);
    }

    /// @notice Grants temporary permission to an account to operate on the encrypted 16-bit unsigned integer
    /// @dev Allows the specified account to access the ciphertext for the current transaction only
    /// @param ctHash The encrypted uint16 value to grant temporary access to
    /// @param account The address being granted temporary permission
    function allowTransient(euint16 ctHash, address account) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allowTransient(euint16.unwrap(ctHash), account);
    }

    /// @notice Grants temporary permission to an account to operate on the encrypted 32-bit unsigned integer
    /// @dev Allows the specified account to access the ciphertext for the current transaction only
    /// @param ctHash The encrypted uint32 value to grant temporary access to
    /// @param account The address being granted temporary permission
    function allowTransient(euint32 ctHash, address account) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allowTransient(euint32.unwrap(ctHash), account);
    }

    /// @notice Grants temporary permission to an account to operate on the encrypted 64-bit unsigned integer
    /// @dev Allows the specified account to access the ciphertext for the current transaction only
    /// @param ctHash The encrypted uint64 value to grant temporary access to
    /// @param account The address being granted temporary permission
    function allowTransient(euint64 ctHash, address account) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allowTransient(euint64.unwrap(ctHash), account);
    }

    /// @notice Grants temporary permission to an account to operate on the encrypted 128-bit unsigned integer
    /// @dev Allows the specified account to access the ciphertext for the current transaction only
    /// @param ctHash The encrypted uint128 value to grant temporary access to
    /// @param account The address being granted temporary permission
    function allowTransient(euint128 ctHash, address account) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allowTransient(euint128.unwrap(ctHash), account);
    }

    /// @notice Grants temporary permission to an account to operate on the encrypted 256-bit unsigned integer
    /// @dev Allows the specified account to access the ciphertext for the current transaction only
    /// @param ctHash The encrypted uint256 value to grant temporary access to
    /// @param account The address being granted temporary permission
    function allowTransient(euint256 ctHash, address account) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allowTransient(euint256.unwrap(ctHash), account);
    }

    /// @notice Grants temporary permission to an account to operate on the encrypted address
    /// @dev Allows the specified account to access the ciphertext for the current transaction only
    /// @param ctHash The encrypted address value to grant temporary access to
    /// @param account The address being granted temporary permission
    function allowTransient(eaddress ctHash, address account) internal {
        ITaskManager(TASK_MANAGER_ADDRESS).allowTransient(eaddress.unwrap(ctHash), account);
    }

}
// ********** BINDING DEFS ************* //

using BindingsEbool for ebool global;
library BindingsEbool {

    /// @notice Performs the eq operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type ebool
    /// @param rhs second input of type ebool
    /// @return the result of the eq
    function eq(ebool lhs, ebool rhs) internal returns (ebool) {
        return FHE.eq(lhs, rhs);
    }

    /// @notice Performs the ne operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type ebool
    /// @param rhs second input of type ebool
    /// @return the result of the ne
    function ne(ebool lhs, ebool rhs) internal returns (ebool) {
        return FHE.ne(lhs, rhs);
    }

    /// @notice Performs the not operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type ebool
    /// @return the result of the not
    function not(ebool lhs) internal returns (ebool) {
        return FHE.not(lhs);
    }

    /// @notice Performs the and operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type ebool
    /// @param rhs second input of type ebool
    /// @return the result of the and
    function and(ebool lhs, ebool rhs) internal returns (ebool) {
        return FHE.and(lhs, rhs);
    }

    /// @notice Performs the or operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type ebool
    /// @param rhs second input of type ebool
    /// @return the result of the or
    function or(ebool lhs, ebool rhs) internal returns (ebool) {
        return FHE.or(lhs, rhs);
    }

    /// @notice Performs the xor operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type ebool
    /// @param rhs second input of type ebool
    /// @return the result of the xor
    function xor(ebool lhs, ebool rhs) internal returns (ebool) {
        return FHE.xor(lhs, rhs);
    }
    function toU8(ebool value) internal returns (euint8) {
        return FHE.asEuint8(value);
    }
    function toU16(ebool value) internal returns (euint16) {
        return FHE.asEuint16(value);
    }
    function toU32(ebool value) internal returns (euint32) {
        return FHE.asEuint32(value);
    }
    function toU64(ebool value) internal returns (euint64) {
        return FHE.asEuint64(value);
    }
    function toU128(ebool value) internal returns (euint128) {
        return FHE.asEuint128(value);
    }
    function toU256(ebool value) internal returns (euint256) {
        return FHE.asEuint256(value);
    }
    function decrypt(ebool value) internal {
        FHE.decrypt(value);
    }
    function allow(ebool ctHash, address account) internal {
        FHE.allow(ctHash, account);
    }
    function isAllowed(ebool ctHash, address account) internal returns (bool) {
        return FHE.isAllowed(ctHash, account);
    }
    function allowThis(ebool ctHash) internal {
        FHE.allowThis(ctHash);
    }
    function allowGlobal(ebool ctHash) internal {
        FHE.allowGlobal(ctHash);
    }
    function allowSender(ebool ctHash) internal {
        FHE.allowSender(ctHash);
    }
    function allowTransient(ebool ctHash, address account) internal {
        FHE.allowTransient(ctHash, account);
    }
}

using BindingsEuint8 for euint8 global;
library BindingsEuint8 {

    /// @notice Performs the add operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return the result of the add
    function add(euint8 lhs, euint8 rhs) internal returns (euint8) {
        return FHE.add(lhs, rhs);
    }

    /// @notice Performs the mul operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return the result of the mul
    function mul(euint8 lhs, euint8 rhs) internal returns (euint8) {
        return FHE.mul(lhs, rhs);
    }

    /// @notice Performs the div operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return the result of the div
    function div(euint8 lhs, euint8 rhs) internal returns (euint8) {
        return FHE.div(lhs, rhs);
    }

    /// @notice Performs the sub operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return the result of the sub
    function sub(euint8 lhs, euint8 rhs) internal returns (euint8) {
        return FHE.sub(lhs, rhs);
    }

    /// @notice Performs the eq operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return the result of the eq
    function eq(euint8 lhs, euint8 rhs) internal returns (ebool) {
        return FHE.eq(lhs, rhs);
    }

    /// @notice Performs the ne operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return the result of the ne
    function ne(euint8 lhs, euint8 rhs) internal returns (ebool) {
        return FHE.ne(lhs, rhs);
    }

    /// @notice Performs the not operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint8
    /// @return the result of the not
    function not(euint8 lhs) internal returns (euint8) {
        return FHE.not(lhs);
    }

    /// @notice Performs the and operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return the result of the and
    function and(euint8 lhs, euint8 rhs) internal returns (euint8) {
        return FHE.and(lhs, rhs);
    }

    /// @notice Performs the or operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return the result of the or
    function or(euint8 lhs, euint8 rhs) internal returns (euint8) {
        return FHE.or(lhs, rhs);
    }

    /// @notice Performs the xor operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return the result of the xor
    function xor(euint8 lhs, euint8 rhs) internal returns (euint8) {
        return FHE.xor(lhs, rhs);
    }

    /// @notice Performs the gt operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return the result of the gt
    function gt(euint8 lhs, euint8 rhs) internal returns (ebool) {
        return FHE.gt(lhs, rhs);
    }

    /// @notice Performs the gte operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return the result of the gte
    function gte(euint8 lhs, euint8 rhs) internal returns (ebool) {
        return FHE.gte(lhs, rhs);
    }

    /// @notice Performs the lt operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return the result of the lt
    function lt(euint8 lhs, euint8 rhs) internal returns (ebool) {
        return FHE.lt(lhs, rhs);
    }

    /// @notice Performs the lte operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return the result of the lte
    function lte(euint8 lhs, euint8 rhs) internal returns (ebool) {
        return FHE.lte(lhs, rhs);
    }

    /// @notice Performs the rem operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return the result of the rem
    function rem(euint8 lhs, euint8 rhs) internal returns (euint8) {
        return FHE.rem(lhs, rhs);
    }

    /// @notice Performs the max operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return the result of the max
    function max(euint8 lhs, euint8 rhs) internal returns (euint8) {
        return FHE.max(lhs, rhs);
    }

    /// @notice Performs the min operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return the result of the min
    function min(euint8 lhs, euint8 rhs) internal returns (euint8) {
        return FHE.min(lhs, rhs);
    }

    /// @notice Performs the shl operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return the result of the shl
    function shl(euint8 lhs, euint8 rhs) internal returns (euint8) {
        return FHE.shl(lhs, rhs);
    }

    /// @notice Performs the shr operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return the result of the shr
    function shr(euint8 lhs, euint8 rhs) internal returns (euint8) {
        return FHE.shr(lhs, rhs);
    }

    /// @notice Performs the rol operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return the result of the rol
    function rol(euint8 lhs, euint8 rhs) internal returns (euint8) {
        return FHE.rol(lhs, rhs);
    }

    /// @notice Performs the ror operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint8
    /// @param rhs second input of type euint8
    /// @return the result of the ror
    function ror(euint8 lhs, euint8 rhs) internal returns (euint8) {
        return FHE.ror(lhs, rhs);
    }

    /// @notice Performs the square operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint8
    /// @return the result of the square
    function square(euint8 lhs) internal returns (euint8) {
        return FHE.square(lhs);
    }
    function toBool(euint8 value) internal  returns (ebool) {
        return FHE.asEbool(value);
    }
    function toU16(euint8 value) internal returns (euint16) {
        return FHE.asEuint16(value);
    }
    function toU32(euint8 value) internal returns (euint32) {
        return FHE.asEuint32(value);
    }
    function toU64(euint8 value) internal returns (euint64) {
        return FHE.asEuint64(value);
    }
    function toU128(euint8 value) internal returns (euint128) {
        return FHE.asEuint128(value);
    }
    function toU256(euint8 value) internal returns (euint256) {
        return FHE.asEuint256(value);
    }
    function decrypt(euint8 value) internal {
        FHE.decrypt(value);
    }
    function allow(euint8 ctHash, address account) internal {
        FHE.allow(ctHash, account);
    }
    function isAllowed(euint8 ctHash, address account) internal returns (bool) {
        return FHE.isAllowed(ctHash, account);
    }
    function allowThis(euint8 ctHash) internal {
        FHE.allowThis(ctHash);
    }
    function allowGlobal(euint8 ctHash) internal {
        FHE.allowGlobal(ctHash);
    }
    function allowSender(euint8 ctHash) internal {
        FHE.allowSender(ctHash);
    }
    function allowTransient(euint8 ctHash, address account) internal {
        FHE.allowTransient(ctHash, account);
    }
}

using BindingsEuint16 for euint16 global;
library BindingsEuint16 {

    /// @notice Performs the add operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return the result of the add
    function add(euint16 lhs, euint16 rhs) internal returns (euint16) {
        return FHE.add(lhs, rhs);
    }

    /// @notice Performs the mul operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return the result of the mul
    function mul(euint16 lhs, euint16 rhs) internal returns (euint16) {
        return FHE.mul(lhs, rhs);
    }

    /// @notice Performs the div operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return the result of the div
    function div(euint16 lhs, euint16 rhs) internal returns (euint16) {
        return FHE.div(lhs, rhs);
    }

    /// @notice Performs the sub operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return the result of the sub
    function sub(euint16 lhs, euint16 rhs) internal returns (euint16) {
        return FHE.sub(lhs, rhs);
    }

    /// @notice Performs the eq operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return the result of the eq
    function eq(euint16 lhs, euint16 rhs) internal returns (ebool) {
        return FHE.eq(lhs, rhs);
    }

    /// @notice Performs the ne operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return the result of the ne
    function ne(euint16 lhs, euint16 rhs) internal returns (ebool) {
        return FHE.ne(lhs, rhs);
    }

    /// @notice Performs the not operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint16
    /// @return the result of the not
    function not(euint16 lhs) internal returns (euint16) {
        return FHE.not(lhs);
    }

    /// @notice Performs the and operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return the result of the and
    function and(euint16 lhs, euint16 rhs) internal returns (euint16) {
        return FHE.and(lhs, rhs);
    }

    /// @notice Performs the or operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return the result of the or
    function or(euint16 lhs, euint16 rhs) internal returns (euint16) {
        return FHE.or(lhs, rhs);
    }

    /// @notice Performs the xor operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return the result of the xor
    function xor(euint16 lhs, euint16 rhs) internal returns (euint16) {
        return FHE.xor(lhs, rhs);
    }

    /// @notice Performs the gt operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return the result of the gt
    function gt(euint16 lhs, euint16 rhs) internal returns (ebool) {
        return FHE.gt(lhs, rhs);
    }

    /// @notice Performs the gte operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return the result of the gte
    function gte(euint16 lhs, euint16 rhs) internal returns (ebool) {
        return FHE.gte(lhs, rhs);
    }

    /// @notice Performs the lt operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return the result of the lt
    function lt(euint16 lhs, euint16 rhs) internal returns (ebool) {
        return FHE.lt(lhs, rhs);
    }

    /// @notice Performs the lte operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return the result of the lte
    function lte(euint16 lhs, euint16 rhs) internal returns (ebool) {
        return FHE.lte(lhs, rhs);
    }

    /// @notice Performs the rem operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return the result of the rem
    function rem(euint16 lhs, euint16 rhs) internal returns (euint16) {
        return FHE.rem(lhs, rhs);
    }

    /// @notice Performs the max operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return the result of the max
    function max(euint16 lhs, euint16 rhs) internal returns (euint16) {
        return FHE.max(lhs, rhs);
    }

    /// @notice Performs the min operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return the result of the min
    function min(euint16 lhs, euint16 rhs) internal returns (euint16) {
        return FHE.min(lhs, rhs);
    }

    /// @notice Performs the shl operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return the result of the shl
    function shl(euint16 lhs, euint16 rhs) internal returns (euint16) {
        return FHE.shl(lhs, rhs);
    }

    /// @notice Performs the shr operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return the result of the shr
    function shr(euint16 lhs, euint16 rhs) internal returns (euint16) {
        return FHE.shr(lhs, rhs);
    }

    /// @notice Performs the rol operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return the result of the rol
    function rol(euint16 lhs, euint16 rhs) internal returns (euint16) {
        return FHE.rol(lhs, rhs);
    }

    /// @notice Performs the ror operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint16
    /// @param rhs second input of type euint16
    /// @return the result of the ror
    function ror(euint16 lhs, euint16 rhs) internal returns (euint16) {
        return FHE.ror(lhs, rhs);
    }

    /// @notice Performs the square operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint16
    /// @return the result of the square
    function square(euint16 lhs) internal returns (euint16) {
        return FHE.square(lhs);
    }
    function toBool(euint16 value) internal  returns (ebool) {
        return FHE.asEbool(value);
    }
    function toU8(euint16 value) internal returns (euint8) {
        return FHE.asEuint8(value);
    }
    function toU32(euint16 value) internal returns (euint32) {
        return FHE.asEuint32(value);
    }
    function toU64(euint16 value) internal returns (euint64) {
        return FHE.asEuint64(value);
    }
    function toU128(euint16 value) internal returns (euint128) {
        return FHE.asEuint128(value);
    }
    function toU256(euint16 value) internal returns (euint256) {
        return FHE.asEuint256(value);
    }
    function decrypt(euint16 value) internal {
        FHE.decrypt(value);
    }
    function allow(euint16 ctHash, address account) internal {
        FHE.allow(ctHash, account);
    }
    function isAllowed(euint16 ctHash, address account) internal returns (bool) {
        return FHE.isAllowed(ctHash, account);
    }
    function allowThis(euint16 ctHash) internal {
        FHE.allowThis(ctHash);
    }
    function allowGlobal(euint16 ctHash) internal {
        FHE.allowGlobal(ctHash);
    }
    function allowSender(euint16 ctHash) internal {
        FHE.allowSender(ctHash);
    }
    function allowTransient(euint16 ctHash, address account) internal {
        FHE.allowTransient(ctHash, account);
    }
}

using BindingsEuint32 for euint32 global;
library BindingsEuint32 {

    /// @notice Performs the add operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return the result of the add
    function add(euint32 lhs, euint32 rhs) internal returns (euint32) {
        return FHE.add(lhs, rhs);
    }

    /// @notice Performs the mul operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return the result of the mul
    function mul(euint32 lhs, euint32 rhs) internal returns (euint32) {
        return FHE.mul(lhs, rhs);
    }

    /// @notice Performs the div operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return the result of the div
    function div(euint32 lhs, euint32 rhs) internal returns (euint32) {
        return FHE.div(lhs, rhs);
    }

    /// @notice Performs the sub operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return the result of the sub
    function sub(euint32 lhs, euint32 rhs) internal returns (euint32) {
        return FHE.sub(lhs, rhs);
    }

    /// @notice Performs the eq operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return the result of the eq
    function eq(euint32 lhs, euint32 rhs) internal returns (ebool) {
        return FHE.eq(lhs, rhs);
    }

    /// @notice Performs the ne operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return the result of the ne
    function ne(euint32 lhs, euint32 rhs) internal returns (ebool) {
        return FHE.ne(lhs, rhs);
    }

    /// @notice Performs the not operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint32
    /// @return the result of the not
    function not(euint32 lhs) internal returns (euint32) {
        return FHE.not(lhs);
    }

    /// @notice Performs the and operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return the result of the and
    function and(euint32 lhs, euint32 rhs) internal returns (euint32) {
        return FHE.and(lhs, rhs);
    }

    /// @notice Performs the or operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return the result of the or
    function or(euint32 lhs, euint32 rhs) internal returns (euint32) {
        return FHE.or(lhs, rhs);
    }

    /// @notice Performs the xor operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return the result of the xor
    function xor(euint32 lhs, euint32 rhs) internal returns (euint32) {
        return FHE.xor(lhs, rhs);
    }

    /// @notice Performs the gt operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return the result of the gt
    function gt(euint32 lhs, euint32 rhs) internal returns (ebool) {
        return FHE.gt(lhs, rhs);
    }

    /// @notice Performs the gte operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return the result of the gte
    function gte(euint32 lhs, euint32 rhs) internal returns (ebool) {
        return FHE.gte(lhs, rhs);
    }

    /// @notice Performs the lt operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return the result of the lt
    function lt(euint32 lhs, euint32 rhs) internal returns (ebool) {
        return FHE.lt(lhs, rhs);
    }

    /// @notice Performs the lte operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return the result of the lte
    function lte(euint32 lhs, euint32 rhs) internal returns (ebool) {
        return FHE.lte(lhs, rhs);
    }

    /// @notice Performs the rem operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return the result of the rem
    function rem(euint32 lhs, euint32 rhs) internal returns (euint32) {
        return FHE.rem(lhs, rhs);
    }

    /// @notice Performs the max operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return the result of the max
    function max(euint32 lhs, euint32 rhs) internal returns (euint32) {
        return FHE.max(lhs, rhs);
    }

    /// @notice Performs the min operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return the result of the min
    function min(euint32 lhs, euint32 rhs) internal returns (euint32) {
        return FHE.min(lhs, rhs);
    }

    /// @notice Performs the shl operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return the result of the shl
    function shl(euint32 lhs, euint32 rhs) internal returns (euint32) {
        return FHE.shl(lhs, rhs);
    }

    /// @notice Performs the shr operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return the result of the shr
    function shr(euint32 lhs, euint32 rhs) internal returns (euint32) {
        return FHE.shr(lhs, rhs);
    }

    /// @notice Performs the rol operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return the result of the rol
    function rol(euint32 lhs, euint32 rhs) internal returns (euint32) {
        return FHE.rol(lhs, rhs);
    }

    /// @notice Performs the ror operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint32
    /// @param rhs second input of type euint32
    /// @return the result of the ror
    function ror(euint32 lhs, euint32 rhs) internal returns (euint32) {
        return FHE.ror(lhs, rhs);
    }

    /// @notice Performs the square operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint32
    /// @return the result of the square
    function square(euint32 lhs) internal returns (euint32) {
        return FHE.square(lhs);
    }
    function toBool(euint32 value) internal  returns (ebool) {
        return FHE.asEbool(value);
    }
    function toU8(euint32 value) internal returns (euint8) {
        return FHE.asEuint8(value);
    }
    function toU16(euint32 value) internal returns (euint16) {
        return FHE.asEuint16(value);
    }
    function toU64(euint32 value) internal returns (euint64) {
        return FHE.asEuint64(value);
    }
    function toU128(euint32 value) internal returns (euint128) {
        return FHE.asEuint128(value);
    }
    function toU256(euint32 value) internal returns (euint256) {
        return FHE.asEuint256(value);
    }
    function decrypt(euint32 value) internal {
        FHE.decrypt(value);
    }
    function allow(euint32 ctHash, address account) internal {
        FHE.allow(ctHash, account);
    }
    function isAllowed(euint32 ctHash, address account) internal returns (bool) {
        return FHE.isAllowed(ctHash, account);
    }
    function allowThis(euint32 ctHash) internal {
        FHE.allowThis(ctHash);
    }
    function allowGlobal(euint32 ctHash) internal {
        FHE.allowGlobal(ctHash);
    }
    function allowSender(euint32 ctHash) internal {
        FHE.allowSender(ctHash);
    }
    function allowTransient(euint32 ctHash, address account) internal {
        FHE.allowTransient(ctHash, account);
    }
}

using BindingsEuint64 for euint64 global;
library BindingsEuint64 {

    /// @notice Performs the add operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return the result of the add
    function add(euint64 lhs, euint64 rhs) internal returns (euint64) {
        return FHE.add(lhs, rhs);
    }

    /// @notice Performs the mul operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return the result of the mul
    function mul(euint64 lhs, euint64 rhs) internal returns (euint64) {
        return FHE.mul(lhs, rhs);
    }

    /// @notice Performs the sub operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return the result of the sub
    function sub(euint64 lhs, euint64 rhs) internal returns (euint64) {
        return FHE.sub(lhs, rhs);
    }

    /// @notice Performs the eq operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return the result of the eq
    function eq(euint64 lhs, euint64 rhs) internal returns (ebool) {
        return FHE.eq(lhs, rhs);
    }

    /// @notice Performs the ne operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return the result of the ne
    function ne(euint64 lhs, euint64 rhs) internal returns (ebool) {
        return FHE.ne(lhs, rhs);
    }

    /// @notice Performs the not operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint64
    /// @return the result of the not
    function not(euint64 lhs) internal returns (euint64) {
        return FHE.not(lhs);
    }

    /// @notice Performs the and operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return the result of the and
    function and(euint64 lhs, euint64 rhs) internal returns (euint64) {
        return FHE.and(lhs, rhs);
    }

    /// @notice Performs the or operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return the result of the or
    function or(euint64 lhs, euint64 rhs) internal returns (euint64) {
        return FHE.or(lhs, rhs);
    }

    /// @notice Performs the xor operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return the result of the xor
    function xor(euint64 lhs, euint64 rhs) internal returns (euint64) {
        return FHE.xor(lhs, rhs);
    }

    /// @notice Performs the gt operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return the result of the gt
    function gt(euint64 lhs, euint64 rhs) internal returns (ebool) {
        return FHE.gt(lhs, rhs);
    }

    /// @notice Performs the gte operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return the result of the gte
    function gte(euint64 lhs, euint64 rhs) internal returns (ebool) {
        return FHE.gte(lhs, rhs);
    }

    /// @notice Performs the lt operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return the result of the lt
    function lt(euint64 lhs, euint64 rhs) internal returns (ebool) {
        return FHE.lt(lhs, rhs);
    }

    /// @notice Performs the lte operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return the result of the lte
    function lte(euint64 lhs, euint64 rhs) internal returns (ebool) {
        return FHE.lte(lhs, rhs);
    }

    /// @notice Performs the max operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return the result of the max
    function max(euint64 lhs, euint64 rhs) internal returns (euint64) {
        return FHE.max(lhs, rhs);
    }

    /// @notice Performs the min operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return the result of the min
    function min(euint64 lhs, euint64 rhs) internal returns (euint64) {
        return FHE.min(lhs, rhs);
    }

    /// @notice Performs the shl operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return the result of the shl
    function shl(euint64 lhs, euint64 rhs) internal returns (euint64) {
        return FHE.shl(lhs, rhs);
    }

    /// @notice Performs the shr operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return the result of the shr
    function shr(euint64 lhs, euint64 rhs) internal returns (euint64) {
        return FHE.shr(lhs, rhs);
    }

    /// @notice Performs the rol operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return the result of the rol
    function rol(euint64 lhs, euint64 rhs) internal returns (euint64) {
        return FHE.rol(lhs, rhs);
    }

    /// @notice Performs the ror operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint64
    /// @param rhs second input of type euint64
    /// @return the result of the ror
    function ror(euint64 lhs, euint64 rhs) internal returns (euint64) {
        return FHE.ror(lhs, rhs);
    }

    /// @notice Performs the square operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint64
    /// @return the result of the square
    function square(euint64 lhs) internal returns (euint64) {
        return FHE.square(lhs);
    }
    function toBool(euint64 value) internal  returns (ebool) {
        return FHE.asEbool(value);
    }
    function toU8(euint64 value) internal returns (euint8) {
        return FHE.asEuint8(value);
    }
    function toU16(euint64 value) internal returns (euint16) {
        return FHE.asEuint16(value);
    }
    function toU32(euint64 value) internal returns (euint32) {
        return FHE.asEuint32(value);
    }
    function toU128(euint64 value) internal returns (euint128) {
        return FHE.asEuint128(value);
    }
    function toU256(euint64 value) internal returns (euint256) {
        return FHE.asEuint256(value);
    }
    function decrypt(euint64 value) internal {
        FHE.decrypt(value);
    }
    function allow(euint64 ctHash, address account) internal {
        FHE.allow(ctHash, account);
    }
    function isAllowed(euint64 ctHash, address account) internal returns (bool) {
        return FHE.isAllowed(ctHash, account);
    }
    function allowThis(euint64 ctHash) internal {
        FHE.allowThis(ctHash);
    }
    function allowGlobal(euint64 ctHash) internal {
        FHE.allowGlobal(ctHash);
    }
    function allowSender(euint64 ctHash) internal {
        FHE.allowSender(ctHash);
    }
    function allowTransient(euint64 ctHash, address account) internal {
        FHE.allowTransient(ctHash, account);
    }
}

using BindingsEuint128 for euint128 global;
library BindingsEuint128 {

    /// @notice Performs the add operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return the result of the add
    function add(euint128 lhs, euint128 rhs) internal returns (euint128) {
        return FHE.add(lhs, rhs);
    }

    /// @notice Performs the sub operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return the result of the sub
    function sub(euint128 lhs, euint128 rhs) internal returns (euint128) {
        return FHE.sub(lhs, rhs);
    }

    /// @notice Performs the eq operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return the result of the eq
    function eq(euint128 lhs, euint128 rhs) internal returns (ebool) {
        return FHE.eq(lhs, rhs);
    }

    /// @notice Performs the ne operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return the result of the ne
    function ne(euint128 lhs, euint128 rhs) internal returns (ebool) {
        return FHE.ne(lhs, rhs);
    }

    /// @notice Performs the not operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint128
    /// @return the result of the not
    function not(euint128 lhs) internal returns (euint128) {
        return FHE.not(lhs);
    }

    /// @notice Performs the and operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return the result of the and
    function and(euint128 lhs, euint128 rhs) internal returns (euint128) {
        return FHE.and(lhs, rhs);
    }

    /// @notice Performs the or operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return the result of the or
    function or(euint128 lhs, euint128 rhs) internal returns (euint128) {
        return FHE.or(lhs, rhs);
    }

    /// @notice Performs the xor operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return the result of the xor
    function xor(euint128 lhs, euint128 rhs) internal returns (euint128) {
        return FHE.xor(lhs, rhs);
    }

    /// @notice Performs the gt operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return the result of the gt
    function gt(euint128 lhs, euint128 rhs) internal returns (ebool) {
        return FHE.gt(lhs, rhs);
    }

    /// @notice Performs the gte operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return the result of the gte
    function gte(euint128 lhs, euint128 rhs) internal returns (ebool) {
        return FHE.gte(lhs, rhs);
    }

    /// @notice Performs the lt operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return the result of the lt
    function lt(euint128 lhs, euint128 rhs) internal returns (ebool) {
        return FHE.lt(lhs, rhs);
    }

    /// @notice Performs the lte operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return the result of the lte
    function lte(euint128 lhs, euint128 rhs) internal returns (ebool) {
        return FHE.lte(lhs, rhs);
    }

    /// @notice Performs the max operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return the result of the max
    function max(euint128 lhs, euint128 rhs) internal returns (euint128) {
        return FHE.max(lhs, rhs);
    }

    /// @notice Performs the min operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return the result of the min
    function min(euint128 lhs, euint128 rhs) internal returns (euint128) {
        return FHE.min(lhs, rhs);
    }

    /// @notice Performs the shl operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return the result of the shl
    function shl(euint128 lhs, euint128 rhs) internal returns (euint128) {
        return FHE.shl(lhs, rhs);
    }

    /// @notice Performs the shr operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return the result of the shr
    function shr(euint128 lhs, euint128 rhs) internal returns (euint128) {
        return FHE.shr(lhs, rhs);
    }

    /// @notice Performs the rol operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return the result of the rol
    function rol(euint128 lhs, euint128 rhs) internal returns (euint128) {
        return FHE.rol(lhs, rhs);
    }

    /// @notice Performs the ror operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint128
    /// @param rhs second input of type euint128
    /// @return the result of the ror
    function ror(euint128 lhs, euint128 rhs) internal returns (euint128) {
        return FHE.ror(lhs, rhs);
    }
    function toBool(euint128 value) internal  returns (ebool) {
        return FHE.asEbool(value);
    }
    function toU8(euint128 value) internal returns (euint8) {
        return FHE.asEuint8(value);
    }
    function toU16(euint128 value) internal returns (euint16) {
        return FHE.asEuint16(value);
    }
    function toU32(euint128 value) internal returns (euint32) {
        return FHE.asEuint32(value);
    }
    function toU64(euint128 value) internal returns (euint64) {
        return FHE.asEuint64(value);
    }
    function toU256(euint128 value) internal returns (euint256) {
        return FHE.asEuint256(value);
    }
    function decrypt(euint128 value) internal {
        FHE.decrypt(value);
    }
    function allow(euint128 ctHash, address account) internal {
        FHE.allow(ctHash, account);
    }
    function isAllowed(euint128 ctHash, address account) internal returns (bool) {
        return FHE.isAllowed(ctHash, account);
    }
    function allowThis(euint128 ctHash) internal {
        FHE.allowThis(ctHash);
    }
    function allowGlobal(euint128 ctHash) internal {
        FHE.allowGlobal(ctHash);
    }
    function allowSender(euint128 ctHash) internal {
        FHE.allowSender(ctHash);
    }
    function allowTransient(euint128 ctHash, address account) internal {
        FHE.allowTransient(ctHash, account);
    }
}

using BindingsEuint256 for euint256 global;
library BindingsEuint256 {

    /// @notice Performs the eq operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint256
    /// @param rhs second input of type euint256
    /// @return the result of the eq
    function eq(euint256 lhs, euint256 rhs) internal returns (ebool) {
        return FHE.eq(lhs, rhs);
    }

    /// @notice Performs the ne operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type euint256
    /// @param rhs second input of type euint256
    /// @return the result of the ne
    function ne(euint256 lhs, euint256 rhs) internal returns (ebool) {
        return FHE.ne(lhs, rhs);
    }
    function toBool(euint256 value) internal  returns (ebool) {
        return FHE.asEbool(value);
    }
    function toU8(euint256 value) internal returns (euint8) {
        return FHE.asEuint8(value);
    }
    function toU16(euint256 value) internal returns (euint16) {
        return FHE.asEuint16(value);
    }
    function toU32(euint256 value) internal returns (euint32) {
        return FHE.asEuint32(value);
    }
    function toU64(euint256 value) internal returns (euint64) {
        return FHE.asEuint64(value);
    }
    function toU128(euint256 value) internal returns (euint128) {
        return FHE.asEuint128(value);
    }
    function toEaddress(euint256 value) internal returns (eaddress) {
        return FHE.asEaddress(value);
    }
    function decrypt(euint256 value) internal {
        FHE.decrypt(value);
    }
    function allow(euint256 ctHash, address account) internal {
        FHE.allow(ctHash, account);
    }
    function isAllowed(euint256 ctHash, address account) internal returns (bool) {
        return FHE.isAllowed(ctHash, account);
    }
    function allowThis(euint256 ctHash) internal {
        FHE.allowThis(ctHash);
    }
    function allowGlobal(euint256 ctHash) internal {
        FHE.allowGlobal(ctHash);
    }
    function allowSender(euint256 ctHash) internal {
        FHE.allowSender(ctHash);
    }
    function allowTransient(euint256 ctHash, address account) internal {
        FHE.allowTransient(ctHash, account);
    }
}

using BindingsEaddress for eaddress global;
library BindingsEaddress {

    /// @notice Performs the eq operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type eaddress
    /// @param rhs second input of type eaddress
    /// @return the result of the eq
    function eq(eaddress lhs, eaddress rhs) internal returns (ebool) {
        return FHE.eq(lhs, rhs);
    }

    /// @notice Performs the ne operation
    /// @dev Pure in this function is marked as a hack/workaround - note that this function is NOT pure as fetches of ciphertexts require state access
    /// @param lhs input of type eaddress
    /// @param rhs second input of type eaddress
    /// @return the result of the ne
    function ne(eaddress lhs, eaddress rhs) internal returns (ebool) {
        return FHE.ne(lhs, rhs);
    }
    function toBool(eaddress value) internal  returns (ebool) {
        return FHE.asEbool(value);
    }
    function toU8(eaddress value) internal returns (euint8) {
        return FHE.asEuint8(value);
    }
    function toU16(eaddress value) internal returns (euint16) {
        return FHE.asEuint16(value);
    }
    function toU32(eaddress value) internal returns (euint32) {
        return FHE.asEuint32(value);
    }
    function toU64(eaddress value) internal returns (euint64) {
        return FHE.asEuint64(value);
    }
    function toU128(eaddress value) internal returns (euint128) {
        return FHE.asEuint128(value);
    }
    function toU256(eaddress value) internal returns (euint256) {
        return FHE.asEuint256(value);
    }
    function decrypt(eaddress value) internal {
        FHE.decrypt(value);
    }
    function allow(eaddress ctHash, address account) internal {
        FHE.allow(ctHash, account);
    }
    function isAllowed(eaddress ctHash, address account) internal returns (bool) {
        return FHE.isAllowed(ctHash, account);
    }
    function allowThis(eaddress ctHash) internal {
        FHE.allowThis(ctHash);
    }
    function allowGlobal(eaddress ctHash) internal {
        FHE.allowGlobal(ctHash);
    }
    function allowSender(eaddress ctHash) internal {
        FHE.allowSender(ctHash);
    }
    function allowTransient(eaddress ctHash, address account) internal {
        FHE.allowTransient(ctHash, account);
    }
}

// src/FhenixFHECompliance_FIXED.sol

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
        require(score <= 100, "Invalid score");
        sanctionedAddresses[user] = true;
        encryptedSanctionScores[user] = FHE.asEuint32(score);
        sanctionedList.push(user);
        FHE.allowThis(encryptedSanctionScores[user]);
        emit SanctionDetected(user);
    }
    
    function removeFromSanctionsList(address user) external onlyOwner {
        if (user == address(0)) revert InvalidAddress();
        require(sanctionedAddresses[user], "Not on list");
        sanctionedAddresses[user] = false;
        uint256 length = sanctionedList.length;
        for (uint256 i = 0; i < length; i++) {
            if (sanctionedList[i] == user) {
                sanctionedList[i] = sanctionedList[length - 1];
                sanctionedList.pop();
                break;
            }
        }
    }
    
    function checkSanctionsList(address user) external view returns (bool) {
        return sanctionedAddresses[user];
    }
    
    function getEncryptedProfile(address user) external view returns (
        euint32 encryptedSanctionsScore,
        euint32 encryptedRiskScore,
        euint8 encryptedSanctionStatus,
        uint256 timestamp,
        bool screened
    ) {
        EncryptedProfile memory profile = encryptedProfiles[user];
        return (
            profile.encryptedSanctionsScore,
            profile.encryptedRiskScore,
            profile.encryptedSanctionStatus,
            profile.timestamp,
            profile.screened
        );
    }
    
    function setAuthorizedCaller(address caller, bool status) external onlyOwner {
        if (caller == address(0)) revert InvalidAddress();
        authorizedCallers[caller] = status;
    }
    
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }
    
    function getSanctionsCount() external view returns (uint256) {
        return sanctionedList.length;
    }
    
    function isProfileScreened(address user) external view returns (bool) {
        return encryptedProfiles[user].screened;
    }
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Vesting
/// @dev Implements a token vesting mechanism where tokens are locked and released linearly over time.
/// @notice This contract is used to manage the vesting of tokens, allowing users to claim their vested tokens over a period.
contract Vesting is Ownable, ReentrancyGuard {
    /// @notice Stores vesting information for each user
    mapping(address => LockInfo) public userToLockInfo;

    /// @notice Address of the DTEC token
    address public immutable dtecTokenAddress;

    /// @notice The period after which tokens begin to unlock
    uint256 public period = 30 days;

    /// @notice The rate at which tokens are released per period
    uint256 public releaseRate;

    /// @notice The start time of the lock
    uint256 public lockStartTime;

    // Event declarations
    event ReleaseInfoSet(uint256 startTime, uint256 rate);
    event PeriodSet(uint256 period);
    event Claimed(address indexed user, uint256 timestamp, uint256 claimedAmount, 
    uint256 totalClaimed, uint256 totalAmount);
    event TokensLocked(address indexed user, uint256 timestamp, uint256 amount);

    // Error declarations
    error Unauthorized();
    error NothingToClaim();
    error OutOfExpectedRange();

    /// @dev Struct to store total amount locked and total amount claimed for each user
    struct LockInfo {
        uint256 totalAmount;
        uint256 totalClaimed;
    }

    /// @notice Constructor to initialize the Vesting contract
    /// @param _dtecAddress Address of the DTEC token contract
    constructor(address _dtecAddress) {
        require (_dtecAddress != address(0) , "Invalid address") ;
        dtecTokenAddress = _dtecAddress;
    }

    /// @notice Sets the start time and release rate for the vesting
    /// @dev The base rate is 10000
    /// @param _startTime Time when the vesting starts
    /// @param _rate Rate at which tokens are released per period
    function setReleaseInfo(uint256 _startTime, uint256 _rate) internal onlyOwner {
        require(_rate > 0 , "Value must be greater than zero.");
        lockStartTime = _startTime;
        releaseRate = _rate;
        emit ReleaseInfoSet(_startTime, _rate);
    }

    /// @notice Sets the period for the vesting
    /// @param _period Duration of each vesting period
    function setPeriod(uint256 _period) internal onlyOwner {
        require(_period > 0 , "Value must be greater than zero.");
        period = _period;
        emit PeriodSet(_period);
    }

    /// @notice Locks a specified amount of tokens for vesting for a given user
    /// @param _user Address of the user whose tokens are to be locked
    /// @param _amt Amount of tokens to lock for vesting
    function lockTokens(address _user, uint256 _amt) external onlyOwner {
        LockInfo storage info = userToLockInfo[_user];
        info.totalAmount += _amt;
        emit TokensLocked(_user, block.timestamp,_amt);
    }

    /// @notice Calculates the amount of tokens claimable by a user at the current time
    /// @param _user Address of the user
    /// @return Amount of tokens that the user can claim
    function getClaimable(address _user) public view returns (uint256) {
        LockInfo memory info = userToLockInfo[_user];
        if (info.totalClaimed == info.totalAmount || lockStartTime == 0 || block.timestamp < lockStartTime) {
            return 0;
        }
        uint256 timePassed = block.timestamp - lockStartTime;
        uint256 periodsPassed = timePassed / period;
        if (periodsPassed == 0) {
            return 0;
        }
        uint256 totalClaimableSoFar = info.totalAmount * releaseRate * periodsPassed / 10000;
        if (totalClaimableSoFar > info.totalAmount) {
            totalClaimableSoFar = info.totalAmount;
        }
        return totalClaimableSoFar - info.totalClaimed;
    }

    /// @notice Allows users to claim their vested tokens
    function claim() external nonReentrant {
        uint256 claimable = getClaimable(msg.sender);
        if (claimable == 0) {
            revert NothingToClaim();
        }
        LockInfo storage info = userToLockInfo[msg.sender];
        info.totalClaimed = info.totalClaimed + claimable;
        IERC20 dtec = IERC20(dtecTokenAddress);
        dtec.transfer(msg.sender, claimable);
        emit Claimed(msg.sender, block.timestamp, claimable, info.totalClaimed, info.totalAmount);
    }
}

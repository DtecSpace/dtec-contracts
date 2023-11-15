// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ITokenLock} from "../interfaces/ITokenLock.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PublicSaleLock is ITokenLock, Ownable, ReentrancyGuard {
    mapping(address => LockInfo) public userToLockInfo;
    address public dtecTokenAddress;
    address public tokenLocker;
    uint256 public period = 30 days;
    uint256 public lockStartTime;

    error Unauthorized();
    error NothingToClaim();
    error OutOfExpectedRange();

    struct LockInfo {
        uint256 totalAmount;
        uint256 totalClaimed;
    }

    constructor(address _dtecAddress, address _locker) {
        dtecTokenAddress = _dtecAddress;
        tokenLocker = _locker;
        lockStartTime = 1704153601;
    }

    // Base rate 10000
    function setReleaseInfo(uint256 _startTime) external onlyOwner {
        lockStartTime = _startTime;
    }

    function setTokenLocker(address _locker) external onlyOwner {
        tokenLocker = _locker;
    }

    function setPeriod(uint256 _period) external onlyOwner {
        // This is for testing only but still we won't allow +30 days period
        if (_period > 30 days) {
            revert OutOfExpectedRange();
        }
        period = _period;
    }

    function getReleaseNumerator(uint256 _periods) internal pure returns (uint256) {
        if (_periods == 0) {
            return 0;
        } else if (_periods == 1) {
            return 2000;
        } else if (_periods == 2) {
            return 5000;
        }
        return 9000;
    }

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
        uint256 numerator = getReleaseNumerator(periodsPassed);
        uint256 totalClaimableSoFar = info.totalAmount * numerator / 10000;
        if (totalClaimableSoFar > info.totalAmount) {
            totalClaimableSoFar = info.totalAmount;
        }
        return totalClaimableSoFar - info.totalClaimed;
    }

    function claim() external nonReentrant {
        uint256 claimable = getClaimable(msg.sender);
        if (claimable == 0) {
            revert NothingToClaim();
        }
        LockInfo storage info = userToLockInfo[msg.sender];
        info.totalClaimed = info.totalClaimed + claimable;
        IERC20 dtec = IERC20(dtecTokenAddress);
        dtec.transfer(msg.sender, claimable);
    }

    function lockTokens(address _user, uint256 _amt) external {
        if (msg.sender != tokenLocker) {
            revert Unauthorized();
        }
        LockInfo storage info = userToLockInfo[_user];
        info.totalAmount += _amt;
    }
}
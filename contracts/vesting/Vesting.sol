// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Vesting is Ownable, ReentrancyGuard {
    mapping(address => LockInfo) public userToLockInfo;
    address public dtecTokenAddress;
    address public tokenLocker;
    uint256 public period = 30 days;
    uint256 public releaseRate;
    uint256 public lockStartTime;

    error Unauthorized();
    error NothingToClaim();
    error OutOfExpectedRange();

    struct LockInfo {
        uint256 totalAmount;
        uint256 totalClaimed;
    }

    constructor(address _dtecAddress) {
        dtecTokenAddress = _dtecAddress;
    }

    // Base rate 10000
    function setReleaseInfo(uint256 _startTime, uint256 _rate) internal onlyOwner {
        lockStartTime = _startTime;
        releaseRate = _rate;
    }

    function setPeriod(uint256 _period) internal onlyOwner {
        period = _period;
    }

    function lockTokens(address _user, uint256 _amt) external onlyOwner {
        LockInfo storage info = userToLockInfo[_user];
        info.totalAmount += _amt;
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
        uint256 totalClaimableSoFar = info.totalAmount * releaseRate * periodsPassed / 10000;
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
}

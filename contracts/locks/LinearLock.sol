// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ITokenLock} from "../interfaces/ITokenLock.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LinearLock is ITokenLock, Ownable, ReentrancyGuard {
    mapping(address => LockInfo) public userToLockInfo;
    address public immutable dtecTokenAddress;
    address public tokenLocker;
    uint256 public period = 30 days;
    uint256 public releaseRate;
    uint256 public lockStartTime;

    event ReleaseInfoSet(uint256 startTime, uint256 rate);
    event TokenLockerSet(address indexed locker);
    event PeriodSet(uint256 period);
    event Claimed(address indexed user, uint256 timestamp, uint256 claimedAmount, 
    uint256 totalClaimed, uint256 totalAmount);
    event TokensLocked(address indexed user, uint256 timestamp, uint256 amount);

    error Unauthorized();
    error NothingToClaim();
    error OutOfExpectedRange();

    struct LockInfo {
        uint256 totalAmount;
        uint256 totalClaimed;
    }

    constructor(address _dtecAddress) {
        require (_dtecAddress != address(0) , "Invalid address") ;
        dtecTokenAddress = _dtecAddress;
    }

    // Base rate 10000
    function setReleaseInfo(uint256 _startTime, uint256 _rate) public onlyOwner {
        require(_rate > 0 , "Value must be greater than zero.");
        lockStartTime = _startTime;
        releaseRate = _rate;
        emit ReleaseInfoSet(_startTime, _rate);
    }

    function setTokenLocker(address _locker) external onlyOwner {
        require (_locker != address(0) , "Invalid address") ;
        tokenLocker = _locker;
        emit TokenLockerSet(_locker);
    }

    function setPeriod(uint256 _period) external onlyOwner {
        require(_period > 0 , "Value must be greater than zero.");
        // This is for testing only but still we won't allow +30 days period
        if (_period > 30 days) {
            revert OutOfExpectedRange();
        }
        period = _period;
        emit PeriodSet(_period);
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
        emit Claimed(msg.sender, block.timestamp, claimable, info.totalClaimed, info.totalAmount);
    }

    function lockTokens(address _user, uint256 _amt) external {
        if (msg.sender != tokenLocker) {
            revert Unauthorized();
        }
        LockInfo storage info = userToLockInfo[_user];
        info.totalAmount += _amt;
        emit TokensLocked(_user, block.timestamp,_amt);
    }
}

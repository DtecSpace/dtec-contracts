// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ITokenLock} from "../interfaces/ITokenLock.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DataSharingVesting is ITokenLock, Ownable, ReentrancyGuard {
    mapping(address => LockInfo) public userToLockInfo;
    address public immutable dtecTokenAddress;
    uint256 public immutable lockStartTime;
    uint256 public constant period = 365 days;

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
        // TGE is 01.04.2024, first lock release for Data Sharing is 01.02.2025
        // To get tokens on time, release lockTimestamp is 1735776001, 30 days before 01.02.2025
        lockStartTime = 1735776001;
    }

    function getReleaseNumerator(uint256 _periods) internal pure returns (uint256) {
        uint256 _numerator = 0;
        // DataSharing vesting is first year %10 , second year %9.8, third year %9.6 etc..
        _numerator = _periods * 1000 - (20 * _periods * (_periods - 1) / 2);
        if (_numerator > 10000) {
            _numerator = 10000;
        }
        return _numerator;
    }

    function lockTokens(address _user, uint256 _amt) external onlyOwner {
        LockInfo storage info = userToLockInfo[_user];
        info.totalAmount += _amt;
        emit TokensLocked(_user, block.timestamp, _amt);
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
        emit Claimed(msg.sender, block.timestamp, claimable, info.totalClaimed, info.totalAmount);
    }
}

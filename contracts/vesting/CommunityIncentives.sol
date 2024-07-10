// SPDX-License-Identifier: MIT
/* 

        (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*                                               
        (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(                                     
        (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.                                
        (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,                             
        (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                           
                       #@@@@@@@@@@@/     .,&@@@@@@@@@@@@@@@@@@@                         
                       #@@@@@@@@@@@/            /@@@@@@@@@@@@@@@/                       
                       #@@@@@@@@@@@/               #@@@@@@@@@@@@@&                      
                                                     #@@@@@@@@@@@@&                     
                                                       @@@@@@@@@@@@(                    
        (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*        @@@@@@@@@@@@                    
        (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*        @@@@@@@@@@@@                    
        (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*        #@@@@@@@@@@@                    
        (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*        @@@@@@@@@@@@                    
        (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*        @@@@@@@@@@@@                    
                                                       @@@@@@@@@@@@/                    
                                                     %@@@@@@@@@@@@&                     
                       #@@@@@@@@@@@/               %@@@@@@@@@@@@@&                      
                       #@@@@@@@@@@@/            %@@@@@@@@@@@@@@@,                       
                       #@@@@@@@@@@@/     ,(@@@@@@@@@@@@@@@@@@@@                         
        (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&                           
        (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.                             
        (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                 
        (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*        
            


                ██████  ████████ ███████  ██████ 
                ██   ██    ██    ██      ██      
                ██   ██    ██    █████   ██      
                ██   ██    ██    ██      ██      
                ██████     ██    ███████  ██████ 
                                
                                 
@author:   Baris Arya CANTEPE  (@bcantepe)
*/
pragma solidity ^0.8.17;

import {ITokenLock} from "../interfaces/ITokenLock.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title CommunityIncentives
/// @dev Implements a token vesting mechanism specific to data sharing purposes, with a unique release schedule.
/// @notice This contract manages the vesting of tokens for data sharing participants, releasing them based on a predetermined schedule.
contract CommunityIncentives is ITokenLock, Ownable, ReentrancyGuard {
    /// @notice Stores vesting information for each participant
    mapping(address => LockInfo) public userToLockInfo;

    /// @notice Address of the DTEC token
    address public immutable dtecTokenAddress;

    /// @notice The start time of the lock
    uint256 public immutable lockStartTime;

    /// @notice The period for each vesting phase
    uint256 public constant period = 90 days;

    // Event declarations
    event Claimed(address indexed user, uint256 timestamp, uint256 claimedAmount, 
    uint256 totalClaimed, uint256 totalAmount);
    event TokensLocked(address indexed user, uint256 timestamp, uint256 amount);

    // Error declarations
    error NothingToClaim();

    /// @dev Struct to store total amount locked and total amount claimed for each user
    struct LockInfo {
        uint256 totalAmount;
        uint256 totalClaimed;
    }

    /// @notice Constructor to initialize the CommunityIncentives contract
    /// @param _dtecAddress Address of the DTEC token contract
    constructor(address _dtecAddress) {
        require (_dtecAddress != address(0) , "Invalid address") ;
        dtecTokenAddress = _dtecAddress;
        // TGE is 14.07.2024, first lock release for Data Sharing is 01.01.2025
        // To get tokens on time, release lockTimestamp is 1727913600, 90 days before 01.01.2025
        lockStartTime = 1727913600;
    }

    /// @notice Calculates the release numerator based on the number of periods passed
    /// @dev This function determines the fraction of tokens to be released after each period
    /// @param _periods The number of vesting periods that have passed
    /// @return The numerator representing the fraction of the total amount that should be released
    function getReleaseNumerator(uint256 _periods) internal pure returns (uint256) {
        uint256 _numerator = 0;
        // DataSharing vesting is first 90 days %6.9 , second 90 days %6.7, third 90 days %6.5 etc..
        _numerator = _periods * 690 - (20 * _periods * (_periods - 1) / 2);
        if (_numerator > 10000) {
            _numerator = 10000;
        }
        return _numerator;
    }

    /// @notice Locks a specified amount of tokens for vesting for a given user
    /// @param _user Address of the user whose tokens are to be locked
    /// @param _amt Amount of tokens to lock for vesting
    function lockTokens(address _user, uint256 _amt) external onlyOwner {
        LockInfo storage info = userToLockInfo[_user];
        info.totalAmount += _amt;
        emit TokensLocked(_user, block.timestamp, _amt);
    }

    /// @notice Calculates the amount of tokens claimable by a user at the current time
    /// @param _user Address of the user
    /// @return Amount of tokens that the user can claim
    function getClaimable(address _user) public view returns (uint256) {
        LockInfo memory info = userToLockInfo[_user];
        if (info.totalClaimed == info.totalAmount || block.timestamp < lockStartTime) {
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

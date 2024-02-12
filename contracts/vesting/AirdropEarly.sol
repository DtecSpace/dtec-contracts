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

/// @title EarlyAirdrop
/// @dev Implements a token vesting mechanism where tokens are locked and released linearly over time.
/// @notice This contract is used to manage the vesting of early airdrop tokens, allowing users to claim their vested tokens over a period.
contract EarlyAirdrop is ITokenLock, Ownable, ReentrancyGuard {
    /// @notice Stores vesting information for each participant
    mapping(address => LockInfo) public userToLockInfo;

    ///@notice Stores airdrop users in an array
    address[] public airdropUsers ; 

    /// @notice Address of the DTEC token
    address public immutable dtecTokenAddress;

    /// @notice The start time of the lock
    uint256 public immutable lockStartTime;

    /// @notice The period for each vesting phase
    uint256 public constant period = 30 days;

    /// @notice The rate at which tokens are released per period
    uint256 public immutable releaseRate;

    /// @notice The rate at which tokens are released per period
    uint256 public immutable tgeReleaseRate;

    // Event declarations
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

    /// @notice Constructor to initialize the EarlyAirdrop contract
    /// @param _dtecAddress Address of the DTEC token contract
    constructor(address _dtecAddress) {
        require (_dtecAddress != address(0) , "Invalid address") ;
        dtecTokenAddress = _dtecAddress;
        // TGE is 01.04.2024, first lock release for Early Airdrop is 01.02.2025
        // To get tokens on time, release lockTimestamp is 1735776001, 30 days before 01.02.2025
        lockStartTime = 1735776001;

        // In TGE %15 of the tokens will be released
        tgeReleaseRate = 1500;

        // Early airdrop vestings will be completed in 4 months, release rate is based 10,000.    
        releaseRate = 2125; 
    }

    /// @notice Locks a specified amount of tokens for vesting for a given user
    /// @param _user Address of the user whose tokens are to be locked
    /// @param _amt Amount of tokens to lock for vesting
    function _lock (address _user, uint256 _amt) internal {
        LockInfo storage info = userToLockInfo[_user];
        if (info.totalAmount == 0 ) {
            airdropUsers.push(_user);
        } 
        info.totalAmount += _amt;
        emit TokensLocked(_user, block.timestamp, _amt);
    }

    /// @notice Locks a specified amount of tokens for vesting for a given user
    /// @param _user Address of the user whose tokens are to be locked
    /// @param _amt Amount of tokens to lock for vesting
    function lockTokens(address _user, uint256 _amt) external onlyOwner {
        _lock(_user, _amt);
    }

    /// @notice Locks a specified amount of tokens for vesting for a given user
    /// @param _users Address array of the users whose tokens are to be locked
    /// @param _amts Amounts array of tokens to lock for vesting
    function lockTokensMultiple(address[] calldata _users, uint256[] calldata _amts) external onlyOwner {
        require(_users.length == _amts.length , "Arrays must have same length");

        for (uint256 i = 0; i < _users.length; i++) {
            _lock(_users[i], _amts[i]);
        }
    }

    /// @notice Calculates the amount of tokens claimable by a user at the current time
    /// @param _user Address of the user
    /// @return Amount of tokens that the user can claim
    function getClaimable(address _user) public view returns (uint256) {
        LockInfo memory info = userToLockInfo[_user];
        if (info.totalClaimed == info.totalAmount || lockStartTime == 0 ) {
            return 0;
        }
        uint256 totalClaimableSoFar;

        if ( block.timestamp < lockStartTime) {
            totalClaimableSoFar = info.totalAmount * tgeReleaseRate / 10000; 
        } else {
            uint256 timePassed = block.timestamp - lockStartTime;
            uint256 periodsPassed = timePassed / period;
            totalClaimableSoFar = info.totalAmount * (tgeReleaseRate + (releaseRate * periodsPassed) ) / 10000;
        }

        if (totalClaimableSoFar > info.totalAmount) {
            totalClaimableSoFar = info.totalAmount;
        }
        return totalClaimableSoFar - info.totalClaimed;
    }

    /// @notice Allows users to claim their vested tokens
    /// @param _user the user which will claim tokens
    function _claim(address _user) internal {
        uint256 claimable = getClaimable(_user);
        if (claimable == 0) {
            revert NothingToClaim();
        }
        LockInfo storage info = userToLockInfo[_user];
        info.totalClaimed = info.totalClaimed + claimable;
        IERC20 dtec = IERC20(dtecTokenAddress);
        dtec.transfer(_user, claimable);
        emit Claimed(_user, block.timestamp, claimable, info.totalClaimed, info.totalAmount);
    }

    /// @notice Allows users to claim their vested tokens
    function claim() external nonReentrant {
        _claim(msg.sender);
    }

    /// @notice Allows users to claim external addresses vested tokens
    function claimToUsers(address[] calldata _adresses) external nonReentrant {
        for (uint256 i = 0; i < _adresses.length; i++) {
            _claim(_adresses[i]);
        }
    }
}

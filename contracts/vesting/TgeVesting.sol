// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ITokenLock} from "../interfaces/ITokenLock.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title TgeVestingBase
/// @dev Implements a token vesting mechanism where tokens are locked and released with TGE, linearly over time.
/// @notice This base contract is used to manage the vestings, allowing users or external users to claim their vested tokens over a period.
contract TgeVestingBase is ITokenLock, Ownable, ReentrancyGuard {
    /// @notice Stores vesting information for each participant
    mapping(address => LockInfo) public userToLockInfo;

    ///@notice Stores users in an array
    address[] public vestingUsers ; 

    ///@notice The total locked amount of DTEC Token
    uint256 public totalLocked ; 

    ///@notice The maximum locked amount of DTEC Token
    uint256 public immutable maxLockedTokenAmount ; 

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
    error NothingToClaim();

    /// @dev Struct to store total amount locked and total amount claimed for each user
    struct LockInfo {
        uint256 totalAmount;
        uint256 totalClaimed;
    }

    /// @notice Constructor to initialize the base TgeVesting contract
    /// @param _dtecAddress Address of the DTEC token contract
    /// @param _lockStartTime Timestamp of vesting start
    /// @param _tgeReleaseRate Percentage of tokens will be released at TGE, based 10000
    /// @param _releaseRate Percentage of tokens will be released each period, based 10000
    /// @param _vestingAmount Maximum reachable vesting token amount. In wei format.
    constructor(address _dtecAddress, uint256 _lockStartTime, uint256 _tgeReleaseRate, uint256 _releaseRate, uint256 _vestingAmount ) {
        require (_dtecAddress != address(0) , "Invalid address") ;
        require (_lockStartTime != 0 , "Lock start can't be equal to zero") ;
        

        dtecTokenAddress = _dtecAddress;
        lockStartTime = _lockStartTime ;
        tgeReleaseRate = _tgeReleaseRate;
        releaseRate = _releaseRate; 
        maxLockedTokenAmount = _vestingAmount * 1e18;
    }

    /// @notice Locks a specified amount of tokens for vesting for a given user
    /// @param _user Address of the user whose tokens are to be locked
    /// @param _amt Amount of tokens to lock for vesting
    function _lock (address _user, uint256 _amt) internal {
        require (_user != address(0) , "Invalid address") ;
        require (_amt > 0 , "Zero amount is given.") ;

        LockInfo storage info = userToLockInfo[_user];
        if (info.totalAmount == 0 ) {
            vestingUsers.push(_user);
        } 
        info.totalAmount += _amt;
        totalLocked += _amt;
        require(totalLocked <= maxLockedTokenAmount, "Vesting amount reached.");
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
        if (info.totalClaimed == info.totalAmount ) {
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

    function getVestingUsers(uint256 _paginationStart, uint256 _paginationEnd ) external view returns (address[] memory, uint256){
        require(vestingUsers.length > 0 , "Nothing to return");
        require(_paginationStart < _paginationEnd, "Should give a range");
        if (_paginationEnd > vestingUsers.length) {
            _paginationEnd = vestingUsers.length;
        }

        address[] memory _vestingUsers = new address[](_paginationEnd - _paginationStart);
        uint256 i;
        for (_paginationStart; _paginationStart < _paginationEnd ; _paginationStart++) 
        {
            _vestingUsers[i] = vestingUsers[_paginationStart];
            i += 1;
        }
        return (_vestingUsers , _paginationEnd);
    }
}

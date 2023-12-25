// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ITokenLock} from "./interfaces/ITokenLock.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title DTECTokenSale
/// @dev This contract implements a token sale process with features like pausing, reentrancy protection, and fund allocation.
/// @notice This contract does not handle token minting but manages the sale and allocation of existing tokens.
abstract contract DTECTokenSale is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Sale price of the tokens
    uint256 public salePrice;

    /// @dev Tracks moderator addresses
    mapping(address => uint8) private mods;

    /// @notice Allocation information for each address
    mapping(address => uint256) public allocations;

    /// @dev Total number of tokens allocated
    uint256 totalAllocated;

    /// @notice Address of the lock contract
    address public immutable lockerAddress;

    /// @notice Address of the DTEC token
    address public immutable dtecTokenAddress;

    /// @dev Address where funds are sent
    address private paymentReceiver;

    /// @notice Immediate release rate of tokens upon purchase based 10000
    uint256 public immediateReleaseRate;

    /// @dev USDC token address
    address public USDC = 0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359;
    
    /// @dev USDT token address
    address public USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

    /// @notice Amount of tokens sold
    uint256 public amountSold;

    // Events declaration
    event ModsAdded(address[] mods);
    event PausedToggled(bool isPaused);
    event ImmediateReleaseRateSet(uint256 rate);
    event PaymentReceiverSet(address receiver);
    event SalePriceSet(uint256 price);
    event TokensPulled(uint256 amount);
    event TokensBought(address indexed user, uint256 timestamp, uint256 totalAmount,
    uint256 releasedAmount, uint256 lockedAmount, bool preferUSDC);
    event TokensAllocated(address indexed user, uint256 timestamp, uint256 amount, bool preferUSDC);
    event AllocationClaimed(address indexed oldUser, address indexed newUser, uint256 timestamp, 
    uint256 totalAllocation, uint256 releasedAmount, uint256 lockedAmount);

    /// @dev Error used to indicate that a purchase operation cannot be performed
    error CantBuy();

    /// @notice Constructor that initializes the contract
    /// @param _receiver The address where funds are sent
    /// @param _dtecAddress The address of the DTEC token
    /// @param _lockerAddress The address of the lock contract
    constructor(address _receiver, address _dtecAddress, address _lockerAddress) {
        require (_receiver != address(0) && _dtecAddress != address(0) 
        && _lockerAddress != address(0) , "Invalid address") ;
        paymentReceiver = _receiver;
        dtecTokenAddress = _dtecAddress;
        lockerAddress = _lockerAddress;
        mods[msg.sender] = 1; // Add owner as mod
        _pause();
    }

    /// @notice Adds a new mod
    /// @dev Only callable by the owner
    /// @param _mods Array of addresses to be added as mods
    function addMods(address[] calldata _mods) external onlyOwner {
        for (uint256 i = 0; i < _mods.length; i++) {
            require (_mods[i] != address(0) , "Invalid address") ;
            mods[_mods[i]] = 1;
        }
        emit ModsAdded(_mods);
    }

    /// @dev Checks if an address is a mod
    /// @param _adr Address to check
    /// @return True if the address is a mod, false otherwise
    function isMod(address _adr) internal view returns (bool) {
        return mods[_adr] == 1;
    }

    /// @notice Toggles the pause state of the contract
    /// @dev Only callable by the owner
    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
        emit PausedToggled(paused());
    }

    /// @notice Sets the immediate release rate for token sales
    /// @dev Only callable by the owner
    /// @param _rate The immediate release rate as a percentage (multiplied by 10000 for precision)
    function setImmediateReleaseRate(uint256 _rate) public onlyOwner {
        immediateReleaseRate = _rate;
        emit ImmediateReleaseRateSet(_rate);
    }

    /// @notice Sets the payment receiver address
    /// @dev Only callable by the owner
    /// @param _receiver The address to receive sale funds
    function setPaymentReceiver(address _receiver) external onlyOwner {
        require (_receiver != address(0) , "Invalid address") ;
        paymentReceiver = _receiver;
        emit PaymentReceiverSet(_receiver);
    }

    /// @notice Sets the sale price for tokens
    /// @dev Only callable by the owner
    /// @param _price Price per token
    function setSalePrice(uint256 _price) public onlyOwner {
        require(_price > 0 , "Value must be greater than zero.");
        salePrice = _price;
        emit SalePriceSet(_price);
    }

    /// @notice Allows the owner to pull unsold/unallocated tokens from the contract
    /// @dev Only callable by the owner
    /// @param _amt Amount of tokens to pull
    function pullTokens(uint256 _amt) public onlyOwner {
        IERC20 dtec = IERC20(dtecTokenAddress);
        uint256 availableBalance = dtec.balanceOf(address(this)) - totalAllocated;
        require(_amt <= availableBalance , "Insufficient unallocated tokens");
        dtec.transfer(owner(), _amt);
        emit TokensPulled(_amt);
    }

    /// @notice Calculates the cost to buy a specified amount of tokens
    /// @param _amt Amount of tokens
    /// @return Cost to buy the specified amount of tokens
    function getBuyCost(uint256 _amt) external view returns (uint256) {
        return _amt * salePrice;
    }

    /// @notice Calculates the release and lock amounts for a given token amount
    /// @dev Used internally to determine how many tokens should be immediately released and how many locked
    /// @param amtInWei The amount of tokens in Wei
    /// @return releaseAmount The amount to be released immediately
    /// @return lockAmount The amount to be locked
    function calculateReleaseAmounts(uint256 amtInWei) internal view returns (uint256, uint256) {
        uint256 lockAmount = amtInWei;
        uint256 releaseAmount = 0;
        if (immediateReleaseRate > 0) {
            releaseAmount = amtInWei * immediateReleaseRate / 10000;
            lockAmount = amtInWei - releaseAmount;
        }
        return (releaseAmount, lockAmount);
    }

    /// @notice Transfers funds and calculates the release and lock amounts
    /// @dev Handles the fund transfer for a token purchase and calculates token distribution
    /// @param _user Address of the user buying the tokens
    /// @param _amt Amount of tokens the user is buying
    /// @param _preferUSDC Boolean indicating whether to use USDC or USDT for payment
    /// @return releaseAmount Amount of tokens to be released immediately
    /// @return lockAmount Amount of tokens to be locked
    /// @return amtInWei Total amount of tokens in Wei
    function transferFundsAndCalculateReleaseAmounts(address _user, uint256 _amt, bool _preferUSDC) internal returns (uint256, uint256, uint256) {
        if (_amt == 0) {
            revert CantBuy();
        }
        uint256 amtInWei = _amt * 1 ether;
        uint256 availableBalance = IERC20(dtecTokenAddress).balanceOf(address(this)) - totalAllocated;
        if (amtInWei > availableBalance) {
            revert CantBuy();
        }
        // _amt is in ether
        IERC20 stable = IERC20(_preferUSDC ? USDC : USDT);
        uint256 stablePaymentAmount = _amt * salePrice; // Sale price is in wei so do not convert this
        stable.safeTransferFrom(_user, paymentReceiver, stablePaymentAmount);
        (uint256 releaseAmount, uint256 lockAmount) = calculateReleaseAmounts(amtInWei);
        return (releaseAmount, lockAmount, amtInWei);
    }

    /// @notice Buys and locks tokens for a user
    /// @dev Used internally to handle the token buying and locking mechanism
    /// @param _user Address of the user buying the tokens
    /// @param _amt Amount of tokens to buy
    /// @param _preferUSDC Boolean indicating whether to use USDC or USDT for payment
    function buyAndLockTokens(address _user, uint256 _amt, bool _preferUSDC) internal whenNotPaused {
        (uint256 releaseAmount, uint256 lockAmount, ) =
            transferFundsAndCalculateReleaseAmounts(_user, _amt, _preferUSDC);
        IERC20 dtec = IERC20(dtecTokenAddress);
        dtec.transfer(lockerAddress, lockAmount);
        ITokenLock tokenLock = ITokenLock(lockerAddress);
        tokenLock.lockTokens(_user, lockAmount);
        // Release to user
        if (releaseAmount > 0) {
            dtec.transfer(_user, releaseAmount);
        }
        amountSold += _amt;
        emit TokensBought(_user, block.timestamp, _amt, releaseAmount, lockAmount, _preferUSDC);
    }

    /// @notice Allocates tokens for a non-Web3 user
    /// @dev Used internally to allocate tokens for users without direct blockchain interaction
    /// @param _user Address of the user to whom tokens are being allocated
    /// @param _amt Amount of tokens to allocate
    /// @param _preferUSDC Boolean indicating whether to use USDC or USDT for payment
    function nonWeb3UserAllocate(address _user, uint256 _amt, bool _preferUSDC) internal whenNotPaused {
        (, , uint256 amtInWei) =
            transferFundsAndCalculateReleaseAmounts(_user, _amt, _preferUSDC);
        allocations[_user] += amtInWei;
        totalAllocated += amtInWei;
        amountSold += _amt;
        emit TokensAllocated(_user, block.timestamp, amtInWei, _preferUSDC);
    }

    /// @notice Allows a user to claim their token allocation
    /// @dev Handles the allocation claiming process for users
    /// @param _to Address where the released tokens should be sent and lock contract keeps for vesting
    function claimAllocation(address _to) external {
        require (_to != address(0) , "Invalid address") ;
        uint256 allocation = allocations[msg.sender];
        if (allocation == 0) {
            revert CantBuy();
        }
        (uint256 releaseAmount, uint256 lockAmount) = calculateReleaseAmounts(allocation);
        allocations[msg.sender] = 0;
        totalAllocated -= allocation;
        IERC20 dtec = IERC20(dtecTokenAddress);
        dtec.transfer(lockerAddress, lockAmount);
        ITokenLock tokenLock = ITokenLock(lockerAddress);
        tokenLock.lockTokens(_to, lockAmount);
        // Release to user
        if (releaseAmount > 0) {
            dtec.transfer(_to, releaseAmount);
        }
        emit AllocationClaimed(msg.sender, _to, block.timestamp, allocation, releaseAmount, lockAmount);
    }

    /// @notice Abstract function for buying tokens
    /// @dev To be implemented in a derived contract
    /// @param _amt Amount of tokens to buy
    /// @param _preferUSDC Boolean indicating whether to use USDC or USDT for payment
    function buyTokens(uint256 _amt, bool _preferUSDC) external virtual;

    /// @notice Abstract function for allocating tokens
    /// @dev To be implemented in a derived contract
    /// @param _amt Amount of tokens to allocate
    /// @param _preferUSDC Boolean indicating whether to use USDC or USDT for payment
    function allocateTokens(uint256 _amt, bool _preferUSDC) external virtual;
}

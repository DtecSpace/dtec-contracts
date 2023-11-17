// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ITokenLock} from "./interfaces/ITokenLock.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract DTECTokenSale is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public salePrice;

    mapping(address => uint8) private mods;
    mapping(address => uint256) public allocations;
    uint256 totalAllocated;

    address public immutable lockerAddress;
    address public immutable dtecTokenAddress;
    address private paymentReceiver;
    uint256 public immediateReleaseRate;
    address public USDC = 0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359;
    address public USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

    uint256 public amountSold;

    error CantBuy();

    constructor(address _receiver, address _dtecAddress, address _lockerAddress) {
        require (_receiver != address(0) && _dtecAddress != address(0) 
        && _lockerAddress != address(0) , "Invalid address") ;
        paymentReceiver = _receiver;
        dtecTokenAddress = _dtecAddress;
        lockerAddress = _lockerAddress;
        mods[msg.sender] = 1; // Add owner as mod
        _pause();
    }

    function addMods(address[] calldata _mods) external onlyOwner {
        for (uint256 i = 0; i < _mods.length; i++) {
            require (_mods[i] != address(0) , "Invalid address") ;
            mods[_mods[i]] = 1;
        }
    }

    function isMod(address _adr) internal view returns (bool) {
        return mods[_adr] == 1;
    }

    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function setImmediateReleaseRate(uint256 _rate) public onlyOwner {
        immediateReleaseRate = _rate;
    }

    function setPaymentReceiver(address _receiver) external onlyOwner {
        require (_receiver != address(0) , "Invalid address") ;
        paymentReceiver = _receiver;
    }

    function setSalePrice(uint256 _price) public onlyOwner {
        require(_price > 0 , "Value must be greater than zero.");
        salePrice = _price;
    }

    function pullTokens(uint256 _amt) public onlyOwner {
        IERC20 dtec = IERC20(dtecTokenAddress);
        dtec.transfer(owner(), _amt);
    }

    function getBuyCost(uint256 _amt) external view returns (uint256) {
        return _amt * salePrice;
    }

    function calculateReleaseAmounts(uint256 amtInWei) internal view returns (uint256, uint256) {
        uint256 lockAmount = amtInWei;
        uint256 releaseAmount = 0;
        if (immediateReleaseRate > 0) {
            releaseAmount = amtInWei * immediateReleaseRate / 10000;
            lockAmount = amtInWei - releaseAmount;
        }
        return (releaseAmount, lockAmount);
    }

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
    }

    function nonWeb3UserAllocate(address _user, uint256 _amt, bool _preferUSDC) internal whenNotPaused {
        (, , uint256 amtInWei) =
            transferFundsAndCalculateReleaseAmounts(_user, _amt, _preferUSDC);
        allocations[_user] += amtInWei;
        totalAllocated += amtInWei;
        amountSold += _amt;
    }

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
    }

    function buyTokens(uint256 _amt, bool _preferUSDC) external virtual;
    function allocateTokens(uint256 _amt, bool _preferUSDC) external virtual;
}

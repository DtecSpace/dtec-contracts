// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {DTECTokenSale} from './DTECTokenSale.sol';

contract DTECPrivateSale is DTECTokenSale {
    uint256 public constant MIN_TOKENS_TO_BUY = 71428;
    uint256 public constant MAX_TOKENS_TO_BUY = 1428572;

    mapping(address => uint8) public wl;
    mapping(address => uint256) public addressToBoughtAmt;

    event WlsAdded(address[] wls);

    error Unauthorized();
    error OverUnderAllowedAmt();

    constructor(address _receiver, address _dtecAddress, address _lockerAddress) DTECTokenSale(_receiver, _dtecAddress, _lockerAddress) {
        setImmediateReleaseRate(100);
        setSalePrice(0.07 ether);
    }

    function addWLs(address[] calldata _wallets) external {
        if (!isMod(msg.sender)) {
            revert Unauthorized();
        }
        for (uint256 i = 0; i < _wallets.length; i++) {
            require (_wallets[i] != address(0) , "Invalid address") ;
            wl[_wallets[i]] = 1;
        }
        emit WlsAdded(_wallets);
    }

    function buyTokens(uint256 _amt, bool _preferUSDC) external override nonReentrant {
        if (wl[msg.sender] != 1) {
            revert CantBuy();
        }
        if (_amt < MIN_TOKENS_TO_BUY) {
            revert OverUnderAllowedAmt();
        }
        addressToBoughtAmt[msg.sender] = addressToBoughtAmt[msg.sender] + _amt;
        if (addressToBoughtAmt[msg.sender] > MAX_TOKENS_TO_BUY) {
            revert OverUnderAllowedAmt();
        }
        buyAndLockTokens(msg.sender, _amt, _preferUSDC);
    }

    function allocateTokens(uint256 _amt, bool _preferUSDC) external override nonReentrant {
        if (wl[msg.sender] != 1) {
            revert CantBuy();
        }
        if (_amt < MIN_TOKENS_TO_BUY) {
            revert OverUnderAllowedAmt();
        }
        addressToBoughtAmt[msg.sender] = addressToBoughtAmt[msg.sender] + _amt;
        if (addressToBoughtAmt[msg.sender] > MAX_TOKENS_TO_BUY) {
            revert OverUnderAllowedAmt();
        }
        nonWeb3UserAllocate(msg.sender, _amt, _preferUSDC);
    }
}

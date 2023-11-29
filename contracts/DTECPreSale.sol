// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {DTECTokenSale} from './DTECTokenSale.sol';

contract DTECPreSale is DTECTokenSale {
    uint256 public constant MIN_TOKENS_TO_BUY = 3700;
    uint256 public constant MAX_TOKENS_TO_BUY = 375000;
    uint256 public constant MIN_TOKENS_TO_ADDITION_BUY = 1200; 

    mapping(address => uint256) addressToBoughtAmt;

    error OverUnderAllowedAmt();

    constructor(address _receiver, address _dtecAddress, address _lockerAddress) DTECTokenSale(_receiver, _dtecAddress, _lockerAddress) {
        setImmediateReleaseRate(300); // Corresponding %3 at TGE
        setSalePrice(80000); // Corresponding 0.08 USD, USDC and USDT have 6 decimals 
    }

    function buyTokens(uint256 _amt, bool _preferUSDC) external override nonReentrant {
        if (_amt < MIN_TOKENS_TO_BUY) {
            if (addressToBoughtAmt[msg.sender] == 0 || _amt < MIN_TOKENS_TO_ADDITION_BUY) {
                revert OverUnderAllowedAmt();
            }
        }
        addressToBoughtAmt[msg.sender] = addressToBoughtAmt[msg.sender] + _amt;
        if (addressToBoughtAmt[msg.sender] > MAX_TOKENS_TO_BUY) {
            revert OverUnderAllowedAmt();
        }
        buyAndLockTokens(msg.sender, _amt, _preferUSDC);
    }

    function allocateTokens(uint256 _amt, bool _preferUSDC) external override nonReentrant {
        if (_amt < MIN_TOKENS_TO_BUY) {
            if (addressToBoughtAmt[msg.sender] == 0 || _amt < MIN_TOKENS_TO_ADDITION_BUY) {
                revert OverUnderAllowedAmt();
            }
        }
        addressToBoughtAmt[msg.sender] = addressToBoughtAmt[msg.sender] + _amt;
        if (addressToBoughtAmt[msg.sender] > MAX_TOKENS_TO_BUY) {
            revert OverUnderAllowedAmt();
        }
        nonWeb3UserAllocate(msg.sender, _amt, _preferUSDC);
    }
}

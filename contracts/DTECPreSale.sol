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

import {DTECTokenSale} from './DTECTokenSale.sol';

/// @title DTECPreSale
/// @dev Extends DTECTokenSale for the presale phase with specific minimum, maximum, and additional purchase limits.
/// @notice This contract allows for presale of tokens with specific purchase requirements and limits.
contract DTECPreSale is DTECTokenSale {
    /// @notice Minimum amount of tokens a user can buy in first buy
    uint256 public constant MIN_TOKENS_TO_BUY = 13000;

    /// @notice Maximum amount of tokens a user can buy in total
    uint256 public constant MAX_TOKENS_TO_BUY = 5263000;

    /// @notice Minimum tokens to buy for additional purchases (after the first buy)
    uint256 public constant MIN_TOKENS_TO_ADDITION_BUY = 7800; 

    /// @dev Mapping to track the amount of tokens bought by each address
    mapping(address => uint256) public addressToBoughtAmt;

    // Error declaration
    error OverUnderAllowedAmt();

    /// @notice Constructor to initialize the presale contract
    /// @param _receiver Address where sale funds will be sent
    /// @param _dtecAddress Address of the DTEC token
    /// @param _lockerAddress Address of the locker contract
    constructor(address _receiver, address _dtecAddress, address _lockerAddress) DTECTokenSale(_receiver, _dtecAddress, _lockerAddress) {
        setImmediateReleaseRate(300); // Corresponding %3 at TGE
        setSalePrice(38000); // Corresponding 0.038 USD, USDC and USDT have 6 decimals 
    }

    /// @notice Allows a user to buy tokens with specific minimum and maximum limits
    /// @dev Overrides buyTokens from DTECTokenSale and includes checks for presale-specific purchase limits
    /// @param _amt Amount of tokens to buy
    /// @param _preferUSDC Boolean indicating whether to use USDC or USDT for payment
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

    /// @notice Allows a user to allocate tokens with specific minimum and maximum limits
    /// @dev Overrides allocateTokens from DTECTokenSale and adds checks for presale-specific allocation limits
    /// @param _amt Amount of tokens to allocate
    /// @param _preferUSDC Boolean indicating whether to use USDC or USDT for payment
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

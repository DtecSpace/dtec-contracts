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

/// @title DTECPublicSale
/// @dev Extends DTECTokenSale to implement a public sale phase with specific minimum and maximum purchase limits.
/// @notice This contract allows public users to buy or allocate tokens with restrictions on the minimum and maximum amounts.
contract DTECPublicSale is DTECTokenSale {
    /// @notice Minimum amount of tokens a user can buy or allocate in one transaction
    uint256 public constant MIN_TOKENS_TO_BUY = 980;

    /// @notice Maximum amount of tokens a user can buy or allocate in total
    uint256 public constant MAX_TOKENS_TO_BUY = 100000;

    /// @dev Mapping to track the amount of tokens bought by each address
    mapping(address => uint256) public addressToBoughtAmt;

    // Error declaration
    error OverUnderAllowedAmt();

    /// @notice Constructor to initialize the public sale contract
    /// @param _receiver Address where sale funds will be sent
    /// @param _dtecAddress Address of the DTEC token
    /// @param _lockerAddress Address of the locker contract
    constructor(address _receiver, address _dtecAddress, address _lockerAddress) DTECTokenSale(_receiver, _dtecAddress, _lockerAddress) {
        setImmediateReleaseRate(1500); // Corresponding %10 at TGE
        setSalePrice(100000); // Corresponding 0.10 USD, USDC and USDT have 6 decimals 
    }

    /// @notice Allows a user to buy tokens with restrictions on the purchase amount
    /// @dev Overrides buyTokens from DTECTokenSale and includes logic for minimum and maximum purchase amounts
    /// @param _amt Amount of tokens to buy
    /// @param _preferUSDC Boolean indicating whether to use USDC or USDT for payment
    function buyTokens(uint256 _amt, bool _preferUSDC) external override nonReentrant {
        if (_amt < MIN_TOKENS_TO_BUY) {
            revert OverUnderAllowedAmt();
        }
        addressToBoughtAmt[msg.sender] = addressToBoughtAmt[msg.sender] + _amt;
        if (addressToBoughtAmt[msg.sender] > MAX_TOKENS_TO_BUY) {
            revert OverUnderAllowedAmt();
        }
        buyAndLockTokens(msg.sender, _amt, _preferUSDC);
    }

    /// @notice Allows a user to allocate tokens with restrictions on the allocation amount
    /// @dev Overrides allocateTokens from DTECTokenSale and adds checks for minimum and maximum allocation limits
    /// @param _amt Amount of tokens to allocate
    /// @param _preferUSDC Boolean indicating whether to use USDC or USDT for payment
    function allocateTokens(uint256 _amt, bool _preferUSDC) external override nonReentrant {
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

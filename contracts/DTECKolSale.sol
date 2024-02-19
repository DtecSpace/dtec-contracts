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

/// @title DTECKolSale
/// @dev Extends DTECTokenSale for the KOL Round with specific minimum, maximum, and additional purchase limits.
/// @notice This contract allows for KOL-Round of tokens with specific purchase requirements and limits.
contract DTECKolSale is DTECTokenSale {
    /// @notice Minimum amount of tokens a user can buy in first buy
    uint256 public constant MIN_TOKENS_TO_BUY = 5550;

    /// @notice Maximum amount of tokens a user can buy in total
    uint256 public constant MAX_TOKENS_TO_BUY = 3333333;

    /// @notice Minimum tokens to buy for additional purchases (after the first buy)
    uint256 public constant MIN_TOKENS_TO_ADDITION_BUY = 3333; 

    /// @dev Mapping to track whitelisted addresses
    mapping(address => uint8) public wl;

    /// @dev Mapping to track the amount of tokens bought by each address
    mapping(address => uint256) public addressToBoughtAmt;

    // Event declaration
    event WlsAdded(address[] wls);

    // Error declarations
    error Unauthorized();
    error OverUnderAllowedAmt();

    /// @notice Constructor to initialize the KOL-Round contract
    /// @param _receiver Address where sale proceeds will be sent
    /// @param _dtecAddress Address of the DTEC token
    /// @param _lockerAddress Address of the lock contract
    constructor(address _receiver, address _dtecAddress, address _lockerAddress) DTECTokenSale(_receiver, _dtecAddress, _lockerAddress) {
        setImmediateReleaseRate(1000); // Corresponding %10 at TGE
        setSalePrice(90000); // Corresponding 0.090 USD, USDC and USDT have 6 decimals 
    }
    /// @notice Adds addresses to the whitelist
    /// @dev Only callable by moderators
    /// @param _wallets Array of addresses to be added to the whitelist
    function addWLs(address[] calldata _wallets) public {
        if (!isMod(msg.sender)) {
            revert Unauthorized();
        }
        for (uint256 i = 0; i < _wallets.length; i++) {
            require (_wallets[i] != address(0) , "Invalid address") ;
            wl[_wallets[i]] = 1;
        }
        emit WlsAdded(_wallets);
    }

    /// @notice Allows a whitelisted user to buy tokens with specific minimum and maximum limits
    /// @dev Overrides buyTokens from DTECTokenSale and includes checks for KOL-Round-specific purchase limits
    /// @param _amt Amount of tokens to buy
    /// @param _preferUSDC Boolean indicating whether to use USDC or USDT for payment
    function buyTokens(uint256 _amt, bool _preferUSDC) external override nonReentrant {
        if (wl[msg.sender] != 1) {
            revert CantBuy();
        }
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
    /// @dev Overrides allocateTokens from DTECTokenSale and adds checks for KOL-Round-specific allocation limits
    /// @param _amt Amount of tokens to allocate
    /// @param _preferUSDC Boolean indicating whether to use USDC or USDT for payment
    function allocateTokens(uint256 _amt, bool _preferUSDC) external override nonReentrant {
        if (wl[msg.sender] != 1) {
            revert CantBuy();
        }
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

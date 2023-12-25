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
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title DTECPrivateSale
/// @dev This contract extends DTECTokenSale for a private sale phase, with specific minimum and maximum purchase amounts and whitelist functionality.
/// @notice This contract includes functionality for whitelisting users, buying and allocating tokens, and migrating users from an old sale contract.
contract DTECPrivateSale is DTECTokenSale {

    /// @notice Minimum amount of tokens a user can buy in first buy
    uint256 public constant MIN_TOKENS_TO_BUY = 83200;

    /// @notice Maximum amount of tokens a user can buy in total
    uint256 public constant MAX_TOKENS_TO_BUY = 5000000;

    /// @notice Minimum tokens to buy for additional purchases (after the first buy)
    uint256 public constant MIN_TOKENS_TO_ADDITION_BUY = 33200; 

    /// @dev Indicates if user migration from the old contract has been completed
    bool migrated = false;

    /// @notice Address of the old sale contract for migration purposes
    address public immutable oldSaleContractAddress;

    /// @dev Mapping to track whitelisted addresses
    mapping(address => uint8) public wl;

    /// @dev Mapping to track the amount of tokens bought by each address
    mapping(address => uint256) public addressToBoughtAmt;

    // Event declarations
    event WlsAdded(address[] wls);
    event MigrationMade (address[] migratedUsers , uint256 timestamp, uint256 migratedTokenAmount);

    // Error declarations
    error Unauthorized();
    error OverUnderAllowedAmt();

    /// @notice Constructor to initialize the private sale contract
    /// @param _receiver Address where sale funds will be sent
    /// @param _dtecAddress Address of the DTEC token
    /// @param _lockerAddress Address of the lock contract
    constructor(address _receiver, address _dtecAddress, address _lockerAddress) DTECTokenSale(_receiver, _dtecAddress, _lockerAddress) {
        setImmediateReleaseRate(100); // Corresponding %1 at TGE
        setSalePrice(60000); // Corresponding 0.06 USD, USDC and USDT have 6 decimals 
        
        oldSaleContractAddress = 0xa40CDB7595fb14F932F56EaA6Aa00E5062B8aa08;
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

    /// @notice Allows a whitelisted user to buy tokens
    /// @dev Overrides buyTokens from DTECTokenSale and includes additional logic for minimum and maximum purchase amounts
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

    /// @notice Allows a whitelisted user to allocate tokens for non-Web3 users
    /// @dev Overrides allocateTokens from DTECTokenSale with additional checks for purchase limits
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

    /// @notice Migrates users from an old sale contract to this one
    /// @dev Only callable by the owner and can only be executed once
    /// @param users Array of user addresses to migrate from the old contract
    function migrateOldUsers (address[] calldata users ) external onlyOwner nonReentrant {

        require(migrated == false , "Migration can only made once");

        DTECPrivateSale oldSaleContract = DTECPrivateSale(oldSaleContractAddress) ;
        uint256 oldSaleAmount = amountSold;
        require(oldSaleAmount == 0 , "Migration should be done before any sale");
        
        IERC20 dtecToken = IERC20(dtecTokenAddress);

        for (uint256 i = 0; i < users.length; i++) {
            require(oldSaleContract.addressToBoughtAmt(users[i]) > 0, "There is nothing to migrate for user.");
        }
        addWLs(users);

        for (uint256 i = 0; i < users.length; i++) {
            require(addressToBoughtAmt[users[i]] == 0 , "User should only migrate once, no duplicate amount");
            uint256 oldBoughtAmtForUser = oldSaleContract.addressToBoughtAmt(users[i]);
            uint256 amtInWei = oldBoughtAmtForUser * 1 ether;

            addressToBoughtAmt[users[i]] += oldBoughtAmtForUser;
            allocations[users[i]] += amtInWei;
            totalAllocated += amtInWei;
            amountSold += oldBoughtAmtForUser;
        }

        uint256 balance = dtecToken.balanceOf(address(this));
        require(totalAllocated <= balance , "There isn't enough token for allocation.");

        uint256 totalMigratedTokenAmount = amountSold - oldSaleAmount;
        migrated = true; 

        require(oldSaleContract.amountSold() == totalMigratedTokenAmount , "All bought amounts should be migrated");
        emit MigrationMade(users, block.timestamp, totalMigratedTokenAmount);
    }
}

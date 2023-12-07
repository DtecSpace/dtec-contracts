// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {DTECTokenSale} from './DTECTokenSale.sol';
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DTECPrivateSale is DTECTokenSale {
    uint256 public constant MIN_TOKENS_TO_BUY = 83200;
    uint256 public constant MAX_TOKENS_TO_BUY = 5000000;
    uint256 public constant MIN_TOKENS_TO_ADDITION_BUY = 33200; 

    bool migrated = false;
    address public immutable oldSaleContractAddress;

    mapping(address => uint8) public wl;
    mapping(address => uint256) public addressToBoughtAmt;

    event WlsAdded(address[] wls);
    event MigrationMade (address[] migratedUsers , uint256 timestamp, uint256 migratedTokenAmount);

    error Unauthorized();
    error OverUnderAllowedAmt();

    constructor(address _receiver, address _dtecAddress, address _lockerAddress) DTECTokenSale(_receiver, _dtecAddress, _lockerAddress) {
        setImmediateReleaseRate(100); // Corresponding %1 at TGE
        setSalePrice(60000); // Corresponding 0.06 USD, USDC and USDT have 6 decimals 
        
        oldSaleContractAddress = 0xa40CDB7595fb14F932F56EaA6Aa00E5062B8aa08;
    }

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

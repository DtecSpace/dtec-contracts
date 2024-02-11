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

import {DTECPrivateSale} from './DTECPrivateSale.sol';
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ITokenLock} from "./interfaces/ITokenLock.sol";

contract DTECPrivateSale2 {

    uint256 public constant oldSalePrice = 60000; // 0.06 USD
    uint256 public constant newSalePrice = 30000; // 0.04 USD

    DTECPrivateSale public constant privateSale1 = DTECPrivateSale(0x6d158bb60FfF3a66F0290BF3F156B9d355163e50);

    address public constant dtecTokenAddress = 0xd87aF7B418d64FF2cdE48d890285bA64fc6E115F;

    address public immutable privSale2LockContract;

    uint256 public totalExtraAllocations;

    // Snapshot of old buyers before price change (0.06 USD -> 0.04 USD) at block 1730444800 (25.01.2024)
    // Addresses are stored in the contract to be clear and transparent
    address[50] public oldBuyers = [
        0x572bBa628b95C731A3D14fc4eB11181971BB3F15,
        0x4De87ED18dDCc29E79Fe0ba04244d49712a8C9dC,
        0x5e5bEC37E25C2b22088B46816053828F2b84E080,
        0x02a8bE9114Cd13bEdDb40E89FBD4b7224b019125,
        0x004e4eC0977Ed8540e52508dDfea16528eC0d5b4,
        0x5FbAC2b9250144bc42a7f56F9DeFb5bae8E45Ad7,
        0xdf87CB36C5C77ca398e3562aaAA855Fe331e493f,
        0x3348174d8c18e5b89BD24E677FFc3c07F6EbA1ED,
        0x98da5dDaDCf49fbEdba4E345f9a35DD074Cc9076,
        0xF312C0Fe1AA5073E9123717433f46043Fa844D3D,
        0xf16C05Ad3daE29EA1CfA6f3B7E15E40a9f3206cf,
        0xA6FbDf47321945C138fD77640261875c6991fAC5,
        0x7b7Bc6680726ca71d2f4316e122811b50c725b01,
        0xE52896143Ec9EaED0d0C9906529d58dA985AdB6F,
        0xB2fb1f1119B97B3Ef6bB032D52500C7De8fccB3b,
        0x403C40582d16B5b9B88E4cb9afF606240D894e06,
        0xACe38CEE5AbCbAc320A5685E2dFa6158305D8381,
        0x5C08e5d7F18eFd58b1AC197F65C799C8d95aA00F,
        0xC56c7B83ff6773B5F1D4D68EEbbe86aCF545A1e3,
        0x66f78123B15eD568e51ACf0ac888cFBbC4c01665,
        0x7294C2e1c377c253DDC2020BD1EccF3Eae254a1f,
        0x0888b5a41D85b1ffDf276706501278c550939736,
        0xF3308B3BC2E3850F660dBf6029fFd632456cc159,
        0xE384de9b4754C353Ff149b21786AD4BaDd436E59,
        0x7650B1798Fe8B6C64f3A64331A38D4BaeBC8816A,
        0xd8E04911bA9E4EC9ABE9F946dbbC0bbc9bDA1817,
        0xf7A8a952b456F4b4A3babB8185db2c98A4288434,
        0x9B253c333aB386B1dF5F8174E17E2B24BF250746,
        0x430FD4aC4D5EA0954a1ce006E4B788aaFA3dBF58,
        0xce7773949131c1D194a0C460b7a19Fe46D51508B,
        0xB3733aCF070bC67dE5EAFB534114b8895dc82E78,
        0xdE1B3F44F8fb86c5Cf3731C3D21b7B4bdBae58B4,
        0xbD73Df2316e6869fE8ce55fFE99a097Ae7a7C0df,
        0x294dae960E17471532984b436445c746919f6455,
        0xde84702b0b46e0b41380975F1f7BaA73fE9225ef,
        0x141160ae7a130AC133cb4B8786C6eB6377D3C411,
        0x4feB9BFa82017fFC1816b7f763D2940a7C62E9fC,
        0x3ff093bf4ec22c00eC4ec30486c696225c6bCE38,
        0x6Af6A0749f92B4a46AEc7727F335A8c6270dad61,
        0x1676858951821F74F08F67FDFC7d84DE2941dbD5,
        0x8aF127BA3AB9C4603556f5983461CaFf58190f66,
        0x1382eD3B3Ed7dfb80485F13734668Ef4F7889d02,
        0x3a025d2fB3bC5f03B305e47252C835F7FadbbCEE,
        0x17E42F66C6B1cf082AB46E7695c0D9eB9e1ddAb6,
        0xC134F10C4e01F07559f492bCDCfE07409174cabf,
        0xd626EE4868DCe052a10eCa8F974153dE1FaF2431,
        0xA30172e8b31864f6709e95B413C0ce7B6BBF5Feb,
        0xB288168437948aD9475D2Ac7e1Ff58e73b95dAB4,
        0xaE07d2FB6065E046BEDE68516d0D081050882d81,
        0xAEc873aD59D70E7Dc30515585BD29C76BAbCaEDA
    ];

    // Total sold tokens for old buyers is 25184810 DTEC Private Sale 1 contract
    // Snapshot of old buyers amountSold state variable before price change at block 1730444800 (25.01.2024)
    uint256 public constant totalOldBuyersSoldTokens = 26625978 * 10 ** 18; // 18 decimals

    mapping(address => uint256) public extraAllocations;
    mapping(address => bool) public isHasExtraAllocation;

    error DontHaveAllocation();

    event ExtraAllocationClaimed(address indexed oldUser, address indexed newUser, uint256 timestamp, 
    uint256 totalAllocation, uint256 releasedAmount, uint256 lockedAmount);

    
    constructor(address _privSale2LockContract) {
        privSale2LockContract = _privSale2LockContract;
        
        // PrivateSale1 Contract will be paused before migration, to prevent old buyers from 
        // additional buying tokens with new price before migration. Using addressToBoughtAmt mapping is safe.
        require(privateSale1.paused() , "Sale contract 1 should be paused before deployment");
        uint256 _totalOldBuyersSoldTokens = 0;

        for (uint256 i = 0; i < oldBuyers.length; i++) {
            address oldBuyer = oldBuyers[i];
            uint256 oldBuyerAllocation = privateSale1.addressToBoughtAmt(oldBuyer) * 10 ** 18; // 18 decimals
            require(oldBuyerAllocation > 0, "Invalid allocation");
            uint256 newBuyerAllocation = oldBuyerAllocation * oldSalePrice / newSalePrice;
            uint256 extraAllocation = (newBuyerAllocation - oldBuyerAllocation) ;
            totalExtraAllocations += extraAllocation;
            extraAllocations[oldBuyer] = extraAllocation;
            _totalOldBuyersSoldTokens += oldBuyerAllocation;
            isHasExtraAllocation[oldBuyer] = true;
        }
        
        require(totalOldBuyersSoldTokens == _totalOldBuyersSoldTokens, "All users must be migrated correctly");
    }

    function claimAllocation(address _to) external {
        require (_to != address(0) , "Invalid address") ;
        uint256 allocation = extraAllocations[msg.sender];
        if (allocation == 0) {
            revert DontHaveAllocation();
        }
        (uint256 releaseAmount, uint256 lockAmount) = calculateReleaseAmounts(allocation);
        extraAllocations[msg.sender] = 0;
        totalExtraAllocations -= allocation;
        IERC20 dtec = IERC20(dtecTokenAddress);
        dtec.transfer(privSale2LockContract, lockAmount);
        ITokenLock tokenLock = ITokenLock(privSale2LockContract);
        tokenLock.lockTokens(_to, lockAmount);
        // Release to user
        if (releaseAmount > 0) {
            dtec.transfer(_to, releaseAmount);
        }
        emit ExtraAllocationClaimed(msg.sender, _to, block.timestamp, allocation, releaseAmount, lockAmount);
    }

    function calculateReleaseAmounts(uint256 amtInWei) internal pure returns (uint256, uint256) {
        uint256 lockAmount = amtInWei;
        uint256 releaseAmount = 0;
        releaseAmount = amtInWei * 100 / 10000; // %1 at TGE
        lockAmount = amtInWei - releaseAmount;
        return (releaseAmount, lockAmount);
    }
}

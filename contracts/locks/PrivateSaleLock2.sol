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

import {DTECPrivateSale} from '../DTECPrivateSale.sol';
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {PrivateSaleLock} from "./PrivateSaleLock.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PrivateSaleLock2 is Ownable, Pausable, ReentrancyGuard {

    DTECPrivateSale public constant privSale1 = DTECPrivateSale(0x6d158bb60FfF3a66F0290BF3F156B9d355163e50);
    PrivateSaleLock public constant privSale1Lock = PrivateSaleLock(0x47D5c7599991F121A817C289B8E62Dd2015D5Eb3);
    IERC20 public constant dtecToken = IERC20(0xd87aF7B418d64FF2cdE48d890285bA64fc6E115F);

    mapping(address => uint256) public addressToBoughtAmtInWei;
    mapping(address => uint256) public userTotalClaimedSoFar;

    uint256 public totalLockedSoFar;
    uint256 public immutable tgeReleaseRate;

    event Claimed(address indexed user, uint256 timestamp, uint256 claimedAmount, 
    uint256 totalUnlocked);
    event TokensReleased(address indexed user, uint256 timestamp, uint256 releasedAmount, 
    uint256 boughtDifference, uint256 totalLockedSoFar);
    event TokensPulled(uint256 amount);
    event PausedToggled(bool isPaused);

    constructor() {
        tgeReleaseRate = privSale1.immediateReleaseRate();
    }

    function releaseFunds(address _to) external nonReentrant whenNotPaused {

        require(_to != address(0) , "Invalid address.");

        uint256 privSale1BoughtAmtInWei = privSale1.addressToBoughtAmt(msg.sender) * 1e18;
        require(privSale1BoughtAmtInWei != 0 , "User doesn't have funds.");
        require(privSale1BoughtAmtInWei > addressToBoughtAmtInWei[msg.sender] , "Nothing to release.");

        uint256 bougthAmountDifference =  privSale1BoughtAmtInWei - addressToBoughtAmtInWei[msg.sender] ;
        addressToBoughtAmtInWei[msg.sender] = privSale1BoughtAmtInWei;

        uint256 releaseAmount = bougthAmountDifference * tgeReleaseRate / 10000 ; // 10,000 is the base rate from old contract

        totalLockedSoFar += bougthAmountDifference - releaseAmount;

        if (releaseAmount > 0) {
            dtecToken.transfer(_to, releaseAmount);
        }

        emit TokensReleased(msg.sender, block.timestamp, releaseAmount, bougthAmountDifference, totalLockedSoFar);

    }

    function claim() external nonReentrant whenNotPaused {

        uint256 claimable = privSale1Lock.getClaimable(msg.sender);
        (, uint256 privSale1UserClaimedSoFar) = privSale1Lock.userToLockInfo(msg.sender);

        uint256 totalUnlocked = claimable + privSale1UserClaimedSoFar;

        require(totalUnlocked > userTotalClaimedSoFar[msg.sender] , "Nothing to claim.");

        uint256 claimAmount = totalUnlocked - userTotalClaimedSoFar[msg.sender] ;
        
        userTotalClaimedSoFar[msg.sender] += claimAmount;

        dtecToken.transfer(msg.sender, claimAmount);

        emit Claimed(msg.sender, block.timestamp, claimAmount, totalUnlocked);
    }



    function pullTokens(uint256 _amt) external onlyOwner {

        require(_amt != 0 , "Wrong amount.");

        uint256 availableBalance = dtecToken.balanceOf(address(this)) - totalLockedSoFar;
        require(availableBalance > 0 && _amt <= availableBalance , "Nothing to pull.");

        dtecToken.transfer(owner(), _amt);

        emit TokensPulled(_amt);
    }

    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
        emit PausedToggled(paused());
    }


}
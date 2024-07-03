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

import {Vesting} from "./Vesting.sol";

/// @title Marketing
/// @dev Extends the Vesting contract with specific settings for Marketing vesting.
/// @notice Manages the vesting of tokens specifically allocated to the Marketing, with a distinct vesting schedule.
contract Marketing is Vesting {
    /// @notice Constructor for Marketing Vesting, initializing the vesting with specific timing and rate for the Marketing's tokens
    /// @param _dtecAddress Address of the DTEC token to be vested for the Marketing
    constructor(address _dtecAddress) Vesting(_dtecAddress) {
        // TGE is 14.07.2024, first lock release for Marketing Vesting is 14.12.2024
        // To get tokens on time, release lockTimestamp is 1731542400, 30 days before 14.12.2024
        setReleaseInfo(1731542400, 209);
    }
}

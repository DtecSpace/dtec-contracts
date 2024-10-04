// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./StakingBase.sol";

contract DTEC60DaysStaking is StakingBase {

    constructor() StakingBase (
        IERC20(0xd87aF7B418d64FF2cdE48d890285bA64fc6E115F), // DTEC staking token
        IERC20(0xd87aF7B418d64FF2cdE48d890285bA64fc6E115F), // DTEC reward token 
        80000, // 80% annual yield
        60 days, // 60 days in seconds
        2_000_000 * 10**18, // 2 million tokens
        14 days // 14 days in seconds
    ) {
    }

}

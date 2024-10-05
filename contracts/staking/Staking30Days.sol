// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./StakingBase.sol";

contract DTEC30DaysStaking is StakingBase {

    constructor() StakingBase (
        IERC20(0xd87aF7B418d64FF2cdE48d890285bA64fc6E115F), // DTEC staking token
        IERC20(0xd87aF7B418d64FF2cdE48d890285bA64fc6E115F), // DTEC reward token 
        5000, // 50% annual yield
        30 days, // 30 days in seconds
        1_000_000 * 10**18, // 1 million tokens
        14 days // 14 days in seconds
    ) {
    }

}
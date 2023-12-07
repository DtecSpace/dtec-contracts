// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Vesting} from "./Vesting.sol";

contract Staking is Vesting {
    constructor(address _dtecAddress) Vesting(_dtecAddress) {
        // TGE is 01.04.2024, first lock release for Staking Vesting is 01.05.2024
        // To get tokens on time, release lockTimestamp is 1711929601, 30 days before 01.05.2024
        setReleaseInfo(1711929601, 83);
    }
}
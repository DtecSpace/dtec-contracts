// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Vesting} from "./Vesting.sol";

contract Partners is Vesting {
    constructor(address _dtecAddress) Vesting(_dtecAddress) {
        // TGE is 01.04.2024, first lock release for Partners Vesting is 01.02.2025
        // To get tokens on time, release lockTimestamp is 1735776001, 30 days before 01.02.2025
        setReleaseInfo(1735776001, 278);
    }
}

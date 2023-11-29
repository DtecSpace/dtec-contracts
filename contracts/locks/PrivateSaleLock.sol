// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LinearLock} from "./LinearLock.sol";

contract PrivateSaleLock is LinearLock {
    constructor(address _dtecAddress) LinearLock(_dtecAddress) {
        // TGE is 01.04.2024, first lock release for Private Sale is 01.01.2025
        // To get tokens on time, release lockTimestamp is 1733097601, 30 days before 01.01.2025
        setReleaseInfo(1733097601, 834);
    }
}

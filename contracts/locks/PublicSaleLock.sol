// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LinearLock} from "./LinearLock.sol";

contract PublicSaleLock is LinearLock {
    constructor(address _dtecAddress) LinearLock(_dtecAddress) {
        // TGE is 01.04.2024, first lock release for Public Sale is 01.06.2024
        // To get tokens on time, release lockTimestamp is 1714608001, 30 days before 01.06.2024
        setReleaseInfo(1714608001, 2500);
    }
}

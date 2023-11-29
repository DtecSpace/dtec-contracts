// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LinearLock} from "./LinearLock.sol";

contract PreSaleLock is LinearLock {
    constructor(address _dtecAddress) LinearLock(_dtecAddress) {
        // TGE is 01.04.2024, first lock release for Pre Sale is 01.10.2024
        // To get tokens on time, release lockTimestamp is 1725148801, 30 days before 01.10.2024
        setReleaseInfo(1725148801, 1112);
    }
}

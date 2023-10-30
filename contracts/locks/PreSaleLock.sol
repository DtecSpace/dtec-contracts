// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LinearLock} from "./LinearLock.sol";

contract PreSaleLock is LinearLock {
    constructor(address _dtecAddress) LinearLock(_dtecAddress) {
        setReleaseInfo(1717200001, 1112);
    }
}

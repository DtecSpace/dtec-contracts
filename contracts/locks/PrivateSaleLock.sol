// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LinearLock} from "./LinearLock.sol";

contract PrivateSaleLock is LinearLock {
    constructor(address _dtecAddress) LinearLock(_dtecAddress) {
        setReleaseInfo(1725148801, 834);
    }
}

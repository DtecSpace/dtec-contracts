// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Vesting} from "./Vesting.sol";

contract Partners is Vesting {
    constructor(address _dtecAddress) Vesting(_dtecAddress) {
        setReleaseInfo(1727740801, 278);
    }
}

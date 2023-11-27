// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Vesting} from "./Vesting.sol";

contract Ecosystem is Vesting {
    constructor(address _dtecAddress) Vesting(_dtecAddress) {
        setReleaseInfo(1751328001, 278);
    }
}

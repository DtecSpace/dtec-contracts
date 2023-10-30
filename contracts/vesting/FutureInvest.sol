// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Vesting} from "./Vesting.sol";

contract FutureInvest is Vesting {
    constructor(address _dtecAddress) Vesting(_dtecAddress) {
        setReleaseInfo(1767225601, 167);
    }
}

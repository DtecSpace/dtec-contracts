// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Vesting} from "./Vesting.sol";

contract DataSharing is Vesting {
    constructor(address _dtecAddress) Vesting(_dtecAddress) {
        setReleaseInfo(1735689601, 1000);
        setPeriod(365 days);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Vesting} from "./Vesting.sol";

contract FutureInvest is Vesting {
    constructor(address _dtecAddress) Vesting(_dtecAddress) {
        // TGE is 01.04.2024, first lock release for FutureInvest Vesting is 01.04.2026
        // To get tokens on time, release lockTimestamp is 1772409601, 30 days before 01.04.2026
        setReleaseInfo(1772409601, 167);
    }
}

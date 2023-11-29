// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Vesting} from "./Vesting.sol";

contract EcosystemFund is Vesting {
    constructor(address _dtecAddress) Vesting(_dtecAddress) {
        // TGE is 01.04.2024, first lock release for EcosystemFund Vesting is 01.01.2025
        // To get tokens on time, release lockTimestamp is 1733097601, 30 days before 01.01.2025
        setReleaseInfo(1733097601, 167);
    }
}

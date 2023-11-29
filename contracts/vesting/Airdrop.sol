// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Vesting} from "./Vesting.sol";

contract Airdrop is Vesting {
    constructor(address _dtecAddress) Vesting(_dtecAddress) {
        // TGE is 01.04.2024, first lock release for Airdrop is 01.10.2024
        // To get tokens on time, release lockTimestamp is 1725148801, 30 days before 01.10.2024
        setReleaseInfo(1725148801, 167);
    }
}

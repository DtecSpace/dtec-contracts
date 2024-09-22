// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StakingBase.sol";

contract DTEC30DaysStaking is StakingBase {

constructor(
        IERC20 _stakingToken,
        IERC20 _rewardToken,
        uint64 _annualYield,
        uint64 _duration,
        uint256 _maxTotalStake
    ) StakingBase (
        _stakingToken,
        _rewardToken,
        _annualYield,
        _duration,
        _maxTotalStake
    ) {

    }

}
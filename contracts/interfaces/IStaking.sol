// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IStaking {
    function stake(uint256 _amount) external;
    function unstake(uint256 _index) external;
    function withdraw(uint256 _index) external;
    function getStakeCount(address _user) external view returns (uint256);
    function getStakeDetails(address _user, uint256 _index) external view returns (StakeDetail memory);
    function getAllStakeDetails(address _user, uint256 _start, uint256 _count) external view returns (StakeDetail[] memory);
    function calculateReward(uint256 _amount, uint256 _time) external view returns (uint256);
    function getPoolDetails() external view returns (
        uint256 _maxTotalStake,
        uint256 _totalStaked,
        uint64 _annualYield,
        uint64 _duration,
        uint64 _unstakePeriod
    );
    function withdrawTokens(IERC20 token, uint256 amount) external;

    struct StakeDetail {
        uint256 index;
        uint256 amount;
        uint128 startTime;
        uint128 endTime;
        bool withdrawn;
        uint256 currentReward;
        bool unstaked;
        uint128 unstakeEndTimestamp;
    }
}

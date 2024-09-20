// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract StakingBase {
    using SafeERC20 for IERC20;

    IERC20 public stakingToken;
    IERC20 public rewardToken;
    uint64 public annualYield; 
    uint64 public duration;    

    uint256 private constant NUMERATOR = 1_000_000; 
    uint256 private constant DENOMINATOR = NUMERATOR * 10000 * 365 days; 

    struct Stake {
        uint128 amount;
        uint128 startTime;
        bool withdrawn;
    }

    struct StakeDetail {
        uint256 index;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        bool withdrawn;
        uint256 currentReward;
    }

    mapping(address => Stake[]) public stakes;

    event Staked(address indexed user, uint256 index, uint256 amount, uint256 startTime);
    event Withdrawn(address indexed user, uint256 index, uint256 amount, uint256 reward);

    constructor(
        IERC20 _stakingToken,
        IERC20 _rewardToken,
        uint64 _annualYield,
        uint64 _duration
    ) {
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        annualYield = _annualYield;
        duration = _duration;
    }

    function stake(uint256 _amount) external virtual {
        require(_amount > 0, "Cannot stake zero tokens");

        // Transfer staking tokens to the contract
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        uint128 amount = uint128(_amount);
        uint128 startTime = uint128(block.timestamp);

        // Create a new stake
        stakes[msg.sender].push(
            Stake({
                amount: amount,
                startTime: startTime,
                withdrawn: false
            })
        );

        uint256 index = stakes[msg.sender].length - 1;

        emit Staked(msg.sender, index, amount, startTime);
    }

    function withdraw(uint256 _index) external virtual {
        Stake storage userStake = stakes[msg.sender][_index];

        require(!userStake.withdrawn, "Stake already withdrawn");

        uint256 endTime = uint256(userStake.startTime) + uint256(duration);
        require(block.timestamp >= endTime, "Stake period not yet completed");

        uint256 reward = calculateReward(userStake.amount, duration);

        userStake.withdrawn = true;

        stakingToken.safeTransfer(msg.sender, userStake.amount);
        rewardToken.safeTransfer(msg.sender, reward);

        emit Withdrawn(msg.sender, _index, userStake.amount, reward);
    }

    function getStakes(address _user) external view returns (Stake[] memory) {
        return stakes[_user];
    }

    function getStakeDetails(address _user, uint256 _index)
        external
        view
        returns (StakeDetail memory)
    {
        Stake storage userStake = stakes[_user][_index];
        return _getStakeDetail(_index, userStake);
    }

    function getAllStakeDetails(address _user)
        external
        view
        returns (StakeDetail[] memory)
    {
        Stake[] storage userStakes = stakes[_user];
        uint256 stakeCount = userStakes.length;
        StakeDetail[] memory details = new StakeDetail[](stakeCount);

        for (uint256 i = 0; i < stakeCount; i++) {
            details[i] = _getStakeDetail(i, userStakes[i]);
        }

        return details;
    }

    function _getStakeDetail(
        uint256 _index,
        Stake storage userStake
    ) internal view returns (StakeDetail memory) {
        uint256 amount = userStake.amount;
        uint256 startTime = userStake.startTime;
        uint256 endTime = startTime + duration;
        bool withdrawn = userStake.withdrawn;

        uint256 elapsedTime;
        if (block.timestamp >= endTime) {
            elapsedTime = duration;
        } else {
            elapsedTime = block.timestamp - startTime;
        }

        uint256 currentReward = calculateReward(amount, elapsedTime);

        return StakeDetail({
            index: _index,
            amount: amount,
            startTime: startTime,
            endTime: endTime,
            withdrawn: withdrawn,
            currentReward: currentReward
        });
    }

    function calculateReward(uint256 _amount, uint256 _time)
        public
        view
        returns (uint256)
    {
        uint256 reward = (_amount * annualYield * _time * NUMERATOR) / DENOMINATOR;
        return reward;
    }
}

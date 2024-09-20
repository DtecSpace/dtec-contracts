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
        returns (
            uint256 amount,
            uint256 startTime,
            uint256 endTime,
            bool withdrawn,
            uint256 currentReward
        )
    {
        Stake storage userStake = stakes[_user][_index];

        amount = userStake.amount;
        startTime = userStake.startTime;
        endTime = startTime + duration;
        withdrawn = userStake.withdrawn;

        uint256 elapsedTime;
        if (block.timestamp >= endTime) {
            elapsedTime = duration;
        } else {
            elapsedTime = block.timestamp - startTime;
        }

        currentReward = calculateReward(userStake.amount, elapsedTime);
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

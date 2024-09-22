// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract StakingBase is ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;
    uint64 public immutable annualYield; 
    uint64 public immutable duration;    

    uint256 public immutable maxTotalStake; 
    uint256 public totalStaked;  

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
        uint64 _duration,
        uint256 _maxTotalStake
    ) {
        require(address(_stakingToken) != address(0), "Invalid staking token address");
        require(address(_rewardToken) != address(0), "Invalid reward token address");
        require(_annualYield > 0, "Annual yield must be greater than 0");
        require(_duration > 0, "Duration must be greater than 0");
        require(_maxTotalStake > 0, "Max total stake must be greater than 0");

        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        annualYield = _annualYield;
        duration = _duration;
        maxTotalStake = _maxTotalStake;
    }

    function stake(uint256 _amount) external virtual nonReentrant {
        require(_amount > 0, "Cannot stake zero tokens");
        require(totalStaked + _amount <= maxTotalStake, "Staking pool limit reached");

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        uint128 amount = uint128(_amount);
        uint128 startTime = uint128(block.timestamp);

        stakes[msg.sender].push(
            Stake({
                amount: amount,
                startTime: startTime,
                withdrawn: false
            })
        );

        uint256 index = stakes[msg.sender].length - 1;

        totalStaked += _amount;

        emit Staked(msg.sender, index, amount, startTime);
    }

    function withdraw(uint256 _index) external virtual nonReentrant {
        require(_index < stakes[msg.sender].length, "Invalid stake index");
        Stake storage userStake = stakes[msg.sender][_index];

        require(!userStake.withdrawn, "Stake already withdrawn");

        uint256 endTime = uint256(userStake.startTime) + uint256(duration);
        require(block.timestamp >= endTime, "Stake period not yet completed");

        uint256 reward = calculateReward(userStake.amount, duration);

        userStake.withdrawn = true;

        totalStaked -= userStake.amount;

        stakingToken.safeTransfer(msg.sender, userStake.amount);
        rewardToken.safeTransfer(msg.sender, reward);

        emit Withdrawn(msg.sender, _index, userStake.amount, reward);
    }

    function getStakeCount(address _user) external view returns (uint256) {
        return stakes[_user].length;
    }

    function getStakeDetails(address _user, uint256 _index)
        external
        view
        returns (StakeDetail memory)
    {
        require(_index < stakes[_user].length, "Invalid stake index");
        Stake storage userStake = stakes[_user][_index];
        return _getStakeDetail(_index, userStake);
    }

    function getAllStakeDetails(
        address _user,
        uint256 _start,
        uint256 _count
    )
        external
        view
        returns (StakeDetail[] memory)
    {
        Stake[] storage userStakes = stakes[_user];
        uint256 totalStakes = userStakes.length;

        if (_start >= totalStakes) {
            return new StakeDetail[](0);
        }

        uint256 end = _start + _count;
        if (end > totalStakes) {
            end = totalStakes;
        }

        uint256 stakeCount = end - _start;
        StakeDetail[] memory details = new StakeDetail[](stakeCount);

        for (uint256 i = 0; i < stakeCount; i++) {
            uint256 index = _start + i;
            details[i] = _getStakeDetail(index, userStakes[index]);
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
        return (_amount * annualYield * _time * NUMERATOR) / DENOMINATOR;
    }
    
    function getPoolDetails()
        external
        view
        returns (
            uint256 _maxTotalStake,
            uint256 _totalStaked,
            uint64 _annualYield,
            uint64 _duration
        )
    {
        return (
            maxTotalStake,
            totalStaked,
            annualYield,
            duration
        );
    }
}

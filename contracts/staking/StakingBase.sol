// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingBase is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;
    uint64 public immutable annualYield; 
    uint64 public immutable duration;    
    uint64 public immutable unstakePeriod;

    uint256 public immutable maxTotalStake; 
    uint256 public totalStaked;  
    uint256 public totalRewardPaid;

    uint256 private constant NUMERATOR = 1_000_000_000; 
    uint256 private constant DENOMINATOR = NUMERATOR * 10000 * 365 days; 

    bool public stakingActive;

    struct Stake {
        uint256 amount;
        uint128 startTime;
        uint128 unstakeEndTimestamp;
        bool withdrawn;
        bool unstaked;
    }

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

    mapping(address => Stake[]) public stakes;

    event Staked(address indexed user, uint256 index, uint256 amount, uint128 startTime);
    event Unstaked(address indexed user, uint256 index, uint256 amount, uint128 unstakeEndTimestamp, uint256 timestampNow);
    event Withdrawn(address indexed user, uint256 index, uint256 amount, uint256 reward, bool isUnstaked);
    event StakingStatusChanged(bool isActive);

    constructor(
        IERC20 _stakingToken,
        IERC20 _rewardToken,
        uint64 _annualYield,
        uint64 _duration,
        uint256 _maxTotalStake,
        uint64 _unstakePeriod
    ) {
        require(address(_stakingToken) != address(0), "Invalid staking token address");
        require(address(_rewardToken) != address(0), "Invalid reward token address");
        require(_annualYield > 0, "Annual yield must be greater than 0");
        require(_duration > 0, "Duration must be greater than 0");
        require(_maxTotalStake > 0, "Max total stake must be greater than 0");
        require(_unstakePeriod > 0, "Unstake period must be greater than 0");

        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        annualYield = _annualYield;
        duration = _duration;
        maxTotalStake = _maxTotalStake;
        unstakePeriod = _unstakePeriod;
        stakingActive = true;
    }

    function stake(uint256 _amount) external virtual nonReentrant {
        require(stakingActive, "Staking is not active");
        require(_amount > 0, "Cannot stake zero tokens");
        require(totalStaked + _amount <= maxTotalStake, "Staking pool limit reached");

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        uint128 startTime = uint128(block.timestamp);

        stakes[msg.sender].push(
            Stake({
                amount: _amount,
                startTime: startTime,
                withdrawn: false,
                unstaked: false,
                unstakeEndTimestamp: 0
            })
        );

        uint256 index = stakes[msg.sender].length - 1;

        totalStaked += _amount;

        emit Staked(msg.sender, index, _amount, startTime);
    }

    function unstake(uint256 _index) external virtual nonReentrant {
        require(_index < stakes[msg.sender].length, "Invalid stake index");
        Stake storage userStake = stakes[msg.sender][_index];

        require(!userStake.withdrawn, "Stake already withdrawn");
        require(!userStake.unstaked, "Stake already unstaked");

        uint256 endTime = uint256(userStake.startTime) + uint256(duration);
        require(block.timestamp < endTime, "Stake period is already completed");

        userStake.unstaked = true;
        userStake.unstakeEndTimestamp = uint128(block.timestamp) + uint128(unstakePeriod);

        emit Unstaked(msg.sender, _index, userStake.amount, userStake.unstakeEndTimestamp, block.timestamp);
    }

    function withdraw(uint256 _index) external virtual nonReentrant {
        require(_index < stakes[msg.sender].length, "Invalid stake index");
        Stake storage userStake = stakes[msg.sender][_index];

        require(!userStake.withdrawn, "Stake already withdrawn");

        if (userStake.unstaked) {
            require(block.timestamp >= uint256(userStake.unstakeEndTimestamp), "Unstake period not yet completed");
            userStake.withdrawn = true;
            totalStaked -= userStake.amount;

            stakingToken.safeTransfer(msg.sender, userStake.amount);
            emit Withdrawn(msg.sender, _index, userStake.amount, 0, userStake.unstaked);

            return;
        } else {
            uint256 endTime = uint256(userStake.startTime) + uint256(duration);
            require(block.timestamp >= endTime, "Stake period not yet completed");

            uint256 reward = calculateReward(userStake.amount, duration);

            userStake.withdrawn = true;
            totalRewardPaid += reward;
            stakingToken.safeTransfer(msg.sender, userStake.amount);
            rewardToken.safeTransfer(msg.sender, reward);

            emit Withdrawn(msg.sender, _index, userStake.amount, reward, userStake.unstaked);
        }

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
        uint128 startTime = userStake.startTime;
        uint128 endTime = startTime + duration;
        bool withdrawn = userStake.withdrawn;
        bool unstaked = userStake.unstaked;
        uint128 unstakeEndTimestamp = userStake.unstakeEndTimestamp;

        uint128 elapsedTime;
        if (block.timestamp >= endTime) {
            elapsedTime = duration;
        } else {
            elapsedTime = uint128(block.timestamp - startTime);
        }

        uint256 currentReward = unstaked ? 0 : calculateReward(amount, elapsedTime);

        return StakeDetail({
            index: _index,
            amount: amount,
            startTime: startTime,
            endTime: endTime,
            withdrawn: withdrawn,
            currentReward: currentReward,
            unstaked: unstaked,
            unstakeEndTimestamp: unstakeEndTimestamp
        });
    }

    function calculateReward(uint256 _amount, uint256 _elapsedTime)
        public
        view
        returns (uint256)
    {
        return (_amount * annualYield * _elapsedTime * NUMERATOR) / DENOMINATOR;
    }
    
    function getPoolDetails()
        external
        view
        returns (
            uint256 _maxTotalStake,
            uint256 _totalStaked,
            uint64 _annualYield,
            uint64 _duration,
            uint64 _unstakePeriod
        )
    {
        return (
            maxTotalStake,
            totalStaked,
            annualYield,
            duration,
            unstakePeriod
        );
    }

    function withdrawTokens(IERC20 token, uint256 amount) external onlyOwner {
        require(amount > 0, "Cannot withdraw zero tokens");
        token.safeTransfer(owner(), amount);
    }

    function setStakingStatus(bool _isActive) external onlyOwner {
        stakingActive = _isActive;
        emit StakingStatusChanged(_isActive);
    }
}

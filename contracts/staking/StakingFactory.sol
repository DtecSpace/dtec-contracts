// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StakingBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingFactory is Ownable {
    event StakingContractCreated(address indexed stakingContract, address indexed creator);

    address[] public stakingContracts;

    mapping(address => bool) public isStakingContract;

    function createStakingContract(
        IERC20 _stakingToken,
        IERC20 _rewardToken,
        uint64 _annualYield,
        uint64 _duration,
        uint256 _maxTotalStake,
        uint64 _unstakePeriod
    ) external onlyOwner returns (address) {
        require(address(_stakingToken) != address(0), "Invalid staking token address");
        require(address(_rewardToken) != address(0), "Invalid reward token address");
        require(_annualYield > 0, "Annual yield must be greater than 0");
        require(_duration > 0, "Duration must be greater than 0");
        require(_maxTotalStake > 0, "Max total stake must be greater than 0");
        require(_unstakePeriod > 0, "Unstake period must be greater than 0");

        StakingBase newStakingContract = new StakingBase(
            _stakingToken,
            _rewardToken,
            _annualYield,
            _duration,
            _maxTotalStake,
            _unstakePeriod
        );

        address stakingContractAddress = address(newStakingContract);
        stakingContracts.push(stakingContractAddress);
        isStakingContract[stakingContractAddress] = true;

        emit StakingContractCreated(stakingContractAddress, msg.sender);

        return stakingContractAddress;
    }

    function getStakingContractCount() external view returns (uint256) {
        return stakingContracts.length;
    }

    function getStakingContracts(uint256 _offset, uint256 _limit) 
        external 
        view 
        returns (address[] memory) 
    {
        require(_offset < stakingContracts.length, "Offset out of bounds");
        
        uint256 end = _offset + _limit;
        if (end > stakingContracts.length) {
            end = stakingContracts.length;
        }
        
        uint256 length = end - _offset;
        address[] memory result = new address[](length);
        
        for (uint256 i = 0; i < length; i++) {
            result[i] = stakingContracts[_offset + i];
        }
        
        return result;
    }

    function getStakingContractDetails(address _stakingContract) 
        external 
        view 
        returns (
            IERC20 stakingToken,
            IERC20 rewardToken,
            uint64 annualYield,
            uint64 duration,
            uint256 maxTotalStake,
            uint256 totalStaked,
            uint64 unstakePeriod
        ) 
    {
        require(isStakingContract[_stakingContract], "Not a valid staking contract");
        
        StakingBase stakingInstance = StakingBase(_stakingContract);
        (maxTotalStake, totalStaked, annualYield, duration, unstakePeriod) = stakingInstance.getPoolDetails();
        stakingToken = stakingInstance.stakingToken();
        rewardToken = stakingInstance.rewardToken();
        
        return (stakingToken, rewardToken, annualYield, duration, maxTotalStake, totalStaked, unstakePeriod);
    }
}
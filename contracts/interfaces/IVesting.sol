// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IVesting {

    // Event declarations
    event ReleaseInfoSet(uint256 startTime, uint256 rate);
    event PeriodSet(uint256 period);
    event Claimed(address indexed user, uint256 timestamp, uint256 claimedAmount, 
    uint256 totalClaimed, uint256 totalAmount);
    event TokensLocked(address indexed user, uint256 timestamp, uint256 amount);

    // Function declarations
    function lockTokens(address _user, uint256 _amt) external;
    function getClaimable(address _user) external view returns (uint256);
    function claim() external;
    function dtecTokenAddress() external view returns (address);
    function period() external view returns (uint256);
    function releaseRate() external view returns (uint256);
    function lockStartTime() external view returns (uint256);
    function userToLockInfo(address _user) external view returns (uint256 totalAmount, uint256 totalClaimed);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITgeVestingBase {

    // Event declarations
    event Claimed(address indexed user, uint256 timestamp, uint256 claimedAmount, 
    uint256 totalClaimed, uint256 totalAmount);
    event TokensLocked(address indexed user, uint256 timestamp, uint256 amount);

    // Function declarations
    function lockTokens(address _user, uint256 _amt) external;
    function lockTokensMultiple(address[] calldata _users, uint256[] calldata _amts) external;
    function getClaimable(address _user) external view returns (uint256);
    function claim() external;
    function claimToUsers(address[] calldata _addresses) external;
    function getVestingUsers(uint256 _paginationStart, uint256 _paginationEnd) external view returns (address[] memory, uint256);
    function totalLocked() external view returns (uint256);
    function maxLockedTokenAmount() external view returns (uint256);
    function dtecTokenAddress() external view returns (address);
    function lockStartTime() external view returns (uint256);
    function releaseRate() external view returns (uint256);
    function tgeReleaseRate() external view returns (uint256);
}

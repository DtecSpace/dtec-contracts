// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITokenLock {
    function claim() external;
    function lockTokens(address _user, uint256 _amt) external;
    function getClaimable(address _user) external view returns (uint256);
}

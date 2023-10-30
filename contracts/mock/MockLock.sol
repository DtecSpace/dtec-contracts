// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ITokenLock} from "../interfaces/ITokenLock.sol";

contract MockLock is ITokenLock {
    function getClaimable(address _user) public view returns (uint256) {
        return 100 ether;
    }

    function claim() external {}

    function lockTokens(address _user, uint256 _amt) external {}
}

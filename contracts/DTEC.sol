// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DTEC is ERC20 {
    uint256 public MAX_SUPPLY = 900000000 * 10 ** 18;

    constructor() ERC20("DTEC", "DTEC") {
        _mint(msg.sender, MAX_SUPPLY);
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}

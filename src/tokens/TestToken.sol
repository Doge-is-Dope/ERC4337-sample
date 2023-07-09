// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * TestToken is a simple ERC20 token for test.
 * The token can be used for paymaster to pay gas fee.
 */
contract TestToken is ERC20 {
    constructor() ERC20("TestToken", "TST") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

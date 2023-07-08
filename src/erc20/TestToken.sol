// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @notice TestToken is a simple ERC20 token for paymaster.
contract TestToken is ERC20 {
    constructor() ERC20("TestToken", "TST") {}
}

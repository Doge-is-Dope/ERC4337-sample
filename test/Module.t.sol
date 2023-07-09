// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/modules/SpendLimit.sol";
import "./helper/Setup.sol";

contract ModuleTest is Setup {
    SpendLimit private _spendLimit;

    event LimitUpdated(address indexed account, address indexed token, uint256 indexed limit, uint256 resetTime);

    function setUp() public override {
        super.setUp();

        // Depoly the SpendLimit module
        _spendLimit = new SpendLimit();
    }

    function testTransferErc20WithDailyLimit() public {
        vm.startPrank(alice);
        assertEq(tkt.balanceOf(address(account)), 1000e18);

        // Set the daily limit to 1 TKT
        vm.expectEmit(true, true, true, true);
        emit LimitUpdated(address(account), address(tkt), 1e18, block.timestamp + 1 days);
        _setErc20DailyLimit(address(tkt), 1e18);

        // Transfer 1 TKT to Bob
        _transferErc20(address(tkt), bob, 1e18);
        assertEq(tkt.balanceOf(address(account)), 999e18); // 1000 - 1 = 999

        // Transfer 1 TKT again, but it should fail because the daily limit is 1 TKT
        vm.expectRevert("SpendLimit: Exceed daily limit");
        _transferErc20(address(tkt), bob, 1e18);

        // Transfer 1 TKT again after 1 day, it should succeed because the daily limit (available) is reset
        vm.warp(block.timestamp + 1 days + 1);
        _transferErc20(address(tkt), bob, 1e18);

        // Remove the daily limit
        vm.expectEmit(true, true, true, true);
        emit LimitUpdated(address(account), address(tkt), 0, 0);
        _removeDailyLimit(address(tkt));
        // Now the account is able to transfer 10 TKT because the daily limit has been removed
        _transferErc20(address(tkt), bob, 10e18);

        assertEq(tkt.balanceOf(address(account)), 988e18);
        vm.stopPrank();
    }

    /**
     * Set the dailiy limit of transferring an ERC-20 token
     */
    function _setErc20DailyLimit(address token, uint256 amount) private {
        bytes memory data = abi.encodeWithSignature("setSpendingLimit(address,uint256)", token, amount);
        account.execute(address(_spendLimit), 0, data);
    }

    /**
     * Remove the dailiy limit of transferring an ERC-20 token
     */
    function _removeDailyLimit(address token) private {
        bytes memory data = abi.encodeWithSignature("removeSpendingLimit(address)", token);
        account.execute(address(_spendLimit), 0, data);
    }

    /**
     * Transfer ERC20 with daily limit which has two steps:
     * 1. Check if the amount is within the daily limit
     * 2. If valid, transfer the amount; Otherwise, revert
     */
    function _transferErc20(address token, address to, uint256 amount) private {
        address[] memory dest = new address[](2);
        dest[0] = address(_spendLimit);
        dest[1] = token;
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSignature("checkSpendingLimit(address,uint256)", token, amount);
        data[1] = abi.encodeWithSignature("transfer(address,uint256)", to, amount);
        account.executeBatch(dest, data);
    }
}

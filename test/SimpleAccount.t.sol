// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "account-abstraction/core/EntryPoint.sol";
import "../src/SimpleAccountFactory.sol";
import "../src/SimpleAccount.sol";

contract SimpleAccountTest is Test {
    address constant ALICE = address(0x123);
    uint256 constant SALT = 0x001;

    EntryPoint entryPoint;
    SimpleAccount account;
    address _user;

    function setUp() public {
        // Deploy the entry point
        entryPoint = new EntryPoint();

        // Create an account for Alice
        SimpleAccountFactory factory = new SimpleAccountFactory(IEntryPoint(address(entryPoint)));
        account = factory.createAccount(ALICE, SALT);
        console.log("account address: %s", address(account));

        deal(address(account), 1 ether);
        assertEq(address(account).balance, 1 ether);

        // Create dummy user
        _user = makeAddr("user");
    }

    function testTransfer() public {
        // Transfer 0.01 ether to user as Alice
        vm.startPrank(address(ALICE));
        account.execute(_user, 0.01 ether, "");
        assertEq(_user.balance, 0.01 ether);
        assertEq(address(account).balance, 0.99 ether);
        vm.stopPrank();

        // Transfer 0.01 ether to user as entry point
        vm.startPrank(address(entryPoint));
        account.execute(_user, 0.01 ether, "");
        assertEq(_user.balance, 0.02 ether);
        assertEq(address(account).balance, 0.98 ether);
        vm.stopPrank();
    }
}

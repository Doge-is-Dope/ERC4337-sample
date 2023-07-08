// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "account-abstraction/core/EntryPoint.sol";
import "../src/SimpleAccountFactory.sol";
import "../src/SimpleAccount.sol";
import "../src/erc20/TestToken.sol";

contract SimpleAccountTest is Test {
    uint256 constant SALT = 0x001;
    address alice; // Alice's eoa address
    address bob;

    EntryPoint entryPoint;
    SimpleAccount account; // Alice's contract account
    IERC20 tkt;

    function setUp() public {
        // Deploy the entry point
        entryPoint = new EntryPoint();

        // Create eoa accounts
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        // Create an contract account for alice
        SimpleAccountFactory factory = new SimpleAccountFactory(IEntryPoint(address(entryPoint)));
        account = factory.createAccount(alice, SALT);
        deal(address(account), 1 ether);
        assertEq(address(account).balance, 1 ether);

        // Deploy TKT
        tkt = new TestToken();
        // Deal TKT to alice's contract account
        deal(address(tkt), address(account), 100e18);
        assertEq(tkt.balanceOf(address(account)), 100 ether);
    }

    function testTransferETH() public {
        // Transfer 0.01 ether to Bob as Alice
        vm.startPrank(address(alice));
        account.execute(bob, 0.01 ether, "");
        assertEq(bob.balance, 0.01 ether);
        assertEq(address(account).balance, 0.99 ether);
        vm.stopPrank();

        // Transfer 0.01 ether to Bob as entry point
        vm.startPrank(address(entryPoint));
        account.execute(bob, 0.01 ether, "");
        assertEq(bob.balance, 0.02 ether);
        assertEq(address(account).balance, 0.98 ether);
        vm.stopPrank();
    }

    function testTransferErc20() public {
        // Transfer 10 TKT to Bob as Alice
        vm.startPrank(address(alice));
        _transferErc20(address(tkt), bob, 10e18);
        assertEq(tkt.balanceOf(bob), 10e18);
        assertEq(tkt.balanceOf(address(account)), 90e18);
        vm.stopPrank();
    }

    function _transferErc20(address token, address to, uint256 amount) private {
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", to, amount);
        account.execute(token, 0, data);
    }
}

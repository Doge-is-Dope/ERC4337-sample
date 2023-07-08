// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "account-abstraction/core/EntryPoint.sol";
import "../../src/SimpleAccountFactory.sol";
import "../../src/SimpleAccount.sol";
import "../..//src/erc20/TestToken.sol";

contract Setup is Test {
    uint256 constant SALT = 0x001;
    uint256 internal alicePrivateKey = 0x123;
    address alice; // Alice's eoa address
    address bob; // Bob as an eoa address

    EntryPoint entryPoint;
    SimpleAccount account; // Alice's contract account
    IERC20 tkt;

    function setUp() public virtual {
        // Deploy the entry point
        entryPoint = new EntryPoint();

        // Create eoa accounts
        alice = vm.addr(alicePrivateKey);
        bob = makeAddr("bob");

        // Create an contract account for alice
        SimpleAccountFactory factory = new SimpleAccountFactory(IEntryPoint(address(entryPoint)));
        account = factory.createAccount(alice, SALT);
        deal(address(account), 1 ether);
        assertEq(address(account).balance, 1 ether);

        // Deploy TKT
        tkt = new TestToken();
        // Fund 1000 TKT to alice's contract account
        deal(address(tkt), address(account), 1_000e18);
        assertEq(tkt.balanceOf(address(account)), 1_000e18);

        vm.label(alice, "Alice's EOA");
        vm.label(bob, "Bob's EOA");
        vm.label(address(account), "Alice's CA");
        vm.label(address(entryPoint), "entry point");
        vm.label(address(tkt), "Test Token");
    }
}

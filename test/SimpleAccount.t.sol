// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./helper/Setup.sol";

contract SimpleAccountTest is Setup {
    function testTransferETH() public {
        // Transfer 0.01 ether to Bob as Alice
        vm.startPrank(alice);
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

        // Transfer 0.01 ether to Bob as Bob
        vm.startPrank(bob);
        vm.expectRevert("SimpleAccount: Not Owner or EntryPoint");
        account.execute(bob, 0.01 ether, "");
        vm.stopPrank();
    }

    function testTransferErc20() public {
        // Transfer 100 TKT to Bob as Alice
        vm.startPrank(alice);
        _transferErc20(address(tkt), bob, 100e18);
        assertEq(tkt.balanceOf(bob), 100e18);
        assertEq(tkt.balanceOf(address(account)), 900e18);
        vm.stopPrank();
    }

    function _transferErc20(address token, address to, uint256 amount) private {
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", to, amount);
        account.execute(token, 0, data);
    }
}

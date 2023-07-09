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
        // Transfer 100 TKT to Bob's eoa from contract account as Alice
        vm.startPrank(alice);
        _transferErc20(address(tkt), bob, 100e18);
        assertEq(tkt.balanceOf(bob), 100e18); // 0 + 100
        assertEq(tkt.balanceOf(address(account)), 900e18); // 1000 - 100
        vm.stopPrank();

        // Transfer 10 TKT from Bob's eoa to Alice's ca
        vm.startPrank(bob);
        tkt.transfer(address(account), 10e18);
        assertEq(tkt.balanceOf(bob), 90e18); // 100 - 10
        assertEq(tkt.balanceOf(address(account)), 910e18); // 900 + 10
        vm.stopPrank();
    }

    function testTransferErc721() public {
        vm.startPrank(alice);

        // Mint ERC-721 to account and check ownership
        titm.mintItem(address(account));
        assertEq(titm.ownerOf(0), address(account));

        // Transfer ERC-721 to Bob and check ownership
        _transferErc721(address(titm), bob, 0);
        assertEq(titm.ownerOf(0), bob);
        vm.stopPrank();

        // Transfer ERC-721 back from Bob to account and check ownership
        vm.startPrank(bob);
        titm.safeTransferFrom(bob, address(account), 0);
        assertEq(titm.ownerOf(0), address(account));
        vm.stopPrank();
    }

    // ERC-4337 account executes ERC-20 transfer
    function _transferErc20(address token, address to, uint256 amount) private {
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", to, amount);
        account.execute(token, 0, data);
    }

    // ERC-4337 account executs ERC-721 safe transfer
    function _transferErc721(address token, address to, uint256 tokenId) private {
        bytes memory data =
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", address(account), to, tokenId);
        account.execute(token, 0, data);
    }
}

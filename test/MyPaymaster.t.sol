// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./helper/Setup.sol";
import "../src/MyPaymaster.sol";

contract MyPaymasterTest is Setup {
    using ECDSA for bytes32;

    address bundlerRefund; // Bundler's refund address

    MyPaymaster paymaster;

    function setUp() public override {
        super.setUp();

        bundlerRefund = makeAddr("bundlerRefund");

        // Deploy MyPaymaster
        paymaster = new MyPaymaster(IEntryPoint(address(entryPoint)));
        // Deposit 100 ether to entry point for the paymaster
        entryPoint.depositTo{value: 100 ether}(address(paymaster));
        // Check if the paymaster has 100 ether in the entry point
        assertEq(entryPoint.balanceOf(address(paymaster)), 100 ether);
    }

    /**
     * Transfer 0.02 ether to bob
     */
    function testTransferByPayingTokenAsFee() public {
        vm.startPrank(address(account));
        assertEq(address(account).balance, 1 ether);
        assertEq(tkt.balanceOf(address(account)), 1_000e18); // Before transfer: 1000 TKT
        tkt.approve(address(paymaster), type(uint256).max);
        vm.stopPrank();

        // Create call data
        bytes memory callData = abi.encodeWithSignature("execute(address,uint256,bytes)", bob, 0.02 ether, "");

        // Paymaster address and token address
        bytes memory paymasterAndData = abi.encodePacked(address(paymaster), address(tkt));

        // Create user operation
        UserOperation memory userOp = UserOperation(
            address(account), // sender
            paymaster.senderNonce(address(account)), // sender nonce
            "", // init code
            callData,
            200000, // callGasLimit
            80000, // verificationGasLimit
            50000, // preVerificationGas
            100, // maxFeePerGas
            100, // maxPriorityFeePerGas
            paymasterAndData,
            "" // signature not included yet
        );

        // Get the signature of the user operation
        // The user op hash is signed as ERC191 message
        bytes32 userOpHash = entryPoint.getUserOpHash(userOp).toEthSignedMessageHash();

        // Sign the user op hash
        vm.startPrank(alice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, userOpHash);
        userOp.signature = abi.encodePacked(r, s, v);
        vm.stopPrank();

        // Append the signature to the user operation
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = userOp;

        // Call the entry point to execute the user operation.
        // The second parameter should be the address for bundler's refund
        entryPoint.handleOps(ops, payable(address(bundlerRefund)));

        // Check if the transfer is successful
        assertEq(address(account).balance, 0.98 ether);
        assertLe(tkt.balanceOf(address(account)), 1_000e18); // The fee is paid by TKT
        assertEq(address(bob).balance, 0.02 ether);
    }
}

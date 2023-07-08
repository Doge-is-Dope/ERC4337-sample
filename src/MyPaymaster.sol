// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "account-abstraction/core/BasePaymaster.sol";
import "./erc20/TestToken.sol";

/**
 * paymasterAndData holds the paymaster address followed by the token address to use.
 */
contract MyPaymaster is BasePaymaster {
    using UserOperationLib for UserOperation;
    using SafeERC20 for IERC20;

    // cost of calling postOp
    uint256 public constant COST_OF_POST = 35000;

    // Since nonce is not accessible within the contract, we need to keep track of it
    mapping(address => uint256) public senderNonce;

    /// @param _entryPoint the entry point contract address
    constructor(IEntryPoint _entryPoint) BasePaymaster(_entryPoint) {}

    function getUserOpHash(UserOperation calldata userOp) public view returns (bytes32) {
        return keccak256(abi.encode(userOp.hash(), address(entryPoint), block.chainid));
    }

    /**
     * This method get the value of token to ETH.
     * Note: Should get the price from oracle in production
     */
    function getTokenValueOfEth(IERC20 token, uint256 ethBought) internal view returns (uint256 valueToken) {
        // (, int256 price, , , ) = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331).latestRoundData();
        return 10e18; // hardcoded for testing
    }

    /**
     * Validate the request:
     * The sender should have enough deposit to pay the max possible cost.
     * Note that the sender's balance is not checked. If it fails to pay from its balance,
     * this deposit will be used to compensate the paymaster for the transaction.
     */
    function _validatePaymasterUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 maxCost)
        internal
        override
        returns (bytes memory context, uint256 validationData)
    {
        (userOpHash);
        // Update sender nonce
        senderNonce[userOp.getSender()]++;
        // verificationGasLimit is dual-purposed, as gas limit for postOp. make sure it is high enough
        require(userOp.verificationGasLimit > COST_OF_POST, "MyPaymaster: gas too low for postOp");

        // Decode the paymasterAndData field to get the token address
        bytes calldata paymasterAndData = userOp.paymasterAndData;
        require(paymasterAndData.length == 20 + 20, "MyPaymaster: paymasterAndData must specify token");

        IERC20 token = IERC20(address(bytes20(paymasterAndData[20:])));
        address account = userOp.getSender();
        uint256 maxTokenCost = getTokenValueOfEth(token, maxCost);

        uint256 gasPriceUserOp = userOp.gasPrice();
        // require(unlockBlock[account] == 0, "MyPaymaster: deposit not locked");
        require(token.balanceOf(account) >= maxTokenCost, "MyPaymaster: not enough token");
        return (abi.encode(account, token, gasPriceUserOp, maxTokenCost, maxCost), 0);
    }

    /**
     * perform the post-operation to charge the sender for the gas.
     * in normal mode, use transferFrom to withdraw enough tokens from the sender's balance.
     * in case the transferFrom fails, the _postOp reverts and the entryPoint will call it again,
     * this time in *postOpReverted* mode.
     * In this mode, we use the deposit to pay (which we validated to be large enough)
     */
    function _postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) internal override {
        (address account, IERC20 token, uint256 gasPricePostOp, uint256 maxTokenCost, uint256 maxCost) =
            abi.decode(context, (address, IERC20, uint256, uint256, uint256));
        //use same conversion rate as used for validation.
        uint256 actualTokenCost = (actualGasCost + COST_OF_POST * gasPricePostOp) * maxTokenCost / maxCost;
        if (mode != PostOpMode.postOpReverted) {
            // attempt to pay with tokens:
            token.safeTransferFrom(account, address(this), actualTokenCost);
        }
    }
}

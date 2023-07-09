// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/**
 * Module for setting a daily spending limit for a token.
 * The limit is reset every 24 hours from the time it was set.
 */
contract SpendLimit {
    /// @param limit: the amount of a daily spending limit
    /// @param available: the available amount that can be spent until resetTime
    /// @param resetTime: block.timestamp at the available amount is restored
    /// @param isEnabled: true when a daily spending limit is enabled
    struct Limit {
        uint256 limit;
        uint256 available;
        uint256 resetTime;
        bool isEnabled;
    }

    uint256 public constant ONE_DAY = 24 hours;

    mapping(address => mapping(address => Limit)) public accountLimits; // account to token to Limit

    event LimitUpdated(address indexed account, address indexed token, uint256 indexed limit, uint256 resetTime);

    /**
     * Set the daily spending limit for a token.
     *  If a limit is set, the reset time is set to 24 hours from now.
     */
    function setSpendingLimit(address _token, uint256 _amount) public {
        _updateLimit(_token, _amount, _amount, block.timestamp + ONE_DAY, true);
    }

    /**
     * Remove the daily spending limit for a token.
     */
    function removeSpendingLimit(address _token) public {
        _updateLimit(_token, 0, 0, 0, false);
    }

    function _updateLimit(address _token, uint256 _limit, uint256 _available, uint256 _resetTime, bool _isEnabled)
        private
    {
        Limit storage limit = accountLimits[msg.sender][_token];
        limit.limit = _limit;
        limit.available = _available;
        limit.resetTime = _resetTime;
        limit.isEnabled = _isEnabled;
        emit LimitUpdated(msg.sender, _token, _limit, _resetTime);
    }

    // This function is called by the account before execution.
    function checkSpendingLimit(address _token, uint256 _amount) external {
        Limit memory limit = accountLimits[msg.sender][_token];

        // return if spending limit hasn't been enabled yet
        if (!limit.isEnabled) return;

        uint256 currentTime = block.timestamp;
        // Renew resetTime and available amount if the reset time has passed.
        if (currentTime > limit.resetTime) {
            limit.resetTime = currentTime + ONE_DAY;
            limit.available = limit.limit;
        }

        // Reverts if the amount exceeds the remaining available amount.
        require(limit.available >= _amount, "SpendLimit: Exceed daily limit");

        // ecrement available amount
        limit.available -= _amount;
        accountLimits[msg.sender][_token] = limit;
    }
}

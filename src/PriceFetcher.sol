// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

import {Switchboard} from "@switchboard-xyz/evm.js/contracts/core/testnet/Switchboard.sol";

contract PriceFetcher {
    address public feedId = 0xE746D2c8547691436C42d22Fa0740AEd3DCD289D;
    int256 public latestValue;
    uint256 public latestTimestamp;

    function fetchLatestResult() external returns (int256 _latestValue) {
        (latestValue, latestTimestamp) = Switchboard.getLatestResult(feedId);
        _latestValue = latestValue;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

interface IPriceFetcher {
    function fetchLatestResult() external view returns (uint256 _latestValue);
}

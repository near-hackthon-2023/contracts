// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

interface IDIAOracleV2{
    function getValue(string memory) external view returns (uint128, uint128);
}

contract PriceFetcher {
    address public feedId = 0xf4e9C0697c6B35fbDe5a17DB93196Afd7aDFe84f;
    uint256 public latestValue;
    uint256 public latestTimestamp;

    function fetchLatestResult() external returns (uint256 _latestValue) {
        (latestValue, latestTimestamp) = IDIAOracleV2(feedId).getValue("ETH/USD");
        _latestValue = latestValue;
    }
}

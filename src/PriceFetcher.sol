// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

import {IPriceFetcher} from "./interfaces/IPriceFetcher.sol";

interface IDIAOracleV2{
    function getValue(string memory) external view returns (uint128, uint128);
}

contract PriceFetcher is IPriceFetcher {

    constructor() {}

    // From https://docs.diadata.org/products/token-price-feeds/access-the-oracle/deployed-contracts#aurora
    address immutable feedId = 0xf4e9C0697c6B35fbDe5a17DB93196Afd7aDFe84f;

    function fetchLatestResult() public view returns (uint256 _latestValue) {
        (_latestValue, ) = IDIAOracleV2(feedId).getValue("AURORA/USD"); 
    }
}

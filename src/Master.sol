// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

import {Borrow} from "src/Borrow.sol";
import {Lending} from "src/Lending.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPriceFetcher} from "./interfaces/IPriceFetcher.sol";

contract Master is Borrow, Lending {
    /// @dev USDC contract interface

    IERC20 private immutable USDT;
    IPriceFetcher private immutable priceFetcher;

    constructor(
        address _USDT,
        address _priceFetcher
    ) Borrow(_USDT, _priceFetcher) Lending(_USDT, _priceFetcher) {
        USDT = IERC20(_USDT);
        priceFetcher = IPriceFetcher(_priceFetcher);
    }
}

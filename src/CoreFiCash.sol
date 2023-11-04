// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

import {Borrow} from "src/Borrow.sol";
import {Lending} from "src/Lending.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPriceFetcher} from "./interfaces/IPriceFetcher.sol";

/// @title CoreFiCash
/// @author CoreFi-Cash Technical Team
/// @notice CoreFiCash main contract
contract CoreFiCash is Borrow, Lending {
    /// @dev USDC contract interface
    IERC20 private immutable USDT;

    /// @dev PriceFetcher contract interface
    IPriceFetcher private immutable priceFetcher;

    /// @notice Master Constructor
    /// @param _USDT USDT contract address
    /// @param _priceFetcher Oracle for core-price contract address
    constructor(
        address _USDT,
        address _priceFetcher
    ) Borrow(_USDT, _priceFetcher) Lending(_USDT, _priceFetcher) {
        USDT = IERC20(_USDT);
        priceFetcher = IPriceFetcher(_priceFetcher);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

import {Borrow} from "src/Borrow.sol";
import {Lending} from "src/Lending.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPriceFetcher} from "./interfaces/IPriceFetcher.sol";

/// @title CoreFiCash
/// @author CoreFi-Cash Technical Team
/// @notice CoreFiCash main contract
contract NearFi is Borrow, Lending {
    /// @dev USDC contract interface
    IERC20 private immutable USDC;

    /// @dev PriceFetcher contract interface
    IPriceFetcher private immutable priceFetcher;

    /// @notice Master Constructor
    /// @param _USDC USDC contract address
    /// @param _priceFetcher Oracle for core-price contract address
    constructor(
        address _USDC,
        address _priceFetcher
    ) Borrow(_USDC, _priceFetcher) Lending(_USDC, _priceFetcher) {
        USDC = IERC20(_USDC);
        priceFetcher = IPriceFetcher(_priceFetcher);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

import {Borrow} from "src/Borrow.sol";
import {Lending} from "src/Lending.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPriceFetcher} from "./interfaces/IPriceFetcher.sol";

/**
 * @title Master
 * @author CoreFi-Cash Technical Team
 * @notice Master contract
 *
 */
contract Master is Borrow, Lending {
    /// @dev USDC contract interface
    IERC20 private immutable USDT;

    /// @dev PriceFetcher contract interface
    IPriceFetcher private immutable priceFetcher;

    /**
     * @notice
     *  Borrow Constructor
     *
     * @param _USDT USDT contract address
     * @param _oracle Oracle for core-price contract address
     *
     */
    constructor(
        address _USDT,
        address _priceFetcher
    ) Borrow(_USDT, _priceFetcher) Lending(_USDT, _priceFetcher) {
        USDT = IERC20(_USDT);
        priceFetcher = IPriceFetcher(_priceFetcher);
    }
}

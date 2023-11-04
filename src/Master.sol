// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

import {Borrow} from "src/Borrow.sol";
import {Lending} from "src/Lending.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Master is Borrow, Lending{
    /// @dev USDC contract interface

    IERC20 public immutable USDT;
    
    constructor(address _USDT) Borrow(_USDT) Lending(_USDT) {
        USDT = IERC20(_USDT);
    }

}

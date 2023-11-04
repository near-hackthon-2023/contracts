// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {ERC20Mock} from "./mock/erc20.sol";
import {Master} from "../src/Master.sol";

// USDT address (mainnet): 0x900101d06A7426441Ae63e9AB3B9b0F63Be145F1

contract MasterTest is Test {
    ERC20Mock USDT;
    Master master;

    address alice = makeAddr("alice");

    function setUp() public {
        USDT = new ERC20Mock("USDT", "USDT");
        deal(address(USDT), alice, 200);

        master = new Master(address(USDT));
    }

    function testDeposit() public {
        vm.startPrank(alice);

        USDT.approve(address(master), 100);
        master.depositFunds(100);

        assertEq(USDT.balanceOf(address(alice)), 100);
        assertEq(USDT.balanceOf(address(master)), 100);
    }
}
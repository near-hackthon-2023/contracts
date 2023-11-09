// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {ERC20Mock} from "./mock/erc20.sol";
import {NearFi} from "../src/NearFi.sol";

contract MasterTest is Test {
    ERC20Mock USDT;
    NearFi master;

    address alice = makeAddr("alice");

    function setUp() public {
        USDT = new ERC20Mock("USDT", "USDT");
        deal(address(USDT), alice, 200);

        master = new NearFi(address(USDT), address(1));
    }

    function testDeposit() public {
        vm.startPrank(alice);

        USDT.approve(address(master), 100);
        master.depositFunds(100);

        assertEq(USDT.balanceOf(address(alice)), 100);
        assertEq(USDT.balanceOf(address(master)), 100);
    }
}
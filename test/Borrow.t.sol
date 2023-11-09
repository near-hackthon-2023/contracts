// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {ERC20Mock} from "./mock/erc20.sol";
import {OracleMock} from "./mock/oracle.sol";
import {NearFi} from "../src/NearFi.sol";

contract MasterTest is Test {
    OracleMock oracle;
    ERC20Mock USDT;
    NearFi master;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        oracle = new OracleMock();
        USDT = new ERC20Mock("USDT", "USDT");
        deal(address(USDT), alice, 1000000);
        deal(bob, 1000000);

        master = new NearFi(address(USDT), address(oracle));
    }

    function testDepositAndBorrow() public {
        vm.startPrank(alice);

        USDT.approve(address(master), 1000000);
        master.depositFunds(1000000);

        assertEq(USDT.balanceOf(address(alice)), 0);
        assertEq(USDT.balanceOf(address(master)), 1000000);

        vm.startPrank(bob);
        master.borrow{value: 100000}(31536000, 100000);
    }
}
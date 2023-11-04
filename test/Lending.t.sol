// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {ERC20Mock} from "./mock/erc20.sol";
import {OracleMock} from "./mock/oracle.sol";
import {Master} from "../src/Master.sol";

contract MasterTest is Test {
    OracleMock oracle;
    ERC20Mock USDT;
    Master master;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        oracle = new OracleMock();
        USDT = new ERC20Mock("USDT", "USDT");
        deal(address(USDT), alice, 100);
        deal(bob, 100);

        master = new Master(address(USDT), address(oracle));

        vm.startPrank(alice);

        USDT.approve(address(master), 100);
        master.depositFunds(100);
    }

    function testActiveLendPosition() public {
        assertEq(master.activeLendPosition(), 100);
        vm.prank(bob);
        assertEq(master.activeLendPosition(), 0);
    }

    function testGetInterestEarnings() public {
        vm.startPrank(bob);
        master.borrow{value: 1}(31536000, 50);
        vm.startPrank(alice);
        emit log_named_uint("interestEarnings", master.getInterestEarnings());
    }
}
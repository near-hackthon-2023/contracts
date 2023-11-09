// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {ERC20Mock} from "./mock/erc20.sol";
import {OracleMock} from "./mock/oracle.sol";
import {NearFi} from "../src/NearFi.sol";
import {Lending} from "../src/Lending.sol";

contract MasterTest is Test {
    OracleMock oracle;
    ERC20Mock USDT;
    NearFi master;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        oracle = new OracleMock();
        USDT = new ERC20Mock("USDT", "USDT");
        deal(address(USDT), alice, 100);
        deal(bob, 100000000);

        master = new NearFi(address(USDT), address(oracle));

        vm.startPrank(alice);

        USDT.approve(address(master), 100);
        master.depositFunds(100);
    }

    function testActiveLendPosition() public {
        assertEq(master.activeLendPosition(), 100);
        vm.prank(bob);
        assertEq(master.activeLendPosition(), 0);
    }

    function testWithdrawFunds() public {
        vm.startPrank(alice);

        master.withdrawFunds(50);

        assertEq(USDT.balanceOf(address(alice)), 50);
        assertEq(USDT.balanceOf(address(master)), 50);
    }

    function testWithdrawFundsFail() public {
        vm.startPrank(alice);

        vm.expectRevert("Amount of funds deposited is not enough");
        master.withdrawFunds(150);
    }

    /* WIP */

    function testComputeYield() public {
        /* 
         * Intermediary test, useful for debugging
         * Must change computeYield() to public for it to work
         */

        // vm.startPrank(alice);

        // Lending.Deposit memory deposit;
        // deposit.amount = 50;
        // deposit.timestamp = 0;

        // skip(1000);

        // emit log_uint(master.computeYield(deposit));
    }

    function testGetInterestEarnings() public {
        vm.startPrank(alice);

        // assertEq(master.getInterestEarnings(), 0);
        // skip(60*60*24*365);
        // assertEq(master.getInterestEarnings(), 5);
    }

    function testClaimYield() public {
        uint256 collateral = 1000;

        vm.startPrank(bob);
        master.borrow{value: collateral}(31536000, 50);
        vm.startPrank(alice);
        skip(60*60*24*365);

        // assertEq(master.getInterestEarnings(), collateral * 5 / 100);

        // Alice gets 5% of the collateral
        emit log_uint(alice.balance);
        master.claimYield();
        emit log_uint(alice.balance);
    }
}
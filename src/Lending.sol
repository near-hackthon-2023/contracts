// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPriceFetcher} from "./interfaces/IPriceFetcher.sol";

contract Lending {

    //uint256 public totalFundsAmount;
    uint256 public nonceLending;
    uint256 public interestRate;
    uint256 public totalAvailable = 300;

    IERC20 public immutable USDT_Lending;
    IPriceFetcher public immutable priceFetcherLending;

    constructor(address _USDT, address _oracle) {
        //totalFundsAmount = 0;
        nonceLending = 0;
        interestRate = 0.05 * 10**18; // 5% = 0.05
        USDT_Lending = IERC20(_USDT);
        priceFetcherLending = IPriceFetcher(_oracle);
    }

    struct Deposit {
        uint256 amount;
        uint256 timestamp;
        uint256 interestRate;
    }

    uint256 public immutable year = 365 days;

    mapping (address => uint256) private userDepositedAmount;
    mapping (address => Deposit[]) public deposits;
    mapping (address => uint256) private userInterestEarns;
    
    // App Deposits
    mapping (uint256 => Deposit) public totalDeposits;

    modifier hasAmount(uint256 amount) {
        require(USDT_Lending.balanceOf(msg.sender) >= amount, "You don't have enough balance");
        _;
    }

    //Deposit Funds:
    function depositFunds(uint256 _newDepositAmount) public {
        require(_newDepositAmount > 0, "Can't deposit 0 funds");
        userDepositedAmount[msg.sender] += _newDepositAmount;
        //totalFundsAmount += _newDepositAmount;
        Deposit storage sessionDeposit = totalDeposits[nonceLending++];
        sessionDeposit.amount = _newDepositAmount;
        sessionDeposit.timestamp = block.timestamp;
        sessionDeposit.interestRate = interestRate;
        deposits[msg.sender].push(sessionDeposit);
        USDT_Lending.transferFrom(msg.sender, address(this), _newDepositAmount);
    }

    // Withdraw Funds
    function withdrawFunds(uint256 _nonce, uint256 _amount) public {
        require(userDepositedAmount[msg.sender] >= _amount && USDT_Lending.balanceOf(address(this)) > _amount, "Amount of funds deposited is not enough");
        userDepositedAmount[msg.sender] -= _amount;
        totalDeposits[_nonce].amount -= _amount;
        //totalFundsAmount -= _amount;

        USDT_Lending.transferFrom(address(this), msg.sender, _amount);
    }

    function updateInterestRate() public returns(uint256) {
        interestRate = interestRate + (totalAvailable / USDT_Lending.balanceOf(address(this))) / 10000;
        return interestRate;
    }

    function activeLendPosition() public view returns(uint256) {
        return userDepositedAmount[msg.sender];
    }

    function computeYield(uint _depositNonce) public view returns(uint256) {
        Deposit storage sessionDeposit = deposits[msg.sender][_depositNonce];
        uint256 timestamp = block.timestamp - sessionDeposit.timestamp;

        return (sessionDeposit.amount * sessionDeposit.interestRate * timestamp) / year;
    }

    function computeYield(Deposit memory _deposit) public view returns(uint256) {
        uint256 timestamp = block.timestamp - _deposit.timestamp;

        return (_deposit.amount * _deposit.interestRate * timestamp) / year;
    }

    function getInterestEarnings() public view returns(uint256) {
        uint256 total = 0;
        for(uint256 i = 0; i < deposits[msg.sender].length; i++) {
            total += computeYield(deposits[msg.sender][i]);
        }
        return total;
    }

    function getTimePassed(uint256 _nonce) public view returns(uint256) {
        return (block.timestamp - totalDeposits[_nonce].timestamp) * 10**18 / year;
    }
}
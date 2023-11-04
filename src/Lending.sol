// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Lending is ERC20 {

    uint256 public nonce;
    uint256 public interestRate;
    uint256 public totalFundsAmount;
    uint256 public totalAvailable = 300;

    constructor() ERC20("FAKE USDT", "USDT") {
        nonce = 0;
        totalFundsAmount = 0;
        interestRate = 0.05 * 10**18; // 5% = 0.05

        _mint(msg.sender, 100000000);
    }

    struct Deposit {
        uint256 amount;
        uint256 timestamp;
        uint256 interestRate;
    }

    uint256 public year = 365 days;

    mapping (address => uint256) private userDepositedAmount;
    mapping (address => Deposit[]) public deposits;
    mapping (address => uint256) private userInterestEarns;
    
    // App Deposits
    mapping (uint256 => Deposit) public totalDeposits;

    modifier hasAmount(uint256 amount) {
        require(balanceOf(msg.sender) >= amount, "You don't have enough balance");
        _;
    }

    //Deposit Funds:
    function depositFunds(uint256 _newDepositAmount) public hasAmount(_newDepositAmount) {
        require(_newDepositAmount > 0, "Can't deposit 0 funds");
        userDepositedAmount[msg.sender] += _newDepositAmount;
        totalFundsAmount += _newDepositAmount;
        Deposit storage sessionDeposit = totalDeposits[nonce++];
        sessionDeposit.amount = _newDepositAmount;
        sessionDeposit.timestamp = block.timestamp;
        sessionDeposit.interestRate = interestRate;
        deposits[msg.sender].push(sessionDeposit);
        _transfer(msg.sender, address(this), _newDepositAmount);
    }

    // Withdraw Funds
    function withdrawFunds(uint256 _nonce, uint256 _amount) public {
        require(userDepositedAmount[msg.sender] >= _amount, "Amount of funds deposited is not enough");
        userDepositedAmount[msg.sender] -= _amount;
        totalDeposits[_nonce].amount -= _amount;
        totalFundsAmount -= _amount;

        _transfer(address(this), msg.sender, _amount);
    }

    function updateInterestRate() public returns(uint256) {
        interestRate = interestRate + (totalAvailable / totalFundsAmount) / 10000;
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
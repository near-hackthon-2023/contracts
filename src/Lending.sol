// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Lending is ERC20 {

    constructor() ERC20("FAKE USDT", "USDT") {
        _mint(msg.sender, 5000);
    }

    mapping (address => uint256) private userDepositedAmount;

    uint256 public totalFundsAmount;

    modifier hasAmount(uint256 amount) {
        require(balanceOf(msg.sender) >= amount, "You don't have enough balance");
        _;
    }

    // Deposit Funds:
    function depositFunds(uint256 _newDepositAmount) public hasAmount(_newDepositAmount) {
        require(_newDepositAmount > 0, "Can't deposit 0 funds");
        userDepositedAmount[msg.sender] += _newDepositAmount;
        totalFundsAmount += _newDepositAmount;
        transfer(address(this), _newDepositAmount);
    }

    // Withdraw Funds
    function withdrawFunds(uint256 _amount) public {
        require(userDepositedAmount[msg.sender] >= _amount, "Amount of funds deposited is not enough");
        userDepositedAmount[msg.sender] -= _amount;
        totalFundsAmount -= _amount;
        _transfer(address(this), msg.sender, _amount);

    }

    function activeLendPosition() public view returns(uint256) {
        return userDepositedAmount[msg.sender];
    }
}
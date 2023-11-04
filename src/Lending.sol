// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPriceFetcher} from "./interfaces/IPriceFetcher.sol";

contract Lending {

    //uint256 public totalFundsAmount;
    uint256 public nonceLending;
    uint256 public interestRate;

    IERC20 private immutable USDT_Lending;
    IPriceFetcher private immutable priceFetcherLending;

    constructor(address _USDT, address _oracle) {
        nonceLending = 0;
        interestRate = 0.05 * 10**18; // 5% = 0.05
        USDT_Lending = IERC20(_USDT);
        priceFetcherLending = IPriceFetcher(_oracle);
    }

    struct Deposit {
        uint256 amount;
        uint256 timestamp;
    }

    uint256 private immutable year = 365 days;

    mapping (address => uint256) private userDepositedAmount;
    mapping (address => Deposit[]) public deposits;
    mapping (address => uint256) private userInterestEarns;
    mapping (address => uint256) private claimedYield;
    
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
        Deposit storage sessionDeposit = totalDeposits[nonceLending++];
        sessionDeposit.amount = _newDepositAmount;
        sessionDeposit.timestamp = block.timestamp;
        deposits[msg.sender].push(sessionDeposit);
        USDT_Lending.transferFrom(msg.sender, address(this), _newDepositAmount);
    }

    // Withdraw Funds
    function withdrawFunds(uint256 _nonce, uint256 _amount) public {
        require(userDepositedAmount[msg.sender] >= _amount && USDT_Lending.balanceOf(address(this)) > _amount, "Amount of funds deposited is not enough");
        userDepositedAmount[msg.sender] -= _amount;
        totalDeposits[_nonce].amount -= _amount;

        USDT_Lending.transferFrom(address(this), msg.sender, _amount);
    }

    function activeLendPosition() public view returns(uint256 _position) {
        _position = userDepositedAmount[msg.sender];
    }

    function computeYield(Deposit memory _deposit) private view returns(uint256 _yield) {
        uint256 timestamp = block.timestamp - _deposit.timestamp;

        _yield = (_deposit.amount * interestRate * timestamp) / year;
    }

    function getInterestEarnings() public view returns(uint256 _total) {
        _total = 0;
        for(uint256 i = 0; i < deposits[msg.sender].length; i++) {
            _total += computeYield(deposits[msg.sender][i]);
        }
    }

    function claimYield() public {
        uint256 yieldToClaim = getInterestEarnings();
        uint256 readyToClaim = yieldToClaim - claimedYield[msg.sender];
        claimedYield[msg.sender] += readyToClaim;
        msg.sender.transfer(readyToClaim);
    }

    function getTreasury() public view returns(uint256 _treasury) {
        _treasury = USDT_Lending.balanceOf(address(this));
    }
}
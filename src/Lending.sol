// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPriceFetcher} from "./interfaces/IPriceFetcher.sol";

/**
 * @title Lending
 * @author CoreFi-Cash Technical Team
 * @notice Lending contract
 *
 */
contract Lending {
    /// @dev nonce identifier for lender
    uint256 public nonceLending;
    
    /// @dev interest rate initiation
    uint256 public interestRate;

    /// @dev USDC contract interface
    IERC20 immutable USDT_Borrow;

    /// @dev PriceFetcher contract interface
    IPriceFetcher immutable priceFetcherBorrow;

    /**
     * @notice
     *  Lending Constructor
     *
     * @param _USDT USDT contract address
     * @param _oracle Oracle for core-price contract address
     *
     */
    constructor(address _USDT, address _oracle) {
        nonceLending = 0;
        interestRate = 0.05 * 10**18; // 5% = 0.05
        USDT_Lending = IERC20(_USDT);
        priceFetcherLending = IPriceFetcher(_oracle);
    }

    /// @dev struct for deposit Params
    struct Deposit {
        uint256 amount;
        uint256 timestamp;
    }

    /// @dev a constant that holds the duration of one year in seconds
    uint256 ONEYEAR = 3.154E7;

    /// @dev
    mapping (address => uint256) private userDepositedAmount;

    /// @dev
    mapping (address => Deposit[]) public deposits;

    /// @dev
    mapping (address => uint256) private userInterestEarns;

    /// @dev
    mapping (address => uint256) private claimedYield;
    
    /// @dev App Deposits
    mapping (uint256 => Deposit) public totalDeposits;

    /// @notice hasAmount is a modifier that controlls that userbalance is enough
    modifier hasAmount(uint256 amount) {
        require(USDT_Lending.balanceOf(msg.sender) >= amount, "You don't have enough balance");
        _;
    }

    /**
     * @notice
     *  Let a user deposit funds as a lender
     *
     * @param _newDepositAmount Amount of funds thAmount of funds that the user wants to deposit
     *
     */
    function depositFunds(uint256 _newDepositAmount) public {
        require(_newDepositAmount > 0, "Can't deposit 0 funds");
        userDepositedAmount[msg.sender] += _newDepositAmount;
        Deposit storage sessionDeposit = totalDeposits[nonceLending++];
        sessionDeposit.amount = _newDepositAmount;
        sessionDeposit.timestamp = block.timestamp;
        deposits[msg.sender].push(sessionDeposit);
        USDT_Lending.transferFrom(msg.sender, address(this), _newDepositAmount);
    }

    /**
     * @notice
     *  Lets a lender withdraw their funds from the borrow pool
     *
     * @param _nonce the unique identifier for the lothe unique identifier for the loan
     * @param _amount Amount they want to withdraw
     *
     */

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

        _yield = (_deposit.amount * interestRate * timestamp) / ONEYEAR;
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

        address payable recipient = payable(msg.sender);
        recipient.transfer(readyToClaim);
    }

    function getTreasury() public view returns(uint256 _treasury) {
        _treasury = USDT_Lending.balanceOf(address(this));
    }
}
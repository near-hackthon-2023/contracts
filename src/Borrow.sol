// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract Borrow {
    uint256 public FAKERESERVE;
    uint256 nonce;

    constructor() {
        FAKERESERVE = 10_000;
    }

    struct LoanParams{
        address borrower;
        uint256 loanSize;
        uint256 collateral;
        uint256 dueDate;
        bool payedBack;
    }

    mapping(uint256 => LoanParams) public loan;

    mapping(address => uint256) public balanceOf;

    uint256 public ONEYEAR = 3.154E7;

    function borrow(uint256 _nonce, uint256 _loanDuration, uint256 _loanSize) public payable {
        require(_nonce == (nonce + 1), "Invalid nonce");
        require(_loanDuration > 0 && _loanDuration < ONEYEAR, "Invalid loan duration");
        require(msg.value > 0 && _loanSize > 0, "You cant lend an amount of 0");
        LoanParams storage sessionLoan = loan[_nonce];

        sessionLoan.borrower = msg.sender;
        sessionLoan.loanSize = _loanSize;
        sessionLoan.collateral = msg.value;
        sessionLoan.dueDate = (block.timestamp + _loanDuration);
        sessionLoan.payedBack = false;
        balanceOf[msg.sender] += msg.value;
        FAKERESERVE -= msg.value;
    }

    function repayBorrow(uint256 _nonce, address payable _to, uint256 _amountPayback) public {
        require(loan[_nonce].loanSize > 0, "Loan doesnt exist");
        require(loan[_nonce].borrower == msg.sender, "You're not authorized");
        require(loan[_nonce].loanSize == _amountPayback, "Not enough repayed");
        LoanParams storage sessionLoan = loan[_nonce];
        sessionLoan.payedBack = true;
        _to.transfer(sessionLoan.collateral);
        sessionLoan.collateral = 0;
    }


    function topUpCollateral() public{}
    function activeBorrowPosition() public view returns(uint256 _borrowPosition){}
    function liquidatePosition() public {}
    function monitorIlliquidPositions() public view returns(uint256 _illiquidPositions) {}
}
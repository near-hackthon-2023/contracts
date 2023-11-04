// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPriceFetcher} from "./interfaces/IPriceFetcher.sol";

contract Borrow {

    /// @dev USDC contract interface
    IERC20 immutable USDT_Borrow;
    IPriceFetcher immutable priceFetcherBorrow;

    uint256 public nonceBorrow;

    uint256 private interestRate = 0.05 * 10**18;

    /// @dev denominator used for multiplier (10_000 = 1)
    uint256 private constant MULTIPLIER_DENOMINATOR = 10_000;

    constructor(address _USDT, address _oracle) {
        USDT_Borrow = IERC20(_USDT);
        priceFetcherBorrow = IPriceFetcher(_oracle);
    }

    struct LoanParams{
        address borrower;
        uint256 loanSize;
        uint256 collateral;
        uint256 borrowedDate;
        uint256 dueDate;
        bool payedBack;
    }

    mapping(uint256 => LoanParams) private loan;

    mapping (address => uint256) private interestSubtracted;

    mapping (address => LoanParams[]) public userLoans;

    uint256 ONEYEAR = 3.154E7;

    function borrow(uint256 _loanDuration, uint256 _loanSize) public payable {
        require(_loanDuration > 0 && _loanDuration < ONEYEAR, "Invalid loan duration");
        require(msg.value > 0 && _loanSize > 0, "You cant lend an amount of 0");

        uint256 amountAvailableForUserLoan = _coreTokenToUSDT(msg.value);
        require(_loanSize <= amountAvailableForUserLoan * 3/2, "You can't take a loan more than 1.5 times your collateral");

        LoanParams storage sessionLoan = loan[nonceBorrow];

        sessionLoan.borrower = msg.sender;
        sessionLoan.loanSize = _loanSize;
        sessionLoan.collateral = msg.value;
        sessionLoan.dueDate = (block.timestamp + _loanDuration);
        sessionLoan.borrowedDate = block.timestamp;
        sessionLoan.payedBack = false;

        userLoans[msg.sender].push(sessionLoan);

        USDT_Borrow.transfer(msg.sender, _loanSize);
        nonceBorrow++;
    }

    function _coreTokenToUSDT(uint256 coreTokenValue) internal returns(uint256 _usdtValue) {
        uint256 dollarPerToken = uint256(priceFetcherBorrow.fetchLatestResult());
        _usdtValue = dollarPerToken * coreTokenValue;
    }

    function repayBorrow(uint256 _nonce, address payable _to, uint256 _amountPayback) public {
        require(loan[_nonce].loanSize > 0, "Loan doesnt exist");
        require(loan[_nonce].borrower == msg.sender, "You're not authorized");
        require(loan[_nonce].loanSize == _amountPayback, "Not enough repayed");
        LoanParams storage sessionLoan = loan[_nonce];
        sessionLoan.payedBack = true;
        _to.transfer(sessionLoan.collateral);
        sessionLoan.collateral = 0;

        userLoans[msg.sender][_nonce].payedBack = true;
        USDT_Borrow.transferFrom(msg.sender, address(this), _amountPayback);
    }

    function topUpCollateral(uint256 _nonce) public payable{
        require(loan[_nonce].loanSize > 0, "Loan doesnt exist");
        require(loan[_nonce].borrower == msg.sender, "You're not authorized");
        LoanParams storage sessionLoan = loan[_nonce];
        sessionLoan.collateral += msg.value;
    }
    
    function activeBorrowPosition(uint256 _nonce) public view returns(LoanParams memory _loanParams){
        require(loan[_nonce].loanSize > 0, "Loan doesnt exist");
        _loanParams = loan[_nonce];
    }
    
    function checkLTV(uint256 _nonce) public returns(uint256 _ltv){
        require(loan[_nonce].loanSize > 0, "Loan doesnt exist");
        LoanParams storage sessionLoan = loan[_nonce];
        _ltv = ((sessionLoan.loanSize * MULTIPLIER_DENOMINATOR) / _coreTokenToUSDT(sessionLoan.collateral));
    }

    function monitorIlliquidPositions() public returns (uint256[] memory _illiquidPositions) {
        uint256 amountOfLoans = nonceBorrow;
        uint256 illiquidCount = 0;
        
        // First, count the number of illiquid positions
        for (uint256 i = 1; i <= amountOfLoans; i++) {
            if (checkLTV(i) > 5000) {
                illiquidCount++;
            }
        }

        // Initialize the dynamic array with the correct size
        _illiquidPositions = new uint256[](illiquidCount);
        
        // Populate the illiquid positions
        uint256 currentIndex = 0;
        for (uint256 i = 1; i <= amountOfLoans; i++) {
            if (checkLTV(i) > 5000) {
                _illiquidPositions[currentIndex] = i;
                currentIndex++;
            }
        }
    }

    function subtractInterest(uint256 _nonce) public {

        LoanParams storage sessionLoan = loan[_nonce];
        uint256 timestamp = block.timestamp - sessionLoan.borrowedDate;

        uint256 interest = (sessionLoan.loanSize * interestRate * timestamp) / (365 days);

        uint256 interestToSubract = interest - interestSubtracted[msg.sender];

        sessionLoan.collateral -= interestToSubract;

        interestSubtracted[msg.sender] += interestToSubract;
    }


    /*
    Notes what we want to do in this function:
    1. set the loan is active to false
    2. return swap the core to usdt so that lender is made whole
    3. 1/2 of whats extra to project
    4. 1/2 of whats extra to the liquidator
    */

    function liquidatePosition(uint256 _nonce) public {
        require(loan[_nonce].loanSize > 0, "Loan doesnt exist");
        uint256[] memory illiquidPositions = monitorIlliquidPositions();
        require(isNumberInArray(illiquidPositions, _nonce), "No illiquid loan found");
        LoanParams storage sessionLoan = loan[_nonce];
        sessionLoan.payedBack = true;  // Maybe we should do a more nuanced system that shows that the loan actually was liquidated 
        // HERE IT SHOULD BE SOME LOGIC THAT PERFORMS THE SWAP
        // HERE IT SHOULD BE SOME LOGIC WITCH CALCULATES HOW MUCH CORE ABOVE THE LENDING VALUE THAT SHOULD BE DISTRIBUTED
    }

    function isNumberInArray(uint[] memory numberArray, uint numberToCheck) private pure returns (bool _isFound) {
        for (uint i = 0; i < numberArray.length; i++) {
            if (numberArray[i] == numberToCheck) {
                _isFound = true; // Number is found in the array
            }
        }
        _isFound = false; // Number is not in the array
    }

    function testTankLTV(uint256 _nonce, uint256 _newCollateral) private {
        require(loan[_nonce].loanSize > 0, "Loan doesnt exist");
        LoanParams storage sessionLoan = loan[_nonce];
        sessionLoan.collateral = _newCollateral;
    }
}
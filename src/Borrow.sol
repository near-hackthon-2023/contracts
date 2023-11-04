// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPriceFetcher} from "./interfaces/IPriceFetcher.sol";


/**
 * @title Borrow
 * @author CoreFi-Cash Technical Team
 * @notice Borrow contract
 *
 */
contract Borrow {

    /// @dev USDC contract interface
    IERC20 immutable USDT_Borrow;

    /// @dev PriceFetcher contract interface
    IPriceFetcher immutable priceFetcherBorrow;

    /// @dev Nonce identifier for a borrow
    uint256 public nonceBorrow;

    /// @dev Interest rate 
    uint256 private interestRate = 0.05 * 10**18;

    /// @dev denominator used for multiplier (10_000 = 1)
    uint256 private constant MULTIPLIER_DENOMINATOR = 10_000;

    /**
     * @notice
     *  Borrow Constructor
     *
     * @param _USDT USDT contract address
     * @param _oracle Oracle for core-price contract address
     *
     */
    constructor(address _USDT, address _oracle) {
        // Set USDT contract
        USDT_Borrow = IERC20(_USDT);
        // Set price oracle contract
        priceFetcherBorrow = IPriceFetcher(_oracle);
    }

    /// @dev LoanParams to keep track of active loans
    struct LoanParams{
        address borrower;
        uint256 loanSize;
        uint256 collateral;
        uint256 borrowedDate;
        uint256 dueDate;
        bool payedBack;
    }

    /// @dev mapping that uses a nonce to identify a specific loan
    mapping(uint256 => LoanParams) private loan;

    
    /// @dev a constant that holds the duration of one year in seconds
    uint256 ONEYEAR = 3.154E7;

    /**
     * @notice
     *  Let a user Borrow. This is a payeable function.
     *
     * @param _loanDuration duration of loan in seconds
     * @param _loanSize The value of USDT that the user wants to lend
     *
     * @param msg.value will act as the collateral
     */

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

        USDT_Borrow.transfer(msg.sender, _loanSize);
        nonceBorrow++;
    }

    /**
     * @notice
     *  Internal function for other functions to convert core amount in USDT value
     *
     * @param _coreTokenAmount amounts of coretokens
     *
     * @return _usdtValue returns the USDT value
     */

    function _coreTokenToUSDT(uint256 coreTokenAmount) internal returns(uint256 _usdtValue) {
        uint256 dollarPerToken = uint256(priceFetcherBorrow.fetchLatestResult());
        _usdtValue = dollarPerToken * coreTokenAmount;
    }

    /**
     * @notice
     *  Let a user repay their dept
     *
     * @param _nonce Nonce as a unique identifier for the loan
     * @param _to payeable address to repay the loan and get back their collateral
     * @param _amountPayback The value of USDT that the user tries to repay, must cover the full loan
     *
     */
    function repayBorrow(uint256 _nonce, address payable _to, uint256 _amountPayback) public {
        require(loan[_nonce].loanSize > 0, "Loan doesnt exist");
        require(loan[_nonce].borrower == msg.sender, "You're not authorized");
        require(loan[_nonce].loanSize == _amountPayback, "Not enough repayed");
        LoanParams storage sessionLoan = loan[_nonce];
        sessionLoan.payedBack = true;
        _to.transfer(sessionLoan.collateral);
        sessionLoan.collateral = 0;
        USDT_Borrow.transferFrom(msg.sender, address(this), _amountPayback);
    }

    /**
     * @notice
     *  Let a user top up their collateral. This is a payable function
     *
     * @param _nonce Nonce as a unique identifier for the loan
     * 
     * @param msg.value the amount of core tokens used to top up collateral
     *
     */
    function topUpCollateral(uint256 _nonce) public payable{
        require(loan[_nonce].loanSize > 0, "Loan doesnt exist");
        require(loan[_nonce].borrower == msg.sender, "You're not authorized");
        LoanParams storage sessionLoan = loan[_nonce];
        sessionLoan.collateral += msg.value;
    }

    /**
     * @notice
     *  Let a user check their current active borrow positions
     *
     * @param _nonce Nonce as a unique identifier for the loan
     * 
     * @return _loanParams returninc the params of the nonce
     *
     */
    function activeBorrowPosition(uint256 _nonce) public view returns(LoanParams memory _loanParams){
        require(loan[_nonce].loanSize > 0, "Loan doesnt exist");
        _loanParams = loan[_nonce];
    }
    
    /**
     * @notice
     *  Let a user check their current LTV ratio
     *
     * @param _nonce Nonce as a unique identifier for the loan
     * 
     * @return _ltv returning the ltv 1% = 100 
     *
     */
    function checkLTV(uint256 _nonce) public view returns(uint256 _ltv){
        require(loan[_nonce].loanSize > 0, "Loan doesnt exist");
        LoanParams storage sessionLoan = loan[_nonce];
        _ltv = ((sessionLoan.loanSize * MULTIPLIER_DENOMINATOR) / sessionLoan.collateral);
    }

    /**
     * @notice
     *  Let a user scan for illiquid positions to liquidate
     * 
     * @return _ltv returning a list of nonces for the illiquid positions
     *
     */
    function monitorIlliquidPositions() public view returns (uint256[] memory _illiquidPositions) {
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

    /**
     * @notice
     *  Private function to for other function to subtract interest from collateral
     *
     * @param _nonce Nonce as a unique identifier for the loan
     * 
     */
    function _subtractInterest(uint256 _nonce) private {
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

    /**
     * @notice
     *  Lets users liquidate illiquid positins
     *
     * @param _nonce Nonce as a unique identifier for the loan
     * 
     */
    function liquidatePosition(uint256 _nonce) public {
        require(loan[_nonce].loanSize > 0, "Loan doesnt exist");
        uint256[] memory illiquidPositions = monitorIlliquidPositions();
        require(_isNumberInArray(illiquidPositions, _nonce), "No illiquid loan found");
        LoanParams storage sessionLoan = loan[_nonce];
        sessionLoan.payedBack = true;  // Maybe we should do a more nuanced system that shows that the loan actually was liquidated 
        // HERE IT SHOULD BE SOME LOGIC THAT PERFORMS THE SWAP
        // HERE IT SHOULD BE SOME LOGIC WITCH CALCULATES HOW MUCH CORE ABOVE THE LENDING VALUE THAT SHOULD BE DISTRIBUTED
    }

    function _isNumberInArray(uint[] memory numberArray, uint numberToCheck) private pure returns (bool _isFound) {
        for (uint i = 0; i < numberArray.length; i++) {
            if (numberArray[i] == numberToCheck) {
                _isFound = true; // Number is found in the array
            }
        }
        _isFound = false; // Number is not in the array
    }

    function testTankLTV(uint256 _nonce, uint256 _newCollateral) public {
        require(loan[_nonce].loanSize > 0, "Loan doesnt exist");
        LoanParams storage sessionLoan = loan[_nonce];
        sessionLoan.collateral = _newCollateral;
    }
}
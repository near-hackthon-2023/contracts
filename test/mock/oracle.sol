pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OracleMock {
    constructor() {}

    function fetchLatestResult() public pure returns (int256) {
        return 389700000000000000; // USD price
    }
}

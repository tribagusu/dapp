// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "hardhat/console.sol";

contract Token {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    // track balances
    mapping(address => uint256) public balanceOf;

    // send tokens
    constructor (string memory _name, string memory _symbol, uint256 _totalSupply) {
      name = _name;
      symbol = _symbol;
      totalSupply = _totalSupply * (10**decimals); // 1,000,000 X 10^8;
      balanceOf[msg.sender] = totalSupply;
    }

}

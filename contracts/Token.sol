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
    // for the owner (caller) and the sender (exchanger)
    mapping(address => mapping(address => uint256)) public allowance;

    // events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // send tokens
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply
    ) {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply * (10 ** decimals); // 1,000,000 X 10^8;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(
        address _to,
        uint256 _value
    ) public returns (bool success) {
        // require that sender has enough tokens to spend
        require(balanceOf[msg.sender] >= _value);
        // require that sender has correct address
        require(_to != address(0));

        // deduct tokens from sender
        balanceOf[msg.sender] = balanceOf[msg.sender] - _value;

        // credit tokens to receiver
        balanceOf[_to] = balanceOf[_to] + _value;

        // emit event
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(
        address _spender,
        uint256 _value
    ) public returns (bool success) {
        // require that spender has correct address
        require(_spender != address(0));

        allowance[msg.sender][_spender] = _value;

        // emit event
        emit Approval(msg.sender, _spender, _value);

        return true;
    }
}

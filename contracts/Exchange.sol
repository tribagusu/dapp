// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "./Token.sol";

//_ ===== Decentralized Exchange List =====
// 1. deposit tokens V
// 2. withdraw tokens V
// 3. check balances V
// 4. make orders V
// 5. cancel orders V
// 6. fill orders V
// 7. charge fees V
// 8. track fee account V

contract Exchange {
    address public feeAccount;
    uint256 public feePercent;
    mapping(address => mapping(address => uint256)) public tokens;
    mapping(uint256 => _Order) public orders;
    uint256 public orderCount; // start from 0
    mapping(uint256 => bool) public orderCancelled;
    mapping(uint256 => bool) public orderFilled;

    //- events
    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Withdraw(
        address token,
        address user,
        uint256 amount,
        uint256 balance
    );
    event Order(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );
    event Cancel(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );

    event Trade(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        address creator,
        uint256 timestamp
    );

    // a way to model the order
    struct _Order {
        // attributes of and order
        uint256 id; // unique identifier for an order
        address user; // user who made order
        address tokenGet; // address of the token user receive
        uint256 amountGet; // amount user receive
        address tokenGive; // address of the token user give
        uint256 amountGive; // amount user give
        uint256 timestamp; // when order was created
    }

    constructor(address _feeAccount, uint256 _feePercent) {
        feeAccount = _feeAccount;
        feePercent = _feePercent;
    }

    //_ ===== DEPOSIT & WITHDRAW TOKENS =====

    function depositToken(address _token, uint256 _amount) public {
        // transfer token to exchange
        require(Token(_token).transferFrom(msg.sender, address(this), _amount));

        // update user balance
        tokens[_token][msg.sender] = tokens[_token][msg.sender] + _amount;

        // emit an event
        emit Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }

    function withdrawToken(address _token, uint256 _amount) public {
        // ensure user has enough tokens to withdraw
        require(tokens[_token][msg.sender] >= _amount);

        // transfer tokens to user
        Token(_token).transfer(msg.sender, _amount);

        // update user balance (deduct)
        tokens[_token][msg.sender] = tokens[_token][msg.sender] - _amount;

        // emit an event
        emit Withdraw(
            _token,
            msg.sender,
            _amount,
            balanceOf(_token, msg.sender)
        );
    }

    // is this function same with mapping tokens?
    function balanceOf(
        address _token,
        address _user
    ) public view returns (uint256) {
        return tokens[_token][_user];
    }

    //_ ===== MAKE & CANCEL ORDERS =====

    function makeOrder(
        address _tokenGet,
        uint256 _amountGet,
        address _tokenGive,
        uint256 _amountGive
    ) public {
        // prevent order if tokens aren't on exchange
        require(balanceOf(_tokenGive, msg.sender) >= _amountGive);

        // instantiate new order
        orderCount++;
        orders[orderCount] = _Order(
            orderCount,
            msg.sender,
            _tokenGet,
            _amountGet,
            _tokenGive,
            _amountGive,
            block.timestamp
        );

        // emits event
        emit Order(
            orderCount,
            msg.sender,
            _tokenGet,
            _amountGet,
            _tokenGive,
            _amountGive,
            block.timestamp
        );
    }

    function cancelOrder(uint256 _id) public {
        // fetch the order
        _Order storage _order = orders[_id];

        // ensure the caller is the owner of the order
        require(address(_order.user) == msg.sender);

        // order must exist
        require(_order.id == _id);

        // cancel the order
        orderCancelled[_id] = true;

        // emit event
        emit Cancel(
            _order.id,
            msg.sender,
            _order.tokenGet,
            _order.amountGet,
            _order.tokenGive,
            _order.amountGive,
            block.timestamp
        );
    }

    //_ ===== EXECUTING ORDERS =====

    function fillOrder(uint256 _id) public {
        // must be valid orderId
        require(_id > 0 && _id <= orderCount, "Order does not exist");

        // order can't be filled already
        require(!orderFilled[_id]);

        // order can't be cancelled already
        require(!orderCancelled[_id]);

        // fetch the order
        _Order storage _order = orders[_id];

        // swapping tokens (trading)
        _trade(
            _order.id,
            _order.user,
            _order.tokenGet,
            _order.amountGet,
            _order.tokenGive,
            _order.amountGive
        );

        // mark order as filled
        orderFilled[_order.id] = true;
    }

    function _trade(
        uint256 _orderId,
        address _user,
        address _tokenGet,
        uint256 _amountGet,
        address _tokenGive,
        uint256 _amountGive
    ) internal {
        // ! tokenGive = SHOL
        // ! tokenGet = sUSD

        // fee is paid by the user who filled the order (msg.sender)
        // fee is deducted from _amountGet
        uint256 _feeAmount = (_amountGet * feePercent) / 100;

        //- Execute the trade
        // ! msg.sender is the user who filled the order, while _user is who make the order

        // take the token B and fees from the filler
        tokens[_tokenGet][msg.sender] =
            tokens[_tokenGet][msg.sender] -
            (_amountGet + _feeAmount);
        // give the token B to the order creator
        tokens[_tokenGet][_user] = tokens[_tokenGet][_user] + _amountGet;

        // give the fees to the exchange (charge fees)
        tokens[_tokenGet][feeAccount] =
            tokens[_tokenGet][feeAccount] +
            _feeAmount;

        // give the token A to the filler
        tokens[_tokenGive][msg.sender] =
            tokens[_tokenGive][msg.sender] +
            _amountGive;
        // take the token A from the order creator
        tokens[_tokenGive][_user] = tokens[_tokenGive][_user] - _amountGive;

        // - emit trade event
        emit Trade(
            _orderId,
            msg.sender,
            _tokenGet,
            _amountGet,
            _tokenGive,
            _amountGive,
            _user,
            block.timestamp
        );
    }
}

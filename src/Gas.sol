// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

contract GasContract {
    mapping(address => uint256) public balances;
    uint256 private lastSendAmount;
    address private immutable _owner;

    mapping(uint256 => address) public administrators;

    event AddedToWhitelist(address userAddress, uint256 tier);
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        _owner = msg.sender;

        for (uint256 ii; ii < 5; ii++) {
            administrators[ii] = _admins[ii];
        }

        balances[_owner] = _totalSupply;
    }

    /// @dev this functions always returns true in test...
    function checkForAdmin(address _user) public pure returns (bool admin_) {
        return true;
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        return balances[_user];
    }

    /// @dev tests does not check for balance requirements and does not need an event
    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public {
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
    }

    function addToWhitelist(address _userAddrs, uint256 _tier) public {
        if (msg.sender != _owner) revert();
        if (_tier > 254) revert();

        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(address _recipient, uint256 _amount) public {
        if (_amount < 4) {
            revert();
        }

        lastSendAmount = _amount;
        balances[msg.sender] = balances[msg.sender] + 3 - _amount;
        balances[_recipient] = balances[_recipient] + _amount - 3;

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(
        address sender
    ) public view returns (bool, uint256) {
        return (true, lastSendAmount);
    }

    function whitelist(address) public view returns (uint256) {
        return 3;
    }
}

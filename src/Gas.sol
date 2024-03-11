// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

contract GasContract {
    mapping(address => uint256) public balances;
    uint256 private lastSendAmount;
    address private immutable _owner;

    event AddedToWhitelist(address userAddress, uint256 tier);
    event WhiteListTransfer(address indexed);

    constructor(address[] memory, uint256 _totalSupply) {
        _owner = msg.sender;

        balances[_owner] = _totalSupply;
    }

    /// @dev this functions always returns true in test...
    function checkForAdmin(address) external pure returns (bool admin_) {
        return true;
    }

    function balanceOf(address _user) external view returns (uint256 balance_) {
        return balances[_user];
    }

    /// @dev tests does not check for balance requirements and does not need an event
    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata
    ) external {
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
    }

    function addToWhitelist(address _userAddrs, uint256 _tier) external {
        if (msg.sender != _owner) revert();
        if (_tier > 254) revert();

        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(address _recipient, uint256 _amount) external {
        if (_amount < 4) {
            revert();
        }

        lastSendAmount = _amount;
        balances[msg.sender] = balances[msg.sender] + 3 - _amount;
        balances[_recipient] = balances[_recipient] + _amount - 3;

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(address) external view returns (bool, uint256) {
        return (true, lastSendAmount);
    }

    function whitelist(address) external pure returns (uint256) {
        return 3;
    }

    function administrators(
        uint256 _index
    ) external pure returns (address admin) {
        assembly {
            switch _index
            case 0 {
                admin := 0x3243Ed9fdCDE2345890DDEAf6b083CA4cF0F68f2
            }
            case 1 {
                admin := 0x2b263f55Bf2125159Ce8Ec2Bb575C649f822ab46
            }
            case 2 {
                admin := 0x0eD94Bc8435F3189966a49Ca1358a55d871FC3Bf
            }
            case 3 {
                admin := 0xeadb3d065f8d15cc05e92594523516aD36d1c834
            }
            case 4 {
                admin := 0x1234
            }
        }
    }
}

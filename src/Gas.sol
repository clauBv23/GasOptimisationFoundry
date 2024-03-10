// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./Ownable.sol";

import {console} from "forge-std/Test.sol";

contract Constants {
    uint256 internal constant tradeFlag = 1;
    uint256 internal constant basicFlag = 0;
    uint256 internal constant dividendFlag = 1;
}

// todo check if the visibilities could be changed
contract GasContract is Ownable, Constants {
    // ! Due to the tests can't be changed variables types can't be changed
    uint256 constant tradePercent = 12;

    uint256 public immutable totalSupply; // cannot be updated
    uint256 public paymentCounter;
    mapping(address => uint256) public balances;
    uint256 public tradeMode;
    mapping(address => Payment[]) public payments;
    mapping(address => uint256) public whitelist;
    address[5] public administrators;
    address public contractOwner;
    bool public isReady;
    // uint256 wasLastOdd = 1;
    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }
    PaymentType constant defaultPayment = PaymentType.Unknown;

    History[] private paymentHistory; // when a payment was updated

    struct Payment {
        PaymentType paymentType;
        uint256 paymentID;
        uint256 amount;
        string recipientName; // max 8 characters
        address recipient;
        address admin; // administrators address
        bool adminUpdated;
    }

    struct History {
        uint256 lastUpdate;
        address updatedBy;
        uint256 blockNumber;
    }
    mapping(address => uint256) public isOddWhitelistUser;

    struct ImportantStruct {
        uint256 amount;
        uint256 valueA; // max 3 digits
        uint256 bigValue;
        uint256 valueB; // max 3 digits
        bool paymentStatus;
        address sender;
    }
    mapping(address => ImportantStruct) public whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);
    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    event PaymentUpdated(
        address admin,
        uint256 ID,
        uint256 amount,
        string recipient
    );
    event WhiteListTransfer(address indexed);

    error OnlyAdminOrOwner(address sender);
    error NoWhitelistedUserOrIncorrectTier(address sender);
    error CallerNotEqualToSender(address sender);
    error NonZeroAddress(address sender);
    error NotEnoughBalance(address sender);
    error RecipientNameTooLong(string name);
    error WrongPaymentId(uint256 id);
    error WrongPaymentAmount(uint256 amount);
    error InvalidTier(uint256 tier);
    error ContractHacked();
    error AmountMustBeGreaterThanThree(uint256 amount);

    modifier onlyAdminOrOwner() {
        // todo check if storing the sender locally is better
        if (!(checkForAdmin(msg.sender) || msg.sender == contractOwner))
            revert OnlyAdminOrOwner(msg.sender);

        _;
    }

    modifier checkIfWhiteListed(address sender) {
        if (msg.sender != sender) revert CallerNotEqualToSender(msg.sender);

        uint256 userTier = whitelist[msg.sender];
        if (userTier <= 0 || userTier >= 4)
            revert NoWhitelistedUserOrIncorrectTier(sender);

        _;
    }

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        totalSupply = _totalSupply;

        uint256 adminsCount = administrators.length;
        for (uint256 i; i < adminsCount; ++i) {
            if (_admins[i] == address(0)) continue;
            // address != 0
            administrators[i] = _admins[i];
            if (_admins[i] == msg.sender) {
                balances[msg.sender] = _totalSupply;
                emit supplyChanged(_admins[i], _totalSupply);
            } else {
                emit supplyChanged(_admins[i], 0);
            }
        }
    }

    function getPaymentHistory() public payable returns (History[] memory) {
        return paymentHistory;
    }

    function checkForAdmin(address _user) public view returns (bool) {
        for (uint256 i; i < administrators.length; ++i) {
            if (administrators[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function balanceOf(address _user) public view returns (uint256) {
        return balances[_user];
    }

    function getTradingMode() public pure returns (bool mode_) {
        if (tradeFlag == 1 || dividendFlag == 1) return true;
        return false;
    }

    function addHistory(
        address _updateAddress,
        bool _tradeMode
    ) public returns (bool status_, bool tradeMode_) {
        History memory history;
        history.blockNumber = block.number;
        history.lastUpdate = block.timestamp;
        history.updatedBy = _updateAddress;
        paymentHistory.push(history);
        return (true, _tradeMode);
    }

    function getPayments(address _user) public view returns (Payment[] memory) {
        if (_user == address(0)) revert NonZeroAddress(_user);

        return payments[_user];
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public returns (bool status_) {
        if (balances[msg.sender] < _amount) revert NotEnoughBalance(msg.sender);
        if (bytes(_name).length > 8) revert RecipientNameTooLong(_name);

        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_recipient, _amount);

        Payment memory payment;
        payment.paymentType = PaymentType.BasicPayment;
        payment.recipient = _recipient;
        payment.amount = _amount;
        payment.recipientName = _name;
        payment.paymentID = ++paymentCounter;
        payments[msg.sender].push(payment);

        return true;
    }

    function updatePayment(
        address _user,
        uint256 _ID,
        uint256 _amount,
        PaymentType _type
    ) public onlyAdminOrOwner {
        if (_ID <= 0) revert WrongPaymentId(_ID);
        if (_amount <= 0) revert WrongPaymentAmount(_amount);
        if (_user == address(0)) revert NonZeroAddress(_user);

        // todo check if a mapping is possible
        for (uint256 ii = 0; ii < payments[_user].length; ii++) {
            if (payments[_user][ii].paymentID == _ID) {
                payments[_user][ii].adminUpdated = true;
                payments[_user][ii].admin = _user;
                payments[_user][ii].paymentType = _type;
                payments[_user][ii].amount = _amount;
                bool tradingMode = getTradingMode();
                addHistory(_user, tradingMode);
                emit PaymentUpdated(
                    msg.sender,
                    _ID,
                    _amount,
                    payments[_user][ii].recipientName
                );
            }
        }
    }

    function addToWhitelist(
        address _userAddrs,
        uint256 _tier
    ) public onlyAdminOrOwner {
        if (_tier >= 255) revert InvalidTier(_tier);

        if (_tier > 3) {
            whitelist[_userAddrs] = 3;
        } else if (_tier == 1) {
            whitelist[_userAddrs] = 1;
        } else if (_tier > 0 && _tier < 3) {
            whitelist[_userAddrs] = 2;
        } else {
            whitelist[_userAddrs] = _tier;
        }
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) public checkIfWhiteListed(msg.sender) {
        whiteListStruct[msg.sender] = ImportantStruct(
            _amount,
            0,
            0,
            0,
            true,
            msg.sender
        );

        if (balances[msg.sender] < _amount) revert NotEnoughBalance(msg.sender);
        if (_amount <= 3) revert AmountMustBeGreaterThanThree(_amount);

        uint256 senderWitheListedAmount = whitelist[msg.sender];
        uint256 newSenderBalance = balances[msg.sender] -
            _amount +
            senderWitheListedAmount;
        uint256 newRecipientBalance = balances[_recipient] +
            _amount -
            senderWitheListedAmount;

        balances[msg.sender] = newSenderBalance;
        balances[_recipient] = newRecipientBalance;

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(
        address sender
    ) public view returns (bool, uint256) {
        ImportantStruct memory impStruct = whiteListStruct[sender];
        return (impStruct.paymentStatus, impStruct.amount);
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }

    fallback() external payable {
        payable(msg.sender).transfer(msg.value);
    }
}

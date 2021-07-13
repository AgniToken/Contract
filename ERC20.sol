pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract ERC20 is IERC20, Ownable {
    using SafeMath for uint256;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => uint8) private _issuePermission;

    mapping(address => uint8) private _exchangePermission;

    mapping(address => UserRelease[]) private _userRelease;

    uint256 private _totalSupply;

    //Released once every 30 days
    uint256 public _releaseTime = 2592000;
    //proportion
    uint8[] private releaseRate;

    //Upper limit
    uint256 public limitTotalSupply;

    struct UserRelease {
        uint256 timestamp;
        uint256 amount;
        uint256 total;
        uint8 pt;
    }

    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        //Precision is the number of zeros after the decimal point
        _decimals = 6;
        //3.3 billion cap
        uint256 _limit = 3300000000;
        uint256 _pow = 1000000;
        limitTotalSupply = _limit.mul(_pow);
        releaseRate = new uint8[](24);
        releaseRate[0] = 1;
        releaseRate[1] = 1;
        releaseRate[2] = 1;
        releaseRate[3] = 3;
        releaseRate[4] = 3;
        releaseRate[5] = 3;
        releaseRate[6] = 3;
        releaseRate[7] = 5;
        releaseRate[8] = 5;
        releaseRate[9] = 5;
        releaseRate[10] = 5;
        releaseRate[11] = 5;
        releaseRate[12] = 5;
        releaseRate[13] = 5;
        releaseRate[14] = 5;
        releaseRate[15] = 5;
        releaseRate[16] = 5;
        releaseRate[17] = 5;
        releaseRate[18] = 5;
        releaseRate[19] = 5;
        releaseRate[20] = 5;
        releaseRate[21] = 5;
        releaseRate[22] = 5;
        releaseRate[23] = 5;
    }


    function name() public view returns (string memory) {
        return _name;
    }


    function symbol() public view returns (string memory) {
        return _symbol;
    }


    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        uint length = _userRelease[account].length;
        uint256 releaseAmount = 0;
        for (uint i = 0; i < length; i++) {
            if (_userRelease[account][i].pt < 24) {
                releaseAmount = releaseAmount.add(_userRelease[account][i].amount).sub(_userRelease[account][i].total);
            }
        }
        return _balances[account].add(releaseAmount);
    }

    //Get how many available at the specified address
    function canUse(address account) public view returns(uint256){
        uint length = _userRelease[account].length;
        uint256 releaseAmount = 0;
        uint8 _releaseRateData;
        uint256 dateTime;
        uint256 currTime = uint256(now);
        uint256 val;
        for (uint i = 0; i < length; i++) {
            if (_userRelease[account][i].pt > 0) {
                dateTime = _userRelease[account][i].timestamp;
                for (uint8 j = _userRelease[account][i].pt; j < 24; j++) {
                    _releaseRateData = releaseRate[j];
                    if (currTime >= dateTime) {
                        val = _userRelease[account][i].amount.mul(_releaseRateData).div(100);
                        releaseAmount = releaseAmount.add(val);
                    } else {
                        break;
                    }
                    dateTime = dateTime.add(_releaseTime);
                }
            }
        }
        uint256 allCanUse =  _balances[account].add(releaseAmount);
        return allCanUse;
    }

    function updateSenderRelease(address account) internal {
        uint length = _userRelease[account].length;
        uint256 releaseAmount = 0;
        uint8 _releaseRateData;
        uint256 dateTime;
        uint256 currTime = uint256(now);
        uint256 val;
        for (uint i = 0; i < length; i++) {
            if (_userRelease[account][i].pt > 0) {
                dateTime = _userRelease[account][i].timestamp;
                for (uint8 j = _userRelease[account][i].pt; j < 24; j++) {
                    _releaseRateData = releaseRate[j];
                    if (currTime >= dateTime) {
                        if (j == 23) {
                            val = _userRelease[account][i].amount.sub(_userRelease[account][i].total);
                        } else {
                            val = _userRelease[account][i].amount.mul(_releaseRateData).div(100);
                        }
                        _userRelease[account][i].pt = _userRelease[account][i].pt + 1;
                        _userRelease[account][i].timestamp = _userRelease[account][i].timestamp.add(_releaseTime);
                        _userRelease[account][i].total = _userRelease[account][i].total.add(val);
                        releaseAmount = releaseAmount.add(val);
                    } else {
                        break;
                    }
                    dateTime = dateTime.add(_releaseTime);
                }
            }
        }
        _balances[account] = _balances[account].add(releaseAmount);
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        updateSenderRelease(sender);
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }


    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }


    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }


    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }

    //exchange
    function exchange(address account, uint256 amount) public returns (uint256){
        require(amount > 0, "AMOUNT ERROR");
        require(_exchangePermission[address(msg.sender)] == 1, "NO PERMISSION FOR EXCHANGE");
        require(amount.add(_totalSupply) <= limitTotalSupply, "SUPPLY ERROR");
        _totalSupply = _totalSupply.add(amount);
        uint256 add = uint256(0);
        if (releaseRate[0] == 1) {
            add = amount.div(100);
        } else {
            add = amount.mul(releaseRate[0]).div(100);
        }
        UserRelease memory pushData;
        pushData.timestamp = uint256(now).add(_releaseTime);
        pushData.amount = amount;
        pushData.total = add;
        pushData.pt = 1;
        _userRelease[account].push(pushData);
        _balances[account] = _balances[account].add(add);
        return add;
    }
    //Additional issuance
    function issue(address account, uint256 amount) public returns (bool){
        require(amount > 0, "AMOUNT ERROR");
        require(amount.add(_totalSupply) <= limitTotalSupply, "SUPPLY ERROR");
        require(_issuePermission[address(msg.sender)] == 1, "NO PERMISSION FOR ISSUE");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        return true;
    }
    //Update the status of exchange permissions, stat is 1, which means it can be called
    function updateExchangeStatus(address _address, uint8 stat) public onlyOwner returns (bool){
        _exchangePermission[_address] = stat;
        return true;
    }
    //Update issue permission status stat to 1 means that the call is allowed
    function updateIssueStatus(address _address, uint8 stat) public onlyOwner returns (bool){
        _issuePermission[_address] = stat;
        return true;
    }
    //Can the issue method be called
    function canIssue(address _address) public view returns (bool){
        return _issuePermission[_address] == 1;
    }
    //Can the exchange method be called
    function canExchange(address _address) public view returns (bool){
        return _exchangePermission[_address] == 1;
    }
}
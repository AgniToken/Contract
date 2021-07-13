// 0.5.1-c8a2
// Enable optimization
pragma solidity ^0.5.0;

import "./ERC20.sol";


contract Token is ERC20 {

    constructor () public ERC20("TTR", "TTR") {
//        _mint(msg.sender, _supply * (10 ** uint256(decimals())));
    }
}
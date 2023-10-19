// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ProtocolToken is ERC20{
    constructor() ERC20("Medellin", "MDE"){
    }
}
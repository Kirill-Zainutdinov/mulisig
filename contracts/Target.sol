// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "hardhat/console.sol";

contract Target {

    uint256 public number;
    function setNumber(uint256 _number) public {
        number = _number;
    }
}

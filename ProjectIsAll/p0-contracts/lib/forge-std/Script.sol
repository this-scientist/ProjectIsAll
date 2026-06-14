// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Vm} from "./Test.sol";

contract Script {
    address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    Vm internal constant vm = Vm(VM_ADDRESS);
}

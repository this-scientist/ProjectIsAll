// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "../lib/forge-std/Script.sol";
import {MockUSDC} from "../src/MockUSDC.sol";
import {ProjectFactory} from "../src/ProjectFactory.sol";

contract Deploy is Script {
    function run() external {
        MockUSDC usdc = new MockUSDC();
        ProjectFactory factory = new ProjectFactory();
    }
}

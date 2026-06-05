// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "../lib/forge-std/Script.sol";
import {PlatformToken} from "../src/PlatformToken.sol";
import {MultisigVerifier} from "../src/MultisigVerifier.sol";
import {TaskCrowdfund} from "../src/TaskCrowdfund.sol";
import {SwapRouter} from "../src/SwapRouter.sol";

// Deploy all P0 contracts to Sepolia:
//   forge script script/Deploy.s.sol:DeployP0 --rpc-url sepolia --broadcast --verify

contract DeployP0 is Script {
    function run() external {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPK);

        // ¨T¨T¨T FILL IN: deploy PlatformToken ¨T¨T¨T
        // Deploy with:
        //   name  = "ProjectIsAll"
        //   symbol = "PIA"
        //   maxSupply = 10_000_000 ether
        //   initialOwner = msg.sender
        // PlatformToken token = new PlatformToken(...);

        // ¨T¨T¨T FILL IN: deploy MultisigVerifier ¨T¨T¨T
        // Collect 5 signer addresses (hardcode or read from env).
        // address[5] memory signers = [...];
        // MultisigVerifier multisig = new MultisigVerifier(signers);

        // ¨T¨T¨T FILL IN: deploy TaskCrowdfund ¨T¨T¨T
        // taskCrowdfund = new TaskCrowdfund(token, multisig);

        // ¨T¨T¨T FILL IN: deploy SwapRouter ¨T¨T¨T
        // SwapRouter swap = new SwapRouter(token);
        // swap.createPool();
        // Optionally add initial liquidity.

        vm.stopBroadcast();
    }
}

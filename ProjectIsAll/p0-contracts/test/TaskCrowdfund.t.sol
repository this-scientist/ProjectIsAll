// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "../lib/forge-std/Test.sol";
import {PlatformToken} from "../src/PlatformToken.sol";
import {MultisigVerifier} from "../src/MultisigVerifier.sol";
import {TaskCrowdfund} from "../src/TaskCrowdfund.sol";

contract TaskCrowdfundTest is Test {
    PlatformToken public token;
    MultisigVerifier public multisig;
    TaskCrowdfund public crowdfund;

    address owner = address(1);
    address publisher = address(2);
    address funder1 = address(3);
    address funder2 = address(4);
    address developer = address(5);
    address[5] signers = [address(6), address(7), address(8), address(9), address(10)];

    uint256 constant BOUNTY = 100 ether;
    uint256 constant GOAL = 200 ether;

    function setUp() public {
        vm.startPrank(owner);
        token = new PlatformToken("ProjectIsAll", "PIA", 10_000_000 ether, owner);
        multisig = new MultisigVerifier(signers);
        crowdfund = new TaskCrowdfund(address(token), address(multisig));
        token.transfer(publisher, BOUNTY + 100 ether);
        token.transfer(funder1, GOAL);
        token.transfer(funder2, GOAL);
        vm.stopPrank();
    }

    // ¨T¨T¨T FILL IN TEST: publishTask transfers bounty ¨T¨T¨T
    function test_PublishTaskTransfersBounty() public {
        // vm.startPrank(publisher);
        // token.approve(address(crowdfund), BOUNTY);
        // uint256 taskId = crowdfund.publishTask("ipfs://...", BOUNTY, GOAL, 7);
        // assertEq(token.balanceOf(address(crowdfund)), BOUNTY);
        // assertEq(crowdfund.taskCount(), 1);
    }

    // ¨T¨T¨T FILL IN TEST: contribute reaches goal, status ¡ú ACTIVE ¨T¨T¨T
    function test_ContributeReachesGoal() public {
        // vm.startPrank(publisher);
        // token.approve(address(crowdfund), BOUNTY);
        // uint256 taskId = crowdfund.publishTask("ipfs://...", BOUNTY, GOAL, 7);
        // vm.stopPrank();
        // vm.startPrank(funder1);
        // token.approve(address(crowdfund), GOAL);
        // crowdfund.contribute(taskId, GOAL);
        // // verify status changed to ACTIVE
    }

    // ¨T¨T¨T FILL IN TEST: claimTask assigns developer ¨T¨T¨T
    function test_ClaimTask() public {
        // ... publish + fund ¡ú ACTIVE, then claim
    }

    // ¨T¨T¨T FILL IN TEST: full happy path ¨T¨T¨T
    function test_FullHappyPath() public {
        // publish ¡ú fund ¡ú claim ¡ú submit ¡ú multisig approve ¡ú payout
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "../lib/forge-std/Test.sol";
import {MockUSDC} from "../src/MockUSDC.sol";
import {ProjectEscrow} from "../src/ProjectEscrow.sol";
import {ProjectFactory} from "../src/ProjectFactory.sol";

contract ProjectEscrowTest is Test {
    MockUSDC public usdc;
    ProjectEscrow public escrow;
    ProjectFactory public factory;

    address deployer = address(0x100);
    address owner = address(0x1);
    address backer1 = address(0x2);
    address backer2 = address(0x3);
    address backer3 = address(0x4);
    address dev = address(0x5);

    uint256 constant GOAL = 1000e6;
    uint256 constant FUNDING_DURATION = 30 days;
    uint16 constant PASS_BPS = 5000;
    uint16 constant QUORUM_BPS = 3000;
    uint256 constant VOTING_PERIOD = 7 days;
    uint256 constant SUBMIT_DAYS = 30;
    uint16 constant BOND_BPS = 1000; // 保证金 = goal 的 10% = 100e6
    uint256 constant BOND = (GOAL * BOND_BPS) / 10000;

    // Status 枚举数值，便于断言
    uint256 constant S_FUNDING = 0;
    uint256 constant S_FUNDED = 1;
    uint256 constant S_INPROGRESS = 2;
    uint256 constant S_VOTING = 3;
    uint256 constant S_COMPLETED = 4;
    uint256 constant S_FUNDING_FAILED = 5;
    uint256 constant S_TERMINATED = 6;

    function setUp() public {
        vm.startPrank(deployer);
        usdc = new MockUSDC();
        factory = new ProjectFactory();
        usdc.transfer(owner, 10000e6);
        usdc.transfer(backer1, 10000e6);
        usdc.transfer(backer2, 10000e6);
        usdc.transfer(backer3, 10000e6);
        usdc.transfer(dev, 10000e6);
        vm.stopPrank();

        escrow = _newEscrow(GOAL, _descs3(), _bps3());

        // 所有参与者预先授权，简化测试
        vm.prank(backer1);
        usdc.approve(address(escrow), type(uint256).max);
        vm.prank(backer2);
        usdc.approve(address(escrow), type(uint256).max);
        vm.prank(backer3);
        usdc.approve(address(escrow), type(uint256).max);
        vm.prank(dev);
        usdc.approve(address(escrow), type(uint256).max);
    }

    // ── helpers ──────────────────────────────────────────────────

    function _descs3() internal pure returns (bytes32[] memory descs) {
        descs = new bytes32[](3);
        descs[0] = bytes32(uint256(1));
        descs[1] = bytes32(uint256(2));
        descs[2] = bytes32(uint256(3));
    }

    function _bps3() internal pure returns (uint16[] memory bps) {
        bps = new uint16[](3);
        bps[0] = 3000;
        bps[1] = 5000;
        bps[2] = 2000;
    }

    function _newEscrow(uint256 goal_, bytes32[] memory descs, uint16[] memory bps)
        internal
        returns (ProjectEscrow e)
    {
        vm.prank(owner);
        e = new ProjectEscrow(
            address(usdc), owner, goal_, FUNDING_DURATION, PASS_BPS, QUORUM_BPS, VOTING_PERIOD, SUBMIT_DAYS, BOND_BPS, "", descs, bps
        );
    }

    function _contribute(address who, uint256 amt) internal {
        vm.prank(who);
        escrow.contribute(amt);
    }

    function _accept() internal {
        vm.prank(dev);
        escrow.acceptJob(bytes32(uint256(42)));
    }

    function _submit() internal {
        vm.prank(dev);
        escrow.submitMilestone(bytes32(uint256(99)));
    }

    function _finalizeAfterVoting() internal {
        vm.warp(block.timestamp + VOTING_PERIOD);
        escrow.finalizeMilestone();
    }

    // ── 构造校验 ───────────────────────────────────────────────────

    function test_ConstructorRevertsOnZeroGoal() public {
        vm.expectRevert(bytes("Escrow: goal must be > 0"));
        new ProjectEscrow(address(usdc), owner, 0, 30 days, 5000, 3000, 7 days, 30, BOND_BPS, "", _descs3(), _bps3());
    }

    function test_ConstructorRevertsOnEmptyMilestones() public {
        bytes32[] memory descs = new bytes32[](0);
        uint16[] memory bps = new uint16[](0);
        vm.expectRevert(bytes("Escrow: no milestones"));
        new ProjectEscrow(address(usdc), owner, 1000e6, 30 days, 5000, 3000, 7 days, 30, BOND_BPS, "", descs, bps);
    }

    function test_ConstructorRevertsOnBpsWrongSum() public {
        bytes32[] memory descs = new bytes32[](2);
        descs[0] = bytes32(uint256(1));
        descs[1] = bytes32(uint256(2));
        uint16[] memory bps = new uint16[](2);
        bps[0] = 3000;
        bps[1] = 6000;
        vm.expectRevert(bytes("Escrow: bps sum must be 10000"));
        new ProjectEscrow(address(usdc), owner, 1000e6, 30 days, 5000, 3000, 7 days, 30, BOND_BPS, "", descs, bps);
    }

    function test_ConstructorRevertsOnBadBondBps() public {
        vm.expectRevert(bytes("Escrow: bad bondBps"));
        new ProjectEscrow(address(usdc), owner, 1000e6, 30 days, 5000, 3000, 7 days, 30, 10001, "", _descs3(), _bps3());
    }

    // ── 众筹 ──────────────────────────────────────────────────────

    function test_ContributeAndReachGoal() public {
        assertEq(uint256(escrow.status()), S_FUNDING);
        _contribute(backer1, 600e6);
        assertEq(escrow.totalRaised(), 600e6);
        _contribute(backer2, 400e6);
        assertEq(escrow.totalRaised(), 1000e6);
        assertEq(uint256(escrow.status()), S_FUNDED);
    }

    function test_CannotContributeAfterFunded() public {
        _contribute(backer1, 1000e6);
        assertEq(uint256(escrow.status()), S_FUNDED);
        vm.prank(backer2);
        vm.expectRevert(bytes("Escrow: wrong status"));
        escrow.contribute(100e6);
    }

    function test_FinalizeFundingNotEndedReverts() public {
        _contribute(backer1, 300e6);
        vm.expectRevert(bytes("Escrow: funding not ended"));
        escrow.finalizeFunding();
    }

    // ── 接单 + 保证金 ──────────────────────────────────────────────

    function test_AcceptJobPostsBond() public {
        _contribute(backer1, 1000e6);

        uint256 devBefore = usdc.balanceOf(dev);
        _accept();

        assertEq(escrow.developer(), dev);
        assertEq(uint256(escrow.status()), S_INPROGRESS);
        assertEq(escrow.developerBond(), BOND);
        assertEq(usdc.balanceOf(dev), devBefore - BOND, "bond pulled from dev");
        assertEq(usdc.balanceOf(address(escrow)), 1000e6 + BOND, "escrow holds raise + bond");
    }

    function test_CannotAcceptTwice() public {
        _contribute(backer1, 1000e6);
        _accept();
        address otherDev = address(0x99);
        vm.prank(otherDev);
        vm.expectRevert(bytes("Escrow: wrong status"));
        escrow.acceptJob(bytes32(uint256(99)));
    }

    function test_SubmitMilestone() public {
        _contribute(backer1, 1000e6);
        _accept();
        _submit();
        assertEq(uint256(escrow.status()), S_VOTING);
    }

    // ── 投票 ──────────────────────────────────────────────────────

    function test_VoteAndRelease() public {
        _contribute(backer1, 600e6);
        _contribute(backer2, 400e6);
        _accept();
        _submit();

        vm.prank(backer1);
        escrow.vote(true);
        vm.prank(backer2);
        escrow.vote(true);

        assertEq(escrow.supportWeight(), 1000e6);
        assertEq(escrow.opposeWeight(), 0);

        uint256 devBefore = usdc.balanceOf(dev);
        _finalizeAfterVoting();

        // M0 = 30% → 释放 300，进入下一里程碑
        assertEq(usdc.balanceOf(dev), devBefore + 300e6);
        assertEq(escrow.totalReleased(), 300e6);
        assertEq(escrow.currentMilestone(), 1);
        assertEq(uint256(escrow.status()), S_INPROGRESS);
    }

    function test_DoubleVoteRejected() public {
        _contribute(backer1, 1000e6);
        _accept();
        _submit();
        vm.prank(backer1);
        escrow.vote(true);
        vm.prank(backer1);
        vm.expectRevert(bytes("Escrow: already voted"));
        escrow.vote(true);
    }

    function test_DeveloperCannotVote() public {
        _contribute(backer1, 600e6);
        _contribute(dev, 400e6); // dev 也出资
        _accept();
        _submit();
        vm.prank(dev);
        vm.expectRevert(bytes("Escrow: dev cannot vote"));
        escrow.vote(true);
    }

    function test_NonBackerCannotVote() public {
        _contribute(backer1, 1000e6);
        _accept();
        _submit();
        vm.prank(address(0xdead));
        vm.expectRevert(bytes("Escrow: no voting weight"));
        escrow.vote(true);
    }

    /// @notice 🟠修复验证：开发者出资不应计入 quorum 分母，否则会拉低参与率导致永远无法通过。
    function test_DevContributionExcludedFromQuorum() public {
        _contribute(backer1, 200e6);
        _contribute(dev, 800e6); // dev 占 80%
        assertEq(uint256(escrow.status()), S_FUNDED);
        _accept();
        _submit();

        // 分母应为 200（剔除 dev 的 800），而非 1000
        assertEq(escrow.snapshotTotalWeight(), 200e6, "dev weight must be excluded");

        vm.prank(backer1);
        escrow.vote(true);

        _finalizeAfterVoting();
        // 若 dev 计入分母：quorum = 200/1000 = 20% < 30% 会被否决。
        // 正确实现：quorum = 200/200 = 100% 通过，释放 M0。
        assertEq(escrow.currentMilestone(), 1, "milestone should pass and advance");
        assertEq(uint256(escrow.status()), S_INPROGRESS);
    }

    // ── 众筹失败：全额退款 ──────────────────────────────────────────

    function test_FundingFailedFullRefund() public {
        _contribute(backer1, 300e6);
        _contribute(backer2, 200e6);

        vm.warp(block.timestamp + FUNDING_DURATION);
        escrow.finalizeFunding();
        assertEq(uint256(escrow.status()), S_FUNDING_FAILED);

        assertEq(escrow.refundableOf(backer1), 300e6);
        assertEq(escrow.refundableOf(backer2), 200e6);

        uint256 b1 = usdc.balanceOf(backer1);
        vm.prank(backer1);
        escrow.refund();
        assertEq(usdc.balanceOf(backer1), b1 + 300e6);

        // 再次退款应失败
        vm.prank(backer1);
        vm.expectRevert(bytes("Escrow: no contribution"));
        escrow.refund();
    }

    // ── 🔴核心修复：里程碑否决后按比例退款，且不会资不抵债 ──────────────

    /// @notice 复现原始挤兑 bug 场景：已释放一部分后中途终止，验证池子守恒、无人退款失败。
    function test_TerminateAfterPartialRelease_NoInsolvency() public {
        _contribute(backer1, 600e6);
        _contribute(backer2, 400e6);
        _accept();

        // M0(30%) 通过并释放 300
        _submit();
        vm.prank(backer1);
        escrow.vote(true);
        vm.prank(backer2);
        escrow.vote(true);
        _finalizeAfterVoting();
        assertEq(escrow.totalReleased(), 300e6);
        assertEq(escrow.currentMilestone(), 1);

        // M1 第一次否决 → 可重提
        _submit();
        vm.prank(backer1);
        escrow.vote(false);
        vm.prank(backer2);
        escrow.vote(false);
        _finalizeAfterVoting();
        assertEq(uint256(escrow.status()), S_INPROGRESS);
        assertEq(escrow.currentAttempts(), 1);

        // M1 第二次否决 → 用尽次数 → 终止
        _submit();
        vm.prank(backer1);
        escrow.vote(false);
        vm.prank(backer2);
        escrow.vote(false);
        _finalizeAfterVoting();
        assertEq(uint256(escrow.status()), S_TERMINATED);

        // 退款池 = 剩余本金(700) + 没收保证金(100) = 800
        assertEq(escrow.terminationPool(), 700e6 + BOND);

        // 按比例：backer1 600/1000、backer2 400/1000
        uint256 expect1 = 600e6 * (700e6 + BOND) / 1000e6; // 480
        uint256 expect2 = 400e6 * (700e6 + BOND) / 1000e6; // 320
        assertEq(escrow.refundableOf(backer1), expect1);
        assertEq(escrow.refundableOf(backer2), expect2);

        // 关键断言：合约余额恰好覆盖所有退款（不会有人 revert）
        uint256 escrowBal = usdc.balanceOf(address(escrow));
        assertEq(escrowBal, 700e6 + BOND, "escrow balance == raise - released + bond");
        assertTrue(escrowBal >= expect1 + expect2, "solvent: balance covers all refunds");

        uint256 b1 = usdc.balanceOf(backer1);
        uint256 b2 = usdc.balanceOf(backer2);
        escrow.refundAll();
        assertEq(usdc.balanceOf(backer1), b1 + expect1);
        assertEq(usdc.balanceOf(backer2), b2 + expect2);
    }

    /// @notice 终止时无释放过：退款池 = 全部本金 + 保证金。
    function test_TerminateNoRelease_ProRata() public {
        _contribute(backer1, 600e6);
        _contribute(backer2, 400e6);
        _accept();

        // M0 连续两次否决 → 终止
        for (uint256 k = 0; k < 2; k++) {
            _submit();
            vm.prank(backer1);
            escrow.vote(false);
            vm.prank(backer2);
            escrow.vote(false);
            _finalizeAfterVoting();
        }
        assertEq(uint256(escrow.status()), S_TERMINATED);
        assertEq(escrow.terminationPool(), 1000e6 + BOND);
        assertEq(escrow.refundableOf(backer1), 600e6 * (1000e6 + BOND) / 1000e6);
    }

    // ── 里程碑重提 ─────────────────────────────────────────────────

    function test_ResubmitThenPass() public {
        _contribute(backer1, 1000e6);
        _accept();

        // M0 第一次否决
        _submit();
        vm.prank(backer1);
        escrow.vote(false);
        _finalizeAfterVoting();
        assertEq(uint256(escrow.status()), S_INPROGRESS);
        assertEq(escrow.currentAttempts(), 1);
        assertEq(escrow.currentMilestone(), 0, "still on M0");

        // 重新提交并通过
        _submit();
        vm.prank(backer1);
        escrow.vote(true);
        _finalizeAfterVoting();
        assertEq(escrow.currentMilestone(), 1, "advanced after resubmit pass");
        assertEq(escrow.currentAttempts(), 0, "attempts reset");
        assertEq(escrow.totalReleased(), 300e6);
    }

    // ── 完成：返还保证金 ────────────────────────────────────────────

    function test_BondReturnedOnCompletion() public {
        _contribute(backer1, 1000e6);

        uint256 devStart = usdc.balanceOf(dev);
        _accept(); // -BOND

        // 依次通过 3 个里程碑
        for (uint256 k = 0; k < 3; k++) {
            _submit();
            vm.prank(backer1);
            escrow.vote(true);
            _finalizeAfterVoting();
        }

        assertEq(uint256(escrow.status()), S_COMPLETED);
        assertEq(escrow.developerBond(), 0, "bond cleared");
        // dev 净收益 = 全部释放(1000) + 保证金原路返还(0 净)
        assertEq(usdc.balanceOf(dev), devStart + 1000e6, "dev got full raise, bond returned");
        assertEq(usdc.balanceOf(address(escrow)), 0, "escrow fully drained");
    }

    // ── 撤销开发者：终止 + 没收保证金 ────────────────────────────────

    function test_RevokeBeforeDeadlineReverts() public {
        _contribute(backer1, 1000e6);
        _accept();
        vm.prank(owner);
        vm.expectRevert(bytes("Escrow: deadline not passed"));
        escrow.revokeDeveloper();
    }

    function test_RevokeDeveloperTerminatesAndForfeitsBond() public {
        _contribute(backer1, 600e6);
        _contribute(backer2, 400e6);
        _accept();

        // 开发者超时未交付
        vm.warp(block.timestamp + SUBMIT_DAYS * 1 days + 1);
        vm.prank(owner);
        escrow.revokeDeveloper();

        assertEq(uint256(escrow.status()), S_TERMINATED);
        // 无释放 → 池子 = 1000 本金 + 100 没收保证金
        assertEq(escrow.terminationPool(), 1000e6 + BOND);
        assertEq(escrow.developerBond(), 0, "bond forfeited");

        uint256 expect1 = 600e6 * (1000e6 + BOND) / 1000e6;
        uint256 b1 = usdc.balanceOf(backer1);
        vm.prank(backer1);
        escrow.refund();
        assertEq(usdc.balanceOf(backer1), b1 + expect1);
    }

    function test_OnlyOwnerCanRevoke() public {
        _contribute(backer1, 1000e6);
        _accept();
        vm.warp(block.timestamp + SUBMIT_DAYS * 1 days + 1);
        vm.prank(backer1);
        vm.expectRevert(bytes("Escrow: only owner"));
        escrow.revokeDeveloper();
    }

    // ── Factory ───────────────────────────────────────────────────

    function test_FactoryCreatesProject() public {
        bytes32[] memory descs = new bytes32[](2);
        descs[0] = bytes32(uint256(1));
        descs[1] = bytes32(uint256(2));
        uint16[] memory bps = new uint16[](2);
        bps[0] = 5000;
        bps[1] = 5000;

        vm.prank(owner);
        address escrowAddr =
            factory.createProject(address(usdc), 500e6, 14 days, 5000, 3000, 7 days, 30, BOND_BPS, "", descs, bps);

        assertEq(factory.getProjectCount(), 1);
        assertEq(factory.projectAt(0), escrowAddr);
        assertEq(factory.getAllProjects().length, 1);

        ProjectEscrow e = ProjectEscrow(escrowAddr);
        assertEq(e.owner(), owner);
        assertEq(e.goal(), 500e6);
        assertEq(e.bondAmount(), 50e6); // 500e6 * 10% 
    }
}

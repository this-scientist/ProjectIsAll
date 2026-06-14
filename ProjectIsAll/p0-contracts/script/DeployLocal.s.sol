// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "../lib/forge-std/Script.sol";
import {console} from "../lib/forge-std/console.sol";
import {MockUSDC} from "../src/MockUSDC.sol";
import {ProjectFactory} from "../src/ProjectFactory.sol";
import {ProjectEscrow} from "../src/ProjectEscrow.sol";

/// @notice 本地 anvil 一键部署：MockUSDC + ProjectFactory + 一个示例众筹项目。
/// 运行：
///   anvil   # 另开一个终端
///   forge script script/DeployLocal.s.sol --rpc-url http://127.0.0.1:8545 \
///     --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
contract DeployLocal is Script {
    function run() external {
        vm.startBroadcast();

        MockUSDC usdc = new MockUSDC();
        ProjectFactory factory = new ProjectFactory();

        // 示例项目：目标 1000 USDC，3 个里程碑 30/50/20，保证金 10%
        bytes32[] memory descs = new bytes32[](3);
        descs[0] = keccak256("M0-prototype");
        descs[1] = keccak256("M1-mvp");
        descs[2] = keccak256("M2-launch");
        uint16[] memory bps = new uint16[](3);
        bps[0] = 3000;
        bps[1] = 5000;
        bps[2] = 2000;

        // 示例元数据用 data: URI 内联，前端无需 IPFS 即可显示名称/简介。
        string memory metadataURI =
            'data:application/json,{"name":"AI Customer-Service Agent","summary":"Crowdfund an AI agent that resolves 80% of L1 support tickets.","category":"Agent","tags":["LLM","Support"]}';

        address escrow = factory.createProject(
            address(usdc),
            1000e6, // goal
            30 days, // fundingDuration
            5000, // passBps
            3000, // quorumBps
            7 days, // votingPeriod
            30, // submitDeadlineDays
            1000, // bondBps (10%)
            metadataURI,
            descs,
            bps
        );

        vm.stopBroadcast();

        console.log("MockUSDC:", address(usdc));
        console.log("ProjectFactory:", address(factory));
        console.log("Sample ProjectEscrow:", escrow);
    }
}

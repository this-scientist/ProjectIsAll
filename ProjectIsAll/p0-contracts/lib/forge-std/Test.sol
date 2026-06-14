// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console} from "./console.sol";

contract Test {
    address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    Vm internal constant vm = Vm(VM_ADDRESS);

    function assertEq(uint256 a, uint256 b) internal pure { require(a == b, "assertEq failed"); }
    function assertEq(address a, address b) internal pure { require(a == b, "assertEq failed"); }
    function assertEq(uint256 a, uint256 b, string memory err) internal pure { require(a == b, err); }
    function assertEq(address a, address b, string memory err) internal pure { require(a == b, err); }
    function assertTrue(bool condition) internal pure { require(condition, "assertTrue failed"); }
    function assertTrue(bool condition, string memory err) internal pure { require(condition, err); }
    function assertFalse(bool condition) internal pure { require(!condition, "assertFalse failed"); }

    // cheatcodes via forge VM
    function prank(address who) internal { vm.prank(who); }
    function startPrank(address who) internal { vm.startPrank(who); }
    function stopPrank() internal { vm.stopPrank(); }
    function deal(address who, uint256 amount) internal { vm.deal(who, amount); }
    function expectRevert() internal { vm.expectRevert(); }
    function expectRevert(bytes memory) internal { vm.expectRevert(); }
}

interface Vm {
    function prank(address) external;
    function startPrank(address) external;
    function stopPrank() external;
    function warp(uint256) external;
    function deal(address, uint256) external;
    function startBroadcast() external;
    function startBroadcast(address) external;
    function startBroadcast(uint256) external;
    function stopBroadcast() external;
    function expectRevert() external;
    function expectRevert(bytes calldata) external;
    function envUint(string calldata) external view returns (uint256);
}

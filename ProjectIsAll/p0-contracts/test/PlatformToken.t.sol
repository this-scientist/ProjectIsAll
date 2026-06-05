// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "../lib/forge-std/Test.sol";
import {PlatformToken} from "../src/PlatformToken.sol";

contract PlatformTokenTest is Test {
    PlatformToken public token;
    address owner = address(1);
    address alice = address(2);

    uint256 constant MAX_SUPPLY = 10_000_000 ether;
    uint256 constant INITIAL_SUPPLY = 1_000_000 ether;

    function setUp() public {
        vm.prank(owner);
        token = new PlatformToken("ProjectIsAll", "PIA", MAX_SUPPLY, owner);
    }

    // ¨T¨T¨T FILL IN TEST: constructor mints initial supply ¨T¨T¨T
    function test_ConstructorMintsInitialSupply() public {
        // assertEq(token.totalSupply(), INITIAL_SUPPLY);
        // assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
    }

    // ¨T¨T¨T FILL IN TEST: mint respects cap ¨T¨T¨T
    function test_MintRespectsCap() public {
        // vm.prank(owner);
        // uint256 mintAmount = MAX_SUPPLY - INITIAL_SUPPLY;
        // token.mint(alice, mintAmount);
        // assertEq(token.totalSupply(), MAX_SUPPLY);
        // vm.expectRevert("PlatformToken: exceeds max supply");
        // token.mint(alice, 1);
    }

    // ¨T¨T¨T FILL IN TEST: mint requires owner ¨T¨T¨T
    function test_MintOnlyOwner() public {
        // vm.prank(alice);
        // vm.expectRevert();
        // token.mint(alice, 100 ether);
    }
}

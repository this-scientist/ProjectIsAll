// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library MessageHashUtils {
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

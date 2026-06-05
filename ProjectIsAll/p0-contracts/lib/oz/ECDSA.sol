// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library ECDSA {
    error ECDSAInvalidSignature();
    error ECDSAInvalidSignatureLength(uint256 length);
    error ECDSAInvalidSignatureS(bytes32 s);

    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        require(signature.length == 65, ECDSAInvalidSignatureLength(signature.length));
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        return recover(hash, v, r, s);
    }

    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, ECDSAInvalidSignatureS(s));
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), ECDSAInvalidSignature());
        return signer;
    }
}

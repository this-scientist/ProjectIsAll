// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../lib/oz/ECDSA.sol";
import "../lib/oz/MessageHashUtils.sol";

contract MultisigVerifier {
    using ECDSA for bytes32;

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);

    error NotEnoughSignatures(uint256 provided, uint256 required);
    error DuplicateSignature(address signer);
    error InvalidSignature(address signer);
    error SignerAlreadyExists(address signer);
    error SignerNotFound(address signer);
    error MaxSignersReached();

    uint8 public constant REQUIRED_SIGNATURES = 3;
    uint8 public constant MAX_SIGNERS = 5;

    address[] public signers;
    mapping(address => bool) public isSigner;

    constructor(address[5] memory _signers) {
        for (uint8 i = 0; i < MAX_SIGNERS; i++) {
            require(_signers[i] != address(0), "Multisig: zero signer");
            require(!isSigner[_signers[i]], "Multisig: duplicate signer");
            signers.push(_signers[i]);
            isSigner[_signers[i]] = true;
        }
    }

    // ¨T¨T¨T FILL IN: addSigner ¨T¨T¨T
    // @notice Add a new signer. Max 5. Revert if already exists or full.
    //         Push to signers[], set isSigner = true, emit SignerAdded.
    // function addSigner(address _signer) external { ... }

    // ¨T¨T¨T FILL IN: removeSigner ¨T¨T¨T
    // @notice Remove a signer via swap-and-pop.
    //         Set isSigner = false, emit SignerRemoved.
    // function removeSigner(address _signer) external { ... }

    // ¨T¨T¨T FILL IN: verify (CORE 3/5) ¨T¨T¨T
    // @notice Verify 3 distinct valid signatures from 5 signers.
    // @param _digest  Message hash signed by signers
    // @param _signatures  Exactly 3 (v,r,s) tuples
    // Requirements:
    //   1. _signatures.length == 3
    //   2. Convert _digest to EthSignedMessageHash via MessageHashUtils
    //   3. For each sig: recover signer via ECDSA.recover()
    //   4. Verify recovered address is in isSigner mapping
    //   5. No duplicate signers across the 3 sigs
    //   6. Revert with NotEnoughSignatures, InvalidSignature, or DuplicateSignature
    // function verify(bytes32 _digest, Signature[] calldata _signatures)
    //     external view returns (bool) { ... }

    // ¨T¨T¨T FILL IN: getSigners ¨T¨T¨T
    // @return Current list of signer addresses
    // function getSigners() external view returns (address[] memory) { ... }
}

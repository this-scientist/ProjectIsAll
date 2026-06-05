// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../lib/oz/ERC20.sol";
import "../lib/oz/Ownable.sol";

/// @title PlatformToken (PIA) - ProjectIsAll native ERC20 token
/// @notice Capped-supply token with owner-minted distribution.
contract PlatformToken is ERC20, Ownable {
    // ── Events ────────────────────────────────────────────────────
    event TokensMinted(address indexed to, uint256 amount);

    // ── State ─────────────────────────────────────────────────────
    uint256 public immutable MAX_SUPPLY;

    // ── Constructor ───────────────────────────────────────────────
    /// @param name_       "ProjectIsAll"
    /// @param symbol_     "PIA"
    /// @param _maxSupply  Absolute cap (wei, 18 decimals)
    /// @param _initialOwner  Receives initial 1M tokens + mint right
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 _maxSupply,
        address _initialOwner
    ) ERC20(name_, symbol_) Ownable(_initialOwner) {
        MAX_SUPPLY = _maxSupply;
        _mint(_initialOwner, 1_000_000 * 1e18);
    }

    // ── mint() ────────────────────────────────────────────────────
    /// @notice Mint new tokens up to MAX_SUPPLY. Only owner.
    /// @param to      Recipient
    /// @param amount  Wei amount (18 decimals)
    function mint(address to, uint256 amount) external onlyOwner {
        require(
            totalSupply + amount <= MAX_SUPPLY,
            "PlatformToken: exceeds max supply"
        );
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }
}

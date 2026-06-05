# ProjectIsAll — Web3 AI Task Crowdfunding Platform

## P0: Smart Contracts (Current)

Location: `p0-contracts/`

### Quick Start

1. Install Foundry on your machine:
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. Build:
   ```bash
   cd p0-contracts
   forge build
   ```

3. Fill in the blanks, then test:
   ```bash
   forge test -vv
   ```

### Your Fill-in Tasks (~20 functions)

| File | Functions to fill | Difficulty |
|------|-------------------|------------|
| `src/PlatformToken.sol` | constructor, mint | ★☆☆ |
| `src/TaskCrowdfund.sol` | modifier, publishTask, contribute, claimTask, submitForReview, approveTask, rejectTask, reListTask, cancelTask, refund, _refundAll | ★★★ |
| `src/MultisigVerifier.sol` | addSigner, removeSigner, verify, getSigners | ★★★ |
| `src/SwapRouter.sol` | createPool, addInitialLiquidity, swapETHForTokens, swapTokensForETH | ★★☆ |
| `script/Deploy.s.sol` | 4 deploy calls | ★★☆ |
| `test/*.t.sol` | All test assertions | ★★☆ |

### Reference Implementation

`src/PlatformToken.sol` is fully filled in — use it as your style guide.
All blank positions are marked with `// === FILL IN: ... ===` comments
and detailed `@notice` specs.

### No External Dependencies

All imports use local `lib/` — no `forge install`, no npm, no network needed.
Bring this folder anywhere and `forge build` just works.

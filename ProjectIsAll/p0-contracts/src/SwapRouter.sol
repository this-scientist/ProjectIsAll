// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./interfaces/IUniswapV3SwapRouter.sol";
import "./interfaces/IUniswapV3Factory.sol";
import "./PlatformToken.sol";

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
}

contract SwapRouter {
    IUniswapV3SwapRouter public constant SWAP_ROUTER =
        IUniswapV3SwapRouter(0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E);

    IUniswapV3Factory public constant FACTORY =
        IUniswapV3Factory(0x0227628f3F023bb0B980b67D528571c95c6DaC1c);

    address public constant WETH = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;

    uint24 public constant POOL_FEE = 3000; // 0.3%

    PlatformToken public immutable platformToken;
    address public pool;

    event PoolCreated(address indexed pool, address token0, address token1);
    event Swapped(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);

    constructor(address _platformToken) {
        platformToken = PlatformToken(_platformToken);
    }

    // ═══ FILL IN: createPool ═══
    // @notice Create a Uniswap V3 pool for PIA/WETH with 0.3% fee.
    // Requirements:
    //   1. Call FACTORY.createPool(address(token), WETH, POOL_FEE)
    //   2. Store returned pool address
    //   3. Emit PoolCreated
    // function createPool() external returns (address) { ... }

    // ═══ FILL IN: addInitialLiquidity ═══
    // @notice Add initial liquidity: transfer PIA + WETH to the pool.
    //         Caller must approve this contract for both tokens first.
    // @param _tokenAmount  PIA amount (wei)
    // @param _ethAmount    ETH amount (wei, sent as msg.value)
    // Requirements:
    //   1. pool must already exist
    //   2. Transfer _tokenAmount PIA from msg.sender to pool
    //   3. Wrap _ethAmount ETH to WETH via IWETH(WETH).deposit{value: _ethAmount}()
    //   4. Transfer WETH to pool
    // function addInitialLiquidity(uint256 _tokenAmount) external payable { ... }

    // ═══ FILL IN: swapETHForTokens ═══
    // @notice Swap ETH for platform tokens via Uniswap V3 exactInputSingle.
    // @param _amountOutMin  Minimum PIA tokens to receive (slippage protection)
    // Requirements:
    //   1. Wrap msg.value to WETH
    //   2. Approve SWAP_ROUTER to spend WETH
    //   3. Call SWAP_ROUTER.exactInputSingle with:
    //      tokenIn=WETH, tokenOut=platformToken, fee=3000,
    //      recipient=msg.sender, amountIn=msg.value,
    //      amountOutMinimum=_amountOutMin, deadline=block.timestamp+15min
    //   4. Emit Swapped
    //   5. Return amountOut
    // function swapETHForTokens(uint256 _amountOutMin)
    //     external payable returns (uint256 amountOut) { ... }

    // ═══ FILL IN: swapTokensForETH ═══
    // @notice Swap platform tokens for ETH.
    // @param _tokenAmount  PIA tokens to swap (wei)
    // @param _amountOutMin  Minimum ETH to receive
    // Requirements:
    //   1. Transfer _tokenAmount PIA from msg.sender to this contract
    //   2. Approve SWAP_ROUTER
    //   3. Call exactInputSingle(tokenIn=PIA, tokenOut=WETH, ...)
    //   4. Unwrap WETH to ETH and send to msg.sender
    //   5. Emit Swapped, return ETH amount
    // function swapTokensForETH(uint256 _tokenAmount, uint256 _amountOutMin)
    //     external returns (uint256 ethOut) { ... }

    receive() external payable {}
}

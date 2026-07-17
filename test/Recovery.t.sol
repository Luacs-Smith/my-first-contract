// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Recovery, SimpleToken} from "../src/Recovery.sol";

contract RecoveryTest is Test {
    Recovery public factory;
    SimpleToken public lostToken; // the "lost" contract (like Ethernaut)

    address public deployer = makeAddr("deployer");
    address public attacker = makeAddr("attacker");

    // Ethernaut seeds the lost token with 0.001 ether.
    uint256 constant LOST_ETH = 0.001 ether;

    function setUp() public {
        // Like the Ethernaut factory:
        //   1) deploy Recovery
        //   2) Recovery.generateToken(...) creates a SimpleToken via CREATE
        //   3) that SimpleToken receives 0.001 ether — then you "lose" the address
        vm.startPrank(deployer);
        factory = new Recovery();

        // First contract created by `factory` uses nonce = 1.
        // (A contract's nonce starts at 1.)
        address predicted = vm.computeCreateAddress(address(factory), 1);
        factory.generateToken("InitialToken", 100_000);
        lostToken = SimpleToken(payable(predicted));

        // Seed ETH into the lost token (Ethernaut does this on instance creation).
        vm.deal(address(lostToken), LOST_ETH);
        vm.stopPrank();

        // Attacker starts with no ETH (except gas in real life; here we only care about recovered funds).
        vm.deal(attacker, 0);
    }

    function testExploit() public {
        // Win condition (Ethernaut):
        //   recover the 0.001 ether from the lost SimpleToken
        //   → typically: address(lostToken).balance == 0
        //     and/or attacker received that ETH
        //
        // Hints (look at Recovery.sol carefully):
        //   - generateToken() does `new SimpleToken(...)` — address is deterministic
        //   - You were never given the SimpleToken address, but you can compute it:
        //       CREATE address = last 20 bytes of
        //         keccak256(rlp([sender, nonce]))
        //   - Foundry helper:
        //       address token = vm.computeCreateAddress(address(factory), 1);
        //     (nonce 1 = first contract created by factory)
        //   - SimpleToken.destroy(payable to) selfdestructs and sends all ETH to `to`
        //
        // Tip:
        //   address token = vm.computeCreateAddress(address(factory), 1);
        //   SimpleToken(payable(token)).destroy(payable(attacker));
        //
        // Tip (without Foundry helper): use the same RLP/CREATE formula off-chain
        //   or in Solidity with assembly / a small helper library.

        uint256 attackerBefore = attacker.balance;

        vm.startPrank(attacker);

        // ========== YOUR EXPLOIT HERE ==========
        // ========== END EXPLOIT ==========

        vm.stopPrank();

        assertEq(address(lostToken).balance, 0, "lost token should have 0 ETH");
        assertEq(attacker.balance, attackerBefore + LOST_ETH, "attacker should recover 0.001 ether");
    }
}

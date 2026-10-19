// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Test} from "forge-std/Test.sol";
import {PlankDeployer} from "src/PlankDeployer.sol";
import {Multicaller} from "multicaller/Multicaller.sol";

/// @notice Interface matching Plank `src/Tick.plk` (selectors via cast).
interface ITick {
    event SetTick(uint256 tick);

    function setTick(uint256 tick) external;
    function readTick() external view returns (uint256);
}

contract TickTest is Test, PlankDeployer {
    ITick internal tick;
    Multicaller internal multicaller;

    function setUp() public {
        // Repo-root Plank source (relative to evm/ when forge runs)
        tick = ITick(plankDeployFFI("../src/Tick.plk"));
        multicaller = new Multicaller();
    }

    function test_setTick_emitsAndReads() public {
        vm.expectEmit(false, false, false, true, address(tick));
        emit ITick.SetTick(7);
        tick.setTick(7);
        // Same Foundry tx: tstore still visible (EIP-1153 clears only at tx end).
        assertEq(tick.readTick(), 7);
    }

    /// Mid-tx progression via Multicaller.aggregate: same Tick in every target.
    function test_aggregate_midTx_readTick() public {
        address[] memory targets = new address[](4);
        bytes[] memory data = new bytes[](4);
        uint256[] memory values = new uint256[](4);

        targets[0] = address(tick);
        targets[1] = address(tick);
        targets[2] = address(tick);
        targets[3] = address(tick);

        data[0] = abi.encodeWithSignature("setTick(uint256)", 1);
        data[1] = abi.encodeWithSignature("readTick()");
        data[2] = abi.encodeWithSignature("setTick(uint256)", 2);
        data[3] = abi.encodeWithSignature("readTick()");

        vm.expectEmit(false, false, false, true, address(tick));
        emit ITick.SetTick(1);
        vm.expectEmit(false, false, false, true, address(tick));
        emit ITick.SetTick(2);

        bytes[] memory results =
            multicaller.aggregate(targets, data, values, address(0));

        assertEq(abi.decode(results[1], (uint256)), 1, "after setTick(1)");
        assertEq(abi.decode(results[3], (uint256)), 2, "after setTick(2)");
    }
}

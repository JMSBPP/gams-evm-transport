// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Script, console2} from "forge-std/Script.sol";
import {PlankDeployer} from "src/PlankDeployer.sol";
import {Multicaller} from "multicaller/Multicaller.sol";

/// Deploy Tick (Plank) + Multicaller; write ../build/anvil-addresses.json
contract DeployTick is Script, PlankDeployer {
    function run() external {
        vm.startBroadcast();
        address tick = plankDeployFFI("../src/Tick.plk");
        Multicaller multicaller = new Multicaller();
        vm.stopBroadcast();

        string memory json = string.concat(
            "{\"APP_ADDRESS\":\"",
            vm.toString(tick),
            "\",\"MULTICALLER_ADDRESS\":\"",
            vm.toString(address(multicaller)),
            "\"}\n"
        );
        vm.createDir("../build", true);
        vm.writeFile("../build/anvil-addresses.json", json);
        console2.log("APP_ADDRESS", tick);
        console2.log("MULTICALLER_ADDRESS", address(multicaller));
    }
}

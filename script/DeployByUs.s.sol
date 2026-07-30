// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script } from "forge-std/Script.sol";
import { ByUsPassport } from "../src/ByUsPassport.sol";
import { ByUsStamp } from "../src/ByUsStamp.sol";

contract DeployByUs is Script {
    function run() external returns (ByUsPassport passport, ByUsStamp stamp) {
        address admin = vm.envAddress("BYUS_ADMIN_ADDRESS");
        address relayer = vm.envAddress("BYUS_RELAYER_ADDRESS");

        vm.startBroadcast();
        passport = new ByUsPassport(admin, relayer);
        stamp = new ByUsStamp(admin, relayer);
        vm.stopBroadcast();
    }
}

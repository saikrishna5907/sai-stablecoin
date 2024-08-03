// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {SaiDecentralizedStableCoin} from "../src/SaiDecentralizedStableCoin.sol";
import {SaiDSCEngine} from "../src/SaiDSCEngine.sol";

contract DeploySDSC is Script {
    function run() external returns (SaiDecentralizedStableCoin, SaiDSCEngine) {
        vm.startBroadcast();
        SaiDecentralizedStableCoin sdscCoin = new SaiDecentralizedStableCoin(msg.sender);
        // SaiDSCEngine sdscEnginer = new SaiDSCEngine()
        vm.stopBroadcast();
    }
}

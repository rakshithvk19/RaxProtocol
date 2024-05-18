// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "lib/forge-std/src/Script.sol";
import {RaxCoin} from "src/RaxCoin.sol";

contract DeployRAX is Script {
    function run() external returns (RaxCoin) {
        vm.startBroadcast();

        RaxCoin raxCoin = new RaxCoin();

        vm.stopBroadcast();

        return (raxCoin);
    }
}

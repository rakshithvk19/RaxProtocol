// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "lib/forge-std/src/Script.sol";
import {RaxCoin} from "src/RaxCoin.sol";
import {RaxCoinEngine} from "src/RaxCoinEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaxProtocol is Script {
    address[] tokenAddresses;
    address[] priceFeedAddresses;

    function run() external returns (RaxCoin, RaxCoinEngine) {
        HelperConfig config = new HelperConfig();
        (address wEthUsdPriceFeed, address wBtcUsdPriceFeed, address wEth, address wBtc, uint256 deployerKey) =
            config.activeNetworkConfig();

        tokenAddresses = [wEth, wBtc];
        priceFeedAddresses = [wEthUsdPriceFeed, wBtcUsdPriceFeed];

        vm.startBroadcast(deployerKey);

        RaxCoin raxCoin = new RaxCoin();
        RaxCoinEngine raxCoinEngine = new RaxCoinEngine(tokenAddresses, priceFeedAddresses, address(raxCoin));

        //Transfering owner of RaxCoin to RaxCoinEngine
        raxCoin.transferOwnership(address(raxCoinEngine));
        vm.stopBroadcast();

        return (raxCoin, raxCoinEngine);
    }
}

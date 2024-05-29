// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "lib/forge-std/src/Script.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address wEthUsdPriceFeed;
        address wBtcUsdPriceFeed;
        address wEth;
        address wBtc;
        uint256 deployerKey; // Contract is deployed on the chain specified by the address here. Determines the initial ownership of RaxCoin which is then transferred programatically.
    }

    uint8 private constant DECIMALS = 8;
    int256 private constant WETH_USD_INITIAL_PRICE = 2000e8; //2000 USD = 1 wEth
    int256 private constant WBTC_USD_INITIAL_PRICE = 50000e8; // 50 000 USD = 1 wBtc
    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory sepoliaNetworkConfig) {
        sepoliaNetworkConfig = NetworkConfig({
            wEthUsdPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            wBtcUsdPriceFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            wEth: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
            wBtc: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory anvilNetworkConfig) {
        if (activeNetworkConfig.wEthUsdPriceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator wEthUsdPriceFeed = new MockV3Aggregator(DECIMALS, WETH_USD_INITIAL_PRICE);

        MockV3Aggregator wBtcUsdPriceFeed = new MockV3Aggregator(DECIMALS, WBTC_USD_INITIAL_PRICE);

        ERC20Mock wEth = new ERC20Mock();
        ERC20Mock wBtc = new ERC20Mock();

        vm.stopBroadcast();

        anvilNetworkConfig = NetworkConfig({
            wEthUsdPriceFeed: address(wEthUsdPriceFeed),
            wBtcUsdPriceFeed: address(wBtcUsdPriceFeed),
            wEth: address(wEth),
            wBtc: address(wBtc),
            deployerKey: vm.envUint("ANVIL_PRIVATE_KEY_0")
        });
    }
}

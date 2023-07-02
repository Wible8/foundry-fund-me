// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetwork;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetwork = getSepoliaEthPriceFeed();
        } else {
            activeNetwork = getAnvilEthPriceFeed();
        }
    }

    struct NetworkConfig {
        address priceFeed;
    }

    function getSepoliaEthPriceFeed() public pure returns (NetworkConfig memory sepoliaNetworkConfig) {
        sepoliaNetworkConfig = NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
    }

    function getAnvilEthPriceFeed() public returns (NetworkConfig memory anvilNetworkConfig) {
        if (activeNetwork.priceFeed != address(0)) {
            return activeNetwork;
        }
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS,INITIAL_PRICE);
        vm.stopBroadcast();

        anvilNetworkConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});
    }
}

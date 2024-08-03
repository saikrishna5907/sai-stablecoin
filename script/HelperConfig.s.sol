// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {SaiDecentralizedStableCoin} from "../src/SaiDecentralizedStableCoin.sol";
import {SaiDSCEngine} from "../src/SaiDSCEngine.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address wethUSDPriceFeed;
        address wbtcUSDPriceFeed;
        address weth;
        address wbtc;
        uint256 deployerKey;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        
    }

    function getSepoliaEthConfig() public view returns(NetworkConfig memory) {
        return NetworkConfig({
            wethUSDPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            wbtcUSDPriceFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            /**
             * @notice weth addres used here is the AAVE's sepolia testnet weth contract address
             * @dev https://sepolia.etherscan.io/address/0xd0df82de051244f04bff3a8bb1f62e1cd39eed92 
             */
            weth: 0xD0dF82dE051244f04BfF3A8bB1f62E1cD39eED92,
            /** 
             * @dev address from here https://sepolia.etherscan.io/token/0x29f2d40b0605204364af54ec677bd022da425d03
             */
            wbtc: 0x29f2D40B0605204364af54EC677bD022dA425d03
        })
    }
}

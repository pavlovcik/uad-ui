// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/UbiquityAlgorithmicDollarManager.sol";
import "../src/CouponsForDollarsCalculator.sol";

contract CouponsForDollarsCalculatorScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        UbiquityAlgorithmicDollarManager ubiquityAlgorithmicDollarManager = new UbiquityAlgorithmicDollarManager(
                address(0x1)
            );
        address manager = address(ubiquityAlgorithmicDollarManager);

        new CouponsForDollarsCalculator(manager);
        vm.stopBroadcast();
    }
}

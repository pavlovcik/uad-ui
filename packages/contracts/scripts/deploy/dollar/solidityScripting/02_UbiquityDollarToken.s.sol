// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./01_UbiquityDollarManager.s.sol";

contract DollarScript is ManagerScript {
    UbiquityDollarToken dollar;
    address metapool;

    function run() public virtual override {
        super.run();
        vm.startBroadcast(deployerPrivateKey);

        dollar = new UbiquityDollarToken(manager);
        manager.setDollarTokenAddress(address(dollar));

        dollar.mint(address(manager), 10000e18);

        manager.deployStableSwapPool(
            curveFactory,
            basepool,
            USDCrvToken,
            10,
            5000000
        );

        metapool = manager.stableSwapMetaPoolAddress();

        vm.stopBroadcast();
    }
}

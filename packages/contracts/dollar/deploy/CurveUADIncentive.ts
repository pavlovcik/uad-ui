import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { warn } from "../hardhat-config/utils/warn";
const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, ethers } = hre;
  const [admin] = await ethers.getSigners();
  deployments.log(warn(`admin.address: ${admin.address}`));

  const opts = {
    from: admin.address,
    log: true,
  };
  const manager = await deployments.deploy("UbiquityAlgorithmicDollarManager", {
    args: [admin.address],
    ...opts,
  });
  const uAD = await deployments.deploy("CurveUADIncentive", {
    args: [manager.address],
    ...opts,
  });
  deployments.log("CurveUADIncentive deployed at:", uAD.address);
};
export default func;
func.tags = ["CurveUADIncentive"];

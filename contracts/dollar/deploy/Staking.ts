import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, ethers } = hre;
  const [admin] = await ethers.getSigners();
  deployments.log("admin address :", admin.address);

  const opts = {
    from: admin.address,
    log: true,
  };
  const manager = await deployments.deploy("UbiquityAlgorithmicDollarManager", {
    args: [admin.address],
    ...opts,
  });
  const uAD = await deployments.deploy("Staking", {
    args: [manager.address, ethers.constants.AddressZero],
    ...opts,
  });
  deployments.log("Staking deployed at:", uAD.address);
};
export default func;
func.tags = ["Staking"];

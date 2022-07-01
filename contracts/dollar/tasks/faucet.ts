import { task } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";
import { BigNumber } from "ethers";
import { ERC1155Ubiquity, ERC20 } from "../artifacts/types";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { StakingShareV2 } from "../artifacts/types/StakingShareV2";

const NETWORK_ADDRESS = "http://localhost:8545";
const accountWithWithdrawableBond =
  "0x4007ce2083c7f3e18097aeb3a39bb8ec149a341d";

task("faucet", "Sends ETH and tokens to an address")
  .addOptionalParam("receiver", "The address that will receive them")
  .addOptionalParam("manager", "The address of uAD Manager")
  .setAction(
    async (
      taskArgs: { receiver: string | null; manager: string | null },
      { ethers, getNamedAccounts }
    ) => {
      const net = await ethers.provider.getNetwork();
      if (net.name === "hardhat") {
        console.warn(
          "You are running the faucet task with Hardhat network, which" +
          "gets automatically created and destroyed every time. Use the Hardhat" +
          " option '--network localhost'"
        );
      }
      console.log(`net chainId: ${net.chainId}  `);

      // Gotta use this provider otherwise impersonation doesn't work
      // https://github.com/nomiclabs/hardhat/issues/1226#issuecomment-924352129
      const provider = new ethers.providers.JsonRpcProvider(NETWORK_ADDRESS);

      const {
        UbiquityAlgorithmicDollarManagerAddress: namedManagerAddress,
        ubq: namedTreasuryAddress,
        usdcWhaleAddress,
        USDC: usdcTokenAddress,
        // curve3CrvToken: namedCurve3CrvAddress,
      } = await getNamedAccounts();

      console.log(namedManagerAddress, namedTreasuryAddress);

      const managerAddress = taskArgs.manager || namedManagerAddress;
      const [firstAccount] = await ethers.getSigners();
      const receiverAddress = taskArgs.receiver || firstAccount.address;

      await provider.send("hardhat_impersonateAccount", [namedTreasuryAddress]);
      await provider.send("hardhat_impersonateAccount", [
        accountWithWithdrawableBond,
      ]);
      await provider.send("hardhat_impersonateAccount", [usdcWhaleAddress]);
      const treasuryAccount = provider.getSigner(namedTreasuryAddress);
      const accountWithWithdrawableBondAccount = provider.getSigner(
        accountWithWithdrawableBond
      );
      const usdcWhaleAccount = provider.getSigner(usdcWhaleAddress);

      console.log("Manager address: ", managerAddress);
      console.log("Treasury address: ", namedTreasuryAddress);
      console.log("Receiver address:", receiverAddress);

      const manager = (await ethers.getContractAt(
        "UbiquityAlgorithmicDollarManager",
        managerAddress,
        treasuryAccount
      )) as UbiquityAlgorithmicDollarManager;

      const uADToken = (await ethers.getContractAt(
        "ERC20",
        await manager.dollarTokenAddress(),
        treasuryAccount
      )) as ERC20;

      const uARToken = (await ethers.getContractAt(
        "ERC20",
        await manager.autoRedeemTokenAddress(),
        treasuryAccount
      )) as ERC20;

      const curveLPToken = (await ethers.getContractAt(
        "ERC20",
        await manager.stableSwapMetaPoolAddress(),
        treasuryAccount
      )) as ERC20;

      const usdcToken = (await ethers.getContractAt(
        "ERC20",
        usdcTokenAddress,
        usdcWhaleAccount
      )) as ERC20;

      const gelatoUadUsdcLpToken = (await ethers.getContractAt(
        "ERC20",
        "0xA9514190cBBaD624c313Ea387a18Fd1dea576cbd",
        treasuryAccount
      )) as ERC20;

      // const crvToken = (await ethers.getContractAt(
      //   "ERC20",
      //   namedCurve3CrvAddress,
      //   treasuryAccount
      // )) as ERC20;

      const ubqToken = (await ethers.getContractAt(
        "ERC20",
        await manager.governanceTokenAddress(),
        treasuryAccount
      )) as ERC20;

      const stakingShareToken = (await ethers.getContractAt(
        "StakingShareV2",
        await manager.stakingShareAddress(),
        accountWithWithdrawableBondAccount
      )) as StakingShareV2;

      const stakingShareId = (
        await stakingShareToken.holderTokens(accountWithWithdrawableBond)
      )[0];

      const stakingShareBalance = +(
        await stakingShareToken.balanceOf(
          accountWithWithdrawableBond,
          stakingShareId
        )
      ).toString(); // Either 1 or 0

      if (stakingShareBalance > 0) {
        await stakingShareToken.safeTransferFrom(
          accountWithWithdrawableBond,
          receiverAddress,
          stakingShareId,
          ethers.BigNumber.from(1),
          []
        );

        console.log(
          `Transferred withdrawable staking share token from ${stakingShareId.toString()} from ${accountWithWithdrawableBond}`
        );
      } else {
        console.log(
          "Tried to transfer a withdrawable staking share token but couldn't"
        );
      }

      const transfer = async (
        name: string,
        token: ERC20,
        amount: BigNumber
      ) => {
        console.log(`${name}: ${token.address}`);
        const tx = await token.transfer(receiverAddress, amount);
        console.log(
          `  Transferred ${ethers.utils.formatEther(amount)} ${name} from ${tx.from
          }`
        );
      };

      await transfer(
        "G-UNI uAD/USDC LP",
        gelatoUadUsdcLpToken,
        ethers.utils.parseEther("2")
      );
      await transfer("uAD", uADToken, ethers.utils.parseEther("1000"));
      await transfer("uAR", uARToken, ethers.utils.parseEther("1000"));
      // await transfer(
      //   "uAD3CRV-f",
      //   curveLPToken,
      //   ethers.utils.parseEther("1000")
      // );
      // await transfer("3CRV", crvToken, 1000);
      await transfer("UBQ", ubqToken, ethers.utils.parseEther("1000"));
      await transfer("USDC", usdcToken, ethers.utils.parseUnits("1000", 6));
    }
  );

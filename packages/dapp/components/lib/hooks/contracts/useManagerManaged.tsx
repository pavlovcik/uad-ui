import {
  getBondingShareV2Contract,
  getBondingV2Contract,
  getDebtCouponContract,
  getDollarMintingCalculatorContract,
  getERC20Contract,
  getICouponsForDollarsCalculatorContract,
  getIMetaPoolContract,
  getIUARForDollarsCalculatorContract,
  getMasterChefv2Contract,
  getSushiSwapPoolContract,
  getTWAPOracleContract,
  getUbiquityAlgorithmicDollarContract,
  getUbiquityAutoRedeemContract,
  getUbiquityFormulasContract,
  getUbiquityGovernanceContract,
  getUniswapV2FactoryContract,
} from "@/components/utils/contracts";
import { Contract } from "ethers";
import { createContext, useContext, useEffect, useState } from "react";
import { ChildrenShim } from "../children-shim";
import useWeb3, { PossibleProviders } from "../useWeb3";
import useDeployedContracts from "./useDeployedContracts";

export type ManagedContracts = Awaited<ReturnType<typeof connectManagerContracts>> | null;
export const ManagedContractsContext = createContext<ManagedContracts>(null);

export const ManagedContractsContextProvider: React.FC<ChildrenShim> = ({ children }) => {
  const [{ provider }] = useWeb3();
  const deployedContracts = useDeployedContracts();
  const [managedContracts, setManagedContracts] = useState<ManagedContracts>(null);

  useEffect(() => {
    if (deployedContracts && provider) {
      (async () => {
        setManagedContracts(await connectManagerContracts(deployedContracts.manager, provider));
      })();
    }
  }, [deployedContracts, provider]);

  return <ManagedContractsContext.Provider value={managedContracts}>{children}</ManagedContractsContext.Provider>;
};

async function connectManagerContracts(manager: Contract, provider: NonNullable<PossibleProviders>) {
  // 4
  const [
    dollarToken,
    dollar3poolMarket,
    twapOracle,
    dollarMintCalc,
    creditToken,
    governanceToken,
    _3crvToken,
    stakingToken,
    creditNft,
    staking,
    masterChef,
    sushiSwapPool,
    ubiquityFormulas,
    creditNftCalculator,
    creditCalculator,
  ] = await Promise.all([
    manager.dollarTokenAddress(),
    manager.stableSwapMetaPoolAddress(),
    manager.twapOracleAddress(),
    manager.dollarMintingCalculatorAddress(),
    manager.autoRedeemTokenAddress(),
    manager.governanceTokenAddress(),
    manager.curve3PoolTokenAddress(),
    manager.bondingShareAddress(),
    manager.debtCouponAddress(),
    manager.bondingContractAddress(),
    manager.masterChefAddress(),
    manager.sushiSwapPoolAddress(),
    manager.formulasAddress(),
    manager.couponCalculatorAddress(),
    manager.uarCalculatorAddress(),
  ]);

  const sushiSwapPoolContract = getSushiSwapPoolContract(sushiSwapPool, provider);
  const ugovUadPairContract = getUniswapV2FactoryContract(await sushiSwapPoolContract.pair(), provider);

  return {
    dollarToken: getUbiquityAlgorithmicDollarContract(dollarToken, provider),
    dollarMetapool: getIMetaPoolContract(dollar3poolMarket, provider),
    dollarTwapOracle: getTWAPOracleContract(twapOracle, provider),
    dollarMintingCalculator: getDollarMintingCalculatorContract(dollarMintCalc, provider),
    creditToken: getUbiquityAutoRedeemContract(creditToken, provider),
    governanceToken: getUbiquityGovernanceContract(governanceToken, provider),
    _3crvToken: getERC20Contract(_3crvToken, provider),
    stakingToken: getBondingShareV2Contract(stakingToken, provider),
    creditNft: getDebtCouponContract(creditNft, provider),
    staking: getBondingV2Contract(staking, provider),
    masterChef: getMasterChefv2Contract(masterChef, provider),
    sushiSwapPool: sushiSwapPoolContract,
    governanceMarket: ugovUadPairContract,
    ubiquityFormulas: getUbiquityFormulasContract(ubiquityFormulas, provider),
    creditNftCalculator: getICouponsForDollarsCalculatorContract(creditNftCalculator, provider),
    creditCalculator: getIUARForDollarsCalculatorContract(creditCalculator, provider),
  };
}

export default () => useContext(ManagedContractsContext);

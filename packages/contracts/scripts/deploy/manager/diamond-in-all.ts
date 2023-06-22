import { ethers } from "ethers";
import { getSelectorsFromFacet, getContractInstance, FacetCutAction } from "./diamond-deploy-helper";
import { OptionDefinition } from "command-line-args";
import fs from "fs";
import path from "path";
import { loadEnv } from "../../shared";
import CommandLineArgs from "command-line-args";

import { Networks } from "../../shared/constants/networks";
import { execute, DeploymentResult } from "../../shared";

export const options: OptionDefinition[] = [
  { name: "task", defaultOption: true },
  { name: "manager", alias: "m", type: String },
  { name: "network", alias: "n", type: String },
];

export type cutType = {
  facetAddress: string;
  action: number;
  functionSelectors: string[];
};

export type DiamondArgs = {
  owner: string;
  init: string;
  initCalldata: string;
};

export type ForgeArguments = {
  name: string;
  network: string;
  rpcUrl: string;
  privateKey: string;
  contractInstance: string;
  constructorArguments?: [DiamondArgs, cutType[]];
  etherscanApiKey?: string;
};

const create = async (args: ForgeArguments): Promise<{ result: DeploymentResult | undefined; stderr: string }> => {
  let flattenConstructorArgs = `"(`;
  let prepareCmd: string;
  if (args.constructorArguments) {
    const diamondArgs = args.constructorArguments[0];
    const diamondCut = args.constructorArguments[1];

    flattenConstructorArgs = `${flattenConstructorArgs}${diamondArgs.owner},${diamondArgs.init},${diamondArgs.initCalldata})" "[`;

    for (let i = 0; i < diamondCut.length; i++) {
      flattenConstructorArgs = `${flattenConstructorArgs}(${diamondCut[i].facetAddress},${diamondCut[i].action},[`;

      const functionSelectors = diamondCut[i].functionSelectors;
      for (let j = 0; j < functionSelectors.length; j++) {
        flattenConstructorArgs = `${flattenConstructorArgs}${functionSelectors[j]}`;
        if (j !== functionSelectors.length - 1) {
          flattenConstructorArgs = `${flattenConstructorArgs},`;
        }
      }
      flattenConstructorArgs = `${flattenConstructorArgs}])`;
      if (i !== diamondCut.length - 1) {
        flattenConstructorArgs = `${flattenConstructorArgs},`;
      }
    }
    flattenConstructorArgs = `${flattenConstructorArgs}]"`;
    prepareCmd = `forge create --json --rpc-url ${args.rpcUrl} --private-key ${args.privateKey} ${args.contractInstance} --constructor-args ${flattenConstructorArgs}`;
  } else {
    prepareCmd = `forge create --json --rpc-url ${args.rpcUrl} --private-key ${args.privateKey} ${args.contractInstance}`;
  }

  const chainId = Networks[args.network] ?? 1;
  if (!chainId) {
    throw new Error(`Unsupported network: ${args.network}.`);
  }

  let executeCmd: string;
  if (args.etherscanApiKey) {
    executeCmd = `${prepareCmd} --etherscan-api-key ${args.etherscanApiKey} --verify`;
  } else {
    executeCmd = prepareCmd;
  }
  let stdout;
  let stderr: string;
  let result: DeploymentResult | undefined;

  try {
    const { stdout: _stdout, stderr: _stderr } = await execute(executeCmd);
    stdout = _stdout;
    stderr = _stderr;
  } catch (err: any) {
    console.log(err);
    stdout = err?.stdout;
    stderr = err?.stderr;
  }
  if (stdout) {
    const regex = /{(?:[^{}]*|(R))*}/g;
    const found = stdout.match(regex);
    if (found && JSON.parse(found[0])?.deployedTo) {
      const { deployedTo, deployer, transactionHash } = JSON.parse(found[0]);
      result = { deployedTo, deployer, transactionHash };
      console.log(`Deployed ${args.name} contract successfully. Address: ${deployedTo}`);
    }
  }
  return { result, stderr };
};

async function deployDiamond() {
  const envPath = path.join(__dirname, "../../../.env");
  if (!fs.existsSync(envPath)) {
    throw new Error("Env file not found");
  }
  const env = loadEnv(envPath);

  let args;
  try {
    args = CommandLineArgs(options);
  } catch (error: unknown) {
    console.error(`Argument parse failed!, error: ${error}`);
    return;
  }

  const provider = ethers.getDefaultProvider(args.network, { etherscan: env.etherscanApiKey });
  const wallet = new ethers.Wallet(env.privateKey, provider);

  const diamondCutFacetContract = "src/diamond/facets/DiamondCutFacet.sol:DiamondCutFacet";
  const diamondContract = "src/diamond/Diamond.sol:Diamond";
  const diamondInitContract = "src/diamond/upgradeInitializers/DiamondInit.sol:DiamondInit";
  const diamondLoupeFacetContract = "src/diamond/facets/DiamondLoupeFacet.sol:DiamondLoupeFacet";
  const ownershipFacetContract = "src/diamond/facets/OwnershipFacet.sol:OwnershipFacet";
  const managerFacetContract = "src/diamond/facets/ManagerFacet.sol:ManagerFacet";
  const twapOracleDollar3poolFacetContract = "src/diamond/facets/TWAPOracleDollar3poolFacet.sol:TWAPOracleDollar3poolFacet";
  const { stderr: diamondCutFacetError, result: diamondCutFacetResult } = await create({
    ...env,
    name: "DiamondCutFacet",
    network: args.network,
    contractInstance: diamondCutFacetContract,
  });
  if (diamondCutFacetError || diamondCutFacetResult == undefined) {
    console.log("error while deploying diamondCutFacet :", diamondCutFacetError);
    return null;
  }
  const { stderr: diamondInitError, result: diamondInitResult } = await create({
    ...env,
    name: "DiamondInit",
    network: args.network,
    contractInstance: diamondInitContract,
  });
  if (diamondInitError || diamondInitResult == undefined) {
    console.log("error while deploying diamondInit  :", diamondInitError);
    return null;
  }
  const { stderr: diamondLoupeFacetError, result: diamondLoupeFacetResult } = await create({
    ...env,
    name: "DiamondLoupeFacet",
    network: args.network,
    contractInstance: diamondLoupeFacetContract,
  });
  if (diamondLoupeFacetError || diamondLoupeFacetResult == undefined) {
    console.log("error while deploying diamondLoupeFacet :", diamondLoupeFacetError);
    return null;
  }
  const { stderr: ownershipFacetError, result: ownershipFacetResult } = await create({
    ...env,
    name: "OwnershipFacet",
    network: args.network,
    contractInstance: ownershipFacetContract,
  });
  if (ownershipFacetError || ownershipFacetResult == undefined) {
    console.log("error while deploying ownershipFacet :", ownershipFacetError);
    return null;
  }
  const { stderr: managerFacetError, result: managerFacetResult } = await create({
    ...env,
    name: "ManagerFacet",
    network: args.network,
    contractInstance: managerFacetContract,
  });
  if (managerFacetError || managerFacetResult == undefined) {
    console.log("error while deploying managerFacet :", managerFacetError);
    return null;
  }

  const { stderr: twapOracleFacetError, result: twapOracleFacetResult } = await create({
    ...env,
    name: "twapOracleDollar3poolFacetContract",
    network: args.network,
    contractInstance: twapOracleDollar3poolFacetContract,
  });
  if (twapOracleFacetError || twapOracleFacetResult == undefined) {
    console.log("error while deploying twapOracleFacet :", twapOracleFacetError);
    return null;
  }
  const cut = [] as cutType[];
  const diamondCutFacetCut = {
    facetAddress: diamondCutFacetResult.deployedTo,
    action: FacetCutAction.Add,
    functionSelectors: await getSelectorsFromFacet("DiamondCutFacet"),
  };
  const diamondLoupeFacetCut = {
    facetAddress: diamondLoupeFacetResult.deployedTo,
    action: FacetCutAction.Add,
    functionSelectors: await getSelectorsFromFacet("DiamondLoupeFacet"),
  };
  const ownershipFacetCut = {
    facetAddress: ownershipFacetResult.deployedTo,
    action: FacetCutAction.Add,
    functionSelectors: await getSelectorsFromFacet("OwnershipFacet"),
  };
  const managerFacetCut = {
    facetAddress: managerFacetResult.deployedTo,
    action: FacetCutAction.Add,
    functionSelectors: await getSelectorsFromFacet("ManagerFacet"),
  };

  const twapOracleFacetCut = {
    facetAddress: twapOracleFacetResult.deployedTo,
    action: FacetCutAction.Add,
    functionSelectors: await getSelectorsFromFacet("TWAPOracleDollar3poolFacet"),
  };

  // add DiamondCutFacetCut DiamondLoupeFacet, OwnershipFacet and ManagerFacet
  cut.push(diamondCutFacetCut, diamondLoupeFacetCut, ownershipFacetCut, managerFacetCut, twapOracleFacetCut);

  console.log("Diamond Cut:", cut);

  // call to init function
  const diamondInitInstance = await getContractInstance("DiamondInit");

  const initArgs: any = [
    {
      admin: wallet.address,
      tos: [ethers.constants.AddressZero],
      amounts: [0],
      stakingShareIDs: [0],
      governancePerBlock: ethers.utils.parseEther("10"),
      creditNFTLengthBlocks: 100,
    },
  ];
  const functionCall = diamondInitInstance.interface.encodeFunctionData("init", initArgs);
  // call diamondCut function
  const DiamondArgs = {
    owner: wallet.address,
    init: diamondInitResult?.deployedTo,
    initCalldata: functionCall,
  };
  const { stderr: diamondError, result: diamondResult } = await create({
    ...env,
    name: "Diamond",
    network: args.network,
    contractInstance: diamondContract,
    constructorArguments: [DiamondArgs, cut],
  });
  if (!diamondError && diamondResult != undefined) {
    console.log("Completed diamond deployment!!!");
  } else {
    console.log("diamondError", diamondError);
  }
}

deployDiamond()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

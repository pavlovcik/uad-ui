import { spawnSync } from "child_process";
import { loadEnv } from "../../shared";
import fs from "fs";
import path from "path";
import axios from "axios";

const envPath = path.join(__dirname, "../../../.env");
if (!fs.existsSync(envPath)) {
  throw new Error("Env file not found");
}
const env = loadEnv(envPath);

const curveWhale = env.curveWhale as string;
const adminAddress = env.adminAddress as string;
const _3CRV = env._3CRV as string;

const impersonateAccount = async () => {
  console.log("----------------------------------------------------------------");
  console.log("Impersonating 'CURVE_WHALE' account");
  console.log("----------------------------------------------------------------");
  spawnSync("cast", ["rpc", "anvil_impersonateAccount", curveWhale, "-r", "http://localhost:8545"], {
    stdio: "inherit",
  });
};

const sendTokens = async () => {
  console.log("----------------------------------------------------------------");
  console.log("Sending 10,000 3CRV LP tokens to 'ADMIN_ADDRESS'");
  console.log("----------------------------------------------------------------");
  spawnSync(
    "cast",
    [
      "send",
      _3CRV,
      "transfer(address, uint256)",
      adminAddress,
      "10000000000000000000000", //10,000e18
      "--from",
      curveWhale,
    ],
    {
      stdio: "inherit",
    }
  );
};

const stopImpersonatingAccount = async () => {
  console.log("----------------------------------------------------------------");
  console.log("Ending account impersonation");
  console.log("----------------------------------------------------------------");
  spawnSync("cast", ["rpc", "anvil_stopImpersonatingAccount", curveWhale, "-r", "http://localhost:8545"], {
    stdio: "inherit",
  });
};

const forgeScript = async () => {
  console.log("----------------------------------------------------------------");
  console.log("Running Solidity script");
  console.log("----------------------------------------------------------------");
  spawnSync(
    "forge",
    ["script", "scripts/deploy/dollar/solidityScripting/08_DevelopmentDeploy.s.sol:DevelopmentDeploy", "--fork-url", "http://localhost:8545", "--broadcast"],
    {
      stdio: "inherit",
    }
  );
};

const main = async () => {
  await impersonateAccount();
  await sendTokens();
  await stopImpersonatingAccount();
  await forgeScript();
};

main();

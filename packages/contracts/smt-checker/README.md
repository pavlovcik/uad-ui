# SMT-Checker Support for Smart Contract Testing

This repository provides SMT-Checker support for testing smart contracts. Follow these steps to get started:

## Step 1: Download and Install Z3

Before proceeding, ensure that you have `g++` and `python3` installed on your system. To download and install Z3, enter the following commands in your terminal:

```
sudo apt-get install g++
sudo apt-get install z3
sudo apt-get install libz3-dev
sudo wget https://github.com/Z3Prover/z3/archive/refs/tags/z3-4.11.0.tar.gz
sudo tar -zxvf z3-4.11.0.tar.gz
cd z3-z3-4.11.0
python3 scripts/mk_make.py
cd build
echo $PWDs
sudo make -j$(nproc)
sudo make install
sudo cp libz3.so libz3.so.4.11
sudo mv libz3.so.4.11 x86_64-linux-gnu
```

Once installed, you can verify that Z3 is correctly installed by checking the version number.

## Step 2: Make Sure Your System Has Z3 Installed >= "Version"

Ensure that your system has Z3 installed with a version number greater than or equal to the required version.

## Step 3: Use Forge to Test Contracts Using SMT

Ensure that your repository is up-to-date with the latest npm/yarn packages, then run the following command:

```
npx tsx smt-checker/smt.ts
```

This will prompt you to select a contract. Once selected, check that the contract was updated in Foundry, then build it using Forge. Wait for the SMT-Checker results to appear after compiling.

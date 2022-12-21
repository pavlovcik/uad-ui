// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../helpers/LiveTestHelper.sol";

contract DepositState is LiveTestHelper {
    uint256 fourthBal;
    uint256 minBal;
    uint256 maxBal;
    uint256[] creationBlock;

    function setUp() public virtual override {
        super.setUp();
        fourthBal = metapool.balanceOf(fourthAccount);
        minBal = metapool.balanceOf(stakingMinAccount);
        maxBal = metapool.balanceOf(stakingMaxAccount);
        address[4] memory depositingAccounts = [
            stakingMinAccount,
            fourthAccount,
            stakingMaxAccount,
            stakingMaxAccount
        ];
        uint256[4] memory depositAmounts =
            [minBal, fourthBal, maxBal / 2, maxBal / 2];
        uint256[4] memory lockupWeeks =
            [uint256(1), uint256(52), uint256(208), uint256(208)];

        for (uint256 i; i < depositingAccounts.length; ++i) {
            vm.startPrank(depositingAccounts[i]);
            metapool.approve(address(staking), 2 ** 256 - 1);
            creationBlock.push(block.number);
            staking.deposit(depositAmounts[i], lockupWeeks[i]);
            vm.stopPrank();
        }
    }
}

contract DepositStateTest is DepositState {
    uint256[] ids;
    uint256[] amounts;

    function testUpdateStake(uint128 amount, uint128 debt, uint256 end) public {
        vm.prank(admin);
        stakingShare.updateStake(1, uint256(amount), uint256(debt), end);
        StakingShare.Stake memory stake = stakingShare.getStake(1);
        assertEq(stake.lpAmount, amount);
        assertEq(stake.lpRewardDebt, debt);
        assertEq(stake.endBlock, end);
    }

    function testMint(uint128 deposited, uint128 debt, uint256 end) public {
        vm.prank(admin);
        uint256 id = stakingShare.mint(
            secondAccount, uint256(deposited), uint256(debt), end
        );
        StakingShare.Stake memory stake = stakingShare.getStake(id);
        assertEq(stake.minter, secondAccount);
        assertEq(stake.lpAmount, deposited);
        assertEq(stake.lpRewardDebt, debt);
        assertEq(stake.endBlock, end);
    }

    function testTransferFrom() public {
        vm.prank(stakingMinAccount);
        stakingShare.setApprovalForAll(admin, true);

        bytes memory data;
        vm.prank(admin);
        stakingShare.safeTransferFrom(
            stakingMinAccount, secondAccount, 1, 1, data
        );
        ids.push(1);

        assertEq(stakingShare.holderTokens(secondAccount), ids);
    }

    function testBatchTransfer() public {
        ids.push(3);
        ids.push(4);
        amounts.push(1);
        amounts.push(1);

        vm.prank(stakingMaxAccount);
        stakingShare.setApprovalForAll(admin, true);

        bytes memory data;

        vm.prank(admin);
        stakingShare.safeBatchTransferFrom(
            stakingMaxAccount, secondAccount, ids, amounts, data
        );
        assertEq(stakingShare.holderTokens(secondAccount), ids);
    }

    function testTotalSupply() public {
        assertEq(stakingShare.totalSupply(), 4);
    }

    // // TODO: needs to figured out why it sometimes fails
    // function test_TotalLP() public {
    //     uint256 totalLp = fourthBal + minBal + maxBal - 1;
    //     assertEq(bondingShareV2.totalLP(), totalLp);
    // }

    function testGetStake() public {
        StakingShare.Stake memory stake = StakingShare.Stake(
            fourthAccount,
            fourthBal,
            creationBlock[1],
            ubiquityFormulas.durationMultiply(
                fourthBal, 52, staking.stakingDiscountMultiplier()
            ),
            staking.blockCountInAWeek() * 52,
            fourthBal
        );

        StakingShare.Stake memory stake_ = stakingShare.getStake(2);
        bytes32 stake1 = bytes32(abi.encode(stake));
        bytes32 stake2 = bytes32(abi.encode(stake_));
        assertEq(stake1, stake2);
    }

    function testHolderTokens() public {
        ids.push(1);
        uint256[] memory ids_ = stakingShare.holderTokens(stakingMinAccount);
        assertEq(ids, ids_);
    }

    function testSetUri() public {
        string memory stringTest = "{'name':'Bonding Share','description':," 
        "'Ubiquity Bonding Share V2',"
        "'image': 'https://bafybeifibz4fhk4yag5reupmgh5cdbm2oladke4zfd7ldyw7avgipocpmy.ipfs.infura-ipfs.io/'}";
        vm.prank(admin);
        stakingShare.setUri(stringTest);
        assertEq(stakingShare.uri(1), stringTest, 'the uri is not set correctly by the method');
    }

    function testCannotSetUriFromNonAllowedAddress() public{
        string memory stringTest ="{'a parsed json':'value'}";
        vm.expectRevert();
        vm.prank(fifthAccount);
        stakingShare.setUri(stringTest);
    }
}
   

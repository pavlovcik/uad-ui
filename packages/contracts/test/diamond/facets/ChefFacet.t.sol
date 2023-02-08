// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IMetaPool} from "../../../src/dollar/interfaces/IMetaPool.sol";
import {MockMetaPool} from "../../../src/dollar/mocks/MockMetaPool.sol";
import "../DiamondTestSetup.sol";
import {StakingShareForDiamond} from "../../../src/diamond/token/StakingShareForDiamond.sol";
import {BondingShareForDiamond} from "../../../src/diamond/mocks/MockShareV1.sol";
import {IERC20Ubiquity} from "../../../src/dollar/interfaces/IERC20Ubiquity.sol";
import {ICurveFactory} from "../../../src/dollar/interfaces/ICurveFactory.sol";

import {DollarMintCalculator} from "../../../src/dollar/core/DollarMintCalculator.sol";
import {MockCreditNFT} from "../../../src/dollar/mocks/MockCreditNFT.sol";
import {UbiquityCreditTokenForDiamond} from "../../../src/diamond/token/UbiquityCreditTokenForDiamond.sol";
import {DollarMintExcess} from "../../../src/dollar/core/DollarMintExcess.sol";
import "../../../src/diamond/libraries/Constants.sol";
import {MockERC20} from "../../../src/dollar/mocks/MockERC20.sol";
import {MockCurveFactory} from "../../../src/diamond/mocks/MockCurveFactory.sol";

contract ZeroStateChef is DiamondSetup {
    MockERC20 crvToken;
    address curve3CrvToken;
    uint256 creditNFTLengthBlocks = 100;
    address treasury = address(0x3);
    address secondAccount = address(0x4);
    address thirdAccount = address(0x5);
    address fourthAccount = address(0x6);
    address fifthAccount = address(0x7);
    address stakingZeroAccount = address(0x8);
    address stakingMinAccount = address(0x9);
    address stakingMaxAccount = address(0x10);

    string uri =
        "https://bafybeifibz4fhk4yag5reupmgh5cdbm2oladke4zfd7ldyw7avgipocpmy.ipfs.infura-ipfs.io/";
    StakingShareForDiamond stakingShare;
    BondingShareForDiamond stakingShareV1;
    IERC20Ubiquity governanceToken;
    event Deposit(
        address indexed user,
        uint256 amount,
        uint256 indexed stakingShareId
    );

    event Withdraw(
        address indexed user,
        uint256 amount,
        uint256 indexed stakingShareId
    );
    IMetaPool metapool;
    address metaPoolAddress;
    event GovernancePerBlockModified(uint256 indexed governancePerBlock);

    event MinPriceDiffToUpdateMultiplierModified(
        uint256 indexed minPriceDiffToUpdateMultiplier
    );

    function setUp() public virtual override {
        super.setUp();
        crvToken = new MockERC20("3 CRV", "3CRV", 18);
        curve3CrvToken = address(crvToken);
        metaPoolAddress = address(
            new MockMetaPool(address(IDollarFacet), curve3CrvToken)
        );

        vm.startPrank(owner);

        ITWAPOracleDollar3pool.setPool(metaPoolAddress, curve3CrvToken);

        address[7] memory mintings = [
            admin,
            address(diamond),
            owner,
            fourthAccount,
            stakingZeroAccount,
            stakingMinAccount,
            stakingMaxAccount
        ];

        for (uint256 i = 0; i < mintings.length; ++i) {
            deal(address(diamond), mintings[i], 10000e18);
        }

        address[5] memory crvDeal = [
            address(diamond),
            owner,
            stakingMaxAccount,
            stakingMinAccount,
            fourthAccount
        ];
        vm.stopPrank();
        for (uint256 i; i < crvDeal.length; ++i) {
            crvToken.mint(crvDeal[i], 10000e18);
        }

        vm.startPrank(admin);
        stakingShareV1 = new BondingShareForDiamond(address(diamond));
        IManager.setStakingShareAddress(address(stakingShareV1));
        stakingShareV1.setApprovalForAll(address(diamond), true);
        IAccessCtrl.grantRole(
            GOVERNANCE_TOKEN_MINTER_ROLE,
            address(stakingShareV1)
        );
        governanceToken = IERC20Ubiquity(IManager.governanceTokenAddress());
        //  vm.stopPrank();
        ICurveFactory curvePoolFactory = ICurveFactory(new MockCurveFactory());
        address curve3CrvBasePool = address(
            new MockMetaPool(address(diamond), address(crvToken))
        );
        //vm.prank(admin);
        IManager.deployStableSwapPool(
            address(curvePoolFactory),
            curve3CrvBasePool,
            curve3CrvToken,
            10,
            50000000
        );
        //
        metapool = IMetaPool(IManager.stableSwapMetaPoolAddress());
        metapool.transfer(address(IStakingFacet), 100e18);
        metapool.transfer(secondAccount, 1000e18);
        vm.stopPrank();
        vm.prank(owner);
        ITWAPOracleDollar3pool.setPool(address(metapool), curve3CrvToken);

        vm.startPrank(admin);
        DollarMintCalculator dollarMintCalc = new DollarMintCalculator(
            UbiquityDollarManager(address(diamond))
        );
        IManager.setDollarMintCalculatorAddress(address(dollarMintCalc));

        IAccessCtrl.grantRole(GOVERNANCE_TOKEN_MANAGER_ROLE, admin);
        IAccessCtrl.grantRole(CREDIT_NFT_MANAGER_ROLE, address(diamond));
        IAccessCtrl.grantRole(GOVERNANCE_TOKEN_MINTER_ROLE, address(diamond));

        IAccessCtrl.grantRole(GOVERNANCE_TOKEN_BURNER_ROLE, address(diamond));
        UbiquityCreditTokenForDiamond creditToken = new UbiquityCreditTokenForDiamond(
                address(IManager)
            );
        IManager.setCreditTokenAddress(address(creditToken));
        DollarMintExcess dollarMintExcess = new DollarMintExcess(
            UbiquityDollarManager(address(this))
        );
        IManager.setExcessDollarsDistributor(
            address(diamond),
            address(dollarMintExcess)
        );
        vm.stopPrank();

        vm.startPrank(stakingMinAccount);
        IDollarFacet.approve(address(metapool), 10000e18);
        crvToken.approve(address(metapool), 10000e18);
        vm.stopPrank();

        vm.startPrank(stakingMaxAccount);
        IDollarFacet.approve(address(metapool), 10000e18);
        crvToken.approve(address(metapool), 10000e18);
        vm.stopPrank();
        vm.startPrank(fourthAccount);
        IDollarFacet.approve(address(metapool), 10000e18);
        crvToken.approve(address(metapool), 10000e18);
        vm.stopPrank();

        uint256[2] memory amounts_ = [uint256(100e18), uint256(100e18)];

        uint256 dyuAD2LP = metapool.calc_token_amount(amounts_, true);

        vm.prank(stakingMinAccount);
        metapool.add_liquidity(
            amounts_,
            (dyuAD2LP * 99) / 100,
            stakingMinAccount
        );

        vm.prank(stakingMaxAccount);
        metapool.add_liquidity(
            amounts_,
            (dyuAD2LP * 99) / 100,
            stakingMaxAccount
        );

        vm.prank(fourthAccount);
        metapool.add_liquidity(amounts_, (dyuAD2LP * 99) / 100, fourthAccount);

        ///uint256 bondingMinBal = metapool.balanceOf(stakingMinAccount);
        ///uint256 bondingMaxBal = metapool.balanceOf(stakingMaxAccount);

        vm.startPrank(admin);
        stakingShare = new StakingShareForDiamond(address(diamond), uri);
        IManager.setStakingShareAddress(address(stakingShare));
        IAccessCtrl.grantRole(GOVERNANCE_TOKEN_MINTER_ROLE, address(diamond));
        IStakingFacet.setBlockCountInAWeek(420);

        vm.stopPrank();

        vm.prank(secondAccount);
        stakingShareV1.setApprovalForAll(address(diamond), true);

        vm.prank(thirdAccount);
        stakingShareV1.setApprovalForAll(address(diamond), true);
    }
}

contract ZeroStateChefTest is ZeroStateChef {
    function testSetGovernancePerBlock(uint256 governancePerBlock) public {
        vm.expectEmit(true, false, false, true, address(IChefFacet));
        emit GovernancePerBlockModified(governancePerBlock);
        vm.prank(admin);
        IChefFacet.setGovernancePerBlock(governancePerBlock);
        assertEq(IChefFacet.governancePerBlock(), governancePerBlock);
    }

    function testSetGovernanceDiv(uint256 div) public {
        vm.prank(admin);
        IChefFacet.setGovernanceShareForTreasury(div);
        assertEq(IChefFacet.governanceDivider(), div);
    }

    function testSetMinPriceDiff(uint256 minPriceDiff) public {
        vm.expectEmit(true, false, false, true, address(IChefFacet));
        emit MinPriceDiffToUpdateMultiplierModified(minPriceDiff);
        vm.prank(admin);
        IChefFacet.setMinPriceDiffToUpdateMultiplier(minPriceDiff);
        assertEq(IChefFacet.minPriceDiffToUpdateMultiplier(), minPriceDiff);
    }

    function testDepositFromZeroState(uint256 lpAmount) public {
        uint256 LPBalance = metapool.balanceOf(fourthAccount);
        lpAmount = bound(lpAmount, 1, LPBalance);
        // lock for 10 weeks
        uint256 shares = IStakingFormulasFacet.durationMultiply(
            lpAmount,
            10,
            IStakingFacet.stakingDiscountMultiplier()
        );
        uint256 id = stakingShare.totalSupply() + 1;

        uint256 allowance = metapool.allowance(
            fourthAccount,
            address(IChefFacet)
        );

        uint256 fourthBalance = metapool.balanceOf(fourthAccount);

        vm.prank(fourthAccount);
        metapool.approve(address(diamond), fourthBalance);
        allowance = metapool.allowance(fourthAccount, address(IChefFacet));
        vm.expectEmit(true, true, true, true, address(IChefFacet));

        emit Deposit(fourthAccount, shares, id);
        vm.prank(fourthAccount);
        IStakingFacet.deposit(lpAmount, 10);

        (, uint256 accGovernance) = IChefFacet.pool();
        uint256[2] memory info1 = [shares, (shares * accGovernance) / 1e12];
        uint256[2] memory info2 = IChefFacet.getStakingShareInfo(id);
        assertEq(info1[0], info2[0]);
        assertEq(info1[1], info2[1]);
    }
}

contract DepositStateChef is ZeroStateChef {
    uint256 fourthBal;
    uint256 fourthID;
    uint256 shares;

    function setUp() public virtual override {
        super.setUp();
        assertEq(IChefFacet.totalShares(), 0);
        fourthBal = metapool.balanceOf(fourthAccount);
        shares = IStakingFormulasFacet.durationMultiply(
            fourthBal,
            1,
            IStakingFacet.stakingDiscountMultiplier()
        );
        vm.startPrank(admin);
        fourthID = stakingShare.totalSupply() + 1;
        vm.stopPrank();
        vm.startPrank(fourthAccount);
        metapool.approve(address(diamond), fourthBal);
        IStakingFacet.deposit(fourthBal, 1);

        assertEq(stakingShare.totalSupply(), fourthID);
        assertEq(stakingShare.balanceOf(fourthAccount, fourthID), 1);

        vm.stopPrank();
    }
}

contract DepositStateChefTest is DepositStateChef {
    function testTotalShares() public {
        assertEq(IChefFacet.totalShares(), shares);
    }

    function testRemoveLiquidity(uint256 amount, uint256 blocks) public {
        assertEq(IChefFacet.totalShares(), shares);

        // advance the block number to  staking time so the withdraw is possible
        uint256 currentBlock = block.number;
        blocks = bound(blocks, 45361, 2 ** 128 - 1);
        assertEq(IChefFacet.totalShares(), shares);

        uint256 preBal = governanceToken.balanceOf(fourthAccount);
        (uint256 lastRewardBlock, ) = IChefFacet.pool();
        // currentBlock = block.number;
        vm.roll(currentBlock + blocks);
        uint256 multiplier = (block.number - lastRewardBlock) * 1e18;
        uint256 governancePerBlock = 10e18;
        uint256 reward = ((multiplier * governancePerBlock) / 1e18);
        uint256 governancePerShare = (reward * 1e12) / shares;
        assertEq(IChefFacet.totalShares(), shares);
        // we have to bound the amount of LP token to withdraw to max what account four has deposited
        amount = bound(amount, 1, fourthBal);
        assertEq(IChefFacet.totalShares(), shares);

        // calculate the reward in governance token for the user based on all his shares
        uint256 userReward = (shares * governancePerShare) / 1e12;
        vm.prank(fourthAccount);
        IStakingFacet.removeLiquidity(amount, fourthID);
        assertEq(preBal + userReward, governanceToken.balanceOf(fourthAccount));
    }

    function testGetRewards(uint256 blocks) public {
        blocks = bound(blocks, 1, 2 ** 128 - 1);

        (uint256 lastRewardBlock, ) = IChefFacet.pool();
        uint256 currentBlock = block.number;
        vm.roll(currentBlock + blocks);
        uint256 multiplier = (block.number - lastRewardBlock) * 1e18;
        uint256 reward = ((multiplier * 10e18) / 1e18);
        uint256 governancePerShare = (reward * 1e12) / shares;
        uint256 userReward = (shares * governancePerShare) / 1e12;
        vm.prank(fourthAccount);
        uint256 rewardSent = IChefFacet.getRewards(1);
        assertEq(userReward, rewardSent);
    }

    function testCannotGetRewardsOtherAccount() public {
        vm.expectRevert("MS: caller is not owner");
        vm.prank(stakingMinAccount);
        IChefFacet.getRewards(1);
    }

    function testPendingGovernance(uint256 blocks) public {
        blocks = bound(blocks, 1, 2 ** 128 - 1);

        (uint256 lastRewardBlock, ) = IChefFacet.pool();
        uint256 currentBlock = block.number;
        vm.roll(currentBlock + blocks);
        uint256 multiplier = (block.number - lastRewardBlock) * 1e18;
        uint256 reward = ((multiplier * 10e18) / 1e18);
        uint256 governancePerShare = (reward * 1e12) / shares;
        uint256 userPending = (shares * governancePerShare) / 1e12;

        uint256 pendingGovernance = IChefFacet.pendingGovernance(1);
        assertEq(userPending, pendingGovernance);
    }

    function testGetStakingShareInfo() public {
        uint256[2] memory info1 = [shares, 0];
        uint256[2] memory info2 = IChefFacet.getStakingShareInfo(1);
        assertEq(info1[0], info2[0]);
        assertEq(info1[1], info2[1]);
    }
}

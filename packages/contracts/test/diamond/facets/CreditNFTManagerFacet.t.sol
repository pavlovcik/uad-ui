// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../DiamondTestSetup.sol";
import {CreditNftManagerFacet} from "../../../src/diamond/facets/CreditNFTManagerFacet.sol";
import {CreditRedemptionCalculatorFacet} from "../../../src/diamond/facets/CreditRedemptionCalculatorFacet.sol";
import {DollarMintCalculator} from "../../../src/dollar/core/DollarMintCalculator.sol";
import {UbiquityCreditToken} from "../../../src/dollar/core/UbiquityCreditToken.sol";
import {DollarMintExcess} from "../../../src/dollar/core/DollarMintExcess.sol";
import {CreditNft} from "../../../src/dollar/core/CreditNft.sol";
import {TWAPOracleDollar3poolFacet} from "../../../src/diamond/facets/TWAPOracleDollar3poolFacet.sol";
import "../../../src/diamond/libraries/Constants.sol";
import {IERC20Ubiquity} from "../../../src/dollar/interfaces/IERC20Ubiquity.sol";
import {MockDollarToken} from "../../../src/dollar/mocks/MockDollarToken.sol";
import {MockCreditNft} from "../../../src/dollar/mocks/MockCreditNft.sol";
import {MockCreditToken} from "../../../src/dollar/mocks/MockCreditToken.sol";

contract CreditNFTManagerFacetTest is DiamondSetup {
    MockCreditNft _creditNFT;
    address dollarManagerAddress;
    address dollarTokenAddress;
    address creditCalculatorAddress;
    address creditNFTManagerAddress;
    uint256 creditNFTLengthBlocks = 100;
    address twapOracleAddress;
    address creditNFTAddress;
    address governanceTokenAddress;
    address creditTokenAddress;
    address dollarMintCalculatorAddress;

    function setUp() public virtual override {
        super.setUp();
        vm.prank(admin);
        IDollarFacet.mint(admin, 10000e18);
        uint256 admSupply = IDollarFacet.balanceOf(admin);
        assertEq(admSupply, 10000e18);

        _creditNFT = new MockCreditNft(100);
        vm.prank(admin);
        IManager.setCreditNftAddress(address(_creditNFT));

        twapOracleAddress = address(diamond);
        dollarTokenAddress = address(diamond);
        creditNFTManagerAddress = address(diamond);
        creditCalculatorAddress = IManager.creditCalculatorAddress();
        creditNFTAddress = address(_creditNFT);
        governanceTokenAddress = IManager.governanceTokenAddress();
        // deploy credit token
        MockCreditToken _creditToken = new MockCreditToken(0);
        creditTokenAddress = address(_creditToken);
        vm.prank(admin);
        IManager.setCreditTokenAddress(creditTokenAddress);
        // deploy dollarMintCalculator
        dollarMintCalculatorAddress = address(
            new DollarMintCalculator(UbiquityDollarManager(address(diamond)))
        );
        vm.prank(admin);
        IManager.setDollarMintCalculatorAddress(dollarMintCalculatorAddress);

        // set this contract as minter
        vm.prank(admin);
        IAccessCtrl.grantRole(GOVERNANCE_TOKEN_MINTER_ROLE, address(this));
    }

    function mockTwapFuncs(uint256 _twapPrice) public {
        uint256 TWAP_ORACLE_STORAGE_POSITION = uint256(
            keccak256("diamond.standard.twap.oracle.storage")
        );
        uint256 dollarPricePosition = TWAP_ORACLE_STORAGE_POSITION + 2;
        vm.store(
            address(diamond),
            bytes32(dollarPricePosition),
            bytes32(_twapPrice)
        );
    }

    function mockDollarMintCalcFuncs(uint256 _dollarsToMint) public {
        vm.mockCall(
            IManager.dollarMintCalculatorAddress(),
            abi.encodeWithSelector(
                DollarMintCalculator.getDollarsToMint.selector
            ),
            abi.encode(_dollarsToMint)
        );
    }

    function helperDeployExcessDollarCalculator(
        address _excessDollarsDistributor
    ) public {
        vm.prank(admin);
        IManager.setExcessDollarsDistributor(
            creditNFTManagerAddress,
            _excessDollarsDistributor
        );
    }

    function test_setExpiredCreditNFTConversionRate() public {
        vm.expectRevert("Caller is not a Credit NFT manager");
        ICreditNFTMgrFacet.setExpiredCreditNFTConversionRate(100);

        vm.prank(admin);
        ICreditNFTMgrFacet.setExpiredCreditNFTConversionRate(100);
        assertEq(ICreditNFTMgrFacet.expiredCreditNFTConversionRate(), 100);
    }

    function test_setCreditNFTLength() public {
        vm.expectRevert("Caller is not a Credit NFT manager");
        ICreditNFTMgrFacet.setCreditNFTLength(100);

        vm.prank(admin);
        ICreditNFTMgrFacet.setCreditNFTLength(100);
        assertEq(ICreditNFTMgrFacet.creditNFTLengthBlocks(), 100);
    }

    function test_exchangeDollarsForCreditNFT() public {
        mockTwapFuncs(2e18);
        vm.expectRevert("Price must be below 1 to mint Credit NFT");
        ICreditNFTMgrFacet.exchangeDollarsForCreditNFT(100);

        mockTwapFuncs(5e17);
        address mockSender = address(0x123);
        vm.roll(10000);
        // Mint some dollarTokens to mockSender and then approve all
        MockDollarToken(dollarTokenAddress).mint(mockSender, 10000e18);
        vm.startPrank(mockSender);

        MockDollarToken(dollarTokenAddress).approve(
            creditNFTManagerAddress,
            10000e18
        );

        uint256 expiryBlockNumber = ICreditNFTMgrFacet
            .exchangeDollarsForCreditNFT(100);
        assertEq(expiryBlockNumber, 10000 + creditNFTLengthBlocks);
    }

    function test_exchangeDollarsForCreditRevertsIfPriceHigherThan1Ether()
        public
    {
        mockTwapFuncs(2e18);
        vm.expectRevert("Price must be below 1 to mint Credit");
        ICreditNFTMgrFacet.exchangeDollarsForCredit(100);
    }

    function test_exchangeDollarsForCreditWorks() public {
        mockTwapFuncs(5e17);
        address mockSender = address(0x123);
        vm.roll(10000); // Mint some dollarTokens to mockSender and then approve all
        MockDollarToken(dollarTokenAddress).mint(mockSender, 10000e18);
        vm.startPrank(mockSender);

        MockDollarToken(dollarTokenAddress).approve(
            creditNFTManagerAddress,
            10000e18
        );

        uint256 creditAmount = ICreditNFTMgrFacet.exchangeDollarsForCredit(100);
        assertEq(creditAmount, 100);
    }

    function test_burnExpiredCreditNFTForGovernanceRevertsIfNotExpired()
        public
    {
        vm.roll(1000);
        vm.expectRevert("Credit NFT has not expired");
        ICreditNFTMgrFacet.burnExpiredCreditNFTForGovernance(2000, 1e18);
    }

    function test_burnExpiredCreditNFTForGovernanceRevertsIfNotEnoughBalance()
        public
    {
        address mockMessageSender = address(0x123);
        vm.prank(admin);
        MockCreditNft(creditNFTAddress).mintCreditNft(
            mockMessageSender,
            100,
            500
        );
        vm.roll(1000);
        vm.prank(mockMessageSender);
        vm.expectRevert("User not enough Credit NFT");
        ICreditNFTMgrFacet.burnExpiredCreditNFTForGovernance(500, 1e18);
    }

    function test_burnExpiredCreditNFTForGovernanceWorks() public {
        address mockMessageSender = address(0x123);
        uint256 expiryBlockNumber = 500;
        vm.startPrank(admin);
        MockCreditNft(creditNFTAddress).mintCreditNft(
            mockMessageSender,
            2e18,
            expiryBlockNumber
        );
        IAccessCtrl.grantRole(
            keccak256("GOVERNANCE_TOKEN_MINTER_ROLE"),
            creditNFTManagerAddress
        );
        vm.stopPrank();
        vm.roll(1000);
        vm.prank(mockMessageSender);
        ICreditNFTMgrFacet.burnExpiredCreditNFTForGovernance(
            expiryBlockNumber,
            1e18
        );
        uint256 governanceBalance = IERC20Ubiquity(governanceTokenAddress)
            .balanceOf(mockMessageSender);
        assertEq(governanceBalance, 5e17);
    }

    function test_burnCreditNFTForCreditRevertsIfExpired() public {
        vm.warp(1000);
        vm.expectRevert("Credit NFT has expired");
        ICreditNFTMgrFacet.burnCreditNFTForCredit(500, 1e18);
    }

    function test_burnCreditNFTForCreditRevertsIfNotEnoughBalance() public {
        vm.warp(1000);
        vm.expectRevert("User not enough Credit NFT");
        ICreditNFTMgrFacet.burnCreditNFTForCredit(1001, 1e18);
    }

    function test_burnCreditNFTForCreditWorks() public {
        address mockMessageSender = address(0x123);
        uint256 expiryBlockNumber = 500;
        vm.startPrank(admin);
        MockCreditNft(creditNFTAddress).mintCreditNft(
            mockMessageSender,
            2e18,
            expiryBlockNumber
        );
        IAccessCtrl.grantRole(
            keccak256("GOVERNANCE_TOKEN_MINTER_ROLE"),
            creditNFTManagerAddress
        );
        vm.stopPrank();
        vm.prank(mockMessageSender);
        vm.warp(expiryBlockNumber - 1);
        ICreditNFTMgrFacet.burnCreditNFTForCredit(expiryBlockNumber, 1e18);
        uint256 redeemBalance = UbiquityCreditToken(creditTokenAddress)
            .balanceOf(mockMessageSender);
        assertEq(redeemBalance, 1e18);
    }

    function test_burnCreditTokensForDollarsRevertsIfPriceLowerThan1Ether()
        public
    {
        mockTwapFuncs(5e17);
        vm.expectRevert("Price must be above 1");
        ICreditNFTMgrFacet.burnCreditTokensForDollars(100);
    }

    function test_burnCreditTokensForDollarsIfNotEnoughBalance() public {
        mockTwapFuncs(2e18);
        vm.expectRevert("User doesn't have enough Credit pool tokens.");
        ICreditNFTMgrFacet.burnCreditTokensForDollars(100);
    }

    function test_burnCreditTokensForDollarsWorks() public {
        mockTwapFuncs(2e18);
        mockDollarMintCalcFuncs(1e18);
        address account1 = address(0x123);
        MockCreditToken(creditTokenAddress).mint(account1, 100e18);
        vm.prank(account1);
        uint256 unredeemed = ICreditNFTMgrFacet.burnCreditTokensForDollars(
            10e18
        );
        assertEq(unredeemed, 10e18 - 1e18);
    }

    function test_redeemCreditNFTRevertsIfPriceLowerThan1Ether() public {
        mockTwapFuncs(5e17);
        vm.expectRevert("Price must be above 1 to redeem Credit NFT");
        ICreditNFTMgrFacet.redeemCreditNFT(123123123, 100);
    }

    function test_redeemCreditNFTRevertsIfCreditNFTExpired() public {
        mockTwapFuncs(2e18);
        vm.roll(10000);
        vm.expectRevert("Credit NFT has expired");
        ICreditNFTMgrFacet.redeemCreditNFT(5555, 100);
    }

    function test_redeemCreditNFTRevertsIfNotEnoughBalance() public {
        mockTwapFuncs(2e18);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        MockCreditNft(creditNFTAddress).mintCreditNft(
            account1,
            100,
            expiryBlockNumber
        );
        vm.expectRevert("User not enough Credit NFT");
        vm.prank(account1);
        vm.roll(expiryBlockNumber - 1);
        ICreditNFTMgrFacet.redeemCreditNFT(expiryBlockNumber, 200);
    }

    function test_redeemCreditNFTRevertsIfNotEnoughDollars() public {
        mockTwapFuncs(2e18);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        MockCreditNft(creditNFTAddress).mintCreditNft(
            account1,
            100,
            expiryBlockNumber
        );
        MockCreditToken(creditTokenAddress).mint(
            creditNFTManagerAddress,
            20000e18
        );

        // set excess dollar distributor for creditNFTAddress
        DollarMintExcess _excessDollarsDistributor = new DollarMintExcess(
            UbiquityDollarManager(dollarManagerAddress)
        );
        helperDeployExcessDollarCalculator(address(_excessDollarsDistributor));
        vm.mockCall(
            address(_excessDollarsDistributor),
            abi.encodeWithSelector(DollarMintExcess.distributeDollars.selector),
            abi.encode()
        );

        vm.prank(account1);
        vm.expectRevert("There aren't enough Dollar to redeem currently");
        vm.roll(expiryBlockNumber - 1);
        ICreditNFTMgrFacet.redeemCreditNFT(expiryBlockNumber, 99);
    }

    function test_redeemCreditNFTRevertsIfZeroAmountOfDollars() public {
        mockTwapFuncs(2e18);
        mockDollarMintCalcFuncs(0);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        MockCreditNft(creditNFTAddress).mintCreditNft(
            account1,
            100,
            expiryBlockNumber
        );
        // MockAutoRedeem(creditTokenAddress).mint(creditNFTManagerAddress, 20000e18);

        // set excess dollar distributor for creditNFTAddress
        DollarMintExcess _excessDollarsDistributor = new DollarMintExcess(
            UbiquityDollarManager(dollarManagerAddress)
        );
        helperDeployExcessDollarCalculator(address(_excessDollarsDistributor));
        vm.mockCall(
            address(_excessDollarsDistributor),
            abi.encodeWithSelector(DollarMintExcess.distributeDollars.selector),
            abi.encode()
        );

        vm.prank(account1);
        vm.expectRevert("There aren't any Dollar to redeem currently");
        vm.roll(expiryBlockNumber - 1);
        ICreditNFTMgrFacet.redeemCreditNFT(expiryBlockNumber, 99);
    }

    function test_redeemCreditNFTWorks() public {
        mockTwapFuncs(2e18);
        mockDollarMintCalcFuncs(20000e18);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        MockCreditNft(creditNFTAddress).mintCreditNft(
            account1,
            100,
            expiryBlockNumber
        );
        MockCreditToken(creditTokenAddress).mint(
            creditNFTManagerAddress,
            10000e18
        );

        // set excess dollar distributor for debtCouponAddress
        DollarMintExcess _excessDollarsDistributor = new DollarMintExcess(
            UbiquityDollarManager(dollarManagerAddress)
        );
        helperDeployExcessDollarCalculator(address(_excessDollarsDistributor));
        vm.mockCall(
            address(_excessDollarsDistributor),
            abi.encodeWithSelector(DollarMintExcess.distributeDollars.selector),
            abi.encode()
        );
        vm.prank(account1);
        vm.roll(expiryBlockNumber - 1);
        uint256 unredeemedCreditNFT = ICreditNFTMgrFacet.redeemCreditNFT(
            expiryBlockNumber,
            99
        );
        assertEq(unredeemedCreditNFT, 0);
    }

    function test_mintClaimableDollars() public {
        mockDollarMintCalcFuncs(50);
        // set excess dollar distributor for creditNFTAddress
        DollarMintExcess _excessDollarsDistributor = new DollarMintExcess(
            UbiquityDollarManager(dollarManagerAddress)
        );
        helperDeployExcessDollarCalculator(address(_excessDollarsDistributor));
        vm.mockCall(
            address(_excessDollarsDistributor),
            abi.encodeWithSelector(DollarMintExcess.distributeDollars.selector),
            abi.encode()
        );

        uint256 beforeBalance = MockDollarToken(dollarTokenAddress).balanceOf(
            creditNFTManagerAddress
        );
        ICreditNFTMgrFacet.mintClaimableDollars();
        uint256 afterBalance = MockDollarToken(dollarTokenAddress).balanceOf(
            creditNFTManagerAddress
        );
        assertEq(afterBalance - beforeBalance, 50);
    }
}

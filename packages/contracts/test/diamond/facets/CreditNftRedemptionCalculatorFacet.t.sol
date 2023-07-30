// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../DiamondTestSetup.sol";
import {MockCreditNft} from "../../../src/dollar/mocks/MockCreditNft.sol";

contract CreditNftRedemptionCalculatorFacetTest is DiamondSetup {
    MockCreditNft _creditNFT;

    function setUp() public virtual override {
        super.setUp();
        vm.prank(admin);
        IDollar.mint(admin, 10000e18);
        uint256 admSupply = IDollar.balanceOf(admin);
        assertEq(admSupply, 10000e18);
        _creditNFT = new MockCreditNft(100);
        vm.prank(admin);
        IManager.setCreditNftAddress(address(_creditNFT));
    }

    function test_getCreditNFTAmount_revertsIfDebtTooHigh() public {
        uint256 totalSupply = IDollar.totalSupply();
        MockCreditNft(IManager.creditNftAddress()).setTotalOutstandingDebt(
            totalSupply + 1
        );

        vm.expectRevert("CreditNft to Dollar: DEBT_TOO_HIGH");
        ICreditNFTRedCalcFacet.getCreditNftAmount(0);
    }

    function test_getCreditNFTAmount() public {
        uint256 totalSupply = IDollar.totalSupply();
        MockCreditNft(IManager.creditNftAddress()).setTotalOutstandingDebt(
            totalSupply / 2
        );
        assertEq(ICreditNFTRedCalcFacet.getCreditNftAmount(10000), 40000);
    }
}

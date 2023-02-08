// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../DiamondTestSetup.sol";
import "../../helpers/LocalTestHelper.sol";

contract DollarMintCalculatorFacetTest is DiamondSetup {
    address dollarManagerAddress;
    address dollarAddress;
    address twapOracleAddress;
    address dollarMintCalculatorAddress;

    function setUp() public virtual override {
        super.setUp();
        dollarManagerAddress = address(diamond);
        twapOracleAddress = address(diamond);
        dollarMintCalculatorAddress = address(diamond);
        dollarAddress = address(diamond);
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

    function test_getDollarsToMintRevertsIfPriceLowerThan1USD() public {
        mockTwapFuncs(5e17);
        vm.expectRevert("DollarMintCalculator: not > 1");
        IDollarMintCalcFacet.getDollarsToMint();
    }

    function test_getDollarsToMintWorks() public {
        mockTwapFuncs(2e18);
        uint256 totalSupply = MockDollarToken(dollarAddress).totalSupply();
        uint256 amountToMint = IDollarMintCalcFacet.getDollarsToMint();
        assertEq(amountToMint, totalSupply);
    }
}

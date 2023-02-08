// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../../dollar/interfaces/ICreditRedemptionCalculator.sol";

import {Modifiers} from "../libraries/LibAppStorage.sol";
import {LibCreditRedemptionCalculator} from "../libraries/LibCreditRedemptionCalculator.sol";

/// @title Uses the following formula: ((1/(1-R)^2) - 1)
contract CreditRedemptionCalculatorFacet is
    Modifiers,
    ICreditRedemptionCalculator
{
    /// @notice set the constant for Credit Token calculation
    /// @param coef new constant for Credit Token calculation in ETH format
    /// @dev a coef of 1 ether means 1
    function setConstant(uint256 coef) external onlyIncentiveAdmin {
        LibCreditRedemptionCalculator.setConstant(coef);
    }

    /// @notice get the constant for Credit Token calculation
    function getConstant() external view returns (uint256) {
        return LibCreditRedemptionCalculator.getConstant();
    }

    // dollarsToBurn * (blockHeight_debt/blockHeight_burn) * _coef
    function getCreditAmount(
        uint256 dollarsToBurn,
        uint256 blockHeightDebt
    ) external view override returns (uint256) {
        return
            LibCreditRedemptionCalculator.getCreditAmount(
                dollarsToBurn,
                blockHeightDebt
            );
    }
}

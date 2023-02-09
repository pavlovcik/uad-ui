// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICreditNftRedemptionCalculator} from "../../dollar/interfaces/ICreditNftRedemptionCalculator.sol";
import {LibCreditNftRedemptionCalculator} from "../libraries/LibCreditNftRedemptionCalculator.sol";

/// @title Uses the following formula: ((1/(1-R)^2) - 1)
contract CreditNftRedemptionCalculatorFacet is ICreditNftRedemptionCalculator {
    function getCreditNftAmount(
        uint256 dollarsToBurn
    ) external view override returns (uint256) {
        return
            LibCreditNftRedemptionCalculator.getCreditNftAmount(dollarsToBurn);
    }
}

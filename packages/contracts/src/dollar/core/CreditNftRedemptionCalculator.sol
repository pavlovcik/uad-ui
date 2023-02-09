// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICreditNftRedemptionCalculator} from "../interfaces/ICreditNftRedemptionCalculator.sol";
import "./UbiquityDollarManager.sol";
import "abdk-libraries-solidity/ABDKMathQuad.sol";
import "./CreditNft.sol";

/// @title Uses the following formula: ((1/(1-R)^2) - 1)

contract CreditNftRedemptionCalculator is ICreditNftRedemptionCalculator {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    UbiquityDollarManager public immutable manager;

    /*   using ABDKMath64x64 for uint256;
    using ABDKMath64x64 for int128;*/

    /// @param _manager the address of the manager/config contract so we can fetch variables
    constructor(UbiquityDollarManager _manager) {
        manager = _manager;
    }

    function getCreditNftAmount(
        uint256 dollarsToBurn
    ) external view override returns (uint256) {
        require(
            CreditNft(manager.creditNftAddress()).getTotalOutstandingDebt() <
                IERC20(manager.dollarTokenAddress()).totalSupply(),
            "CreditNFT to Dollar: DEBT_TOO_HIGH"
        );
        bytes16 one = uint256(1).fromUInt();
        bytes16 totalDebt = CreditNft(manager.creditNftAddress())
            .getTotalOutstandingDebt()
            .fromUInt();
        bytes16 r = totalDebt.div(
            IERC20(manager.dollarTokenAddress()).totalSupply().fromUInt()
        );

        bytes16 oneMinusRAllSquared = (one.sub(r)).mul(one.sub(r));
        bytes16 res = one.mul(dollarsToBurn.fromUInt());
        return res.div(oneMinusRAllSquared).toUInt();
    }
}

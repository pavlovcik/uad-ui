// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "abdk-libraries-solidity/ABDKMathQuad.sol";

import {CreditNft} from "../../dollar/core/CreditNft.sol";
import {LibAppStorage} from "./LibAppStorage.sol";

/// @title Uses the following formula: ((1/(1-R)^2) - 1)
library LibCreditNftRedemptionCalculator {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    function getCreditNftAmount(
        uint256 dollarsToBurn
    ) internal view returns (uint256) {
        address creditNftAddress = LibAppStorage.appStorage().creditNftAddress;
        CreditNft credits = CreditNft(creditNftAddress);
        require(
            credits.getTotalOutstandingDebt() <
                IERC20(address(this)).totalSupply(),
            "CreditNFT to Dollar: DEBT_TOO_HIGH"
        );
        bytes16 one = uint256(1).fromUInt();
        bytes16 totalDebt = credits.getTotalOutstandingDebt().fromUInt();
        bytes16 r = totalDebt.div(
            IERC20(address(this)).totalSupply().fromUInt()
        );

        bytes16 oneMinusRAllSquared = (one.sub(r)).mul(one.sub(r));
        bytes16 res = one.div(oneMinusRAllSquared);
        return res.mul(dollarsToBurn.fromUInt()).toUInt();
    }
}
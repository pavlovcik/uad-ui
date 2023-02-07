// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/// @title A Credit NFT redemption mechanism for Credit NFT holders
/// @notice Allows users to redeem individual Credit Nft or batch redeem Credit Nft
/// @dev Implements IERC1155Receiver so that it can deal with redemptions
interface ICreditNftManager is IERC1155Receiver {
    function redeemCreditNft(address from, uint256 id, uint256 amount) external;

    function exchangeDollarsForCreditNft(uint256 amount) external;
}

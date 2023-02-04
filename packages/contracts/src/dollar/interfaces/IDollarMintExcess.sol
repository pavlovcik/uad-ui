// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/// @title A mechanism for distributing excess dollars to relevant places
interface IDollarMintExcess {
    function distributeDollars() external;
}

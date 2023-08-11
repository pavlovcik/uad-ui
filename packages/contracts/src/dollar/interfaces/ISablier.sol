// SPDX-License-Identifier: MIT
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol. SEE BELOW FOR SOURCE. !!
pragma solidity 0.8.19;

interface ISablier {
    event CreateCompoundingStream(
        uint256 indexed streamId,
        uint256 exchangeRate,
        uint256 senderSharePercentage,
        uint256 recipientSharePercentage
    );
    event PayInterest(
        uint256 indexed streamId,
        uint256 senderInterest,
        uint256 recipientInterest,
        uint256 sablierInterest
    );
    event TakeEarnings(address indexed tokenAddress, uint256 indexed amount);
    event UpdateFee(uint256 indexed fee);
    event Paused(address account);
    event Unpaused(address account);
    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event CreateStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    );
    event WithdrawFromStream(
        uint256 indexed streamId,
        address indexed recipient,
        uint256 amount
    );
    event CancelStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 senderBalance,
        uint256 recipientBalance
    );

    function unpause() external;

    function cancelStream(uint256 streamId) external returns (bool);

    function withdrawFromStream(
        uint256 streamId,
        uint256 amount
    ) external returns (bool);

    function initialize() external;

    function createCompoundingStream(
        address recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime,
        uint256 senderSharePercentage,
        uint256 recipientSharePercentage
    ) external returns (uint256);

    function addPauser(address account) external;

    function pause() external;

    function interestOf(
        uint256 streamId,
        uint256 amount
    )
        external
        returns (
            uint256 senderInterest,
            uint256 recipientInterest,
            uint256 sablierInterest
        );

    function updateFee(uint256 feePercentage) external;

    function takeEarnings(address tokenAddress, uint256 amount) external;

    function initialize(address sender) external;

    function createStream(
        address recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    ) external returns (uint256);

    function transferOwnership(address newOwner) external;

    function getEarnings(address tokenAddress) external view returns (uint256);

    function nextStreamId() external view returns (uint256);

    function getCompoundingStream(
        uint256 streamId
    )
        external
        view
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            address tokenAddress,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond,
            uint256 exchangeRateInitial,
            uint256 senderSharePercentage,
            uint256 recipientSharePercentage
        );

    function balanceOf(
        uint256 streamId,
        address who
    ) external view returns (uint256 balance);

    function isPauser(address account) external view returns (bool);

    function paused() external view returns (bool);

    function getStream(
        uint256 streamId
    )
        external
        view
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            address tokenAddress,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond
        );

    function owner() external view returns (address);

    function isOwner() external view returns (bool);

    function isCompoundingStream(uint256 streamId) external view returns (bool);

    function deltaOf(uint256 streamId) external view returns (uint256 delta);

    function cTokenManager() external view returns (address);

    function fee() external view returns (uint256 mantissa);
}
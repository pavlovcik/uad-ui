// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol. SEE BELOW FOR SOURCE. !!
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISushiMasterChef {
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool.
        uint256 lastRewardBlock; // Last block number that SUSHI distribution occurs.
        uint256 accSushiPerShare; // Accumulated SUSHI per share, times 1e12. See below.
    }

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user, uint256 indexed pid, uint256 amount
    );

    function deposit(uint256 _pid, uint256 _amount) external;

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external;

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() external;

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) external;

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate)
        external;

    // Update the given pool's SUSHI allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate)
        external;

    // Returns the address of the current owner.
    function owner() external view returns (address);

    // Info of each pool.
    function userInfo(uint256 pid, address user)
        external
        view
        returns (ISushiMasterChef.UserInfo memory);

    // SUSHI tokens created per block.
    function sushiPerBlock() external view returns (uint256);

    // Info of each pool.
    function poolInfo(uint256 pid)
        external
        view
        returns (ISushiMasterChef.PoolInfo memory);

    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    function totalAllocPoint() external view returns (uint256);

    function poolLength() external view returns (uint256);

    // View function to see pending SUSHIs on frontend.
    function pendingSushi(uint256 _pid, address _user)
        external
        view
        returns (uint256);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:

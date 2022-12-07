// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./core/UbiquityDollarManager.sol";
import "./interfaces/IERC20Ubiquity.sol";
import "./interfaces/ITWAPOracleDollar3pool.sol";
import "./StakingShare.sol";
import "./interfaces/IUbiquityFormulas.sol";
import "./interfaces/IERC1155Ubiquity.sol";

contract UbiquityChef is ReentrancyGuard {
    using SafeERC20 for IERC20Ubiquity;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct StakingShareInfo {
        uint256 amount; // staking rights.
        uint256 rewardDebt; // Reward debt. See explanation below.
            //
            // We do some fancy math here. Basically, any point in time, the amount of Governance Tokens
            // entitled to a user but is pending to be distributed is:
            //
            //   pending reward = (user.amount * pool.accGovernancePerShare) - user.rewardDebt
            //
            // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
            //   1. The pool's `accGovernancePerShare` (and `lastRewardBlock`) gets updated.
            //   2. User receives the pending reward sent to his/her address.
            //   3. User's `amount` gets updated.
            //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.

    struct PoolInfo {
        uint256 lastRewardBlock; // Last block number that Governance Token distribution occurs.
        uint256 accGovernancePerShare; // Accumulated Governance Tokens per share, times 1e12. See below.
    }

    uint256 private _totalShares;

    // Ubiquity Manager
    UbiquityDollarManager public manager;

    // Governance Tokens created per block.
    uint256 public governancePerBlock;
    // Bonus multiplier for early Governance Token makers.
    uint256 public governanceMultiplier = 1e18;
    uint256 public minPriceDiffToUpdateMultiplier = 1e15;
    uint256 public lastPrice = 1e18;
    uint256 public governanceDivider;
    // Info of each pool.
    PoolInfo public pool;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => StakingShareInfo) private _ssInfo;

    event Deposit(
        address indexed user, uint256 amount, uint256 indexed stakingShareId
    );

    event Withdraw(
        address indexed user, uint256 amount, uint256 indexed stakingShareId
    );

    event GovernancePerBlockModified(uint256 indexed governancePerBlock);

    event MinPriceDiffToUpdateMultiplierModified(
        uint256 indexed minPriceDiffToUpdateMultiplier
    );

    // ----------- Modifiers -----------
    modifier onlyTokenManager() {
        require(
            manager.hasRole(manager.GOVERNANCE_TOKEN_MANAGER_ROLE(), msg.sender),
            "MasterChef: not Governance Token manager"
        );
        _;
    }

    modifier onlyStakingContract() {
        require(
            msg.sender == manager.stakingContractAddress(),
            "MasterChef: not Staking Contract"
        );
        _;
    }

    constructor(
        address _manager,
        address[] memory _tos,
        uint256[] memory _amounts,
        uint256[] memory _stakingShareIDs
    ) {
        manager = UbiquityDollarManager(_manager);
        pool.lastRewardBlock = block.number;
        pool.accGovernancePerShare = 0; // uint256(1e12);
        governanceDivider = 5; // 100 / 5 = 20% extra minted Governance Tokens for treasury
        _updateGovernanceMultiplier();

        uint256 lgt = _tos.length;
        require(lgt == _amounts.length, "_amounts array not same length");
        require(
            lgt == _stakingShareIDs.length,
            "_stakingShareIDs array not same length"
        );

        for (uint256 i = 0; i < lgt; ++i) {
            _deposit(_tos[i], _amounts[i], _stakingShareIDs[i]);
        }
    }

    function setGovernancePerBlock(uint256 _governancePerBlock) external onlyTokenManager {
        governancePerBlock = _governancePerBlock;
        emit GovernancePerBlockModified(_governancePerBlock);
    }

    // the bigger governanceDivider is the less extra Governance Tokens will be minted for the treasury
    function setGovernanceShareForTreasury(uint256 _governanceDivider)
        external
        onlyTokenManager
    {
        governanceDivider = _governanceDivider;
    }

    function setMinPriceDiffToUpdateMultiplier(
        uint256 _minPriceDiffToUpdateMultiplier
    ) external onlyTokenManager {
        minPriceDiffToUpdateMultiplier = _minPriceDiffToUpdateMultiplier;
        emit MinPriceDiffToUpdateMultiplierModified(
            _minPriceDiffToUpdateMultiplier
            );
    }

    // Deposit LP tokens to MasterChef for Governance Tokens allocation.
    function deposit(address to, uint256 _amount, uint256 _stakingShareID)
        external
        nonReentrant
        onlyStakingContract
    {
        _deposit(to, _amount, _stakingShareID);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(address to, uint256 _amount, uint256 _stakingShareID)
        external
        nonReentrant
        onlyStakingContract
    {
        StakingShareInfo storage ss = _ssInfo[_stakingShareID];
        require(ss.amount >= _amount, "MC: amount too high");
        _updatePool();
        uint256 pending =
            ((ss.amount * pool.accGovernancePerShare) / 1e12) - ss.rewardDebt;
        // send Governance Tokens to Staking Share holder

        _safeGovernanceTransfer(to, pending);
        ss.amount -= _amount;
        ss.rewardDebt = (ss.amount * pool.accGovernancePerShare) / 1e12;
        _totalShares -= _amount;
        emit Withdraw(to, _amount, _stakingShareID);
    }

    /// @dev get pending Governance Token rewards from MasterChef.
    /// @return amount of pending rewards transferred to msg.sender
    /// @notice only send pending rewards
    function getRewards(uint256 stakingShareID) external returns (uint256) {
        require(
            IERC1155Ubiquity(manager.stakingShareAddress()).balanceOf(
                msg.sender, stakingShareID
            ) == 1,
            "MS: caller is not owner"
        );

        // calculate user reward
        StakingShareInfo storage user = _ssInfo[stakingShareID];
        _updatePool();
        uint256 pending =
            ((user.amount * pool.accGovernancePerShare) / 1e12) - user.rewardDebt;
        _safeGovernanceTransfer(msg.sender, pending);
        user.rewardDebt = (user.amount * pool.accGovernancePerShare) / 1e12;
        return pending;
    }

    // View function to see pending Governance Tokens on frontend.
    function pendingGovernance(uint256 stakingShareID)
        external
        view
        returns (uint256)
    {
        StakingShareInfo storage user = _ssInfo[stakingShareID];
        uint256 accGovernancePerShare = pool.accGovernancePerShare;

        if (block.number > pool.lastRewardBlock && _totalShares != 0) {
            uint256 multiplier = _getMultiplier();
            uint256 governanceReward = (multiplier * governancePerBlock) / 1e18;
            accGovernancePerShare =
                accGovernancePerShare + ((governanceReward * 1e12) / _totalShares);
        }
        return (user.amount * accGovernancePerShare) / 1e12 - user.rewardDebt;
    }

    /**
     * @dev get the amount of shares and the reward debt of a staking share .
     */
    function getStakingShareInfo(uint256 _id)
        external
        view
        returns (uint256[2] memory)
    {
        return [_ssInfo[_id].amount, _ssInfo[_id].rewardDebt];
    }

    /**
     * @dev Total amount of shares .
     */
    function totalShares() external view virtual returns (uint256) {
        return _totalShares;
    }

    // _Deposit LP tokens to MasterChef for Governance Token allocation.
    function _deposit(address to, uint256 _amount, uint256 _stakingShareID)
        internal
    {
        StakingShareInfo storage ss = _ssInfo[_stakingShareID];
        _updatePool();
        if (ss.amount > 0) {
            uint256 pending =
                ((ss.amount * pool.accGovernancePerShare) / 1e12) - ss.rewardDebt;
            _safeGovernanceTransfer(to, pending);
        }
        ss.amount += _amount;
        ss.rewardDebt = (ss.amount * pool.accGovernancePerShare) / 1e12;
        _totalShares += _amount;
        emit Deposit(to, _amount, _stakingShareID);
    }

    // UPDATE Governance Token multiplier
    function _updateGovernanceMultiplier() internal {
        // (1.05/(1+abs(1-TWAP_PRICE)))
        uint256 currentPrice = _getTwapPrice();

        bool isPriceDiffEnough = false;
        // a minimum price variation is needed to update the multiplier
        if (currentPrice > lastPrice) {
            isPriceDiffEnough =
                currentPrice - lastPrice > minPriceDiffToUpdateMultiplier;
        } else {
            isPriceDiffEnough =
                lastPrice - currentPrice > minPriceDiffToUpdateMultiplier;
        }

        if (isPriceDiffEnough) {
            governanceMultiplier = IUbiquityFormulas(manager.formulasAddress())
                .governanceMultiply(governanceMultiplier, currentPrice);
            lastPrice = currentPrice;
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function _updatePool() internal {
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        _updateGovernanceMultiplier();

        if (_totalShares == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = _getMultiplier();
        uint256 governanceReward = (multiplier * governancePerBlock) / 1e18;
        IERC20Ubiquity(manager.governanceTokenAddress()).mint(
            address(this), governanceReward
        );
        // mint another x% for the treasury
        IERC20Ubiquity(manager.governanceTokenAddress()).mint(
            manager.treasuryAddress(), governanceReward / governanceDivider
        );
        pool.accGovernancePerShare =
            pool.accGovernancePerShare + ((governanceReward * 1e12) / _totalShares);
        pool.lastRewardBlock = block.number;
    }

    // Safe Governance Token transfer function, just in case if rounding
    // error causes pool to not have enough Governance Tokens.
    function _safeGovernanceTransfer(address _to, uint256 _amount) internal {
        IERC20Ubiquity governanceToken = IERC20Ubiquity(manager.governanceTokenAddress());
        uint256 governanceBalance = governanceToken.balanceOf(address(this));
        if (_amount > governanceBalance) {
            governanceToken.safeTransfer(_to, governanceBalance);
        } else {
            governanceToken.safeTransfer(_to, _amount);
        }
    }

    function _getMultiplier() internal view returns (uint256) {
        return (block.number - pool.lastRewardBlock) * governanceMultiplier;
    }

    function _getTwapPrice() internal view returns (uint256) {
        return ITWAPOracleDollar3pool(manager.twapOracleAddress()).consult(
            manager.dollarTokenAddress()
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IMetaNodeStake
 * @dev Interface for MetaNode staking contract
 */
interface IMetaNodeStake {
    // Structs
    struct Pool {
        address stTokenAddress;     // Address of staking token (address(0) for ETH)
        uint256 poolWeight;         // Pool weight for reward distribution
        uint256 lastRewardBlock;    // Last block number that rewards distribution occurred
        uint256 accMetaNodePerShare; // Accumulated MetaNode per share, times 1e12
        uint256 stTokenAmount;      // Total amount of tokens staked in pool
        uint256 minDepositAmount;   // Minimum deposit amount
        uint256 unstakeLockedBlocks; // Number of blocks tokens are locked after unstaking
    }

    struct User {
        uint256 stAmount;           // Amount of tokens user has staked
        uint256 finishedMetaNode;   // Finished MetaNode rewards
        uint256 pendingMetaNode;    // Pending MetaNode rewards
    }

    struct UnstakeRequest {
        uint256 amount;             // Amount to unstake
        uint256 unlockTime;         // Block number when tokens can be withdrawn
        bool processed;             // Whether the request has been processed
    }

    // Events
    event PoolAdded(
        uint256 indexed pid,
        address indexed stTokenAddress,
        uint256 poolWeight,
        uint256 minDepositAmount,
        uint256 unstakeLockedBlocks
    );

    event PoolUpdated(
        uint256 indexed pid,
        uint256 poolWeight,
        uint256 minDepositAmount,
        uint256 unstakeLockedBlocks
    );

    event Staked(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    event Unstaked(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        uint256 unlockTime
    );

    event Withdrawn(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    event RewardClaimed(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    event RewardPerBlockUpdated(uint256 oldReward, uint256 newReward);

    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    // Functions
    function addPool(
        address _stTokenAddress,
        uint256 _poolWeight,
        uint256 _minDepositAmount,
        uint256 _unstakeLockedBlocks
    ) external;

    function updatePool(
        uint256 _pid,
        uint256 _poolWeight,
        uint256 _minDepositAmount,
        uint256 _unstakeLockedBlocks
    ) external;

    function stake(uint256 _pid, uint256 _amount) external payable;

    function unstake(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _requestIndex) external;

    function claimReward(uint256 _pid) external;

    function emergencyWithdraw(uint256 _pid) external;

    // View functions
    function poolLength() external view returns (uint256);

    function getPool(uint256 _pid) external view returns (Pool memory);

    function getUser(uint256 _pid, address _user) external view returns (User memory);

    function getUserUnstakeRequests(uint256 _pid, address _user) external view returns (UnstakeRequest[] memory);

    function pendingReward(uint256 _pid, address _user) external view returns (uint256);
}
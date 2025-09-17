// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IStakeContract
 * @dev Interface for the main staking contract
 */
interface IStakeContract {
    // Structs
    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        uint256 lastRewardTime;
        uint256 accumulatedRewards;
        bool active;
    }

    // Events
    event Staked(address indexed user, uint256 amount, uint256 timestamp);
    event Unstaked(address indexed user, uint256 amount, uint256 timestamp);
    event RewardsClaimed(address indexed user, uint256 amount, uint256 timestamp);
    event EmergencyWithdrawToggled(bool enabled);

    // Core staking functions
    function stake() external payable;
    function unstake(uint256 _amount) external;
    function claimRewards() external;
    function emergencyWithdraw() external;

    // View functions
    function getPendingRewards(address _user) external view returns (uint256);
    function getUserStakeInfo(address _user) external view returns (
        uint256 amount,
        uint256 startTime,
        uint256 lastRewardTime,
        uint256 accumulatedRewards,
        bool active
    );
    function getContractStats() external view returns (
        uint256 _totalStaked,
        uint256 _totalRewardsDistributed,
        uint256 _contractBalance,
        uint256 _activeStakers
    );

    // Admin functions
    function toggleEmergencyWithdraw(bool _enabled) external;
    function pause() external;
    function unpause() external;
    function withdrawContractBalance(uint256 _amount) external;
}
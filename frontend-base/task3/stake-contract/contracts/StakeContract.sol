// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MetaNodeToken.sol";

/**
 * @title StakeContract
 * @dev Main staking contract that allows users to stake ETH and earn MetaNode token rewards
 * @notice Users can stake ETH and earn rewards based on staking duration and amount
 */
contract StakeContract is ReentrancyGuard, Pausable, AccessControl {
    using SafeMath for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // Staking parameters
    uint256 public constant MIN_STAKE_AMOUNT = 0.01 ether; // Minimum stake amount
    uint256 public constant MAX_STAKE_AMOUNT = 100 ether; // Maximum stake amount per user
    uint256 public constant REWARD_RATE = 100; // 1% per day (100 basis points)
    uint256 public constant SECONDS_PER_DAY = 86400;
    uint256 public constant BASIS_POINTS = 10000;

    // Contract state
    MetaNodeToken public immutable rewardToken;
    uint256 public totalStaked;
    uint256 public totalRewardsDistributed;
    bool public emergencyWithdrawEnabled;

    // Staking data structures
    struct StakeInfo {
        uint256 amount; // Amount of ETH staked
        uint256 startTime; // When the stake was created
        uint256 lastRewardTime; // Last time rewards were calculated
        uint256 accumulatedRewards; // Accumulated but unclaimed rewards
        bool active; // Whether the stake is active
    }

    // Mappings
    mapping(address => StakeInfo) public stakes;
    mapping(address => uint256) public userTotalStaked;
    mapping(address => uint256) public userTotalRewards;

    // Events
    event Staked(address indexed user, uint256 amount, uint256 timestamp);
    event Unstaked(address indexed user, uint256 amount, uint256 timestamp);
    event RewardsClaimed(address indexed user, uint256 amount, uint256 timestamp);
    event EmergencyWithdrawToggled(bool enabled);
    event RewardRateUpdated(uint256 newRate);

    /**
     * @dev Constructor
     * @param _rewardToken Address of the MetaNode token contract
     */
    constructor(address _rewardToken) {
        require(_rewardToken != address(0), "Invalid reward token address");
        
        rewardToken = MetaNodeToken(_rewardToken);
        
        // Grant roles to deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
    }

    /**
     * @dev Stake ETH to earn rewards
     * @notice Users can stake ETH and start earning MetaNode token rewards
     */
    function stake() external payable nonReentrant whenNotPaused {
        require(msg.value >= MIN_STAKE_AMOUNT, "Stake amount too low");
        require(
            userTotalStaked[msg.sender].add(msg.value) <= MAX_STAKE_AMOUNT,
            "Stake amount exceeds maximum"
        );

        StakeInfo storage userStake = stakes[msg.sender];

        // If user already has an active stake, claim pending rewards first
        if (userStake.active) {
            _updateRewards(msg.sender);
            userStake.amount = userStake.amount.add(msg.value);
        } else {
            // Create new stake
            userStake.amount = msg.value;
            userStake.startTime = block.timestamp;
            userStake.lastRewardTime = block.timestamp;
            userStake.accumulatedRewards = 0;
            userStake.active = true;
        }

        // Update global state
        totalStaked = totalStaked.add(msg.value);
        userTotalStaked[msg.sender] = userTotalStaked[msg.sender].add(msg.value);

        emit Staked(msg.sender, msg.value, block.timestamp);
    }

    /**
     * @dev Unstake ETH and claim all rewards
     * @param _amount Amount of ETH to unstake (0 means unstake all)
     */
    function unstake(uint256 _amount) external nonReentrant whenNotPaused {
        StakeInfo storage userStake = stakes[msg.sender];
        require(userStake.active, "No active stake found");
        
        uint256 unstakeAmount = _amount == 0 ? userStake.amount : _amount;
        require(unstakeAmount > 0, "Invalid unstake amount");
        require(unstakeAmount <= userStake.amount, "Insufficient staked amount");

        // Update rewards before unstaking
        _updateRewards(msg.sender);

        // Calculate proportional rewards to claim
        uint256 rewardsToTransfer = 0;
        if (unstakeAmount == userStake.amount) {
            // Unstaking all, claim all rewards
            rewardsToTransfer = userStake.accumulatedRewards;
            userStake.active = false;
            userStake.accumulatedRewards = 0;
        } else {
            // Partial unstake, claim proportional rewards
            rewardsToTransfer = userStake.accumulatedRewards.mul(unstakeAmount).div(userStake.amount);
            userStake.accumulatedRewards = userStake.accumulatedRewards.sub(rewardsToTransfer);
        }

        // Update stake amount
        userStake.amount = userStake.amount.sub(unstakeAmount);
        
        // Update global state
        totalStaked = totalStaked.sub(unstakeAmount);
        userTotalStaked[msg.sender] = userTotalStaked[msg.sender].sub(unstakeAmount);

        // Transfer ETH back to user
        (bool success, ) = payable(msg.sender).call{value: unstakeAmount}("");
        require(success, "ETH transfer failed");

        // Transfer rewards if any
        if (rewardsToTransfer > 0) {
            _transferRewards(msg.sender, rewardsToTransfer);
        }

        emit Unstaked(msg.sender, unstakeAmount, block.timestamp);
    }

    /**
     * @dev Claim accumulated rewards without unstaking
     */
    function claimRewards() external nonReentrant whenNotPaused {
        require(!emergencyWithdrawEnabled, "Cannot claim rewards during emergency mode");
        
        StakeInfo storage userStake = stakes[msg.sender];
        require(userStake.active, "No active stake found");

        _updateRewards(msg.sender);
        
        uint256 rewardsToTransfer = userStake.accumulatedRewards;
        require(rewardsToTransfer > 0, "No rewards to claim");

        userStake.accumulatedRewards = 0;
        _transferRewards(msg.sender, rewardsToTransfer);

        emit RewardsClaimed(msg.sender, rewardsToTransfer, block.timestamp);
    }

    /**
     * @dev Emergency withdraw function (only when enabled by admin)
     */
    function emergencyWithdraw() external nonReentrant {
        require(emergencyWithdrawEnabled, "Emergency withdraw not enabled");
        
        StakeInfo storage userStake = stakes[msg.sender];
        require(userStake.active, "No active stake found");

        uint256 stakeAmount = userStake.amount;
        
        // Reset user stake
        userStake.amount = 0;
        userStake.active = false;
        userStake.accumulatedRewards = 0;

        // Update global state
        totalStaked = totalStaked.sub(stakeAmount);
        userTotalStaked[msg.sender] = userTotalStaked[msg.sender].sub(stakeAmount);

        // Transfer ETH back to user (no rewards in emergency)
        (bool success, ) = payable(msg.sender).call{value: stakeAmount}("");
        require(success, "ETH transfer failed");

        emit Unstaked(msg.sender, stakeAmount, block.timestamp);
    }

    /**
     * @dev Calculate pending rewards for a user
     * @param _user Address of the user
     * @return Pending rewards amount
     */
    function getPendingRewards(address _user) external view returns (uint256) {
        StakeInfo memory userStake = stakes[_user];
        if (!userStake.active || userStake.amount == 0) {
            return userStake.accumulatedRewards;
        }

        uint256 timeElapsed = block.timestamp.sub(userStake.lastRewardTime);
        uint256 newRewards = userStake.amount
            .mul(REWARD_RATE)
            .mul(timeElapsed)
            .div(SECONDS_PER_DAY)
            .div(BASIS_POINTS);

        return userStake.accumulatedRewards.add(newRewards);
    }

    /**
     * @dev Get user stake information
     * @param _user Address of the user
     * @return amount Staked amount
     * @return startTime Stake start time
     * @return lastRewardTime Last reward calculation time
     * @return accumulatedRewards Total accumulated rewards
     * @return active Whether the stake is active
     */
    function getUserStakeInfo(address _user) external view returns (
        uint256 amount,
        uint256 startTime,
        uint256 lastRewardTime,
        uint256 accumulatedRewards,
        bool active
    ) {
        StakeInfo memory userStake = stakes[_user];
        return (
            userStake.amount,
            userStake.startTime,
            userStake.lastRewardTime,
            userStake.accumulatedRewards,
            userStake.active
        );
    }

    /**
     * @dev Internal function to update rewards for a user
     * @param _user Address of the user
     */
    function _updateRewards(address _user) internal {
        StakeInfo storage userStake = stakes[_user];
        if (!userStake.active || userStake.amount == 0) {
            return;
        }

        uint256 timeElapsed = block.timestamp.sub(userStake.lastRewardTime);
        if (timeElapsed > 0) {
            uint256 newRewards = userStake.amount
                .mul(REWARD_RATE)
                .mul(timeElapsed)
                .div(SECONDS_PER_DAY)
                .div(BASIS_POINTS);

            userStake.accumulatedRewards = userStake.accumulatedRewards.add(newRewards);
            userStake.lastRewardTime = block.timestamp;
        }
    }

    /**
     * @dev Internal function to transfer rewards to user
     * @param _user Address of the user
     * @param _amount Amount of rewards to transfer
     */
    function _transferRewards(address _user, uint256 _amount) internal {
        require(_amount > 0, "No rewards to transfer");
        
        // Check if contract has enough tokens to mint
        require(
            rewardToken.remainingMintableSupply() >= _amount,
            "Insufficient mintable supply"
        );

        // Mint rewards to user
        rewardToken.mint(_user, _amount);
        
        // Update global state
        totalRewardsDistributed = totalRewardsDistributed.add(_amount);
        userTotalRewards[_user] = userTotalRewards[_user].add(_amount);
    }

    // Admin functions

    /**
     * @dev Toggle emergency withdraw functionality
     * @param _enabled Whether to enable emergency withdraw
     */
    function toggleEmergencyWithdraw(bool _enabled) external onlyRole(ADMIN_ROLE) {
        emergencyWithdrawEnabled = _enabled;
        emit EmergencyWithdrawToggled(_enabled);
    }

    /**
     * @dev Pause the contract
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause the contract
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Withdraw contract ETH balance (for admin use)
     * @param _amount Amount to withdraw (0 means withdraw all)
     */
    function withdrawContractBalance(uint256 _amount) external onlyRole(ADMIN_ROLE) {
        uint256 contractBalance = address(this).balance;
        uint256 withdrawAmount = _amount == 0 ? contractBalance : _amount;
        
        require(withdrawAmount <= contractBalance, "Insufficient contract balance");
        require(withdrawAmount <= contractBalance.sub(totalStaked), "Cannot withdraw staked funds");

        (bool success, ) = payable(msg.sender).call{value: withdrawAmount}("");
        require(success, "ETH transfer failed");
    }

    /**
     * @dev Get contract statistics
     * @return _totalStaked Total amount staked
     * @return _totalRewardsDistributed Total rewards distributed
     * @return _contractBalance Current contract balance
     * @return _activeStakers Number of active stakers
     */
    function getContractStats() external view returns (
        uint256 _totalStaked,
        uint256 _totalRewardsDistributed,
        uint256 _contractBalance,
        uint256 _activeStakers
    ) {
        return (
            totalStaked,
            totalRewardsDistributed,
            address(this).balance,
            0 // Note: activeStakers would need additional tracking
        );
    }

    /**
     * @dev Receive function to accept ETH
     */
    receive() external payable {
        // Allow contract to receive ETH
    }
}
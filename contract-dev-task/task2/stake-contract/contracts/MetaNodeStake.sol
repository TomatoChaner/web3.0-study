// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IMetaNodeStake.sol";

/**
 * @title MetaNodeStake
 * @dev Staking contract for MetaNode tokens with multiple pools
 */
contract MetaNodeStake is 
    IMetaNodeStake,
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable 
{
    using SafeERC20 for IERC20;

    // Constants
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // State variables
    IERC20 public metaNodeToken;
    uint256 public rewardPerBlock;
    uint256 public lastRewardBlock;
    uint256 public totalPoolWeight;

    // Pool and user data
    Pool[] public pools;
    mapping(uint256 => mapping(address => User)) public users;
    mapping(uint256 => mapping(address => UnstakeRequest[])) public unstakeRequests;

    // Modifiers
    modifier validPool(uint256 _pid) {
        require(_pid < pools.length, "MetaNodeStake: Invalid pool ID");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "MetaNodeStake: Caller is not admin");
        _;
    }

    /**
     * @dev Constructor
     * @notice Disables initializers to prevent the implementation contract from being initialized
     * This is required for proxy upgrade pattern
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialize the contract
     */
    function initialize(
        address _metaNodeToken,
        uint256 _rewardPerBlock,
        address _admin
    ) external initializer {
        require(_metaNodeToken != address(0), "MetaNodeStake: Invalid token address");
        require(_admin != address(0), "MetaNodeStake: Invalid admin address");
        require(_rewardPerBlock > 0, "MetaNodeStake: Invalid reward per block");

        // Initialize parent contracts
        __AccessControl_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        metaNodeToken = IERC20(_metaNodeToken);
        rewardPerBlock = _rewardPerBlock;
        lastRewardBlock = block.number;

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(ADMIN_ROLE, _admin);

        emit RewardPerBlockUpdated(0, _rewardPerBlock);
    }

    /**
     * @dev Authorize upgrade (required by UUPSUpgradeable)
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}

    /**
     * @dev Add a new pool
     */
    function addPool(
        address _stTokenAddress,
        uint256 _poolWeight,
        uint256 _minDepositAmount,
        uint256 _unstakeLockedBlocks
    ) external onlyAdmin {
        pools.push(Pool({
            stTokenAddress: _stTokenAddress,
            poolWeight: _poolWeight,
            lastRewardBlock: block.number,
            accMetaNodePerShare: 0,
            stTokenAmount: 0,
            minDepositAmount: _minDepositAmount,
            unstakeLockedBlocks: _unstakeLockedBlocks
        }));

        totalPoolWeight += _poolWeight;

        emit PoolAdded(pools.length - 1, _stTokenAddress, _poolWeight, _minDepositAmount, _unstakeLockedBlocks);
    }

    /**
     * @dev Update pool parameters
     */
    function updatePool(
        uint256 _pid,
        uint256 _poolWeight,
        uint256 _minDepositAmount,
        uint256 _unstakeLockedBlocks
    ) external onlyAdmin validPool(_pid) {
        _updatePool(_pid);
        
        totalPoolWeight = totalPoolWeight - pools[_pid].poolWeight + _poolWeight;
        pools[_pid].poolWeight = _poolWeight;
        pools[_pid].minDepositAmount = _minDepositAmount;
        pools[_pid].unstakeLockedBlocks = _unstakeLockedBlocks;

        emit PoolUpdated(_pid, _poolWeight, _minDepositAmount, _unstakeLockedBlocks);
    }

    /**
     * @dev Stake tokens
     */
    function stake(uint256 _pid, uint256 _amount) external payable nonReentrant whenNotPaused validPool(_pid) {
        Pool storage pool = pools[_pid];
        User storage user = users[_pid][msg.sender];

        require(_amount >= pool.minDepositAmount, "MetaNodeStake: Amount below minimum");

        _updatePool(_pid);

        if (user.stAmount > 0) {
            uint256 pending = user.stAmount * pool.accMetaNodePerShare / 1e12 - user.finishedMetaNode;
            if (pending > 0) {
                user.pendingMetaNode += pending;
            }
        }

        if (pool.stTokenAddress == address(0)) {
            // ETH staking
            require(msg.value == _amount, "MetaNodeStake: ETH amount mismatch");
        } else {
            // ERC20 staking
            require(msg.value == 0, "MetaNodeStake: ETH not accepted for ERC20 pools");
            IERC20(pool.stTokenAddress).safeTransferFrom(msg.sender, address(this), _amount);
        }

        user.stAmount += _amount;
        pool.stTokenAmount += _amount;
        user.finishedMetaNode = user.stAmount * pool.accMetaNodePerShare / 1e12;

        emit Staked(msg.sender, _pid, _amount);
    }

    /**
     * @dev Unstake tokens
     */
    function unstake(uint256 _pid, uint256 _amount) external nonReentrant whenNotPaused validPool(_pid) {
        Pool storage pool = pools[_pid];
        User storage user = users[_pid][msg.sender];

        require(user.stAmount >= _amount, "MetaNodeStake: Insufficient staked amount");

        _updatePool(_pid);

        uint256 pending = user.stAmount * pool.accMetaNodePerShare / 1e12 - user.finishedMetaNode;
        if (pending > 0) {
            user.pendingMetaNode += pending;
        }

        user.stAmount -= _amount;
        pool.stTokenAmount -= _amount;
        user.finishedMetaNode = user.stAmount * pool.accMetaNodePerShare / 1e12;

        uint256 unlockTime = block.number + pool.unstakeLockedBlocks;
        unstakeRequests[_pid][msg.sender].push(UnstakeRequest({
            amount: _amount,
            unlockTime: unlockTime,
            processed: false
        }));

        emit Unstaked(msg.sender, _pid, _amount, unlockTime);
    }

    /**
     * @dev Withdraw unstaked tokens
     */
    function withdraw(uint256 _pid, uint256 _requestIndex) external nonReentrant validPool(_pid) {
        UnstakeRequest storage request = unstakeRequests[_pid][msg.sender][_requestIndex];
        
        require(!request.processed, "MetaNodeStake: Request already processed");
        require(block.number >= request.unlockTime, "MetaNodeStake: Tokens still locked");

        request.processed = true;
        uint256 amount = request.amount;

        Pool storage pool = pools[_pid];
        if (pool.stTokenAddress == address(0)) {
            // ETH withdrawal
            payable(msg.sender).transfer(amount);
        } else {
            // ERC20 withdrawal
            IERC20(pool.stTokenAddress).safeTransfer(msg.sender, amount);
        }

        emit Withdrawn(msg.sender, _pid, amount);
    }

    /**
     * @dev Claim rewards
     */
    function claimReward(uint256 _pid) external nonReentrant whenNotPaused validPool(_pid) {
        Pool storage pool = pools[_pid];
        User storage user = users[_pid][msg.sender];

        _updatePool(_pid);

        uint256 pending = user.stAmount * pool.accMetaNodePerShare / 1e12 - user.finishedMetaNode;
        uint256 totalReward = user.pendingMetaNode + pending;

        if (totalReward > 0) {
            user.pendingMetaNode = 0;
            user.finishedMetaNode = user.stAmount * pool.accMetaNodePerShare / 1e12;
            metaNodeToken.safeTransfer(msg.sender, totalReward);
            emit RewardClaimed(msg.sender, _pid, totalReward);
        }
    }

    /**
     * @dev Emergency withdraw without caring about rewards
     */
    function emergencyWithdraw(uint256 _pid) external nonReentrant validPool(_pid) {
        Pool storage pool = pools[_pid];
        User storage user = users[_pid][msg.sender];

        uint256 amount = user.stAmount;
        user.stAmount = 0;
        user.finishedMetaNode = 0;
        user.pendingMetaNode = 0;
        pool.stTokenAmount -= amount;

        if (pool.stTokenAddress == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20(pool.stTokenAddress).safeTransfer(msg.sender, amount);
        }

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    /**
     * @dev Set reward per block (admin only)
     */
    function setRewardPerBlock(uint256 _rewardPerBlock) external onlyAdmin {
        uint256 oldReward = rewardPerBlock;
        rewardPerBlock = _rewardPerBlock;
        emit RewardPerBlockUpdated(oldReward, _rewardPerBlock);
    }

    /**
     * @dev Pause the contract (admin only)
     */
    function pause() external onlyAdmin {
        _pause();
    }

    /**
     * @dev Unpause the contract (admin only)
     */
    function unpause() external onlyAdmin {
        _unpause();
    }

    // View functions
    function poolLength() external view returns (uint256) {
        return pools.length;
    }

    function getPool(uint256 _pid) external view validPool(_pid) returns (Pool memory) {
        return pools[_pid];
    }

    function getUser(uint256 _pid, address _user) external view validPool(_pid) returns (User memory) {
        return users[_pid][_user];
    }

    function getUserUnstakeRequests(uint256 _pid, address _user) external view validPool(_pid) returns (UnstakeRequest[] memory) {
        return unstakeRequests[_pid][_user];
    }

    function pendingReward(uint256 _pid, address _user) external view validPool(_pid) returns (uint256) {
        Pool storage pool = pools[_pid];
        User storage user = users[_pid][_user];

        uint256 accMetaNodePerShare = pool.accMetaNodePerShare;
        if (block.number > pool.lastRewardBlock && pool.stTokenAmount != 0 && totalPoolWeight > 0) {
            uint256 multiplier = block.number - pool.lastRewardBlock;
            uint256 reward = multiplier * rewardPerBlock * pool.poolWeight / totalPoolWeight;
            accMetaNodePerShare += reward * 1e12 / pool.stTokenAmount;
        }

        return user.stAmount * accMetaNodePerShare / 1e12 - user.finishedMetaNode + user.pendingMetaNode;
    }

    // Internal functions
    function _updatePool(uint256 _pid) internal {
        Pool storage pool = pools[_pid];
        
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        if (pool.stTokenAmount == 0 || totalPoolWeight == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = block.number - pool.lastRewardBlock;
        uint256 reward = multiplier * rewardPerBlock * pool.poolWeight / totalPoolWeight;
        pool.accMetaNodePerShare += reward * 1e12 / pool.stTokenAmount;
        pool.lastRewardBlock = block.number;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../libraries/TransferHelper.sol";

/**
 * @title TokenVesting
 * @dev 代币锁仓合约，支持线性释放和分期释放
 */
contract TokenVesting is Ownable, ReentrancyGuard {
    using TransferHelper for address;

    struct VestingSchedule {
        bool initialized;
        address beneficiary;
        uint256 cliff;
        uint256 start;
        uint256 duration;
        uint256 slicePeriodSeconds;
        bool revocable;
        uint256 amountTotal;
        uint256 released;
        bool revoked;
    }

    // 代币合约地址
    IERC20 private immutable _token;
    
    // 锁仓计划映射
    mapping(bytes32 => VestingSchedule) private vestingSchedules;
    
    // 受益人的锁仓计划ID列表
    mapping(address => bytes32[]) private holdersVestingSchedules;
    
    // 锁仓计划总数
    uint256 private vestingSchedulesTotalCount;
    
    // 总锁仓金额
    uint256 private vestingSchedulesTotalAmount;

    // 事件
    event VestingScheduleCreated(
        bytes32 indexed vestingScheduleId,
        address indexed beneficiary,
        uint256 amount
    );
    
    event TokensReleased(
        bytes32 indexed vestingScheduleId,
        address indexed beneficiary,
        uint256 amount
    );
    
    event VestingScheduleRevoked(
        bytes32 indexed vestingScheduleId,
        address indexed beneficiary,
        uint256 unreleased
    );

    modifier onlyIfVestingScheduleExists(bytes32 vestingScheduleId) {
        require(vestingSchedules[vestingScheduleId].initialized, "TokenVesting: vesting schedule not found");
        _;
    }

    modifier onlyIfVestingScheduleNotRevoked(bytes32 vestingScheduleId) {
        require(!vestingSchedules[vestingScheduleId].revoked, "TokenVesting: vesting schedule revoked");
        _;
    }

    /**
     * @dev 构造函数
     * @param token_ 代币合约地址
     */
    constructor(address token_) {
        require(token_ != address(0), "TokenVesting: token is zero address");
        _token = IERC20(token_);
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev 创建锁仓计划
     * @param _beneficiary 受益人地址
     * @param _start 开始时间
     * @param _cliff 悬崖期（秒）
     * @param _duration 总持续时间（秒）
     * @param _slicePeriodSeconds 释放周期（秒）
     * @param _revocable 是否可撤销
     * @param _amount 锁仓总金额
     */
    function createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        bool _revocable,
        uint256 _amount
    ) external onlyOwner {
        require(_beneficiary != address(0), "TokenVesting: beneficiary is zero address");
        require(_duration > 0, "TokenVesting: duration must be > 0");
        require(_amount > 0, "TokenVesting: amount must be > 0");
        require(_slicePeriodSeconds >= 1, "TokenVesting: slicePeriodSeconds must be >= 1");
        require(_duration >= _cliff, "TokenVesting: duration must be >= cliff");
        
        bytes32 vestingScheduleId = computeNextVestingScheduleIdForHolder(_beneficiary);
        uint256 cliff = _start + _cliff;
        
        vestingSchedules[vestingScheduleId] = VestingSchedule(
            true,
            _beneficiary,
            cliff,
            _start,
            _duration,
            _slicePeriodSeconds,
            _revocable,
            _amount,
            0,
            false
        );
        
        vestingSchedulesTotalAmount += _amount;
        vestingSchedulesTotalCount++;
        holdersVestingSchedules[_beneficiary].push(vestingScheduleId);
        
        uint256 currentTokenBalance = _token.balanceOf(address(this));
        require(
            currentTokenBalance >= vestingSchedulesTotalAmount,
            "TokenVesting: insufficient token balance"
        );
        
        emit VestingScheduleCreated(vestingScheduleId, _beneficiary, _amount);
    }

    /**
     * @dev 撤销锁仓计划
     * @param vestingScheduleId 锁仓计划ID
     */
    function revoke(bytes32 vestingScheduleId)
        external
        onlyOwner
        onlyIfVestingScheduleExists(vestingScheduleId)
        onlyIfVestingScheduleNotRevoked(vestingScheduleId)
    {
        VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
        require(vestingSchedule.revocable, "TokenVesting: vesting schedule not revocable");
        
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        if (vestedAmount > 0) {
            release(vestingScheduleId, vestedAmount);
        }
        
        uint256 unreleased = vestingSchedule.amountTotal - vestingSchedule.released;
        vestingSchedulesTotalAmount -= unreleased;
        vestingSchedule.revoked = true;
        
        emit VestingScheduleRevoked(vestingScheduleId, vestingSchedule.beneficiary, unreleased);
    }

    /**
     * @dev 释放代币
     * @param vestingScheduleId 锁仓计划ID
     * @param amount 释放数量
     */
    function release(bytes32 vestingScheduleId, uint256 amount)
        public
        nonReentrant
        onlyIfVestingScheduleExists(vestingScheduleId)
        onlyIfVestingScheduleNotRevoked(vestingScheduleId)
    {
        VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
        bool isBeneficiary = msg.sender == vestingSchedule.beneficiary;
        bool isOwner = msg.sender == owner();
        require(isBeneficiary || isOwner, "TokenVesting: only beneficiary and owner can release vested tokens");
        
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        require(vestedAmount >= amount, "TokenVesting: cannot release tokens, not enough vested tokens");
        
        vestingSchedule.released += amount;
        vestingSchedulesTotalAmount -= amount;
        
        address(_token).safeTransfer(vestingSchedule.beneficiary, amount);
        
        emit TokensReleased(vestingScheduleId, vestingSchedule.beneficiary, amount);
    }

    /**
     * @dev 批量释放代币
     * @param vestingScheduleIds 锁仓计划ID数组
     */
    function batchRelease(bytes32[] memory vestingScheduleIds) external {
        for (uint256 i = 0; i < vestingScheduleIds.length; i++) {
            bytes32 vestingScheduleId = vestingScheduleIds[i];
            VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
            uint256 releasableAmount = _computeReleasableAmount(vestingSchedule);
            if (releasableAmount > 0) {
                release(vestingScheduleId, releasableAmount);
            }
        }
    }

    /**
     * @dev 获取锁仓计划数量
     */
    function getVestingSchedulesTotalCount() external view returns (uint256) {
        return vestingSchedulesTotalCount;
    }

    /**
     * @dev 获取总锁仓金额
     */
    function getVestingSchedulesTotalAmount() external view returns (uint256) {
        return vestingSchedulesTotalAmount;
    }

    /**
     * @dev 获取代币地址
     */
    function getToken() external view returns (address) {
        return address(_token);
    }

    /**
     * @dev 获取锁仓计划详情
     */
    function getVestingSchedule(bytes32 vestingScheduleId)
        external
        view
        returns (VestingSchedule memory)
    {
        return vestingSchedules[vestingScheduleId];
    }

    /**
     * @dev 获取可释放金额
     */
    function computeReleasableAmount(bytes32 vestingScheduleId)
        external
        view
        onlyIfVestingScheduleExists(vestingScheduleId)
        onlyIfVestingScheduleNotRevoked(vestingScheduleId)
        returns (uint256)
    {
        VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
        return _computeReleasableAmount(vestingSchedule);
    }

    /**
     * @dev 获取锁仓计划ID
     */
    function computeVestingScheduleIdForAddressAndIndex(address holder, uint256 index)
        external
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(holder, index));
    }

    /**
     * @dev 获取受益人的锁仓计划数量
     */
    function getVestingSchedulesCountByBeneficiary(address _beneficiary)
        external
        view
        returns (uint256)
    {
        return holdersVestingSchedules[_beneficiary].length;
    }

    /**
     * @dev 获取受益人的锁仓计划ID
     */
    function getVestingIdAtIndex(address holder, uint256 index)
        external
        view
        returns (bytes32)
    {
        return holdersVestingSchedules[holder][index];
    }

    /**
     * @dev 获取受益人的所有锁仓计划
     */
    function getVestingSchedulesByBeneficiary(address _beneficiary)
        external
        view
        returns (VestingSchedule[] memory)
    {
        bytes32[] memory vestingScheduleIds = holdersVestingSchedules[_beneficiary];
        VestingSchedule[] memory vestingSchedules_ = new VestingSchedule[](vestingScheduleIds.length);
        
        for (uint256 i = 0; i < vestingScheduleIds.length; i++) {
            vestingSchedules_[i] = vestingSchedules[vestingScheduleIds[i]];
        }
        
        return vestingSchedules_;
    }

    /**
     * @dev 计算下一个锁仓计划ID
     */
    function computeNextVestingScheduleIdForHolder(address holder)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(holder, holdersVestingSchedules[holder].length));
    }

    /**
     * @dev 获取最后一个锁仓计划ID
     */
    function getLastVestingScheduleForHolder(address holder)
        external
        view
        returns (bytes32)
    {
        return holdersVestingSchedules[holder][holdersVestingSchedules[holder].length - 1];
    }

    /**
     * @dev 计算可释放金额
     */
    function _computeReleasableAmount(VestingSchedule memory vestingSchedule)
        internal
        view
        returns (uint256)
    {
        uint256 currentTime = getCurrentTime();
        if ((currentTime < vestingSchedule.cliff) || vestingSchedule.revoked) {
            return 0;
        } else if (currentTime >= vestingSchedule.start + vestingSchedule.duration) {
            return vestingSchedule.amountTotal - vestingSchedule.released;
        } else {
            uint256 timeFromStart = currentTime - vestingSchedule.start;
            uint256 secondsPerSlice = vestingSchedule.slicePeriodSeconds;
            uint256 vestedSlicePeriods = timeFromStart / secondsPerSlice;
            uint256 vestedSeconds = vestedSlicePeriods * secondsPerSlice;
            uint256 vestedAmount = (vestingSchedule.amountTotal * vestedSeconds) / vestingSchedule.duration;
            return vestedAmount - vestingSchedule.released;
        }
    }

    /**
     * @dev 获取当前时间
     */
    function getCurrentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /**
     * @dev 紧急提取代币
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        require(token != address(_token), "TokenVesting: cannot withdraw vesting token");
        address(token).safeTransfer(owner(), amount);
    }

    /**
     * @dev 紧急提取ETH
     */
    function emergencyWithdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "TokenVesting: no ETH to withdraw");
        payable(owner()).transfer(balance);
    }
}
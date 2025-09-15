// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ICrossChainAuction.sol";
import "./CrossChainMessenger.sol";
import "../interfaces/IPriceOracle.sol";

/**
 * @title CrossChainBidSettlement
 * @dev 跨链出价和结算合约
 * @notice 处理跨链出价的资金托管、验证和自动结算
 */
contract CrossChainBidSettlement is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // ============ 状态变量 ============

    /// @dev 跨链消息传递合约
    CrossChainMessenger public immutable messenger;
    
    /// @dev 价格预言机合约
    IPriceOracle public priceOracle;
    
    /// @dev 拍卖管理器合约
    address public auctionManager;
    
    /// @dev 出价托管信息
    struct EscrowInfo {
        address bidder;           // 出价者
        uint256 amount;          // 托管金额
        address token;           // 代币地址（address(0)表示ETH）
        uint256 auctionId;       // 拍卖ID
        uint64 targetChainId;    // 目标链ID
        uint256 timestamp;       // 托管时间
        bool isActive;           // 是否活跃
        bool isSettled;          // 是否已结算
    }
    
    /// @dev 托管ID计数器
    uint256 public escrowCounter;
    
    /// @dev 托管信息映射
    mapping(uint256 => EscrowInfo) public escrows;
    
    /// @dev 用户托管映射
    mapping(address => uint256[]) public userEscrows;
    
    /// @dev 拍卖托管映射
    mapping(uint256 => uint256[]) public auctionEscrows;
    
    /// @dev 结算信息
    struct SettlementInfo {
        uint256 auctionId;       // 拍卖ID
        address winner;          // 获胜者
        uint256 winningAmount;   // 获胜金额
        address winningToken;    // 获胜代币
        uint256 escrowId;        // 托管ID
        uint256 timestamp;       // 结算时间
        bool isExecuted;         // 是否已执行
    }
    
    /// @dev 结算信息映射
    mapping(uint256 => SettlementInfo) public settlements;
    
    /// @dev 支持的代币映射
    mapping(address => bool) public supportedTokens;
    
    /// @dev 最小托管时间（秒）
    uint256 public constant MIN_ESCROW_DURATION = 1 hours;
    
    /// @dev 最大托管时间（秒）
    uint256 public constant MAX_ESCROW_DURATION = 7 days;
    
    /// @dev 结算超时时间（秒）
    uint256 public settlementTimeout = 24 hours;

    // ============ 事件定义 ============

    event BidEscrowed(
        uint256 indexed escrowId,
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 amount,
        address token,
        uint64 targetChainId
    );
    
    event BidReleased(
        uint256 indexed escrowId,
        address indexed bidder,
        uint256 amount,
        address token
    );
    
    event SettlementInitiated(
        uint256 indexed auctionId,
        address indexed winner,
        uint256 winningAmount,
        uint256 escrowId
    );
    
    event SettlementExecuted(
        uint256 indexed auctionId,
        address indexed winner,
        uint256 amount,
        address token
    );
    
    event RefundProcessed(
        uint256 indexed escrowId,
        address indexed bidder,
        uint256 amount,
        address token
    );

    // ============ 错误定义 ============

    error EscrowNotFound(uint256 escrowId);
    error EscrowNotActive(uint256 escrowId);
    error EscrowAlreadySettled(uint256 escrowId);
    error InvalidAmount(uint256 amount);
    error UnsupportedToken(address token);
    error UnauthorizedCaller(address caller);
    error SettlementNotFound(uint256 auctionId);
    error SettlementAlreadyExecuted(uint256 auctionId);
    error InsufficientBalance(uint256 required, uint256 available);
    error TransferFailed();
    error InvalidTimeout(uint256 timeout);

    // ============ 修饰符 ============

    /**
     * @dev 仅拍卖管理器可调用
     */
    modifier onlyAuctionManager() {
        if (msg.sender != auctionManager) {
            revert UnauthorizedCaller(msg.sender);
        }
        _;
    }

    /**
     * @dev 仅消息传递合约可调用
     */
    modifier onlyMessenger() {
        if (msg.sender != address(messenger)) {
            revert UnauthorizedCaller(msg.sender);
        }
        _;
    }

    /**
     * @dev 检查托管是否存在
     * @param escrowId 托管ID
     */
    modifier escrowExists(uint256 escrowId) {
        if (escrowId == 0 || escrowId > escrowCounter) {
            revert EscrowNotFound(escrowId);
        }
        _;
    }

    // ============ 构造函数 ============

    /**
     * @dev 构造函数
     * @param _messenger 跨链消息传递合约地址
     * @param _priceOracle 价格预言机合约地址
     */
    constructor(
        address _messenger,
        address _priceOracle
    ) Ownable(msg.sender) {
        require(_messenger != address(0), "Invalid messenger");
        require(_priceOracle != address(0), "Invalid price oracle");
        
        messenger = CrossChainMessenger(_messenger);
        priceOracle = IPriceOracle(_priceOracle);
    }

    // ============ 外部函数 ============

    /**
     * @dev 托管出价资金
     * @param auctionId 拍卖ID
     * @param amount 出价金额
     * @param token 代币地址（address(0)表示ETH）
     * @param targetChainId 目标链ID
     * @return escrowId 托管ID
     */
    function escrowBid(
        uint256 auctionId,
        uint256 amount,
        address token,
        uint64 targetChainId
    ) external payable nonReentrant whenNotPaused returns (uint256 escrowId) {
        // 验证参数
        if (amount == 0) revert InvalidAmount(amount);
        if (!supportedTokens[token] && token != address(0)) {
            revert UnsupportedToken(token);
        }
        
        // 处理资金转移
        if (token == address(0)) {
            // ETH出价
            require(msg.value == amount, "Incorrect ETH amount");
        } else {
            // ERC20出价
            require(msg.value == 0, "No ETH required for ERC20");
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        }
        
        // 创建托管
        escrowId = ++escrowCounter;
        EscrowInfo storage escrow = escrows[escrowId];
        
        escrow.bidder = msg.sender;
        escrow.amount = amount;
        escrow.token = token;
        escrow.auctionId = auctionId;
        escrow.targetChainId = targetChainId;
        escrow.timestamp = block.timestamp;
        escrow.isActive = true;
        escrow.isSettled = false;
        
        // 更新映射
        userEscrows[msg.sender].push(escrowId);
        auctionEscrows[auctionId].push(escrowId);
        
        emit BidEscrowed(escrowId, auctionId, msg.sender, amount, token, targetChainId);
    }

    /**
     * @dev 释放托管资金（用于非获胜出价）
     * @param escrowId 托管ID
     */
    function releaseBid(uint256 escrowId) external escrowExists(escrowId) nonReentrant {
        EscrowInfo storage escrow = escrows[escrowId];
        
        // 验证权限
        require(
            msg.sender == escrow.bidder || 
            msg.sender == auctionManager || 
            msg.sender == owner(),
            "Unauthorized"
        );
        
        if (!escrow.isActive) revert EscrowNotActive(escrowId);
        if (escrow.isSettled) revert EscrowAlreadySettled(escrowId);
        
        // 标记为已结算
        escrow.isActive = false;
        escrow.isSettled = true;
        
        // 退还资金
        _transferFunds(escrow.bidder, escrow.amount, escrow.token);
        
        emit BidReleased(escrowId, escrow.bidder, escrow.amount, escrow.token);
    }

    /**
     * @dev 批量释放托管资金
     * @param escrowIds 托管ID数组
     */
    function batchReleaseBids(uint256[] calldata escrowIds) external nonReentrant {
        for (uint256 i = 0; i < escrowIds.length; i++) {
            uint256 escrowId = escrowIds[i];
            if (escrowId > 0 && escrowId <= escrowCounter) {
                EscrowInfo storage escrow = escrows[escrowId];
                
                if (escrow.isActive && !escrow.isSettled && 
                    (msg.sender == escrow.bidder || msg.sender == auctionManager || msg.sender == owner())) {
                    
                    escrow.isActive = false;
                    escrow.isSettled = true;
                    
                    _transferFunds(escrow.bidder, escrow.amount, escrow.token);
                    
                    emit BidReleased(escrowId, escrow.bidder, escrow.amount, escrow.token);
                }
            }
        }
    }

    /**
     * @dev 初始化结算（由拍卖管理器调用）
     * @param auctionId 拍卖ID
     * @param winner 获胜者地址
     * @param winningAmount 获胜金额
     * @param winningToken 获胜代币
     * @param escrowId 获胜出价的托管ID
     */
    function initiateSettlement(
        uint256 auctionId,
        address winner,
        uint256 winningAmount,
        address winningToken,
        uint256 escrowId
    ) external onlyAuctionManager {
        require(settlements[auctionId].auctionId == 0, "Settlement already exists");
        
        SettlementInfo storage settlement = settlements[auctionId];
        settlement.auctionId = auctionId;
        settlement.winner = winner;
        settlement.winningAmount = winningAmount;
        settlement.winningToken = winningToken;
        settlement.escrowId = escrowId;
        settlement.timestamp = block.timestamp;
        settlement.isExecuted = false;
        
        emit SettlementInitiated(auctionId, winner, winningAmount, escrowId);
    }

    /**
     * @dev 执行结算
     * @param auctionId 拍卖ID
     * @param seller 卖家地址
     * @param platformFee 平台手续费
     * @param feeRecipient 手续费接收地址
     */
    function executeSettlement(
        uint256 auctionId,
        address seller,
        uint256 platformFee,
        address feeRecipient
    ) external onlyAuctionManager nonReentrant {
        SettlementInfo storage settlement = settlements[auctionId];
        
        if (settlement.auctionId == 0) revert SettlementNotFound(auctionId);
        if (settlement.isExecuted) revert SettlementAlreadyExecuted(auctionId);
        
        // 验证托管
        EscrowInfo storage escrow = escrows[settlement.escrowId];
        require(escrow.isActive && !escrow.isSettled, "Invalid escrow state");
        require(escrow.amount >= settlement.winningAmount, "Insufficient escrow amount");
        
        // 标记为已执行
        settlement.isExecuted = true;
        escrow.isActive = false;
        escrow.isSettled = true;
        
        // 计算分配金额
        uint256 sellerAmount = settlement.winningAmount - platformFee;
        
        // 转移资金
        if (platformFee > 0) {
            _transferFunds(feeRecipient, platformFee, settlement.winningToken);
        }
        _transferFunds(seller, sellerAmount, settlement.winningToken);
        
        // 如果托管金额大于获胜金额，退还差额给出价者
        if (escrow.amount > settlement.winningAmount) {
            uint256 refundAmount = escrow.amount - settlement.winningAmount;
            _transferFunds(settlement.winner, refundAmount, settlement.winningToken);
        }
        
        emit SettlementExecuted(auctionId, settlement.winner, settlement.winningAmount, settlement.winningToken);
    }

    /**
     * @dev 处理退款（超时或拍卖取消）
     * @param auctionId 拍卖ID
     */
    function processRefunds(uint256 auctionId) external nonReentrant {
        uint256[] memory escrowIds = auctionEscrows[auctionId];
        
        for (uint256 i = 0; i < escrowIds.length; i++) {
            uint256 escrowId = escrowIds[i];
            EscrowInfo storage escrow = escrows[escrowId];
            
            if (escrow.isActive && !escrow.isSettled) {
                // 检查是否超时或有权限
                bool canRefundNow = block.timestamp > escrow.timestamp + settlementTimeout ||
                                 msg.sender == auctionManager ||
                                 msg.sender == owner();
                 
                 if (canRefundNow) {
                    escrow.isActive = false;
                    escrow.isSettled = true;
                    
                    _transferFunds(escrow.bidder, escrow.amount, escrow.token);
                    
                    emit RefundProcessed(escrowId, escrow.bidder, escrow.amount, escrow.token);
                }
            }
        }
    }

    /**
     * @dev 紧急提取（仅所有者）
     * @param token 代币地址（address(0)表示ETH）
     * @param amount 提取金额
     * @param to 接收地址
     */
    function emergencyWithdraw(
        address token,
        uint256 amount,
        address to
    ) external onlyOwner {
        require(to != address(0), "Invalid recipient");
        _transferFunds(to, amount, token);
    }

    /**
     * @dev 设置拍卖管理器
     * @param _auctionManager 拍卖管理器地址
     */
    function setAuctionManager(address _auctionManager) external onlyOwner {
        require(_auctionManager != address(0), "Invalid auction manager");
        auctionManager = _auctionManager;
    }

    /**
     * @dev 设置价格预言机
     * @param _priceOracle 价格预言机地址
     */
    function setPriceOracle(address _priceOracle) external onlyOwner {
        require(_priceOracle != address(0), "Invalid price oracle");
        priceOracle = IPriceOracle(_priceOracle);
    }

    /**
     * @dev 设置支持的代币
     * @param token 代币地址
     * @param supported 是否支持
     */
    function setSupportedToken(address token, bool supported) external onlyOwner {
        supportedTokens[token] = supported;
    }

    /**
     * @dev 设置结算超时时间
     * @param _timeout 超时时间（秒）
     */
    function setSettlementTimeout(uint256 _timeout) external onlyOwner {
        if (_timeout < MIN_ESCROW_DURATION || _timeout > MAX_ESCROW_DURATION) {
            revert InvalidTimeout(_timeout);
        }
        settlementTimeout = _timeout;
    }

    /**
     * @dev 暂停合约
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev 恢复合约
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // ============ 内部函数 ============

    /**
     * @dev 转移资金
     * @param to 接收地址
     * @param amount 金额
     * @param token 代币地址（address(0)表示ETH）
     */
    function _transferFunds(address to, uint256 amount, address token) internal {
        if (amount == 0) return;
        
        if (token == address(0)) {
            // ETH转移
            (bool success, ) = payable(to).call{value: amount}("");
            if (!success) revert TransferFailed();
        } else {
            // ERC20转移
            IERC20(token).safeTransfer(to, amount);
        }
    }

    // ============ 视图函数 ============

    /**
     * @dev 获取托管信息
     * @param escrowId 托管ID
     * @return 托管信息
     */
    function getEscrowInfo(uint256 escrowId) external view escrowExists(escrowId) returns (EscrowInfo memory) {
        return escrows[escrowId];
    }

    /**
     * @dev 获取用户的所有托管
     * @param user 用户地址
     * @return 托管ID数组
     */
    function getUserEscrows(address user) external view returns (uint256[] memory) {
        return userEscrows[user];
    }

    /**
     * @dev 获取拍卖的所有托管
     * @param auctionId 拍卖ID
     * @return 托管ID数组
     */
    function getAuctionEscrows(uint256 auctionId) external view returns (uint256[] memory) {
        return auctionEscrows[auctionId];
    }

    /**
     * @dev 获取结算信息
     * @param auctionId 拍卖ID
     * @return 结算信息
     */
    function getSettlementInfo(uint256 auctionId) external view returns (SettlementInfo memory) {
        return settlements[auctionId];
    }

    /**
     * @dev 获取合约余额
     * @param token 代币地址（address(0)表示ETH）
     * @return 余额
     */
    function getBalance(address token) external view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }

    /**
     * @dev 检查托管是否可以退款
     * @param escrowId 托管ID
     * @return 是否可以退款
     */
    function canRefund(uint256 escrowId) external view escrowExists(escrowId) returns (bool) {
        EscrowInfo storage escrow = escrows[escrowId];
        return escrow.isActive && 
               !escrow.isSettled && 
               block.timestamp > escrow.timestamp + settlementTimeout;
    }

    // ============ 接收ETH ============

    /**
     * @dev 接收ETH
     */
    receive() external payable {
        // 允许接收ETH用于托管
    }
}
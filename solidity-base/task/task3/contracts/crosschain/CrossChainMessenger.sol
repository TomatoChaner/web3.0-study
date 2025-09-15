// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IRouterClient} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/contracts/applications/CCIPReceiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./ICrossChainAuction.sol";

/**
 * @title CrossChainMessenger
 * @dev Chainlink CCIP集成合约，负责跨链消息的发送和接收
 * @notice 实现跨链拍卖系统的消息传递功能
 */
contract CrossChainMessenger is CCIPReceiver, Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // ============ 状态变量 ============

    /// @dev CCIP路由器接口
    IRouterClient private immutable i_router;
    
    /// @dev LINK代币地址
    IERC20 private immutable i_linkToken;
    
    /// @dev 跨链拍卖合约地址
    address public auctionContract;
    
    /// @dev 支持的链配置
    mapping(uint64 => ICrossChainAuction.ChainConfig) public chainConfigs;
    
    /// @dev 已发送的消息记录
    mapping(bytes32 => bool) public sentMessages;
    
    /// @dev 已接收的消息记录
    mapping(bytes32 => bool) public receivedMessages;
    
    /// @dev 消息重试计数
    mapping(bytes32 => uint256) public messageRetryCount;
    
    /// @dev 最大重试次数
    uint256 public constant MAX_RETRY_COUNT = 3;
    
    /// @dev Gas限制
    uint256 public defaultGasLimit = 200000;

    // ============ 事件定义 ============

    /**
     * @dev 消息发送事件
     * @param messageId CCIP消息ID
     * @param destinationChainSelector 目标链选择器
     * @param receiver 接收者地址
     * @param data 消息数据
     * @param feeToken 手续费代币
     * @param fees 手续费金额
     */
    event MessageSent(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        bytes data,
        address feeToken,
        uint256 fees
    );

    /**
     * @dev 消息接收事件
     * @param messageId CCIP消息ID
     * @param sourceChainSelector 源链选择器
     * @param sender 发送者地址
     * @param data 消息数据
     */
    event MessageReceived(
        bytes32 indexed messageId,
        uint64 indexed sourceChainSelector,
        address sender,
        bytes data
    );

    /**
     * @dev 链配置更新事件
     * @param chainId 链ID
     * @param config 链配置
     */
    event ChainConfigUpdated(uint64 indexed chainId, ICrossChainAuction.ChainConfig config);

    /**
     * @dev 拍卖合约更新事件
     * @param oldContract 旧合约地址
     * @param newContract 新合约地址
     */
    event AuctionContractUpdated(address indexed oldContract, address indexed newContract);

    // ============ 错误定义 ============

    error UnsupportedChain(uint64 chainId);
    error InvalidAuctionContract();
    error MessageAlreadyReceived(bytes32 messageId);
    error InsufficientBalance(uint256 required, uint256 available);
    error MaxRetryExceeded(bytes32 messageId);
    error InvalidMessageData();

    // ============ 修饰符 ============

    /**
     * @dev 仅拍卖合约可调用
     */
    modifier onlyAuctionContract() {
        require(msg.sender == auctionContract, "Only auction contract");
        _;
    }

    /**
     * @dev 检查链是否支持
     * @param chainId 链ID
     */
    modifier onlySupportedChain(uint64 chainId) {
        if (!chainConfigs[chainId].isSupported) {
            revert UnsupportedChain(chainId);
        }
        _;
    }

    // ============ 构造函数 ============

    /**
     * @dev 构造函数
     * @param router CCIP路由器地址
     * @param linkToken LINK代币地址
     * @param owner 合约所有者地址
     */
    constructor(address router, address linkToken, address owner) CCIPReceiver(router) Ownable(owner) {
        i_router = IRouterClient(router);
        i_linkToken = IERC20(linkToken);
    }

    // ============ 外部函数 ============

    /**
     * @dev 设置拍卖合约地址
     * @param _auctionContract 拍卖合约地址
     */
    function setAuctionContract(address _auctionContract) external onlyOwner {
        require(_auctionContract != address(0), "Invalid auction contract");
        address oldContract = auctionContract;
        auctionContract = _auctionContract;
        emit AuctionContractUpdated(oldContract, _auctionContract);
    }

    /**
     * @dev 添加或更新链配置
     * @param chainId 链ID
     * @param config 链配置
     */
    function setChainConfig(
        uint64 chainId,
        ICrossChainAuction.ChainConfig memory config
    ) external onlyOwner {
        require(config.chainId == chainId, "Chain ID mismatch");
        require(config.ccipRouter != address(0), "Invalid CCIP router");
        require(config.auctionContract != address(0), "Invalid auction contract");
        
        chainConfigs[chainId] = config;
        emit ChainConfigUpdated(chainId, config);
    }

    /**
     * @dev 移除链配置
     * @param chainId 链ID
     */
    function removeChainConfig(uint64 chainId) external onlyOwner {
        delete chainConfigs[chainId];
        emit ChainConfigUpdated(chainId, ICrossChainAuction.ChainConfig({
            chainId: 0,
            ccipRouter: address(0),
            linkToken: address(0),
            auctionContract: address(0),
            isSupported: false,
            gasLimit: 0,
            extraArgs: ""
        }));
    }

    /**
     * @dev 发送跨链消息
     * @param destinationChainId 目标链ID
     * @param message 跨链消息
     * @return messageId CCIP消息ID
     */
    function sendMessage(
        uint64 destinationChainId,
        ICrossChainAuction.CrossChainMessage memory message
    ) external onlyAuctionContract onlySupportedChain(destinationChainId) nonReentrant whenNotPaused returns (bytes32 messageId) {
        ICrossChainAuction.ChainConfig memory config = chainConfigs[destinationChainId];
        
        // 编码消息数据
        bytes memory encodedMessage = abi.encode(message);
        
        // 构建CCIP消息
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(config.auctionContract),
            data: encodedMessage,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: config.extraArgs,
            feeToken: address(i_linkToken)
        });
        
        // 计算手续费
        uint256 fees = i_router.getFee(destinationChainId, evm2AnyMessage);
        
        // 检查LINK余额
        uint256 linkBalance = i_linkToken.balanceOf(address(this));
        if (fees > linkBalance) {
            revert InsufficientBalance(fees, linkBalance);
        }
        
        // 批准LINK代币
        i_linkToken.approve(address(i_router), fees);
        
        // 发送消息
        messageId = i_router.ccipSend(destinationChainId, evm2AnyMessage);
        
        // 记录已发送消息
        sentMessages[messageId] = true;
        
        emit MessageSent(
            messageId,
            destinationChainId,
            config.auctionContract,
            encodedMessage,
            address(i_linkToken),
            fees
        );
    }

    /**
     * @dev 设置默认Gas限制
     * @param gasLimit Gas限制
     */
    function setDefaultGasLimit(uint256 gasLimit) external onlyOwner {
        require(gasLimit > 0, "Invalid gas limit");
        defaultGasLimit = gasLimit;
    }

    /**
     * @dev 提取LINK代币
     * @param to 接收地址
     * @param amount 提取金额
     */
    function withdrawLink(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid recipient");
        i_linkToken.safeTransfer(to, amount);
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
     * @dev 处理接收到的CCIP消息
     * @param any2EvmMessage CCIP消息
     */
    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override whenNotPaused {
        bytes32 messageId = any2EvmMessage.messageId;
        
        // 检查消息是否已处理
        if (receivedMessages[messageId]) {
            revert MessageAlreadyReceived(messageId);
        }
        
        // 解码消息
        try this.decodeMessage(any2EvmMessage.data) returns (
            ICrossChainAuction.CrossChainMessage memory message
        ) {
            // 验证消息来源
            require(
                chainConfigs[any2EvmMessage.sourceChainSelector].isSupported,
                "Unsupported source chain"
            );
            
            // 标记消息已接收
            receivedMessages[messageId] = true;
            
            // 处理消息
            _processMessage(message, any2EvmMessage.sourceChainSelector);
            
            emit MessageReceived(
                messageId,
                any2EvmMessage.sourceChainSelector,
                abi.decode(any2EvmMessage.sender, (address)),
                any2EvmMessage.data
            );
        } catch {
            // 增加重试计数
            messageRetryCount[messageId]++;
            
            if (messageRetryCount[messageId] >= MAX_RETRY_COUNT) {
                revert MaxRetryExceeded(messageId);
            }
            
            revert InvalidMessageData();
        }
    }

    /**
     * @dev 解码消息（外部可见以支持try-catch）
     * @param data 消息数据
     * @return message 解码后的消息
     */
    function decodeMessage(
        bytes calldata data
    ) external pure returns (ICrossChainAuction.CrossChainMessage memory message) {
        return abi.decode(data, (ICrossChainAuction.CrossChainMessage));
    }

    /**
     * @dev 处理跨链消息
     * @param message 跨链消息
     * @param sourceChainId 源链ID
     */
    function _processMessage(
        ICrossChainAuction.CrossChainMessage memory message,
        uint64 sourceChainId
    ) internal {
        // 调用拍卖合约处理消息
        (bool success, ) = auctionContract.call(
            abi.encodeWithSignature(
                "processCrossChainMessage((uint8,uint256,address,bytes,uint64,uint64,uint256),uint64)",
                message,
                sourceChainId
            )
        );
        
        require(success, "Failed to process message");
    }

    // ============ 视图函数 ============

    /**
     * @dev 获取路由器地址
     * @return 路由器地址
     */
    function getRouter() public view override returns (address) {
        return address(i_router);
    }

    /**
     * @dev 获取LINK代币地址
     * @return LINK代币地址
     */
    function getLinkToken() external view returns (address) {
        return address(i_linkToken);
    }

    /**
     * @dev 检查链是否支持
     * @param chainId 链ID
     * @return 是否支持
     */
    function isChainSupported(uint64 chainId) external view returns (bool) {
        return chainConfigs[chainId].isSupported;
    }

    /**
     * @dev 获取链配置
     * @param chainId 链ID
     * @return 链配置
     */
    function getChainConfig(uint64 chainId) external view returns (ICrossChainAuction.ChainConfig memory) {
        return chainConfigs[chainId];
    }

    /**
     * @dev 估算跨链消息费用
     * @param destinationChainId 目标链ID
     * @param message 跨链消息
     * @return 费用金额
     */
    function estimateMessageFee(
        uint64 destinationChainId,
        ICrossChainAuction.CrossChainMessage memory message
    ) external view onlySupportedChain(destinationChainId) returns (uint256) {
        ICrossChainAuction.ChainConfig memory config = chainConfigs[destinationChainId];
        
        bytes memory encodedMessage = abi.encode(message);
        
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(config.auctionContract),
            data: encodedMessage,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: config.extraArgs,
            feeToken: address(i_linkToken)
        });
        
        return i_router.getFee(destinationChainId, evm2AnyMessage);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ICrossChainAuction
 * @dev 跨链拍卖接口定义
 * @notice 定义跨链拍卖系统的核心接口和数据结构
 */
interface ICrossChainAuction {
    /**
     * @dev 跨链消息类型枚举
     */
    enum MessageType {
        BID,           // 出价消息
        AUCTION_END,   // 拍卖结束消息
        NFT_TRANSFER,  // NFT转移消息
        REFUND         // 退款消息
    }

    /**
     * @dev 跨链拍卖状态枚举
     */
    enum CrossChainAuctionStatus {
        ACTIVE,        // 活跃状态
        ENDED,         // 已结束
        SETTLED,       // 已结算
        CANCELLED      // 已取消
    }

    /**
     * @dev 跨链出价信息结构体
     */
    struct CrossChainBid {
        address bidder;           // 出价者地址
        uint256 amount;           // 出价金额（以USD计价）
        address token;            // 出价代币地址
        uint256 originalAmount;   // 原始出价金额
        uint64 sourceChainId;     // 源链ID
        uint256 timestamp;        // 出价时间戳
        bool isValid;             // 出价是否有效
    }

    /**
     * @dev 跨链拍卖信息结构体
     */
    struct CrossChainAuctionInfo {
        uint256 auctionId;                    // 拍卖ID
        address nftContract;                  // NFT合约地址
        uint256 tokenId;                      // NFT代币ID
        address seller;                       // 卖家地址
        uint256 startingPrice;                // 起始价格（USD）
        uint256 endTime;                      // 结束时间
        uint64 originChainId;                 // 原始链ID
        CrossChainAuctionStatus status;       // 拍卖状态
        CrossChainBid highestBid;             // 最高出价
        uint256 totalBids;                    // 总出价数量
        mapping(uint64 => bool) supportedChains; // 支持的链
    }

    /**
     * @dev 跨链消息结构体
     */
    struct CrossChainMessage {
        MessageType messageType;    // 消息类型
        uint256 auctionId;         // 拍卖ID
        address sender;            // 发送者地址
        bytes data;                // 消息数据
        uint64 sourceChainId;      // 源链ID
        uint64 destinationChainId; // 目标链ID
        uint256 timestamp;         // 时间戳
    }

    /**
     * @dev 链配置信息结构体
     */
    struct ChainConfig {
        uint64 chainId;              // 链ID
        address ccipRouter;          // CCIP路由器地址
        address linkToken;           // LINK代币地址
        address auctionContract;     // 拍卖合约地址
        bool isSupported;            // 是否支持
        uint256 gasLimit;            // Gas限制
        bytes extraArgs;             // 额外参数
    }

    // ============ 事件定义 ============

    /**
     * @dev 跨链出价事件
     * @param auctionId 拍卖ID
     * @param bidder 出价者地址
     * @param amount 出价金额（USD）
     * @param sourceChainId 源链ID
     * @param messageId CCIP消息ID
     */
    event CrossChainBidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 amount,
        uint64 sourceChainId,
        bytes32 messageId
    );

    /**
     * @dev 跨链拍卖创建事件
     * @param auctionId 拍卖ID
     * @param nftContract NFT合约地址
     * @param tokenId NFT代币ID
     * @param seller 卖家地址
     * @param startingPrice 起始价格
     * @param endTime 结束时间
     * @param supportedChains 支持的链ID数组
     */
    event CrossChainAuctionCreated(
        uint256 indexed auctionId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        uint256 startingPrice,
        uint256 endTime,
        uint64[] supportedChains
    );

    /**
     * @dev 跨链拍卖结束事件
     * @param auctionId 拍卖ID
     * @param winner 获胜者地址
     * @param winningAmount 获胜金额
     * @param winnerChainId 获胜者链ID
     */
    event CrossChainAuctionEnded(
        uint256 indexed auctionId,
        address indexed winner,
        uint256 winningAmount,
        uint64 winnerChainId
    );

    /**
     * @dev 跨链消息发送事件
     * @param messageId CCIP消息ID
     * @param destinationChainId 目标链ID
     * @param messageType 消息类型
     * @param auctionId 拍卖ID
     */
    event CrossChainMessageSent(
        bytes32 indexed messageId,
        uint64 indexed destinationChainId,
        MessageType messageType,
        uint256 auctionId
    );

    /**
     * @dev 跨链消息接收事件
     * @param messageId CCIP消息ID
     * @param sourceChainId 源链ID
     * @param messageType 消息类型
     * @param auctionId 拍卖ID
     */
    event CrossChainMessageReceived(
        bytes32 indexed messageId,
        uint64 indexed sourceChainId,
        MessageType messageType,
        uint256 auctionId
    );

    // ============ 函数接口 ============

    /**
     * @dev 创建跨链拍卖
     * @param nftContract NFT合约地址
     * @param tokenId NFT代币ID
     * @param startingPrice 起始价格（USD）
     * @param duration 拍卖持续时间（秒）
     * @param supportedChains 支持的链ID数组
     * @return auctionId 拍卖ID
     */
    function createCrossChainAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startingPrice,
        uint256 duration,
        uint64[] calldata supportedChains
    ) external returns (uint256 auctionId);

    /**
     * @dev 发送跨链出价
     * @param auctionId 拍卖ID
     * @param amount 出价金额
     * @param token 出价代币地址
     * @param destinationChainId 目标链ID
     * @return messageId CCIP消息ID
     */
    function sendCrossChainBid(
        uint256 auctionId,
        uint256 amount,
        address token,
        uint64 destinationChainId
    ) external payable returns (bytes32 messageId);

    /**
     * @dev 结束跨链拍卖
     * @param auctionId 拍卖ID
     */
    function endCrossChainAuction(uint256 auctionId) external;

    /**
     * @dev 获取跨链拍卖信息
     * @param auctionId 拍卖ID
     * @return 拍卖信息（不包含mapping字段）
     */
    function getCrossChainAuctionInfo(uint256 auctionId) external view returns (
        uint256,
        address,
        uint256,
        address,
        uint256,
        uint256,
        uint64,
        CrossChainAuctionStatus,
        CrossChainBid memory,
        uint256
    );

    /**
     * @dev 检查链是否支持
     * @param auctionId 拍卖ID
     * @param chainId 链ID
     * @return 是否支持
     */
    function isChainSupported(uint256 auctionId, uint64 chainId) external view returns (bool);

    /**
     * @dev 获取链配置信息
     * @param chainId 链ID
     * @return 链配置信息
     */
    function getChainConfig(uint64 chainId) external view returns (ChainConfig memory);
}
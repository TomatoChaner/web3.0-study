// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IAuction
 * @dev 拍卖功能接口
 * @notice 定义核心拍卖操作和事件
 */
interface IAuction {
    /**
     * @dev 拍卖状态枚举
     */
    enum AuctionStatus {
        Active,     // 拍卖进行中
        Ended,      // 拍卖已结束
        Cancelled   // 拍卖已取消
    }

    /**
     * @dev 拍卖信息结构体
     */
    struct AuctionInfo {
        uint256 tokenId;        // NFT代币ID
        address nftContract;    // NFT合约地址
        address seller;         // 卖家地址
        uint256 startPrice;     // 起始价格
        uint256 reservePrice;   // 保留价格（最低可接受价格）
        uint256 currentBid;     // 当前最高出价
        address currentBidder;  // 当前最高出价者
        uint256 startTime;      // 拍卖开始时间
        uint256 endTime;        // 拍卖结束时间
        AuctionStatus status;   // 拍卖状态
        bool settled;           // 是否已结算
    }

    /**
     * @dev 创建新拍卖时触发的事件
     */
    event AuctionCreated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed nftContract,
        address seller,
        uint256 startPrice,
        uint256 reservePrice,
        uint256 startTime,
        uint256 endTime
    );

    /**
     * @dev 出价时触发的事件
     */
    event BidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @dev 拍卖结算时触发的事件
     */
    event AuctionSettled(
        uint256 indexed auctionId,
        address indexed winner,
        uint256 winningBid,
        uint256 timestamp
    );

    /**
     * @dev 拍卖取消时触发的事件
     */
    event AuctionCancelled(
        uint256 indexed auctionId,
        uint256 timestamp
    );

    /**
     * @dev 创建新拍卖
     * @param tokenId 要拍卖的NFT代币ID
     * @param nftContract NFT合约地址
     * @param startPrice 拍卖起始价格
     * @param reservePrice 最低可接受价格
     * @param duration 拍卖持续时间（秒）
     * @return auctionId 创建的拍卖ID
     */
    function createAuction(
        uint256 tokenId,
        address nftContract,
        uint256 startPrice,
        uint256 reservePrice,
        uint256 duration
    ) external returns (uint256 auctionId);

    /**
     * @dev 对拍卖进行出价
     * @param auctionId 要出价的拍卖ID
     */
    function placeBid(uint256 auctionId) external payable;

    /**
     * @dev 拍卖结束后进行结算
     * @param auctionId 要结算的拍卖ID
     */
    function settleAuction(uint256 auctionId) external;

    /**
     * @dev 取消拍卖（仅限卖家在首次出价前）
     * @param auctionId 要取消的拍卖ID
     */
    function cancelAuction(uint256 auctionId) external;

    /**
     * @dev 如果在接近结束时出价则延长拍卖时间
     * @param auctionId 拍卖ID
     * @param extensionTime 额外延长时间（秒）
     */
    function extendAuction(uint256 auctionId, uint256 extensionTime) external;

    /**
     * @dev 返回拍卖信息
     * @param auctionId 拍卖ID
     * @return 拍卖信息结构体
     */
    function getAuction(uint256 auctionId) external view returns (AuctionInfo memory);

    /**
     * @dev 返回拍卖的当前最高出价
     * @param auctionId 拍卖ID
     * @return bidder 当前最高出价者
     * @return amount 当前最高出价金额
     */
    function getCurrentBid(uint256 auctionId) external view returns (address bidder, uint256 amount);

    /**
     * @dev 检查拍卖是否处于活跃状态
     * @param auctionId 拍卖ID
     * @return 如果拍卖处于活跃状态则返回true
     */
    function isAuctionActive(uint256 auctionId) external view returns (bool);

    /**
     * @dev 返回最小出价增量
     * @return 最小出价增量百分比（基点）
     */
    function getMinBidIncrement() external view returns (uint256);

    /**
     * @dev 返回拍卖延长时间
     * @return 在接近结束时出价时添加的时间（秒）
     */
    function getAuctionExtensionTime() external view returns (uint256);
}
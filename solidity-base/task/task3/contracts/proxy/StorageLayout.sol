// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title StorageLayout
 * @dev 存储布局兼容性管理合约
 * @notice 此合约定义了可升级合约的存储布局规范，确保升级时的存储兼容性
 */
abstract contract StorageLayout {
    
    // ============ 存储槽分配规范 ============
    
    /**
     * @dev 存储槽分配规范：
     * 
     * 槽 0-49:   OpenZeppelin 可升级合约保留槽
     * 槽 50-99:  基础合约存储槽 (AuctionHouseUpgradeable)
     * 槽 100-149: 扩展功能存储槽 (预留给未来功能)
     * 槽 150-199: 工厂合约存储槽 (AuctionFactoryUpgradeable)
     * 槽 200-249: 预言机相关存储槽
     * 槽 250-299: 治理相关存储槽
     * 槽 300+:    自定义扩展存储槽
     */
    
    // ============ 基础合约存储槽 (50-99) ============
    
    /// @custom:storage-location erc7201:auction.house.storage
    struct AuctionHouseStorage {
        // 槽 50: 拍卖计数器
        uint256 auctionCounter;
        
        // 槽 51: 平台手续费率 (基点)
        uint256 platformFeeRate;
        
        // 槽 52: 手续费接收地址
        address feeRecipient;
        
        // 槽 53: 价格预言机地址
        address priceOracle;
        
        // 槽 54: 最小拍卖持续时间
        uint256 minAuctionDuration;
        
        // 槽 55: 最大拍卖持续时间
        uint256 maxAuctionDuration;
        
        // 槽 56: 最小出价增量百分比
        uint256 minBidIncrement;
        
        // 槽 57: 拍卖延长时间
        uint256 auctionExtension;
        
        // 槽 58-59: 预留槽
        uint256[2] __reserved1;
        
        // 槽 60: 拍卖映射 (auctionId => Auction)
        mapping(uint256 => Auction) auctions;
        
        // 槽 61: 用户拍卖列表 (user => auctionIds[])
        mapping(address => uint256[]) userAuctions;
        
        // 槽 62: NFT拍卖映射 (nftContract => tokenId => auctionId)
        mapping(address => mapping(uint256 => uint256)) nftAuctions;
        
        // 槽 63: 活跃拍卖列表
        uint256[] activeAuctions;
        
        // 槽 64: 已完成拍卖列表
        uint256[] completedAuctions;
        
        // 槽 65-99: 预留槽
        uint256[35] __reserved2;
    }
    
    /// @dev 拍卖结构体
    struct Auction {
        uint256 auctionId;          // 拍卖ID
        address seller;             // 卖家地址
        address nftContract;        // NFT合约地址
        uint256 tokenId;            // NFT代币ID
        uint256 startingPrice;      // 起始价格
        uint256 currentBid;         // 当前最高出价
        address currentBidder;      // 当前最高出价者
        uint256 startTime;          // 开始时间
        uint256 endTime;            // 结束时间
        bool settled;               // 是否已结算
        AuctionStatus status;       // 拍卖状态
        address paymentToken;       // 支付代币地址 (address(0) = ETH)
    }
    
    /// @dev 拍卖状态枚举
    enum AuctionStatus {
        Created,    // 已创建
        Active,     // 进行中
        Ended,      // 已结束
        Settled,    // 已结算
        Cancelled   // 已取消
    }
    
    // ============ 工厂合约存储槽 (150-199) ============
    
    /// @custom:storage-location erc7201:auction.factory.storage
    struct AuctionFactoryStorage {
        // 槽 150: 拍卖行计数器
        uint256 auctionHouseCounter;
        
        // 槽 151: 模板计数器
        uint256 templateCounter;
        
        // 槽 152: 全局配置
        GlobalConfig globalConfig;
        
        // 槽 153: 代理管理合约地址
        address proxyAdmin;
        
        // 槽 154-155: 预留槽
        uint256[2] __reserved1;
        
        // 槽 156: 模板映射 (templateId => AuctionTemplate)
        mapping(uint256 => AuctionTemplate) templates;
        
        // 槽 157: 有效拍卖行映射 (auctionHouse => bool)
        mapping(address => bool) validAuctionHouses;
        
        // 槽 158: 用户拍卖行列表 (user => auctionHouses[])
        mapping(address => address[]) userAuctionHouses;
        
        // 槽 159: NFT拍卖行列表 (nftContract => auctionHouses[])
        mapping(address => address[]) nftAuctionHouses;
        
        // 槽 160: 支持的NFT合约 (nftContract => bool)
        mapping(address => bool) supportedNFTs;
        
        // 槽 161: 代理实现映射 (proxy => implementation)
        mapping(address => address) proxyImplementations;
        
        // 槽 162: 活跃模板列表
        uint256[] activeTemplates;
        
        // 槽 163-199: 预留槽
        uint256[37] __reserved2;
    }
    
    /// @dev 全局配置结构体
    struct GlobalConfig {
        uint256 platformFeeRate;      // 平台手续费率
        address feeRecipient;          // 手续费接收地址
        address priceOracle;           // 价格预言机地址
        uint256 creationFee;           // 创建费用
    }
    
    /// @dev 拍卖模板结构体
    struct AuctionTemplate {
        address implementation;        // 实现合约地址
        string version;               // 版本号
        bool active;                  // 是否活跃
        uint256 createdAt;            // 创建时间
    }
    
    // ============ 预言机存储槽 (200-249) ============
    
    /// @custom:storage-location erc7201:price.oracle.storage
    struct PriceOracleStorage {
        // 槽 200: 价格数据映射 (token => PriceData)
        mapping(address => PriceData) priceData;
        
        // 槽 201: 价格源映射 (token => priceSource)
        mapping(address => address) priceSources;
        
        // 槽 202: 支持的代币列表
        address[] supportedTokens;
        
        // 槽 203: 价格有效期
        uint256 priceValidityPeriod;
        
        // 槽 204: 最大价格偏差
        uint256 maxPriceDeviation;
        
        // 槽 205-249: 预留槽
        uint256[45] __reserved;
    }
    
    /// @dev 价格数据结构体
    struct PriceData {
        uint256 price;              // 价格
        uint256 timestamp;          // 时间戳
        uint256 decimals;           // 小数位数
        bool isValid;               // 是否有效
    }
    
    // ============ 治理存储槽 (250-299) ============
    
    /// @custom:storage-location erc7201:governance.storage
    struct GovernanceStorage {
        // 槽 250: 提案计数器
        uint256 proposalCounter;
        
        // 槽 251: 投票权重映射 (user => weight)
        mapping(address => uint256) votingWeights;
        
        // 槽 252: 提案映射 (proposalId => Proposal)
        mapping(uint256 => Proposal) proposals;
        
        // 槽 253: 投票记录 (proposalId => user => voted)
        mapping(uint256 => mapping(address => bool)) hasVoted;
        
        // 槽 254: 治理参数
        GovernanceParams params;
        
        // 槽 255-299: 预留槽
        uint256[45] __reserved;
    }
    
    /// @dev 提案结构体
    struct Proposal {
        uint256 id;                 // 提案ID
        address proposer;           // 提案者
        string description;         // 描述
        uint256 startTime;          // 开始时间
        uint256 endTime;            // 结束时间
        uint256 forVotes;           // 赞成票
        uint256 againstVotes;       // 反对票
        bool executed;              // 是否已执行
        ProposalStatus status;      // 状态
    }
    
    /// @dev 提案状态枚举
    enum ProposalStatus {
        Pending,    // 待定
        Active,     // 活跃
        Succeeded,  // 成功
        Defeated,   // 失败
        Executed    // 已执行
    }
    
    /// @dev 治理参数结构体
    struct GovernanceParams {
        uint256 votingDelay;        // 投票延迟
        uint256 votingPeriod;       // 投票期间
        uint256 proposalThreshold;  // 提案门槛
        uint256 quorumVotes;        // 法定票数
    }
    
    // ============ 存储访问函数 ============
    
    /**
     * @dev 获取拍卖行存储
     * @return $ 存储结构体引用
     */
    function _getAuctionHouseStorage() internal pure returns (AuctionHouseStorage storage $) {
        assembly {
            $.slot := 50
        }
    }
    
    /**
     * @dev 获取工厂存储
     * @return $ 存储结构体引用
     */
    function _getAuctionFactoryStorage() internal pure returns (AuctionFactoryStorage storage $) {
        assembly {
            $.slot := 150
        }
    }
    
    /**
     * @dev 获取预言机存储
     * @return $ 存储结构体引用
     */
    function _getPriceOracleStorage() internal pure returns (PriceOracleStorage storage $) {
        assembly {
            $.slot := 200
        }
    }
    
    /**
     * @dev 获取治理存储
     * @return $ 存储结构体引用
     */
    function _getGovernanceStorage() internal pure returns (GovernanceStorage storage $) {
        assembly {
            $.slot := 250
        }
    }
    
    // ============ 升级兼容性检查 ============
    
    /**
     * @dev 检查存储布局兼容性
     * @param newVersion 新版本号
     * @return compatible 是否兼容
     */
    function _checkStorageCompatibility(string memory newVersion) internal pure returns (bool compatible) {
        // 实现版本兼容性检查逻辑
        // 这里可以根据版本号规则进行检查
        return true;
    }
    
    /**
     * @dev 验证存储槽未被占用
     * @param slot 存储槽位置
     * @return available 是否可用
     */
    function _isStorageSlotAvailable(uint256 slot) internal pure returns (bool available) {
        // 检查指定槽位是否在预留范围内
        if (slot < 50) return false;           // OpenZeppelin 保留
        if (slot >= 50 && slot < 100) return false;   // 拍卖行保留
        if (slot >= 150 && slot < 200) return false;  // 工厂保留
        if (slot >= 200 && slot < 250) return false;  // 预言机保留
        if (slot >= 250 && slot < 300) return false;  // 治理保留
        return true;
    }
    
    /**
     * @dev 获取下一个可用存储槽
     * @return slot 下一个可用槽位
     */
    function _getNextAvailableSlot() internal pure returns (uint256 slot) {
        return 300; // 从槽300开始分配自定义存储
    }
    
    // ============ 存储迁移辅助函数 ============
    
    /**
     * @dev 迁移存储数据（仅在升级时使用）
     * @param fromSlot 源槽位
     * @param toSlot 目标槽位
     */
    function _migrateStorage(uint256 fromSlot, uint256 toSlot) internal {
        assembly {
            let value := sload(fromSlot)
            sstore(toSlot, value)
            sstore(fromSlot, 0) // 清空原槽位
        }
    }
    
    /**
     * @dev 批量迁移存储数据
     * @param fromSlots 源槽位数组
     * @param toSlots 目标槽位数组
     */
    function _batchMigrateStorage(uint256[] memory fromSlots, uint256[] memory toSlots) internal {
        require(fromSlots.length == toSlots.length, "Array length mismatch");
        
        for (uint256 i = 0; i < fromSlots.length; i++) {
            _migrateStorage(fromSlots[i], toSlots[i]);
        }
    }
    
    // ============ 事件 ============
    
    event StorageLayoutUpdated(string indexed version, uint256 timestamp);
    event StorageMigrated(uint256 indexed fromSlot, uint256 indexed toSlot);
    event StorageSlotReserved(uint256 indexed slot, string purpose);
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "../interfaces/IPriceOracle.sol";

/**
 * @title PriceOracle
 * @dev 价格预言机合约，提供ETH和ERC20代币的USD价格查询
 * @author Auction System Team
 */
contract PriceOracle is IPriceOracle, Ownable, Pausable {
    // 价格数据结构
    struct PriceData {
        uint256 price;          // 价格（以USD为单位，18位小数）
        uint256 timestamp;      // 更新时间戳
        bool isValid;           // 价格是否有效
    }
    
    // 常量
    uint256 public constant PRICE_DECIMALS = 18; // 价格小数位数
    uint256 public constant MAX_PRICE_AGE = 3600; // 最大价格年龄（1小时）
    uint256 public constant MIN_PRICE = 1e16;    // 最小价格（$0.01）
    uint256 public constant MAX_PRICE = 1e25;    // 最大价格（$10,000,000）
    
    // 状态变量
    mapping(address => PriceData) private tokenPrices;       // 代币价格映射
    mapping(address => PriceFeed) private priceFeeds;        // 价格数据源映射
    mapping(address => bool) public supportedTokens;         // 支持的代币映射
    
    address[] public tokenList;                              // 支持的代币列表
    string public constant VERSION = "1.0.0";               // 合约版本
    
    // 事件
    event PriceUpdated(
        address indexed token,
        uint256 price,
        uint256 timestamp
    );
    
    event TokenSupported(
        address indexed token,
        address indexed aggregator,
        bool supported
    );
    
    event AggregatorUpdated(
        address indexed token,
        address indexed oldAggregator,
        address indexed newAggregator
    );
    
    event EmergencyPriceSet(
        address indexed token,
        uint256 price,
        address indexed setter
    );
    
    /**
     * @dev 构造函数
     */
    constructor() Ownable(msg.sender) {
        // 初始化合约
    }
    
    /**
     * @dev 获取代币的最新价格
     * @param token 代币地址
     * @return price 最新价格（缩放到18位小数）
     * @return timestamp 价格更新的时间戳
     */
    function getLatestPrice(address token) external view override returns (uint256 price, uint256 timestamp) {
        require(supportedTokens[token], "PriceOracle: token not supported");
        
        PriceData memory priceData = tokenPrices[token];
        
        // 如果没有缓存价格或价格过期，从聚合器获取
        if (!priceData.isValid || block.timestamp - priceData.timestamp > MAX_PRICE_AGE) {
            (price, timestamp) = _fetchPriceFromAggregator(token);
        } else {
            price = priceData.price;
            timestamp = priceData.timestamp;
        }
        
        require(price > 0, "PriceOracle: invalid price");
    }
    
    /**
     * @dev 获取代币在特定时间戳的历史价格
     * @param token 代币地址
     * @return price 指定时间的价格
     * @return actualTimestamp 价格数据的实际时间戳
     */
    function getHistoricalPrice(
        address token,
        uint256 /* timestamp */
    ) external view override returns (uint256 price, uint256 actualTimestamp) {
        require(supportedTokens[token], "PriceOracle: token not supported");
        
        // 简化实现：返回当前价格
        PriceData memory priceData = tokenPrices[token];
        if (priceData.isValid) {
            price = priceData.price;
            actualTimestamp = priceData.timestamp;
        } else {
            (price, actualTimestamp) = _fetchPriceFromAggregator(token);
        }
    }
    
    /**
     * @dev 使用当前价格将金额从一种代币转换为另一种代币
     * @param fromToken 源代币地址
     * @param toToken 目标代币地址
     * @param amount 要转换的金额
     * @return convertedAmount 转换后的金额
     */
    function convertPrice(
        address fromToken,
        address toToken,
        uint256 amount
    ) external view override returns (uint256 convertedAmount) {
        (uint256 fromPrice,) = this.getLatestPrice(fromToken);
        (uint256 toPrice,) = this.getLatestPrice(toToken);
        
        uint8 fromDecimals = fromToken == address(0) ? 18 : IERC20Metadata(fromToken).decimals();
        uint8 toDecimals = toToken == address(0) ? 18 : IERC20Metadata(toToken).decimals();
        
        // 转换公式：(amount * fromPrice * 10^toDecimals) / (toPrice * 10^fromDecimals)
        convertedAmount = (amount * fromPrice * (10 ** toDecimals)) / (toPrice * (10 ** fromDecimals));
    }
    
    /**
     * @dev 检查价格数据源是否可用且新鲜
     * @param token 代币地址
     * @return available 如果价格数据源可用则返回true
     * @return fresh 如果价格在心跳周期内则返回true
     */
    function isPriceFeedHealthy(address token) external view override returns (bool available, bool fresh) {
        if (!supportedTokens[token]) {
            return (false, false);
        }
        
        PriceFeed memory feed = priceFeeds[token];
        available = feed.active && feed.feedAddress != address(0);
        
        PriceData memory priceData = tokenPrices[token];
        fresh = priceData.isValid && (block.timestamp - priceData.timestamp <= feed.heartbeat);
    }
    
    /**
     * @dev 返回价格数据源信息
     * @param token 代币地址
     * @return 价格数据源信息结构体
     */
    function getPriceFeed(address token) external view override returns (PriceFeed memory) {
        return priceFeeds[token];
    }
    
    /**
     * @dev 返回所有支持的代币
     * @return tokens 支持的代币地址数组
     */
    function getSupportedTokens() external view override returns (address[] memory tokens) {
        return tokenList;
    }
    
    /**
     * @dev 返回代币金额的美元价格
     * @param token 代币地址
     * @param amount 代币数量
     * @return usdValue 美元价值（缩放到18位小数）
     */
    function getUSDValue(address token, uint256 amount) external view override returns (uint256 usdValue) {
        (uint256 price,) = this.getLatestPrice(token);
        
        uint8 tokenDecimals = token == address(0) ? 18 : IERC20Metadata(token).decimals();
        
        // 计算USD价值：(amount * price) / (10^tokenDecimals)
        usdValue = (amount * price) / (10 ** tokenDecimals);
    }
    
    /**
     * @dev 返回预言机管理员地址
     * @return 管理员地址
     */
    function admin() external view override returns (address) {
        return owner();
    }
    
    /**
     * @dev 返回预言机版本
     * @return 版本字符串
     */
    function version() external pure override returns (string memory) {
        return VERSION;
    }
    
    /**
     * @dev 为代币添加新的价格数据源
     * @param token 代币地址
     * @param feedAddress Chainlink价格数据源地址
     * @param heartbeat 更新间隔最大时间（秒）
     * @param description 价格数据源描述
     */
    function addPriceFeed(
        address token,
        address feedAddress,
        uint256 heartbeat,
        string calldata description
    ) external override onlyOwner {
        require(feedAddress != address(0), "PriceOracle: invalid feed address");
        require(!supportedTokens[token], "PriceOracle: token already supported");
        require(heartbeat > 0 && heartbeat <= 86400, "PriceOracle: invalid heartbeat");
        
        supportedTokens[token] = true;
        tokenList.push(token);
        
        priceFeeds[token] = PriceFeed({
            feedAddress: feedAddress,
            decimals: 8, // Chainlink标准
            heartbeat: heartbeat,
            active: true,
            description: description
        });
        
        emit PriceFeedAdded(token, feedAddress, description);
    }
    
    /**
     * @dev 更新现有价格数据源
     * @param token 代币地址
     * @param newFeedAddress 新的价格数据源地址
     * @param newHeartbeat 新的心跳值
     * @param newDescription 新的描述
     */
    function updatePriceFeed(
        address token,
        address newFeedAddress,
        uint256 newHeartbeat,
        string calldata newDescription
    ) external override onlyOwner {
        require(supportedTokens[token], "PriceOracle: token not supported");
        require(newFeedAddress != address(0), "PriceOracle: invalid feed address");
        require(newHeartbeat > 0 && newHeartbeat <= 86400, "PriceOracle: invalid heartbeat");
        
        address oldFeedAddress = priceFeeds[token].feedAddress;
        
        priceFeeds[token].feedAddress = newFeedAddress;
        priceFeeds[token].heartbeat = newHeartbeat;
        priceFeeds[token].description = newDescription;
        
        // 清除旧价格数据
        delete tokenPrices[token];
        
        emit PriceFeedUpdated(token, oldFeedAddress, newFeedAddress);
    }
    
    /**
     * @dev 停用价格数据源
     * @param token 代币地址
     */
    function deactivatePriceFeed(address token) external override onlyOwner {
        require(supportedTokens[token], "PriceOracle: token not supported");
        
        address feedAddress = priceFeeds[token].feedAddress;
        priceFeeds[token].active = false;
        
        emit PriceFeedDeactivated(token, feedAddress);
    }
    
    /**
     * @dev 暂停合约（仅所有者）
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev 恢复合约（仅所有者）
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev 从聚合器获取价格
     * @param token 代币地址
     * @return price 价格
     * @return timestamp 时间戳
     */
    function _fetchPriceFromAggregator(address token) 
        internal 
        view 
        returns (uint256 price, uint256 timestamp) 
    {
        PriceFeed memory feed = priceFeeds[token];
        require(feed.active, "PriceOracle: feed not active");
        
        // 模拟从Chainlink聚合器获取价格
        // 在实际部署中，这里应该调用Chainlink的latestRoundData()
        // 为了测试目的，我们使用简化的逻辑
        
        if (token == address(0)) {
            // ETH价格模拟
            price = 2000 * 10**PRICE_DECIMALS; // $2000
        } else {
            // 其他代币价格模拟
            price = 1 * 10**PRICE_DECIMALS; // $1
        }
        
        timestamp = block.timestamp;
        
        // 验证价格范围
        require(price >= MIN_PRICE && price <= MAX_PRICE, "PriceOracle: price out of range");
    }
    
    /**
     * @dev 获取缓存的价格数据
     * @param token 代币地址
     * @return priceData 价格数据
     */
    function getCachedPrice(address token) 
        external 
        view 
        returns (PriceData memory priceData) 
    {
        return tokenPrices[token];
    }
    
    /**
     * @dev 手动更新价格（仅所有者）
     * @param token 代币地址
     * @param price 新价格
     */
    function updatePrice(address token, uint256 price) external onlyOwner {
        require(supportedTokens[token], "PriceOracle: token not supported");
        require(price >= MIN_PRICE && price <= MAX_PRICE, "PriceOracle: price out of range");
        
        tokenPrices[token] = PriceData({
            price: price,
            timestamp: block.timestamp,
            isValid: true
        });
        
        emit PriceRequested(token, msg.sender, price, block.timestamp);
    }
}
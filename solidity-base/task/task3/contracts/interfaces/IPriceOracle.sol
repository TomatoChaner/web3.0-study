// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IPriceOracle
 * @dev 价格预言机功能接口
 * @notice 定义拍卖定价的价格数据源操作
 */
interface IPriceOracle {
    /**
     * @dev 价格数据源信息结构体
     */
    struct PriceFeed {
        address feedAddress;    // Chainlink价格数据源地址
        uint8 decimals;        // 价格数据源小数位数
        uint256 heartbeat;     // 更新间隔最大时间
        bool active;           // 数据源是否激活
        string description;    // 数据源描述
    }

    /**
     * @dev 添加价格数据源时触发的事件
     */
    event PriceFeedAdded(
        address indexed token,
        address indexed feedAddress,
        string description
    );

    /**
     * @dev 更新价格数据源时触发的事件
     */
    event PriceFeedUpdated(
        address indexed token,
        address indexed oldFeed,
        address indexed newFeed
    );

    /**
     * @dev 停用价格数据源时触发的事件
     */
    event PriceFeedDeactivated(
        address indexed token,
        address indexed feedAddress
    );

    /**
     * @dev 请求价格时触发的事件
     */
    event PriceRequested(
        address indexed token,
        address indexed requester,
        uint256 price,
        uint256 timestamp
    );

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
    ) external;

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
    ) external;

    /**
     * @dev 停用价格数据源
     * @param token 代币地址
     */
    function deactivatePriceFeed(address token) external;

    /**
     * @dev 获取代币的最新价格
     * @param token 代币地址
     * @return price 最新价格（缩放到18位小数）
     * @return timestamp 价格更新的时间戳
     */
    function getLatestPrice(address token) external view returns (uint256 price, uint256 timestamp);

    /**
     * @dev 获取代币在特定时间戳的历史价格
     * @param token 代币地址
     * @param timestamp 目标时间戳
     * @return price 指定时间的价格
     * @return actualTimestamp 价格数据的实际时间戳
     */
    function getHistoricalPrice(
        address token,
        uint256 timestamp
    ) external view returns (uint256 price, uint256 actualTimestamp);

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
    ) external view returns (uint256 convertedAmount);

    /**
     * @dev 检查价格数据源是否可用且新鲜
     * @param token 代币地址
     * @return available 如果价格数据源可用则返回true
     * @return fresh 如果价格在心跳周期内则返回true
     */
    function isPriceFeedHealthy(address token) external view returns (bool available, bool fresh);

    /**
     * @dev 返回价格数据源信息
     * @param token 代币地址
     * @return 价格数据源信息结构体
     */
    function getPriceFeed(address token) external view returns (PriceFeed memory);

    /**
     * @dev 返回所有支持的代币
     * @return tokens 支持的代币地址数组
     */
    function getSupportedTokens() external view returns (address[] memory tokens);

    /**
     * @dev 返回代币金额的美元价格
     * @param token 代币地址
     * @param amount 代币数量
     * @return usdValue 美元价值（缩放到18位小数）
     */
    function getUSDValue(address token, uint256 amount) external view returns (uint256 usdValue);

    /**
     * @dev 返回预言机管理员地址
     * @return 管理员地址
     */
    function admin() external view returns (address);

    /**
     * @dev 返回预言机版本
     * @return 版本字符串
     */
    function version() external view returns (string memory);
}
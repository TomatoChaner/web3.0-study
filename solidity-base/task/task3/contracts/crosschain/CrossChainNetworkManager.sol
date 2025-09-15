// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ICrossChainAuction.sol";
import "../interfaces/IPriceOracle.sol";

/**
 * @title CrossChainNetworkManager
 * @dev 跨链配置和网络管理合约
 * @notice 管理多链网络配置、路由、费用计算等功能
 */
contract CrossChainNetworkManager is AccessControl, Pausable {

    // ============ 角色定义 ============

    /// @dev 网络管理员角色
    bytes32 public constant NETWORK_ADMIN_ROLE = keccak256("NETWORK_ADMIN_ROLE");
    
    /// @dev 费用管理员角色
    bytes32 public constant FEE_ADMIN_ROLE = keccak256("FEE_ADMIN_ROLE");
    
    /// @dev 路由管理员角色
    bytes32 public constant ROUTE_ADMIN_ROLE = keccak256("ROUTE_ADMIN_ROLE");

    // ============ 状态变量 ============

    /// @dev 网络配置信息
    struct NetworkConfig {
        uint64 chainId;              // 链ID
        string name;                 // 链名称
        string rpcUrl;               // RPC URL
        address ccipRouter;          // CCIP路由器地址
        address linkToken;           // LINK代币地址
        uint256 gasLimit;            // Gas限制
        uint256 gasPrice;            // Gas价格
        bool isActive;               // 是否活跃
        bool isTestnet;              // 是否测试网
        uint256 blockConfirmations;  // 区块确认数
        uint256 maxMessageSize;      // 最大消息大小
        uint256 addedAt;             // 添加时间
        uint256 lastUpdated;         // 最后更新时间
    }
    
    /// @dev 路由配置
    struct RouteConfig {
        uint64 sourceChainId;        // 源链ID
        uint64 destinationChainId;   // 目标链ID
        address sourceRouter;        // 源链路由器
        address destinationRouter;   // 目标链路由器
        uint256 baseFee;            // 基础费用
        uint256 gasMultiplier;      // Gas倍数
        uint256 maxGasLimit;        // 最大Gas限制
        bool isEnabled;             // 是否启用
        uint256 estimatedTime;      // 预估时间（秒）
        uint256 reliability;        // 可靠性评分（0-100）
    }
    
    /// @dev 费用配置
    struct FeeConfig {
        uint256 baseFee;            // 基础费用（USD，18位小数）
        uint256 perByteRate;        // 每字节费率
        uint256 gasMultiplier;      // Gas倍数（基点）
        uint256 priorityFee;        // 优先费用
        uint256 maxFee;             // 最大费用
        uint256 minFee;             // 最小费用
        bool isDynamic;             // 是否动态定价
    }
    
    /// @dev 代币配置
    struct TokenConfig {
        address tokenAddress;       // 代币地址
        string symbol;              // 代币符号
        uint8 decimals;             // 小数位数
        bool isSupported;           // 是否支持
        uint256 minAmount;          // 最小金额
        uint256 maxAmount;          // 最大金额
        uint256 dailyLimit;         // 日限额
        uint256 currentDailyUsage;  // 当前日使用量
        uint256 lastResetTime;      // 最后重置时间
        mapping(uint64 => bool) supportedChains; // 支持的链
    }
    
    /// @dev 网络统计
    struct NetworkStats {
        uint256 totalMessages;      // 总消息数
        uint256 successfulMessages; // 成功消息数
        uint256 failedMessages;     // 失败消息数
        uint256 totalVolume;        // 总交易量（USD）
        uint256 averageTime;        // 平均处理时间
        uint256 lastActivity;       // 最后活动时间
    }
    
    /// @dev 价格预言机
    IPriceOracle public priceOracle;
    
    /// @dev 支持的网络列表
    uint64[] public supportedChains;
    
    /// @dev 网络配置映射
    mapping(uint64 => NetworkConfig) public networkConfigs;
    
    /// @dev 路由配置映射
    mapping(bytes32 => RouteConfig) public routeConfigs;
    
    /// @dev 费用配置映射
    mapping(uint64 => FeeConfig) public feeConfigs;
    
    /// @dev 代币配置映射
    mapping(address => TokenConfig) private tokenConfigs;
    
    /// @dev 网络统计映射
    mapping(uint64 => NetworkStats) public networkStats;
    
    /// @dev 链对应的代币列表
    mapping(uint64 => address[]) public chainTokens;
    
    /// @dev 路由键映射（源链ID => 目标链ID => 路由键）
    mapping(uint64 => mapping(uint64 => bytes32)) public routeKeys;
    
    /// @dev 全局配置
    uint256 public constant MAX_CHAINS = 50;
    uint256 public constant MAX_MESSAGE_SIZE = 1024 * 1024; // 1MB
    uint256 public constant MIN_GAS_LIMIT = 21000;
    uint256 public constant MAX_GAS_LIMIT = 10000000;
    
    /// @dev 默认配置
    uint256 public defaultGasLimit = 500000;
    uint256 public defaultGasMultiplier = 12000; // 120%
    uint256 public defaultBlockConfirmations = 12;
    
    /// @dev 紧急配置
    bool public emergencyMode = false;
    mapping(uint64 => bool) public chainEmergencyPaused;

    // ============ 事件定义 ============

    event NetworkAdded(uint64 indexed chainId, string name, address ccipRouter);
    event NetworkUpdated(uint64 indexed chainId, string name);
    event NetworkRemoved(uint64 indexed chainId);
    event RouteConfigured(uint64 indexed sourceChainId, uint64 indexed destinationChainId, bool enabled);
    event FeeConfigUpdated(uint64 indexed chainId, uint256 baseFee, uint256 gasMultiplier);
    event TokenConfigured(address indexed token, string symbol, bool supported);
    event MessageProcessed(uint64 indexed sourceChainId, uint64 indexed destinationChainId, bool success);
    event EmergencyModeToggled(bool enabled);
    event ChainEmergencyPaused(uint64 indexed chainId, bool paused);
    event DailyLimitReset(address indexed token, uint256 newLimit);

    // ============ 错误定义 ============

    error ChainNotSupported(uint64 chainId);
    error ChainAlreadyExists(uint64 chainId);
    error RouteNotFound(uint64 sourceChainId, uint64 destinationChainId);
    error RouteAlreadyExists(uint64 sourceChainId, uint64 destinationChainId);
    error TokenNotSupported(address token);
    error InvalidGasLimit(uint256 gasLimit);
    error InvalidFeeConfig(uint256 fee);
    error ExceedsMaxChains(uint256 count);
    error EmergencyModeActive();
    error ChainEmergencyPausedError(uint64 chainId);
    error DailyLimitExceeded(address token, uint256 amount, uint256 limit);
    error InvalidAmount(uint256 amount, uint256 min, uint256 max);

    // ============ 修饰符 ============

    /**
     * @dev 检查链是否支持
     * @param chainId 链ID
     */
    modifier supportedChain(uint64 chainId) {
        if (!networkConfigs[chainId].isActive) {
            revert ChainNotSupported(chainId);
        }
        _;
    }

    /**
     * @dev 检查紧急模式
     */
    modifier notInEmergencyMode() {
        if (emergencyMode) {
            revert EmergencyModeActive();
        }
        _;
    }

    /**
     * @dev 检查链是否紧急暂停
     * @param chainId 链ID
     */
    modifier chainNotPaused(uint64 chainId) {
        if (chainEmergencyPaused[chainId]) {
            revert ChainEmergencyPausedError(chainId);
        }
        _;
    }

    // ============ 构造函数 ============

    /**
     * @dev 构造函数
     * @param admin 管理员地址
     * @param _priceOracle 价格预言机地址
     */
    constructor(address admin, address _priceOracle) {
        require(admin != address(0), "Invalid admin");
        require(_priceOracle != address(0), "Invalid price oracle");
        
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(NETWORK_ADMIN_ROLE, admin);
        _grantRole(FEE_ADMIN_ROLE, admin);
        _grantRole(ROUTE_ADMIN_ROLE, admin);
        
        priceOracle = IPriceOracle(_priceOracle);
    }

    // ============ 网络管理 ============

    /**
     * @dev 添加网络配置
     * @param config 网络配置
     */
    function addNetwork(NetworkConfig memory config) external onlyRole(NETWORK_ADMIN_ROLE) {
        require(config.chainId != 0, "Invalid chain ID");
        require(bytes(config.name).length > 0, "Invalid name");
        require(config.ccipRouter != address(0), "Invalid CCIP router");
        
        if (networkConfigs[config.chainId].chainId != 0) {
            revert ChainAlreadyExists(config.chainId);
        }
        if (supportedChains.length >= MAX_CHAINS) {
            revert ExceedsMaxChains(supportedChains.length);
        }
        
        // 设置默认值
        if (config.gasLimit == 0) config.gasLimit = defaultGasLimit;
        if (config.blockConfirmations == 0) config.blockConfirmations = defaultBlockConfirmations;
        if (config.maxMessageSize == 0) config.maxMessageSize = MAX_MESSAGE_SIZE;
        
        config.addedAt = block.timestamp;
        config.lastUpdated = block.timestamp;
        
        networkConfigs[config.chainId] = config;
        supportedChains.push(config.chainId);
        
        emit NetworkAdded(config.chainId, config.name, config.ccipRouter);
    }

    /**
     * @dev 更新网络配置
     * @param chainId 链ID
     * @param config 新配置
     */
    function updateNetwork(uint64 chainId, NetworkConfig memory config) external onlyRole(NETWORK_ADMIN_ROLE) supportedChain(chainId) {
        require(config.chainId == chainId, "Chain ID mismatch");
        
        NetworkConfig storage existing = networkConfigs[chainId];
        existing.name = config.name;
        existing.rpcUrl = config.rpcUrl;
        existing.ccipRouter = config.ccipRouter;
        existing.linkToken = config.linkToken;
        existing.gasLimit = config.gasLimit;
        existing.gasPrice = config.gasPrice;
        existing.isActive = config.isActive;
        existing.blockConfirmations = config.blockConfirmations;
        existing.maxMessageSize = config.maxMessageSize;
        existing.lastUpdated = block.timestamp;
        
        emit NetworkUpdated(chainId, config.name);
    }

    /**
     * @dev 移除网络
     * @param chainId 链ID
     */
    function removeNetwork(uint64 chainId) external onlyRole(NETWORK_ADMIN_ROLE) supportedChain(chainId) {
        // 从数组中移除
        for (uint256 i = 0; i < supportedChains.length; i++) {
            if (supportedChains[i] == chainId) {
                supportedChains[i] = supportedChains[supportedChains.length - 1];
                supportedChains.pop();
                break;
            }
        }
        
        delete networkConfigs[chainId];
        
        emit NetworkRemoved(chainId);
    }

    // ============ 路由管理 ============

    /**
     * @dev 配置路由
     * @param sourceChainId 源链ID
     * @param destinationChainId 目标链ID
     * @param config 路由配置
     */
    function configureRoute(
        uint64 sourceChainId,
        uint64 destinationChainId,
        RouteConfig memory config
    ) external onlyRole(ROUTE_ADMIN_ROLE) supportedChain(sourceChainId) supportedChain(destinationChainId) {
        require(sourceChainId != destinationChainId, "Same chain");
        
        bytes32 routeKey = _getRouteKey(sourceChainId, destinationChainId);
        
        config.sourceChainId = sourceChainId;
        config.destinationChainId = destinationChainId;
        
        routeConfigs[routeKey] = config;
        routeKeys[sourceChainId][destinationChainId] = routeKey;
        
        emit RouteConfigured(sourceChainId, destinationChainId, config.isEnabled);
    }

    /**
     * @dev 启用/禁用路由
     * @param sourceChainId 源链ID
     * @param destinationChainId 目标链ID
     * @param enabled 是否启用
     */
    function setRouteEnabled(
        uint64 sourceChainId,
        uint64 destinationChainId,
        bool enabled
    ) external onlyRole(ROUTE_ADMIN_ROLE) {
        bytes32 routeKey = routeKeys[sourceChainId][destinationChainId];
        if (routeKey == bytes32(0)) {
            revert RouteNotFound(sourceChainId, destinationChainId);
        }
        
        routeConfigs[routeKey].isEnabled = enabled;
        
        emit RouteConfigured(sourceChainId, destinationChainId, enabled);
    }

    // ============ 费用管理 ============

    /**
     * @dev 设置费用配置
     * @param chainId 链ID
     * @param config 费用配置
     */
    function setFeeConfig(uint64 chainId, FeeConfig memory config) external onlyRole(FEE_ADMIN_ROLE) supportedChain(chainId) {
        require(config.baseFee > 0, "Invalid base fee");
        require(config.maxFee >= config.minFee, "Invalid fee range");
        require(config.gasMultiplier >= 10000, "Invalid gas multiplier"); // 至少100%
        
        feeConfigs[chainId] = config;
        
        emit FeeConfigUpdated(chainId, config.baseFee, config.gasMultiplier);
    }

    /**
     * @dev 计算跨链费用
     * @param sourceChainId 源链ID
     * @param destinationChainId 目标链ID
     * @param messageSize 消息大小
     * @param gasLimit Gas限制
     * @param isPriority 是否优先
     * @return totalFee 总费用（USD，18位小数）
     */
    function calculateCrossChainFee(
        uint64 sourceChainId,
        uint64 destinationChainId,
        uint256 messageSize,
        uint256 gasLimit,
        bool isPriority
    ) external view supportedChain(sourceChainId) supportedChain(destinationChainId) returns (uint256 totalFee) {
        bytes32 routeKey = routeKeys[sourceChainId][destinationChainId];
        if (routeKey == bytes32(0)) {
            revert RouteNotFound(sourceChainId, destinationChainId);
        }
        
        RouteConfig storage route = routeConfigs[routeKey];
        FeeConfig storage feeConfig = feeConfigs[destinationChainId];
        
        // 基础费用
        totalFee = feeConfig.baseFee + route.baseFee;
        
        // 消息大小费用
        totalFee += messageSize * feeConfig.perByteRate;
        
        // Gas费用
        uint256 gasFee = gasLimit * networkConfigs[destinationChainId].gasPrice;
        gasFee = (gasFee * feeConfig.gasMultiplier) / 10000;
        totalFee += gasFee;
        
        // 优先费用
        if (isPriority) {
            totalFee += feeConfig.priorityFee;
        }
        
        // 应用限制
        if (totalFee < feeConfig.minFee) {
            totalFee = feeConfig.minFee;
        } else if (totalFee > feeConfig.maxFee) {
            totalFee = feeConfig.maxFee;
        }
    }

    // ============ 代币管理 ============

    /**
     * @dev 配置代币
     * @param tokenAddress 代币地址
     * @param symbol 代币符号
     * @param decimals 小数位数
     * @param minAmount 最小金额
     * @param maxAmount 最大金额
     * @param dailyLimit 日限额
     * @param supportedChainIds 支持的链ID数组
     */
    function configureToken(
        address tokenAddress,
        string memory symbol,
        uint8 decimals,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 dailyLimit,
        uint64[] memory supportedChainIds
    ) external onlyRole(NETWORK_ADMIN_ROLE) {
        require(tokenAddress != address(0), "Invalid token address");
        require(bytes(symbol).length > 0, "Invalid symbol");
        require(maxAmount >= minAmount, "Invalid amount range");
        
        TokenConfig storage config = tokenConfigs[tokenAddress];
        config.tokenAddress = tokenAddress;
        config.symbol = symbol;
        config.decimals = decimals;
        config.isSupported = true;
        config.minAmount = minAmount;
        config.maxAmount = maxAmount;
        config.dailyLimit = dailyLimit;
        config.currentDailyUsage = 0;
        config.lastResetTime = block.timestamp;
        
        // 设置支持的链
        for (uint256 i = 0; i < supportedChainIds.length; i++) {
            config.supportedChains[supportedChainIds[i]] = true;
            chainTokens[supportedChainIds[i]].push(tokenAddress);
        }
        
        emit TokenConfigured(tokenAddress, symbol, true);
    }

    /**
     * @dev 检查并更新代币使用量
     * @param tokenAddress 代币地址
     * @param amount 使用金额
     */
    function checkAndUpdateTokenUsage(address tokenAddress, uint256 amount) external {
        TokenConfig storage config = tokenConfigs[tokenAddress];
        
        if (!config.isSupported) {
            revert TokenNotSupported(tokenAddress);
        }
        
        if (amount < config.minAmount || amount > config.maxAmount) {
            revert InvalidAmount(amount, config.minAmount, config.maxAmount);
        }
        
        // 重置日限额（如果需要）
        if (block.timestamp >= config.lastResetTime + 1 days) {
            config.currentDailyUsage = 0;
            config.lastResetTime = block.timestamp;
        }
        
        // 检查日限额
        if (config.currentDailyUsage + amount > config.dailyLimit) {
            revert DailyLimitExceeded(tokenAddress, amount, config.dailyLimit - config.currentDailyUsage);
        }
        
        config.currentDailyUsage += amount;
    }

    // ============ 统计管理 ============

    /**
     * @dev 记录消息处理结果
     * @param sourceChainId 源链ID
     * @param destinationChainId 目标链ID
     * @param success 是否成功
     * @param processingTime 处理时间
     * @param volume 交易量（USD）
     */
    function recordMessageResult(
        uint64 sourceChainId,
        uint64 destinationChainId,
        bool success,
        uint256 processingTime,
        uint256 volume
    ) external onlyRole(NETWORK_ADMIN_ROLE) {
        NetworkStats storage sourceStats = networkStats[sourceChainId];
        NetworkStats storage destStats = networkStats[destinationChainId];
        
        // 更新源链统计
        sourceStats.totalMessages++;
        sourceStats.totalVolume += volume;
        sourceStats.lastActivity = block.timestamp;
        
        if (success) {
            sourceStats.successfulMessages++;
        } else {
            sourceStats.failedMessages++;
        }
        
        // 更新平均处理时间
        if (sourceStats.totalMessages == 1) {
            sourceStats.averageTime = processingTime;
        } else {
            sourceStats.averageTime = (sourceStats.averageTime * (sourceStats.totalMessages - 1) + processingTime) / sourceStats.totalMessages;
        }
        
        // 更新目标链统计
        destStats.totalMessages++;
        destStats.totalVolume += volume;
        destStats.lastActivity = block.timestamp;
        
        if (success) {
            destStats.successfulMessages++;
        } else {
            destStats.failedMessages++;
        }
        
        emit MessageProcessed(sourceChainId, destinationChainId, success);
    }

    // ============ 紧急管理 ============

    /**
     * @dev 切换紧急模式
     * @param enabled 是否启用
     */
    function setEmergencyMode(bool enabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emergencyMode = enabled;
        emit EmergencyModeToggled(enabled);
    }

    /**
     * @dev 紧急暂停特定链
     * @param chainId 链ID
     * @param paused 是否暂停
     */
    function setChainEmergencyPause(uint64 chainId, bool paused) external onlyRole(DEFAULT_ADMIN_ROLE) {
        chainEmergencyPaused[chainId] = paused;
        emit ChainEmergencyPaused(chainId, paused);
    }

    // ============ 内部函数 ============

    /**
     * @dev 生成路由键
     * @param sourceChainId 源链ID
     * @param destinationChainId 目标链ID
     * @return 路由键
     */
    function _getRouteKey(uint64 sourceChainId, uint64 destinationChainId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(sourceChainId, destinationChainId));
    }

    // ============ 视图函数 ============

    /**
     * @dev 获取所有支持的链
     * @return 链ID数组
     */
    function getSupportedChains() external view returns (uint64[] memory) {
        return supportedChains;
    }

    /**
     * @dev 获取路由配置
     * @param sourceChainId 源链ID
     * @param destinationChainId 目标链ID
     * @return 路由配置
     */
    function getRouteConfig(uint64 sourceChainId, uint64 destinationChainId) external view returns (RouteConfig memory) {
        bytes32 routeKey = routeKeys[sourceChainId][destinationChainId];
        return routeConfigs[routeKey];
    }

    /**
     * @dev 检查路由是否可用
     * @param sourceChainId 源链ID
     * @param destinationChainId 目标链ID
     * @return 是否可用
     */
    function isRouteAvailable(uint64 sourceChainId, uint64 destinationChainId) external view returns (bool) {
        if (emergencyMode || chainEmergencyPaused[sourceChainId] || chainEmergencyPaused[destinationChainId]) {
            return false;
        }
        
        if (!networkConfigs[sourceChainId].isActive || !networkConfigs[destinationChainId].isActive) {
            return false;
        }
        
        bytes32 routeKey = routeKeys[sourceChainId][destinationChainId];
        if (routeKey == bytes32(0)) {
            return false;
        }
        
        return routeConfigs[routeKey].isEnabled;
    }

    /**
     * @dev 获取代币配置
     * @param tokenAddress 代币地址
     * @return symbol 代币符号
     * @return decimals 小数位数
     * @return isSupported 是否支持
     * @return minAmount 最小金额
     * @return maxAmount 最大金额
     * @return dailyLimit 日限额
     * @return currentDailyUsage 当前日使用量
     */
    function getTokenConfig(address tokenAddress) external view returns (
        string memory symbol,
        uint8 decimals,
        bool isSupported,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 dailyLimit,
        uint256 currentDailyUsage
    ) {
        TokenConfig storage config = tokenConfigs[tokenAddress];
        return (
            config.symbol,
            config.decimals,
            config.isSupported,
            config.minAmount,
            config.maxAmount,
            config.dailyLimit,
            config.currentDailyUsage
        );
    }

    /**
     * @dev 检查代币是否在特定链上支持
     * @param tokenAddress 代币地址
     * @param chainId 链ID
     * @return 是否支持
     */
    function isTokenSupportedOnChain(address tokenAddress, uint64 chainId) external view returns (bool) {
        return tokenConfigs[tokenAddress].supportedChains[chainId];
    }

    /**
     * @dev 获取链上支持的代币列表
     * @param chainId 链ID
     * @return 代币地址数组
     */
    function getChainTokens(uint64 chainId) external view returns (address[] memory) {
        return chainTokens[chainId];
    }

    /**
     * @dev 获取网络统计
     * @param chainId 链ID
     * @return 网络统计信息
     */
    function getNetworkStats(uint64 chainId) external view returns (NetworkStats memory) {
        return networkStats[chainId];
    }

    /**
     * @dev 获取网络健康状态
     * @param chainId 链ID
     * @return isHealthy 是否健康
     * @return successRate 成功率（基点）
     * @return avgTime 平均处理时间
     */
    function getNetworkHealth(uint64 chainId) external view returns (
        bool isHealthy,
        uint256 successRate,
        uint256 avgTime
    ) {
        NetworkStats storage stats = networkStats[chainId];
        
        if (stats.totalMessages == 0) {
            return (true, 10000, 0); // 100%成功率，无数据时认为健康
        }
        
        successRate = (stats.successfulMessages * 10000) / stats.totalMessages;
        avgTime = stats.averageTime;
        
        // 健康标准：成功率>95%，平均处理时间<1小时，最近24小时有活动
        isHealthy = successRate >= 9500 && 
                   avgTime < 3600 && 
                   block.timestamp - stats.lastActivity < 86400;
    }
}
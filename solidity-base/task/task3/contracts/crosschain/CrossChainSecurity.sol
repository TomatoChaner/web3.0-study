// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "./ICrossChainAuction.sol";

/**
 * @title CrossChainSecurity
 * @dev 跨链安全验证和权限控制合约
 * @notice 提供跨链消息验证、签名验证、权限管理等安全功能
 */
contract CrossChainSecurity is AccessControl, Pausable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // ============ 角色定义 ============

    /// @dev 验证者角色
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    
    /// @dev 操作员角色
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    
    /// @dev 审计员角色
    bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE");
    
    /// @dev 紧急响应角色
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

    // ============ 状态变量 ============

    /// @dev 验证者信息
    struct ValidatorInfo {
        address validator;       // 验证者地址
        uint256 weight;         // 权重
        bool isActive;          // 是否活跃
        uint256 addedAt;        // 添加时间
        uint256 lastActivity;   // 最后活动时间
    }
    
    /// @dev 消息验证信息
    struct MessageValidation {
        bytes32 messageHash;     // 消息哈希
        uint256 validatorCount; // 验证者数量
        uint256 totalWeight;    // 总权重
        bool isValidated;       // 是否已验证
        uint256 timestamp;      // 验证时间
        mapping(address => bool) hasValidated; // 验证者是否已验证
    }
    
    /// @dev 链安全配置
    struct ChainSecurityConfig {
        uint64 chainId;          // 链ID
        bool isSupported;        // 是否支持
        uint256 minValidators;   // 最小验证者数量
        uint256 minWeight;       // 最小权重要求
        uint256 timeoutPeriod;   // 超时时间
        bool requiresSignature;  // 是否需要签名
        address trustedForwarder; // 可信转发器
    }
    
    /// @dev 验证者列表
    address[] public validators;
    
    /// @dev 验证者信息映射
    mapping(address => ValidatorInfo) public validatorInfo;
    
    /// @dev 消息验证映射
    mapping(bytes32 => MessageValidation) private messageValidations;
    
    /// @dev 链安全配置映射
    mapping(uint64 => ChainSecurityConfig) public chainConfigs;
    
    /// @dev 已使用的nonce映射（防重放攻击）
    mapping(address => mapping(uint256 => bool)) public usedNonces;
    
    /// @dev 黑名单地址
    mapping(address => bool) public blacklist;
    
    /// @dev 白名单地址
    mapping(address => bool) public whitelist;
    
    /// @dev 速率限制配置
    struct RateLimit {
        uint256 maxRequests;     // 最大请求数
        uint256 timeWindow;      // 时间窗口
        uint256 currentCount;    // 当前计数
        uint256 windowStart;     // 窗口开始时间
    }
    
    /// @dev 地址速率限制映射
    mapping(address => RateLimit) public rateLimits;
    
    /// @dev 全局安全参数
    uint256 public constant MIN_VALIDATOR_WEIGHT = 1;
    uint256 public constant MAX_VALIDATOR_WEIGHT = 100;
    uint256 public constant DEFAULT_TIMEOUT = 1 hours;
    uint256 public constant MAX_VALIDATORS = 100;
    
    /// @dev 默认速率限制
    uint256 public defaultMaxRequests = 100;
    uint256 public defaultTimeWindow = 1 hours;
    
    /// @dev 紧急暂停状态
    bool public emergencyPaused = false;

    // ============ 事件定义 ============

    event ValidatorAdded(address indexed validator, uint256 weight);
    event ValidatorRemoved(address indexed validator);
    event ValidatorWeightUpdated(address indexed validator, uint256 oldWeight, uint256 newWeight);
    event MessageValidated(bytes32 indexed messageHash, address indexed validator, uint256 totalWeight);
    event MessageFullyValidated(bytes32 indexed messageHash, uint256 finalWeight);
    event ChainConfigUpdated(uint64 indexed chainId, bool isSupported);
    event AddressBlacklisted(address indexed addr, bool blacklisted);
    event AddressWhitelisted(address indexed addr, bool whitelisted);
    event EmergencyPauseToggled(bool paused);
    event NonceUsed(address indexed user, uint256 nonce);
    event RateLimitExceeded(address indexed addr, uint256 requests, uint256 limit);

    // ============ 错误定义 ============

    error ValidatorNotFound(address validator);
    error ValidatorAlreadyExists(address validator);
    error InvalidWeight(uint256 weight);
    error MessageAlreadyValidated(bytes32 messageHash);
    error InsufficientValidation(uint256 current, uint256 required);
    error InvalidSignature(address signer, bytes32 hash);
    error NonceAlreadyUsed(address user, uint256 nonce);
    error AddressBlacklistedError(address addr);
    error ChainNotSupported(uint64 chainId);
    error RateLimitExceededError(address addr);
    error EmergencyPauseActive();
    error InvalidChainConfig(uint64 chainId);
    error TooManyValidators(uint256 count);

    // ============ 修饰符 ============

    /**
     * @dev 检查地址是否在黑名单中
     * @param addr 地址
     */
    modifier notBlacklisted(address addr) {
        if (blacklist[addr]) {
            revert AddressBlacklistedError(addr);
        }
        _;
    }

    /**
     * @dev 检查速率限制
     * @param addr 地址
     */
    modifier rateLimited(address addr) {
        _checkRateLimit(addr);
        _;
    }

    /**
     * @dev 检查紧急暂停状态
     */
    modifier notEmergencyPaused() {
        if (emergencyPaused) {
            revert EmergencyPauseActive();
        }
        _;
    }

    /**
     * @dev 检查链是否支持
     * @param chainId 链ID
     */
    modifier supportedChain(uint64 chainId) {
        if (!chainConfigs[chainId].isSupported) {
            revert ChainNotSupported(chainId);
        }
        _;
    }

    // ============ 构造函数 ============

    /**
     * @dev 构造函数
     * @param admin 管理员地址
     */
    constructor(address admin) {
        require(admin != address(0), "Invalid admin");
        
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(VALIDATOR_ROLE, admin);
        _grantRole(OPERATOR_ROLE, admin);
        _grantRole(AUDITOR_ROLE, admin);
        _grantRole(EMERGENCY_ROLE, admin);
    }

    // ============ 验证者管理 ============

    /**
     * @dev 添加验证者
     * @param validator 验证者地址
     * @param weight 权重
     */
    function addValidator(address validator, uint256 weight) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(validator != address(0), "Invalid validator");
        if (validatorInfo[validator].validator != address(0)) {
            revert ValidatorAlreadyExists(validator);
        }
        if (weight < MIN_VALIDATOR_WEIGHT || weight > MAX_VALIDATOR_WEIGHT) {
            revert InvalidWeight(weight);
        }
        if (validators.length >= MAX_VALIDATORS) {
            revert TooManyValidators(validators.length);
        }
        
        validators.push(validator);
        validatorInfo[validator] = ValidatorInfo({
            validator: validator,
            weight: weight,
            isActive: true,
            addedAt: block.timestamp,
            lastActivity: block.timestamp
        });
        
        _grantRole(VALIDATOR_ROLE, validator);
        
        emit ValidatorAdded(validator, weight);
    }

    /**
     * @dev 移除验证者
     * @param validator 验证者地址
     */
    function removeValidator(address validator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (validatorInfo[validator].validator == address(0)) {
            revert ValidatorNotFound(validator);
        }
        
        // 从数组中移除
        for (uint256 i = 0; i < validators.length; i++) {
            if (validators[i] == validator) {
                validators[i] = validators[validators.length - 1];
                validators.pop();
                break;
            }
        }
        
        delete validatorInfo[validator];
        _revokeRole(VALIDATOR_ROLE, validator);
        
        emit ValidatorRemoved(validator);
    }

    /**
     * @dev 更新验证者权重
     * @param validator 验证者地址
     * @param newWeight 新权重
     */
    function updateValidatorWeight(address validator, uint256 newWeight) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (validatorInfo[validator].validator == address(0)) {
            revert ValidatorNotFound(validator);
        }
        if (newWeight < MIN_VALIDATOR_WEIGHT || newWeight > MAX_VALIDATOR_WEIGHT) {
            revert InvalidWeight(newWeight);
        }
        
        uint256 oldWeight = validatorInfo[validator].weight;
        validatorInfo[validator].weight = newWeight;
        
        emit ValidatorWeightUpdated(validator, oldWeight, newWeight);
    }

    // ============ 消息验证 ============

    /**
     * @dev 验证跨链消息
     * @param message 跨链消息
     * @param signature 签名
     * @param nonce 防重放nonce
     * @return messageHash 消息哈希
     */
    function validateMessage(
        ICrossChainAuction.CrossChainMessage memory message,
        bytes memory signature,
        uint256 nonce
    ) external 
        onlyRole(VALIDATOR_ROLE) 
        notBlacklisted(msg.sender)
        rateLimited(msg.sender)
        notEmergencyPaused
        supportedChain(message.sourceChainId)
        returns (bytes32 messageHash) 
    {
        // 检查nonce
        if (usedNonces[msg.sender][nonce]) {
            revert NonceAlreadyUsed(msg.sender, nonce);
        }
        usedNonces[msg.sender][nonce] = true;
        
        // 计算消息哈希
        messageHash = _computeMessageHash(message, nonce);
        
        // 验证签名
        if (chainConfigs[message.sourceChainId].requiresSignature) {
            _verifySignature(messageHash, signature, message.sender);
        }
        
        // 获取或创建验证记录
        MessageValidation storage validation = messageValidations[messageHash];
        if (validation.messageHash == bytes32(0)) {
            validation.messageHash = messageHash;
            validation.timestamp = block.timestamp;
        }
        
        // 检查是否已验证
        if (validation.hasValidated[msg.sender]) {
            revert MessageAlreadyValidated(messageHash);
        }
        
        // 记录验证
        validation.hasValidated[msg.sender] = true;
        validation.validatorCount++;
        validation.totalWeight += validatorInfo[msg.sender].weight;
        
        // 更新验证者活动时间
        validatorInfo[msg.sender].lastActivity = block.timestamp;
        
        emit MessageValidated(messageHash, msg.sender, validation.totalWeight);
        
        // 检查是否达到验证要求
        ChainSecurityConfig storage config = chainConfigs[message.sourceChainId];
        if (validation.validatorCount >= config.minValidators && 
            validation.totalWeight >= config.minWeight) {
            validation.isValidated = true;
            emit MessageFullyValidated(messageHash, validation.totalWeight);
        }
        
        emit NonceUsed(msg.sender, nonce);
    }

    /**
     * @dev 批量验证消息
     * @param messages 消息数组
     * @param signatures 签名数组
     * @param nonces nonce数组
     * @return messageHashes 消息哈希数组
     */
    function batchValidateMessages(
        ICrossChainAuction.CrossChainMessage[] memory messages,
        bytes[] memory signatures,
        uint256[] memory nonces
    ) external 
        onlyRole(VALIDATOR_ROLE)
        notBlacklisted(msg.sender)
        notEmergencyPaused
        returns (bytes32[] memory messageHashes) 
    {
        require(messages.length == signatures.length && messages.length == nonces.length, "Array length mismatch");
        require(messages.length <= 10, "Too many messages"); // 限制批量大小
        
        messageHashes = new bytes32[](messages.length);
        
        for (uint256 i = 0; i < messages.length; i++) {
            // 检查速率限制（每条消息都计入）
            _checkRateLimit(msg.sender);
            
            messageHashes[i] = this.validateMessage(messages[i], signatures[i], nonces[i]);
        }
    }

    // ============ 安全配置管理 ============

    /**
     * @dev 设置链安全配置
     * @param chainId 链ID
     * @param config 安全配置
     */
    function setChainConfig(uint64 chainId, ChainSecurityConfig memory config) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(config.minValidators > 0, "Invalid min validators");
        require(config.minWeight > 0, "Invalid min weight");
        require(config.timeoutPeriod > 0, "Invalid timeout");
        
        chainConfigs[chainId] = config;
        
        emit ChainConfigUpdated(chainId, config.isSupported);
    }

    /**
     * @dev 设置黑名单
     * @param addr 地址
     * @param blacklisted 是否加入黑名单
     */
    function setBlacklist(address addr, bool blacklisted) external onlyRole(OPERATOR_ROLE) {
        blacklist[addr] = blacklisted;
        emit AddressBlacklisted(addr, blacklisted);
    }

    /**
     * @dev 设置白名单
     * @param addr 地址
     * @param whitelisted 是否加入白名单
     */
    function setWhitelist(address addr, bool whitelisted) external onlyRole(OPERATOR_ROLE) {
        whitelist[addr] = whitelisted;
        emit AddressWhitelisted(addr, whitelisted);
    }

    /**
     * @dev 设置速率限制
     * @param addr 地址
     * @param maxRequests 最大请求数
     * @param timeWindow 时间窗口
     */
    function setRateLimit(address addr, uint256 maxRequests, uint256 timeWindow) external onlyRole(OPERATOR_ROLE) {
        require(maxRequests > 0, "Invalid max requests");
        require(timeWindow > 0, "Invalid time window");
        
        rateLimits[addr] = RateLimit({
            maxRequests: maxRequests,
            timeWindow: timeWindow,
            currentCount: 0,
            windowStart: block.timestamp
        });
    }

    /**
     * @dev 紧急暂停/恢复
     * @param paused 是否暂停
     */
    function setEmergencyPause(bool paused) external onlyRole(EMERGENCY_ROLE) {
        emergencyPaused = paused;
        emit EmergencyPauseToggled(paused);
    }

    // ============ 内部函数 ============

    /**
     * @dev 计算消息哈希
     * @param message 跨链消息
     * @param nonce 防重放nonce
     * @return 消息哈希
     */
    function _computeMessageHash(ICrossChainAuction.CrossChainMessage memory message, uint256 nonce) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            message.messageType,
            message.auctionId,
            message.sender,
            message.data,
            message.sourceChainId,
            message.destinationChainId,
            message.timestamp,
            nonce
        ));
    }

    /**
     * @dev 验证签名
     * @param messageHash 消息哈希
     * @param signature 签名
     * @param expectedSigner 期望的签名者
     */
    function _verifySignature(bytes32 messageHash, bytes memory signature, address expectedSigner) internal pure {
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        address recoveredSigner = ethSignedMessageHash.recover(signature);
        
        if (recoveredSigner != expectedSigner) {
            revert InvalidSignature(recoveredSigner, messageHash);
        }
    }

    /**
     * @dev 检查速率限制
     * @param addr 地址
     */
    function _checkRateLimit(address addr) internal {
        // 白名单地址跳过速率限制
        if (whitelist[addr]) {
            return;
        }
        
        RateLimit storage limit = rateLimits[addr];
        
        // 如果没有设置特定限制，使用默认值
        if (limit.maxRequests == 0) {
            limit.maxRequests = defaultMaxRequests;
            limit.timeWindow = defaultTimeWindow;
            limit.windowStart = block.timestamp;
        }
        
        // 检查时间窗口是否需要重置
        if (block.timestamp >= limit.windowStart + limit.timeWindow) {
            limit.currentCount = 0;
            limit.windowStart = block.timestamp;
        }
        
        // 检查是否超过限制
        if (limit.currentCount >= limit.maxRequests) {
            emit RateLimitExceeded(addr, limit.currentCount, limit.maxRequests);
            revert RateLimitExceededError(addr);
        }
        
        limit.currentCount++;
    }

    // ============ 视图函数 ============

    /**
     * @dev 检查消息是否已验证
     * @param messageHash 消息哈希
     * @return 是否已验证
     */
    function isMessageValidated(bytes32 messageHash) external view returns (bool) {
        return messageValidations[messageHash].isValidated;
    }

    /**
     * @dev 获取消息验证信息
     * @param messageHash 消息哈希
     * @return validatorCount 验证者数量
     * @return totalWeight 总权重
     * @return isValidated 是否已验证
     * @return timestamp 验证时间
     */
    function getMessageValidation(bytes32 messageHash) external view returns (
        uint256 validatorCount,
        uint256 totalWeight,
        bool isValidated,
        uint256 timestamp
    ) {
        MessageValidation storage validation = messageValidations[messageHash];
        return (
            validation.validatorCount,
            validation.totalWeight,
            validation.isValidated,
            validation.timestamp
        );
    }

    /**
     * @dev 获取所有验证者
     * @return 验证者地址数组
     */
    function getAllValidators() external view returns (address[] memory) {
        return validators;
    }

    /**
     * @dev 获取活跃验证者数量
     * @return 活跃验证者数量
     */
    function getActiveValidatorCount() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < validators.length; i++) {
            if (validatorInfo[validators[i]].isActive) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev 获取总验证权重
     * @return 总权重
     */
    function getTotalValidatorWeight() external view returns (uint256) {
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < validators.length; i++) {
            if (validatorInfo[validators[i]].isActive) {
                totalWeight += validatorInfo[validators[i]].weight;
            }
        }
        return totalWeight;
    }

    /**
     * @dev 检查地址的当前速率限制状态
     * @param addr 地址
     * @return currentCount 当前计数
     * @return maxRequests 最大请求数
     * @return timeRemaining 剩余时间
     */
    function getRateLimitStatus(address addr) external view returns (
        uint256 currentCount,
        uint256 maxRequests,
        uint256 timeRemaining
    ) {
        RateLimit storage limit = rateLimits[addr];
        
        if (limit.maxRequests == 0) {
            maxRequests = defaultMaxRequests;
            currentCount = 0;
            timeRemaining = defaultTimeWindow;
        } else {
            maxRequests = limit.maxRequests;
            currentCount = limit.currentCount;
            
            uint256 windowEnd = limit.windowStart + limit.timeWindow;
            timeRemaining = block.timestamp >= windowEnd ? 0 : windowEnd - block.timestamp;
        }
    }
}
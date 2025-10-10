// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/ICalculator.sol";

/**
 * @title StorageOptimizedCalculator
 * @dev 存储优化策略计算器合约
 * @notice 通过变量打包、常量使用、存储访问优化等策略减少Gas消耗
 * @author Gas Optimization Study Project
 */
contract StorageOptimizedCalculator is ICalculator {
    // ============ Constants & Immutables ============
    
    /// @dev 最大允许值 - 使用常量避免存储槽消耗
    uint256 public constant MAX_VALUE = type(uint248).max;
    
    /// @dev 默认精度 - 编译时常量
    uint8 public constant DEFAULT_PRECISION = 18;
    
    /// @dev 合约部署时间 - 不可变量，部署时设置
    uint256 public immutable DEPLOY_TIME;
    
    /// @dev 合约所有者 - 不可变量，节省存储
    address public immutable OWNER;

    // ============ Packed Storage Structures ============
    
    /**
     * @dev 打包的合约状态数据
     * @notice 将多个小型变量打包到单个存储槽中
     */
    struct PackedState {
        uint248 lastResult;      // 31字节 - 最后运算结果
        bool isActive;           // 1字节 - 激活状态
        uint8 precision;         // 1字节 - 精度设置
    }
    
    /**
     * @dev 打包的计数器数据
     */
    struct PackedCounters {
        uint128 operationCount;     // 16字节 - 总运算次数
        uint128 batchCount;         // 16字节 - 批量运算次数
    }

    // ============ Storage Variables ============
    
    /// @dev 打包的状态变量
    PackedState private _state;
    
    /// @dev 打包的计数器
    PackedCounters private _counters;
    
    /// @dev 用户运算次数统计 - 使用打包结构
    mapping(address => uint128) private _userOperationCount;
    
    /// @dev 运算历史记录 - 仅存储关键历史
    mapping(uint256 => uint256) private _operationHistory;

    // ============ Constructor ============
    
    /**
     * @dev 构造函数
     * @notice 使用不可变量设置部署时的固定值
     */
    constructor() {
        OWNER = msg.sender;
        DEPLOY_TIME = block.timestamp;
        
        // 初始化打包状态
        _state = PackedState({
            lastResult: 0,
            isActive: true,
            precision: DEFAULT_PRECISION
        });
        
        // 初始化计数器
        _counters = PackedCounters({
            operationCount: 0,
            batchCount: 0
        });
    }

    // ============ Modifiers ============
    
    /**
     * @dev 仅所有者可调用 - 使用不可变量
     */
    modifier onlyOwner() {
        require(msg.sender == OWNER, "StorageOptimized: not owner");
        _;
    }
    
    /**
     * @dev 合约必须处于激活状态 - 优化存储读取
     */
    modifier whenActive() {
        require(_state.isActive, "StorageOptimized: not active");
        _;
    }

    // ============ Core Functions ============
    
    /**
     * @inheritdoc ICalculator
     */
    function add(uint256 a, uint256 b) 
        external 
        whenActive 
        returns (uint256 result) 
    {
        uint256 gasStart = gasleft();
        
        // 使用常量进行范围检查
        if (a > MAX_VALUE || b > MAX_VALUE) {
            revert("StorageOptimized: value exceeds maximum");
        }
        
        // 检查溢出 - 使用unchecked优化
        unchecked {
            result = a + b;
            if (result < a) {
                revert ArithmeticOverflow();
            }
        }
        
        // 批量更新存储状态
        _updateStateAfterOperation(result);
        
        uint256 gasUsed = gasStart - gasleft();
        emit CalculationPerformed(0, a, b, result, gasUsed);
        
        return result;
    }

    /**
     * @inheritdoc ICalculator
     */
    function subtract(uint256 a, uint256 b) 
        external 
        whenActive 
        returns (uint256 result) 
    {
        uint256 gasStart = gasleft();
        
        // 使用常量进行范围检查
        if (a > MAX_VALUE || b > MAX_VALUE) {
            revert("StorageOptimized: value exceeds maximum");
        }
        
        // 检查下溢
        if (a < b) {
            revert ArithmeticOverflow();
        }
        
        unchecked {
            result = a - b;
        }
        
        // 批量更新存储状态
        _updateStateAfterOperation(result);
        
        uint256 gasUsed = gasStart - gasleft();
        emit CalculationPerformed(1, a, b, result, gasUsed);
        
        return result;
    }

    /**
     * @inheritdoc ICalculator
     */
    function multiply(uint256 a, uint256 b) 
        external 
        whenActive 
        returns (uint256 result) 
    {
        uint256 gasStart = gasleft();
        
        // 使用常量进行范围检查
        if (a > MAX_VALUE || b > MAX_VALUE) {
            revert("StorageOptimized: value exceeds maximum");
        }
        
        // 优化的溢出检查
        if (a != 0) {
            result = a * b;
            if (result / a != b) {
                revert ArithmeticOverflow();
            }
        } else {
            result = 0;
        }
        
        // 批量更新存储状态
        _updateStateAfterOperation(result);
        
        uint256 gasUsed = gasStart - gasleft();
        emit CalculationPerformed(2, a, b, result, gasUsed);
        
        return result;
    }

    /**
     * @inheritdoc ICalculator
     */
    function divide(uint256 a, uint256 b) 
        external 
        whenActive 
        returns (uint256 result) 
    {
        uint256 gasStart = gasleft();
        
        // 使用常量进行范围检查
        if (a > MAX_VALUE || b > MAX_VALUE) {
            revert("StorageOptimized: value exceeds maximum");
        }
        
        // 检查除零
        if (b == 0) {
            revert DivisionByZero();
        }
        
        unchecked {
            result = a / b;
        }
        
        // 批量更新存储状态
        _updateStateAfterOperation(result);
        
        uint256 gasUsed = gasStart - gasleft();
        emit CalculationPerformed(3, a, b, result, gasUsed);
        
        return result;
    }

    // ============ Batch Operations ============
    
    /**
     * @inheritdoc ICalculator
     */
    function batchCalculate(
        uint256[] calldata values,
        uint8[] calldata operations
    ) external whenActive returns (uint256[] memory results) {
        uint256 gasStart = gasleft();
        
        // 检查数组长度
        if (values.length != operations.length * 2) {
            revert ArrayLengthMismatch();
        }
        
        uint256 operationsLength = operations.length;
        results = new uint256[](operationsLength);
        
        // 缓存状态变量以减少存储读取
        PackedState memory currentState = _state;
        PackedCounters memory currentCounters = _counters;
        
        for (uint256 i = 0; i < operationsLength;) {
            uint256 a = values[i * 2];
            uint256 b = values[i * 2 + 1];
            uint8 op = operations[i];
            
            // 验证操作符
            if (op > 3) {
                revert InvalidOperator(op);
            }
            
            // 验证数值范围 - 使用常量
            if (a > MAX_VALUE || b > MAX_VALUE) {
                revert("StorageOptimized: value exceeds maximum");
            }
            
            // 执行运算 - 使用内联逻辑
            if (op == 0) {
                // 加法
                unchecked {
                    results[i] = a + b;
                    if (results[i] < a) {
                        revert ArithmeticOverflow();
                    }
                }
            } else if (op == 1) {
                // 减法
                if (a < b) {
                    revert ArithmeticOverflow();
                }
                unchecked {
                    results[i] = a - b;
                }
            } else if (op == 2) {
                // 乘法
                if (a != 0) {
                    results[i] = a * b;
                    if (results[i] / a != b) {
                        revert ArithmeticOverflow();
                    }
                } else {
                    results[i] = 0;
                }
            } else {
                // 除法
                if (b == 0) {
                    revert DivisionByZero();
                }
                unchecked {
                    results[i] = a / b;
                }
            }
            
            // 更新计数器
            unchecked {
                currentCounters.operationCount++;
                ++i;
            }
        }
        
        // 批量更新存储状态
        if (operationsLength > 0) {
            currentState.lastResult = uint248(results[operationsLength - 1]);
            currentCounters.batchCount++;
            
            // 一次性写入存储
            _state = currentState;
            _counters = currentCounters;
            
            // 更新用户统计
            _userOperationCount[msg.sender] += uint128(operationsLength);
        }
        
        uint256 gasUsed = gasStart - gasleft();
        emit BatchCalculationCompleted(operationsLength, gasUsed);
        
        return results;
    }

    // ============ Internal Functions ============
    
    /**
     * @dev 运算后更新状态 - 优化存储写入
     * @param result 运算结果
     */
    function _updateStateAfterOperation(uint256 result) private {
        // 缓存当前状态
        PackedState memory currentState = _state;
        PackedCounters memory currentCounters = _counters;
        
        // 更新状态
        currentState.lastResult = uint248(result);
        currentCounters.operationCount++;
        
        // 一次性写入存储
        _state = currentState;
        _counters = currentCounters;
        
        // 更新用户统计
        _userOperationCount[msg.sender]++;
        
        // 仅存储重要的历史记录（每100次运算）
        if (currentCounters.operationCount % 100 == 0) {
            _operationHistory[currentCounters.operationCount] = result;
        }
    }

    // ============ View Functions ============
    
    /**
     * @inheritdoc ICalculator
     */
    function getLastResult() external view returns (uint256) {
        return _state.lastResult;
    }

    /**
     * @inheritdoc ICalculator
     */
    function getOperationCount() external view returns (uint256) {
        return _counters.operationCount;
    }

    /**
     * @inheritdoc ICalculator
     */
    function version() external pure returns (string memory) {
        return "StorageOptimizedCalculator v1.0.0";
    }

    /**
     * @dev 获取用户运算次数
     * @param user 用户地址
     * @return 用户的运算次数
     */
    function getUserOperationCount(address user) external view returns (uint256) {
        return _userOperationCount[user];
    }

    /**
     * @dev 获取批量运算次数
     * @return 批量运算次数
     */
    function getBatchCount() external view returns (uint256) {
        return _counters.batchCount;
    }

    /**
     * @dev 获取合约状态信息
     * @return isActive 是否激活
     * @return precision 精度设置
     * @return lastResult 最后结果
     */
    function getState() external view returns (bool isActive, uint8 precision, uint256 lastResult) {
        PackedState memory state = _state;
        return (state.isActive, state.precision, state.lastResult);
    }

    /**
     * @dev 获取历史运算结果（仅关键记录）
     * @param index 运算索引（必须是100的倍数）
     * @return 对应的运算结果
     */
    function getOperationHistory(uint256 index) external view returns (uint256) {
        require(index % 100 == 0, "StorageOptimized: only milestone records");
        require(index <= _counters.operationCount, "StorageOptimized: invalid index");
        return _operationHistory[index];
    }

    // ============ Admin Functions ============
    
    /**
     * @dev 设置激活状态
     * @param _isActive 新的激活状态
     */
    function setActive(bool _isActive) external onlyOwner {
        _state.isActive = _isActive;
    }

    /**
     * @dev 设置精度
     * @param _precision 新的精度值
     */
    function setPrecision(uint8 _precision) external onlyOwner {
        _state.precision = _precision;
    }

    /**
     * @dev 获取合约部署信息
     * @return owner 合约所有者
     * @return deployTime 部署时间
     */
    function getDeployInfo() external view returns (address owner, uint256 deployTime) {
        return (OWNER, DEPLOY_TIME);
    }
}
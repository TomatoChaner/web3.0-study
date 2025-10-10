// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/ICalculator.sol";

/**
 * @title ComputationOptimizedCalculator
 * @dev 计算优化策略计算器合约
 * @notice 通过批量操作、结果缓存、循环优化等策略减少计算Gas消耗
 * @author Gas Optimization Study Project
 */
contract ComputationOptimizedCalculator is ICalculator {
    // ============ State Variables ============
    
    /// @dev 最后一次运算结果
    uint256 public lastResult;
    
    /// @dev 运算次数计数器
    uint256 public operationCount;
    
    /// @dev 合约所有者
    address public owner;
    
    /// @dev 是否激活状态
    bool public isActive;
    
    /// @dev 结果缓存映射 - 缓存计算结果避免重复计算
    mapping(bytes32 => uint256) private _resultCache;
    
    /// @dev 缓存命中次数统计
    mapping(bytes32 => uint256) private _cacheHitCount;
    
    /// @dev 用户运算次数统计
    mapping(address => uint256) public userOperationCount;
    
    /// @dev 批量运算统计
    uint256 public batchOperationCount;
    
    /// @dev 缓存命中总次数
    uint256 public totalCacheHits;

    // ============ Events ============
    
    /**
     * @dev 缓存命中事件
     * @param cacheKey 缓存键
     * @param result 缓存结果
     * @param hitCount 命中次数
     */
    event CacheHit(bytes32 indexed cacheKey, uint256 result, uint256 hitCount);

    /**
     * @dev 批量运算优化事件
     * @param operationsCount 运算数量
     * @param gasPerOperation 平均每次运算Gas消耗
     */
    event BatchOptimization(uint256 operationsCount, uint256 gasPerOperation);

    // ============ Constructor ============
    
    /**
     * @dev 构造函数
     */
    constructor() {
        owner = msg.sender;
        isActive = true;
        operationCount = 0;
        batchOperationCount = 0;
        totalCacheHits = 0;
    }

    // ============ Modifiers ============
    
    /**
     * @dev 仅所有者可调用
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "ComputationOptimized: caller is not the owner");
        _;
    }
    
    /**
     * @dev 合约必须处于激活状态
     */
    modifier whenActive() {
        require(isActive, "ComputationOptimized: contract is not active");
        _;
    }

    // ============ Core Functions with Caching ============
    
    /**
     * @inheritdoc ICalculator
     */
    function add(uint256 a, uint256 b) 
        external 
        whenActive 
        returns (uint256 result) 
    {
        uint256 gasStart = gasleft();
        
        // 生成缓存键
        bytes32 cacheKey = _generateCacheKey(a, b, 0);
        
        // 检查缓存
        if (_resultCache[cacheKey] != 0) {
            result = _resultCache[cacheKey];
            _cacheHitCount[cacheKey]++;
            totalCacheHits++;
            
            emit CacheHit(cacheKey, result, _cacheHitCount[cacheKey]);
            return result;
        }
        
        // 执行计算
        unchecked {
            result = a + b;
            // 检查溢出
            if (result < a) {
                revert ArithmeticOverflow();
            }
        }
        
        // 缓存结果
        _resultCache[cacheKey] = result;
        
        // 更新状态
        _updateOperationState(result);
        
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
        
        // 生成缓存键
        bytes32 cacheKey = _generateCacheKey(a, b, 1);
        
        // 检查缓存
        if (_resultCache[cacheKey] != 0 || (a == b && _resultCache[cacheKey] == 0)) {
            result = _resultCache[cacheKey];
            _cacheHitCount[cacheKey]++;
            totalCacheHits++;
            
            emit CacheHit(cacheKey, result, _cacheHitCount[cacheKey]);
            return result;
        }
        
        // 检查下溢
        if (a < b) {
            revert ArithmeticOverflow();
        }
        
        unchecked {
            result = a - b;
        }
        
        // 缓存结果
        _resultCache[cacheKey] = result;
        
        // 更新状态
        _updateOperationState(result);
        
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
        
        // 生成缓存键
        bytes32 cacheKey = _generateCacheKey(a, b, 2);
        
        // 检查缓存
        if (_resultCache[cacheKey] != 0 || (a == 0 || b == 0)) {
            result = _resultCache[cacheKey];
            _cacheHitCount[cacheKey]++;
            totalCacheHits++;
            
            emit CacheHit(cacheKey, result, _cacheHitCount[cacheKey]);
            return result;
        }
        
        // 优化的乘法计算
        if (a == 0 || b == 0) {
            result = 0;
        } else {
            result = a * b;
            // 检查溢出
            if (result / a != b) {
                revert ArithmeticOverflow();
            }
        }
        
        // 缓存结果
        _resultCache[cacheKey] = result;
        
        // 更新状态
        _updateOperationState(result);
        
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
        
        // 检查除零
        if (b == 0) {
            revert DivisionByZero();
        }
        
        // 生成缓存键
        bytes32 cacheKey = _generateCacheKey(a, b, 3);
        
        // 检查缓存
        if (_resultCache[cacheKey] != 0 || a == 0) {
            result = _resultCache[cacheKey];
            _cacheHitCount[cacheKey]++;
            totalCacheHits++;
            
            emit CacheHit(cacheKey, result, _cacheHitCount[cacheKey]);
            return result;
        }
        
        unchecked {
            result = a / b;
        }
        
        // 缓存结果
        _resultCache[cacheKey] = result;
        
        // 更新状态
        _updateOperationState(result);
        
        uint256 gasUsed = gasStart - gasleft();
        emit CalculationPerformed(3, a, b, result, gasUsed);
        
        return result;
    }

    // ============ Advanced Batch Operations ============
    
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
        
        // 批量处理优化
        uint256 cacheHits = 0;
        
        for (uint256 i = 0; i < operationsLength;) {
            uint256 a = values[i * 2];
            uint256 b = values[i * 2 + 1];
            uint8 op = operations[i];
            
            // 验证操作符
            if (op > 3) {
                revert InvalidOperator(op);
            }
            
            // 生成缓存键
            bytes32 cacheKey = _generateCacheKey(a, b, op);
            
            // 检查缓存
            if (_resultCache[cacheKey] != 0 || _isZeroResult(a, b, op)) {
                results[i] = _resultCache[cacheKey];
                _cacheHitCount[cacheKey]++;
                cacheHits++;
            } else {
                // 执行计算
                results[i] = _performOperation(a, b, op);
                // 缓存结果
                _resultCache[cacheKey] = results[i];
            }
            
            unchecked {
                ++i;
            }
        }
        
        // 批量更新状态
        unchecked {
            operationCount += operationsLength;
            batchOperationCount++;
            totalCacheHits += cacheHits;
            userOperationCount[msg.sender] += operationsLength;
        }
        
        // 更新最后结果
        if (operationsLength > 0) {
            lastResult = results[operationsLength - 1];
        }
        
        uint256 gasUsed = gasStart - gasleft();
        uint256 gasPerOperation = operationsLength > 0 ? gasUsed / operationsLength : 0;
        
        emit BatchCalculationCompleted(operationsLength, gasUsed);
        emit BatchOptimization(operationsLength, gasPerOperation);
        
        return results;
    }

    /**
     * @dev 高级批量计算 - 支持链式运算
     * @param initialValue 初始值
     * @param values 操作数数组
     * @param operations 操作符数组
     * @return finalResult 最终结果
     */
    function chainedBatchCalculate(
        uint256 initialValue,
        uint256[] calldata values,
        uint8[] calldata operations
    ) external whenActive returns (uint256 finalResult) {
        uint256 gasStart = gasleft();
        
        // 检查数组长度
        if (values.length != operations.length) {
            revert ArrayLengthMismatch();
        }
        
        finalResult = initialValue;
        uint256 operationsLength = operations.length;
        
        // 优化的链式计算
        for (uint256 i = 0; i < operationsLength;) {
            uint256 value = values[i];
            uint8 op = operations[i];
            
            // 验证操作符
            if (op > 3) {
                revert InvalidOperator(op);
            }
            
            // 执行运算
            finalResult = _performOperation(finalResult, value, op);
            
            unchecked {
                ++i;
            }
        }
        
        // 更新状态
        _updateOperationState(finalResult);
        unchecked {
            operationCount += operationsLength;
            batchOperationCount++;
            userOperationCount[msg.sender] += operationsLength;
        }
        
        uint256 gasUsed = gasStart - gasleft();
        emit BatchCalculationCompleted(operationsLength, gasUsed);
        
        return finalResult;
    }

    /**
     * @dev 数组求和优化
     * @param values 数值数组
     * @return sum 总和
     */
    function optimizedSum(uint256[] calldata values) external whenActive returns (uint256 sum) {
        uint256 gasStart = gasleft();
        uint256 length = values.length;
        
        // 优化的循环求和
        for (uint256 i = 0; i < length;) {
            unchecked {
                sum += values[i];
                ++i;
            }
        }
        
        // 检查溢出
        if (length > 0 && sum < values[0]) {
            revert ArithmeticOverflow();
        }
        
        _updateOperationState(sum);
        unchecked {
            operationCount += length;
            userOperationCount[msg.sender] += length;
        }
        
        uint256 gasUsed = gasStart - gasleft();
        emit BatchCalculationCompleted(length, gasUsed);
        
        return sum;
    }

    // ============ Internal Functions ============
    
    /**
     * @dev 生成缓存键
     * @param a 第一个操作数
     * @param b 第二个操作数
     * @param op 操作符
     * @return 缓存键
     */
    function _generateCacheKey(uint256 a, uint256 b, uint8 op) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(a, b, op));
    }
    
    /**
     * @dev 检查是否为零结果
     * @param a 第一个操作数
     * @param b 第二个操作数
     * @param op 操作符
     * @return 是否为零结果
     */
    function _isZeroResult(uint256 a, uint256 b, uint8 op) private pure returns (bool) {
        if (op == 0) return false; // 加法
        if (op == 1) return a == b; // 减法
        if (op == 2) return a == 0 || b == 0; // 乘法
        if (op == 3) return a == 0; // 除法
        return false;
    }
    
    /**
     * @dev 执行运算
     * @param a 第一个操作数
     * @param b 第二个操作数
     * @param op 操作符
     * @return result 运算结果
     */
    function _performOperation(uint256 a, uint256 b, uint8 op) private pure returns (uint256 result) {
        if (op == 0) {
            // 加法
            unchecked {
                result = a + b;
                if (result < a) {
                    revert ArithmeticOverflow();
                }
            }
        } else if (op == 1) {
            // 减法
            if (a < b) {
                revert ArithmeticOverflow();
            }
            unchecked {
                result = a - b;
            }
        } else if (op == 2) {
            // 乘法
            if (a == 0 || b == 0) {
                result = 0;
            } else {
                result = a * b;
                if (result / a != b) {
                    revert ArithmeticOverflow();
                }
            }
        } else if (op == 3) {
            // 除法
            if (b == 0) {
                revert DivisionByZero();
            }
            unchecked {
                result = a / b;
            }
        }
        
        return result;
    }
    
    /**
     * @dev 更新运算状态
     * @param result 运算结果
     */
    function _updateOperationState(uint256 result) private {
        lastResult = result;
        unchecked {
            operationCount++;
            userOperationCount[msg.sender]++;
        }
    }

    // ============ View Functions ============
    
    /**
     * @inheritdoc ICalculator
     */
    function getLastResult() external view returns (uint256) {
        return lastResult;
    }

    /**
     * @inheritdoc ICalculator
     */
    function getOperationCount() external view returns (uint256) {
        return operationCount;
    }

    /**
     * @inheritdoc ICalculator
     */
    function version() external pure returns (string memory) {
        return "ComputationOptimizedCalculator v1.0.0";
    }

    /**
     * @dev 获取缓存统计信息
     * @param a 第一个操作数
     * @param b 第二个操作数
     * @param op 操作符
     * @return result 缓存结果
     * @return hitCount 命中次数
     */
    function getCacheInfo(uint256 a, uint256 b, uint8 op) 
        external 
        view 
        returns (uint256 result, uint256 hitCount) 
    {
        bytes32 cacheKey = _generateCacheKey(a, b, op);
        return (_resultCache[cacheKey], _cacheHitCount[cacheKey]);
    }

    /**
     * @dev 获取批量运算统计
     * @return batchCount 批量运算次数
     * @return totalCacheHitsCount 总缓存命中次数
     */
    function getBatchStats() external view returns (uint256 batchCount, uint256 totalCacheHitsCount) {
        return (batchOperationCount, totalCacheHits);
    }

    /**
     * @dev 获取用户运算次数
     * @param user 用户地址
     * @return 用户的运算次数
     */
    function getUserOperationCount(address user) external view returns (uint256) {
        return userOperationCount[user];
    }

    // ============ Cache Management ============
    
    /**
     * @dev 清除特定缓存
     * @param a 第一个操作数
     * @param b 第二个操作数
     * @param op 操作符
     */
    function clearCache(uint256 a, uint256 b, uint8 op) external onlyOwner {
        bytes32 cacheKey = _generateCacheKey(a, b, op);
        delete _resultCache[cacheKey];
        delete _cacheHitCount[cacheKey];
    }

    // ============ Admin Functions ============
    
    /**
     * @dev 设置激活状态
     * @param _isActive 新的激活状态
     */
    function setActive(bool _isActive) external onlyOwner {
        isActive = _isActive;
    }

    /**
     * @dev 转移所有权
     * @param newOwner 新所有者地址
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ComputationOptimized: new owner is the zero address");
        owner = newOwner;
    }
}
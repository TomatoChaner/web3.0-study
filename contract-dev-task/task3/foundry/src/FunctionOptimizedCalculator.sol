// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/ICalculator.sol";

/**
 * @title FunctionOptimizedCalculator
 * @dev 函数优化策略计算器合约
 * @notice 通过函数内联、调用优化、修饰符优化等策略减少函数调用Gas消耗
 * @author Gas Optimization Study Project
 */
contract FunctionOptimizedCalculator is ICalculator {
    // ============ State Variables ============
    
    /// @dev 最后一次运算结果
    uint256 public lastResult;
    
    /// @dev 运算次数计数器
    uint256 public operationCount;
    
    /// @dev 合约所有者
    address public immutable owner;
    
    /// @dev 是否激活状态
    bool public isActive;
    
    /// @dev 用户运算次数统计
    mapping(address => uint256) public userOperationCount;
    
    /// @dev 批量运算统计
    uint256 public batchOperationCount;

    // ============ Constructor ============
    
    /**
     * @dev 构造函数
     */
    constructor() {
        owner = msg.sender;
        isActive = true;
        operationCount = 0;
        batchOperationCount = 0;
    }

    // ============ Optimized Core Functions ============
    
    /**
     * @inheritdoc ICalculator
     * @dev 内联优化的加法运算
     */
    function add(uint256 a, uint256 b) 
        external 
        returns (uint256 result) 
    {
        // 内联检查和计算，避免额外的函数调用
        if (!isActive) {
            revert("FunctionOptimized: contract is not active");
        }
        
        uint256 gasStart = gasleft();
        
        // 内联溢出检查
        unchecked {
            result = a + b;
            if (result < a) {
                revert ArithmeticOverflow();
            }
        }
        
        // 内联状态更新
        lastResult = result;
        unchecked {
            operationCount++;
            userOperationCount[msg.sender]++;
        }
        
        uint256 gasUsed = gasStart - gasleft();
        emit CalculationPerformed(0, a, b, result, gasUsed);
        
        return result;
    }

    /**
     * @inheritdoc ICalculator
     * @dev 内联优化的减法运算
     */
    function subtract(uint256 a, uint256 b) 
        external 
        returns (uint256 result) 
    {
        // 内联检查和计算
        if (!isActive) {
            revert("FunctionOptimized: contract is not active");
        }
        
        uint256 gasStart = gasleft();
        
        // 内联下溢检查
        if (a < b) {
            revert ArithmeticOverflow();
        }
        
        unchecked {
            result = a - b;
        }
        
        // 内联状态更新
        lastResult = result;
        unchecked {
            operationCount++;
            userOperationCount[msg.sender]++;
        }
        
        uint256 gasUsed = gasStart - gasleft();
        emit CalculationPerformed(1, a, b, result, gasUsed);
        
        return result;
    }

    /**
     * @inheritdoc ICalculator
     * @dev 内联优化的乘法运算
     */
    function multiply(uint256 a, uint256 b) 
        external 
        returns (uint256 result) 
    {
        // 内联检查和计算
        if (!isActive) {
            revert("FunctionOptimized: contract is not active");
        }
        
        uint256 gasStart = gasleft();
        
        // 内联零值优化
        if (a == 0 || b == 0) {
            result = 0;
        } else {
            result = a * b;
            // 内联溢出检查
            if (result / a != b) {
                revert ArithmeticOverflow();
            }
        }
        
        // 内联状态更新
        lastResult = result;
        unchecked {
            operationCount++;
            userOperationCount[msg.sender]++;
        }
        
        uint256 gasUsed = gasStart - gasleft();
        emit CalculationPerformed(2, a, b, result, gasUsed);
        
        return result;
    }

    /**
     * @inheritdoc ICalculator
     * @dev 内联优化的除法运算
     */
    function divide(uint256 a, uint256 b) 
        external 
        returns (uint256 result) 
    {
        // 内联检查和计算
        if (!isActive) {
            revert("FunctionOptimized: contract is not active");
        }
        
        uint256 gasStart = gasleft();
        
        // 内联除零检查
        if (b == 0) {
            revert DivisionByZero();
        }
        
        unchecked {
            result = a / b;
        }
        
        // 内联状态更新
        lastResult = result;
        unchecked {
            operationCount++;
            userOperationCount[msg.sender]++;
        }
        
        uint256 gasUsed = gasStart - gasleft();
        emit CalculationPerformed(3, a, b, result, gasUsed);
        
        return result;
    }

    // ============ Optimized Batch Operations ============
    
    /**
     * @inheritdoc ICalculator
     * @dev 高度优化的批量计算
     */
    function batchCalculate(
        uint256[] calldata values,
        uint8[] calldata operations
    ) external returns (uint256[] memory results) {
        // 内联检查
        if (!isActive) {
            revert("FunctionOptimized: contract is not active");
        }
        
        uint256 gasStart = gasleft();
        
        // 内联数组长度检查
        if (values.length != operations.length * 2) {
            revert ArrayLengthMismatch();
        }
        
        uint256 operationsLength = operations.length;
        results = new uint256[](operationsLength);
        
        // 优化的批量处理循环
        for (uint256 i = 0; i < operationsLength;) {
            uint256 a = values[i * 2];
            uint256 b = values[i * 2 + 1];
            uint8 op = operations[i];
            
            // 内联操作符验证
            if (op > 3) {
                revert InvalidOperator(op);
            }
            
            // 内联运算执行
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
                if (a == 0 || b == 0) {
                    results[i] = 0;
                } else {
                    results[i] = a * b;
                    if (results[i] / a != b) {
                        revert ArithmeticOverflow();
                    }
                }
            } else {
                // 除法 (op == 3)
                if (b == 0) {
                    revert DivisionByZero();
                }
                unchecked {
                    results[i] = a / b;
                }
            }
            
            unchecked {
                ++i;
            }
        }
        
        // 内联状态更新
        unchecked {
            operationCount += operationsLength;
            batchOperationCount++;
            userOperationCount[msg.sender] += operationsLength;
        }
        
        // 更新最后结果
        if (operationsLength > 0) {
            lastResult = results[operationsLength - 1];
        }
        
        uint256 gasUsed = gasStart - gasleft();
        emit BatchCalculationCompleted(operationsLength, gasUsed);
        
        return results;
    }

    /**
     * @dev 超级优化的快速加法 - 专门用于高频调用
     * @param a 第一个操作数
     * @param b 第二个操作数
     * @return result 运算结果
     */
    function fastAdd(uint256 a, uint256 b) external returns (uint256 result) {
        // 最小化的检查和计算
        unchecked {
            result = a + b;
            if (result < a) {
                revert ArithmeticOverflow();
            }
            lastResult = result;
            operationCount++;
        }
        return result;
    }

    /**
     * @dev 超级优化的快速乘法 - 专门用于高频调用
     * @param a 第一个操作数
     * @param b 第二个操作数
     * @return result 运算结果
     */
    function fastMultiply(uint256 a, uint256 b) external returns (uint256 result) {
        // 最小化的检查和计算
        if (a == 0 || b == 0) {
            unchecked {
                lastResult = 0;
                operationCount++;
            }
            return 0;
        }
        
        unchecked {
            result = a * b;
            if (result / a != b) {
                revert ArithmeticOverflow();
            }
            lastResult = result;
            operationCount++;
        }
        return result;
    }

    /**
     * @dev 内联批量求和 - 极致优化
     * @param values 数值数组
     * @return sum 总和
     */
    function inlineSum(uint256[] calldata values) external returns (uint256 sum) {
        uint256 length = values.length;
        
        // 内联循环求和
        for (uint256 i = 0; i < length;) {
            unchecked {
                sum += values[i];
                ++i;
            }
        }
        
        // 简化的溢出检查
        if (length > 0 && sum < values[0]) {
            revert ArithmeticOverflow();
        }
        
        // 内联状态更新
        unchecked {
            lastResult = sum;
            operationCount += length;
            userOperationCount[msg.sender] += length;
        }
        
        return sum;
    }

    /**
     * @dev 优化的数组平均值计算
     * @param values 数值数组
     * @return average 平均值
     */
    function optimizedAverage(uint256[] calldata values) external returns (uint256 average) {
        uint256 length = values.length;
        if (length == 0) return 0;
        
        uint256 sum = 0;
        
        // 内联循环求和
        for (uint256 i = 0; i < length;) {
            unchecked {
                sum += values[i];
                ++i;
            }
        }
        
        unchecked {
            average = sum / length;
            lastResult = average;
            operationCount += length + 1; // 求和 + 除法
            userOperationCount[msg.sender] += length + 1;
        }
        
        return average;
    }

    /**
     * @dev 优化的幂运算
     * @param base 底数
     * @param exponent 指数
     * @return result 结果
     */
    function optimizedPower(uint256 base, uint256 exponent) external returns (uint256 result) {
        if (exponent == 0) {
            unchecked {
                lastResult = 1;
                operationCount++;
            }
            return 1;
        }
        
        if (base == 0) {
            unchecked {
                lastResult = 0;
                operationCount++;
            }
            return 0;
        }
        
        result = 1;
        uint256 currentBase = base;
        uint256 currentExponent = exponent;
        
        // 快速幂算法
        while (currentExponent > 0) {
            if (currentExponent & 1 == 1) {
                result = result * currentBase;
                // 检查溢出
                if (result / currentBase != result / currentBase) {
                    revert ArithmeticOverflow();
                }
            }
            currentBase = currentBase * currentBase;
            currentExponent >>= 1;
        }
        
        unchecked {
            lastResult = result;
            operationCount++;
            userOperationCount[msg.sender]++;
        }
        
        return result;
    }

    // ============ View Functions (Optimized) ============
    
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
        return "FunctionOptimizedCalculator v1.0.0";
    }

    /**
     * @dev 获取批量运算统计
     * @return batchCount 批量运算次数
     */
    function getBatchCount() external view returns (uint256 batchCount) {
        return batchOperationCount;
    }

    /**
     * @dev 获取用户运算次数
     * @param user 用户地址
     * @return 用户的运算次数
     */
    function getUserOperationCount(address user) external view returns (uint256) {
        return userOperationCount[user];
    }

    /**
     * @dev 批量获取多个用户的运算次数
     * @param users 用户地址数组
     * @return counts 对应的运算次数数组
     */
    function getBatchUserOperationCounts(address[] calldata users) 
        external 
        view 
        returns (uint256[] memory counts) 
    {
        uint256 length = users.length;
        counts = new uint256[](length);
        
        for (uint256 i = 0; i < length;) {
            counts[i] = userOperationCount[users[i]];
            unchecked {
                ++i;
            }
        }
        
        return counts;
    }

    // ============ Admin Functions (Optimized) ============
    
    /**
     * @dev 设置激活状态 - 内联所有者检查
     * @param _isActive 新的激活状态
     */
    function setActive(bool _isActive) external {
        // 内联所有者检查
        if (msg.sender != owner) {
            revert("FunctionOptimized: caller is not the owner");
        }
        isActive = _isActive;
    }

    /**
     * @dev 重置运算计数器 - 仅所有者
     */
    function resetCounters() external {
        // 内联所有者检查
        if (msg.sender != owner) {
            revert("FunctionOptimized: caller is not the owner");
        }
        
        operationCount = 0;
        batchOperationCount = 0;
        lastResult = 0;
    }

    /**
     * @dev 批量重置用户计数器
     * @param users 用户地址数组
     */
    function batchResetUserCounters(address[] calldata users) external {
        // 内联所有者检查
        if (msg.sender != owner) {
            revert("FunctionOptimized: caller is not the owner");
        }
        
        uint256 length = users.length;
        for (uint256 i = 0; i < length;) {
            userOperationCount[users[i]] = 0;
            unchecked {
                ++i;
            }
        }
    }

    // ============ Emergency Functions ============
    
    /**
     * @dev 紧急停止 - 最小化Gas消耗
     */
    function emergencyStop() external {
        if (msg.sender != owner) {
            revert("FunctionOptimized: caller is not the owner");
        }
        isActive = false;
    }

    /**
     * @dev 紧急恢复
     */
    function emergencyResume() external {
        if (msg.sender != owner) {
            revert("FunctionOptimized: caller is not the owner");
        }
        isActive = true;
    }
}
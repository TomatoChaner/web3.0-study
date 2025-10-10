// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/ICalculator.sol";

/**
 * @title BaseCalculator
 * @dev 基础计算器合约 - 作为Gas优化对比的基准版本
 * @notice 实现基本的算术运算功能，未进行任何Gas优化
 * @author Gas Optimization Study Project
 */
contract BaseCalculator is ICalculator {
    // ============ State Variables ============
    
    /// @dev 最后一次运算结果
    uint256 public lastResult;
    
    /// @dev 运算次数计数器
    uint256 public operationCount;
    
    /// @dev 是否激活状态
    bool public isActive;
    
    /// @dev 精度设置
    uint8 public precision;
    
    /// @dev 最大允许值
    uint256 public maxValue;
    
    /// @dev 合约所有者
    address public owner;
    
    /// @dev 运算历史记录
    mapping(uint256 => uint256) public operationHistory;
    
    /// @dev 用户运算次数统计
    mapping(address => uint256) public userOperationCount;

    // ============ Constructor ============
    
    /**
     * @dev 构造函数
     */
    constructor() {
        owner = msg.sender;
        isActive = true;
        precision = 18;
        maxValue = type(uint256).max;
        operationCount = 0;
    }

    // ============ Modifiers ============
    
    /**
     * @dev 仅所有者可调用
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "BaseCalculator: caller is not the owner");
        _;
    }
    
    /**
     * @dev 合约必须处于激活状态
     */
    modifier whenActive() {
        require(isActive, "BaseCalculator: contract is not active");
        _;
    }
    
    /**
     * @dev 检查数值范围
     */
    modifier validRange(uint256 value) {
        require(value <= maxValue, "BaseCalculator: value exceeds maximum");
        _;
    }

    // ============ Core Functions ============
    
    /**
     * @inheritdoc ICalculator
     */
    function add(uint256 a, uint256 b) 
        external 
        whenActive 
        validRange(a) 
        validRange(b) 
        returns (uint256 result) 
    {
        uint256 gasStart = gasleft();
        
        // 检查溢出
        if (a > type(uint256).max - b) {
            revert ArithmeticOverflow();
        }
        
        result = a + b;
        lastResult = result;
        operationCount++;
        operationHistory[operationCount] = result;
        userOperationCount[msg.sender]++;
        
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
        validRange(a) 
        validRange(b) 
        returns (uint256 result) 
    {
        uint256 gasStart = gasleft();
        
        // 检查下溢
        if (a < b) {
            revert ArithmeticOverflow();
        }
        
        result = a - b;
        lastResult = result;
        operationCount++;
        operationHistory[operationCount] = result;
        userOperationCount[msg.sender]++;
        
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
        validRange(a) 
        validRange(b) 
        returns (uint256 result) 
    {
        uint256 gasStart = gasleft();
        
        // 检查溢出
        if (a != 0 && b > type(uint256).max / a) {
            revert ArithmeticOverflow();
        }
        
        result = a * b;
        lastResult = result;
        operationCount++;
        operationHistory[operationCount] = result;
        userOperationCount[msg.sender]++;
        
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
        validRange(a) 
        validRange(b) 
        returns (uint256 result) 
    {
        uint256 gasStart = gasleft();
        
        // 检查除零
        if (b == 0) {
            revert DivisionByZero();
        }
        
        result = a / b;
        lastResult = result;
        operationCount++;
        operationHistory[operationCount] = result;
        userOperationCount[msg.sender]++;
        
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
        
        for (uint256 i = 0; i < operationsLength; i++) {
            uint256 a = values[i * 2];
            uint256 b = values[i * 2 + 1];
            uint8 op = operations[i];
            
            // 验证操作符
            if (op > 3) {
                revert InvalidOperator(op);
            }
            
            // 验证数值范围
            if (a > maxValue || b > maxValue) {
                revert("BaseCalculator: value exceeds maximum");
            }
            
            // 执行运算
            if (op == 0) {
                // 加法
                if (a > type(uint256).max - b) {
                    revert ArithmeticOverflow();
                }
                results[i] = a + b;
            } else if (op == 1) {
                // 减法
                if (a < b) {
                    revert ArithmeticOverflow();
                }
                results[i] = a - b;
            } else if (op == 2) {
                // 乘法
                if (a != 0 && b > type(uint256).max / a) {
                    revert ArithmeticOverflow();
                }
                results[i] = a * b;
            } else if (op == 3) {
                // 除法
                if (b == 0) {
                    revert DivisionByZero();
                }
                results[i] = a / b;
            }
            
            // 更新状态
            operationCount++;
            operationHistory[operationCount] = results[i];
        }
        
        // 更新最后结果和用户统计
        if (operationsLength > 0) {
            lastResult = results[operationsLength - 1];
            userOperationCount[msg.sender] += operationsLength;
        }
        
        uint256 gasUsed = gasStart - gasleft();
        emit BatchCalculationCompleted(operationsLength, gasUsed);
        
        return results;
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
        return "BaseCalculator v1.0.0";
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
     * @dev 获取历史运算结果
     * @param index 运算索引
     * @return 对应的运算结果
     */
    function getOperationHistory(uint256 index) external view returns (uint256) {
        require(index <= operationCount, "BaseCalculator: invalid index");
        return operationHistory[index];
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
     * @dev 设置精度
     * @param _precision 新的精度值
     */
    function setPrecision(uint8 _precision) external onlyOwner {
        precision = _precision;
    }

    /**
     * @dev 设置最大值
     * @param _maxValue 新的最大值
     */
    function setMaxValue(uint256 _maxValue) external onlyOwner {
        maxValue = _maxValue;
    }

    /**
     * @dev 转移所有权
     * @param newOwner 新所有者地址
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "BaseCalculator: new owner is the zero address");
        owner = newOwner;
    }
}
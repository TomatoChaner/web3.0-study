// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ICalculator
 * @dev 计算器合约的通用接口
 * @notice 定义了所有计算器合约必须实现的基本算术运算功能
 */
interface ICalculator {
    // ============ Events ============
    
    /**
     * @dev 当执行算术运算时触发
     * @param operator 操作符 (0: add, 1: subtract, 2: multiply, 3: divide)
     * @param operandA 第一个操作数
     * @param operandB 第二个操作数
     * @param result 运算结果
     * @param gasUsed 消耗的Gas量
     */
    event CalculationPerformed(
        uint8 indexed operator,
        uint256 operandA,
        uint256 operandB,
        uint256 result,
        uint256 gasUsed
    );

    /**
     * @dev 当批量运算完成时触发
     * @param operationsCount 执行的运算数量
     * @param totalGasUsed 总Gas消耗
     */
    event BatchCalculationCompleted(
        uint256 operationsCount,
        uint256 totalGasUsed
    );

    // ============ Errors ============
    
    /// @dev 除零错误
    error DivisionByZero();
    
    /// @dev 算术溢出错误
    error ArithmeticOverflow();
    
    /// @dev 无效操作符错误
    error InvalidOperator(uint8 operator);
    
    /// @dev 数组长度不匹配错误
    error ArrayLengthMismatch();

    // ============ Core Functions ============
    
    /**
     * @dev 加法运算
     * @param a 第一个加数
     * @param b 第二个加数
     * @return result 运算结果
     */
    function add(uint256 a, uint256 b) external returns (uint256 result);

    /**
     * @dev 减法运算
     * @param a 被减数
     * @param b 减数
     * @return result 运算结果
     */
    function subtract(uint256 a, uint256 b) external returns (uint256 result);

    /**
     * @dev 乘法运算
     * @param a 第一个乘数
     * @param b 第二个乘数
     * @return result 运算结果
     */
    function multiply(uint256 a, uint256 b) external returns (uint256 result);

    /**
     * @dev 除法运算
     * @param a 被除数
     * @param b 除数
     * @return result 运算结果
     */
    function divide(uint256 a, uint256 b) external returns (uint256 result);

    // ============ Batch Operations ============
    
    /**
     * @dev 批量计算
     * @param values 操作数数组
     * @param operations 操作符数组 (0: add, 1: subtract, 2: multiply, 3: divide)
     * @return results 结果数组
     */
    function batchCalculate(
        uint256[] calldata values,
        uint8[] calldata operations
    ) external returns (uint256[] memory results);

    // ============ View Functions ============
    
    /**
     * @dev 获取最后一次运算结果
     * @return 最后一次运算的结果
     */
    function getLastResult() external view returns (uint256);

    /**
     * @dev 获取运算次数统计
     * @return 总运算次数
     */
    function getOperationCount() external view returns (uint256);

    /**
     * @dev 获取合约版本信息
     * @return 版本字符串
     */
    function version() external pure returns (string memory);
}
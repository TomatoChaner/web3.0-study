// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/FunctionOptimizedCalculator.sol";
import "../src/interfaces/ICalculator.sol";

contract FunctionOptimizedCalculatorTest is Test {
    FunctionOptimizedCalculator public calculator;
    
    // 事件定义
    event CalculationPerformed(uint8 indexed operation, uint256 a, uint256 b, uint256 result, uint256 gasUsed);
    event BatchOptimization(uint256 operationCount, uint256 gasSaved);
    event BatchCalculationCompleted(uint256 operationsLength, uint256 gasUsed);
    
    // 错误定义
    error ArithmeticOverflow();
    error DivisionByZero();
    
    function setUp() public {
        calculator = new FunctionOptimizedCalculator();
    }

    // ============ 基础功能测试 ============
    
    function testBasicOperations() public {
        // 测试加法
        uint256 result = calculator.add(10, 20);
        assertEq(result, 30);
        assertEq(calculator.getLastResult(), 30);
        assertEq(calculator.getOperationCount(), 1);
        
        // 测试减法
        result = calculator.subtract(50, 20);
        assertEq(result, 30);
        assertEq(calculator.getLastResult(), 30);
        assertEq(calculator.getOperationCount(), 2);
        
        // 测试乘法
        result = calculator.multiply(7, 8);
        assertEq(result, 56);
        assertEq(calculator.getLastResult(), 56);
        assertEq(calculator.getOperationCount(), 3);
        
        // 测试除法
        result = calculator.divide(100, 5);
        assertEq(result, 20);
        assertEq(calculator.getLastResult(), 20);
        assertEq(calculator.getOperationCount(), 4);
    }

    // ============ 函数优化测试 ============
    
    function testFastAdd() public {
        uint256 result = calculator.fastAdd(15, 25);
        assertEq(result, 40);
        
        // 验证状态更新
        assertEq(calculator.getLastResult(), 40);
        assertEq(calculator.getOperationCount(), 1);
    }

    function testFastMultiply() public {
        uint256 result = calculator.fastMultiply(6, 9);
        assertEq(result, 54);
        
        // 验证状态更新
        assertEq(calculator.getLastResult(), 54);
        assertEq(calculator.getOperationCount(), 1);
    }

    function testInlineSum() public {
        uint256[] memory values = new uint256[](5);
        values[0] = 10;
        values[1] = 20;
        values[2] = 30;
        values[3] = 40;
        values[4] = 50;
        
        uint256 sum = calculator.inlineSum(values);
        assertEq(sum, 150);
        
        // 验证状态更新
        assertEq(calculator.getLastResult(), 150);
        assertEq(calculator.getOperationCount(), 5); // 数组长度为5，每个元素计为一个操作
    }

    function testOptimizedAverage() public {
        uint256[] memory values = new uint256[](4);
        values[0] = 10;
        values[1] = 20;
        values[2] = 30;
        values[3] = 40;
        
        uint256 average = calculator.optimizedAverage(values);
        assertEq(average, 25); // (10+20+30+40)/4 = 25
        
        // 验证状态更新
        assertEq(calculator.getLastResult(), 25);
        assertEq(calculator.getOperationCount(), 5); // 4个求和操作 + 1个除法操作
    }

    function testOptimizedPower() public {
        uint256 result = calculator.optimizedPower(2, 8);
        assertEq(result, 256); // 2^8 = 256
        
        result = calculator.optimizedPower(3, 4);
        assertEq(result, 81); // 3^4 = 81
        
        result = calculator.optimizedPower(5, 0);
        assertEq(result, 1); // 任何数的0次方都是1
        
        result = calculator.optimizedPower(0, 5);
        assertEq(result, 0); // 0的任何正数次方都是0
    }

    // ============ 批量操作测试 ============
    
    function testBatchCalculate() public {
        uint256[] memory values = new uint256[](8);
        values[0] = 100; values[1] = 25;  // 100 + 25 = 125
        values[2] = 200; values[3] = 50;  // 200 - 50 = 150
        values[4] = 10;  values[5] = 15;  // 10 * 15 = 150
        values[6] = 300; values[7] = 6;   // 300 / 6 = 50
        
        uint8[] memory operations = new uint8[](4);
        operations[0] = 0; // add
        operations[1] = 1; // subtract
        operations[2] = 2; // multiply
        operations[3] = 3; // divide
        
        vm.expectEmit(true, false, false, false); // 只检查第一个参数
        emit BatchCalculationCompleted(4, 0); // Gas使用量会在实际执行中计算
        
        uint256[] memory results = calculator.batchCalculate(values, operations);
        
        assertEq(results.length, 4);
        assertEq(results[0], 125);
        assertEq(results[1], 150);
        assertEq(results[2], 150);
        assertEq(results[3], 50);
        
        // 验证批量操作计数
        assertEq(calculator.getBatchCount(), 1);
    }

    // ============ 用户操作统计测试 ============
    
    function testUserOperationCount() public {
        address user1 = address(0x1);
        address user2 = address(0x2);
        
        // 用户1执行操作
        vm.prank(user1);
        calculator.add(10, 20);
        
        vm.prank(user1);
        calculator.subtract(50, 20);
        
        // 用户2执行操作
        vm.prank(user2);
        calculator.multiply(5, 6);
        
        // 验证用户操作计数
        assertEq(calculator.getUserOperationCount(user1), 2);
        assertEq(calculator.getUserOperationCount(user2), 1);
        assertEq(calculator.getUserOperationCount(address(this)), 0);
    }

    function testBatchUserOperationCounts() public {
        address[] memory users = new address[](3);
        users[0] = address(0x1);
        users[1] = address(0x2);
        users[2] = address(0x3);
        
        // 各用户执行不同数量的操作
        vm.prank(users[0]);
        calculator.add(10, 20);
        
        vm.prank(users[1]);
        calculator.add(30, 40);
        vm.prank(users[1]);
        calculator.subtract(100, 50);
        
        vm.prank(users[2]);
        calculator.multiply(5, 6);
        vm.prank(users[2]);
        calculator.divide(100, 4);
        vm.prank(users[2]);
        calculator.add(1, 1);
        
        // 批量获取用户操作计数
        uint256[] memory counts = calculator.getBatchUserOperationCounts(users);
        
        assertEq(counts.length, 3);
        assertEq(counts[0], 1);
        assertEq(counts[1], 2);
        assertEq(counts[2], 3);
    }

    // ============ 管理功能测试 ============
    
    function testSetActive() public {
        // 测试设置为非激活状态
        calculator.setActive(false);
        assertEq(calculator.isActive(), false);
        
        // 非激活状态下应该无法执行计算
        vm.expectRevert("FunctionOptimized: contract is not active");
        calculator.add(10, 20);
        
        // 重新激活
        calculator.setActive(true);
        assertEq(calculator.isActive(), true);
        
        // 激活后应该可以正常执行
        uint256 result = calculator.add(10, 20);
        assertEq(result, 30);
    }

    function testResetCounters() public {
        // 执行一些操作
        calculator.add(10, 20);
        calculator.subtract(50, 20);
        
        assertEq(calculator.getOperationCount(), 2);
        assertEq(calculator.getUserOperationCount(address(this)), 2);
        
        // 重置计数器
        calculator.resetCounters();
        
        assertEq(calculator.getOperationCount(), 0);
        // 注意：resetCounters不会重置用户操作计数，这是设计决定
        assertEq(calculator.getUserOperationCount(address(this)), 2);
    }

    function testBatchResetUserCounters() public {
        address[] memory users = new address[](2);
        users[0] = address(0x1);
        users[1] = address(0x2);
        
        // 用户执行操作
        vm.prank(users[0]);
        calculator.add(10, 20);
        
        vm.prank(users[1]);
        calculator.subtract(50, 20);
        
        assertEq(calculator.getUserOperationCount(users[0]), 1);
        assertEq(calculator.getUserOperationCount(users[1]), 1);
        
        // 批量重置用户计数器
        calculator.batchResetUserCounters(users);
        
        assertEq(calculator.getUserOperationCount(users[0]), 0);
        assertEq(calculator.getUserOperationCount(users[1]), 0);
    }

    function testEmergencyFunctions() public {
        // 测试紧急停止
        calculator.emergencyStop();
        assertEq(calculator.isActive(), false);
        
        // 紧急停止后无法执行操作
        vm.expectRevert("FunctionOptimized: contract is not active");
        calculator.add(10, 20);
        
        // 测试紧急恢复
        calculator.emergencyResume();
        assertEq(calculator.isActive(), true);
        
        // 恢复后可以正常执行
        uint256 result = calculator.add(10, 20);
        assertEq(result, 30);
    }

    // ============ 错误处理测试 ============
    
    function testErrorHandling() public {
        // 测试除零错误
        vm.expectRevert(ICalculator.DivisionByZero.selector);
        calculator.divide(100, 0);
        
        // 测试溢出错误
        vm.expectRevert(ICalculator.ArithmeticOverflow.selector);
        calculator.add(type(uint256).max, 1);
        
        // 测试下溢错误
        vm.expectRevert(ICalculator.ArithmeticOverflow.selector);
        calculator.subtract(10, 20);
    }

    // ============ Gas优化测试 ============
    
    function testGasOptimization() public {
        uint256 gasBefore;
        uint256 gasUsed;
        
        // 测试fastAdd的Gas消耗
        gasBefore = gasleft();
        calculator.fastAdd(100, 200);
        gasUsed = gasBefore - gasleft();
        emit log_named_uint("FunctionOptimized fastAdd() gas used", gasUsed);
        
        // 测试fastMultiply的Gas消耗
        gasBefore = gasleft();
        calculator.fastMultiply(50, 4);
        gasUsed = gasBefore - gasleft();
        emit log_named_uint("FunctionOptimized fastMultiply() gas used", gasUsed);
        
        // 测试inlineSum的Gas消耗
        uint256[] memory values = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            values[i] = i + 1;
        }
        
        gasBefore = gasleft();
        calculator.inlineSum(values);
        gasUsed = gasBefore - gasleft();
        emit log_named_uint("FunctionOptimized inlineSum(10 values) gas used", gasUsed);
    }

    // ============ 边界条件测试 ============
    
    function testBoundaryConditions() public {
        // 测试最大值
        uint256 result = calculator.add(type(uint128).max, 1);
        assertGt(result, type(uint128).max);
        
        // 测试最小值
        uint256 minResult = calculator.subtract(1, 1);
        assertEq(minResult, 0);
        
        // 测试空数组
        uint256[] memory emptyValues = new uint256[](0);
        uint256 sum = calculator.inlineSum(emptyValues);
        assertEq(sum, 0);
        
        // 测试单元素数组
        uint256[] memory singleValue = new uint256[](1);
        singleValue[0] = 42;
        uint256 average = calculator.optimizedAverage(singleValue);
        assertEq(average, 42);
    }

    // ============ Fuzz测试 ============
    
    function testFuzzFastAdd(uint128 a, uint128 b) public {
        uint256 result = calculator.fastAdd(a, b);
        assertEq(result, uint256(a) + uint256(b));
    }

    function testFuzzFastMultiply(uint64 a, uint64 b) public {
        uint256 result = calculator.fastMultiply(a, b);
        assertEq(result, uint256(a) * uint256(b));
    }

    function testFuzzOptimizedPower(uint8 base, uint8 exponent) public {
        vm.assume(base > 0 && exponent <= 10); // 限制范围避免溢出
        
        uint256 result = calculator.optimizedPower(base, exponent);
        
        // 手动计算预期结果
        uint256 expected = 1;
        for (uint256 i = 0; i < exponent; i++) {
            expected *= base;
        }
        
        assertEq(result, expected);
    }

    // ============ 版本信息测试 ============
    
    function testVersionInfo() public {
        string memory version = calculator.version();
        assertEq(version, "FunctionOptimizedCalculator v1.0.0");
    }

    // ============ 事件发射测试 ============
    
    function testEventEmission() public {
        vm.expectEmit(true, true, true, false); // 忽略gasUsed字段
        emit CalculationPerformed(0, 10, 20, 30, 0); // gasUsed会在实际执行中计算
        
        calculator.add(10, 20);
    }

    // ============ 复杂场景测试 ============
    
    function testComplexScenario() public {
        // 混合使用各种优化函数
        uint256 result1 = calculator.fastAdd(10, 20);
        uint256 result2 = calculator.fastMultiply(5, 6);
        
        uint256[] memory values = new uint256[](3);
        values[0] = result1;
        values[1] = result2;
        values[2] = 40;
        
        uint256 sum = calculator.inlineSum(values);
        assertEq(sum, 100); // 30 + 30 + 40 = 100
        
        uint256 average = calculator.optimizedAverage(values);
        assertEq(average, 33); // 100 / 3 = 33 (整数除法)
        
        uint256 power = calculator.optimizedPower(2, 5);
        assertEq(power, 32); // 2^5 = 32
        
        // 验证总操作计数
        // fastAdd(1) + fastMultiply(1) + inlineSum(3) + optimizedAverage(4) + optimizedPower(1) = 10
        assertEq(calculator.getOperationCount(), 10);
    }
}
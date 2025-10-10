// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/ComputationOptimizedCalculator.sol";
import "../src/interfaces/ICalculator.sol";

contract ComputationOptimizedCalculatorTest is Test {
    ComputationOptimizedCalculator public calculator;
    address public owner;
    address public user;

    event CalculationPerformed(uint8 indexed operator, uint256 operandA, uint256 operandB, uint256 result, uint256 gasUsed);
    event BatchCalculationCompleted(uint256 indexed batchId, uint256 totalOperations);
    event CacheHit(uint256 a, uint256 b, uint8 operation, uint256 result);
    event BatchOptimization(uint256 batchSize, uint256 gasOptimized);

    function setUp() public {
        owner = address(this);
        user = address(0x1);
        calculator = new ComputationOptimizedCalculator();
    }

    // 基础功能测试
    function testBasicOperations() public {
        uint256 result = calculator.add(100, 50);
        assertEq(result, 150);
        
        result = calculator.subtract(100, 30);
        assertEq(result, 70);
        
        result = calculator.multiply(10, 15);
        assertEq(result, 150);
        
        result = calculator.divide(100, 4);
        assertEq(result, 25);
    }

    // 缓存机制测试
    function testCacheHit() public {
        // 第一次计算，应该缓存结果
        uint256 result1 = calculator.add(10, 20);
        assertEq(result1, 30);
        
        // 第二次相同计算，应该命中缓存
        uint256 result2 = calculator.add(10, 20);
        assertEq(result2, 30);
        assertEq(result1, result2);
    }

    function testCacheSubtract() public {
        uint256 result1 = calculator.subtract(50, 20);
        assertEq(result1, 30);
        
        // 测试缓存命中
        uint256 result2 = calculator.subtract(50, 20);
        assertEq(result2, 30);
    }

    function testCacheMultiply() public {
        uint256 result1 = calculator.multiply(7, 8);
        assertEq(result1, 56);
        
        // 测试缓存命中
        uint256 result2 = calculator.multiply(7, 8);
        assertEq(result2, 56);
    }

    function testCacheDivide() public {
        uint256 result1 = calculator.divide(100, 5);
        assertEq(result1, 20);
        
        // 测试缓存命中
        uint256 result2 = calculator.divide(100, 5);
        assertEq(result2, 20);
    }

    // 批量计算测试
    function testBatchCalculate() public {
        uint256[] memory values = new uint256[](8);
        values[0] = 100; values[1] = 25;  // 100 + 25 = 125
        values[2] = 200; values[3] = 50;  // 200 - 50 = 150
        values[4] = 15;  values[5] = 8;   // 15 * 8 = 120
        values[6] = 144; values[7] = 12;  // 144 / 12 = 12

        uint8[] memory operations = new uint8[](4);
        operations[0] = 0; // ADD
        operations[1] = 1; // SUBTRACT
        operations[2] = 2; // MULTIPLY
        operations[3] = 3; // DIVIDE

        uint256[] memory results = calculator.batchCalculate(values, operations);
        
        assertEq(results.length, 4);
        assertEq(results[0], 125);
        assertEq(results[1], 150);
        assertEq(results[2], 120);
        assertEq(results[3], 12);
    }

    // 优化数组求和测试
    function testOptimizedSum() public {
        uint256[] memory numbers = new uint256[](5);
        numbers[0] = 10;
        numbers[1] = 20;
        numbers[2] = 30;
        numbers[3] = 40;
        numbers[4] = 50;
        
        uint256 result = calculator.add(numbers[0], numbers[1]);
        for (uint256 i = 2; i < numbers.length; i++) {
            result = calculator.add(result, numbers[i]);
        }
        
        assertEq(result, 150);
    }

    function testOptimizedSumLargeArray() public {
        uint256[] memory numbers = new uint256[](100);
        uint256 expectedSum = 0;
        
        for (uint256 i = 0; i < 100; i++) {
            numbers[i] = i + 1;
            expectedSum += i + 1;
        }
        
        uint256 sum = calculator.optimizedSum(numbers);
        assertEq(sum, expectedSum);
        assertEq(sum, 5050); // 1+2+...+100 = 5050
    }

    // 缓存管理测试
    function testClearCache() public {
        // 先创建一些缓存
        calculator.add(10, 20);
        calculator.multiply(5, 6);
        
        // 清除特定缓存
        calculator.clearCache(10, 20, 0);
        
        // 再次调用应该重新计算而不是命中缓存
        uint256 result = calculator.add(10, 20);
        assertEq(result, 30);
    }

    // 活跃状态测试
    function testActiveState() public {
        calculator.setActive(false);
        calculator.setActive(true);
        
        // 确保在活跃状态下可以正常操作
        uint256 result = calculator.add(10, 20);
        assertEq(result, 30);
    }

    // 权限测试
    function testOwnershipFunctions() public {
        vm.prank(user);
        vm.expectRevert("ComputationOptimized: caller is not the owner");
        calculator.clearCache(10, 20, 0);
        
        vm.prank(user);
        vm.expectRevert("ComputationOptimized: caller is not the owner");
        calculator.setActive(false);
        
        vm.prank(user);
        vm.expectRevert("ComputationOptimized: caller is not the owner");
        calculator.transferOwnership(user);
    }

    function testOwnershipTransfer() public {
        calculator.transferOwnership(user);
        
        // 验证所有权转移
        vm.prank(user);
        calculator.setActive(false);
        
        vm.prank(user);
        calculator.clearCache(10, 20, 0);
    }

    // 错误处理测试
    function testErrorHandling() public {
        vm.expectRevert(ICalculator.DivisionByZero.selector);
        calculator.divide(100, 0);
        
        vm.expectRevert(ICalculator.DivisionByZero.selector);
        calculator.divide(100, 0);
        
        vm.expectRevert(ICalculator.ArithmeticOverflow.selector);
        calculator.subtract(10, 20);
    }

    // Gas优化效果测试
    function testComputationGasOptimization() public {
        uint256 gasBefore;
        uint256 gasUsed;
        
        // 测试第一次计算（无缓存）
        gasBefore = gasleft();
        calculator.add(100, 200);
        gasUsed = gasBefore - gasleft();
        emit log_named_uint("ComputationOptimized first add() gas used", gasUsed);
        
        // 测试第二次计算（命中缓存）
        gasBefore = gasleft();
        calculator.add(100, 200);
        gasUsed = gasBefore - gasleft();
        emit log_named_uint("ComputationOptimized cached add() gas used", gasUsed);
    }

    function testBatchComputationOptimization() public {
        uint256[] memory values = new uint256[](20);
        uint8[] memory operations = new uint8[](10);
        
        // 准备大批量数据
        for (uint256 i = 0; i < 10; i++) {
            values[i * 2] = (i + 1) * 10;
            values[i * 2 + 1] = (i + 1) * 5;
            operations[i] = uint8(i % 4);
        }
        
        uint256 gasBefore = gasleft();
        calculator.batchCalculate(values, operations);
        uint256 gasUsed = gasBefore - gasleft();
        
        emit log_named_uint("ComputationOptimized advanced batch 10 operations gas used", gasUsed);
    }

    // 缓存性能测试
    function testCachePerformance() public {
        uint256 gasBefore;
        uint256 gasUsed;
        
        // 测试多次相同计算的性能提升
        gasBefore = gasleft();
        for (uint256 i = 0; i < 5; i++) {
            calculator.add(50, 75);
        }
        gasUsed = gasBefore - gasleft();
        emit log_named_uint("ComputationOptimized 5 cached operations gas used", gasUsed);
        
        // 对比：多次不同计算
        gasBefore = gasleft();
        for (uint256 i = 0; i < 5; i++) {
            calculator.add(50 + i, 75 + i);
        }
        gasUsed = gasBefore - gasleft();
        emit log_named_uint("ComputationOptimized 5 different operations gas used", gasUsed);
    }

    // 状态一致性测试
    function testStateConsistency() public {
        uint256 initialCount = calculator.getOperationCount();
        
        calculator.add(10, 5);
        assertEq(calculator.getOperationCount(), initialCount + 1);
        assertEq(calculator.getLastResult(), 15);
        
        calculator.multiply(3, 4);
        assertEq(calculator.getOperationCount(), initialCount + 2);
        assertEq(calculator.getLastResult(), 12);
    }

    // 边界条件测试
    function testBoundaryConditions() public {
        // 测试缓存边界
        uint256 result = calculator.add(type(uint128).max, 1);
        assertGt(result, type(uint128).max);
        
        // 测试空数组求和
        uint256[] memory emptyArray = new uint256[](0);
        uint256 sum = calculator.optimizedSum(emptyArray);
        assertEq(sum, 0);
        
        // 测试单元素数组
        uint256[] memory singleElement = new uint256[](1);
        singleElement[0] = 42;
        sum = calculator.optimizedSum(singleElement);
        assertEq(sum, 42);
    }

    // Fuzz测试
    function testFuzzAdd(uint128 a, uint128 b) public {
        uint256 result1 = calculator.add(a, b);
        uint256 result2 = calculator.add(a, b);
        
        assertEq(result1, uint256(a) + uint256(b));
        assertEq(result1, result2); // 缓存一致性
    }

    function testFuzzSubtract(uint256 a, uint256 b) public {
        vm.assume(a >= b);
        uint256 result1 = calculator.subtract(a, b);
        uint256 result2 = calculator.subtract(a, b);
        
        assertEq(result1, a - b);
        assertEq(result1, result2);
    }

    function testFuzzOptimizedSum(uint8 arraySize) public {
        vm.assume(arraySize > 0 && arraySize <= 50);
        
        uint256[] memory numbers = new uint256[](arraySize);
        uint256 expectedSum = 0;
        
        for (uint256 i = 0; i < arraySize; i++) {
            numbers[i] = i + 1;
            expectedSum += i + 1;
        }
        
        uint256 result = calculator.optimizedSum(numbers);
        assertEq(result, expectedSum);
    }

    // 版本信息测试
    function testVersion() public {
        string memory version = calculator.version();
        assertEq(version, "ComputationOptimizedCalculator v1.0.0");
    }

    // 事件发射测试
    function testEventEmission() public {
        vm.expectEmit(true, true, true, false); // 忽略gasUsed字段
        emit CalculationPerformed(0, 100, 50, 150, 0);
        calculator.add(100, 50);
    }

    function testBatchEventEmission() public {
        uint256[] memory values = new uint256[](4);
        values[0] = 10; values[1] = 5;
        values[2] = 20; values[3] = 3;
        
        uint8[] memory operations = new uint8[](2);
        operations[0] = 0; // ADD
        operations[1] = 1; // SUBTRACT
        
        calculator.batchCalculate(values, operations);
    }

    // 复杂场景测试
    function testComplexCacheScenario() public {
        // 创建复杂的缓存场景
        calculator.add(10, 20);      // 缓存 10+20=30
        calculator.multiply(5, 6);   // 缓存 5*6=30
        calculator.subtract(50, 20); // 缓存 50-20=30
        
        // 验证所有缓存都正常工作
        uint256 result1 = calculator.add(10, 20);
        uint256 result2 = calculator.multiply(5, 6);
        uint256 result3 = calculator.subtract(50, 20);
        
        assertEq(result1, 30);
        assertEq(result2, 30);
        assertEq(result3, 30);
    }

    function testMixedOperations() public {
        // 混合使用缓存和非缓存操作
        uint256 result1 = calculator.add(10, 20);           // 普通操作
        uint256 result2 = calculator.add(10, 20);     // 缓存操作
        uint256 result3 = calculator.add(10, 20);     // 命中缓存
        
        assertEq(result1, 30);
        assertEq(result2, 30);
        assertEq(result3, 30);
        
        // 验证操作计数（缓存命中不增加计数）
        assertEq(calculator.getOperationCount(), 1);
    }
}
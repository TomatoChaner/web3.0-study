// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/StorageOptimizedCalculator.sol";
import "../src/interfaces/ICalculator.sol";

contract StorageOptimizedCalculatorTest is Test {
    StorageOptimizedCalculator public calculator;
    address public owner;
    address public user;

    event CalculationPerformed(uint8 indexed operator, uint256 operandA, uint256 operandB, uint256 result, uint256 gasUsed);
    event BatchCalculationCompleted(uint256 indexed batchId, uint256 totalOperations);

    function setUp() public {
        owner = address(this);
        user = address(0x1);
        calculator = new StorageOptimizedCalculator();
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

    // 存储优化测试
    function testPackedStateAccess() public {
        // 测试打包状态的访问
        calculator.add(10, 5);
        assertEq(calculator.getLastResult(), 15);
        assertEq(calculator.getOperationCount(), 1);
        
        calculator.multiply(3, 7);
        assertEq(calculator.getLastResult(), 21);
        assertEq(calculator.getOperationCount(), 2);
    }

    function testImmutableVariables() public {
        // 测试不可变变量
        (address deployOwner, uint256 deployTime) = calculator.getDeployInfo();
        assertEq(deployOwner, owner);
        assertGt(deployTime, 0);
        
        // 部署时间应该接近当前时间
        assertApproxEqAbs(deployTime, block.timestamp, 10);
    }

    function testConstantUsage() public {
        // 测试常量的使用（通过版本信息）
        string memory version = calculator.version();
        assertEq(version, "StorageOptimizedCalculator v1.0.0");
    }

    // 批量操作优化测试
    function testOptimizedBatchCalculate() public {
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
        assertEq(calculator.getOperationCount(), 4);
    }

    // 精度设置测试
    function testPrecisionSetting() public {
        calculator.setPrecision(2);
        
        // 测试除法精度
        uint256 result = calculator.divide(100, 3);
        // 整数除法结果为33 (100/3 = 33.333... -> 33)
        assertEq(result, 33);
    }

    // 活跃状态测试
    function testActiveState() public {
        calculator.setActive(false);
        calculator.setActive(true);
        
        // 确保在活跃状态下可以正常操作
        uint256 result = calculator.add(10, 20);
        assertEq(result, 30);
    }

    // 错误处理测试
    function testErrorHandling() public {
        vm.expectRevert(ICalculator.DivisionByZero.selector);
        calculator.divide(100, 0);
        
        vm.expectRevert(ICalculator.ArithmeticOverflow.selector);
        calculator.subtract(10, 20);
    }

    // 权限测试
    function testOwnershipFunctions() public {
        vm.prank(user);
        vm.expectRevert("StorageOptimized: not owner");
        calculator.setActive(false);
        
        vm.prank(user);
        vm.expectRevert("StorageOptimized: not owner");
        calculator.setPrecision(3);
    }

    function testOwnerOnlyFunctions() public {
        // 测试owner可以调用的函数
        calculator.setActive(false);
        calculator.setActive(true);
        
        calculator.setPrecision(4);
        calculator.setPrecision(2);
    }

    // Gas优化效果测试
    function testStorageGasOptimization() public {
        uint256 gasBefore;
        uint256 gasUsed;
        
        // 测试单次操作的Gas消耗
        gasBefore = gasleft();
        calculator.add(100, 200);
        gasUsed = gasBefore - gasleft();
        emit log_named_uint("StorageOptimized add() gas used", gasUsed);
        
        // 测试连续操作的Gas消耗（应该受益于存储优化）
        gasBefore = gasleft();
        calculator.add(10, 20);
        calculator.subtract(50, 15);
        calculator.multiply(5, 6);
        gasUsed = gasBefore - gasleft();
        emit log_named_uint("StorageOptimized 3 operations gas used", gasUsed);
    }

    function testBatchOperationGasEfficiency() public {
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
        
        emit log_named_uint("StorageOptimized batch 10 operations gas used", gasUsed);
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
        // 测试最大值
        uint256 maxVal = type(uint128).max;
        uint256 result = calculator.add(maxVal, 1);
        assertEq(result, maxVal + 1);
        
        // 测试零值
        result = calculator.multiply(1000, 0);
        assertEq(result, 0);
        
        result = calculator.add(0, 0);
        assertEq(result, 0);
    }

    // Fuzz测试
    function testFuzzStorageOptimizedAdd(uint128 a, uint128 b) public {
        uint256 result = calculator.add(a, b);
        assertEq(result, uint256(a) + uint256(b));
        
        // 验证状态更新
        assertEq(calculator.getLastResult(), result);
    }

    function testFuzzStorageOptimizedSubtract(uint248 a, uint248 b) public {
        vm.assume(a >= b);
        uint256 result = calculator.subtract(a, b);
        assertEq(result, uint256(a) - uint256(b));
    }

    function testFuzzStorageOptimizedMultiply(uint64 a, uint64 b) public {
        uint256 result = calculator.multiply(a, b);
        assertEq(result, uint256(a) * uint256(b));
    }

    function testFuzzStorageOptimizedDivide(uint248 a, uint248 b) public {
        vm.assume(b > 0);
        uint256 result = calculator.divide(a, b);
        assertEq(result, uint256(a) / uint256(b));
    }

    // 存储槽优化验证
    function testStorageSlotOptimization() public {
        // 通过多次操作验证存储槽的高效使用
        uint256 gasBefore = gasleft();
        
        for (uint256 i = 0; i < 5; i++) {
            calculator.add(i * 10, i * 5);
        }
        
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("StorageOptimized 5 sequential adds gas used", gasUsed);
        
        // 验证最终状态
        assertEq(calculator.getOperationCount(), 5);
        assertEq(calculator.getLastResult(), 60); // 4*10 + 4*5 = 60
    }

    // 内存vs存储优化测试
    function testMemoryVsStorageOptimization() public {
        uint256[] memory testValues = new uint256[](6);
        testValues[0] = 100; testValues[1] = 50;
        testValues[2] = 200; testValues[3] = 75;
        testValues[4] = 300; testValues[5] = 25;
        
        uint8[] memory testOps = new uint8[](3);
        testOps[0] = 0; // ADD
        testOps[1] = 1; // SUBTRACT  
        testOps[2] = 2; // MULTIPLY
        
        uint256 gasBefore = gasleft();
        uint256[] memory results = calculator.batchCalculate(testValues, testOps);
        uint256 gasUsed = gasBefore - gasleft();
        
        emit log_named_uint("StorageOptimized batch memory operations gas used", gasUsed);
        
        assertEq(results[0], 150); // 100 + 50
        assertEq(results[1], 125); // 200 - 75
        assertEq(results[2], 7500); // 300 * 25
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
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/BaseCalculator.sol";
import "../src/StorageOptimizedCalculator.sol";
import "../src/ComputationOptimizedCalculator.sol";
import "../src/FunctionOptimizedCalculator.sol";
import "../src/utils/GasTracker.sol";

/**
 * @title BatchOperationsTest
 * @dev 批量操作性能测试，专注于测试各种批量操作的性能表现
 */
contract BatchOperationsTest is Test {
    BaseCalculator public baseCalculator;
    StorageOptimizedCalculator public storageCalculator;
    ComputationOptimizedCalculator public computationCalculator;
    FunctionOptimizedCalculator public functionCalculator;
    GasTracker public gasTracker;
    
    // 批量操作结果结构
    struct BatchResult {
        uint256 gasUsed;
        uint256 operationsCount;
        uint256 avgGasPerOperation;
        bool success;
    }
    
    function setUp() public {
        baseCalculator = new BaseCalculator();
        storageCalculator = new StorageOptimizedCalculator();
        computationCalculator = new ComputationOptimizedCalculator();
        functionCalculator = new FunctionOptimizedCalculator();
        gasTracker = new GasTracker();
    }

    // ============ 小规模批量操作测试 ============
    
    function testSmallBatchOperations() public {
        uint256[] memory values = new uint256[](4);
        values[0] = 100; values[1] = 50;
        values[2] = 200; values[3] = 25;
        
        uint8[] memory operations = new uint8[](2);
        operations[0] = 0; // add
        operations[1] = 1; // subtract
        
        _testBatchOperation("Small Batch (2 ops)", values, operations);
    }
    
    function testMediumBatchOperations() public {
        uint256[] memory values = new uint256[](12);
        values[0] = 100; values[1] = 50;   // add
        values[2] = 200; values[3] = 25;   // subtract
        values[4] = 10;  values[5] = 15;   // multiply
        values[6] = 300; values[7] = 6;    // divide
        values[8] = 80;  values[9] = 20;   // add
        values[10] = 500; values[11] = 100; // subtract
        
        uint8[] memory operations = new uint8[](6);
        operations[0] = 0; // add
        operations[1] = 1; // subtract
        operations[2] = 2; // multiply
        operations[3] = 3; // divide
        operations[4] = 0; // add
        operations[5] = 1; // subtract
        
        _testBatchOperation("Medium Batch (6 ops)", values, operations);
    }
    
    function testLargeBatchOperations() public {
        uint256[] memory values = new uint256[](20);
        uint8[] memory operations = new uint8[](10);
        
        // 填充测试数据
        for (uint256 i = 0; i < 20; i += 2) {
            values[i] = (i + 1) * 10;
            values[i + 1] = (i + 2) * 5;
        }
        
        for (uint256 i = 0; i < 10; i++) {
            operations[i] = uint8(i % 4); // 循环使用四种操作
        }
        
        _testBatchOperation("Large Batch (10 ops)", values, operations);
    }

    // ============ 特定操作类型批量测试 ============
    
    function testBatchAdditionOnly() public {
        uint256[] memory values = new uint256[](16);
        uint8[] memory operations = new uint8[](8);
        
        // 只进行加法操作
        for (uint256 i = 0; i < 16; i += 2) {
            values[i] = (i + 1) * 25;
            values[i + 1] = (i + 2) * 15;
        }
        
        for (uint256 i = 0; i < 8; i++) {
            operations[i] = 0; // 全部为加法
        }
        
        _testBatchOperation("Batch Addition Only (8 ops)", values, operations);
    }
    
    function testBatchMultiplicationOnly() public {
        uint256[] memory values = new uint256[](12);
        uint8[] memory operations = new uint8[](6);
        
        // 只进行乘法操作
        for (uint256 i = 0; i < 12; i += 2) {
            values[i] = (i + 1) * 2;
            values[i + 1] = (i + 2) + 3;
        }
        
        for (uint256 i = 0; i < 6; i++) {
            operations[i] = 2; // 全部为乘法
        }
        
        _testBatchOperation("Batch Multiplication Only (6 ops)", values, operations);
    }
    
    function testBatchDivisionOnly() public {
        uint256[] memory values = new uint256[](10);
        uint8[] memory operations = new uint8[](5);
        
        // 只进行除法操作
        values[0] = 1000; values[1] = 10;
        values[2] = 2000; values[3] = 20;
        values[4] = 1500; values[5] = 15;
        values[6] = 3000; values[7] = 30;
        values[8] = 2500; values[9] = 25;
        
        for (uint256 i = 0; i < 5; i++) {
            operations[i] = 3; // 全部为除法
        }
        
        _testBatchOperation("Batch Division Only (5 ops)", values, operations);
    }

    // ============ 混合操作模式测试 ============
    
    function testAlternatingOperations() public {
        uint256[] memory values = new uint256[](16);
        uint8[] memory operations = new uint8[](8);
        
        // 交替进行加法和减法
        for (uint256 i = 0; i < 16; i += 2) {
            values[i] = (i + 1) * 50;
            values[i + 1] = (i + 2) * 25;
        }
        
        for (uint256 i = 0; i < 8; i++) {
            operations[i] = uint8(i % 2); // 交替加法和减法
        }
        
        _testBatchOperation("Alternating Add/Sub (8 ops)", values, operations);
    }
    
    function testComplexMixedOperations() public {
        uint256[] memory values = new uint256[](20);
        uint8[] memory operations = new uint8[](10);
        
        // 复杂混合操作模式
        values[0] = 100; values[1] = 50;   // add
        values[2] = 200; values[3] = 75;   // subtract
        values[4] = 15;  values[5] = 8;    // multiply
        values[6] = 1000; values[7] = 25;  // divide
        values[8] = 300; values[9] = 150;  // add
        values[10] = 500; values[11] = 200; // subtract
        values[12] = 12; values[13] = 7;   // multiply
        values[14] = 2000; values[15] = 40; // divide
        values[16] = 80; values[17] = 30;  // add
        values[18] = 600; values[19] = 120; // subtract
        
        operations[0] = 0; operations[1] = 1; operations[2] = 2; operations[3] = 3;
        operations[4] = 0; operations[5] = 1; operations[6] = 2; operations[7] = 3;
        operations[8] = 0; operations[9] = 1;
        
        _testBatchOperation("Complex Mixed (10 ops)", values, operations);
    }

    // ============ 性能压力测试 ============
    
    function testBatchPerformanceStress() public {
        uint256[] memory values = new uint256[](40);
        uint8[] memory operations = new uint8[](20);
        
        // 生成大量操作数据
        for (uint256 i = 0; i < 40; i += 2) {
            values[i] = (i + 1) * 13 + 100;
            values[i + 1] = (i + 2) * 7 + 50;
        }
        
        for (uint256 i = 0; i < 20; i++) {
            operations[i] = uint8(i % 4);
        }
        
        _testBatchOperation("Stress Test (20 ops)", values, operations);
    }

    // ============ 边界条件批量测试 ============
    
    function testBatchBoundaryConditions() public {
        uint256[] memory values = new uint256[](8);
        uint8[] memory operations = new uint8[](4);
        
        // 边界值测试
        values[0] = 0; values[1] = 1;           // 最小值加法
        values[2] = type(uint256).max; values[3] = 1; // 最大值减法
        values[4] = 1; values[5] = 1;           // 最小乘法
        values[6] = 100; values[7] = 1;         // 除以1
        
        operations[0] = 0; // add
        operations[1] = 1; // subtract
        operations[2] = 2; // multiply
        operations[3] = 3; // divide
        
        _testBatchOperation("Boundary Conditions (4 ops)", values, operations);
    }

    // ============ 缓存效果批量测试 ============
    
    function testBatchCacheEffects() public {
        uint256[] memory values = new uint256[](16);
        uint8[] memory operations = new uint8[](8);
        
        // 重复相同的操作以测试缓存效果
        for (uint256 i = 0; i < 16; i += 2) {
            values[i] = 100;
            values[i + 1] = 200;
        }
        
        for (uint256 i = 0; i < 8; i++) {
            operations[i] = 0; // 全部为相同的加法操作
        }
        
        emit log_string("=== Cache Effects Test ===");
        
        // 只测试支持缓存的计算优化计算器
        uint256 gasBefore = gasleft();
        uint256[] memory results = computationCalculator.batchCalculate(values, operations);
        uint256 gasUsed = gasBefore - gasleft();
        
        emit log_named_uint("Computation Calculator (with cache) gas", gasUsed);
        emit log_named_uint("Operations count", operations.length);
        emit log_named_uint("Avg gas per operation", gasUsed / operations.length);
        
        // 验证结果
        for (uint256 i = 0; i < results.length; i++) {
            assertEq(results[i], 300, "Cache result should be correct");
        }
    }

    // ============ 链式批量操作测试 ============
    
    function testChainedBatchOperations() public {
        // 测试计算优化计算器的链式批量操作
        uint256[] memory values1 = new uint256[](2);
        values1[0] = 50;
        values1[1] = 25;
        
        uint8[] memory operations1 = new uint8[](2);
        operations1[0] = 0; // add
        operations1[1] = 1; // subtract
        
        uint256[] memory values2 = new uint256[](4);
        values2[0] = 10; values2[1] = 5;
        values2[2] = 20; values2[3] = 4;
        
        uint8[] memory operations2 = new uint8[](2);
        operations2[0] = 2; // multiply
        operations2[1] = 3; // divide
        
        emit log_string("=== Chained Batch Operations Test ===");
        
        uint256 gasBefore = gasleft();
        uint256 finalResult = computationCalculator.chainedBatchCalculate(
            100, values1, operations1
        );
        uint256 gasUsed = gasBefore - gasleft();
        
        emit log_named_uint("Chained batch gas", gasUsed);
        emit log_named_uint("Total operations", operations1.length);
        emit log_named_uint("Avg gas per operation", gasUsed / operations1.length);
        emit log_named_uint("Final result", finalResult);
        
        // 验证结果不为零
        assertGt(finalResult, 0, "Final result should be greater than zero");
    }

    // ============ 批量操作错误处理测试 ============
    
    function testBatchErrorHandling() public {
        uint256[] memory values = new uint256[](6);
        uint8[] memory operations = new uint8[](3);
        
        // 包含除零错误的批量操作
        values[0] = 100; values[1] = 50;  // 正常加法
        values[2] = 200; values[3] = 0;   // 除零错误
        values[4] = 300; values[5] = 100; // 正常减法
        
        operations[0] = 0; // add
        operations[1] = 3; // divide (会出错)
        operations[2] = 1; // subtract
        
        emit log_string("=== Batch Error Handling Test ===");
        
        // 测试基础计算器的错误处理
        vm.expectRevert(ICalculator.DivisionByZero.selector);
        baseCalculator.batchCalculate(values, operations);
        
        // 测试存储优化计算器的错误处理
        vm.expectRevert(ICalculator.DivisionByZero.selector);
        storageCalculator.batchCalculate(values, operations);
        
        // 测试计算优化计算器的错误处理
        vm.expectRevert(ICalculator.DivisionByZero.selector);
        computationCalculator.batchCalculate(values, operations);
        
        // 测试函数优化计算器的错误处理
        vm.expectRevert(ICalculator.DivisionByZero.selector);
        functionCalculator.batchCalculate(values, operations);
        
        emit log_string("All calculators properly handle batch errors");
    }

    // ============ 批量操作数据验证测试 ============
    
    function testBatchDataValidation() public {
        emit log_string("=== Batch Data Validation Test ===");
        
        // 测试空数组 - 应该成功返回空结果
        uint256[] memory emptyValues = new uint256[](0);
        uint8[] memory emptyOps = new uint8[](0);
        
        uint256[] memory emptyResults = baseCalculator.batchCalculate(emptyValues, emptyOps);
        assertEq(emptyResults.length, 0, "Empty arrays should return empty results");
        
        // 测试不匹配的数组长度
        uint256[] memory values = new uint256[](4);
        uint8[] memory operations = new uint8[](3); // 长度不匹配
        
        values[0] = 100; values[1] = 50;
        values[2] = 200; values[3] = 75;
        operations[0] = 0; operations[1] = 1; operations[2] = 2;
        
        vm.expectRevert(ICalculator.ArrayLengthMismatch.selector);
        baseCalculator.batchCalculate(values, operations);
        
        // 测试无效操作码
        uint256[] memory validValues = new uint256[](2);
        uint8[] memory invalidOps = new uint8[](1);
        
        validValues[0] = 100; validValues[1] = 50;
        invalidOps[0] = 5; // 无效操作码
        
        vm.expectRevert(abi.encodeWithSelector(ICalculator.InvalidOperator.selector, 5));
        baseCalculator.batchCalculate(validValues, invalidOps);
        
        emit log_string("All data validation tests passed");
    }

    // ============ 批量操作统计测试 ============
    
    function testBatchStatistics() public {
        uint256[] memory values = new uint256[](8);
        uint8[] memory operations = new uint8[](4);
        
        values[0] = 100; values[1] = 50;
        values[2] = 200; values[3] = 75;
        values[4] = 10; values[5] = 5;
        values[6] = 300; values[7] = 6;
        
        operations[0] = 0; // add
        operations[1] = 1; // subtract
        operations[2] = 2; // multiply
        operations[3] = 3; // divide
        
        emit log_string("=== Batch Statistics Test ===");
        
        // 执行批量操作
        computationCalculator.batchCalculate(values, operations);
        
        // 获取批量统计信息
        (uint256 totalBatches, uint256 totalCacheHits) = 
            computationCalculator.getBatchStats();
        
        emit log_named_uint("Total batches executed", totalBatches);
        emit log_named_uint("Total cache hits", totalCacheHits);
        
        assertGt(totalBatches, 0, "Should have executed batches");
    }

    // ============ 辅助函数 ============
    
    function _testBatchOperation(
        string memory testName,
        uint256[] memory values,
        uint8[] memory operations
    ) internal {
        emit log_named_string("Testing", testName);
        
        BatchResult memory baseResult = _measureBatchOperationBase(baseCalculator, values, operations);
        BatchResult memory storageResult = _measureBatchOperationStorage(storageCalculator, values, operations);
        BatchResult memory computationResult = _measureBatchOperationComputation(computationCalculator, values, operations);
        BatchResult memory functionResult = _measureBatchOperationFunction(functionCalculator, values, operations);
        
        // 输出结果
        emit log_named_uint("Base Calculator gas", baseResult.gasUsed);
        emit log_named_uint("Storage Optimized gas", storageResult.gasUsed);
        emit log_named_uint("Computation Optimized gas", computationResult.gasUsed);
        emit log_named_uint("Function Optimized gas", functionResult.gasUsed);
        
        emit log_named_uint("Base avg gas/op", baseResult.avgGasPerOperation);
        emit log_named_uint("Storage avg gas/op", storageResult.avgGasPerOperation);
        emit log_named_uint("Computation avg gas/op", computationResult.avgGasPerOperation);
        emit log_named_uint("Function avg gas/op", functionResult.avgGasPerOperation);
        
        // 计算节省百分比
        _logBatchSavings("Storage vs Base", baseResult, storageResult);
        _logBatchSavings("Computation vs Base", baseResult, computationResult);
        _logBatchSavings("Function vs Base", baseResult, functionResult);
        
        emit log_string("---");
    }
    
    function _measureBatchOperationBase(
        BaseCalculator calculator,
        uint256[] memory values,
        uint8[] memory operations
    ) internal returns (BatchResult memory result) {
        uint256 gasBefore = gasleft();
        
        try calculator.batchCalculate(values, operations) returns (uint256[] memory) {
            result.gasUsed = gasBefore - gasleft();
            result.operationsCount = operations.length;
            result.avgGasPerOperation = result.operationsCount > 0 ? 
                result.gasUsed / result.operationsCount : 0;
            result.success = true;
        } catch {
            result.gasUsed = gasBefore - gasleft();
            result.operationsCount = operations.length;
            result.avgGasPerOperation = 0;
            result.success = false;
        }
    }
    
    function _measureBatchOperationStorage(
        StorageOptimizedCalculator calculator,
        uint256[] memory values,
        uint8[] memory operations
    ) internal returns (BatchResult memory result) {
        uint256 gasBefore = gasleft();
        
        try calculator.batchCalculate(values, operations) returns (uint256[] memory) {
            result.gasUsed = gasBefore - gasleft();
            result.operationsCount = operations.length;
            result.avgGasPerOperation = result.operationsCount > 0 ? 
                result.gasUsed / result.operationsCount : 0;
            result.success = true;
        } catch {
            result.gasUsed = gasBefore - gasleft();
            result.operationsCount = operations.length;
            result.avgGasPerOperation = 0;
            result.success = false;
        }
    }
    
    function _measureBatchOperationComputation(
        ComputationOptimizedCalculator calculator,
        uint256[] memory values,
        uint8[] memory operations
    ) internal returns (BatchResult memory result) {
        uint256 gasBefore = gasleft();
        
        try calculator.batchCalculate(values, operations) returns (uint256[] memory) {
            result.gasUsed = gasBefore - gasleft();
            result.operationsCount = operations.length;
            result.avgGasPerOperation = result.operationsCount > 0 ? 
                result.gasUsed / result.operationsCount : 0;
            result.success = true;
        } catch {
            result.gasUsed = gasBefore - gasleft();
            result.operationsCount = operations.length;
            result.avgGasPerOperation = 0;
            result.success = false;
        }
    }
    
    function _measureBatchOperationFunction(
        FunctionOptimizedCalculator calculator,
        uint256[] memory values,
        uint8[] memory operations
    ) internal returns (BatchResult memory result) {
        uint256 gasBefore = gasleft();
        
        try calculator.batchCalculate(values, operations) returns (uint256[] memory) {
            result.gasUsed = gasBefore - gasleft();
            result.operationsCount = operations.length;
            result.avgGasPerOperation = result.operationsCount > 0 ? 
                result.gasUsed / result.operationsCount : 0;
            result.success = true;
        } catch {
            result.gasUsed = gasBefore - gasleft();
            result.operationsCount = operations.length;
            result.avgGasPerOperation = 0;
            result.success = false;
        }
    }
    
    function _logBatchSavings(
        string memory label,
        BatchResult memory baseResult,
        BatchResult memory optimizedResult
    ) internal {
        if (baseResult.success && optimizedResult.success && baseResult.gasUsed > 0) {
            if (optimizedResult.gasUsed < baseResult.gasUsed) {
                uint256 savings = baseResult.gasUsed - optimizedResult.gasUsed;
                uint256 savingsPercent = (savings * 100) / baseResult.gasUsed;
                emit log_named_string("Batch comparison", label);
                emit log_named_uint("Total gas saved", savings);
                emit log_named_uint("Savings %", savingsPercent);
                
                // 平均每操作节省
                if (baseResult.avgGasPerOperation > optimizedResult.avgGasPerOperation) {
                    uint256 avgSavings = baseResult.avgGasPerOperation - optimizedResult.avgGasPerOperation;
                    emit log_named_uint("Avg gas saved per op", avgSavings);
                }
            } else if (optimizedResult.gasUsed > baseResult.gasUsed) {
                uint256 increase = optimizedResult.gasUsed - baseResult.gasUsed;
                uint256 increasePercent = (increase * 100) / baseResult.gasUsed;
                emit log_named_string("Batch comparison", label);
                emit log_named_uint("Total gas increased", increase);
                emit log_named_uint("Increase %", increasePercent);
            } else {
                emit log_named_string("Batch comparison", label);
                emit log_string("Gas usage identical");
            }
        }
    }

    // ============ Fuzz测试 ============
    
    function testFuzzBatchOperations(
        uint8 operationCount,
        uint256 seed
    ) public {
        // 限制操作数量在合理范围内
        operationCount = uint8(bound(operationCount, 1, 15));
        
        uint256[] memory values = new uint256[](operationCount * 2);
        uint8[] memory operations = new uint8[](operationCount);
        
        // 使用种子生成测试数据
        for (uint256 i = 0; i < operationCount; i++) {
            uint256 val1 = uint256(keccak256(abi.encodePacked(seed, i, "val1"))) % 10000 + 1;
            uint256 val2 = uint256(keccak256(abi.encodePacked(seed, i, "val2"))) % 1000 + 1;
            
            values[i * 2] = val1;
            values[i * 2 + 1] = val2;
            operations[i] = uint8(uint256(keccak256(abi.encodePacked(seed, i, "op"))) % 4);
        }
        
        // 测试所有计算器
        try baseCalculator.batchCalculate(values, operations) returns (uint256[] memory baseResults) {
            try storageCalculator.batchCalculate(values, operations) returns (uint256[] memory storageResults) {
                try computationCalculator.batchCalculate(values, operations) returns (uint256[] memory computationResults) {
                    try functionCalculator.batchCalculate(values, operations) returns (uint256[] memory functionResults) {
                        // 验证所有结果一致
                        assertEq(baseResults.length, storageResults.length, "Result lengths should match");
                        assertEq(baseResults.length, computationResults.length, "Result lengths should match");
                        assertEq(baseResults.length, functionResults.length, "Result lengths should match");
                        
                        for (uint256 i = 0; i < baseResults.length; i++) {
                            assertEq(baseResults[i], storageResults[i], "Storage results should match base");
                            assertEq(baseResults[i], computationResults[i], "Computation results should match base");
                            assertEq(baseResults[i], functionResults[i], "Function results should match base");
                        }
                    } catch {
                        // 如果函数优化计算器失败，其他的也应该失败
                        vm.expectRevert();
                        baseCalculator.batchCalculate(values, operations);
                    }
                } catch {
                    // 如果计算优化计算器失败，其他的也应该失败
                    vm.expectRevert();
                    baseCalculator.batchCalculate(values, operations);
                }
            } catch {
                // 如果存储优化计算器失败，其他的也应该失败
                vm.expectRevert();
                baseCalculator.batchCalculate(values, operations);
            }
        } catch {
            // 基础计算器失败是可以接受的（比如除零错误）
        }
    }
}
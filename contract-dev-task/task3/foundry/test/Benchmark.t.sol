// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/BaseCalculator.sol";
import "../src/StorageOptimizedCalculator.sol";
import "../src/ComputationOptimizedCalculator.sol";
import "../src/FunctionOptimizedCalculator.sol";

/**
 * @title Benchmark Test Suite
 * @dev 全面的性能基准测试，比较所有计算器实现的性能表现
 */
contract BenchmarkTest is Test {
    BaseCalculator public baseCalculator;
    StorageOptimizedCalculator public storageCalculator;
    ComputationOptimizedCalculator public computationCalculator;
    FunctionOptimizedCalculator public functionCalculator;
    
    // 基准测试结果结构
    struct BenchmarkResult {
        uint256 deploymentGas;
        uint256 basicOperationGas;
        uint256 batchOperationGas;
        uint256 complexOperationGas;
        uint256 memoryUsage;
        uint256 storageReads;
        uint256 storageWrites;
        bool success;
    }
    
    // 操作类型枚举
    enum OperationType {
        ADD,
        SUBTRACT,
        MULTIPLY,
        DIVIDE
    }
    
    function setUp() public {
        // 部署所有计算器并测量部署gas
        uint256 gasBeforeBase = gasleft();
        baseCalculator = new BaseCalculator();
        uint256 baseDeployGas = gasBeforeBase - gasleft();
        
        uint256 gasBeforeStorage = gasleft();
        storageCalculator = new StorageOptimizedCalculator();
        uint256 storageDeployGas = gasBeforeStorage - gasleft();
        
        uint256 gasBeforeComputation = gasleft();
        computationCalculator = new ComputationOptimizedCalculator();
        uint256 computationDeployGas = gasBeforeComputation - gasleft();
        
        uint256 gasBeforeFunction = gasleft();
        functionCalculator = new FunctionOptimizedCalculator();
        uint256 functionDeployGas = gasBeforeFunction - gasleft();
        
        // 记录部署gas消耗
        emit log_named_uint("Base Calculator Deployment Gas", baseDeployGas);
        emit log_named_uint("Storage Calculator Deployment Gas", storageDeployGas);
        emit log_named_uint("Computation Calculator Deployment Gas", computationDeployGas);
        emit log_named_uint("Function Calculator Deployment Gas", functionDeployGas);
    }
    
    /**
     * @dev 基本操作性能基准测试
     */
    function testBasicOperationsBenchmark() public {
        emit log_string("=== Basic Operations Benchmark ===");
        
        // 测试加法
        _benchmarkBasicOperation(OperationType.ADD, 100, 50);
        
        // 测试减法
        _benchmarkBasicOperation(OperationType.SUBTRACT, 100, 30);
        
        // 测试乘法
        _benchmarkBasicOperation(OperationType.MULTIPLY, 12, 8);
        
        // 测试除法
        _benchmarkBasicOperation(OperationType.DIVIDE, 100, 5);
    }
    
    /**
     * @dev 批量操作性能基准测试
     */
    function testBatchOperationsBenchmark() public {
        emit log_string("=== Batch Operations Benchmark ===");
        
        // 小批量操作 (10个操作)
        _benchmarkBatchOperations(10, "Small Batch");
        
        // 中等批量操作 (50个操作)
        _benchmarkBatchOperations(50, "Medium Batch");
        
        // 大批量操作 (100个操作)
        _benchmarkBatchOperations(100, "Large Batch");
    }
    
    /**
     * @dev 复杂操作性能基准测试
     */
    function testComplexOperationsBenchmark() public {
        emit log_string("=== Complex Operations Benchmark ===");
        
        // 测试链式操作
        _benchmarkChainedOperations();
        
        // 测试重复操作（缓存效果）
        _benchmarkRepeatedOperations();
        
        // 测试混合操作
        _benchmarkMixedOperations();
    }
    
    /**
     * @dev 内存和存储使用基准测试
     */
    function testMemoryStorageBenchmark() public {
        emit log_string("=== Memory & Storage Benchmark ===");
        
        // 测试存储读写操作
        _benchmarkStorageOperations();
        
        // 测试内存使用效率
        _benchmarkMemoryUsage();
    }
    
    /**
     * @dev 边界条件性能基准测试
     */
    function testBoundaryConditionsBenchmark() public {
        emit log_string("=== Boundary Conditions Benchmark ===");
        
        // 测试最大值操作
        _benchmarkBoundaryOperation(type(uint256).max / 2, type(uint256).max / 2, OperationType.ADD);
        
        // 测试最小值操作
        _benchmarkBoundaryOperation(1, 1, OperationType.SUBTRACT);
        
        // 测试零值操作
        _benchmarkBoundaryOperation(0, 100, OperationType.ADD);
    }
    
    /**
     * @dev 压力测试基准
     */
    function testStressBenchmark() public {
        emit log_string("=== Stress Test Benchmark ===");
        
        // 连续1000次操作
        _benchmarkStressTest(1000);
    }
    
    /**
     * @dev 全面性能比较
     */
    function testOverallPerformanceComparison() public {
        emit log_string("=== Overall Performance Comparison ===");
        
        BenchmarkResult memory baseResult = _generateOverallBenchmark(baseCalculator, "Base");
        BenchmarkResult memory storageResult = _generateOverallBenchmarkStorage(storageCalculator, "Storage");
        BenchmarkResult memory computationResult = _generateOverallBenchmarkComputation(computationCalculator, "Computation");
        BenchmarkResult memory functionResult = _generateOverallBenchmarkFunction(functionCalculator, "Function");
        
        // 输出综合比较结果
        _logOverallComparison(baseResult, storageResult, computationResult, functionResult);
        
        // 确定最优实现
        _determineOptimalImplementation(baseResult, storageResult, computationResult, functionResult);
    }
    
    // ============ 内部辅助函数 ============
    
    function _benchmarkBasicOperation(OperationType opType, uint256 a, uint256 b) internal {
        string memory opName = _getOperationName(opType);
        emit log_named_string("Testing Operation", opName);
        
        // 测试Base Calculator
        uint256 baseGas = _measureBasicOperationBase(baseCalculator, opType, a, b);
        
        // 测试Storage Calculator
        uint256 storageGas = _measureBasicOperationStorage(storageCalculator, opType, a, b);
        
        // 测试Computation Calculator
        uint256 computationGas = _measureBasicOperationComputation(computationCalculator, opType, a, b);
        
        // 测试Function Calculator
        uint256 functionGas = _measureBasicOperationFunction(functionCalculator, opType, a, b);
        
        // 输出结果
        emit log_named_uint("Base Gas", baseGas);
        emit log_named_uint("Storage Gas", storageGas);
        emit log_named_uint("Computation Gas", computationGas);
        emit log_named_uint("Function Gas", functionGas);
        
        // 计算节省百分比
        _logSavingsPercentage("Storage vs Base", baseGas, storageGas);
        _logSavingsPercentage("Computation vs Base", baseGas, computationGas);
        _logSavingsPercentage("Function vs Base", baseGas, functionGas);
        
        emit log_string("---");
    }
    
    function _benchmarkBatchOperations(uint256 batchSize, string memory batchName) internal {
        emit log_named_string("Testing Batch", batchName);
        
        // 生成测试数据
        uint256[] memory values = new uint256[](batchSize * 2);
        uint8[] memory operations = new uint8[](batchSize);
        
        for (uint256 i = 0; i < batchSize; i++) {
            // 为每个操作生成两个操作数
            uint256 baseIndex = i * 2;
            uint8 op = uint8(i % 4);
            
            if (op == 1) { // 减法操作，确保第一个操作数大于第二个
                values[baseIndex] = (i + 10) * 10;     // 较大的数
                values[baseIndex + 1] = (i + 1) * 5;   // 较小的数
            } else if (op == 3) { // 除法操作，确保第二个操作数不为0
                values[baseIndex] = (i + 1) * 20;
                values[baseIndex + 1] = (i % 9) + 1;   // 1-9之间的数
            } else {
                values[baseIndex] = (i + 1) * 10;
                values[baseIndex + 1] = (i + 1) * 5;
            }
            
            operations[i] = op;
        }
        
        // 测试各个计算器
        uint256 baseGas = _measureBatchOperationBase(baseCalculator, values, operations);
        uint256 storageGas = _measureBatchOperationStorage(storageCalculator, values, operations);
        uint256 computationGas = _measureBatchOperationComputation(computationCalculator, values, operations);
        uint256 functionGas = _measureBatchOperationFunction(functionCalculator, values, operations);
        
        // 输出结果
        emit log_named_uint("Base Batch Gas", baseGas);
        emit log_named_uint("Storage Batch Gas", storageGas);
        emit log_named_uint("Computation Batch Gas", computationGas);
        emit log_named_uint("Function Batch Gas", functionGas);
        
        // 计算平均每操作gas
        emit log_named_uint("Base Avg Gas/Op", baseGas / batchSize);
        emit log_named_uint("Storage Avg Gas/Op", storageGas / batchSize);
        emit log_named_uint("Computation Avg Gas/Op", computationGas / batchSize);
        emit log_named_uint("Function Avg Gas/Op", functionGas / batchSize);
        
        emit log_string("---");
    }
    
    function _benchmarkChainedOperations() internal {
        emit log_string("Testing Chained Operations");
        
        uint256[] memory values = new uint256[](5);
        uint8[] memory operations = new uint8[](5);
        
        values[0] = 10;
        values[1] = 20;
        values[2] = 5;
        values[3] = 2;
        values[4] = 3;
        
        operations[0] = 0; // ADD
        operations[1] = 1; // SUBTRACT
        operations[2] = 2; // MULTIPLY
        operations[3] = 3; // DIVIDE
        operations[4] = 0; // ADD
        
        // 只测试支持链式操作的计算器
        uint256 gasBefore = gasleft();
        uint256 result = computationCalculator.chainedBatchCalculate(100, values, operations);
        uint256 gasUsed = gasBefore - gasleft();
        
        emit log_named_uint("Chained Operation Result", result);
        emit log_named_uint("Chained Operation Gas", gasUsed);
        
        assertGt(result, 0, "Chained operation should produce result");
    }
    
    function _benchmarkRepeatedOperations() internal {
        emit log_string("Testing Repeated Operations (Cache Effect)");
        
        // 重复相同操作以测试缓存效果
        uint256 totalGas = 0;
        uint256 iterations = 10;
        
        for (uint256 i = 0; i < iterations; i++) {
            uint256 gasBefore = gasleft();
            computationCalculator.add(100, 200);
            totalGas += gasBefore - gasleft();
        }
        
        emit log_named_uint("Total Gas for Repeated Ops", totalGas);
        emit log_named_uint("Average Gas per Repeated Op", totalGas / iterations);
    }
    
    function _benchmarkMixedOperations() internal {
        emit log_string("Testing Mixed Operations");
        
        uint256 totalGas = 0;
        uint256 gasBefore;
        
        // 混合不同类型的操作
        gasBefore = gasleft();
        baseCalculator.add(100, 50);
        totalGas += gasBefore - gasleft();
        
        gasBefore = gasleft();
        baseCalculator.multiply(10, 5);
        totalGas += gasBefore - gasleft();
        
        gasBefore = gasleft();
        baseCalculator.divide(100, 4);
        totalGas += gasBefore - gasleft();
        
        gasBefore = gasleft();
        baseCalculator.subtract(200, 75);
        totalGas += gasBefore - gasleft();
        
        emit log_named_uint("Mixed Operations Total Gas", totalGas);
        emit log_named_uint("Mixed Operations Avg Gas", totalGas / 4);
    }
    
    function _benchmarkStorageOperations() internal {
        emit log_string("Testing Storage Operations");
        
        // 测试存储读写密集操作
        uint256 gasBefore = gasleft();
        
        // 执行多次操作以触发存储读写
        for (uint256 i = 0; i < 5; i++) {
            storageCalculator.add(i * 10, i * 5);
        }
        
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("Storage Operations Gas", gasUsed);
    }
    
    function _benchmarkMemoryUsage() internal {
        emit log_string("Testing Memory Usage");
        
        // 创建大数组以测试内存使用
        uint256[] memory largeArray = new uint256[](100);
        uint8[] memory operations = new uint8[](50);
        
        for (uint256 i = 0; i < 50; i++) {
            uint256 baseIndex = i * 2;
            uint8 op = uint8(i % 4);
            
            if (op == 1) { // 减法操作，确保第一个操作数大于第二个
                largeArray[baseIndex] = (i + 10) * 10;
                largeArray[baseIndex + 1] = (i + 1) * 5;
            } else if (op == 3) { // 除法操作，确保第二个操作数不为0
                largeArray[baseIndex] = (i + 1) * 20;
                largeArray[baseIndex + 1] = (i % 9) + 1;
            } else {
                largeArray[baseIndex] = (i + 1) * 10;
                largeArray[baseIndex + 1] = (i + 1) * 5;
            }
            
            operations[i] = op;
        }
        
        uint256 gasBefore = gasleft();
        baseCalculator.batchCalculate(largeArray, operations);
        uint256 gasUsed = gasBefore - gasleft();
        
        emit log_named_uint("Large Array Operation Gas", gasUsed);
    }
    
    function _benchmarkBoundaryOperation(uint256 a, uint256 b, OperationType opType) internal {
        string memory opName = _getOperationName(opType);
        emit log_named_string("Testing Boundary", opName);
        
        uint256 gasBefore = gasleft();
        
        if (opType == OperationType.ADD) {
            try baseCalculator.add(a, b) {
                // Success
            } catch {
                // Handle overflow
            }
        } else if (opType == OperationType.SUBTRACT) {
            try baseCalculator.subtract(a, b) {
                // Success
            } catch {
                // Handle underflow
            }
        }
        
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("Boundary Operation Gas", gasUsed);
    }
    
    function _benchmarkStressTest(uint256 iterations) internal {
        emit log_named_uint("Stress Test Iterations", iterations);
        
        uint256 totalGas = 0;
        
        for (uint256 i = 0; i < iterations; i++) {
            uint256 gasBefore = gasleft();
            baseCalculator.add(i, i + 1);
            totalGas += gasBefore - gasleft();
        }
        
        emit log_named_uint("Stress Test Total Gas", totalGas);
        emit log_named_uint("Stress Test Avg Gas", totalGas / iterations);
    }
    
    function _generateOverallBenchmark(
        BaseCalculator calculator,
        string memory name
    ) internal returns (BenchmarkResult memory result) {
        emit log_named_string("Generating Overall Benchmark", name);
        
        // 基本操作测试
        result.basicOperationGas = _measureBasicOperationBase(calculator, OperationType.ADD, 100, 50);
        
        // 批量操作测试
        uint256[] memory values = new uint256[](10);
        uint8[] memory operations = new uint8[](5);
        for (uint256 i = 0; i < 5; i++) {
            uint256 baseIndex = i * 2;
            uint8 op = uint8(i % 4);
            
            if (op == 1) { // 减法操作
                values[baseIndex] = (i + 10) * 10;
                values[baseIndex + 1] = (i + 1) * 5;
            } else if (op == 3) { // 除法操作
                values[baseIndex] = (i + 1) * 20;
                values[baseIndex + 1] = (i % 9) + 1;
            } else {
                values[baseIndex] = (i + 1) * 10;
                values[baseIndex + 1] = (i + 1) * 5;
            }
            
            operations[i] = op;
        }
        result.batchOperationGas = _measureBatchOperationBase(calculator, values, operations);
        
        // 复杂操作测试
        result.complexOperationGas = _measureComplexOperationBase(calculator);
        
        result.success = true;
    }
    
    function _generateOverallBenchmarkStorage(
        StorageOptimizedCalculator calculator,
        string memory name
    ) internal returns (BenchmarkResult memory result) {
        emit log_named_string("Generating Overall Benchmark", name);
        
        result.basicOperationGas = _measureBasicOperationStorage(calculator, OperationType.ADD, 100, 50);
        
        uint256[] memory values = new uint256[](10);
        uint8[] memory operations = new uint8[](5);
        for (uint256 i = 0; i < 5; i++) {
            uint256 baseIndex = i * 2;
            uint8 op = uint8(i % 4);
            
            if (op == 1) { // 减法操作
                values[baseIndex] = (i + 10) * 10;
                values[baseIndex + 1] = (i + 1) * 5;
            } else if (op == 3) { // 除法操作
                values[baseIndex] = (i + 1) * 20;
                values[baseIndex + 1] = (i % 9) + 1;
            } else {
                values[baseIndex] = (i + 1) * 10;
                values[baseIndex + 1] = (i + 1) * 5;
            }
            
            operations[i] = op;
        }
        result.batchOperationGas = _measureBatchOperationStorage(calculator, values, operations);
        
        result.complexOperationGas = _measureComplexOperationStorage(calculator);
        result.success = true;
    }
    
    function _generateOverallBenchmarkComputation(
        ComputationOptimizedCalculator calculator,
        string memory name
    ) internal returns (BenchmarkResult memory result) {
        emit log_named_string("Generating Overall Benchmark", name);
        
        result.basicOperationGas = _measureBasicOperationComputation(calculator, OperationType.ADD, 100, 50);
        
        uint256[] memory values = new uint256[](10);
        uint8[] memory operations = new uint8[](5);
        for (uint256 i = 0; i < 5; i++) {
            uint256 baseIndex = i * 2;
            uint8 op = uint8(i % 4);
            
            if (op == 1) { // 减法操作
                values[baseIndex] = (i + 10) * 10;
                values[baseIndex + 1] = (i + 1) * 5;
            } else if (op == 3) { // 除法操作
                values[baseIndex] = (i + 1) * 20;
                values[baseIndex + 1] = (i % 9) + 1;
            } else {
                values[baseIndex] = (i + 1) * 10;
                values[baseIndex + 1] = (i + 1) * 5;
            }
            
            operations[i] = op;
        }
        result.batchOperationGas = _measureBatchOperationComputation(calculator, values, operations);
        
        result.complexOperationGas = _measureComplexOperationComputation(calculator);
        result.success = true;
    }
    
    function _generateOverallBenchmarkFunction(
        FunctionOptimizedCalculator calculator,
        string memory name
    ) internal returns (BenchmarkResult memory result) {
        emit log_named_string("Generating Overall Benchmark", name);
        
        result.basicOperationGas = _measureBasicOperationFunction(calculator, OperationType.ADD, 100, 50);
        
        uint256[] memory values = new uint256[](10);
        uint8[] memory operations = new uint8[](5);
        for (uint256 i = 0; i < 5; i++) {
            uint256 baseIndex = i * 2;
            uint8 op = uint8(i % 4);
            
            if (op == 1) { // 减法操作
                values[baseIndex] = (i + 10) * 10;
                values[baseIndex + 1] = (i + 1) * 5;
            } else if (op == 3) { // 除法操作
                values[baseIndex] = (i + 1) * 20;
                values[baseIndex + 1] = (i % 9) + 1;
            } else {
                values[baseIndex] = (i + 1) * 10;
                values[baseIndex + 1] = (i + 1) * 5;
            }
            
            operations[i] = op;
        }
        result.batchOperationGas = _measureBatchOperationFunction(calculator, values, operations);
        
        result.complexOperationGas = _measureComplexOperationFunction(calculator);
        result.success = true;
    }
    
    // 测量函数
    function _measureBasicOperationBase(
        BaseCalculator calculator,
        OperationType opType,
        uint256 a,
        uint256 b
    ) internal returns (uint256 gasUsed) {
        uint256 gasBefore = gasleft();
        
        if (opType == OperationType.ADD) {
            calculator.add(a, b);
        } else if (opType == OperationType.SUBTRACT) {
            calculator.subtract(a, b);
        } else if (opType == OperationType.MULTIPLY) {
            calculator.multiply(a, b);
        } else if (opType == OperationType.DIVIDE) {
            calculator.divide(a, b);
        }
        
        gasUsed = gasBefore - gasleft();
    }
    
    function _measureBasicOperationStorage(
        StorageOptimizedCalculator calculator,
        OperationType opType,
        uint256 a,
        uint256 b
    ) internal returns (uint256 gasUsed) {
        uint256 gasBefore = gasleft();
        
        if (opType == OperationType.ADD) {
            calculator.add(a, b);
        } else if (opType == OperationType.SUBTRACT) {
            calculator.subtract(a, b);
        } else if (opType == OperationType.MULTIPLY) {
            calculator.multiply(a, b);
        } else if (opType == OperationType.DIVIDE) {
            calculator.divide(a, b);
        }
        
        gasUsed = gasBefore - gasleft();
    }
    
    function _measureBasicOperationComputation(
        ComputationOptimizedCalculator calculator,
        OperationType opType,
        uint256 a,
        uint256 b
    ) internal returns (uint256 gasUsed) {
        uint256 gasBefore = gasleft();
        
        if (opType == OperationType.ADD) {
            calculator.add(a, b);
        } else if (opType == OperationType.SUBTRACT) {
            calculator.subtract(a, b);
        } else if (opType == OperationType.MULTIPLY) {
            calculator.multiply(a, b);
        } else if (opType == OperationType.DIVIDE) {
            calculator.divide(a, b);
        }
        
        gasUsed = gasBefore - gasleft();
    }
    
    function _measureBasicOperationFunction(
        FunctionOptimizedCalculator calculator,
        OperationType opType,
        uint256 a,
        uint256 b
    ) internal returns (uint256 gasUsed) {
        uint256 gasBefore = gasleft();
        
        if (opType == OperationType.ADD) {
            calculator.add(a, b);
        } else if (opType == OperationType.SUBTRACT) {
            calculator.subtract(a, b);
        } else if (opType == OperationType.MULTIPLY) {
            calculator.multiply(a, b);
        } else if (opType == OperationType.DIVIDE) {
            calculator.divide(a, b);
        }
        
        gasUsed = gasBefore - gasleft();
    }
    
    function _measureBatchOperationBase(
        BaseCalculator calculator,
        uint256[] memory values,
        uint8[] memory operations
    ) internal returns (uint256 gasUsed) {
        uint256 gasBefore = gasleft();
        calculator.batchCalculate(values, operations);
        gasUsed = gasBefore - gasleft();
    }
    
    function _measureBatchOperationStorage(
        StorageOptimizedCalculator calculator,
        uint256[] memory values,
        uint8[] memory operations
    ) internal returns (uint256 gasUsed) {
        uint256 gasBefore = gasleft();
        calculator.batchCalculate(values, operations);
        gasUsed = gasBefore - gasleft();
    }
    
    function _measureBatchOperationComputation(
        ComputationOptimizedCalculator calculator,
        uint256[] memory values,
        uint8[] memory operations
    ) internal returns (uint256 gasUsed) {
        uint256 gasBefore = gasleft();
        calculator.batchCalculate(values, operations);
        gasUsed = gasBefore - gasleft();
    }
    
    function _measureBatchOperationFunction(
        FunctionOptimizedCalculator calculator,
        uint256[] memory values,
        uint8[] memory operations
    ) internal returns (uint256 gasUsed) {
        uint256 gasBefore = gasleft();
        calculator.batchCalculate(values, operations);
        gasUsed = gasBefore - gasleft();
    }
    
    function _measureComplexOperationBase(BaseCalculator calculator) internal returns (uint256 gasUsed) {
        uint256 gasBefore = gasleft();
        
        // 执行一系列复杂操作
        uint256 result1 = calculator.add(100, 200);
        uint256 result2 = calculator.multiply(result1, 2);
        calculator.divide(result2, 3);
        
        gasUsed = gasBefore - gasleft();
    }
    
    function _measureComplexOperationStorage(StorageOptimizedCalculator calculator) internal returns (uint256 gasUsed) {
        uint256 gasBefore = gasleft();
        
        uint256 result1 = calculator.add(100, 200);
        uint256 result2 = calculator.multiply(result1, 2);
        calculator.divide(result2, 3);
        
        gasUsed = gasBefore - gasleft();
    }
    
    function _measureComplexOperationComputation(ComputationOptimizedCalculator calculator) internal returns (uint256 gasUsed) {
        uint256 gasBefore = gasleft();
        
        uint256 result1 = calculator.add(100, 200);
        uint256 result2 = calculator.multiply(result1, 2);
        calculator.divide(result2, 3);
        
        gasUsed = gasBefore - gasleft();
    }
    
    function _measureComplexOperationFunction(FunctionOptimizedCalculator calculator) internal returns (uint256 gasUsed) {
        uint256 gasBefore = gasleft();
        
        uint256 result1 = calculator.add(100, 200);
        uint256 result2 = calculator.multiply(result1, 2);
        calculator.divide(result2, 3);
        
        gasUsed = gasBefore - gasleft();
    }
    
    function _logOverallComparison(
        BenchmarkResult memory baseResult,
        BenchmarkResult memory storageResult,
        BenchmarkResult memory computationResult,
        BenchmarkResult memory functionResult
    ) internal {
        emit log_string("=== Overall Performance Comparison ===");
        
        emit log_string("Basic Operations:");
        emit log_named_uint("Base", baseResult.basicOperationGas);
        emit log_named_uint("Storage", storageResult.basicOperationGas);
        emit log_named_uint("Computation", computationResult.basicOperationGas);
        emit log_named_uint("Function", functionResult.basicOperationGas);
        
        emit log_string("Batch Operations:");
        emit log_named_uint("Base", baseResult.batchOperationGas);
        emit log_named_uint("Storage", storageResult.batchOperationGas);
        emit log_named_uint("Computation", computationResult.batchOperationGas);
        emit log_named_uint("Function", functionResult.batchOperationGas);
        
        emit log_string("Complex Operations:");
        emit log_named_uint("Base", baseResult.complexOperationGas);
        emit log_named_uint("Storage", storageResult.complexOperationGas);
        emit log_named_uint("Computation", computationResult.complexOperationGas);
        emit log_named_uint("Function", functionResult.complexOperationGas);
    }
    
    function _determineOptimalImplementation(
        BenchmarkResult memory baseResult,
        BenchmarkResult memory storageResult,
        BenchmarkResult memory computationResult,
        BenchmarkResult memory functionResult
    ) internal {
        emit log_string("=== Optimal Implementation Analysis ===");
        
        // 计算总分数（越低越好）
        uint256 baseScore = baseResult.basicOperationGas + baseResult.batchOperationGas + baseResult.complexOperationGas;
        uint256 storageScore = storageResult.basicOperationGas + storageResult.batchOperationGas + storageResult.complexOperationGas;
        uint256 computationScore = computationResult.basicOperationGas + computationResult.batchOperationGas + computationResult.complexOperationGas;
        uint256 functionScore = functionResult.basicOperationGas + functionResult.batchOperationGas + functionResult.complexOperationGas;
        
        emit log_named_uint("Base Total Score", baseScore);
        emit log_named_uint("Storage Total Score", storageScore);
        emit log_named_uint("Computation Total Score", computationScore);
        emit log_named_uint("Function Total Score", functionScore);
        
        // 确定最优实现
        string memory optimal = "Base";
        uint256 bestScore = baseScore;
        
        if (storageScore < bestScore) {
            optimal = "Storage";
            bestScore = storageScore;
        }
        if (computationScore < bestScore) {
            optimal = "Computation";
            bestScore = computationScore;
        }
        if (functionScore < bestScore) {
            optimal = "Function";
            bestScore = functionScore;
        }
        
        emit log_named_string("Optimal Implementation", optimal);
        emit log_named_uint("Best Score", bestScore);
    }
    
    function _getOperationName(OperationType opType) internal pure returns (string memory) {
        if (opType == OperationType.ADD) return "ADD";
        if (opType == OperationType.SUBTRACT) return "SUBTRACT";
        if (opType == OperationType.MULTIPLY) return "MULTIPLY";
        if (opType == OperationType.DIVIDE) return "DIVIDE";
        return "UNKNOWN";
    }
    
    function _logSavingsPercentage(string memory label, uint256 baseline, uint256 optimized) internal {
        if (baseline > optimized) {
            uint256 savings = ((baseline - optimized) * 100) / baseline;
            emit log_named_string("Savings", label);
            emit log_named_uint("Percentage", savings);
        } else if (optimized > baseline) {
            uint256 increase = ((optimized - baseline) * 100) / baseline;
            emit log_named_string("Increase", label);
            emit log_named_uint("Percentage", increase);
        } else {
            emit log_named_string("No Change", label);
        }
    }
}
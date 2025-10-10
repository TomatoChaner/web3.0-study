// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/BaseCalculator.sol";
import "../src/StorageOptimizedCalculator.sol";
import "../src/ComputationOptimizedCalculator.sol";
import "../src/FunctionOptimizedCalculator.sol";
import "../src/utils/GasTracker.sol";

/**
 * @title GasComparisonTest
 * @dev Gas消耗对比测试，比较不同优化策略的效果
 */
contract GasComparisonTest is Test {
    BaseCalculator public baseCalculator;
    StorageOptimizedCalculator public storageCalculator;
    ComputationOptimizedCalculator public computationCalculator;
    FunctionOptimizedCalculator public functionCalculator;
    GasTracker public gasTracker;

    // Gas测量结果结构
    struct GasResult {
        uint256 baseGas;
        uint256 storageGas;
        uint256 computationGas;
        uint256 functionGas;
    }

    // 综合性能测试结果结构
    struct OverallResult {
        uint256 totalGas;
        uint256 avgGas;
    }

    function setUp() public {
        baseCalculator = new BaseCalculator();
        storageCalculator = new StorageOptimizedCalculator();
        computationCalculator = new ComputationOptimizedCalculator();
        functionCalculator = new FunctionOptimizedCalculator();
        gasTracker = new GasTracker();
    }

    // ============ 基础运算Gas对比 ============

    function testAdditionGasComparison() public {
        uint256 a = 100;
        uint256 b = 200;

        GasResult memory result;

        // 基础计算器
        uint256 gasBefore = gasleft();
        baseCalculator.add(a, b);
        result.baseGas = gasBefore - gasleft();

        // 存储优化计算器
        gasBefore = gasleft();
        storageCalculator.add(a, b);
        result.storageGas = gasBefore - gasleft();

        // 计算优化计算器
        gasBefore = gasleft();
        computationCalculator.add(a, b);
        result.computationGas = gasBefore - gasleft();

        // 函数优化计算器
        gasBefore = gasleft();
        functionCalculator.add(a, b);
        result.functionGas = gasBefore - gasleft();

        // 输出结果
        emit log_named_uint("Base Calculator add() gas", result.baseGas);
        emit log_named_uint("Storage Optimized add() gas", result.storageGas);
        emit log_named_uint(
            "Computation Optimized add() gas",
            result.computationGas
        );
        emit log_named_uint("Function Optimized add() gas", result.functionGas);

        // 计算节省百分比
        _logSavingsPercentage(
            "Storage vs Base",
            result.baseGas,
            result.storageGas
        );
        _logSavingsPercentage(
            "Computation vs Base",
            result.baseGas,
            result.computationGas
        );
        _logSavingsPercentage(
            "Function vs Base",
            result.baseGas,
            result.functionGas
        );
    }

    function testSubtractionGasComparison() public {
        uint256 a = 500;
        uint256 b = 200;

        GasResult memory result;

        // 基础计算器
        uint256 gasBefore = gasleft();
        baseCalculator.subtract(a, b);
        result.baseGas = gasBefore - gasleft();

        // 存储优化计算器
        gasBefore = gasleft();
        storageCalculator.subtract(a, b);
        result.storageGas = gasBefore - gasleft();

        // 计算优化计算器
        gasBefore = gasleft();
        computationCalculator.subtract(a, b);
        result.computationGas = gasBefore - gasleft();

        // 函数优化计算器
        gasBefore = gasleft();
        functionCalculator.subtract(a, b);
        result.functionGas = gasBefore - gasleft();

        // 输出结果
        emit log_named_uint("Base Calculator subtract() gas", result.baseGas);
        emit log_named_uint(
            "Storage Optimized subtract() gas",
            result.storageGas
        );
        emit log_named_uint(
            "Computation Optimized subtract() gas",
            result.computationGas
        );
        emit log_named_uint(
            "Function Optimized subtract() gas",
            result.functionGas
        );

        // 计算节省百分比
        _logSavingsPercentage(
            "Storage vs Base",
            result.baseGas,
            result.storageGas
        );
        _logSavingsPercentage(
            "Computation vs Base",
            result.baseGas,
            result.computationGas
        );
        _logSavingsPercentage(
            "Function vs Base",
            result.baseGas,
            result.functionGas
        );
    }

    function testMultiplicationGasComparison() public {
        uint256 a = 25;
        uint256 b = 40;

        GasResult memory result;

        // 基础计算器
        uint256 gasBefore = gasleft();
        baseCalculator.multiply(a, b);
        result.baseGas = gasBefore - gasleft();

        // 存储优化计算器
        gasBefore = gasleft();
        storageCalculator.multiply(a, b);
        result.storageGas = gasBefore - gasleft();

        // 计算优化计算器
        gasBefore = gasleft();
        computationCalculator.multiply(a, b);
        result.computationGas = gasBefore - gasleft();

        // 函数优化计算器
        gasBefore = gasleft();
        functionCalculator.multiply(a, b);
        result.functionGas = gasBefore - gasleft();

        // 输出结果
        emit log_named_uint("Base Calculator multiply() gas", result.baseGas);
        emit log_named_uint(
            "Storage Optimized multiply() gas",
            result.storageGas
        );
        emit log_named_uint(
            "Computation Optimized multiply() gas",
            result.computationGas
        );
        emit log_named_uint(
            "Function Optimized multiply() gas",
            result.functionGas
        );

        // 计算节省百分比
        _logSavingsPercentage(
            "Storage vs Base",
            result.baseGas,
            result.storageGas
        );
        _logSavingsPercentage(
            "Computation vs Base",
            result.baseGas,
            result.computationGas
        );
        _logSavingsPercentage(
            "Function vs Base",
            result.baseGas,
            result.functionGas
        );
    }

    function testDivisionGasComparison() public {
        uint256 a = 1000;
        uint256 b = 25;

        GasResult memory result;

        // 基础计算器
        uint256 gasBefore = gasleft();
        baseCalculator.divide(a, b);
        result.baseGas = gasBefore - gasleft();

        // 存储优化计算器
        gasBefore = gasleft();
        storageCalculator.divide(a, b);
        result.storageGas = gasBefore - gasleft();

        // 计算优化计算器
        gasBefore = gasleft();
        computationCalculator.divide(a, b);
        result.computationGas = gasBefore - gasleft();

        // 函数优化计算器
        gasBefore = gasleft();
        functionCalculator.divide(a, b);
        result.functionGas = gasBefore - gasleft();

        // 输出结果
        emit log_named_uint("Base Calculator divide() gas", result.baseGas);
        emit log_named_uint(
            "Storage Optimized divide() gas",
            result.storageGas
        );
        emit log_named_uint(
            "Computation Optimized divide() gas",
            result.computationGas
        );
        emit log_named_uint(
            "Function Optimized divide() gas",
            result.functionGas
        );

        // 计算节省百分比
        _logSavingsPercentage(
            "Storage vs Base",
            result.baseGas,
            result.storageGas
        );
        _logSavingsPercentage(
            "Computation vs Base",
            result.baseGas,
            result.computationGas
        );
        _logSavingsPercentage(
            "Function vs Base",
            result.baseGas,
            result.functionGas
        );
    }

    // ============ 批量操作Gas对比 ============

    function testBatchOperationGasComparison() public {
        uint256[] memory values = new uint256[](8);
        values[0] = 100;
        values[1] = 25;
        values[2] = 200;
        values[3] = 50;
        values[4] = 10;
        values[5] = 15;
        values[6] = 300;
        values[7] = 6;

        uint8[] memory operations = new uint8[](4);
        operations[0] = 0; // add
        operations[1] = 1; // subtract
        operations[2] = 2; // multiply
        operations[3] = 3; // divide

        GasResult memory result;

        // 基础计算器
        uint256 gasBefore = gasleft();
        baseCalculator.batchCalculate(values, operations);
        result.baseGas = gasBefore - gasleft();

        // 存储优化计算器
        gasBefore = gasleft();
        storageCalculator.batchCalculate(values, operations);
        result.storageGas = gasBefore - gasleft();

        // 计算优化计算器
        gasBefore = gasleft();
        computationCalculator.batchCalculate(values, operations);
        result.computationGas = gasBefore - gasleft();

        // 函数优化计算器
        gasBefore = gasleft();
        functionCalculator.batchCalculate(values, operations);
        result.functionGas = gasBefore - gasleft();

        // 输出结果
        emit log_named_uint(
            "Base Calculator batchCalculate() gas",
            result.baseGas
        );
        emit log_named_uint(
            "Storage Optimized batchCalculate() gas",
            result.storageGas
        );
        emit log_named_uint(
            "Computation Optimized batchCalculate() gas",
            result.computationGas
        );
        emit log_named_uint(
            "Function Optimized batchCalculate() gas",
            result.functionGas
        );

        // 计算节省百分比
        _logSavingsPercentage(
            "Storage vs Base (batch)",
            result.baseGas,
            result.storageGas
        );
        _logSavingsPercentage(
            "Computation vs Base (batch)",
            result.baseGas,
            result.computationGas
        );
        _logSavingsPercentage(
            "Function vs Base (batch)",
            result.baseGas,
            result.functionGas
        );
    }

    // ============ 缓存效果测试 ============

    function testCacheEffectComparison() public {
        uint256 a = 123;
        uint256 b = 456;

        // 计算优化计算器 - 第一次计算（无缓存）
        uint256 gasBefore = gasleft();
        computationCalculator.add(a, b);
        uint256 firstCallGas = gasBefore - gasleft();

        // 计算优化计算器 - 第二次计算（命中缓存）
        gasBefore = gasleft();
        computationCalculator.add(a, b);
        uint256 cachedCallGas = gasBefore - gasleft();

        // 基础计算器 - 作为对比
        gasBefore = gasleft();
        baseCalculator.add(a, b);
        uint256 baseCallGas = gasBefore - gasleft();

        emit log_named_uint("Base Calculator add() gas", baseCallGas);
        emit log_named_uint("Computation first add() gas", firstCallGas);
        emit log_named_uint("Computation cached add() gas", cachedCallGas);

        // 计算缓存节省
        uint256 cacheSavings = firstCallGas > cachedCallGas
            ? firstCallGas - cachedCallGas
            : 0;
        emit log_named_uint("Cache savings (gas)", cacheSavings);

        if (firstCallGas > 0) {
            uint256 cacheSavingsPercent = (cacheSavings * 100) / firstCallGas;
            emit log_named_uint("Cache savings (%)", cacheSavingsPercent);
        }
    }

    // ============ 特殊函数Gas对比 ============

    function testSpecialFunctionGasComparison() public {
        // 测试函数优化计算器的特殊函数
        uint256[] memory values = new uint256[](5);
        values[0] = 10;
        values[1] = 20;
        values[2] = 30;
        values[3] = 40;
        values[4] = 50;

        // fastAdd vs 普通add
        uint256 gasBefore = gasleft();
        functionCalculator.add(100, 200);
        uint256 normalAddGas = gasBefore - gasleft();

        gasBefore = gasleft();
        functionCalculator.fastAdd(100, 200);
        uint256 fastAddGas = gasBefore - gasleft();

        // inlineSum
        gasBefore = gasleft();
        functionCalculator.inlineSum(values);
        uint256 inlineSumGas = gasBefore - gasleft();

        // optimizedAverage
        gasBefore = gasleft();
        functionCalculator.optimizedAverage(values);
        uint256 optimizedAverageGas = gasBefore - gasleft();

        // optimizedPower
        gasBefore = gasleft();
        functionCalculator.optimizedPower(2, 10);
        uint256 optimizedPowerGas = gasBefore - gasleft();

        emit log_named_uint("Normal add() gas", normalAddGas);
        emit log_named_uint("Fast add() gas", fastAddGas);
        emit log_named_uint("Inline sum() gas", inlineSumGas);
        emit log_named_uint("Optimized average() gas", optimizedAverageGas);
        emit log_named_uint("Optimized power() gas", optimizedPowerGas);

        _logSavingsPercentage("FastAdd vs NormalAdd", normalAddGas, fastAddGas);
    }

    // ============ 重复操作Gas对比 ============

    function testRepeatedOperationGasComparison() public {
        uint256 iterations = 10;

        // 基础计算器 - 重复操作
        uint256 gasBefore = gasleft();
        for (uint256 i = 0; i < iterations; i++) {
            baseCalculator.add(i + 1, i + 2);
        }
        uint256 baseRepeatedGas = gasBefore - gasleft();

        // 计算优化计算器 - 重复操作（有缓存）
        gasBefore = gasleft();
        for (uint256 i = 0; i < iterations; i++) {
            computationCalculator.add(i + 1, i + 2);
        }
        uint256 computationRepeatedGas = gasBefore - gasleft();

        // 函数优化计算器 - 重复操作
        gasBefore = gasleft();
        for (uint256 i = 0; i < iterations; i++) {
            functionCalculator.add(i + 1, i + 2);
        }
        uint256 functionRepeatedGas = gasBefore - gasleft();

        emit log_named_uint("Base repeated operations gas", baseRepeatedGas);
        emit log_named_uint(
            "Computation repeated operations gas",
            computationRepeatedGas
        );
        emit log_named_uint(
            "Function repeated operations gas",
            functionRepeatedGas
        );

        _logSavingsPercentage(
            "Computation vs Base (repeated)",
            baseRepeatedGas,
            computationRepeatedGas
        );
        _logSavingsPercentage(
            "Function vs Base (repeated)",
            baseRepeatedGas,
            functionRepeatedGas
        );
    }

    // ============ 部署Gas对比 ============

    function testDeploymentGasComparison() public {
        uint256 gasBefore;
        uint256 deployGas;

        // 基础计算器部署Gas
        gasBefore = gasleft();
        new BaseCalculator();
        deployGas = gasBefore - gasleft();
        emit log_named_uint("Base Calculator deployment gas", deployGas);

        // 存储优化计算器部署Gas
        gasBefore = gasleft();
        new StorageOptimizedCalculator();
        deployGas = gasBefore - gasleft();
        emit log_named_uint("Storage Optimized deployment gas", deployGas);

        // 计算优化计算器部署Gas
        gasBefore = gasleft();
        new ComputationOptimizedCalculator();
        deployGas = gasBefore - gasleft();
        emit log_named_uint("Computation Optimized deployment gas", deployGas);

        // 函数优化计算器部署Gas
        gasBefore = gasleft();
        new FunctionOptimizedCalculator();
        deployGas = gasBefore - gasleft();
        emit log_named_uint("Function Optimized deployment gas", deployGas);
    }

    // ============ 综合性能测试 ============

    function testOverallPerformanceComparison() public {
        uint256 testOperations = 5;

        OverallResult memory baseResult;
        OverallResult memory storageResult;
        OverallResult memory computationResult;
        OverallResult memory functionResult;

        // 基础计算器综合测试
        uint256 gasBefore = gasleft();
        baseCalculator.add(100, 200);
        baseCalculator.subtract(500, 200);
        baseCalculator.multiply(25, 4);
        baseCalculator.divide(1000, 25);
        uint256[] memory values = new uint256[](4);
        values[0] = 10; values[1] = 20; values[2] = 50; values[3] = 30;
        uint8[] memory ops = new uint8[](2);
        ops[0] = 0; ops[1] = 1;
        baseCalculator.batchCalculate(values, ops);
        baseResult.totalGas = gasBefore - gasleft();
        baseResult.avgGas = baseResult.totalGas / testOperations;

        // 存储优化计算器综合测试
        gasBefore = gasleft();
        storageCalculator.add(100, 200);
        storageCalculator.subtract(500, 200);
        storageCalculator.multiply(25, 4);
        storageCalculator.divide(1000, 25);
        storageCalculator.batchCalculate(values, ops);
        storageResult.totalGas = gasBefore - gasleft();
        storageResult.avgGas = storageResult.totalGas / testOperations;

        // 计算优化计算器综合测试
        gasBefore = gasleft();
        computationCalculator.add(100, 200);
        computationCalculator.subtract(500, 200);
        computationCalculator.multiply(25, 4);
        computationCalculator.divide(1000, 25);
        computationCalculator.batchCalculate(values, ops);
        computationResult.totalGas = gasBefore - gasleft();
        computationResult.avgGas = computationResult.totalGas / testOperations;

        // 函数优化计算器综合测试
        gasBefore = gasleft();
        functionCalculator.add(100, 200);
        functionCalculator.subtract(500, 200);
        functionCalculator.multiply(25, 4);
        functionCalculator.divide(1000, 25);
        functionCalculator.batchCalculate(values, ops);
        functionResult.totalGas = gasBefore - gasleft();
        functionResult.avgGas = functionResult.totalGas / testOperations;

        // 输出综合结果
        emit log_string("=== Overall Performance Comparison ===");
        emit log_named_uint("Base total gas", baseResult.totalGas);
        emit log_named_uint("Storage total gas", storageResult.totalGas);
        emit log_named_uint(
            "Computation total gas",
            computationResult.totalGas
        );
        emit log_named_uint("Function total gas", functionResult.totalGas);

        emit log_named_uint("Base avg gas", baseResult.avgGas);
        emit log_named_uint("Storage avg gas", storageResult.avgGas);
        emit log_named_uint("Computation avg gas", computationResult.avgGas);
        emit log_named_uint("Function avg gas", functionResult.avgGas);

        // 计算总体节省
        _logSavingsPercentage(
            "Storage vs Base (overall)",
            baseResult.totalGas,
            storageResult.totalGas
        );
        _logSavingsPercentage(
            "Computation vs Base (overall)",
            baseResult.totalGas,
            computationResult.totalGas
        );
        _logSavingsPercentage(
            "Function vs Base (overall)",
            baseResult.totalGas,
            functionResult.totalGas
        );
    }

    // ============ 辅助函数 ============

    function _logSavingsPercentage(
        string memory label,
        uint256 baseGas,
        uint256 optimizedGas
    ) internal {
        if (baseGas > 0) {
            if (optimizedGas < baseGas) {
                uint256 savings = baseGas - optimizedGas;
                uint256 savingsPercent = (savings * 100) / baseGas;
                emit log_named_string("Comparison", label);
                emit log_named_uint("Gas saved", savings);
                emit log_named_uint("Savings %", savingsPercent);
            } else if (optimizedGas > baseGas) {
                uint256 increase = optimizedGas - baseGas;
                uint256 increasePercent = (increase * 100) / baseGas;
                emit log_named_string("Comparison", label);
                emit log_named_uint("Gas increased", increase);
                emit log_named_uint("Increase %", increasePercent);
            } else {
                emit log_named_string("Comparison", label);
                emit log_string("Gas usage identical");
            }
        }
        emit log_string("---");
    }

    // ============ 使用GasTracker的高级对比 ============

    function testAdvancedGasComparison() public {
        // 使用GasTracker进行更精确的Gas测量
        (bool success1, uint256 baseGas, ) = gasTracker.measureCall(
            address(baseCalculator),
            abi.encodeWithSelector(BaseCalculator.add.selector, 100, 200),
            "Base Calculator add()"
        );
        require(success1, "Base calculator call failed");

        (bool success2, uint256 storageGas, ) = gasTracker.measureCall(
            address(storageCalculator),
            abi.encodeWithSelector(
                StorageOptimizedCalculator.add.selector,
                100,
                200
            ),
            "Storage Optimized add()"
        );
        require(success2, "Storage calculator call failed");

        (bool success3, uint256 computationGas, ) = gasTracker.measureCall(
            address(computationCalculator),
            abi.encodeWithSelector(
                ComputationOptimizedCalculator.add.selector,
                100,
                200
            ),
            "Computation Optimized add()"
        );
        require(success3, "Computation calculator call failed");

        (bool success4, uint256 functionGas, ) = gasTracker.measureCall(
            address(functionCalculator),
            abi.encodeWithSelector(
                FunctionOptimizedCalculator.add.selector,
                100,
                200
            ),
            "Function Optimized add()"
        );
        require(success4, "Function calculator call failed");

        // 直接计算节省
        emit log_named_uint("Base Calculator gas", baseGas);
        emit log_named_uint("Storage Optimized gas", storageGas);
        emit log_named_uint("Computation Optimized gas", computationGas);
        emit log_named_uint("Function Optimized gas", functionGas);

        // 计算节省百分比
        _logSavingsPercentage(
            "Storage vs Base (advanced)",
            baseGas,
            storageGas
        );
        _logSavingsPercentage(
            "Computation vs Base (advanced)",
            baseGas,
            computationGas
        );
        _logSavingsPercentage(
            "Function vs Base (advanced)",
            baseGas,
            functionGas
        );
    }
}

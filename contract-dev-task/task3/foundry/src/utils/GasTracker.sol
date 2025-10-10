// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title GasTracker
 * @dev Gas消耗追踪和分析工具合约
 * @notice 用于精确测量和比较不同合约的Gas消耗
 * @author Gas Optimization Study Project
 */
contract GasTracker {
    // ============ Structs ============
    
    /**
     * @dev Gas测量结果结构体
     */
    struct GasMeasurement {
        uint256 gasUsed;        // 消耗的Gas
        uint256 timestamp;      // 测量时间戳
        address caller;         // 调用者地址
        string operation;       // 操作名称
        bytes32 dataHash;       // 输入数据哈希
    }

    /**
     * @dev Gas比较结果结构体
     */
    struct GasComparison {
        uint256 baseGas;        // 基础合约Gas消耗
        uint256 optimizedGas;   // 优化合约Gas消耗
        uint256 savings;        // 节省的Gas
        uint256 savingsPercent; // 节省百分比 (乘以100)
        string optimizationType; // 优化类型
    }

    /**
     * @dev 批量测试结果结构体
     */
    struct BatchTestResult {
        uint256 totalOperations;   // 总操作数
        uint256 totalGasUsed;      // 总Gas消耗
        uint256 averageGasPerOp;   // 平均每次操作Gas消耗
        uint256 minGasUsed;        // 最小Gas消耗
        uint256 maxGasUsed;        // 最大Gas消耗
        string testName;           // 测试名称
    }

    // ============ State Variables ============
    
    /// @dev 合约所有者
    address public owner;
    
    /// @dev Gas测量记录
    mapping(bytes32 => GasMeasurement) public gasMeasurements;
    
    /// @dev 测试ID计数器
    uint256 public testIdCounter;
    
    /// @dev 测试ID到测量ID的映射
    mapping(uint256 => bytes32[]) internal testMeasurements;
    
    /// @dev 批量测试结果
    mapping(uint256 => BatchTestResult) public batchResults;
    
    /// @dev 比较结果存储
    mapping(bytes32 => GasComparison) public comparisons;

    // ============ Events ============
    
    /**
     * @dev Gas测量完成事件
     */
    event GasMeasured(
        bytes32 indexed measurementId,
        address indexed caller,
        string operation,
        uint256 gasUsed,
        uint256 timestamp
    );

    /**
     * @dev Gas比较完成事件
     */
    event GasCompared(
        bytes32 indexed comparisonId,
        string optimizationType,
        uint256 baseGas,
        uint256 optimizedGas,
        uint256 savings,
        uint256 savingsPercent
    );

    /**
     * @dev 批量测试完成事件
     */
    event BatchTestCompleted(
        uint256 indexed testId,
        string testName,
        uint256 totalOperations,
        uint256 totalGasUsed,
        uint256 averageGasPerOp
    );

    // ============ Constructor ============
    
    constructor() {
        owner = msg.sender;
        testIdCounter = 0;
    }

    // ============ Modifiers ============
    
    modifier onlyOwner() {
        require(msg.sender == owner, "GasTracker: caller is not the owner");
        _;
    }

    // ============ Gas Measurement Functions ============
    
    /**
     * @dev 开始Gas测量
     * @return startGas 开始时的Gas量
     */
    function startMeasurement() external view returns (uint256 startGas) {
        return gasleft();
    }

    /**
     * @dev 结束Gas测量并记录结果
     * @param startGas 开始时的Gas量
     * @param operation 操作名称
     * @param inputData 输入数据
     * @return measurementId 测量ID
     * @return gasUsed 消耗的Gas
     */
    function endMeasurement(
        uint256 startGas,
        string calldata operation,
        bytes calldata inputData
    ) external returns (bytes32 measurementId, uint256 gasUsed) {
        gasUsed = startGas - gasleft();
        bytes32 dataHash = keccak256(inputData);
        
        measurementId = keccak256(abi.encodePacked(
            msg.sender,
            operation,
            dataHash,
            block.timestamp,
            gasUsed
        ));
        
        gasMeasurements[measurementId] = GasMeasurement({
            gasUsed: gasUsed,
            timestamp: block.timestamp,
            caller: msg.sender,
            operation: operation,
            dataHash: dataHash
        });
        
        emit GasMeasured(measurementId, msg.sender, operation, gasUsed, block.timestamp);
        
        return (measurementId, gasUsed);
    }

    /**
     * @dev 一次性测量函数调用的Gas消耗
     * @param target 目标合约地址
     * @param data 调用数据
     * @param operation 操作名称
     * @return success 调用是否成功
     * @return gasUsed 消耗的Gas
     * @return result 调用结果
     */
    function measureCall(
        address target,
        bytes calldata data,
        string calldata operation
    ) external returns (bool success, uint256 gasUsed, bytes memory result) {
        uint256 startGas = gasleft();
        
        (success, result) = target.call(data);
        
        gasUsed = startGas - gasleft();
        
        bytes32 measurementId = keccak256(abi.encodePacked(
            target,
            data,
            operation,
            block.timestamp,
            gasUsed
        ));
        
        gasMeasurements[measurementId] = GasMeasurement({
            gasUsed: gasUsed,
            timestamp: block.timestamp,
            caller: msg.sender,
            operation: operation,
            dataHash: keccak256(data)
        });
        
        emit GasMeasured(measurementId, msg.sender, operation, gasUsed, block.timestamp);
        
        return (success, gasUsed, result);
    }

    // ============ Batch Testing Functions ============
    
    /**
     * @dev 开始批量测试
     * @param testName 测试名称
     * @return testId 测试ID
     */
    function startBatchTest(string calldata testName) external returns (uint256 testId) {
        testId = ++testIdCounter;
        
        batchResults[testId] = BatchTestResult({
            totalOperations: 0,
            totalGasUsed: 0,
            averageGasPerOp: 0,
            minGasUsed: type(uint256).max,
            maxGasUsed: 0,
            testName: testName
        });
        
        return testId;
    }

    /**
     * @dev 添加测量到批量测试
     * @param testId 测试ID
     * @param measurementId 测量ID
     */
    function addToBatchTest(uint256 testId, bytes32 measurementId) external {
        require(testId <= testIdCounter && testId > 0, "GasTracker: invalid test ID");
        
        GasMeasurement memory measurement = gasMeasurements[measurementId];
        require(measurement.gasUsed > 0, "GasTracker: measurement not found");
        
        testMeasurements[testId].push(measurementId);
        
        BatchTestResult storage result = batchResults[testId];
        result.totalOperations++;
        result.totalGasUsed += measurement.gasUsed;
        
        if (measurement.gasUsed < result.minGasUsed) {
            result.minGasUsed = measurement.gasUsed;
        }
        if (measurement.gasUsed > result.maxGasUsed) {
            result.maxGasUsed = measurement.gasUsed;
        }
        
        result.averageGasPerOp = result.totalGasUsed / result.totalOperations;
    }

    /**
     * @dev 完成批量测试
     * @param testId 测试ID
     * @return result 批量测试结果
     */
    function finalizeBatchTest(uint256 testId) external returns (BatchTestResult memory result) {
        require(testId <= testIdCounter && testId > 0, "GasTracker: invalid test ID");
        
        result = batchResults[testId];
        
        emit BatchTestCompleted(
            testId,
            result.testName,
            result.totalOperations,
            result.totalGasUsed,
            result.averageGasPerOp
        );
        
        return result;
    }

    // ============ Comparison Functions ============
    
    /**
     * @dev 比较两个Gas测量结果
     * @param baseMeasurementId 基础测量ID
     * @param optimizedMeasurementId 优化测量ID
     * @param optimizationType 优化类型
     * @return comparisonId 比较结果ID
     * @return comparison 比较结果
     */
    function compareGas(
        bytes32 baseMeasurementId,
        bytes32 optimizedMeasurementId,
        string calldata optimizationType
    ) external returns (bytes32 comparisonId, GasComparison memory comparison) {
        GasMeasurement memory baseMeasurement = gasMeasurements[baseMeasurementId];
        GasMeasurement memory optimizedMeasurement = gasMeasurements[optimizedMeasurementId];
        
        require(baseMeasurement.gasUsed > 0, "GasTracker: base measurement not found");
        require(optimizedMeasurement.gasUsed > 0, "GasTracker: optimized measurement not found");
        
        uint256 savings = baseMeasurement.gasUsed > optimizedMeasurement.gasUsed 
            ? baseMeasurement.gasUsed - optimizedMeasurement.gasUsed 
            : 0;
        
        uint256 savingsPercent = baseMeasurement.gasUsed > 0 
            ? (savings * 10000) / baseMeasurement.gasUsed 
            : 0;
        
        comparison = GasComparison({
            baseGas: baseMeasurement.gasUsed,
            optimizedGas: optimizedMeasurement.gasUsed,
            savings: savings,
            savingsPercent: savingsPercent,
            optimizationType: optimizationType
        });
        
        comparisonId = keccak256(abi.encodePacked(
            baseMeasurementId,
            optimizedMeasurementId,
            optimizationType,
            block.timestamp
        ));
        
        comparisons[comparisonId] = comparison;
        
        emit GasCompared(
            comparisonId,
            optimizationType,
            comparison.baseGas,
            comparison.optimizedGas,
            comparison.savings,
            comparison.savingsPercent
        );
        
        return (comparisonId, comparison);
    }

    /**
     * @dev 批量比较测试结果
     * @param baseTestId 基础测试ID
     * @param optimizedTestId 优化测试ID
     * @param optimizationType 优化类型
     * @return comparisonId 比较结果ID
     * @return comparison 比较结果
     */
    function compareBatchTests(
        uint256 baseTestId,
        uint256 optimizedTestId,
        string calldata optimizationType
    ) external returns (bytes32 comparisonId, GasComparison memory comparison) {
        BatchTestResult memory baseResult = batchResults[baseTestId];
        BatchTestResult memory optimizedResult = batchResults[optimizedTestId];
        
        require(baseResult.totalOperations > 0, "GasTracker: base test not found");
        require(optimizedResult.totalOperations > 0, "GasTracker: optimized test not found");
        
        uint256 savings = baseResult.averageGasPerOp > optimizedResult.averageGasPerOp 
            ? baseResult.averageGasPerOp - optimizedResult.averageGasPerOp 
            : 0;
        
        uint256 savingsPercent = baseResult.averageGasPerOp > 0 
            ? (savings * 10000) / baseResult.averageGasPerOp 
            : 0;
        
        comparison = GasComparison({
            baseGas: baseResult.averageGasPerOp,
            optimizedGas: optimizedResult.averageGasPerOp,
            savings: savings,
            savingsPercent: savingsPercent,
            optimizationType: optimizationType
        });
        
        comparisonId = keccak256(abi.encodePacked(
            baseTestId,
            optimizedTestId,
            optimizationType,
            "batch_comparison",
            block.timestamp
        ));
        
        comparisons[comparisonId] = comparison;
        
        emit GasCompared(
            comparisonId,
            optimizationType,
            comparison.baseGas,
            comparison.optimizedGas,
            comparison.savings,
            comparison.savingsPercent
        );
        
        return (comparisonId, comparison);
    }

    // ============ View Functions ============
    
    /**
     * @dev 获取测量结果
     * @param measurementId 测量ID
     * @return measurement 测量结果
     */
    function getMeasurement(bytes32 measurementId) 
        external 
        view 
        returns (GasMeasurement memory measurement) 
    {
        return gasMeasurements[measurementId];
    }

    /**
     * @dev 获取比较结果
     * @param comparisonId 比较ID
     * @return comparison 比较结果
     */
    function getComparison(bytes32 comparisonId) 
        external 
        view 
        returns (GasComparison memory comparison) 
    {
        return comparisons[comparisonId];
    }

    /**
     * @dev 获取批量测试结果
     * @param testId 测试ID
     * @return result 批量测试结果
     */
    function getBatchResult(uint256 testId) 
        external 
        view 
        returns (BatchTestResult memory result) 
    {
        return batchResults[testId];
    }

    /**
     * @dev 获取测试的所有测量ID
     * @param testId 测试ID
     * @return measurementIds 测量ID数组
     */
    function getTestMeasurements(uint256 testId) 
        external 
        view 
        returns (bytes32[] memory measurementIds) 
    {
        return testMeasurements[testId];
    }

    /**
     * @dev 计算节省百分比
     * @param baseGas 基础Gas消耗
     * @param optimizedGas 优化后Gas消耗
     * @return savingsPercent 节省百分比 (乘以100)
     */
    function calculateSavingsPercent(uint256 baseGas, uint256 optimizedGas) 
        external 
        pure 
        returns (uint256 savingsPercent) 
    {
        if (baseGas == 0) return 0;
        if (optimizedGas >= baseGas) return 0;
        
        uint256 savings = baseGas - optimizedGas;
        return (savings * 10000) / baseGas;
    }

    // ============ Admin Functions ============
    
    /**
     * @dev 清除测量数据
     * @param measurementId 测量ID
     */
    function clearMeasurement(bytes32 measurementId) external onlyOwner {
        delete gasMeasurements[measurementId];
    }

    /**
     * @dev 清除批量测试数据
     * @param testId 测试ID
     */
    function clearBatchTest(uint256 testId) external onlyOwner {
        delete batchResults[testId];
        delete testMeasurements[testId];
    }

    /**
     * @dev 转移所有权
     * @param newOwner 新所有者地址
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "GasTracker: new owner is the zero address");
        owner = newOwner;
    }
}
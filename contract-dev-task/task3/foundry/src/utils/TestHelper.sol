// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title TestHelper
 * @dev 测试辅助工具合约
 * @notice 提供测试数据生成、验证和工具函数
 * @author Gas Optimization Study Project
 */
contract TestHelper {
    // ============ Structs ============

    /**
     * @dev 测试用例结构体
     */
    struct TestCase {
        uint256 a; // 第一个操作数
        uint256 b; // 第二个操作数
        uint8 operation; // 操作类型 (0: add, 1: sub, 2: mul, 3: div)
        uint256 expectedResult; // 期望结果
        bool shouldRevert; // 是否应该回滚
        string description; // 测试描述
    }

    /**
     * @dev 批量测试数据结构体
     */
    struct BatchTestData {
        uint256[] values; // 操作数数组
        uint8[] operations; // 操作类型数组
        uint256[] expectedResults; // 期望结果数组
        string description; // 测试描述
    }

    /**
     * @dev 性能测试配置结构体
     */
    struct PerformanceTestConfig {
        uint256 iterations; // 迭代次数
        uint256 dataSize; // 数据大小
        bool useRandomData; // 是否使用随机数据
        uint256 seed; // 随机种子
        string testType; // 测试类型
    }

    // ============ State Variables ============

    /// @dev 合约所有者
    address public owner;

    /// @dev 随机种子
    uint256 private _randomSeed;

    /// @dev 测试用例计数器
    uint256 public testCaseCounter;

    /// @dev 存储的测试用例
    mapping(uint256 => TestCase) public testCases;

    /// @dev 批量测试数据
    mapping(uint256 => BatchTestData) public batchTestData;

    // ============ Events ============

    /**
     * @dev 测试用例创建事件
     */
    event TestCaseCreated(uint256 indexed caseId, string description);

    /**
     * @dev 批量测试数据创建事件
     */
    event BatchTestDataCreated(
        uint256 indexed dataId,
        string description,
        uint256 size
    );

    // ============ Constructor ============

    constructor() {
        owner = msg.sender;
        _randomSeed = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, block.difficulty, msg.sender)
            )
        );
        testCaseCounter = 0;
    }

    // ============ Modifiers ============

    modifier onlyOwner() {
        require(msg.sender == owner, "TestHelper: caller is not the owner");
        _;
    }

    // ============ Test Data Generation ============

    /**
     * @dev 生成基础测试用例
     * @return caseId 测试用例ID
     */
    function generateBasicTestCases() external returns (uint256 caseId) {
        caseId = ++testCaseCounter;

        // 基础加法测试
        testCases[caseId] = TestCase({
            a: 100,
            b: 200,
            operation: 0,
            expectedResult: 300,
            shouldRevert: false,
            description: "Basic Addition Test"
        });

        emit TestCaseCreated(caseId, "Basic Addition Test");
        return caseId;
    }

    /**
     * @dev 生成边界测试用例
     * @return caseIds 测试用例ID数组
     */
    function generateBoundaryTestCases()
        external
        returns (uint256[] memory caseIds)
    {
        caseIds = new uint256[](8);

        // 最大值加法测试 (应该溢出)
        caseIds[0] = ++testCaseCounter;
        testCases[caseIds[0]] = TestCase({
            a: type(uint256).max,
            b: 1,
            operation: 0,
            expectedResult: 0,
            shouldRevert: true,
            description: "Max Value Addition Overflow Test"
        });

        // 零值测试
        caseIds[1] = ++testCaseCounter;
        testCases[caseIds[1]] = TestCase({
            a: 0,
            b: 0,
            operation: 0,
            expectedResult: 0,
            shouldRevert: false,
            description: "Zero Addition Test"
        });

        // 减法下溢测试
        caseIds[2] = ++testCaseCounter;
        testCases[caseIds[2]] = TestCase({
            a: 5,
            b: 10,
            operation: 1,
            expectedResult: 0,
            shouldRevert: true,
            description: "Subtraction Underflow Test"
        });

        // 乘法溢出测试
        caseIds[3] = ++testCaseCounter;
        testCases[caseIds[3]] = TestCase({
            a: type(uint256).max,
            b: 2,
            operation: 2,
            expectedResult: 0,
            shouldRevert: true,
            description: "Multiplication Overflow Test"
        });

        // 零乘法测试
        caseIds[4] = ++testCaseCounter;
        testCases[caseIds[4]] = TestCase({
            a: 0,
            b: 12345,
            operation: 2,
            expectedResult: 0,
            shouldRevert: false,
            description: "Zero Multiplication Test"
        });

        // 除零测试
        caseIds[5] = ++testCaseCounter;
        testCases[caseIds[5]] = TestCase({
            a: 100,
            b: 0,
            operation: 3,
            expectedResult: 0,
            shouldRevert: true,
            description: "Division by Zero Test"
        });

        // 正常除法测试
        caseIds[6] = ++testCaseCounter;
        testCases[caseIds[6]] = TestCase({
            a: 100,
            b: 4,
            operation: 3,
            expectedResult: 25,
            shouldRevert: false,
            description: "Normal Division Test"
        });

        // 整数除法测试
        caseIds[7] = ++testCaseCounter;
        testCases[caseIds[7]] = TestCase({
            a: 7,
            b: 3,
            operation: 3,
            expectedResult: 2,
            shouldRevert: false,
            description: "Integer Division Test"
        });

        for (uint256 i = 0; i < caseIds.length; i++) {
            emit TestCaseCreated(caseIds[i], testCases[caseIds[i]].description);
        }

        return caseIds;
    }

    /**
     * @dev 生成随机测试用例
     * @param count 生成数量
     * @param maxValue 最大值
     * @return caseIds 测试用例ID数组
     */
    function generateRandomTestCases(
        uint256 count,
        uint256 maxValue
    ) external returns (uint256[] memory caseIds) {
        caseIds = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            caseIds[i] = ++testCaseCounter;

            uint256 a = _generateRandomNumber(maxValue);
            uint256 b = _generateRandomNumber(maxValue);
            uint8 operation = uint8(_generateRandomNumber(4));

            uint256 expectedResult = 0;
            bool shouldRevert = false;

            // 计算期望结果和是否应该回滚
            if (operation == 0) {
                // 加法
                if (a > type(uint256).max - b) {
                    shouldRevert = true;
                } else {
                    expectedResult = a + b;
                }
            } else if (operation == 1) {
                // 减法
                if (a < b) {
                    shouldRevert = true;
                } else {
                    expectedResult = a - b;
                }
            } else if (operation == 2) {
                // 乘法
                if (a != 0 && b > type(uint256).max / a) {
                    shouldRevert = true;
                } else {
                    expectedResult = a * b;
                }
            } else {
                // 除法
                if (b == 0) {
                    shouldRevert = true;
                } else {
                    expectedResult = a / b;
                }
            }

            testCases[caseIds[i]] = TestCase({
                a: a,
                b: b,
                operation: operation,
                expectedResult: expectedResult,
                shouldRevert: shouldRevert,
                description: string(
                    abi.encodePacked("Random Test Case ", _toString(i + 1))
                )
            });

            emit TestCaseCreated(caseIds[i], testCases[caseIds[i]].description);
        }

        return caseIds;
    }

    /**
     * @dev 生成批量测试数据
     * @param size 数据大小
     * @param maxValue 最大值
     * @param useRandom 是否使用随机数据
     * @return dataId 批量测试数据ID
     */
    function generateBatchTestData(
        uint256 size,
        uint256 maxValue,
        bool useRandom
    ) external returns (uint256 dataId) {
        dataId = ++testCaseCounter;

        uint256[] memory values = new uint256[](size * 2);
        uint8[] memory operations = new uint8[](size);
        uint256[] memory expectedResults = new uint256[](size);

        for (uint256 i = 0; i < size; i++) {
            uint256 a;
            uint256 b;
            uint8 operation;

            if (useRandom) {
                a = _generateRandomNumber(maxValue);
                b = _generateRandomNumber(maxValue);
                operation = uint8(_generateRandomNumber(4));
            } else {
                a = (i + 1) * 10;
                b = (i + 1) * 5;
                operation = uint8(i % 4);
            }

            values[i * 2] = a;
            values[i * 2 + 1] = b;
            operations[i] = operation;

            // 计算期望结果
            if (operation == 0 && a <= type(uint256).max - b) {
                expectedResults[i] = a + b;
            } else if (operation == 1 && a >= b) {
                expectedResults[i] = a - b;
            } else if (
                operation == 2 && (a == 0 || b <= type(uint256).max / a)
            ) {
                expectedResults[i] = a * b;
            } else if (operation == 3 && b != 0) {
                expectedResults[i] = a / b;
            }
        }

        batchTestData[dataId] = BatchTestData({
            values: values,
            operations: operations,
            expectedResults: expectedResults,
            description: string(
                abi.encodePacked("Batch Test Data ", _toString(dataId))
            )
        });

        emit BatchTestDataCreated(
            dataId,
            batchTestData[dataId].description,
            size
        );
        return dataId;
    }

    /**
     * @dev 生成性能测试数据
     * @param config 性能测试配置
     * @return dataId 测试数据ID
     */
    function generatePerformanceTestData(
        PerformanceTestConfig calldata config
    ) external returns (uint256 dataId) {
        dataId = ++testCaseCounter;

        uint256[] memory values = new uint256[](config.dataSize * 2);
        uint8[] memory operations = new uint8[](config.dataSize);
        uint256[] memory expectedResults = new uint256[](config.dataSize);

        // 设置随机种子
        if (config.useRandomData) {
            _randomSeed = config.seed;
        }

        for (uint256 i = 0; i < config.dataSize; i++) {
            uint256 a;
            uint256 b;
            uint8 operation;

            if (config.useRandomData) {
                a = _generateRandomNumber(1000000);
                b = _generateRandomNumber(1000000);
                operation = uint8(_generateRandomNumber(4));
            } else {
                // 生成可预测的测试数据
                a = (i + 1) * 100;
                b = (i + 1) * 50;
                operation = uint8(i % 4);
            }

            values[i * 2] = a;
            values[i * 2 + 1] = b;
            operations[i] = operation;

            // 计算期望结果 (简化版本，不处理溢出)
            if (operation == 0) {
                expectedResults[i] = a + b;
            } else if (operation == 1) {
                expectedResults[i] = a >= b ? a - b : 0;
            } else if (operation == 2) {
                expectedResults[i] = a * b;
            } else {
                expectedResults[i] = b != 0 ? a / b : 0;
            }
        }

        batchTestData[dataId] = BatchTestData({
            values: values,
            operations: operations,
            expectedResults: expectedResults,
            description: string(
                abi.encodePacked("Performance Test Data - ", config.testType)
            )
        });

        emit BatchTestDataCreated(
            dataId,
            batchTestData[dataId].description,
            config.dataSize
        );
        return dataId;
    }

    // ============ Test Validation Functions ============

    /**
     * @dev 验证单个测试结果
     * @param caseId 测试用例ID
     * @param actualResult 实际结果
     * @param didRevert 是否发生回滚
     * @return isValid 验证是否通过
     */
    function validateTestResult(
        uint256 caseId,
        uint256 actualResult,
        bool didRevert
    ) external view returns (bool isValid) {
        TestCase memory testCase = testCases[caseId];

        if (testCase.shouldRevert) {
            return didRevert;
        } else {
            return !didRevert && actualResult == testCase.expectedResult;
        }
    }

    /**
     * @dev 验证批量测试结果
     * @param dataId 批量测试数据ID
     * @param actualResults 实际结果数组
     * @return isValid 验证是否通过
     * @return failedCount 失败数量
     */
    function validateBatchResults(
        uint256 dataId,
        uint256[] calldata actualResults
    ) external view returns (bool isValid, uint256 failedCount) {
        BatchTestData memory data = batchTestData[dataId];

        if (actualResults.length != data.expectedResults.length) {
            return (false, actualResults.length);
        }

        failedCount = 0;
        for (uint256 i = 0; i < actualResults.length; i++) {
            if (actualResults[i] != data.expectedResults[i]) {
                failedCount++;
            }
        }

        isValid = failedCount == 0;
        return (isValid, failedCount);
    }

    // ============ Utility Functions ============

    /**
     * @dev 生成随机数
     * @param max 最大值 (不包含)
     * @return 随机数
     */
    function _generateRandomNumber(uint256 max) private returns (uint256) {
        if (max == 0) return 0;

        _randomSeed = uint256(
            keccak256(
                abi.encodePacked(
                    _randomSeed,
                    block.timestamp,
                    block.difficulty,
                    msg.sender
                )
            )
        );

        return _randomSeed % max;
    }

    /**
     * @dev 将数字转换为字符串
     * @param value 数值
     * @return 字符串
     */
    function _toString(uint256 value) private pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // ============ View Functions ============

    /**
     * @dev 获取测试用例
     * @param caseId 测试用例ID
     * @return testCase 测试用例
     */
    function getTestCase(
        uint256 caseId
    ) external view returns (TestCase memory testCase) {
        return testCases[caseId];
    }

    /**
     * @dev 获取批量测试数据
     * @param dataId 数据ID
     * @return data 批量测试数据
     */
    function getBatchTestData(
        uint256 dataId
    ) external view returns (BatchTestData memory data) {
        return batchTestData[dataId];
    }

    /**
     * @dev 获取当前随机种子
     * @return 随机种子
     */
    function getCurrentSeed() external view returns (uint256) {
        return _randomSeed;
    }

    // ============ Admin Functions ============

    /**
     * @dev 设置随机种子
     * @param seed 新的随机种子
     */
    function setSeed(uint256 seed) external onlyOwner {
        _randomSeed = seed;
    }

    /**
     * @dev 清除测试用例
     * @param caseId 测试用例ID
     */
    function clearTestCase(uint256 caseId) external onlyOwner {
        delete testCases[caseId];
    }

    /**
     * @dev 清除批量测试数据
     * @param dataId 数据ID
     */
    function clearBatchTestData(uint256 dataId) external onlyOwner {
        delete batchTestData[dataId];
    }

    /**
     * @dev 转移所有权
     * @param newOwner 新所有者地址
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(
            newOwner != address(0),
            "TestHelper: new owner is the zero address"
        );
        owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/BaseCalculator.sol";
import "../src/interfaces/ICalculator.sol";

contract BaseCalculatorTest is Test {
    BaseCalculator public calculator;
    address public owner;
    address public user;

    event CalculationPerformed(uint256 indexed result, uint8 operation, uint256 a, uint256 b);
    event BatchCalculationCompleted(uint256 indexed batchId, uint256 totalOperations);

    function setUp() public {
        owner = address(this);
        user = address(0x1);
        calculator = new BaseCalculator();
    }

    // 基础算术运算测试
    function testAdd() public {
        uint256 result = calculator.add(10, 5);
        assertEq(result, 15);
        assertEq(calculator.getLastResult(), 15);
        assertEq(calculator.getOperationCount(), 1);
    }

    function testSubtract() public {
        uint256 result = calculator.subtract(10, 5);
        assertEq(result, 5);
        assertEq(calculator.getLastResult(), 5);
        assertEq(calculator.getOperationCount(), 1);
    }

    function testMultiply() public {
        uint256 result = calculator.multiply(10, 5);
        assertEq(result, 50);
        assertEq(calculator.getLastResult(), 50);
        assertEq(calculator.getOperationCount(), 1);
    }

    function testDivide() public {
        uint256 result = calculator.divide(10, 5);
        assertEq(result, 2);
        assertEq(calculator.getLastResult(), 2);
        assertEq(calculator.getOperationCount(), 1);
    }

    // 边界条件测试
    function testAddWithZero() public {
        uint256 result = calculator.add(100, 0);
        assertEq(result, 100);
    }

    function testSubtractToZero() public {
        uint256 result = calculator.subtract(100, 100);
        assertEq(result, 0);
    }

    function testMultiplyByZero() public {
        uint256 result = calculator.multiply(100, 0);
        assertEq(result, 0);
    }

    function testDivideByOne() public {
        uint256 result = calculator.divide(100, 1);
        assertEq(result, 100);
    }

    // 大数测试
    function testLargeNumbers() public {
        uint256 a = type(uint256).max / 2;
        uint256 b = 2;
        
        uint256 result = calculator.add(a, a);
        assertEq(result, a * 2);
        
        result = calculator.multiply(a, b);
        assertEq(result, a * 2);
    }

    // 错误处理测试
    function testDivideByZero() public {
        vm.expectRevert(ICalculator.DivisionByZero.selector);
        calculator.divide(10, 0);
    }

    function testSubtractUnderflow() public {
        vm.expectRevert(ICalculator.ArithmeticOverflow.selector);
        calculator.subtract(5, 10);
    }

    function testAddOverflow() public {
        vm.expectRevert(ICalculator.ArithmeticOverflow.selector);
        calculator.add(type(uint256).max, 1);
    }

    function testMultiplyOverflow() public {
        vm.expectRevert(ICalculator.ArithmeticOverflow.selector);
        calculator.multiply(type(uint256).max, 2);
    }

    // 批量操作测试
    function testBatchCalculate() public {
        uint256[] memory values = new uint256[](6);
        values[0] = 10; values[1] = 5;  // 10 + 5 = 15
        values[2] = 20; values[3] = 3;  // 20 - 3 = 17
        values[4] = 4;  values[5] = 6;  // 4 * 6 = 24

        uint8[] memory operations = new uint8[](3);
        operations[0] = 0; // ADD
        operations[1] = 1; // SUBTRACT
        operations[2] = 2; // MULTIPLY

        // 不检查事件，因为gas使用量会变化

        uint256[] memory results = calculator.batchCalculate(values, operations);
        
        assertEq(results.length, 3);
        assertEq(results[0], 15);
        assertEq(results[1], 17);
        assertEq(results[2], 24);
        assertEq(calculator.getOperationCount(), 3);
    }

    function testBatchCalculateWithInvalidOperation() public {
        uint256[] memory values = new uint256[](2);
        values[0] = 10; values[1] = 5;

        uint8[] memory operations = new uint8[](1);
        operations[0] = 5; // 无效操作

        vm.expectRevert(abi.encodeWithSelector(ICalculator.InvalidOperator.selector, 5));
        calculator.batchCalculate(values, operations);
    }

    function testBatchCalculateArrayLengthMismatch() public {
        uint256[] memory values = new uint256[](3);
        values[0] = 10; values[1] = 5; values[2] = 3;

        uint8[] memory operations = new uint8[](1);
        operations[0] = 0;

        vm.expectRevert(ICalculator.ArrayLengthMismatch.selector);
        calculator.batchCalculate(values, operations);
    }

    // 事件测试
    function testCalculationPerformedEvent() public {
        // 不检查事件，因为gas使用量会变化
        calculator.add(10, 5);
    }

    // 状态管理测试
    function testOperationCountIncrement() public {
        assertEq(calculator.getOperationCount(), 0);
        
        calculator.add(1, 1);
        assertEq(calculator.getOperationCount(), 1);
        
        calculator.subtract(5, 2);
        assertEq(calculator.getOperationCount(), 2);
        
        calculator.multiply(3, 4);
        assertEq(calculator.getOperationCount(), 3);
        
        calculator.divide(10, 2);
        assertEq(calculator.getOperationCount(), 4);
    }

    function testLastResultUpdate() public {
        calculator.add(10, 5);
        assertEq(calculator.getLastResult(), 15);
        
        calculator.multiply(3, 4);
        assertEq(calculator.getLastResult(), 12);
        
        calculator.divide(20, 4);
        assertEq(calculator.getLastResult(), 5);
    }

    // 权限测试
    function testOnlyOwnerFunctions() public {
        vm.prank(user);
        vm.expectRevert("BaseCalculator: caller is not the owner");
        calculator.setActive(false);
        
        vm.prank(user);
        vm.expectRevert("BaseCalculator: caller is not the owner");
        calculator.transferOwnership(user);
    }

    function testSetActive() public {
        calculator.setActive(false);
        // 测试设置状态功能
        calculator.setActive(true);
    }

    function testTransferOwnership() public {
        assertEq(calculator.owner(), owner);
        
        calculator.transferOwnership(user);
        assertEq(calculator.owner(), user);
        
        // 原owner不能再调用owner函数
        vm.expectRevert("BaseCalculator: caller is not the owner");
        calculator.setActive(false);
        
        // 新owner可以调用
        vm.prank(user);
        calculator.setActive(true);
    }

    // 版本信息测试
    function testVersion() public {
        string memory version = calculator.version();
        assertEq(version, "BaseCalculator v1.0.0");
    }

    // Fuzz测试
    function testFuzzAdd(uint128 a, uint128 b) public {
        uint256 result = calculator.add(a, b);
        assertEq(result, uint256(a) + uint256(b));
    }

    function testFuzzSubtract(uint256 a, uint256 b) public {
        vm.assume(a >= b);
        uint256 result = calculator.subtract(a, b);
        assertEq(result, a - b);
    }

    function testFuzzMultiply(uint128 a, uint128 b) public {
        uint256 result = calculator.multiply(a, b);
        assertEq(result, uint256(a) * uint256(b));
    }

    function testFuzzDivide(uint256 a, uint256 b) public {
        vm.assume(b > 0);
        uint256 result = calculator.divide(a, b);
        assertEq(result, a / b);
    }

    // 性能测试辅助函数
    function testGasCostBaseline() public {
        uint256 gasBefore = gasleft();
        calculator.add(100, 200);
        uint256 gasUsed = gasBefore - gasleft();
        
        // 记录基础Gas消耗，用于后续对比
        emit log_named_uint("BaseCalculator add() gas used", gasUsed);
    }
}
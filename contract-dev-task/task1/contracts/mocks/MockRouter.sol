// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../interfaces/IUniswapV2.sol';

contract MockRouter {
    address public factory;
    address public WETH;
    
    constructor(address _factory, address _weth) {
        factory = _factory;
        WETH = _weth;
    }
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external {
        // 模拟实现，不做实际交换
    }
    
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity) {
        // 模拟实现，返回输入值
        return (amountTokenDesired, msg.value, 1000);
    }
}

contract MockFactory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        // 简单返回一个计算出的地址
        pair = address(uint160(uint(keccak256(abi.encodePacked(tokenA, tokenB)))));
        getPair[tokenA][tokenB] = pair;
        getPair[tokenB][tokenA] = pair;
        allPairs.push(pair);
        return pair;
    }
    
    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }
}
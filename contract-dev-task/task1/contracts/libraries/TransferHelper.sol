// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TransferHelper
 * @dev 安全转账辅助库，提供ERC20代币和ETH的安全转账功能
 */
library TransferHelper {
    /**
     * @dev 安全转账ERC20代币
     * @param token 代币合约地址
     * @param to 接收地址
     * @param value 转账数量
     */
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    /**
     * @dev 安全从某地址转账ERC20代币
     * @param token 代币合约地址
     * @param from 发送地址
     * @param to 接收地址
     * @param value 转账数量
     */
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    /**
     * @dev 安全转账ETH
     * @param to 接收地址
     * @param value 转账数量
     */
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }

    /**
     * @dev 安全授权ERC20代币
     * @param token 代币合约地址
     * @param to 被授权地址
     * @param value 授权数量
     */
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    /**
     * @dev 获取ERC20代币余额
     * @param token 代币合约地址
     * @param account 查询地址
     * @return balance 余额
     */
    function safeBalanceOf(address token, address account)
        internal
        view
        returns (uint256 balance)
    {
        // bytes4(keccak256(bytes('balanceOf(address)')));
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(0x70a08231, account)
        );
        require(success, "TransferHelper: BALANCE_QUERY_FAILED");
        balance = abi.decode(data, (uint256));
    }

    /**
     * @dev 获取ERC20代币授权额度
     * @param token 代币合约地址
     * @param owner 授权者地址
     * @param spender 被授权者地址
     * @return allowance 授权额度
     */
    function safeAllowance(
        address token,
        address owner,
        address spender
    ) internal view returns (uint256 allowance) {
        // bytes4(keccak256(bytes('allowance(address,address)')));
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(0xdd62ed3e, owner, spender)
        );
        require(success, "TransferHelper: ALLOWANCE_QUERY_FAILED");
        allowance = abi.decode(data, (uint256));
    }

    /**
     * @dev 批量安全转账ERC20代币
     * @param token 代币合约地址
     * @param recipients 接收地址数组
     * @param amounts 转账数量数组
     */
    function safeBatchTransfer(
        address token,
        address[] memory recipients,
        uint256[] memory amounts
    ) internal {
        require(
            recipients.length == amounts.length,
            "TransferHelper: ARRAY_LENGTH_MISMATCH"
        );
        
        for (uint256 i = 0; i < recipients.length; i++) {
            safeTransfer(token, recipients[i], amounts[i]);
        }
    }

    /**
     * @dev 批量安全转账ETH
     * @param recipients 接收地址数组
     * @param amounts 转账数量数组
     */
    function safeBatchTransferETH(
        address[] memory recipients,
        uint256[] memory amounts
    ) internal {
        require(
            recipients.length == amounts.length,
            "TransferHelper: ARRAY_LENGTH_MISMATCH"
        );
        
        for (uint256 i = 0; i < recipients.length; i++) {
            safeTransferETH(recipients[i], amounts[i]);
        }
    }

    /**
     * @dev 检查合约是否存在
     * @param account 地址
     * @return 是否为合约
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev 安全调用合约函数
     * @param target 目标合约地址
     * @param data 调用数据
     * @return success 是否成功
     * @return returnData 返回数据
     */
    function safeCall(address target, bytes memory data)
        internal
        returns (bool success, bytes memory returnData)
    {
        require(isContract(target), "TransferHelper: CALL_TO_NON_CONTRACT");
        (success, returnData) = target.call(data);
    }

    /**
     * @dev 安全静态调用合约函数
     * @param target 目标合约地址
     * @param data 调用数据
     * @return success 是否成功
     * @return returnData 返回数据
     */
    function safeStaticCall(address target, bytes memory data)
        internal
        view
        returns (bool success, bytes memory returnData)
    {
        require(isContract(target), "TransferHelper: STATICCALL_TO_NON_CONTRACT");
        (success, returnData) = target.staticcall(data);
    }
}
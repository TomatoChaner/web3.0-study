/**
 * ✅ 作业 1：ERC20 代币
任务：参考 openzeppelin-contracts/contracts/token/ERC20/IERC20.sol实现一个简单的 ERC20 代币合约。要求：
合约包含以下标准 ERC20 功能：
balanceOf：查询账户余额。
transfer：转账。
approve 和 transferFrom：授权和代扣转账。
使用 event 记录转账和授权操作。
提供 mint 函数，允许合约所有者增发代币。
提示：
使用 mapping 存储账户余额和授权信息。
使用 event 定义 Transfer 和 Approval 事件。
部署到sepolia 测试网，导入到自己的钱包
 */

// 测试网合约地址：0x8382096d88c0B76aefE808A6a3C34F80B4501481

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title MyERC20
 * @dev 实现ERC20标准的代币合约
 *
 * 解题思路：
 * 1. 实现ERC20标准接口，包括基本的转账、授权功能
 * 2. 使用mapping存储账户余额和授权信息，确保数据安全
 * 3. 添加事件记录所有重要操作，便于链下监听和审计
 * 4. 实现所有者权限控制，只有所有者可以增发代币
 * 5. 添加安全检查，防止溢出和非法操作
 */
contract MyERC20 {
    // ==================== 状态变量 ====================

    /**
     * @dev 代币基本信息
     * 这些变量定义了代币的基本属性，符合ERC20标准要求
     */
    string public name; // 代币名称
    string public symbol; // 代币符号
    uint8 public decimals; // 小数位数，通常为18
    uint256 public totalSupply; // 总供应量

    /**
     * @dev 合约所有者地址
     * 用于权限控制，只有所有者可以执行mint等特权操作
     */
    address public owner;

    /**
     * @dev 账户余额映射
     * 存储每个地址的代币余额，这是ERC20的核心数据结构
     */
    mapping(address => uint256) private _balances;

    /**
     * @dev 授权映射
     * 存储授权信息：_allowances[owner][spender] = amount
     * 表示owner授权spender可以代为转账的金额
     */
    mapping(address => mapping(address => uint256)) private _allowances;

    // ==================== 事件定义 ====================

    /**
     * @dev 转账事件
     * 当代币转移时触发，包括mint和burn操作
     * from为零地址表示mint，to为零地址表示burn
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev 授权事件
     * 当调用approve函数时触发
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev 增发事件
     * 当所有者增发代币时触发
     */
    event Mint(address indexed to, uint256 amount);

    // ==================== 修饰符 ====================

    /**
     * @dev 只有所有者可以调用的修饰符
     * 用于保护mint等特权函数
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "MyERC20: caller is not the owner");
        _;
    }

    // ==================== 构造函数 ====================

    /**
     * @dev 构造函数
     * 初始化代币基本信息和所有者
     * @param _name 代币名称
     * @param _symbol 代币符号
     * @param _decimals 小数位数
     * @param _initialSupply 初始供应量
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        owner = msg.sender;

        // 将初始供应量分配给合约部署者
        totalSupply = _initialSupply * 10 ** _decimals;
        _balances[msg.sender] = totalSupply;

        // 触发Transfer事件，表示从零地址mint到部署者
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    // ==================== ERC20标准函数 ====================

    /**
     * @dev 查询账户余额
     * @param account 要查询的账户地址
     * @return 账户的代币余额
     *
     * 设计理由：这是ERC20标准的核心查询函数，必须是public view
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev 转账函数
     * @param to 接收方地址
     * @param amount 转账金额
     * @return 是否转账成功
     *
     * 设计理由：实现基本的代币转移功能，包含安全检查
     */
    function transfer(address to, uint256 amount) public returns (bool) {
        address from = msg.sender;
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev 查询授权额度
     * @param _owner 授权方地址
     * @param spender 被授权方地址
     * @return 授权的代币数量
     *
     * 设计理由：查询授权信息，支持第三方代扣功能
     */
    function allowance(
        address _owner,
        address spender
    ) public view returns (uint256) {
        return _allowances[_owner][spender];
    }

    /**
     * @dev 授权函数
     * @param spender 被授权方地址
     * @param amount 授权金额
     * @return 是否授权成功
     *
     * 设计理由：允许第三方代为转账，是DeFi生态的基础功能
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        address _owner = msg.sender;
        _approve(_owner, spender, amount);
        return true;
    }

    /**
     * @dev 代扣转账函数
     * @param from 转出方地址
     * @param to 接收方地址
     * @param amount 转账金额
     * @return 是否转账成功
     *
     * 设计理由：允许被授权方代为执行转账，支持复杂的DeFi操作
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        address spender = msg.sender;

        // 检查并更新授权额度
        _spendAllowance(from, spender, amount);

        // 执行转账
        _transfer(from, to, amount);

        return true;
    }

    // ==================== 扩展功能 ====================

    /**
     * @dev 增发代币函数
     * @param to 接收增发代币的地址
     * @param amount 增发数量
     *
     * 设计理由：允许所有者根据需要增发代币，但需要权限控制
     */
    function mint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "MyERC20: mint to the zero address");

        // 更新总供应量和接收方余额
        totalSupply += amount;
        _balances[to] += amount;

        // 触发相关事件
        emit Transfer(address(0), to, amount);
        emit Mint(to, amount);
    }

    /**
     * @dev 转移所有权
     * @param newOwner 新所有者地址
     *
     * 设计理由：允许转移合约控制权，但需要当前所有者授权
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "MyERC20: new owner is the zero address"
        );
        owner = newOwner;
    }

    // ==================== 内部函数 ====================

    /**
     * @dev 内部转账函数
     * @param from 转出方地址
     * @param to 接收方地址
     * @param amount 转账金额
     *
     * 设计理由：统一的转账逻辑，包含所有安全检查
     */
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "MyERC20: transfer from the zero address");
        require(to != address(0), "MyERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "MyERC20: transfer amount exceeds balance"
        );

        // 更新余额
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        // 触发转账事件
        emit Transfer(from, to, amount);
    }

    /**
     * @dev 内部授权函数
     * @param _owner 授权方地址
     * @param spender 被授权方地址
     * @param amount 授权金额
     *
     * 设计理由：统一的授权逻辑，确保授权操作的安全性
     */
    function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) internal {
        require(_owner != address(0), "MyERC20: approve from the zero address");
        require(spender != address(0), "MyERC20: approve to the zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    /**
     * @dev 消费授权额度
     * @param _owner 授权方地址
     * @param spender 被授权方地址
     * @param amount 要消费的金额
     *
     * 设计理由：在代扣转账时检查和更新授权额度
     */
    function _spendAllowance(
        address _owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(_owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "MyERC20: insufficient allowance"
            );
            unchecked {
                _approve(_owner, spender, currentAllowance - amount);
            }
        }
    }
}

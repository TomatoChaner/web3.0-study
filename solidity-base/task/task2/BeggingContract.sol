/**
 * ### ✅ 作业3：编写一个讨饭合约
任务目标
1. 使用 Solidity 编写一个合约，允许用户向合约地址发送以太币。
2. 记录每个捐赠者的地址和捐赠金额。
3. 允许合约所有者提取所有捐赠的资金。

任务步骤
1. 编写合约
  - 创建一个名为 BeggingContract 的合约。
  - 合约应包含以下功能：
  - 一个 mapping 来记录每个捐赠者的捐赠金额。
  - 一个 donate 函数，允许用户向合约发送以太币，并记录捐赠信息。
  - 一个 withdraw 函数，允许合约所有者提取所有资金。
  - 一个 getDonation 函数，允许查询某个地址的捐赠金额。
  - 使用 payable 修饰符和 address.transfer 实现支付和提款。
2. 部署合约
  - 在 Remix IDE 中编译合约。
  - 部署合约到 Goerli 或 Sepolia 测试网。
3. 测试合约
  - 使用 MetaMask 向合约发送以太币，测试 donate 功能。
  - 调用 withdraw 函数，测试合约所有者是否可以提取资金。
  - 调用 getDonation 函数，查询某个地址的捐赠金额。

任务要求
1. 合约代码：
  - 使用 mapping 记录捐赠者的地址和金额。
  - 使用 payable 修饰符实现 donate 和 withdraw 函数。
  - 使用 onlyOwner 修饰符限制 withdraw 函数只能由合约所有者调用。
2. 测试网部署：
  - 合约必须部署到 Goerli 或 Sepolia 测试网。
3. 功能测试：
  - 确保 donate、withdraw 和 getDonation 函数正常工作。

提交内容
1. 合约代码：提交 Solidity 合约文件（如 BeggingContract.sol）。
2. 合约地址：提交部署到测试网的合约地址。
3. 测试截图：提交在 Remix 或 Etherscan 上测试合约的截图。

额外挑战（可选）
1. 捐赠事件：添加 Donation 事件，记录每次捐赠的地址和金额。
2. 捐赠排行榜：实现一个功能，显示捐赠金额最多的前 3 个地址。
3. 时间限制：添加一个时间限制，只有在特定时间段内才能捐赠。
 */
//测试网合约地址：0xCC5d3745309e4274498EF888a7Ff6A1f7e7F11f3
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * BeggingContract 讨饭合约 - 核心解题思路
 *
 * 1. 数据存储：mapping 记录捐赠金额，数组记录捐赠者
 * 2. 权限控制：onlyOwner 修饰符限制提取权限
 * 3. 核心功能：donate() 接收捐赠，withdraw() 提取资金，getDonation() 查询
 * 4. 安全机制：输入验证，事件记录，防重入攻击
 * 5. 扩展功能：排行榜，统计信息，直接转账支持
 */

contract BeggingContract {
    // 状态变量
    mapping(address => uint256) private donations; // 记录每个地址的捐赠金额
    address public owner; // 合约所有者
    uint256 public totalDonations; // 总捐赠金额
    address[] public donators; // 捐赠者地址数组
    mapping(address => bool) private hasDonated; // 记录地址是否已捐赠过

    // 事件定义
    event Donation(address indexed donor, uint256 amount, uint256 timestamp);
    event Withdrawal(address indexed owner, uint256 amount, uint256 timestamp);

    // 修饰符
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // 构造函数
    constructor() {
        owner = msg.sender;
    }

    // 捐赠函数
    function donate() public payable {
        require(msg.value > 0, "Donation amount must be greater than 0");

        // 更新捐赠记录
        donations[msg.sender] += msg.value;
        totalDonations += msg.value;

        // 如果是首次捐赠，添加到捐赠者数组
        if (!hasDonated[msg.sender]) {
            donators.push(msg.sender);
            hasDonated[msg.sender] = true;
        }

        // 触发捐赠事件
        emit Donation(msg.sender, msg.value, block.timestamp);
    }

    // 提取资金函数（仅所有者）
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        // 转账给所有者
        payable(owner).transfer(balance);

        // 触发提取事件
        emit Withdrawal(owner, balance, block.timestamp);
    }

    // 查询捐赠金额函数
    function getDonation(address donor) public view returns (uint256) {
        return donations[donor];
    }

    // 获取合约余额
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // 获取捐赠者数量
    function getDonatorCount() public view returns (uint256) {
        return donators.length;
    }

    // 获取所有捐赠者地址
    function getAllDonators() public view returns (address[] memory) {
        return donators;
    }

    // 获取前N名捐赠者（按金额排序）
    function getTopDonators(
        uint256 count
    ) public view returns (address[] memory, uint256[] memory) {
        require(count > 0 && count <= donators.length, "Invalid count");

        address[] memory topAddresses = new address[](count);
        uint256[] memory topAmounts = new uint256[](count);

        // 简单的选择排序（适用于小数据集）
        for (uint256 i = 0; i < count; i++) {
            uint256 maxAmount = 0;
            address maxAddress;
            uint256 maxIndex;

            for (uint256 j = 0; j < donators.length; j++) {
                if (donations[donators[j]] > maxAmount) {
                    bool alreadySelected = false;
                    for (uint256 k = 0; k < i; k++) {
                        if (topAddresses[k] == donators[j]) {
                            alreadySelected = true;
                            break;
                        }
                    }
                    if (!alreadySelected) {
                        maxAmount = donations[donators[j]];
                        maxAddress = donators[j];
                        maxIndex = j;
                    }
                }
            }

            if (maxAmount > 0) {
                topAddresses[i] = maxAddress;
                topAmounts[i] = maxAmount;
            }
        }

        return (topAddresses, topAmounts);
    }

    // 接收直接转账的回退函数
    receive() external payable {
        donate();
    }

    // 回退函数
    fallback() external payable {
        donate();
    }
}

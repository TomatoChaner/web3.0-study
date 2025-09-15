/**
 * ### ✅ 作业2：在测试网上发行一个图文并茂的 NFT
任务目标
1. 使用 Solidity 编写一个符合 ERC721 标准的 NFT 合约。
2. 将图文数据上传到 IPFS，生成元数据链接。
3. 将合约部署到以太坊测试网（如 Goerli 或 Sepolia）。
4. 铸造 NFT 并在测试网环境中查看。
任务步骤
1. 编写 NFT 合约
  - 使用 OpenZeppelin 的 ERC721 库编写一个 NFT 合约。
  - 合约应包含以下功能：
  - 构造函数：设置 NFT 的名称和符号。
  - mintNFT 函数：允许用户铸造 NFT，并关联元数据链接（tokenURI）。
  - 在 Remix IDE 中编译合约。
2. 准备图文数据
  - 准备一张图片，并将其上传到 IPFS（可以使用 Pinata 或其他工具）。
  - 创建一个 JSON 文件，描述 NFT 的属性（如名称、描述、图片链接等）。
  - 将 JSON 文件上传到 IPFS，获取元数据链接。
  - JSON文件参考 https://docs.opensea.io/docs/metadata-standards
3. 部署合约到测试网
  - 在 Remix IDE 中连接 MetaMask，并确保 MetaMask 连接到 Goerli 或 Sepolia 测试网。
  - 部署 NFT 合约到测试网，并记录合约地址。
4. 铸造 NFT
  - 使用 mintNFT 函数铸造 NFT：
  - 在 recipient 字段中输入你的钱包地址。
  - 在 tokenURI 字段中输入元数据的 IPFS 链接。
  - 在 MetaMask 中确认交易。
5. 查看 NFT
  - 打开 OpenSea 测试网 或 Etherscan 测试网。
  - 连接你的钱包，查看你铸造的 NFT。
 */

// 测试网地址：0x33e9f8b5AEd0108B28C14ce22fB6E600065A8Fea

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MyNFT
 * @dev 基于 OpenZeppelin ERC721 标准的 NFT 合约
 *
 * 解题思路：
 * - 使用 OpenZeppelin 库确保安全性和标准兼容性
 * - 继承 ERC721URIStorage 支持独立元数据
 * - 使用 Ownable 实现权限控制
 * - 使用简单计数器管理 Token ID
 */
contract MyNFT is ERC721, ERC721URIStorage, Ownable {
    // ==================== 状态变量 ====================

    /**
     * @dev Token ID 计数器，防止溢出
     */
    uint256 private _tokenIdCounter;

    // ==================== 事件定义 ====================
    // 注意：ERC721 标准事件已在 OpenZeppelin 基类中定义
    // Transfer, Approval, ApprovalForAll 事件由基类自动处理

    // ==================== 构造函数 ====================

    /**
     * @dev 构造函数，初始化 NFT 名称和符号
     * @param name_ NFT 集合名称
     * @param symbol_ NFT 集合符号
     */
    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {
        // Token ID 计数器自动从 0 开始
    }

    // ==================== 重写函数 ====================

    /**
     * @dev 重写 tokenURI 函数以支持 ERC721URIStorage
     */
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev 重写 supportsInterface 函数以支持多重继承
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // ==================== 铸造功能 ====================

    /**
     * @dev 铸造 NFT，只有所有者可调用
     * @param to 接收地址
     * @param tokenURI_ 元数据 URI
     * @return tokenId 新铸造的 Token ID
     */
    function mintNFT(
        address to,
        string memory tokenURI_
    ) public onlyOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter; // 获取当前 Token ID
        _tokenIdCounter++; // 先递增计数器

        _safeMint(to, tokenId); // 使用 OpenZeppelin 的安全铸造
        _setTokenURI(tokenId, tokenURI_); // 设置元数据 URI

        return tokenId; // 返回新的 Token ID
    }

    // ==================== 查询功能 ====================

    /**
     * @dev 获取下一个 Token ID
     */
    function getNextTokenId() public view returns (uint256) {
        return _tokenIdCounter;
    }

    /**
     * @dev 获取已铸造的 NFT 总数
     */
    function getTotalSupply() public view returns (uint256) {
        return _tokenIdCounter;
    }

    /**
     * @dev 检查 Token ID 是否存在
     */
    function exists(uint256 tokenId) public view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    // ==================== 内部函数 ====================
    // 注意：大部分内部函数已由 OpenZeppelin 库提供，这里只保留必要的自定义逻辑
}

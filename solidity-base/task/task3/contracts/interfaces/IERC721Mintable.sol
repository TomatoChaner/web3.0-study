// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title IERC721Mintable
 * @dev 具有铸造功能的ERC721代币接口
 * @notice 扩展IERC721接口，增加铸造和销毁功能
 */
interface IERC721Mintable is IERC721 {
    /**
     * @dev 铸造新代币时触发的事件
     * @param to 接收代币的地址
     * @param tokenId 铸造的代币ID
     * @param tokenURI 代币的元数据URI
     */
    event TokenMinted(address indexed to, uint256 indexed tokenId, string tokenURI);

    /**
     * @dev 销毁代币时触发的事件
     * @param tokenId 被销毁的代币ID
     */
    event TokenBurned(uint256 indexed tokenId);

    /**
     * @dev 向指定地址铸造新代币
     * @param to 铸造代币的目标地址
     * @param tokenURI 代币的元数据URI
     * @return tokenId 新铸造代币的ID
     */
    function mint(address to, string calldata tokenURI) external returns (uint256 tokenId);

    /**
     * @dev 销毁代币
     * @param tokenId 要销毁的代币ID
     */
    function burn(uint256 tokenId) external;

    /**
     * @dev 返回已铸造代币的总数量
     * @return 代币的总供应量
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev 检查地址是否具有铸造权限
     * @param account 要检查的地址
     * @return 如果地址可以铸造代币则返回true
     */
    function canMint(address account) external view returns (bool);

    /**
     * @dev 设置代币元数据的基础URI
     * @param baseURI 新的基础URI
     */
    function setBaseURI(string calldata baseURI) external;

    /**
     * @dev 返回代币元数据的基础URI
     * @return 当前的基础URI
     */
    function baseURI() external view returns (string memory);
}
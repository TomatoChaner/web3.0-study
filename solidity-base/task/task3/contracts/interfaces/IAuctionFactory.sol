// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IAuctionFactory
 * @dev 拍卖工厂功能接口
 * @notice 定义创建和管理拍卖合约的工厂操作
 */
interface IAuctionFactory {
    /**
     * @dev 拍卖行模板信息
     */
    struct AuctionTemplate {
        address implementation;  // 实现合约地址
        string version;         // 模板版本
        bool active;           // 模板是否激活
        uint256 createdAt;     // 创建时间戳
    }

    /**
     * @dev 创建新拍卖行时触发的事件
     */
    event AuctionHouseCreated(
        address indexed auctionHouse,
        address indexed owner,
        address indexed nftContract,
        string name,
        uint256 timestamp
    );

    /**
     * @dev 添加新模板时触发的事件
     */
    event TemplateAdded(
        uint256 indexed templateId,
        address indexed implementation,
        string version
    );

    /**
     * @dev 更新模板时触发的事件
     */
    event TemplateUpdated(
        uint256 indexed templateId,
        address indexed newImplementation,
        string newVersion
    );

    /**
     * @dev 停用模板时触发的事件
     */
    event TemplateDeactivated(
        uint256 indexed templateId
    );

    /**
     * @dev 创建新的拍卖行合约
     * @param nftContract 此拍卖行的NFT合约地址
     * @param name 拍卖行名称
     * @param templateId 用于部署的模板ID
     * @param initData 拍卖行的初始化数据
     * @return auctionHouse 创建的拍卖行地址
     */
    function createAuctionHouse(
        address nftContract,
        string calldata name,
        uint256 templateId,
        bytes calldata initData
    ) external payable returns (address auctionHouse);

    /**
     * @dev 添加新的拍卖行模板
     * @param implementation 实现合约地址
     * @param version 此模板的版本字符串
     * @return templateId 添加的模板ID
     */
    function addTemplate(
        address implementation,
        string calldata version
    ) external returns (uint256 templateId);

    /**
     * @dev 更新现有模板
     * @param templateId 要更新的模板ID
     * @param newImplementation 新的实现地址
     * @param newVersion 新的版本字符串
     */
    function updateTemplate(
        uint256 templateId,
        address newImplementation,
        string calldata newVersion
    ) external;

    /**
     * @dev 停用模板
     * @param templateId 要停用的模板ID
     */
    function deactivateTemplate(uint256 templateId) external;

    /**
     * @dev 返回模板信息
     * @param templateId 模板ID
     * @return 模板信息结构体
     */
    function getTemplate(uint256 templateId) external view returns (AuctionTemplate memory);

    /**
     * @dev 返回所有活跃模板
     * @return templateIds 活跃模板ID数组
     */
    function getActiveTemplates() external view returns (uint256[] memory templateIds);

    /**
     * @dev 返回由所有者创建的拍卖行
     * @param owner 所有者地址
     * @return auctionHouses 拍卖行地址数组
     */
    function getAuctionHousesByOwner(address owner) external view returns (address[] memory auctionHouses);

    /**
     * @dev 返回特定NFT合约的拍卖行
     * @param nftContract NFT合约地址
     * @return auctionHouses 拍卖行地址数组
     */
    function getAuctionHousesByNFT(address nftContract) external view returns (address[] memory auctionHouses);

    /**
     * @dev 检查地址是否为此工厂创建的有效拍卖行
     * @param auctionHouse 要检查的地址
     * @return 如果是有效拍卖行则返回true
     */
    function isValidAuctionHouse(address auctionHouse) external view returns (bool);

    /**
     * @dev 返回创建的拍卖行总数
     * @return 总数量
     */
    function getTotalAuctionHouses() external view returns (uint256);

    /**
     * @dev 返回模板总数
     * @return 总数量
     */
    function getTotalTemplates() external view returns (uint256);

    /**
     * @dev 返回工厂所有者
     * @return 所有者地址
     */
    function owner() external view returns (address);

    /**
     * @dev 返回工厂版本
     * @return 版本字符串
     */
    function version() external view returns (string memory);
}
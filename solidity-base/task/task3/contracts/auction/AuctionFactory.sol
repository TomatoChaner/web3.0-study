// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./AuctionHouse.sol";
import "../interfaces/IAuctionFactory.sol";

/**
 * @title AuctionFactory
 * @dev 拍卖工厂合约，负责创建和管理拍卖行实例
 * @notice 此合约用于统一创建和管理拍卖行合约实例
 */
contract AuctionFactory is IAuctionFactory, Ownable, ReentrancyGuard, Pausable {
    using Clones for address;
    
    // 拍卖行计数器
    uint256 private _auctionHouseCounter;
    
    // 模板计数器
    uint256 private _templateCounter;
    
    // 模板存储：模板ID => 模板信息
    mapping(uint256 => AuctionTemplate) private _templates;
    
    // 拍卖行注册表：拍卖行地址 => 是否有效
    mapping(address => bool) private _validAuctionHouses;
    
    // 用户创建的拍卖行列表：用户地址 => 拍卖行地址数组
    mapping(address => address[]) private _userAuctionHouses;
    
    // NFT合约对应的拍卖行列表：NFT合约地址 => 拍卖行地址数组
    mapping(address => address[]) private _nftAuctionHouses;
    
    // 活跃模板ID数组
    uint256[] private _activeTemplates;
    
    // 全局配置参数
    struct GlobalConfig {
        uint256 platformFeeRate;      // 平台手续费率 (基点，10000 = 100%)
        address feeRecipient;          // 手续费接收地址
        address priceOracle;           // 价格预言机地址
        uint256 creationFee;           // 创建拍卖行的费用
    }
    
    GlobalConfig public globalConfig;
    
    // 支持的NFT合约白名单
    mapping(address => bool) public supportedNFTs;
    
    // 额外事件定义
    event GlobalConfigUpdated(
        uint256 platformFeeRate,
        address feeRecipient,
        uint256 creationFee
    );
    
    event NFTSupportUpdated(address indexed nftContract, bool supported);
    event CreationFeeCollected(address indexed creator, uint256 amount);
    
    /**
     * @dev 构造函数
     * @param _feeRecipient 手续费接收地址
     * @param _priceOracle 价格预言机地址
     */
    constructor(address _feeRecipient, address _priceOracle) Ownable(msg.sender) {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        require(_priceOracle != address(0), "Invalid price oracle");
        
        globalConfig = GlobalConfig({
            platformFeeRate: 250,           // 2.5%
            feeRecipient: _feeRecipient,
            priceOracle: _priceOracle,
            creationFee: 0.001 ether        // 创建费用0.001 ETH
        });
        
        // 添加默认模板
        _addDefaultTemplate();
    }
    
    /**
     * @dev 添加默认拍卖行模板
     */
    function _addDefaultTemplate() private {
        // 部署一个AuctionHouse作为模板
        AuctionHouse template = new AuctionHouse(globalConfig.feeRecipient, globalConfig.priceOracle);
        
        _templates[_templateCounter] = AuctionTemplate({
            implementation: address(template),
            version: "1.0.0",
            active: true,
            createdAt: block.timestamp
        });
        
        _activeTemplates.push(_templateCounter);
        
        emit TemplateAdded(_templateCounter, address(template), "1.0.0");
        _templateCounter++;
    }
    
    /**
     * @dev 创建新的拍卖行合约
     * @param nftContract 此拍卖行的NFT合约地址
     * @param name 拍卖行名称
     * @param templateId 用于部署的模板ID
     * @param initData 拍卖行的初始化数据（暂未使用）
     * @return auctionHouse 创建的拍卖行地址
     */
    function createAuctionHouse(
        address nftContract,
        string calldata name,
        uint256 templateId,
        bytes calldata initData
    ) external payable nonReentrant whenNotPaused returns (address auctionHouse) {
        require(supportedNFTs[nftContract], "NFT contract not supported");
        // 注意：这里移除了payable检查，因为接口定义为非payable
        require(templateId < _templateCounter, "Invalid template ID");
        require(_templates[templateId].active, "Template not active");
        
        // 使用克隆工厂创建拍卖行实例
        address template = _templates[templateId].implementation;
        auctionHouse = template.clone();
        
        // 初始化拍卖行（调用构造函数逻辑）
        AuctionHouse(auctionHouse).initialize(globalConfig.feeRecipient, globalConfig.priceOracle);
        
        // 注册拍卖行实例
        _validAuctionHouses[auctionHouse] = true;
        _userAuctionHouses[msg.sender].push(auctionHouse);
        _nftAuctionHouses[nftContract].push(auctionHouse);
        _auctionHouseCounter++;
        
        // 注意：移除了收取创建费用的逻辑，因为函数不再是payable
        
        emit AuctionHouseCreated(auctionHouse, msg.sender, nftContract, name, block.timestamp);
        
        return auctionHouse;
    }
    
    /**
     * @dev 添加新的拍卖行模板
     * @param implementation 实现合约地址
     * @param templateVersion 此模板的版本字符串
     * @return templateId 添加的模板ID
     */
    function addTemplate(
        address implementation,
        string calldata templateVersion
    ) external onlyOwner returns (uint256 templateId) {
        require(implementation != address(0), "Invalid implementation");
        require(bytes(templateVersion).length > 0, "Invalid version");
        
        templateId = _templateCounter;
        
        _templates[templateId] = AuctionTemplate({
            implementation: implementation,
            version: templateVersion,
            active: true,
            createdAt: block.timestamp
        });
        
        _activeTemplates.push(templateId);
        
        emit TemplateAdded(templateId, implementation, templateVersion);
        _templateCounter++;
        
        return templateId;
    }
    
    /**
     * @dev 更新现有模板
     * @param templateId 要更新的模板ID
     * @param newImplementation 新的实现地址
     * @param newTemplateVersion 新的版本字符串
     */
    function updateTemplate(
        uint256 templateId,
        address newImplementation,
        string calldata newTemplateVersion
    ) external onlyOwner {
        require(templateId < _templateCounter, "Invalid template ID");
        require(newImplementation != address(0), "Invalid implementation");
        require(bytes(newTemplateVersion).length > 0, "Invalid version");
        
        _templates[templateId].implementation = newImplementation;
        _templates[templateId].version = newTemplateVersion;
        
        emit TemplateUpdated(templateId, newImplementation, newTemplateVersion);
    }
    
    /**
     * @dev 停用模板
     * @param templateId 要停用的模板ID
     */
    function deactivateTemplate(uint256 templateId) external onlyOwner {
        require(templateId < _templateCounter, "Invalid template ID");
        require(_templates[templateId].active, "Template already inactive");
        
        _templates[templateId].active = false;
        
        // 从活跃模板数组中移除
        for (uint256 i = 0; i < _activeTemplates.length; i++) {
            if (_activeTemplates[i] == templateId) {
                _activeTemplates[i] = _activeTemplates[_activeTemplates.length - 1];
                _activeTemplates.pop();
                break;
            }
        }
        
        emit TemplateDeactivated(templateId);
    }
    
    /**
     * @dev 返回模板信息
     * @param templateId 模板ID
     * @return 模板信息结构体
     */
    function getTemplate(uint256 templateId) external view returns (AuctionTemplate memory) {
        require(templateId < _templateCounter, "Invalid template ID");
        return _templates[templateId];
    }
    
    /**
     * @dev 返回所有活跃模板
     * @return templateIds 活跃模板ID数组
     */
    function getActiveTemplates() external view returns (uint256[] memory templateIds) {
        return _activeTemplates;
    }
    
    /**
     * @dev 根据所有者地址获取其创建的拍卖行
     * @param ownerAddress 所有者地址
     * @return auctionHouses 拍卖行地址数组
     */
    function getAuctionHousesByOwner(address ownerAddress) external view returns (address[] memory auctionHouses) {
        return _userAuctionHouses[ownerAddress];
    }
    
    /**
     * @dev 返回特定NFT合约的拍卖行
     * @param nftContract NFT合约地址
     * @return auctionHouses 拍卖行地址数组
     */
    function getAuctionHousesByNFT(address nftContract) external view returns (address[] memory auctionHouses) {
        return _nftAuctionHouses[nftContract];
    }
    
    /**
     * @dev 检查地址是否为此工厂创建的有效拍卖行
     * @param auctionHouse 要检查的地址
     * @return 如果是有效拍卖行则返回true
     */
    function isValidAuctionHouse(address auctionHouse) external view returns (bool) {
        return _validAuctionHouses[auctionHouse];
    }
    
    /**
     * @dev 返回创建的拍卖行总数
     * @return 总数量
     */
    function getTotalAuctionHouses() external view returns (uint256) {
        return _auctionHouseCounter;
    }
    
    /**
     * @dev 返回模板总数
     * @return 总数量
     */
    function getTotalTemplates() external view returns (uint256) {
        return _templateCounter;
    }
    
    /**
     * @dev 重写owner函数以解决继承冲突
     * @return 合约所有者地址
     */
    function owner() public view override(Ownable, IAuctionFactory) returns (address) {
        return Ownable.owner();
    }
    
    /**
     * @dev 更新全局配置（仅所有者）
     * @param _platformFeeRate 平台手续费率
     * @param _feeRecipient 手续费接收地址
     * @param _priceOracle 价格预言机地址
     * @param _creationFee 创建费用
     */
    function updateGlobalConfig(
        uint256 _platformFeeRate,
        address _feeRecipient,
        address _priceOracle,
        uint256 _creationFee
    ) external onlyOwner {
        require(_platformFeeRate <= 1000, "Fee rate too high"); // 最大10%
        require(_feeRecipient != address(0), "Invalid fee recipient");
        require(_priceOracle != address(0), "Invalid price oracle");
        
        globalConfig.platformFeeRate = _platformFeeRate;
        globalConfig.feeRecipient = _feeRecipient;
        globalConfig.priceOracle = _priceOracle;
        globalConfig.creationFee = _creationFee;
        
        emit GlobalConfigUpdated(_platformFeeRate, _feeRecipient, _creationFee);
    }
    
    /**
     * @dev 设置NFT合约支持状态（仅所有者）
     * @param nftContract NFT合约地址
     * @param supported 是否支持
     */
    function setNFTSupport(address nftContract, bool supported) external onlyOwner {
        require(nftContract != address(0), "Invalid NFT contract");
        supportedNFTs[nftContract] = supported;
        emit NFTSupportUpdated(nftContract, supported);
    }
    
    /**
     * @dev 批量设置NFT合约支持状态（仅所有者）
     * @param nftContracts NFT合约地址数组
     * @param supported 是否支持
     */
    function batchSetNFTSupport(address[] calldata nftContracts, bool supported) external onlyOwner {
        for (uint256 i = 0; i < nftContracts.length; i++) {
            require(nftContracts[i] != address(0), "Invalid NFT contract");
            supportedNFTs[nftContracts[i]] = supported;
            emit NFTSupportUpdated(nftContracts[i], supported);
        }
    }
    
    /**
     * @dev 暂停合约（仅所有者）
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev 恢复合约（仅所有者）
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev 紧急提取合约中的ETH（仅所有者）
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Withdraw failed");
    }
    
    /**
     * @dev 获取合约版本
     * @return 版本字符串
     */
    function version() external pure returns (string memory) {
        return "1.0.0";
    }
}
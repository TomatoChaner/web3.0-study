// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../proxy/ProxyAdmin.sol";
import "../auction/AuctionHouseUpgradeable.sol";
import "../interfaces/IAuctionFactory.sol";

/**
 * @title AuctionFactoryUpgradeable
 * @dev 可升级的拍卖工厂合约，负责创建和管理可升级的拍卖行实例
 * @notice 此合约用于统一创建和管理可升级的拍卖行合约实例，使用UUPS代理模式
 */
contract AuctionFactoryUpgradeable is 
    Initializable,
    UUPSUpgradeable,
    IAuctionFactory,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    // ============ 存储变量 ============
    
    /// @dev 拍卖行计数器
    uint256 private _auctionHouseCounter;
    
    /// @dev 模板计数器
    uint256 private _templateCounter;
    
    /// @dev 模板存储：模板ID => 模板信息
    mapping(uint256 => AuctionTemplate) private _templates;
    
    /// @dev 拍卖行注册表：拍卖行地址 => 是否有效
    mapping(address => bool) private _validAuctionHouses;
    
    /// @dev 用户创建的拍卖行列表：用户地址 => 拍卖行地址数组
    mapping(address => address[]) private _userAuctionHouses;
    
    /// @dev NFT合约对应的拍卖行列表：NFT合约地址 => 拍卖行地址数组
    mapping(address => address[]) private _nftAuctionHouses;
    
    /// @dev 活跃模板ID数组
    uint256[] private _activeTemplates;
    
    /// @dev 代理管理合约
    ProxyAdmin public proxyAdmin;
    
    /// @dev 全局配置参数
    struct GlobalConfig {
        uint256 platformFeeRate;      // 平台手续费率 (基点，10000 = 100%)
        address feeRecipient;          // 手续费接收地址
        address priceOracle;           // 价格预言机地址
        uint256 creationFee;           // 创建拍卖行的费用
    }
    
    GlobalConfig public globalConfig;
    
    /// @dev 支持的NFT合约白名单
    mapping(address => bool) public supportedNFTs;
    
    /// @dev 代理合约映射：代理地址 => 实现地址
    mapping(address => address) public proxyImplementations;

    // ============ 事件 ============
    
    event GlobalConfigUpdated(
        uint256 platformFeeRate,
        address feeRecipient,
        uint256 creationFee
    );
    
    event NFTSupportUpdated(address indexed nftContract, bool supported);
    event CreationFeeCollected(address indexed creator, uint256 amount);
    event ProxyAdminUpdated(address indexed oldAdmin, address indexed newAdmin);
    event AuctionHouseUpgraded(
        address indexed proxy,
        address indexed oldImplementation,
        address indexed newImplementation
    );

    // ============ 初始化函数 ============
    
    /**
     * @dev 初始化函数，替代构造函数
     * @param _feeRecipient 手续费接收地址
     * @param _priceOracle 价格预言机地址
     * @param _proxyAdmin 代理管理合约地址
     */
    function initialize(
        address _feeRecipient,
        address _priceOracle,
        address _proxyAdmin
    ) public initializer {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        require(_priceOracle != address(0), "Invalid price oracle");
        require(_proxyAdmin != address(0), "Invalid proxy admin");
        
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        
        globalConfig = GlobalConfig({
            platformFeeRate: 250,           // 2.5%
            feeRecipient: _feeRecipient,
            priceOracle: _priceOracle,
            creationFee: 0.001 ether        // 创建费用0.001 ETH
        });
        
        proxyAdmin = ProxyAdmin(_proxyAdmin);
        _auctionHouseCounter = 0;
        _templateCounter = 0;
        
        // 添加默认模板
        _addDefaultTemplate();
    }

    // ============ 升级授权 ============
    
    /**
     * @dev 授权升级函数，只有所有者可以升级
     * @param newImplementation 新实现合约地址
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // ============ 核心功能 ============
    
    /**
     * @dev 添加默认拍卖行模板
     */
    function _addDefaultTemplate() private {
        // 部署一个AuctionHouseUpgradeable作为模板
        AuctionHouseUpgradeable template = new AuctionHouseUpgradeable();
        
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
     * @dev 创建新的可升级拍卖行合约
     * @param nftContract 此拍卖行的NFT合约地址
     * @param name 拍卖行名称
     * @param templateId 用于部署的模板ID
     * @param initData 拍卖行的初始化数据（暂未使用）
     * @return auctionHouse 创建的拍卖行代理地址
     */
    function createAuctionHouse(
        address nftContract,
        string calldata name,
        uint256 templateId,
        bytes calldata initData
    ) external payable nonReentrant whenNotPaused returns (address auctionHouse) {
        require(supportedNFTs[nftContract], "NFT contract not supported");
        require(msg.value >= globalConfig.creationFee, "Insufficient creation fee");
        require(templateId < _templateCounter, "Invalid template ID");
        require(_templates[templateId].active, "Template not active");
        
        // 获取模板实现地址
        address implementation = _templates[templateId].implementation;
        
        // 准备初始化数据
        bytes memory initializeData = abi.encodeWithSelector(
            AuctionHouseUpgradeable.initialize.selector,
            globalConfig.feeRecipient,
            globalConfig.priceOracle
        );
        
        // 通过ProxyAdmin部署代理
        auctionHouse = proxyAdmin.deployProxy(implementation, initializeData);
        
        // 记录代理和实现的映射
        proxyImplementations[auctionHouse] = implementation;
        
        // 注册拍卖行实例
        _validAuctionHouses[auctionHouse] = true;
        _userAuctionHouses[msg.sender].push(auctionHouse);
        _nftAuctionHouses[nftContract].push(auctionHouse);
        _auctionHouseCounter++;
        
        // 收取创建费用
        if (globalConfig.creationFee > 0) {
            (bool success, ) = globalConfig.feeRecipient.call{value: globalConfig.creationFee}("");
            require(success, "Fee transfer failed");
            emit CreationFeeCollected(msg.sender, globalConfig.creationFee);
        }
        
        // 退还多余的ETH
        if (msg.value > globalConfig.creationFee) {
            (bool success, ) = msg.sender.call{value: msg.value - globalConfig.creationFee}("");
            require(success, "Refund failed");
        }
        
        emit AuctionHouseCreated(auctionHouse, msg.sender, nftContract, name, block.timestamp);
        
        return auctionHouse;
    }
    
    /**
     * @dev 升级拍卖行实现
     * @param auctionHouse 拍卖行代理地址
     * @param newImplementation 新实现地址
     */
    function upgradeAuctionHouse(
        address auctionHouse,
        address newImplementation
    ) external onlyOwner {
        require(_validAuctionHouses[auctionHouse], "Invalid auction house");
        require(newImplementation != address(0), "Invalid implementation");
        
        address oldImplementation = proxyImplementations[auctionHouse];
        require(oldImplementation != newImplementation, "Same implementation");
        
        // 通过ProxyAdmin执行升级
        proxyAdmin.upgrade(auctionHouse, newImplementation);
        
        // 更新映射
        proxyImplementations[auctionHouse] = newImplementation;
        
        emit AuctionHouseUpgraded(auctionHouse, oldImplementation, newImplementation);
    }
    
    /**
     * @dev 批量升级拍卖行实现
     * @param auctionHouses 拍卖行代理地址数组
     * @param newImplementation 新实现地址
     */
    function batchUpgradeAuctionHouses(
        address[] calldata auctionHouses,
        address newImplementation
    ) external onlyOwner {
        require(newImplementation != address(0), "Invalid implementation");
        
        for (uint256 i = 0; i < auctionHouses.length; i++) {
            address auctionHouse = auctionHouses[i];
            require(_validAuctionHouses[auctionHouse], "Invalid auction house");
            
            address oldImplementation = proxyImplementations[auctionHouse];
            if (oldImplementation != newImplementation) {
                proxyAdmin.upgrade(auctionHouse, newImplementation);
                proxyImplementations[auctionHouse] = newImplementation;
                emit AuctionHouseUpgraded(auctionHouse, oldImplementation, newImplementation);
            }
        }
    }

    // ============ 模板管理 ============
    
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

    // ============ 查询函数 ============
    
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
     * @dev 返回由所有者创建的拍卖行
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
     * @dev 获取拍卖行的当前实现地址
     * @param auctionHouse 拍卖行代理地址
     * @return implementation 实现地址
     */
    function getAuctionHouseImplementation(address auctionHouse) external view returns (address) {
        return proxyImplementations[auctionHouse];
    }
    
    /**
     * @dev 重写owner函数以解决继承冲突
     * @return 合约所有者地址
     */
    function owner() public view override(OwnableUpgradeable, IAuctionFactory) returns (address) {
        return OwnableUpgradeable.owner();
    }

    // ============ 管理函数 ============
    
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
     * @dev 更新代理管理合约
     * @param _proxyAdmin 新的代理管理合约地址
     */
    function updateProxyAdmin(address _proxyAdmin) external onlyOwner {
        require(_proxyAdmin != address(0), "Invalid proxy admin");
        address oldAdmin = address(proxyAdmin);
        proxyAdmin = ProxyAdmin(_proxyAdmin);
        emit ProxyAdminUpdated(oldAdmin, _proxyAdmin);
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

    // ============ 接收ETH ============
    
    /**
     * @dev 接收ETH函数
     */
    receive() external payable {}
    
    /**
     * @dev 回退函数
     */
    fallback() external payable {}
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IERC721Mintable.sol";

/**
 * @title AuctionNFT
 * @dev 拍卖市场专用的NFT合约，支持铸造、元数据管理和拍卖授权
 * @notice 这是一个ERC721标准的NFT合约，专为拍卖市场设计
 */
contract AuctionNFT is ERC721, ERC721URIStorage, Ownable, ReentrancyGuard, IERC721Mintable {
    // 代币ID计数器
    uint256 private _tokenIdCounter;
    
    // 基础URI
    string private _baseTokenURI;
    
    // 铸造者权限映射
    mapping(address => bool) public minters;
    
    // 拍卖授权映射 - tokenId => 拍卖合约地址
    mapping(uint256 => address) public auctionApprovals;
    
    // 版税信息
    struct RoyaltyInfo {
        address recipient; // 版税接收者
        uint96 percentage; // 版税百分比 (基点，10000 = 100%)
    }
    
    // 代币版税信息映射
    mapping(uint256 => RoyaltyInfo) private _tokenRoyalties;
    
    // 默认版税信息
    RoyaltyInfo private _defaultRoyalty;
    
    // 最大版税百分比 (10% = 1000基点)
    uint96 public constant MAX_ROYALTY_PERCENTAGE = 1000;

    // 修饰符定义
    modifier onlyMinter() {
        require(minters[msg.sender], "AuctionNFT: caller is not a minter");
        _;
    }

    // 事件定义
    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);
    event AuctionApprovalSet(uint256 indexed tokenId, address indexed auctionContract);
    event AuctionApprovalCleared(uint256 indexed tokenId);
    event RoyaltySet(uint256 indexed tokenId, address indexed recipient, uint96 percentage);
    event DefaultRoyaltySet(address indexed recipient, uint96 percentage);

    /**
     * @dev 构造函数
     * @param name NFT集合名称
     * @param symbol NFT集合符号
     */
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
        // 设置部署者为初始铸造者
        minters[msg.sender] = true;
    }

    /**
     * @dev 添加铸造者权限
     * @param minter 要添加的铸造者地址
     */
    function addMinter(address minter) external onlyOwner {
        require(minter != address(0), "AuctionNFT: minter cannot be zero address");
        require(!minters[minter], "AuctionNFT: address is already a minter");
        
        minters[minter] = true;
        emit MinterAdded(minter);
    }

    /**
     * @dev 移除铸造者权限
     * @param minter 要移除的铸造者地址
     */
    function removeMinter(address minter) external onlyOwner {
        require(minters[minter], "AuctionNFT: address is not a minter");
        
        minters[minter] = false;
        emit MinterRemoved(minter);
    }

    /**
     * @dev 铸造NFT
     * @param to 接收者地址
     * @param uri 代币元数据URI
     * @return tokenId 新铸造的代币ID
     */
    function mint(address to, string memory uri) external onlyMinter returns (uint256) {
        require(to != address(0), "AuctionNFT: cannot mint to zero address");
        require(bytes(uri).length > 0, "AuctionNFT: tokenURI cannot be empty");

        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        emit TokenMinted(to, tokenId, uri);
        return tokenId;
    }

    /**
     * @dev 批量铸造NFT
     * @param to 接收者地址
     * @param uris 代币元数据URI数组
     * @return tokenIds 新铸造的代币ID数组
     */
    function mintBatch(address to, string[] memory uris) external onlyMinter returns (uint256[] memory) {
        require(to != address(0), "AuctionNFT: cannot mint to zero address");
        require(uris.length > 0, "AuctionNFT: tokenURIs array cannot be empty");
        require(uris.length <= 100, "AuctionNFT: can mint at most 100 NFTs at once");

        uint256[] memory tokenIds = new uint256[](uris.length);
        
        for (uint256 i = 0; i < uris.length; i++) {
            require(bytes(uris[i]).length > 0, "AuctionNFT: tokenURI cannot be empty");
            
            uint256 tokenId = _tokenIdCounter;
            _tokenIdCounter++;
            
            _safeMint(to, tokenId);
            _setTokenURI(tokenId, uris[i]);
            
            tokenIds[i] = tokenId;
            emit TokenMinted(to, tokenId, uris[i]);
        }

        return tokenIds;
    }

    /**
     * @dev 销毁NFT
     * @param tokenId 要销毁的代币ID
     */
    function burn(uint256 tokenId) external override {
        require(
            ownerOf(tokenId) == msg.sender || 
            getApproved(tokenId) == msg.sender || 
            isApprovedForAll(ownerOf(tokenId), msg.sender),
            "AuctionNFT: caller is not owner nor approved"
        );
        
        // 清除拍卖授权
        if (auctionApprovals[tokenId] != address(0)) {
            delete auctionApprovals[tokenId];
        }
        
        // 清除版税信息
        if (_tokenRoyalties[tokenId].recipient != address(0)) {
            delete _tokenRoyalties[tokenId];
        }
        
        _burn(tokenId);
        emit TokenBurned(tokenId);
    }

    /**
     * @dev 设置拍卖授权
     * @param tokenId 代币ID
     * @param auctionContract 拍卖合约地址
     */
    function setAuctionApproval(uint256 tokenId, address auctionContract) external {
        require(_ownerOf(tokenId) != address(0), "AuctionNFT: token does not exist");
        require(ownerOf(tokenId) == msg.sender, "AuctionNFT: only owner can set auction approval");
        
        auctionApprovals[tokenId] = auctionContract;
        emit AuctionApprovalSet(tokenId, auctionContract);
    }

    /**
     * @dev 清除拍卖授权
     * @param tokenId 代币ID
     */
    function clearAuctionApproval(uint256 tokenId) external {
        require(_ownerOf(tokenId) != address(0), "AuctionNFT: token does not exist");
        require(ownerOf(tokenId) == msg.sender, "AuctionNFT: only owner can clear auction approval");
        
        delete auctionApprovals[tokenId];
        emit AuctionApprovalCleared(tokenId);
    }

    /**
     * @dev 检查是否有拍卖授权
     * @param tokenId 代币ID
     * @param auctionContract 拍卖合约地址
     * @return 是否有授权
     */
    function isApprovedForAuction(uint256 tokenId, address auctionContract) external view returns (bool) {
        return auctionApprovals[tokenId] == auctionContract;
    }

    /**
     * @dev 设置代币版税信息
     * @param tokenId 代币ID
     * @param recipient 版税接收者
     * @param percentage 版税百分比（基点）
     */
    function setTokenRoyalty(uint256 tokenId, address recipient, uint96 percentage) external {
        require(_ownerOf(tokenId) != address(0), "AuctionNFT: token does not exist");
        require(ownerOf(tokenId) == msg.sender, "AuctionNFT: only owner can set royalty");
        require(recipient != address(0), "AuctionNFT: royalty recipient cannot be zero address");
        require(percentage <= MAX_ROYALTY_PERCENTAGE, "AuctionNFT: royalty percentage exceeds maximum");
        
        _tokenRoyalties[tokenId] = RoyaltyInfo(recipient, percentage);
        emit RoyaltySet(tokenId, recipient, percentage);
    }

    /**
     * @dev 设置默认版税信息
     * @param recipient 版税接收者
     * @param percentage 版税百分比（基点）
     */
    function setDefaultRoyalty(address recipient, uint96 percentage) external onlyOwner {
        require(recipient != address(0), "AuctionNFT: royalty recipient cannot be zero address");
        require(percentage <= MAX_ROYALTY_PERCENTAGE, "AuctionNFT: royalty percentage exceeds maximum");
        
        _defaultRoyalty = RoyaltyInfo(recipient, percentage);
        emit DefaultRoyaltySet(recipient, percentage);
    }

    /**
     * @dev 获取版税信息
     * @param tokenId 代币ID
     * @param salePrice 销售价格
     * @return receiver 版税接收者
     * @return royaltyAmount 版税金额
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyalties[tokenId];
        
        // 如果代币没有设置特定版税，使用默认版税
        if (royalty.recipient == address(0)) {
            royalty = _defaultRoyalty;
        }
        
        uint256 royaltyAmount = (salePrice * royalty.percentage) / 10000;
        return (royalty.recipient, royaltyAmount);
    }

    /**
     * @dev 获取下一个代币ID
     * @return 下一个将要铸造的代币ID
     */
    function getNextTokenId() external view returns (uint256) {
        return _tokenIdCounter;
    }

    /**
     * @dev 获取总供应量
     * @return 已铸造的代币总数
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter;
    }

    /**
     * @dev 检查地址是否可以铸造
     * @param account 要检查的地址
     * @return 是否可以铸造
     */
    function canMint(address account) external view returns (bool) {
        return minters[account];
    }

    /**
     * @dev 设置基础URI
     * @param baseURI_ 基础URI
     */
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    /**
     * @dev 获取基础URI
     * @return 基础URI
     */
    function baseURI() external view returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev 检查是否支持接口
     * @param interfaceId 接口ID
     * @return 是否支持
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721URIStorage, IERC165) returns (bool) {
        return interfaceId == type(IERC721Mintable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev 重写tokenURI函数
     * @param tokenId 代币ID
     * @return 代币元数据URI
     */
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }



    /**
     * @dev 重写_update函数，添加转移前检查
     * @param to 接收者地址
     * @param tokenId 代币ID
     * @param auth 授权地址
     * @return 之前的所有者
     */
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        
        // 如果是转移（非铸造和销毁），清除拍卖授权
        if (from != address(0) && to != address(0)) {
            if (auctionApprovals[tokenId] != address(0)) {
                delete auctionApprovals[tokenId];
                emit AuctionApprovalCleared(tokenId);
            }
        }
        
        return super._update(to, tokenId, auth);
    }
}
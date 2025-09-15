// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IPriceOracle.sol";

/**
 * @title AuctionHouseUpgradeable
 * @dev 可升级的拍卖行合约，支持NFT拍卖功能
 * @notice 这是AuctionHouse的可升级版本，使用UUPS代理模式
 */
contract AuctionHouseUpgradeable is 
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using Address for address payable;

    // ============ 存储变量 ============
    
    /// @dev 拍卖状态枚举
    enum AuctionStatus {
        Active,     // 进行中
        Ended,      // 已结束
        Cancelled   // 已取消
    }

    /// @dev 拍卖结构体
    struct Auction {
        uint256 auctionId;        // 拍卖ID
        address nftContract;      // NFT合约地址
        uint256 tokenId;          // NFT Token ID
        address seller;           // 卖家地址
        uint256 startingPrice;    // 起拍价（USD，18位小数）
        uint256 reservePrice;     // 保留价（USD，18位小数）
        uint256 currentBid;       // 当前最高出价（USD，18位小数）
        address currentBidder;    // 当前最高出价者
        address bidToken;         // 当前出价代币地址（address(0)表示ETH）
        uint256 bidTokenAmount;   // 当前出价代币数量
        uint256 startTime;        // 开始时间
        uint256 endTime;          // 结束时间
        AuctionStatus status;     // 拍卖状态
        uint256 bidIncrement;     // 最小加价幅度（USD，18位小数）
    }

    // ============ 状态变量 ============
    
    /// @dev 拍卖ID计数器
    uint256 private _auctionIdCounter;
    
    /// @dev 拍卖映射
    mapping(uint256 => Auction) public auctions;
    
    /// @dev 用户创建的拍卖列表
    mapping(address => uint256[]) public userAuctions;
    
    /// @dev 用户参与的拍卖列表
    mapping(address => uint256[]) public userBids;
    
    /// @dev 价格预言机
    IPriceOracle public priceOracle;
    
    /// @dev 支持的ERC20代币
    mapping(address => bool) public supportedTokens;
    
    /// @dev 平台手续费率（基点，10000 = 100%）
    uint256 public platformFeeRate;
    
    /// @dev 手续费接收地址
    address public feeRecipient;
    
    /// @dev 最小拍卖时长（秒）
    uint256 public constant MIN_AUCTION_DURATION = 1 hours;
    
    /// @dev 最大拍卖时长（秒）
    uint256 public constant MAX_AUCTION_DURATION = 30 days;

    // ============ 事件 ============
    
    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        uint256 startingPrice,
        uint256 reservePrice,
        uint256 startTime,
        uint256 endTime
    );
    
    event BidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 bidAmount,
        uint256 timestamp
    );
    
    event AuctionEnded(
        uint256 indexed auctionId,
        address indexed winner,
        uint256 winningBid,
        uint256 timestamp
    );
    
    event AuctionCancelled(
        uint256 indexed auctionId,
        address indexed seller,
        uint256 timestamp
    );
    
    event PlatformFeeUpdated(uint256 oldFee, uint256 newFee);
    event FeeRecipientUpdated(address oldRecipient, address newRecipient);
    event PriceOracleUpdated(address oldOracle, address newOracle);
    event TokenSupportUpdated(address indexed token, bool supported);

    // ============ 修饰符 ============
    
    modifier validAuction(uint256 auctionId) {
        require(
            auctionId < _auctionIdCounter,
            "AuctionHouse: auction does not exist"
        );
        _;
    }

    modifier onlyActiveBidding(uint256 auctionId) {
        Auction storage auction = auctions[auctionId];
        require(
            auction.status == AuctionStatus.Active,
            "AuctionHouse: auction not active"
        );
        require(
            block.timestamp >= auction.startTime,
            "AuctionHouse: auction not started"
        );
        require(
            block.timestamp < auction.endTime,
            "AuctionHouse: auction ended"
        );
        _;
    }

    // ============ 初始化函数 ============
    
    /**
     * @dev 初始化函数，替代构造函数
     * @param _feeRecipient 手续费接收地址
     * @param _priceOracle 价格预言机地址
     */
    function initialize(
        address _feeRecipient,
        address _priceOracle
    ) public initializer {
        require(_feeRecipient != address(0), "AuctionHouse: invalid fee recipient");
        require(_priceOracle != address(0), "AuctionHouse: invalid price oracle");
        
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        
        feeRecipient = _feeRecipient;
        priceOracle = IPriceOracle(_priceOracle);
        platformFeeRate = 250; // 2.5%
        _auctionIdCounter = 0;
        
        // 默认支持ETH
        supportedTokens[address(0)] = true;
    }

    // ============ 升级授权 ============
    
    /**
     * @dev 授权升级函数，只有所有者可以升级
     * @param newImplementation 新实现合约地址
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // ============ 核心功能 ============
    
    /**
     * @dev 创建拍卖
     * @param nftContract NFT合约地址
     * @param tokenId NFT Token ID
     * @param startingPrice 起拍价
     * @param reservePrice 保留价
     * @param duration 拍卖时长（秒）
     * @param bidIncrement 最小加价幅度
     */
    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startingPrice,
        uint256 reservePrice,
        uint256 duration,
        uint256 bidIncrement
    ) external whenNotPaused nonReentrant returns (uint256) {
        require(
            nftContract != address(0),
            "AuctionHouse: invalid NFT contract"
        );
        require(
            startingPrice > 0,
            "AuctionHouse: starting price must be greater than 0"
        );
        require(
            reservePrice >= startingPrice,
            "AuctionHouse: reserve price must be >= starting price"
        );
        require(
            duration >= MIN_AUCTION_DURATION &&
                duration <= MAX_AUCTION_DURATION,
            "AuctionHouse: invalid auction duration"
        );
        require(
            bidIncrement > 0,
            "AuctionHouse: bid increment must be greater than 0"
        );

        // 验证NFT所有权和授权
        IERC721 nft = IERC721(nftContract);
        require(
            nft.ownerOf(tokenId) == msg.sender,
            "AuctionHouse: not NFT owner"
        );
        require(
            nft.isApprovedForAll(msg.sender, address(this)) ||
                nft.getApproved(tokenId) == address(this),
            "AuctionHouse: NFT not approved"
        );

        uint256 auctionId = _auctionIdCounter++;
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;

        auctions[auctionId] = Auction({
            auctionId: auctionId,
            nftContract: nftContract,
            tokenId: tokenId,
            seller: msg.sender,
            startingPrice: startingPrice,
            reservePrice: reservePrice,
            currentBid: 0,
            currentBidder: address(0),
            bidToken: address(0),
            bidTokenAmount: 0,
            startTime: startTime,
            endTime: endTime,
            status: AuctionStatus.Active,
            bidIncrement: bidIncrement
        });

        userAuctions[msg.sender].push(auctionId);

        // 托管NFT
        nft.transferFrom(msg.sender, address(this), tokenId);

        emit AuctionCreated(
            auctionId,
            nftContract,
            tokenId,
            msg.sender,
            startingPrice,
            reservePrice,
            startTime,
            endTime
        );

        return auctionId;
    }

    /**
     * @dev ETH出价
     * @param auctionId 拍卖ID
     */
    function placeBid(
        uint256 auctionId
    )
        external
        payable
        validAuction(auctionId)
        onlyActiveBidding(auctionId)
        whenNotPaused
        nonReentrant
    {
        _placeBid(auctionId, address(0), msg.value);
    }

    /**
     * @dev ERC20代币出价
     * @param auctionId 拍卖ID
     * @param token 代币地址
     * @param amount 代币数量
     */
    function placeBidWithToken(
        uint256 auctionId,
        address token,
        uint256 amount
    )
        external
        validAuction(auctionId)
        onlyActiveBidding(auctionId)
        whenNotPaused
        nonReentrant
    {
        require(token != address(0), "AuctionHouse: use placeBid for ETH");
        require(supportedTokens[token], "AuctionHouse: token not supported");
        require(amount > 0, "AuctionHouse: amount must be greater than 0");
        
        // 转移代币到合约
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        
        _placeBid(auctionId, token, amount);
    }

    /**
     * @dev 内部出价逻辑
     * @param auctionId 拍卖ID
     * @param token 代币地址（address(0)表示ETH）
     * @param amount 代币数量
     */
    function _placeBid(
        uint256 auctionId,
        address token,
        uint256 amount
    ) internal {
        Auction storage auction = auctions[auctionId];
        require(
            msg.sender != auction.seller,
            "AuctionHouse: seller cannot bid"
        );
        require(amount > 0, "AuctionHouse: bid must be greater than 0");

        // 将出价转换为USD价值
        uint256 bidValueInUSD = priceOracle.convertPrice(token, address(0), amount);
        
        uint256 minBid = auction.currentBid == 0
            ? auction.startingPrice
            : auction.currentBid + auction.bidIncrement;

        require(bidValueInUSD >= minBid, "AuctionHouse: bid too low");

        // 退还前一个出价者的资金
        if (auction.currentBidder != address(0)) {
            _refundBidder(auction.currentBidder, auction.bidToken, auction.bidTokenAmount);
        }

        // 更新拍卖信息
        auction.currentBid = bidValueInUSD;
        auction.currentBidder = msg.sender;
        auction.bidToken = token;
        auction.bidTokenAmount = amount;

        // 记录用户参与的拍卖
        userBids[msg.sender].push(auctionId);

        emit BidPlaced(auctionId, msg.sender, bidValueInUSD, block.timestamp);
    }

    /**
     * @dev 退还出价者资金
     * @param bidder 出价者地址
     * @param token 代币地址（address(0)表示ETH）
     * @param amount 退还数量
     */
    function _refundBidder(address bidder, address token, uint256 amount) internal {
        if (token == address(0)) {
            // 退还ETH
            payable(bidder).sendValue(amount);
        } else {
            // 退还ERC20代币
            IERC20(token).transfer(bidder, amount);
        }
    }

    /**
     * @dev 结束拍卖
     * @param auctionId 拍卖ID
     */
    function endAuction(
        uint256 auctionId
    ) external validAuction(auctionId) whenNotPaused nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(
            auction.status == AuctionStatus.Active,
            "AuctionHouse: auction not active"
        );
        require(
            block.timestamp >= auction.endTime,
            "AuctionHouse: auction not ended"
        );

        auction.status = AuctionStatus.Ended;

        IERC721 nft = IERC721(auction.nftContract);

        // 检查是否达到保留价
        if (
            auction.currentBid >= auction.reservePrice &&
            auction.currentBidder != address(0)
        ) {
            // 拍卖成功，转移NFT和资金
            nft.transferFrom(
                address(this),
                auction.currentBidder,
                auction.tokenId
            );

            // 计算平台手续费（基于实际代币数量）
            uint256 platformFeeAmount = (auction.bidTokenAmount * platformFeeRate) / 10000;
            uint256 sellerAmount = auction.bidTokenAmount - platformFeeAmount;

            // 转移资金
            if (platformFeeAmount > 0) {
                if (auction.bidToken == address(0)) {
                    payable(feeRecipient).sendValue(platformFeeAmount);
                } else {
                    IERC20(auction.bidToken).transfer(feeRecipient, platformFeeAmount);
                }
            }
            
            if (auction.bidToken == address(0)) {
                payable(auction.seller).sendValue(sellerAmount);
            } else {
                IERC20(auction.bidToken).transfer(auction.seller, sellerAmount);
            }

            emit AuctionEnded(
                auctionId,
                auction.currentBidder,
                auction.currentBid,
                block.timestamp
            );
        } else {
            // 拍卖失败，退还NFT和资金
            nft.transferFrom(address(this), auction.seller, auction.tokenId);

            if (auction.currentBidder != address(0)) {
                _refundBidder(auction.currentBidder, auction.bidToken, auction.bidTokenAmount);
            }

            emit AuctionEnded(auctionId, address(0), 0, block.timestamp);
        }
    }

    /**
     * @dev 取消拍卖（仅卖家可调用，且无人出价时）
     * @param auctionId 拍卖ID
     */
    function cancelAuction(
        uint256 auctionId
    ) external validAuction(auctionId) whenNotPaused nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(
            msg.sender == auction.seller,
            "AuctionHouse: only seller can cancel"
        );
        require(
            auction.status == AuctionStatus.Active,
            "AuctionHouse: auction not active"
        );
        require(
            auction.currentBidder == address(0),
            "AuctionHouse: cannot cancel with bids"
        );

        auction.status = AuctionStatus.Cancelled;

        // 退还NFT给卖家
        IERC721(auction.nftContract).transferFrom(
            address(this),
            auction.seller,
            auction.tokenId
        );

        emit AuctionCancelled(auctionId, auction.seller, block.timestamp);
    }

    // ============ 查询函数 ============
    
    /**
     * @dev 获取拍卖信息
     * @param auctionId 拍卖ID
     */
    function getAuction(
        uint256 auctionId
    ) external view validAuction(auctionId) returns (Auction memory) {
        return auctions[auctionId];
    }

    /**
     * @dev 获取用户创建的拍卖列表
     * @param user 用户地址
     */
    function getUserAuctions(
        address user
    ) external view returns (uint256[] memory) {
        return userAuctions[user];
    }

    /**
     * @dev 获取用户参与的拍卖列表
     * @param user 用户地址
     */
    function getUserBids(
        address user
    ) external view returns (uint256[] memory) {
        return userBids[user];
    }

    /**
     * @dev 获取当前拍卖ID计数器
     */
    function getCurrentAuctionId() external view returns (uint256) {
        return _auctionIdCounter;
    }

    /**
     * @dev 获取拍卖的USD价值信息
     * @param auctionId 拍卖ID
     */
    function getAuctionUSDValue(uint256 auctionId) external view validAuction(auctionId) returns (
        uint256 startingPriceUSD,
        uint256 reservePriceUSD,
        uint256 currentBidUSD,
        uint256 minNextBidUSD
    ) {
        Auction storage auction = auctions[auctionId];
        startingPriceUSD = auction.startingPrice;
        reservePriceUSD = auction.reservePrice;
        currentBidUSD = auction.currentBid;
        
        minNextBidUSD = auction.currentBid == 0
            ? auction.startingPrice
            : auction.currentBid + auction.bidIncrement;
    }

    /**
     * @dev 获取代币在USD中的价值
     * @param token 代币地址（address(0)表示ETH）
     * @param amount 代币数量
     */
    function getTokenValueInUSD(address token, uint256 amount) external view returns (uint256) {
        return priceOracle.convertPrice(token, address(0), amount);
    }

    // ============ 管理函数 ============
    
    /**
     * @dev 设置平台手续费率（仅所有者）
     * @param newFeeRate 新的手续费率（基点）
     */
    function setPlatformFeeRate(uint256 newFeeRate) external onlyOwner {
        require(newFeeRate <= 1000, "AuctionHouse: fee rate too high"); // 最大10%
        uint256 oldFee = platformFeeRate;
        platformFeeRate = newFeeRate;
        emit PlatformFeeUpdated(oldFee, newFeeRate);
    }

    /**
     * @dev 设置手续费接收地址（仅所有者）
     * @param newRecipient 新的接收地址
     */
    function setFeeRecipient(address newRecipient) external onlyOwner {
        require(newRecipient != address(0), "AuctionHouse: invalid recipient");
        address oldRecipient = feeRecipient;
        feeRecipient = newRecipient;
        emit FeeRecipientUpdated(oldRecipient, newRecipient);
    }

    /**
     * @dev 设置价格预言机地址（仅所有者）
     * @param newOracle 新的价格预言机地址
     */
    function setPriceOracle(address newOracle) external onlyOwner {
        require(newOracle != address(0), "AuctionHouse: invalid oracle");
        address oldOracle = address(priceOracle);
        priceOracle = IPriceOracle(newOracle);
        emit PriceOracleUpdated(oldOracle, newOracle);
    }

    /**
     * @dev 设置代币支持状态（仅所有者）
     * @param token 代币地址
     * @param supported 是否支持
     */
    function setSupportedToken(address token, bool supported) external onlyOwner {
        require(token != address(0), "AuctionHouse: cannot modify ETH support");
        supportedTokens[token] = supported;
        emit TokenSupportUpdated(token, supported);
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
     * @dev 紧急提取ETH（仅所有者，仅在暂停状态下）
     */
    function emergencyWithdraw() external onlyOwner whenPaused {
        payable(owner()).sendValue(address(this).balance);
    }

    /**
     * @dev 检查合约是否支持某个接口
     */
    function supportsInterface(
        bytes4 interfaceId
    ) external pure returns (bool) {
        return interfaceId == type(IERC721).interfaceId;
    }

    /**
     * @dev 获取合约版本
     */
    function version() external pure returns (string memory) {
        return "1.0.0";
    }
}
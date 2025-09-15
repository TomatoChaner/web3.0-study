// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IPriceOracle.sol";

/**
 * @title AuctionHouseProxy
 * @dev UUPS可升级的拍卖行合约代理
 * @notice 这是AuctionHouse的可升级版本，使用UUPS代理模式
 */
contract AuctionHouseProxy is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;

    // ============ 存储变量 ============

    /// @dev 拍卖状态枚举
    enum AuctionStatus {
        Active, // 活跃
        Ended, // 已结束
        Cancelled // 已取消
    }

    /// @dev 拍卖结构体
    struct Auction {
        address seller; // 卖家地址
        address nftContract; // NFT合约地址
        uint256 tokenId; // NFT代币ID
        uint256 startingPrice; // 起始价格
        uint256 reservePrice; // 保留价格
        uint256 currentBid; // 当前出价
        address currentBidder; // 当前出价者
        address bidToken; // 出价代币地址(0x0表示ETH)
        uint256 bidTokenAmount; // 出价代币数量
        uint256 endTime; // 结束时间
        uint256 bidIncrement; // 最小加价幅度
        AuctionStatus status; // 拍卖状态
    }

    // ============ 状态变量 ============

    /// @dev 拍卖映射
    mapping(uint256 => Auction) public auctions;

    /// @dev 拍卖计数器
    uint256 public auctionCounter;

    /// @dev 平台手续费率 (基点，10000 = 100%)
    uint256 public platformFeeRate;

    /// @dev 手续费接收地址
    address public feeRecipient;

    /// @dev 价格预言机
    IPriceOracle public priceOracle;

    /// @dev 用户创建的拍卖列表
    mapping(address => uint256[]) public userAuctions;

    /// @dev 用户参与的拍卖列表
    mapping(address => uint256[]) public userBids;

    // ============ 事件 ============

    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 startingPrice,
        uint256 reservePrice,
        uint256 endTime
    );

    event BidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 amount,
        address bidToken
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

    event PlatformFeeRateUpdated(uint256 oldRate, uint256 newRate);
    event FeeRecipientUpdated(address oldRecipient, address newRecipient);
    event PriceOracleUpdated(address oldOracle, address newOracle);

    // ============ 修饰符 ============

    modifier validAuction(uint256 auctionId) {
        require(auctionId < auctionCounter, "AuctionHouse: invalid auction ID");
        _;
    }

    // ============ 初始化函数 ============

    /**
     * @dev 初始化函数，替代构造函数
     * @param _feeRecipient 手续费接收地址
     * @param _platformFeeRate 平台手续费率
     * @param _priceOracle 价格预言机地址
     */
    function initialize(
        address _feeRecipient,
        uint256 _platformFeeRate,
        address _priceOracle
    ) public initializer {
        require(
            _feeRecipient != address(0),
            "AuctionHouse: invalid fee recipient"
        );
        require(_platformFeeRate <= 1000, "AuctionHouse: fee rate too high"); // 最大10%
        require(
            _priceOracle != address(0),
            "AuctionHouse: invalid price oracle"
        );

        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        feeRecipient = _feeRecipient;
        platformFeeRate = _platformFeeRate;
        priceOracle = IPriceOracle(_priceOracle);
        auctionCounter = 0;
    }

    // ============ 升级授权 ============

    /**
     * @dev 授权升级函数，只有所有者可以升级
     * @param newImplementation 新实现合约地址
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    // ============ 核心功能 ============

    /**
     * @dev 创建拍卖
     * @param nftContract NFT合约地址
     * @param tokenId NFT代币ID
     * @param startingPrice 起始价格(ETH)
     * @param reservePrice 保留价格(ETH)
     * @param duration 拍卖持续时间(秒)
     * @param bidIncrement 最小加价幅度(ETH)
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
            "AuctionHouse: starting price must be positive"
        );
        require(
            reservePrice >= startingPrice,
            "AuctionHouse: reserve price too low"
        );
        require(duration >= 300, "AuctionHouse: duration too short"); // 最少5分钟
        require(duration <= 7 days, "AuctionHouse: duration too long");
        require(
            bidIncrement > 0,
            "AuctionHouse: bid increment must be positive"
        );

        IERC721 nft = IERC721(nftContract);
        require(
            nft.ownerOf(tokenId) == msg.sender,
            "AuctionHouse: not NFT owner"
        );
        require(
            nft.getApproved(tokenId) == address(this) ||
                nft.isApprovedForAll(msg.sender, address(this)),
            "AuctionHouse: NFT not approved"
        );

        uint256 auctionId = auctionCounter++;
        uint256 endTime = block.timestamp + duration;

        auctions[auctionId] = Auction({
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            startingPrice: startingPrice,
            reservePrice: reservePrice,
            currentBid: 0,
            currentBidder: address(0),
            bidToken: address(0),
            bidTokenAmount: 0,
            endTime: endTime,
            bidIncrement: bidIncrement,
            status: AuctionStatus.Active
        });

        // 转移NFT到合约
        nft.transferFrom(msg.sender, address(this), tokenId);

        // 记录用户创建的拍卖
        userAuctions[msg.sender].push(auctionId);

        emit AuctionCreated(
            auctionId,
            msg.sender,
            nftContract,
            tokenId,
            startingPrice,
            reservePrice,
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
    ) external payable validAuction(auctionId) whenNotPaused nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(
            auction.status == AuctionStatus.Active,
            "AuctionHouse: auction not active"
        );
        require(
            block.timestamp < auction.endTime,
            "AuctionHouse: auction ended"
        );
        require(
            msg.sender != auction.seller,
            "AuctionHouse: seller cannot bid"
        );
        require(msg.value > 0, "AuctionHouse: bid must be positive");

        uint256 minBid = auction.currentBid == 0
            ? auction.startingPrice
            : auction.currentBid + auction.bidIncrement;

        require(msg.value >= minBid, "AuctionHouse: bid too low");

        // 退还前一个出价者的资金
        if (auction.currentBidder != address(0)) {
            _refundBidder(
                auction.currentBidder,
                auction.bidToken,
                auction.bidTokenAmount
            );
        }

        // 更新拍卖信息
        auction.currentBid = msg.value;
        auction.currentBidder = msg.sender;
        auction.bidToken = address(0); // ETH
        auction.bidTokenAmount = msg.value;

        // 记录用户参与的拍卖
        userBids[msg.sender].push(auctionId);

        emit BidPlaced(auctionId, msg.sender, msg.value, address(0));
    }

    /**
     * @dev ERC20代币出价
     * @param auctionId 拍卖ID
     * @param token 代币合约地址
     * @param amount 出价数量
     */
    function placeBidWithToken(
        uint256 auctionId,
        address token,
        uint256 amount
    ) external validAuction(auctionId) whenNotPaused nonReentrant {
        require(token != address(0), "AuctionHouse: invalid token");
        require(amount > 0, "AuctionHouse: amount must be positive");

        Auction storage auction = auctions[auctionId];
        require(
            auction.status == AuctionStatus.Active,
            "AuctionHouse: auction not active"
        );
        require(
            block.timestamp < auction.endTime,
            "AuctionHouse: auction ended"
        );
        require(
            msg.sender != auction.seller,
            "AuctionHouse: seller cannot bid"
        );

        // 获取代币的USD价值
        uint256 tokenValueUSD = priceOracle.getUSDValue(token, amount);
        uint256 currentBidUSD = auction.currentBid == 0
            ? 0
            : (
                auction.bidToken == address(0)
                    ? priceOracle.getUSDValue(address(0), auction.currentBid)
                    : priceOracle.getUSDValue(
                        auction.bidToken,
                        auction.bidTokenAmount
                    )
            );

        uint256 minBidUSD = auction.currentBid == 0
            ? priceOracle.getUSDValue(address(0), auction.startingPrice)
            : currentBidUSD +
                priceOracle.getUSDValue(address(0), auction.bidIncrement);

        require(tokenValueUSD >= minBidUSD, "AuctionHouse: bid too low");

        // 转移代币到合约
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // 退还前一个出价者的资金
        if (auction.currentBidder != address(0)) {
            _refundBidder(
                auction.currentBidder,
                auction.bidToken,
                auction.bidTokenAmount
            );
        }

        // 更新拍卖信息
        auction.currentBid = tokenValueUSD; // 存储USD价值用于比较
        auction.currentBidder = msg.sender;
        auction.bidToken = token;
        auction.bidTokenAmount = amount;

        // 记录用户参与的拍卖
        userBids[msg.sender].push(auctionId);

        emit BidPlaced(auctionId, msg.sender, amount, token);
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

        if (auction.currentBidder != address(0)) {
            // 检查是否达到保留价
            uint256 reservePriceUSD = priceOracle.getUSDValue(
                address(0),
                auction.reservePrice
            );

            if (auction.currentBid >= reservePriceUSD) {
                // 达到保留价，执行交易
                _executeAuction(auctionId);
            } else {
                // 未达到保留价，退还出价和NFT
                _refundBidder(
                    auction.currentBidder,
                    auction.bidToken,
                    auction.bidTokenAmount
                );
                IERC721(auction.nftContract).transferFrom(
                    address(this),
                    auction.seller,
                    auction.tokenId
                );
            }
        } else {
            // 无人出价，退还NFT
            IERC721(auction.nftContract).transferFrom(
                address(this),
                auction.seller,
                auction.tokenId
            );
        }

        emit AuctionEnded(
            auctionId,
            auction.currentBidder,
            auction.currentBid,
            block.timestamp
        );
    }

    // ============ 内部函数 ============

    /**
     * @dev 执行拍卖交易
     * @param auctionId 拍卖ID
     */
    function _executeAuction(uint256 auctionId) internal {
        Auction storage auction = auctions[auctionId];

        // 计算手续费
        uint256 fee = 0;
        uint256 sellerAmount = 0;

        if (auction.bidToken == address(0)) {
            // ETH出价
            fee = (auction.bidTokenAmount * platformFeeRate) / 10000;
            sellerAmount = auction.bidTokenAmount - fee;

            // 转账给卖家
            (bool success, ) = auction.seller.call{value: sellerAmount}("");
            require(success, "AuctionHouse: transfer to seller failed");

            // 转账手续费
            if (fee > 0) {
                (success, ) = feeRecipient.call{value: fee}("");
                require(success, "AuctionHouse: fee transfer failed");
            }
        } else {
            // ERC20代币出价
            fee = (auction.bidTokenAmount * platformFeeRate) / 10000;
            sellerAmount = auction.bidTokenAmount - fee;

            IERC20 token = IERC20(auction.bidToken);

            // 转账给卖家
            token.safeTransfer(auction.seller, sellerAmount);

            // 转账手续费
            if (fee > 0) {
                token.safeTransfer(feeRecipient, fee);
            }
        }

        // 转移NFT给获胜者
        IERC721(auction.nftContract).transferFrom(
            address(this),
            auction.currentBidder,
            auction.tokenId
        );
    }

    /**
     * @dev 退还出价者资金
     * @param bidder 出价者地址
     * @param token 代币地址
     * @param amount 金额
     */
    function _refundBidder(
        address bidder,
        address token,
        uint256 amount
    ) internal {
        if (amount == 0) return;

        if (token == address(0)) {
            // 退还ETH
            (bool success, ) = bidder.call{value: amount}("");
            require(success, "AuctionHouse: ETH refund failed");
        } else {
            // 退还ERC20代币
            IERC20(token).safeTransfer(bidder, amount);
        }
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
     * @dev 获取拍卖的USD价值
     * @param auctionId 拍卖ID
     */
    function getAuctionValueInUSD(
        uint256 auctionId
    ) external view validAuction(auctionId) returns (uint256) {
        Auction storage auction = auctions[auctionId];
        if (auction.currentBid == 0) return 0;

        return
            auction.bidToken == address(0)
                ? priceOracle.getUSDValue(address(0), auction.bidTokenAmount)
                : priceOracle.getUSDValue(
                    auction.bidToken,
                    auction.bidTokenAmount
                );
    }

    /**
     * @dev 获取拍卖的USD价格信息
     * @param auctionId 拍卖ID
     */
    function getAuctionUSDValue(
        uint256 auctionId
    )
        external
        view
        validAuction(auctionId)
        returns (uint256 startingPriceUSD, uint256 reservePriceUSD)
    {
        Auction storage auction = auctions[auctionId];
        startingPriceUSD = priceOracle.getUSDValue(
            address(0),
            auction.startingPrice
        );
        reservePriceUSD = priceOracle.getUSDValue(
            address(0),
            auction.reservePrice
        );
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

    // ============ 管理函数 ============

    /**
     * @dev 设置平台手续费率
     * @param _platformFeeRate 新的手续费率
     */
    function setPlatformFeeRate(uint256 _platformFeeRate) external onlyOwner {
        require(_platformFeeRate <= 1000, "AuctionHouse: fee rate too high"); // 最大10%
        uint256 oldRate = platformFeeRate;
        platformFeeRate = _platformFeeRate;
        emit PlatformFeeRateUpdated(oldRate, _platformFeeRate);
    }

    /**
     * @dev 设置手续费接收地址
     * @param _feeRecipient 新的手续费接收地址
     */
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(
            _feeRecipient != address(0),
            "AuctionHouse: invalid fee recipient"
        );
        address oldRecipient = feeRecipient;
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(oldRecipient, _feeRecipient);
    }

    /**
     * @dev 设置价格预言机
     * @param _priceOracle 新的价格预言机地址
     */
    function setPriceOracle(address _priceOracle) external onlyOwner {
        require(
            _priceOracle != address(0),
            "AuctionHouse: invalid price oracle"
        );
        address oldOracle = address(priceOracle);
        priceOracle = IPriceOracle(_priceOracle);
        emit PriceOracleUpdated(oldOracle, _priceOracle);
    }

    /**
     * @dev 暂停合约
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev 恢复合约
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // ============ 取消拍卖 ============

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

    /**
     * @dev 获取合约版本
     */
    function version() external pure returns (string memory) {
        return "1.0.0";
    }
}

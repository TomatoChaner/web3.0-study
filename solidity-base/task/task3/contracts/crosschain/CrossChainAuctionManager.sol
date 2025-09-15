// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ICrossChainAuction.sol";
import "./CrossChainMessenger.sol";
import "../interfaces/IPriceOracle.sol";

/**
 * @title CrossChainAuctionManager
 * @dev 跨链拍卖管理器合约
 * @notice 管理跨链拍卖的创建、出价、结算等核心功能
 */
contract CrossChainAuctionManager is ICrossChainAuction, Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // ============ 状态变量 ============

    /// @dev 跨链消息传递合约
    CrossChainMessenger public immutable messenger;
    
    /// @dev 价格预言机合约
    IPriceOracle public priceOracle;
    
    /// @dev 拍卖计数器
    uint256 public auctionCounter;
    
    /// @dev 拍卖信息映射
    mapping(uint256 => CrossChainAuctionInfo) private auctions;
    
    /// @dev 用户出价历史
    mapping(address => mapping(uint256 => CrossChainBid[])) public userBids;
    
    /// @dev 拍卖的所有出价
    mapping(uint256 => CrossChainBid[]) public auctionBids;
    
    /// @dev 链配置映射
    mapping(uint64 => ChainConfig) public chainConfigs;
    
    /// @dev 支持的代币映射
    mapping(address => bool) public supportedTokens;
    
    /// @dev 平台手续费率（基点，10000 = 100%）
    uint256 public platformFeeRate = 250; // 2.5%
    
    /// @dev 平台手续费接收地址
    address public feeRecipient;
    
    /// @dev 最小拍卖持续时间（秒）
    uint256 public constant MIN_AUCTION_DURATION = 1 hours;
    
    /// @dev 最大拍卖持续时间（秒）
    uint256 public constant MAX_AUCTION_DURATION = 30 days;
    
    /// @dev 最小出价增幅（基点）
    uint256 public minBidIncrement = 500; // 5%

    // ============ 错误定义 ============

    error AuctionNotFound(uint256 auctionId);
    error AuctionNotActive(uint256 auctionId);
    error AuctionEnded(uint256 auctionId);
    error InvalidDuration(uint256 duration);
    error InvalidStartingPrice(uint256 price);
    error BidTooLow(uint256 bid, uint256 required);
    error UnsupportedToken(address token);
    error NotAuctionSeller(address caller, address seller);
    error InvalidChainConfig(uint64 chainId);
    error TransferFailed();

    // ============ 修饰符 ============

    /**
     * @dev 检查拍卖是否存在
     * @param auctionId 拍卖ID
     */
    modifier auctionExists(uint256 auctionId) {
        if (auctionId == 0 || auctionId > auctionCounter) {
            revert AuctionNotFound(auctionId);
        }
        _;
    }

    /**
     * @dev 检查拍卖是否活跃
     * @param auctionId 拍卖ID
     */
    modifier auctionActive(uint256 auctionId) {
        CrossChainAuctionInfo storage auction = auctions[auctionId];
        if (auction.status != CrossChainAuctionStatus.ACTIVE) {
            revert AuctionNotActive(auctionId);
        }
        if (block.timestamp >= auction.endTime) {
            revert AuctionEnded(auctionId);
        }
        _;
    }

    /**
     * @dev 仅消息传递合约可调用
     */
    modifier onlyMessenger() {
        require(msg.sender == address(messenger), "Only messenger");
        _;
    }

    // ============ 构造函数 ============

    /**
     * @dev 构造函数
     * @param _messenger 跨链消息传递合约地址
     * @param _priceOracle 价格预言机合约地址
     * @param _feeRecipient 手续费接收地址
     */
    constructor(
        address _messenger,
        address _priceOracle,
        address _feeRecipient
    ) Ownable(msg.sender) {
        require(_messenger != address(0), "Invalid messenger");
        require(_priceOracle != address(0), "Invalid price oracle");
        require(_feeRecipient != address(0), "Invalid fee recipient");
        
        messenger = CrossChainMessenger(_messenger);
        priceOracle = IPriceOracle(_priceOracle);
        feeRecipient = _feeRecipient;
    }

    // ============ 外部函数 ============

    /**
     * @dev 创建跨链拍卖
     * @param nftContract NFT合约地址
     * @param tokenId NFT代币ID
     * @param startingPrice 起始价格（USD，18位小数）
     * @param duration 拍卖持续时间（秒）
     * @param supportedChains 支持的链ID数组
     * @return auctionId 拍卖ID
     */
    function createCrossChainAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startingPrice,
        uint256 duration,
        uint64[] calldata supportedChains
    ) external nonReentrant whenNotPaused returns (uint256 auctionId) {
        // 验证参数
        require(nftContract != address(0), "Invalid NFT contract");
        if (startingPrice == 0) revert InvalidStartingPrice(startingPrice);
        if (duration < MIN_AUCTION_DURATION || duration > MAX_AUCTION_DURATION) {
            revert InvalidDuration(duration);
        }
        require(supportedChains.length > 0, "No supported chains");
        
        // 验证NFT所有权
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, "Not NFT owner");
        require(nft.getApproved(tokenId) == address(this) || 
                nft.isApprovedForAll(msg.sender, address(this)), "NFT not approved");
        
        // 验证支持的链
        for (uint256 i = 0; i < supportedChains.length; i++) {
            if (!chainConfigs[supportedChains[i]].isSupported) {
                revert InvalidChainConfig(supportedChains[i]);
            }
        }
        
        // 转移NFT到合约
        nft.transferFrom(msg.sender, address(this), tokenId);
        
        // 创建拍卖
        auctionId = ++auctionCounter;
        CrossChainAuctionInfo storage auction = auctions[auctionId];
        
        auction.auctionId = auctionId;
        auction.nftContract = nftContract;
        auction.tokenId = tokenId;
        auction.seller = msg.sender;
        auction.startingPrice = startingPrice;
        auction.endTime = block.timestamp + duration;
        auction.originChainId = uint64(block.chainid);
        auction.status = CrossChainAuctionStatus.ACTIVE;
        auction.totalBids = 0;
        
        // 设置支持的链
        for (uint256 i = 0; i < supportedChains.length; i++) {
            auction.supportedChains[supportedChains[i]] = true;
        }
        
        emit CrossChainAuctionCreated(
            auctionId,
            nftContract,
            tokenId,
            msg.sender,
            startingPrice,
            auction.endTime,
            supportedChains
        );
        
        // 向支持的链广播拍卖创建消息
        _broadcastAuctionCreation(auctionId, supportedChains);
    }

    /**
     * @dev 发送跨链出价
     * @param auctionId 拍卖ID
     * @param amount 出价金额
     * @param token 出价代币地址
     * @param destinationChainId 目标链ID
     * @return messageId CCIP消息ID
     */
    function sendCrossChainBid(
        uint256 auctionId,
        uint256 amount,
        address token,
        uint64 destinationChainId
    ) external payable auctionExists(auctionId) nonReentrant whenNotPaused returns (bytes32 messageId) {
        // 验证代币支持
        if (!supportedTokens[token] && token != address(0)) {
            revert UnsupportedToken(token);
        }
        
        // 验证目标链支持
        if (!auctions[auctionId].supportedChains[destinationChainId]) {
            revert InvalidChainConfig(destinationChainId);
        }
        
        // 获取USD价格
        uint256 usdAmount;
        if (token == address(0)) {
            // ETH出价
            require(msg.value == amount, "Incorrect ETH amount");
            usdAmount = priceOracle.getUSDValue(address(0), amount);
        } else {
            // ERC20出价
            require(msg.value == 0, "No ETH required for ERC20");
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            usdAmount = priceOracle.getUSDValue(token, amount);
        }
        
        // 创建出价消息
        CrossChainMessage memory message = CrossChainMessage({
            messageType: MessageType.BID,
            auctionId: auctionId,
            sender: msg.sender,
            data: abi.encode(CrossChainBid({
                bidder: msg.sender,
                amount: usdAmount,
                token: token,
                originalAmount: amount,
                sourceChainId: uint64(block.chainid),
                timestamp: block.timestamp,
                isValid: true
            })),
            sourceChainId: uint64(block.chainid),
            destinationChainId: destinationChainId,
            timestamp: block.timestamp
        });
        
        // 发送消息
        messageId = messenger.sendMessage(destinationChainId, message);
        
        emit CrossChainBidPlaced(auctionId, msg.sender, usdAmount, uint64(block.chainid), messageId);
    }

    /**
     * @dev 结束跨链拍卖
     * @param auctionId 拍卖ID
     */
    function endCrossChainAuction(uint256 auctionId) external auctionExists(auctionId) nonReentrant {
        CrossChainAuctionInfo storage auction = auctions[auctionId];
        
        // 检查拍卖是否可以结束
        require(
            block.timestamp >= auction.endTime || msg.sender == auction.seller,
            "Auction not ended"
        );
        require(auction.status == CrossChainAuctionStatus.ACTIVE, "Auction not active");
        
        auction.status = CrossChainAuctionStatus.ENDED;
        
        // 如果有出价，处理结算
        if (auction.highestBid.bidder != address(0)) {
            _settleAuction(auctionId);
        } else {
            // 没有出价，返还NFT给卖家
            IERC721(auction.nftContract).transferFrom(
                address(this),
                auction.seller,
                auction.tokenId
            );
        }
        
        emit CrossChainAuctionEnded(
            auctionId,
            auction.highestBid.bidder,
            auction.highestBid.amount,
            auction.highestBid.sourceChainId
        );
    }

    /**
     * @dev 处理跨链消息
     * @param message 跨链消息
     * @param sourceChainId 源链ID
     */
    function processCrossChainMessage(
        CrossChainMessage memory message,
        uint64 sourceChainId
    ) external onlyMessenger {
        if (message.messageType == MessageType.BID) {
            _processCrossChainBid(message, sourceChainId);
        } else if (message.messageType == MessageType.AUCTION_END) {
            _processAuctionEnd(message);
        } else if (message.messageType == MessageType.NFT_TRANSFER) {
            _processNFTTransfer(message);
        } else if (message.messageType == MessageType.REFUND) {
            _processRefund(message);
        }
    }

    /**
     * @dev 设置价格预言机
     * @param _priceOracle 新的价格预言机地址
     */
    function setPriceOracle(address _priceOracle) external onlyOwner {
        require(_priceOracle != address(0), "Invalid price oracle");
        priceOracle = IPriceOracle(_priceOracle);
    }

    /**
     * @dev 设置平台手续费率
     * @param _feeRate 手续费率（基点）
     */
    function setPlatformFeeRate(uint256 _feeRate) external onlyOwner {
        require(_feeRate <= 1000, "Fee rate too high"); // 最大10%
        platformFeeRate = _feeRate;
    }

    /**
     * @dev 设置手续费接收地址
     * @param _feeRecipient 新的手续费接收地址
     */
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _feeRecipient;
    }

    /**
     * @dev 设置支持的代币
     * @param token 代币地址
     * @param supported 是否支持
     */
    function setSupportedToken(address token, bool supported) external onlyOwner {
        supportedTokens[token] = supported;
    }

    /**
     * @dev 设置链配置
     * @param chainId 链ID
     * @param config 链配置
     */
    function setChainConfig(uint64 chainId, ChainConfig memory config) external onlyOwner {
        chainConfigs[chainId] = config;
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

    // ============ 内部函数 ============

    /**
     * @dev 广播拍卖创建消息
     * @param auctionId 拍卖ID
     * @param supportedChains 支持的链ID数组
     */
    function _broadcastAuctionCreation(uint256 auctionId, uint64[] calldata supportedChains) internal {
        CrossChainAuctionInfo storage auction = auctions[auctionId];
        
        for (uint256 i = 0; i < supportedChains.length; i++) {
            if (supportedChains[i] != uint64(block.chainid)) {
                CrossChainMessage memory message = CrossChainMessage({
                    messageType: MessageType.AUCTION_END, // 复用类型表示拍卖信息同步
                    auctionId: auctionId,
                    sender: auction.seller,
                    data: abi.encode(auction.nftContract, auction.tokenId, auction.startingPrice, auction.endTime),
                    sourceChainId: uint64(block.chainid),
                    destinationChainId: supportedChains[i],
                    timestamp: block.timestamp
                });
                
                try messenger.sendMessage(supportedChains[i], message) {
                    // 消息发送成功
                } catch {
                    // 消息发送失败，记录日志但不阻止拍卖创建
                }
            }
        }
    }

    /**
     * @dev 处理跨链出价
     * @param message 跨链消息
     * @param sourceChainId 源链ID
     */
    function _processCrossChainBid(CrossChainMessage memory message, uint64 sourceChainId) internal {
        CrossChainBid memory bid = abi.decode(message.data, (CrossChainBid));
        CrossChainAuctionInfo storage auction = auctions[message.auctionId];
        
        // 验证拍卖状态
        require(auction.status == CrossChainAuctionStatus.ACTIVE, "Auction not active");
        require(block.timestamp < auction.endTime, "Auction ended");
        require(auction.supportedChains[sourceChainId], "Chain not supported");
        
        // 验证出价金额
        uint256 minBid = auction.highestBid.amount == 0 ? 
            auction.startingPrice : 
            auction.highestBid.amount + (auction.highestBid.amount * minBidIncrement / 10000);
        
        if (bid.amount < minBid) {
            revert BidTooLow(bid.amount, minBid);
        }
        
        // 更新最高出价
        auction.highestBid = bid;
        auction.totalBids++;
        
        // 记录出价历史
        auctionBids[message.auctionId].push(bid);
        userBids[bid.bidder][message.auctionId].push(bid);
        
        emit CrossChainBidPlaced(
            message.auctionId,
            bid.bidder,
            bid.amount,
            sourceChainId,
            bytes32(0) // 本地处理，无messageId
        );
    }

    /**
     * @dev 处理拍卖结束消息
     * @param message 跨链消息
     */
    function _processAuctionEnd(CrossChainMessage memory message) internal {
        // 同步拍卖信息或处理拍卖结束
        // 具体实现根据业务需求
    }

    /**
     * @dev 处理NFT转移消息
     * @param message 跨链消息
     */
    function _processNFTTransfer(CrossChainMessage memory message) internal {
        // 处理跨链NFT转移
        // 具体实现根据业务需求
    }

    /**
     * @dev 处理退款消息
     * @param message 跨链消息
     */
    function _processRefund(CrossChainMessage memory message) internal {
        // 处理退款
        // 具体实现根据业务需求
    }

    /**
     * @dev 结算拍卖
     * @param auctionId 拍卖ID
     */
    function _settleAuction(uint256 auctionId) internal {
        CrossChainAuctionInfo storage auction = auctions[auctionId];
        CrossChainBid memory winningBid = auction.highestBid;
        
        // 计算手续费
        uint256 platformFee = (winningBid.originalAmount * platformFeeRate) / 10000;
        uint256 sellerAmount = winningBid.originalAmount - platformFee;
        
        // 转移NFT给获胜者
        IERC721(auction.nftContract).transferFrom(
            address(this),
            winningBid.bidder,
            auction.tokenId
        );
        
        // 转移资金
        if (winningBid.token == address(0)) {
            // ETH支付
            (bool success1, ) = payable(auction.seller).call{value: sellerAmount}("");
            (bool success2, ) = payable(feeRecipient).call{value: platformFee}("");
            if (!success1 || !success2) revert TransferFailed();
        } else {
            // ERC20支付
            IERC20(winningBid.token).safeTransfer(auction.seller, sellerAmount);
            IERC20(winningBid.token).safeTransfer(feeRecipient, platformFee);
        }
        
        auction.status = CrossChainAuctionStatus.SETTLED;
    }

    // ============ 视图函数 ============

    /**
     * @dev 获取跨链拍卖信息
     * @param auctionId 拍卖ID
     * @return 拍卖信息（不包含mapping字段）
     */
    function getCrossChainAuctionInfo(uint256 auctionId) external view auctionExists(auctionId) returns (
        uint256,
        address,
        uint256,
        address,
        uint256,
        uint256,
        uint64,
        CrossChainAuctionStatus,
        CrossChainBid memory,
        uint256
    ) {
        CrossChainAuctionInfo storage auction = auctions[auctionId];
        return (
            auction.auctionId,
            auction.nftContract,
            auction.tokenId,
            auction.seller,
            auction.startingPrice,
            auction.endTime,
            auction.originChainId,
            auction.status,
            auction.highestBid,
            auction.totalBids
        );
    }

    /**
     * @dev 检查链是否支持
     * @param auctionId 拍卖ID
     * @param chainId 链ID
     * @return 是否支持
     */
    function isChainSupported(uint256 auctionId, uint64 chainId) external view auctionExists(auctionId) returns (bool) {
        return auctions[auctionId].supportedChains[chainId];
    }

    /**
     * @dev 获取链配置信息
     * @param chainId 链ID
     * @return 链配置信息
     */
    function getChainConfig(uint64 chainId) external view returns (ChainConfig memory) {
        return chainConfigs[chainId];
    }

    /**
     * @dev 获取拍卖的所有出价
     * @param auctionId 拍卖ID
     * @return 出价数组
     */
    function getAuctionBids(uint256 auctionId) external view auctionExists(auctionId) returns (CrossChainBid[] memory) {
        return auctionBids[auctionId];
    }

    /**
     * @dev 获取用户在特定拍卖的出价历史
     * @param user 用户地址
     * @param auctionId 拍卖ID
     * @return 出价数组
     */
    function getUserBids(address user, uint256 auctionId) external view returns (CrossChainBid[] memory) {
        return userBids[user][auctionId];
    }
}
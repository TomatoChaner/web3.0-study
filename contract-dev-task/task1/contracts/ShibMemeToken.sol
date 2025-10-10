// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IERC20Extended.sol";
import "./interfaces/IUniswapV2.sol";

/**
 * @title ShibMemeToken
 * @dev SHIB风格的Meme代币合约，实现税收机制、交易限制和流动性池集成
 */
contract ShibMemeToken is ERC20, Ownable, Pausable, ReentrancyGuard, IERC20Extended {
    // 基础配置
    uint256 private constant TOTAL_SUPPLY = 1_000_000_000 * 10**18; // 10亿代币
    uint256 private constant BASIS_POINTS = 10000; // 基点单位 (100% = 10000)
    
    // 税收配置
    uint256 public override buyTax = 300;  // 3% 买入税
    uint256 public override sellTax = 500; // 5% 卖出税
    uint256 public constant MAX_TAX = 1000; // 最大税率 10%
    
    // 交易限制配置
    uint256 public override maxTransactionAmount = TOTAL_SUPPLY / 100; // 1% 最大交易额
    uint256 public override maxWalletAmount = TOTAL_SUPPLY * 2 / 100;  // 2% 最大持有量
    uint256 public override tradingCooldown = 30; // 30秒冷却时间
    
    // 状态变量
    bool public override tradingEnabled = false;
    bool private _inSwap = false;
    uint256 private _swapTokensAtAmount = TOTAL_SUPPLY / 1000; // 0.1% 触发swap
    
    // 地址映射
    mapping(address => bool) private _blacklisted;
    mapping(address => bool) private _excludedFromFees;
    mapping(address => bool) private _excludedFromMaxTransaction;
    mapping(address => uint256) public override lastTransactionTime;
    
    // 钱包地址
    address public marketingWallet;
    address public developmentWallet;
    address public liquidityWallet;
    
    // Uniswap集成
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    mapping(address => bool) public automatedMarketMakerPairs;
    
    // 税收分配 (总计100%)
    uint256 public liquidityFeePercent = 50;  // 50%
    uint256 public marketingFeePercent = 30;  // 30%
    uint256 public developmentFeePercent = 20; // 20%
    
    // 事件
    event TradingEnabled(uint256 timestamp);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event TaxDistributed(uint256 marketing, uint256 development, uint256 liquidity);
    event AutomatedMarketMakerPairUpdated(address indexed pair, bool indexed value);
    
    // 修饰符
    modifier lockTheSwap {
        _inSwap = true;
        _;
        _inSwap = false;
    }
    
    modifier validAddress(address addr) {
        require(addr != address(0), "ShibMemeToken: zero address");
        _;
    }
    
    constructor(
        address _marketingWallet,
        address _developmentWallet,
        address _liquidityWallet,
        address _uniswapV2Router
    ) ERC20("SHIB Meme Token", "SMT") {
        require(_marketingWallet != address(0), "ShibMemeToken: marketing wallet is zero address");
        require(_developmentWallet != address(0), "ShibMemeToken: development wallet is zero address");
        require(_liquidityWallet != address(0), "ShibMemeToken: liquidity wallet is zero address");
        require(_uniswapV2Router != address(0), "ShibMemeToken: router is zero address");
        
        marketingWallet = _marketingWallet;
        developmentWallet = _developmentWallet;
        liquidityWallet = _liquidityWallet;
        
        // 设置Uniswap路由器
        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        
        _setAutomatedMarketMakerPair(uniswapV2Pair, true);
        
        // 排除费用和限制
        _excludedFromFees[owner()] = true;
        _excludedFromFees[address(this)] = true;
        _excludedFromFees[marketingWallet] = true;
        _excludedFromFees[developmentWallet] = true;
        _excludedFromFees[liquidityWallet] = true;
        
        _excludedFromMaxTransaction[owner()] = true;
        _excludedFromMaxTransaction[address(this)] = true;
        _excludedFromMaxTransaction[marketingWallet] = true;
        _excludedFromMaxTransaction[developmentWallet] = true;
        _excludedFromMaxTransaction[liquidityWallet] = true;
        _excludedFromMaxTransaction[uniswapV2Pair] = true;
        
        // 铸造总供应量给合约部署者
        _mint(owner(), TOTAL_SUPPLY);
    }
    
    receive() external payable {}
    
    // ============ 公共函数 ============
    
    /**
     * @dev 启用交易
     */
    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "ShibMemeToken: trading already enabled");
        tradingEnabled = true;
        emit TradingEnabled(block.timestamp);
        emit TradingEnabledUpdated(true);
    }
    
    /**
     * @dev 暂停/恢复合约
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    // ============ 税收管理 ============
    
    /**
     * @dev 设置买入税
     */
    function setBuyTax(uint256 _buyTax) external onlyOwner {
        require(_buyTax <= MAX_TAX, "ShibMemeToken: buy tax too high");
        uint256 oldTax = buyTax;
        buyTax = _buyTax;
        emit BuyTaxUpdated(oldTax, _buyTax);
    }
    
    /**
     * @dev 设置卖出税
     */
    function setSellTax(uint256 _sellTax) external onlyOwner {
        require(_sellTax <= MAX_TAX, "ShibMemeToken: sell tax too high");
        uint256 oldTax = sellTax;
        sellTax = _sellTax;
        emit SellTaxUpdated(oldTax, _sellTax);
    }
    
    /**
     * @dev 设置税收分配比例
     */
    function setTaxDistribution(
        uint256 _liquidityPercent,
        uint256 _marketingPercent,
        uint256 _developmentPercent
    ) external onlyOwner {
        require(
            _liquidityPercent + _marketingPercent + _developmentPercent == 100,
            "ShibMemeToken: percentages must sum to 100"
        );
        liquidityFeePercent = _liquidityPercent;
        marketingFeePercent = _marketingPercent;
        developmentFeePercent = _developmentPercent;
    }
    
    // ============ 交易限制管理 ============
    
    /**
     * @dev 设置最大交易额度
     */
    function setMaxTransactionAmount(uint256 _maxTransactionAmount) external onlyOwner {
        require(
            _maxTransactionAmount >= TOTAL_SUPPLY / 1000,
            "ShibMemeToken: max transaction amount too low"
        );
        uint256 oldAmount = maxTransactionAmount;
        maxTransactionAmount = _maxTransactionAmount;
        emit MaxTransactionAmountUpdated(oldAmount, _maxTransactionAmount);
    }
    
    /**
     * @dev 设置最大钱包持有量
     */
    function setMaxWalletAmount(uint256 _maxWalletAmount) external onlyOwner {
        require(
            _maxWalletAmount >= TOTAL_SUPPLY / 500,
            "ShibMemeToken: max wallet amount too low"
        );
        uint256 oldAmount = maxWalletAmount;
        maxWalletAmount = _maxWalletAmount;
        emit MaxWalletAmountUpdated(oldAmount, _maxWalletAmount);
    }
    
    /**
     * @dev 设置交易冷却时间
     */
    function setTradingCooldown(uint256 _tradingCooldown) external onlyOwner {
        require(_tradingCooldown <= 300, "ShibMemeToken: cooldown too long");
        uint256 oldCooldown = tradingCooldown;
        tradingCooldown = _tradingCooldown;
        emit TradingCooldownUpdated(oldCooldown, _tradingCooldown);
    }
    
    // ============ 黑名单管理 ============
    
    /**
     * @dev 添加/移除黑名单
     */
    function setBlacklisted(address account, bool blacklisted) external onlyOwner {
        require(account != owner(), "ShibMemeToken: cannot blacklist owner");
        require(account != address(this), "ShibMemeToken: cannot blacklist contract");
        _blacklisted[account] = blacklisted;
        emit BlacklistUpdated(account, blacklisted);
    }
    
    /**
     * @dev 批量设置黑名单
     */
    function setBlacklistedBatch(address[] calldata accounts, bool blacklisted) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (accounts[i] != owner() && accounts[i] != address(this)) {
                _blacklisted[accounts[i]] = blacklisted;
                emit BlacklistUpdated(accounts[i], blacklisted);
            }
        }
    }
    
    // ============ 费用排除管理 ============
    
    /**
     * @dev 设置费用排除
     */
    function setExcludedFromFees(address account, bool excluded) external onlyOwner {
        _excludedFromFees[account] = excluded;
        emit ExcludeFromFeesUpdated(account, excluded);
    }
    
    /**
     * @dev 设置交易限制排除
     */
    function setExcludedFromMaxTransaction(address account, bool excluded) external onlyOwner {
        _excludedFromMaxTransaction[account] = excluded;
        emit ExcludeFromMaxTransactionUpdated(account, excluded);
    }
    
    // ============ AMM管理 ============
    
    /**
     * @dev 设置自动做市商对
     */
    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "ShibMemeToken: cannot remove main pair");
        _setAutomatedMarketMakerPair(pair, value);
    }
    
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        _excludedFromMaxTransaction[pair] = value;
        emit AutomatedMarketMakerPairUpdated(pair, value);
    }
    
    // ============ 钱包管理 ============
    
    /**
     * @dev 更新营销钱包
     */
    function setMarketingWallet(address _marketingWallet) external onlyOwner validAddress(_marketingWallet) {
        marketingWallet = _marketingWallet;
    }
    
    /**
     * @dev 更新开发钱包
     */
    function setDevelopmentWallet(address _developmentWallet) external onlyOwner validAddress(_developmentWallet) {
        developmentWallet = _developmentWallet;
    }
    
    /**
     * @dev 更新流动性钱包
     */
    function setLiquidityWallet(address _liquidityWallet) external onlyOwner validAddress(_liquidityWallet) {
        liquidityWallet = _liquidityWallet;
    }
    
    // ============ 查询函数 ============
    
    function isBlacklisted(address account) external view override returns (bool) {
        return _blacklisted[account];
    }
    
    function isExcludedFromFees(address account) external view override returns (bool) {
        return _excludedFromFees[account];
    }
    
    function isExcludedFromMaxTransaction(address account) external view override returns (bool) {
        return _excludedFromMaxTransaction[account];
    }
    
    function paused() public view override(Pausable, IERC20Extended) returns (bool) {
        return super.paused();
    }
    
    // ============ 转账逻辑 ============
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_blacklisted[from], "ShibMemeToken: sender is blacklisted");
        require(!_blacklisted[to], "ShibMemeToken: recipient is blacklisted");
        require(!paused(), "ShibMemeToken: token transfer while paused");
        
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        // 检查交易是否启用
        if (!tradingEnabled) {
            require(
                _excludedFromFees[from] || _excludedFromFees[to],
                "ShibMemeToken: trading not enabled"
            );
        }
        
        // 检查交易限制
        if (!_excludedFromMaxTransaction[from] && !_excludedFromMaxTransaction[to]) {
            require(amount <= maxTransactionAmount, "ShibMemeToken: transfer amount exceeds max");
            
            // 检查冷却时间
            if (tradingCooldown > 0) {
                require(
                    block.timestamp >= lastTransactionTime[from] + tradingCooldown,
                    "ShibMemeToken: transfer cooldown not met"
                );
                lastTransactionTime[from] = block.timestamp;
            }
        }
        
        // 检查最大钱包持有量
        if (!_excludedFromMaxTransaction[to]) {
            require(
                balanceOf(to) + amount <= maxWalletAmount,
                "ShibMemeToken: recipient balance exceeds max wallet amount"
            );
        }
        
        // 处理税收
        bool takeFee = !_inSwap && !_excludedFromFees[from] && !_excludedFromFees[to];
        
        if (takeFee) {
            uint256 fees = 0;
            
            // 卖出到AMM
            if (automatedMarketMakerPairs[to] && sellTax > 0) {
                fees = (amount * sellTax) / BASIS_POINTS;
            }
            // 从AMM买入
            else if (automatedMarketMakerPairs[from] && buyTax > 0) {
                fees = (amount * buyTax) / BASIS_POINTS;
            }
            
            if (fees > 0) {
                super._transfer(from, address(this), fees);
                amount -= fees;
            }
        }
        
        // 自动swap和流动性添加
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= _swapTokensAtAmount;
        
        if (
            canSwap &&
            !_inSwap &&
            !automatedMarketMakerPairs[from] &&
            !_excludedFromFees[from] &&
            !_excludedFromFees[to]
        ) {
            _swapAndDistribute(contractTokenBalance);
        }
        
        super._transfer(from, to, amount);
    }
    
    /**
     * @dev 交换代币并分配税收
     */
    function _swapAndDistribute(uint256 tokenAmount) private lockTheSwap {
        if (tokenAmount == 0) return;
        
        // 计算各部分数量
        uint256 liquidityTokens = (tokenAmount * liquidityFeePercent) / 100;
        uint256 liquidityTokensHalf = liquidityTokens / 2;
        uint256 tokensToSwap = tokenAmount - liquidityTokensHalf;
        
        uint256 initialETHBalance = address(this).balance;
        
        // 交换代币为ETH
        _swapTokensForEth(tokensToSwap);
        
        uint256 newETHBalance = address(this).balance - initialETHBalance;
        
        // 计算ETH分配
        uint256 totalPercent = 100 - (liquidityFeePercent / 2);
        uint256 liquidityETH = (newETHBalance * (liquidityFeePercent / 2)) / totalPercent;
        uint256 marketingETH = (newETHBalance * marketingFeePercent) / totalPercent;
        uint256 developmentETH = newETHBalance - liquidityETH - marketingETH;
        
        // 添加流动性
        if (liquidityTokensHalf > 0 && liquidityETH > 0) {
            _addLiquidity(liquidityTokensHalf, liquidityETH);
            emit SwapAndLiquify(liquidityTokensHalf, liquidityETH, liquidityTokensHalf);
        }
        
        // 分发ETH
        if (marketingETH > 0) {
            payable(marketingWallet).transfer(marketingETH);
        }
        
        if (developmentETH > 0) {
            payable(developmentWallet).transfer(developmentETH);
        }
        
        emit TaxDistributed(marketingETH, developmentETH, liquidityETH);
    }
    
    /**
     * @dev 交换代币为ETH
     */
    function _swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    /**
     * @dev 添加流动性
     */
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidityWallet,
            block.timestamp
        );
    }
    
    // ============ 紧急函数 ============
    
    /**
     * @dev 紧急提取ETH
     */
    function emergencyWithdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "ShibMemeToken: no ETH to withdraw");
        payable(owner()).transfer(balance);
    }
    
    /**
     * @dev 紧急提取代币
     */
    function emergencyWithdrawTokens(address token, uint256 amount) external onlyOwner {
        require(token != address(this), "ShibMemeToken: cannot withdraw own tokens");
        IERC20(token).transfer(owner(), amount);
    }
    
    /**
     * @dev 手动交换和分配
     */
    function manualSwapAndDistribute() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        require(contractBalance > 0, "ShibMemeToken: no tokens to swap");
        _swapAndDistribute(contractBalance);
    }
}
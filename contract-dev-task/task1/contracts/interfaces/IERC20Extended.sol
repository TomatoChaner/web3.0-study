// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IERC20Extended
 * @dev Extended ERC20 interface with tax and trading limit functionality
 */
interface IERC20Extended is IERC20 {
    /**
     * @dev Returns the buy tax percentage (in basis points, e.g., 300 = 3%)
     */
    function buyTax() external view returns (uint256);

    /**
     * @dev Returns the sell tax percentage (in basis points, e.g., 500 = 5%)
     */
    function sellTax() external view returns (uint256);

    /**
     * @dev Returns the maximum transaction amount
     */
    function maxTransactionAmount() external view returns (uint256);

    /**
     * @dev Returns the maximum wallet amount
     */
    function maxWalletAmount() external view returns (uint256);

    /**
     * @dev Returns the trading cooldown period in seconds
     */
    function tradingCooldown() external view returns (uint256);

    /**
     * @dev Returns whether trading is currently enabled
     */
    function tradingEnabled() external view returns (bool);

    /**
     * @dev Returns whether the contract is paused
     */
    function paused() external view returns (bool);

    /**
     * @dev Returns whether an address is blacklisted
     */
    function isBlacklisted(address account) external view returns (bool);

    /**
     * @dev Returns whether an address is excluded from fees
     */
    function isExcludedFromFees(address account) external view returns (bool);

    /**
     * @dev Returns whether an address is excluded from max transaction limits
     */
    function isExcludedFromMaxTransaction(address account) external view returns (bool);

    /**
     * @dev Returns the last transaction timestamp for an address
     */
    function lastTransactionTime(address account) external view returns (uint256);

    /**
     * @dev Emitted when buy tax is updated
     */
    event BuyTaxUpdated(uint256 oldTax, uint256 newTax);

    /**
     * @dev Emitted when sell tax is updated
     */
    event SellTaxUpdated(uint256 oldTax, uint256 newTax);

    /**
     * @dev Emitted when max transaction amount is updated
     */
    event MaxTransactionAmountUpdated(uint256 oldAmount, uint256 newAmount);

    /**
     * @dev Emitted when max wallet amount is updated
     */
    event MaxWalletAmountUpdated(uint256 oldAmount, uint256 newAmount);

    /**
     * @dev Emitted when trading cooldown is updated
     */
    event TradingCooldownUpdated(uint256 oldCooldown, uint256 newCooldown);

    /**
     * @dev Emitted when trading is enabled or disabled
     */
    event TradingEnabledUpdated(bool enabled);

    /**
     * @dev Emitted when an address is blacklisted or removed from blacklist
     */
    event BlacklistUpdated(address indexed account, bool isBlacklisted);

    /**
     * @dev Emitted when fee exclusion status is updated
     */
    event ExcludeFromFeesUpdated(address indexed account, bool isExcluded);

    /**
     * @dev Emitted when max transaction exclusion status is updated
     */
    event ExcludeFromMaxTransactionUpdated(address indexed account, bool isExcluded);
}
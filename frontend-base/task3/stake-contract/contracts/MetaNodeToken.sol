// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title MetaNodeToken
 * @dev ERC20 token used as rewards in the staking system
 * @notice This token is minted as rewards for staking activities
 */
contract MetaNodeToken is ERC20, ERC20Burnable, AccessControl, Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // Maximum supply of MetaNode tokens (100 million tokens)
    uint256 public constant MAX_SUPPLY = 100_000_000 * 10**18;

    // Events
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);

    /**
     * @dev Constructor that sets up the token with initial parameters
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _initialSupply Initial supply to mint to deployer
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    ) ERC20(_name, _symbol) {
        require(_initialSupply <= MAX_SUPPLY, "Initial supply exceeds max supply");

        // Grant the contract deployer the default admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);

        // Mint initial supply to deployer
        if (_initialSupply > 0) {
            _mint(msg.sender, _initialSupply);
            emit TokensMinted(msg.sender, _initialSupply);
        }
    }

    /**
     * @dev Mints tokens to a specified address
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     * @notice Only addresses with MINTER_ROLE can call this function
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) whenNotPaused {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Amount must be greater than 0");
        require(totalSupply() + amount <= MAX_SUPPLY, "Minting would exceed max supply");

        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    /**
     * @dev Burns tokens from the caller's account
     * @param amount Amount of tokens to burn
     */
    function burn(uint256 amount) public override whenNotPaused {
        super.burn(amount);
        emit TokensBurned(msg.sender, amount);
    }

    /**
     * @dev Burns tokens from a specified account (requires allowance)
     * @param account Account to burn tokens from
     * @param amount Amount of tokens to burn
     */
    function burnFrom(address account, uint256 amount) public override whenNotPaused {
        super.burnFrom(account, amount);
        emit TokensBurned(account, amount);
    }

    /**
     * @dev Pauses all token transfers
     * @notice Only addresses with PAUSER_ROLE can call this function
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers
     * @notice Only addresses with PAUSER_ROLE can call this function
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Grants MINTER_ROLE to an address
     * @param account Address to grant minter role to
     * @notice Only addresses with DEFAULT_ADMIN_ROLE can call this function
     */
    function grantMinterRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, account);
    }

    /**
     * @dev Revokes MINTER_ROLE from an address
     * @param account Address to revoke minter role from
     * @notice Only addresses with DEFAULT_ADMIN_ROLE can call this function
     */
    function revokeMinterRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(MINTER_ROLE, account);
    }

    /**
     * @dev Returns the remaining tokens that can be minted
     * @return The number of tokens that can still be minted
     */
    function remainingMintableSupply() external view returns (uint256) {
        return MAX_SUPPLY - totalSupply();
    }

    /**
     * @dev Hook that is called before any transfer of tokens
     * @param from Address tokens are transferred from
     * @param to Address tokens are transferred to
     * @param amount Amount of tokens being transferred
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Returns true if this contract implements the interface defined by interfaceId
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return True if the contract implements interfaceId
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
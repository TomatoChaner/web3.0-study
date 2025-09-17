// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IMetaNodeToken
 * @dev Interface for the MetaNode token contract
 */
interface IMetaNodeToken is IERC20 {
    // Events
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);

    // Core token functions
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;

    // Access control functions
    function grantMinterRole(address account) external;
    function revokeMinterRole(address account) external;

    // Pausable functions
    function pause() external;
    function unpause() external;

    // View functions
    function remainingMintableSupply() external view returns (uint256);
    function MAX_SUPPLY() external view returns (uint256);

    // Role constants
    function MINTER_ROLE() external view returns (bytes32);
    function PAUSER_ROLE() external view returns (bytes32);
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
}
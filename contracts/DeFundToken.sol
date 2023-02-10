// SPDX-License-Identifier: GNU

pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/// @title DeFundToken
/// @author Ayan Maiti
/// @notice Simple ERC20 token contract using openzeppelin-ERC20 interface
contract DeFundToken is ERC20, Ownable {

    /// @notice Stores the initial supply of DFND tokens
    uint256 public initialSupply;


    /// @notice Contract constructor
    /// @param _initialSupply: Initial supply of tokens passed by deployer
    constructor (uint256 _initialSupply) ERC20("DeFundToken", "DFND") {
        // Initializing value
        initialSupply = _initialSupply;

        // Minting initial supply amount in deployer's account
        _mint(owner(), initialSupply);
    }

/// @notice Mint tokens
/// @dev Can only be called by owner (deployer)
/// @param _to: Address to mint tokens to
/// @param _amount: Amount of tokens to be minted
    function mint(address _to, uint256 _amount) external onlyOwner {
        // Calling IERC20._mint() function
        _mint(_to, _amount);
    }

}

// SPDX-License-Identifier: GNU

pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeFundToken is ERC20, Ownable {

    uint256 initialSupply;
    constructor (uint256 _initialSupply) ERC20("DeFundToken", "DFND") {
        initialSupply = _initialSupply;
        _mint(owner(), initialSupply);
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

}

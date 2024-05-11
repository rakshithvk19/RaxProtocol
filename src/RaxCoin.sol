// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title RaxCoin
 * @author Rakshith_Rajkumar
 * @notice This contract is meant to be governed by RaxEngin. This contract is ERC20 implementation of a stablecoin named RaxCoin.
 * TokenCollateral: wETH & wBTC
 * TokenMinting: Algorithmic
 * Relative Stability: Pegged to USD
 *
 */
contract RaxCoin is ERC20Burnable, Ownable {
    ///Custom Errors
    error RaxCoin__MustBeMoreThanZero();
    error RaxCoin__BurnAmountExceedsBalance();
    error RaxCoin__NotZeroAddress();

    constructor() ERC20("RaxCoin", "RAX") Ownable(msg.sender) {}

    /**
     * @param _amount Amount of Tokens that needs to be burned
     * @dev Function to burn the tokens created
     */
    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);

        if (_amount <= 0) {
            revert RaxCoin__MustBeMoreThanZero();
        }

        if (_amount < balance) {
            revert RaxCoin__BurnAmountExceedsBalance();
        }

        super.burn(_amount);
    }

    /**
     * @param _to The address to whom the token is minted to.
     * @param _amount Amount of tokens that needs to be minted.
     * @dev Function to mint tokens
     */
    function mint(
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert RaxCoin__NotZeroAddress();
        }

        if (_amount <= 0) {
            revert RaxCoin__MustBeMoreThanZero();
        }

        _mint(_to, _amount);
        return true;
    }
}

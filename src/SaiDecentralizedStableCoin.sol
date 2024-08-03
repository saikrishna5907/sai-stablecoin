// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions
// SPDX-Licence-Identifier: MIT

pragma solidity 0.8.20;

import {ERC20, ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SaiDecentralizedStableCoin
 * @author Saikrishna Sangishetty
 * Collateral: Exogenous (ETH & BTC)
 * Minting: Algorithmic
 * Relative Stability: Peddged to USD
 *
 * This is the contract meant to be governed by SaiDSCEngine and it is just the ERC20 implmentation of our stablecoin system.
 */
contract SaiDecentralizedStableCoin is ERC20Burnable, Ownable {
    error SaiDecentralizedStableCoin__MustBeMoreThanZero();
    error SaiDecentralizedStableCoin__BurnAmountIsMoreThanBalance();
    error SaiDecentralizedStableCoin__NotZeroAddress();

    constructor(
        address owner
    ) ERC20("Sai Decentralized Stable Coin", "SAIT") Ownable(owner) {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);

        if (_amount <= 0) {
            revert SaiDecentralizedStableCoin__MustBeMoreThanZero();
        }

        if (_amount > balance) {
            revert SaiDecentralizedStableCoin__BurnAmountIsMoreThanBalance();
        }

        super.burn(_amount);
    }

    function mint(
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert SaiDecentralizedStableCoin__NotZeroAddress();
        }
        if (_amount <= 0) {
            revert SaiDecentralizedStableCoin__MustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }
}

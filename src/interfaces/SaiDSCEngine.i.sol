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

/**
 * @author  Saikrishna Sangishetty
 * @title   Interface of the SaiDSCEngine contract.
 * @notice
 */
interface ISaiDSCEngine {
    function depositCollateralAndMintSDSC() external;

    function despositCollateral(address tokenCollateralAddress, uint256 collateralAmount) external;

    function redeemCollateralForSDSC() external;

    function redeemCollateral() external;

    function mintSDSC(uint256 sdscAmountToMint) external;

    function burnSDSC() external;

    /**
     * @notice Threshold to let's say 150%
     * For a $100 of ETH Collateral, then user1 mints $50 of SDSC
     * if ETH tanks to $74 worth, then this is will UNDERCOLLATERALIZED!!!
     * some other say user2 will see this UNDERCOLLATERALIZED and will liquidate the user1
     * by paying $50 of SDSC -> this user2 will get the $74 worth of ETH which is the entire collateral of user1
     * Result would be
     * user1 -> $0 of ETH
     * user2 -> $74 of ETH minus the $50 of SDSC
     */
    function liquidate() external;

    function getHealthFactor() external view;
}

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
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ISaiDSCEngine} from "./interfaces/SaiDSCEngine.i.sol";
import {SaiDecentralizedStableCoin} from "./SaiDecentralizedStableCoin.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/interfaces/AggregatorV3Interface.sol";
/**
 * @title SaiDSCEngine
 * @author Saikrishna Sangishetty
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token = $1 PEG
 * This stablecoint has the properties:
 * - Exogenous Collateral
 * - Dollar Pegged
 * - Algorithmically Stable
 *
 * It is simialr to DAI if DAI has no governance, no fees, and was only backed by WETH and WBTC.
 *
 * This system should always be "overcollateralized". At no point, should the value of all collateral <= the $ backed value of all the SDSC.
 *
 * @notice This contract is the core of the SDSC System. It handles all the logic for mining and redeeming SDSC, as well as depositing & withdrawing collateral.
 * @notice This contract is very loosely based on the MakerDAO DSS (DAI) System.
 */

contract SaiDSCEngine is ISaiDSCEngine, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error SaiDSCEngine__MustBeMoreThanZero();
    error SaiDSCEngine__TokensAndPriceFeedsMustBeSameLength();
    error SaiDSCEngine__TokenNotAllowed();
    error SaiDSCEngine__CollateralTransferFailed();
    error SaiDSCEngine__MintFailed();
    error SaiDSCEngine__HealthFactorFailed(uint256 healthFactor);
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralBalances;
    mapping(address user => uint256 amountMinted) private s_SDSCMinted;

    SaiDecentralizedStableCoin private i_sdsc;
    address[] private s_allowedCollateralTokens;
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // user should be 200% over collateralized
    uint256 private constant LIQUIDATION_PRECISION = 10;
    uint256 private constant MINIMUM_HEALTH_FACTOR = 1;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event CollateralDeposited(address indexed user, address indexed tokenCollateralAddress, uint256 collateralAmount);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice reverts with "SaiDSCEngine__MustBeMoreThanZero" if amount sent is less than or equal zero, else continues to execute
     * @param amount the amount to check for validation
     */
    modifier mustBeGreaterThenZero(uint256 amount) {
        if (amount == 0) {
            revert SaiDSCEngine__MustBeMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address tokenAddress) {
        if (s_priceFeeds[tokenAddress] == address(0)) {
            revert SaiDSCEngine__TokenNotAllowed();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @param tokenAddresses list of tokens that are allowed for collateral
     * @param priceFeedAddresses list of allowed token's respective price feed addresses
     * @param sdscAddress SaiDecentralizedStableCoin address
     * @custom:example
     * tokenAddresses = [<ETH address>, <BTC address>, <ADA address>, <MATIC address>]
     * priceFeedAddresses = [<ETH price feed address>, <BTC price feed address>, <ADA price feed address>, <MATIC price feed address>]
     */
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address sdscAddress) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert SaiDSCEngine__TokensAndPriceFeedsMustBeSameLength();
        }

        /**
         * for a token address setting the price feed that particular token in s_priceFeeds
         */
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_allowedCollateralTokens.push(tokenAddresses[i]);
        }
        i_sdsc = SaiDecentralizedStableCoin(sdscAddress);
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function depositCollateralAndMintSDSC() external override {}

    /**
     * @param tokenCollateralAddress  The address of the token to deposit as collateral
     * @param collateralAmount The amount of collateral to deposit
     * @dev it follows CEI pattern
     */
    function despositCollateral(address tokenCollateralAddress, uint256 collateralAmount)
        external
        override
        mustBeGreaterThenZero(collateralAmount)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralBalances[msg.sender][tokenCollateralAddress] += collateralAmount;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, collateralAmount);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), collateralAmount);
        if (!success) {
            revert SaiDSCEngine__CollateralTransferFailed();
        }
    }

    function redeemCollateralForSDSC() external override {}

    function redeemCollateral() external override {}

    /**
     * @dev It follows CEI pattern
     * @param sdscAmountToMint The amount of SDSC to mint
     * @notice minting SDSC is only possible if the user has enough collateral, which is more than the minimum threshold
     */
    function mintSDSC(uint256 sdscAmountToMint)
        external
        override
        mustBeGreaterThenZero(sdscAmountToMint)
        nonReentrant
    {
        s_SDSCMinted[msg.sender] += sdscAmountToMint;
        _revertIfHealthFactorIsFailed(msg.sender);

        bool minted = i_sdsc.mint(msg.sender, sdscAmountToMint);

        if (!minted) revert SaiDSCEngine__MintFailed();
    }

    function burnSDSC() external override {}

    function liquidate() external override {}

    function getHealthFactor() external view override {}

    /*//////////////////////////////////////////////////////////////
                     PRIVATE AND INTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalSDSCMinted, uint256 collateralValueInUSD)
    {
        totalSDSCMinted = s_SDSCMinted[user];
        collateralValueInUSD = getAccountCollateralValueInUSD(user);
    }

    /**
     * Returns how close the user is to being liquidated
     * If a user goes below 1, then they can get liquidated
     * @param user The address of the user
     */
    function _healthFactor(address user) internal view returns (uint256) {
        (uint256 totalSDSCMinted, uint256 collateralValueInUSD) = _getAccountInformation(user);

        uint256 collateralAdjustedForThreshold = (collateralValueInUSD * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;

        return (collateralAdjustedForThreshold * PRECISION) / totalSDSCMinted;
    }

    /**
     *
     * @param user The address of the user
     * @notice if the health factor of the user is below the set MINIMUM_HEALTH_FACTOR then it revert error
     */
    function _revertIfHealthFactorIsFailed(address user) internal view {
        uint256 userHealthFactor = _healthFactor(user);

        if (userHealthFactor < MINIMUM_HEALTH_FACTOR) {
            revert SaiDSCEngine__HealthFactorFailed(userHealthFactor);
        }
    }

    /*//////////////////////////////////////////////////////////////
                     PUBLIC AND EXTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getAccountCollateralValueInUSD(address user) public view returns (uint256 totalCollateralValueInUSD) {
        for (uint256 i = 0; i < s_allowedCollateralTokens.length; i++) {
            address token = s_allowedCollateralTokens[i];
            /**
             * @dev ex: if a user has deposited collateral of 100 ETH  then this tokenAmount will 100 for ETH token
             */
            uint256 tokenAmount = s_collateralBalances[user][token];
            totalCollateralValueInUSD += getUSDValue(token, tokenAmount);
        }
        return totalCollateralValueInUSD;
    }

    function getUSDValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);

        (, int256 price,,,) = priceFeed.latestRoundData();

        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION;
    }
}

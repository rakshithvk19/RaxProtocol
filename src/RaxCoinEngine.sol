// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RaxCoin} from "./RaxCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/interfaces/feeds/AggregatorV3Interface.sol";

/**
 * @title RaxCoinEngine
 * @author Rakshith_Rajkumar
 * @notice This contract is the core of RaxCoin Engine. It contains the logic to mint and burn RaxCoin and also depositing and withdrawing collateral.
 * The system is designed to be pegged and maintain as 1 RAX == 1USD.
 *
 * Features of RaxCoinEngine
 * 1. Overcollateralized.
 *
 */
contract RaxCoinEngine is ReentrancyGuard {
    ///////////////////////////
    //       ERRORS          //
    ///////////////////////////

    error RaxCoinEngine__NeedsMoreThanZero();
    error RaxCoinEngine__UnequalCollateralTokensAndPriceFeedAddress(
        uint256 numCollateralTokens, uint256 numCollateralPriceFeed
    );
    error RaxCoinEngine__CannotBeZeroAddress();
    error RaxCoinEngine__DepositCollateralFailed();
    error RaxCoinEngine__MsgSenderCannotBeZeroAddress();
    error RaxCoinEngine__HealthFactorIsBelowMinimum(uint256 healthFactorValue);
    error RaxCoin__MintFailed();

    //////////////////////////////
    //     STATE VARIABLES      //
    //////////////////////////////
    RaxCoin private immutable i_RaxCoin;
    /// @dev Mapping of pricefeed address of the collateral token address.
    mapping(address token => address priceFeed) private s_priceFeeds;

    /// @dev Amount of collateral deposited by the user
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;

    /// @dev Amount of RAX coins minted by an account
    mapping(address user => uint256 RaxMinted) s_RAXMinted;

    /// @dev Addresses of the collateral tokens deposited.
    address[] private s_collateralTokens;

    uint256 private constant ADDITIONAL_PRICE_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1;

    ///////////////////////////
    //         EVENTS        //
    ///////////////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);

    ///////////////////////////
    //       MODIFIERS       //
    ///////////////////////////

    modifier moreThanZero(uint256 amount) {
        if (amount > 0) {
            revert RaxCoinEngine__NeedsMoreThanZero();
        }

        _;
    }

    modifier isTokenAllowed(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert RaxCoinEngine__CannotBeZeroAddress();
        }

        // if()
        _;
    }

    modifier senderCannotBeZeroAddress(address sender) {
        if (sender == address(0)) {
            revert RaxCoinEngine__MsgSenderCannotBeZeroAddress();
        }
        _;
    }

    ///////////////////////////
    //       FUNCTIONS       //
    ///////////////////////////

    /**
     *
     * @param tokenAddress Address of Tokens that can be used as collaterals.
     * @param priceFeedAddress Address of priceFeeds between Token/USD on a chain.
     * @param RaxCoinAddress Address of RAX Token deployed on chain.
     * @notice Only tokens that are having priceFeeds on a particular chain and PriceFeed of token/USD can be used as collateral against RAX tokens.
     * Also storing the addresses of the tokens that is deposited as collateral.
     */
    constructor(address[] memory tokenAddress, address[] memory priceFeedAddress, address RaxCoinAddress) {
        if (tokenAddress.length != priceFeedAddress.length) {
            revert RaxCoinEngine__UnequalCollateralTokensAndPriceFeedAddress(
                tokenAddress.length, priceFeedAddress.length
            );
        }

        //Adding address of the priceFeed of the provided collateral.
        //Capture the collateral token address.
        for (uint256 i = 0; i < tokenAddress.length; i++) {
            s_priceFeeds[tokenAddress[i] = priceFeedAddress[i]];
            s_collateralTokens.push(tokenAddress[i]);
        }
    }

    ////////////////////////////////////
    //       EXTERNAL FUNCTIONS       //
    ////////////////////////////////////

    function depositeCollateralAndMintRAX() external {}

    function redeemCollateralForRAX() external {}

    /**
     * @param tokenCollateralAddress The address of the collateral where it is stored
     * @param collateralAmount The amount of collateral that one is depositing for the RAX.
     * @notice Allows the user to deposit Collateral to the contract thereby storing the details in the contract after doing the necessary checks and conditions. Also has 'nonReentrant' modifier from OZ library for security purposes.
     */
    function depositCollateral(address tokenCollateralAddress, uint256 collateralAmount)
        external
        moreThanZero(collateralAmount)
        isTokenAllowed(tokenCollateralAddress)
        senderCannotBeZeroAddress(msg.sender)
        nonReentrant
    {
        //Updating state variable
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += collateralAmount;

        //Emiting event
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, collateralAmount);

        //Transfer collateral amount to be held in contract
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), collateralAmount);

        if (!success) {
            revert RaxCoinEngine__DepositCollateralFailed();
        }
    }

    function redeemCollateral() external {}

    /**
     * @notice This function allows the user to mint the Rax Coins after predetermined conditions are satisfied.
     *  This function also gives the user the flexibility to mint the amount of RaxCoins whose value in USD <= value of collateral in USD.
     *  Ex: User can deposit collateral worth of $60 and choose to mint only $20 USD worth of RAX.
     *  The user should have a collateral value greater than the minimum threshold specified in the contract.
     * @param _amountRaxToMint amount of RAX tokens to mint to an user.
     */
    function mintRAX(uint256 _amountRaxToMint)
        external
        senderCannotBeZeroAddress(msg.sender)
        moreThanZero(_amountRaxToMint)
        nonReentrant
    {
        //Update state variable to store amount of RAX minted to particular user.
        s_RAXMinted[msg.sender] += _amountRaxToMint;

        //Collateral value in USD> RAX value in USD
        _revertIfHealtFactorIsBroken(msg.sender);

        bool mint = i_RaxCoin.mint(msg.sender, _amountRaxToMint);
        if (!mint) {
            revert RaxCoin__MintFailed();
        }
    }

    function burnRAX() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}

    ////////////////////////
    //  PUBLIC FUNCTIONS  //
    ////////////////////////

    ////////////////////////////////////////////////////
    //       PRIVATE & INTERNAL VIEW  FUNCTIONS       //
    ////////////////////////////////////////////////////

    /**
     *
     * @param userAddress The address of the user of of whom we should fetch the information.
     * @return totalRAXMinted Total amount of RAX tokens minted by the user.
     * @return collateralValueInUsd The collateral value deposited by the user in USD.
     */
    function _getAccountInformation(address userAddress)
        private
        view
        returns (uint256 totalRAXMinted, uint256 collateralValueInUsd)
    {
        totalRAXMinted = s_RAXMinted[userAddress];
        collateralValueInUsd = getAccountCollateralValue(userAddress);
    }

    /**
     *
     * @param user address for which we are calculating the health factor.
     * @dev Function to calculate the health factor of the debt.
     * Returns how close to liquidation is a users to RAX tokens.
     * If collateral value wrt RAX token value in USD goes below 1, then the collateral is liquidated to recover the amount.
     *
     */
    function _healthFactor(address user) private view returns (uint256) {
        (uint256 totalTokensMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);

        //Adjust the collateral value to include liquidation threshold. Makes sure that the RAX minted is always overcollateralized.
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;

        return ((collateralAdjustedForThreshold * LIQUIDATION_PRECISION) / totalTokensMinted);
    }

    /**
     *
     * @param user address of the user for whom we are checking the health factor
     * @dev Internal function that reverts with custom error if health factor of the user address is not satisfied.
     */
    function _revertIfHealtFactorIsBroken(address user) internal view {
        uint256 userHealthFactor = _healthFactor(user);

        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert RaxCoinEngine__HealthFactorIsBelowMinimum(userHealthFactor);
        }
    }

    ////////////////////////////////////
    // PUBLIC & EXTERNAL FUNCTION     //
    ////////////////////////////////////

    /**
     *
     * @param user Account address of the user to get the collateral of.
     * @notice Returns the value of the collateral deposited in USD of the specified user.
     */
    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 collateralAmount = s_collateralDeposited[user][token];

            totalCollateralValueInUsd += getAmountInUsd(token, collateralAmount);
        }
        return totalCollateralValueInUsd;
    }

    /**
     *
     * @param token the address of the token which is deposited as collateral.
     * @param amount the number of token deposited as collateral.
     * @notice Returns the value of tokens in USD for the specified amount of tokens from the priceFeed.
     * Chainlink Pricefeed returns the rounddata with a precision of 1e10.
     */
    function getAmountInUsd(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);

        (, int256 price,,,) = priceFeed.latestRoundData();

        //value returned from ChainLink PriceFeed is explicitly converted to unsigned integers.
        return ((uint256(price) * ADDITIONAL_PRICE_FEED_PRECISION) * amount) / PRECISION;
    }
}

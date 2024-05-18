// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RaxCoin} from "./RaxCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
        uint256 numCollateralTokens,
        uint256 numCollateralPriceFeed
    );
    error RaxCoinEngine__CannotBeZeroAddress();
    error RaxCoinEngine__DepositCollateralFailed();

    //////////////////////////////
    //     STATE VARIABLES      //
    //////////////////////////////
    RaxCoin private immutable i_RaxCoin;
    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount))
        private s_collateralDeposited;

    ///////////////////////////
    //         EVENTS        //
    ///////////////////////////
    event CollateralDeposited(
        address indexed user,
        address indexed token,
        uint256 amount
    );

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

    ///////////////////////////
    //       FUNCTIONS       //
    ///////////////////////////

    /**
     *
     * @param tokenAddress Address of Tokens that can be used as collaterals.
     * @param priceFeedAddress Address of priceFeeds between Token/USD on a chain.
     * @param RaxCoinAddress Address of RAX Token deployed on chain.
     *
     *
     * @notice Only tokens that are having priceFeeds on a particular chain  and PriceFeed of token/USD can be used as collateral againest RAX tokens
     */
    constructor(
        address[] memory tokenAddress,
        address[] memory priceFeedAddress,
        address RaxCoinAddress
    ) {
        if (tokenAddress.length != priceFeedAddress.length) {
            revert RaxCoinEngine__UnequalCollateralTokensAndPriceFeedAddress(
                tokenAddress.length,
                priceFeedAddress.length
            );
        }

        for (uint256 i = 0; i < tokenAddress.length; i++) {
            s_priceFeeds[tokenAddress[i] = priceFeedAddress[i]];
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
     */
    function depositCollateral(
        address tokenCollateralAddress,
        uint256 collateralAmount
    )
        external
        moreThanZero(collateralAmount)
        isTokenAllowed(tokenCollateralAddress)
        nonReentrant
    {
        if (msg.sender == address(0)) {
            revert RaxCoinEngine__CannotBeZeroAddress();
        }

        s_collateralDeposited[msg.sender][
            tokenCollateralAddress
        ] += collateralAmount;

        emit CollateralDeposited(
            msg.sender,
            tokenCollateralAddress,
            collateralAmount
        );

        bool success = IERC20(tokenCollateralAddress).transferFrom(
            msg.sender,
            address(this),
            collateralAmount
        );

        if (!success) {
            revert RaxCoinEngine__DepositCollateralFailed();
        }
    }

    function redeemCollateral() external {}

    function mintRAX() external {}

    function burnRAX() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RaxCoin} from "src/RaxCoin.sol";
import {DeployRAX} from "script/DeployRaxCoin.s.sol";

contract RaxCoinTest is Test {
    RaxCoin public raxCoin;
    error OwnableUnauthorizedAccount(address account);

    address ADMIN = makeAddr("admin");
    address ALICE = makeAddr("alice");

    function setUp() external {
        // DeployRAX deployRax = new DeployRAX();
        // raxCoin = deployRax.run();

        /**
         * RAXCOIN contract deployed by ADMIN who is also the inital owner of the contract.
         */

        vm.startBroadcast(ADMIN);
        raxCoin = new RaxCoin();
        vm.stopBroadcast();
    }

    ///////////////////////////////
    //        Mint Function      //
    ///////////////////////////////

    function test_MintValidAmountByRaxCoinDeployer() public {
        //ARRANGE/ACT
        // Mint tokens to the contract
        vm.startPrank(ADMIN);
        bool success = raxCoin.mint(ADMIN, 1000);

        //ASSERT
        // Assert that the mint operation was successful
        assertTrue(success);

        // Assert that the balance has increased
        assertEq(raxCoin.balanceOf(ADMIN), 1000);
        vm.stopPrank();
    }

    function test_MintValidAmountByAddressOtherThanRaxCoinDeployer() public {
        //Arrange
        vm.startPrank(ADMIN);

        //Act
        bool success = raxCoin.mint(ALICE, 1000);

        //Assert
        assertTrue(success);
    }

    function test_RevertNotRaxCoinOwnerMintingTokens() public {
        //Arrange
        vm.startPrank(ALICE);

        //Asserting revert
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, ALICE)
        );

        //Act
        bool success = raxCoin.mint(ADMIN, 1000);

        //Asserting Success
        assertTrue(!success);

        vm.stopPrank();
    }

    function test_RevertOnMintingZeroAmount() public {
        //Arrange
        vm.startPrank(ADMIN);

        //Assert
        vm.expectRevert(
            abi.encodeWithSelector(RaxCoin.RaxCoin__MustBeMoreThanZero.selector)
        );

        //Act
        bool success = raxCoin.mint(ADMIN, 0);

        //assert
        assertTrue(!success);
        vm.stopPrank();
    }

    function test_RevertOnMintingToZeroAddress() public {
        //Arrange
        vm.startPrank(ADMIN);

        //Assert
        vm.expectRevert(
            abi.encodeWithSelector(RaxCoin.RaxCoin__NotZeroAddress.selector)
        );
        //Act
        bool success = raxCoin.mint(address(0), 1000);

        //Assert
        assertTrue(!success);
    }

    ///////////////////////////////
    //        Burn Function      //
    ///////////////////////////////

    function test_Burn() public {
        console.log("Testing Burn Functionality");
    }
}

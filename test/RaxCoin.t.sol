// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RaxCoin} from "src/RaxCoin.sol";
import {DeployRAX} from "script/DeployRaxCoin.s.sol";

contract RaxCoinTest is Test {
    RaxCoin raxCoin;

    function setUp() external {
        DeployRAX deployRax = new DeployRAX();

        raxCoin = deployRax.run();
    }

    ///////////////////////////////
    //        Burn Function      //
    ///////////////////////////////

    function test_Burn() public {
        console.log("Testing Burn Functionality");
    }

    ///////////////////////////////
    //        Mint Function      //
    ///////////////////////////////

    function test_Mint() public {
        console.log("Testing Mint Functionality");
    }
}

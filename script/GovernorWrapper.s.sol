// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {GovernorWrapper} from "../src/GovernorWrapper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GovernorWrapperScript is Script {
    GovernorWrapper public governorWrapper;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        governorWrapper = new GovernorWrapper(
            IERC20(address(0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72)),
            "Voting ENS Wrapper",
            "vENS",
            address(0)
        );

        vm.stopBroadcast();
    }
}

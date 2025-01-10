// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {GovernorWrapper} from "../src/GovernorWrapper.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GovernorWrapperTest is Test {
    GovernorWrapper public wrapper;
    ERC20Votes public token;
    address public delegatee;

    address constant ENS_TOKEN = 0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72;
    address constant ENS_WHALE = 0xFe89cc7aBB2C4183683ab71653C4cdc9B02D44b7;
    address constant USER = address(0xbeef);

    uint256 constant AMOUNT = 1000 * 10**18;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        token = ERC20Votes(ENS_TOKEN);
        delegatee = address(0xdead);

        wrapper = new GovernorWrapper(
            IERC20(address(token)),
            "Voting ENS Wrapper",
            "vENS",
            delegatee
        );

        vm.prank(ENS_WHALE);
        token.transfer(USER, AMOUNT);
    }

    function test_InitialDelegation() public {
        assertEq(token.delegates(address(wrapper)), delegatee);
    }

    function testFuzz_OneToOneConversion(uint256 amount) public {
        vm.assume(amount < type(uint256).max);
        assertEq(wrapper.convertToShares(amount), amount);
        assertEq(wrapper.convertToAssets(amount), amount);
    }

    function test_Deposit() public {
        vm.startPrank(USER);
        token.approve(address(wrapper), AMOUNT);
        wrapper.deposit(AMOUNT, USER);
        vm.stopPrank();

        assertEq(wrapper.balanceOf(USER), AMOUNT);
        assertEq(token.balanceOf(address(wrapper)), AMOUNT);
        assertEq(token.delegates(address(wrapper)), delegatee);
    }

    function test_VotingPower() public {
        vm.startPrank(USER);
        token.approve(address(wrapper), AMOUNT);
        wrapper.deposit(AMOUNT, USER);
        vm.stopPrank();

        assertEq(token.getVotes(delegatee), AMOUNT);
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AragonDelegateVault, IAragonVoting} from "../src/AragonDelegateVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AragonDelegateVaultTest is Test {
    AragonDelegateVault public vault;
    IERC20 public token;
    address public delegatee;

    // TODO: change for lido
    address constant LDO_TOKEN = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;
    address constant LDO_WHALE = 0x3e40D73EB977Dc6a537aF587D48316feE66E9C8c;
    address constant USER = address(0xbeef);
    IAragonVoting constant ARAGON_VOTING =
        IAragonVoting(0x2e59A20f205bB85a89C53f1936454680651E618e);

    uint256 constant AMOUNT = 1000 * 10 ** 18;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        token = IERC20(LDO_TOKEN);
        delegatee = address(0xdead);

        vault = new AragonDelegateVault(
            IERC20(address(token)),
            "Voting ENS Wrapper",
            "vENS",
            delegatee,
            address(ARAGON_VOTING)
        );

        vm.prank(LDO_WHALE);
        token.transfer(USER, AMOUNT);
    }

    function test_InitialDelegation() public {
        assertEq(ARAGON_VOTING.getDelegate(address(vault)), delegatee);
    }

    function testFuzz_OneToOneConversion(uint256 amount) public {
        vm.assume(amount < type(uint256).max);
        assertEq(vault.convertToShares(amount), amount);
        assertEq(vault.convertToAssets(amount), amount);
    }

    function test_Deposit() public {
        vm.startPrank(USER);
        token.approve(address(vault), AMOUNT);
        vault.deposit(AMOUNT, USER);
        vm.stopPrank();

        assertEq(vault.balanceOf(USER), AMOUNT);
        assertEq(token.balanceOf(address(vault)), AMOUNT);
        assertEq(ARAGON_VOTING.getDelegate(address(vault)), delegatee);
    }

    function test_VotingPower() public {
        vm.startPrank(USER);
        token.approve(address(vault), AMOUNT);
        vault.deposit(AMOUNT, USER);
        vm.stopPrank();

        address[] memory addresses = new address[](1);

        addresses[0] = address(vault);

        assertEq(ARAGON_VOTING.getVotingPowerMultiple(addresses)[0], AMOUNT);
        assertEq(ARAGON_VOTING.getDelegate(address(vault)), delegatee);
    }
}

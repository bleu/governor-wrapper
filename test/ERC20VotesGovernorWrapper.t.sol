// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ERC20VotesGovernorWrapper} from "../src/ERC20VotesGovernorWrapper.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IENSGovernor} from "../src/interfaces/IENSGovernor.sol";
contract GovernorWrapperTest is Test {
    ERC20VotesGovernorWrapper public wrapper;
    ERC20Votes public token;
    address public delegatee;

    address constant ENS_TOKEN = 0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72;
    address constant ENS_WHALE = 0xFe89cc7aBB2C4183683ab71653C4cdc9B02D44b7;
    address constant USER = address(0xbeef);
    IENSGovernor constant ENS_GOVERNOR =
        IENSGovernor(0x323A76393544d5ecca80cd6ef2A560C6a395b7E3);
    uint256 constant AMOUNT = 1000 * 10 ** 18;
    address constant CREATOR = 0x809FA673fe2ab515FaA168259cB14E2BeDeBF68e;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        token = ERC20Votes(ENS_TOKEN);
        delegatee = address(0xdead);

        wrapper = new ERC20VotesGovernorWrapper(
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

    function test_e2e() public {
        vm.startPrank(USER);
        token.approve(address(wrapper), AMOUNT);
        wrapper.deposit(AMOUNT, USER);
        vm.stopPrank();

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        string memory description = "test";

        vm.roll(vm.getBlockNumber() + 1);
        vm.prank(CREATOR);
        uint256 proposalId = ENS_GOVERNOR.propose(
            targets,
            values,
            calldatas,
            description
        );

        vm.roll(vm.getBlockNumber() + ENS_GOVERNOR.votingDelay() + 1);

        vm.prank(delegatee);
        uint256 balance = ENS_GOVERNOR.castVote(proposalId, 1);

        assert(ENS_GOVERNOR.hasVoted(proposalId, delegatee));

        assertEq(balance, AMOUNT);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AragonGovernorWrapper, IAragonVoting} from "../src/AragonGovernorWrapper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AragonDelegateVaultTest is Test {
    AragonGovernorWrapper public wrapper;
    IERC20 public token;
    address public delegatee;

    address constant LDO_TOKEN = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;
    address constant LDO_WHALE = 0x3e40D73EB977Dc6a537aF587D48316feE66E9C8c;
    address constant USER = address(0xbeef);
    IAragonVoting constant ARAGON_VOTING =
        IAragonVoting(0x2e59A20f205bB85a89C53f1936454680651E618e);
    address constant CREATOR = 0xf73a1260d222f447210581DDf212D915c09a3249;

    uint256 constant AMOUNT = 1000 * 10 ** 18;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        token = IERC20(LDO_TOKEN);
        delegatee = address(0xdead);

        wrapper = new AragonGovernorWrapper(
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
        assertEq(ARAGON_VOTING.getDelegate(address(wrapper)), delegatee);
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
        assertEq(ARAGON_VOTING.getDelegate(address(wrapper)), delegatee);
    }

    function test_VotingPower() public {
        vm.startPrank(USER);
        token.approve(address(wrapper), AMOUNT);
        wrapper.deposit(AMOUNT, USER);
        vm.stopPrank();

        address[] memory addresses = new address[](1);

        addresses[0] = address(wrapper);

        assertEq(ARAGON_VOTING.getVotingPowerMultiple(addresses)[0], AMOUNT);
        assertEq(ARAGON_VOTING.getDelegate(address(wrapper)), delegatee);
    }

    function test_e2e() public {
        vm.startPrank(USER);
        token.approve(address(wrapper), AMOUNT);
        wrapper.deposit(AMOUNT, USER);
        vm.stopPrank();

        vm.startPrank(CREATOR);
        bytes memory data = new bytes(32);
        string memory metadata = "test";

        vm.roll(vm.getBlockNumber() + 1);
        uint256 voteId = ARAGON_VOTING.newVote(data, metadata, false, false);
        vm.stopPrank();

        vm.roll(vm.getBlockNumber() + 1);
        assertEq(ARAGON_VOTING.canVote(voteId, address(wrapper)), true);

        vm.startPrank(delegatee);
        ARAGON_VOTING.attemptVoteFor(voteId, true, address(wrapper));

        vm.stopPrank();

        // enum VoterState {
        //     Absent, // Voter has not voted
        //     Yea, // Voter has voted for
        //     Nay, // Voter has voted against
        //     DelegateYea, // Delegate has voted for on behalf of the voter
        //     DelegateNay // Delegate has voted against on behalf of the voter
        // }

        assertEq(ARAGON_VOTING.getVoterState(voteId, address(wrapper)), 3);

        (, , , , , , uint256 yea, , , , ) = ARAGON_VOTING.getVote(voteId);

        assertEq(yea, AMOUNT);
    }
}

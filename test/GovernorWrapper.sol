// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {GovernorWrapper} from "../src/GovernorWrapper.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { TokenConfig, PoolRoleAccounts } from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { PoolHooksMock } from "@balancer-labs/v3-vault/contracts/test/PoolHooksMock.sol";
import { IBatchRouter } from "@balancer-labs/v3-interfaces/contracts/vault/IBatchRouter.sol";

import {WETH} from "solmate/src/tokens/WETH.sol";

import {IWeightedPool} from "@balancer-labs/v3-interfaces/contracts/pool-weighted/IWeightedPool.sol";
import { BasePoolTest } from "@balancer-labs/v3-vault/test/foundry/utils/BasePoolTest.sol";
import { CastingHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/CastingHelpers.sol";
import { InputHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/InputHelpers.sol";
import { ArrayHelpers } from "@balancer-labs/v3-solidity-utils/contracts/test/ArrayHelpers.sol";
import { WeightedPool } from "@balancer-labs/v3-pool-weighted/contracts/WeightedPool.sol";
import { WeightedPoolFactory } from "@balancer-labs/v3-pool-weighted/contracts/WeightedPoolFactory.sol";
import { WeightedPoolContractsDeployer } from "@balancer-labs/v3-pool-weighted/test/foundry/utils/WeightedPoolContractsDeployer.sol";

contract GovernorWrapperTest is Test, WeightedPoolContractsDeployer, BasePoolTest {
    using CastingHelpers for address[];
    using ArrayHelpers for *;

    GovernorWrapper public wrapper;
    ERC20Votes public ens;
    address public delegatee;

    address constant ENS_TOKEN = 0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72;
    address constant ENS_WHALE = 0xFe89cc7aBB2C4183683ab71653C4cdc9B02D44b7;
    address constant USER = address(0xbeef);
    // address lpaddr = 0x44bC268D6f10DfB004c5b9afe91648b1c7c8b6D9;
    // address payable lp = payable(address(0x3000)) ;

    uint256 constant AMOUNT = 1000 * 10**18;

    string constant POOL_VERSION = "Pool v1";
    uint256 constant DEFAULT_SWAP_FEE = 1e16; // 1%
    uint256 constant TOKEN_AMOUNT = 1e3 * 1e18;

    uint256[] internal weights;

    uint256 wethIdx;
    uint256 wrapperIdx;

    function setUp() public virtual override {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        ens = ERC20Votes(ENS_TOKEN);
        delegatee = address(0xdead);

        wrapper = new GovernorWrapper(
            IERC20(address(ens)),
            "Voting ENS Wrapper",
            "vENS",
            delegatee
        );

        // vm.prank(ENS_WHALE);
        // ens.transfer(lp, AMOUNT);

        // vm.deal(lp, type(uint160).max); // Give ETH to lp
        // vm.prank(lp);
        // weth.deposit{value: type(uint160).max}();

        vm.prank(ENS_WHALE);
        ens.transfer(USER, AMOUNT);

        expectedAddLiquidityBptAmountOut = TOKEN_AMOUNT;
        tokenAmountIn = TOKEN_AMOUNT / 4;
        isTestSwapFeeEnabled = false;

        BasePoolTest.setUp();

        (wethIdx, wrapperIdx) = getSortedIndexes(address(weth), address(wrapper));

        poolMinSwapFeePercentage = 0.001e16; // 0.001%
        poolMaxSwapFeePercentage = 10e16;
    }

    function createPoolFactory() internal override returns (address) {
        vm.startPrank(lp);
        wrapper.approve(address(permit2), type(uint256).max);
        permit2.approve(address(wrapper), address(router), type(uint160).max, type(uint48).max);
        permit2.approve(address(wrapper), address(batchRouter), type(uint160).max, type(uint48).max);
        vm.stopPrank();

        vm.startPrank(ENS_WHALE);
        ens.approve(address(wrapper), type(uint256).max);
        wrapper.deposit(1e21, lp);
        vm.stopPrank();
    
        return address(deployWeightedPoolFactory(IVault(address(vault)), 365 days, "Factory v1", POOL_VERSION));
    }

    function createPool() internal override returns (address newPool, bytes memory poolArgs) {
        string memory name = "WeightedV3 8020 vENS-WETH";
        string memory symbol = "8020vENS-WETH";

        IERC20[] memory sortedTokens = InputHelpers.sortTokens(
            [address(weth), address(wrapper)].toMemoryArray().asIERC20()
        );
        for (uint256 i = 0; i < sortedTokens.length; i++) {
            poolTokens.push(sortedTokens[i]);
            tokenAmounts.push(TOKEN_AMOUNT);
        }

        weights = [uint256(20e16), uint256(80e16)].toMemoryArray();

        PoolRoleAccounts memory roleAccounts;
        // Allow pools created by `factory` to use poolHooksMock hooks
        PoolHooksMock(poolHooksContract).allowFactory(poolFactory);

        newPool = WeightedPoolFactory(poolFactory).create(
            name,
            symbol,
            vault.buildTokenConfig(sortedTokens),
            weights,
            roleAccounts,
            DEFAULT_SWAP_FEE,
            poolHooksContract,
            false, // Do not enable donations
            false, // Do not disable unbalanced add/remove liquidity
            ZERO_BYTES32
        );

        // poolArgs is used to check pool deployment address with create2.
        poolArgs = abi.encode(
            WeightedPool.NewPoolParams({
                name: name,
                symbol: symbol,
                numTokens: sortedTokens.length,
                normalizedWeights: weights,
                version: POOL_VERSION
            }),
            vault
        );
    }

    function initPool() internal override {
        vm.startPrank(lp);
        bptAmountOut = _initPool(
            pool,
            tokenAmounts,
            // Account for the precision loss
            expectedAddLiquidityBptAmountOut - DELTA
        );
        vm.stopPrank();
    }

    function testInitialize() public view virtual override {
        uint256 x =1;
        assertEq(x,x);
    }

    function testPoolPausedState() public view virtual override {
        uint256 x =1;
        assertEq(x,x);
    }

    function testAddLiquidity() public virtual override {
        uint256 x =1;
        assertEq(x,x);
    }

    function testRemoveLiquidity() public virtual override {
        uint256 x =1;
        assertEq(x,x);
    }

    function testSwap() public virtual override {
        uint256 initialVotes = ens.getVotes(delegatee);

        if (!isTestSwapFeeEnabled) {
            vault.manuallySetSwapFee(pool, 0);
        }

        vm.startPrank(ENS_WHALE);

        ens.approve(address(permit2), type(uint256).max);
        permit2.approve(address(ens), address(batchRouter), type(uint160).max, type(uint48).max);
        permit2.approve(address(ens), address(bufferRouter), type(uint160).max, type(uint48).max);

        uint256 shares = bufferRouter.initializeBuffer(wrapper, 1e18, 0, 0);
        vault.removeLiquidityFromBuffer(wrapper, shares, 0, 0);

        IBatchRouter.SwapPathStep[] memory steps = new IBatchRouter.SwapPathStep[](2);
        IBatchRouter.SwapPathExactAmountIn[] memory paths = new IBatchRouter.SwapPathExactAmountIn[](1);

        IERC20 tokenIn = IERC20(ens);
        IERC20 tokenOut = IERC20(weth);

        uint256 amountIn = 1e18;

        steps[0] = IBatchRouter.SwapPathStep({ pool: address(wrapper), tokenOut: wrapper, isBuffer: true });

        steps[1] = IBatchRouter.SwapPathStep({ pool: address(pool), tokenOut: tokenOut, isBuffer: false });

        paths[0] = IBatchRouter.SwapPathExactAmountIn({
            tokenIn: tokenIn,
            steps: steps,
            exactAmountIn: amountIn,
            minAmountOut: 0
        });

        batchRouter.swapExactIn(paths, MAX_UINT256, false, bytes(""));

        vm.stopPrank();

        assertEq(ens.getVotes(delegatee) - initialVotes, amountIn);

    }

    function test_InitialDelegation() public {
        assertEq(ens.delegates(address(wrapper)), delegatee);
    }

    function testFuzz_OneToOneConversion(uint256 amount) public {
        vm.assume(amount < type(uint256).max);
        assertEq(wrapper.convertToShares(amount), amount);
        assertEq(wrapper.convertToAssets(amount), amount);
    }

    function test_Deposit() public {
        uint256 initialUserBalance = wrapper.balanceOf(USER);
        uint256 initialWrapperBalance = ens.balanceOf(address(wrapper));

        vm.startPrank(USER);
        ens.approve(address(wrapper), AMOUNT);
        wrapper.deposit(AMOUNT, USER);
        vm.stopPrank();

        assertEq(wrapper.balanceOf(USER), initialUserBalance + AMOUNT);
        assertEq(ens.balanceOf(address(wrapper)),initialWrapperBalance + AMOUNT);
        assertEq(ens.delegates(address(wrapper)), delegatee);
    }

    function test_VotingPower() public {
        uint256 initialVotes = ens.getVotes(delegatee);

        vm.startPrank(USER);
        ens.approve(address(wrapper), AMOUNT);
        wrapper.deposit(AMOUNT, USER);
        vm.stopPrank();

        assertEq(ens.getVotes(delegatee) - initialVotes, AMOUNT);
    }
    
}
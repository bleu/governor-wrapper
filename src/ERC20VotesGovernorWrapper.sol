// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract ERC20VotesGovernorWrapper is ERC4626 {
    constructor(
        IERC20 asset_,
        string memory name_,
        string memory symbol_,
        address delegatee
    ) ERC20(name_, symbol_) ERC4626(asset_) {
        ERC20Votes(address(asset_)).delegate(delegatee);
    }

    function convertToShares(
        uint256 assets
    ) public view virtual override returns (uint256) {
        return assets;
    }

    function convertToAssets(
        uint256 shares
    ) public view virtual override returns (uint256) {
        return shares;
    }
}

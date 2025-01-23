// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20VotesGovernorWrapper.sol";

contract GovernorWrapperFactory {
    event WrapperCreated(address indexed token, address indexed wrapper);

    function create(
        IERC20 asset_,
        string memory name_,
        string memory symbol_,
        address delegatee
    ) external returns (ERC20VotesGovernorWrapper wrapper) {
        wrapper = new ERC20VotesGovernorWrapper(
            asset_,
            name_,
            symbol_,
            delegatee
        );

        emit WrapperCreated(address(asset_), address(wrapper));
    }
}

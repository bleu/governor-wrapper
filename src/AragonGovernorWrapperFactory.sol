// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AragonGovernorWrapper.sol";

contract AragonGovernorWrapperFactory {
    event WrapperCreated(address indexed token, address indexed wrapper);

    function create(
        IERC20 asset_,
        string memory name_,
        string memory symbol_,
        address delegatee,
        address voting
    ) external returns (AragonGovernorWrapper wrapper) {
        wrapper = new AragonGovernorWrapper(
            asset_,
            name_,
            symbol_,
            delegatee,
            voting
        );

        emit WrapperCreated(address(asset_), address(wrapper));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import {IERC20Metadata} from "../../lib/openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";

/**
 * @title IZi
 * @dev This is the interface for the Zi contract which extends the ERC20 standard.
 * It includes functions for minting and burning tokens as well as getting the one basis point of the total supply,
 * and variables for the initial supply and supply limit.
 */
interface IZi is IERC20Metadata {
    /**
     * @notice Mint a specific amount of tokens.
     * @dev This function allows to create a specified amount of the token and assign it to an account.
     * It encapsulates the _mint internal function which does the increment.
     * @param account The address of the recipient who receives the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address account, uint256 amount) external;

    /**
     * @notice Burn a specific amount of tokens.
     * @dev This function allows to destroy a specified amount of the token from an account.
     * It encapsulates the _burn internal function which does the decrement.
     * @param account The address from which tokens will be burned.
     * @param amount The amount of tokens to burn.
     */
    function burn(address account, uint256 amount) external;

    /**
     * @notice Get one basis point of the total supply.
     * @dev This function allows to calculate one basis point (1/10000) of the total supply of the token.
     * It can be used to calculate fees or other proportions relative to the total supply.
     * @return The one basis point of the total supply.
     */
    function oneBipOfTotalSupply() external view returns (uint256);

    /**
     * @notice Get the initial supply of tokens.
     * @dev This function allows to access the initial supply of tokens created upon contract deployment.
     * @return The initial supply of tokens.
     */
    function initialSupply() external returns (uint256);

    /**
     * @notice Get the maximum supply limit of tokens.
     * @dev This function allows to access the upper limit on the total supply of tokens that can be created.
     * @return The supply limit of tokens.
     */
    function supplyLimit() external returns (uint256);
}

pragma solidity >=0.8.0;

import {PRBTest} from "../lib/prb-test/src/PRBTest.sol";
import {console2} from "forge-std/console2.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Zi} from "../src/Zi.sol";
import {console} from "forge-std/console.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract Zi_Setup is PRBTest, StdCheats {
    Zi zi;
    ERC20Mock mock;
    address alice = address(0xAA); // alice is designated the owner of the pizza contract
    address bob = address(0xBB);
    address carol = address(0xCC);
    address dominic = address(0xDD);

    address minter_1 = address(1);
    address minter_2 = address(2);

    function setUp() public {
        uint256 _initialSupply = 1e5 * 1e18;
        uint256 _supplyLimit = 1e6 * 1e18;
        zi = new Zi(_initialSupply, _supplyLimit);
        mock = new ERC20Mock();
    }

    function basicTest() public {
        assertEq(zi.owner(), address(this));
    }
}

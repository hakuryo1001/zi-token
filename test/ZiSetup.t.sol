pragma solidity >=0.8.0;

import {PRBTest} from "../lib/prb-test/src/PRBTest.sol";
import {console2} from "forge-std/console2.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Zi} from "../src/Zi.sol";
import {console} from "forge-std/console.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract Zi_Setup is PRBTest, StdCheats {
    Zi zi;
    address alice = address(0xAA); // alice is designated the owner of the pizza contract
    address bob = address(0xBB);
    address carol = address(0xCC);
    address dominic = address(0xDD);

    function setUp() public {
        vm.prank(alice);
        zi = new Zi();
    }

    function basicTest() public {
        assertEq(zi.owner(), alice);
    }
}

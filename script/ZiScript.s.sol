// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;
import {BaseScript} from "./Base.s.sol";
import "forge-std/Script.sol";
import {Zi} from "../src/Zi.sol";

// contract ZiScript is Script {
//     function run() external {
//         uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
//         vm.startBroadcast(deployerPrivateKey);
//         Zi zi = new Zi();

//         vm.stopBroadcast();
//     }
// }

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract ZiScript is BaseScript {
    function run() public broadcaster returns (Zi zi) {
        zi = new Zi();
    }
}

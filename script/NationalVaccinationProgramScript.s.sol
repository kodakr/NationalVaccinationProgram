// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Factory} from "../src/Factory.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public returns (address factory){
        vm.startBroadcast();
        factory = address(new Factory());
        vm.stopBroadcast();
    }
}

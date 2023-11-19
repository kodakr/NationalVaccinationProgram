// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Factory} from "../src/Factory.sol";

contract NationalVaccinationProgramScript is Script {
    function setUp() public {}

    // function run() public returns (address factory){
    //     vm.startBroadcast();
    //     factory = address(new Factory());
    //     vm.stopBroadcast();
    // }

    //script\NationalVaccinationProgramScript.s.sol

    // 0x03905e60759b03979314f5a5bA788C93E20cdC8c
    // forge script script\NationalVaccinationProgramScript.s.sol:NationalVaccinationProgramScript --rpc-url $TORONET_RPC_URL --broadcast --verify -vvvv


    function run() external returns (address factory){
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        factory = address(new Factory());
        vm.stopBroadcast();
        console.log("addr=====",factory);
        
    }
}

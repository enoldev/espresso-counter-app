// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {CounterBidirectional} from "../src/CounterBidirectional.sol";

contract CounterScript is Script {
    CounterBidirectional public counter;

    function setUp() public {}

    function run() public {
        address mailbox = vm.envAddress("MAILBOX");

        vm.startBroadcast();

        counter = new CounterBidirectional(mailbox);

        vm.stopBroadcast();
    }
}

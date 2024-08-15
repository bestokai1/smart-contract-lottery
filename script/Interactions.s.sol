// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/Mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinator,,,,, uint256 deployerKey) = helperConfig.activeNetworkConfig();
        return createSubscription(vrfCoordinator, deployerKey);
    }

    function createSubscription(address vrfCoordinator, uint256 deployerKey) public returns (uint64){
        console.log("Creating subscription on chain ID: ", block.chainid);
        vm.startBroadcast(deployerKey);
        uint64 subscriptionID = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your sub ID is: ", subscriptionID, ". Please update subscriptionID in the HelperConfig.s.sol.");
        return subscriptionID;
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public{
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinator,, uint64 subscriptionID,, address linkToken, uint256 deployerKey) = helperConfig.activeNetworkConfig();
        return fundSubscription(vrfCoordinator, subscriptionID, linkToken, deployerKey);
    }

    function fundSubscription(address vrfCoordinator, uint64 subscriptionID, address linkToken, uint256 deployerKey) public{
        console.log("Funding subscription: ", subscriptionID);
        console.log("Using vrf co-ordinator: ", vrfCoordinator);
        console.log("On chain: ", block.chainid);

        if (block.chainid == 31337) {
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subscriptionID, FUND_AMOUNT);
            vm.stopBroadcast(); 
        } else {
            vm.startBroadcast(deployerKey);
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionID));
            vm.stopBroadcast(); 
        }
        
    }

    function run() external{
        return fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(address raffle, address vrfCoordinator, uint64 subscriptionID, uint256 deployerKey) public{
        console.log("Adding consumer contract: ", raffle);
        console.log("Using VRF Co-ordinator: ", vrfCoordinator);
        console.log("On chain ID: ", block.chainid);
        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subscriptionID, raffle);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address raffle) public{
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinator,, uint64 subscriptionID,,, uint256 deployerKey) = helperConfig.activeNetworkConfig();
        return addConsumer(raffle, vrfCoordinator, subscriptionID, deployerKey);
    }

    function run() external{
        address raffle = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(raffle);
    }
}
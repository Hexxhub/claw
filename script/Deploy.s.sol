// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {VoucherFactory} from "../src/VoucherFactory.sol";

contract DeployScript is Script {
    // Base Sepolia USDC (Circle's testnet USDC)
    address constant BASE_SEPOLIA_USDC = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
    
    // Base Mainnet USDC (for reference)
    address constant BASE_MAINNET_USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy to Base Sepolia
        VoucherFactory factory = new VoucherFactory(BASE_SEPOLIA_USDC);
        
        console2.log("VoucherFactory deployed to:", address(factory));
        console2.log("USDC address:", BASE_SEPOLIA_USDC);
        
        vm.stopBroadcast();
    }
}

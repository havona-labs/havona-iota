// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/lib/forge-std/src/Script.sol";
import "../src/ETRSeal.sol";

/**
 * @title DeployETRSeal
 * @dev Deployment script for ETRSeal (permissionless document attestation)
 *
 * Usage:
 *   forge script script/DeployETRSeal.s.sol:DeployETRSeal \
 *     --rpc-url https://json-rpc.evm.testnet.iotaledger.net \
 *     --private-key $PRIVATE_KEY \
 *     --broadcast --legacy -vvv
 */
contract DeployETRSeal is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        ETRSeal sealContract = new ETRSeal();

        vm.stopBroadcast();

        console.log("ETR_SEAL_ADDRESS:", address(sealContract));
    }
}

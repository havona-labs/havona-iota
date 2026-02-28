// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/lib/forge-std/src/Script.sol";
import "../src/IOTAIdentityAnchor.sol";

/**
 * @title DeployIOTAIdentityAnchor
 * @dev Deployment script for IOTAIdentityAnchor (IOTA Identity DID storage)
 *
 * Usage:
 *   forge script script/DeployIOTAIdentityAnchor.s.sol:DeployIOTAIdentityAnchor \
 *     --rpc-url https://json-rpc.evm.testnet.iotaledger.net \
 *     --private-key $PRIVATE_KEY \
 *     --broadcast --legacy -vvv
 */
contract DeployIOTAIdentityAnchor is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        IOTAIdentityAnchor anchorContract = new IOTAIdentityAnchor();

        vm.stopBroadcast();

        console.log("IOTA_IDENTITY_ANCHOR_ADDRESS:", address(anchorContract));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title IOTAIdentityAnchor
 * @notice Stores IOTA Identity DID references on EVM for bidirectional lookup
 * @dev On-chain half of the IOTA Identity integration. The off-chain WASM SDK
 *      resolves full DID documents from the IOTA L1 Tangle; this contract
 *      provides fast EVM-side mapping between DID strings and EVM addresses.
 *
 * Architecture:
 * - Havona server anchors DID references after IOTA Identity SDK verification
 * - Trade counterparties can verify DID ownership via view functions
 * - Bidirectional: DID string => EVM address, EVM address => DID string
 *
 * IOTA Identity DIDs follow the format: did:iota:<network>:<tag>
 *
 * @custom:security-contact security@havona.io
 * @custom:version 1.0.0
 */
contract IOTAIdentityAnchor is Ownable {
    // ============ Storage ============

    /// @notice DID string => EVM address
    mapping(string => address) public didToAddress;

    /// @notice EVM address => DID string
    mapping(address => string) public addressToDid;

    /// @notice Total anchored DIDs
    uint256 public anchorCount;

    // ============ Events ============

    /// @notice Emitted when a DID is anchored to an EVM address
    event DIDAnchored(string indexed didHash, string did, address indexed evmAddress, uint256 timestamp);

    /// @notice Emitted when a DID anchor is removed
    event DIDRemoved(string indexed didHash, string did, address indexed evmAddress, uint256 timestamp);

    // ============ Constructor ============

    constructor() Ownable(msg.sender) {}

    // ============ Write Functions ============

    /**
     * @notice Anchor an IOTA Identity DID to an EVM address
     * @param did The full DID string (e.g. "did:iota:smr:0xabc...")
     * @param evmAddress The EVM address to associate
     * @dev Only callable by Havona server (owner). Overwrites existing anchors.
     */
    function anchorDID(string calldata did, address evmAddress) external onlyOwner {
        require(bytes(did).length > 0, "Empty DID");
        require(evmAddress != address(0), "Zero address");

        // Track whether this is a net-new anchor
        bool isNewAnchor = true;

        // Clear old mapping if this address already had a DID
        string memory oldDid = addressToDid[evmAddress];
        if (bytes(oldDid).length > 0) {
            delete didToAddress[oldDid];
            // Address already counted, not a new anchor
            isNewAnchor = false;
        }

        // Clear old mapping if this DID was already anchored elsewhere
        address oldAddress = didToAddress[did];
        if (oldAddress != address(0)) {
            delete addressToDid[oldAddress];
            if (oldAddress != evmAddress) {
                // DID moved from one address to another: old address loses its anchor
                // but new address gains one. If new address didn't have one, net zero
                // change is handled by isNewAnchor. If both had anchors, net -1.
                if (!isNewAnchor) {
                    // Both address and DID were already anchored (to different things)
                    // After this operation, one fewer unique anchor exists
                    unchecked {
                        anchorCount--;
                    }
                }
                isNewAnchor = false;
            } else {
                // DID re-anchored to the same address (no-op for count)
                isNewAnchor = false;
            }
        }

        if (isNewAnchor) {
            unchecked {
                anchorCount++;
            }
        }

        didToAddress[did] = evmAddress;
        addressToDid[evmAddress] = did;

        emit DIDAnchored(did, did, evmAddress, block.timestamp);
    }

    /**
     * @notice Remove a DID anchor
     * @param did The DID string to remove
     * @dev Only callable by Havona server (owner)
     */
    function removeDID(string calldata did) external onlyOwner {
        address evmAddress = didToAddress[did];
        require(evmAddress != address(0), "DID not anchored");

        delete didToAddress[did];
        delete addressToDid[evmAddress];

        unchecked {
            anchorCount--;
        }

        emit DIDRemoved(did, did, evmAddress, block.timestamp);
    }

    // ============ View Functions ============

    /**
     * @notice Resolve a DID to its EVM address
     * @param did The DID string to look up
     * @return The associated EVM address (zero if not anchored)
     */
    function resolve(string calldata did) external view returns (address) {
        return didToAddress[did];
    }

    /**
     * @notice Reverse-resolve an EVM address to its DID
     * @param evmAddress The address to look up
     * @return The associated DID string (empty if not anchored)
     */
    function reverseLookup(address evmAddress) external view returns (string memory) {
        return addressToDid[evmAddress];
    }

    /**
     * @notice Check if a DID is anchored
     * @param did The DID string to check
     * @return True if the DID has an active anchor
     */
    function isAnchored(string calldata did) external view returns (bool) {
        return didToAddress[did] != address(0);
    }

    /**
     * @notice Get contract version
     */
    function version() external pure returns (string memory) {
        return "1.0.0";
    }
}

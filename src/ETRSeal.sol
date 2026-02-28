// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ETRSeal
 * @notice Permissionless document attestation for trade documents on IOTA EVM
 * @dev Public good: any party can hash+timestamp a trade document.
 *      Verification is free (view function). No admin, no ownership.
 *
 * Use cases:
 * - Bill of Lading attestation before transfer
 * - Letter of Credit document sealing
 * - Inspection certificate timestamping
 * - Any trade document that needs tamper-evident proof of existence
 *
 * @custom:security-contact security@havona.io
 * @custom:version 1.0.0
 */
contract ETRSeal {
    // ============ Storage ============

    struct Seal {
        address sealer;    // Who sealed the document
        uint256 timestamp; // When it was sealed
        uint256 blockNum;  // Block number for extra anchoring
    }

    /// @notice Document hash => seal record
    mapping(bytes32 => Seal) public seals;

    /// @notice Total number of seals created
    uint256 public sealCount;

    // ============ Events ============

    /// @notice Emitted when a document is sealed
    event DocumentSealed(
        bytes32 indexed documentHash,
        address indexed sealer,
        uint256 timestamp,
        uint256 blockNumber
    );

    /// @notice Emitted during batch sealing (one per document)
    event BatchSealed(
        bytes32 indexed documentHash,
        address indexed sealer,
        uint256 batchSize
    );

    // ============ Write Functions ============

    /**
     * @notice Seal a single document hash
     * @param documentHash keccak256 hash of the document content
     * @dev Reverts if the document has already been sealed
     */
    function seal(bytes32 documentHash) external {
        require(documentHash != bytes32(0), "Empty hash");
        require(seals[documentHash].timestamp == 0, "Already sealed");

        seals[documentHash] = Seal({
            sealer: msg.sender,
            timestamp: block.timestamp,
            blockNum: block.number
        });

        unchecked { sealCount++; }

        emit DocumentSealed(documentHash, msg.sender, block.timestamp, block.number);
    }

    /**
     * @notice Seal multiple document hashes in one transaction
     * @param documentHashes Array of keccak256 hashes to seal
     * @dev Reverts if any document has already been sealed.
     *      Gas efficient for bulk attestation (e.g. full shipment docs).
     */
    function sealBatch(bytes32[] calldata documentHashes) external {
        uint256 len = documentHashes.length;
        require(len > 0, "Empty batch");
        require(len <= 50, "Batch too large");

        for (uint256 i = 0; i < len;) {
            bytes32 docHash = documentHashes[i];
            require(docHash != bytes32(0), "Empty hash in batch");
            require(seals[docHash].timestamp == 0, "Already sealed");

            seals[docHash] = Seal({
                sealer: msg.sender,
                timestamp: block.timestamp,
                blockNum: block.number
            });

            emit BatchSealed(docHash, msg.sender, len);

            unchecked { i++; }
        }

        unchecked { sealCount += len; }
    }

    // ============ View Functions ============

    /**
     * @notice Check if a document has been sealed
     * @param documentHash The document hash to check
     * @return True if the document has been sealed
     */
    function isSealed(bytes32 documentHash) external view returns (bool) {
        return seals[documentHash].timestamp != 0;
    }

    /**
     * @notice Get full seal details for a document
     * @param documentHash The document hash to look up
     * @return sealer Address that sealed the document
     * @return timestamp When the document was sealed (0 if not sealed)
     * @return blockNum Block number when sealed
     */
    function verifySeal(bytes32 documentHash)
        external
        view
        returns (address sealer, uint256 timestamp, uint256 blockNum)
    {
        Seal storage s = seals[documentHash];
        return (s.sealer, s.timestamp, s.blockNum);
    }

    /**
     * @notice Get contract version
     */
    function version() external pure returns (string memory) {
        return "1.0.0";
    }
}

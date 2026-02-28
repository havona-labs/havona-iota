// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/lib/forge-std/src/Test.sol";
import "../src/ETRSeal.sol";

contract ETRSealTest is Test {
    ETRSeal internal sealContract;

    address internal alice;
    address internal bob;

    bytes32 internal constant DOC_HASH_1 = keccak256("bill-of-lading-001");
    bytes32 internal constant DOC_HASH_2 = keccak256("letter-of-credit-002");
    bytes32 internal constant DOC_HASH_3 = keccak256("inspection-cert-003");

    event DocumentSealed(
        bytes32 indexed documentHash,
        address indexed sealer,
        uint256 timestamp,
        uint256 blockNumber
    );

    event BatchSealed(
        bytes32 indexed documentHash,
        address indexed sealer,
        uint256 batchSize
    );

    function setUp() public {
        alice = address(0x1);
        bob = address(0x2);

        sealContract = new ETRSeal();
    }

    // ============ Seal Tests ============

    function testSealDocument() public {
        vm.prank(alice);

        vm.expectEmit(true, true, true, true);
        emit DocumentSealed(DOC_HASH_1, alice, block.timestamp, block.number);

        sealContract.seal(DOC_HASH_1);

        assertTrue(sealContract.isSealed(DOC_HASH_1));
        assertEq(sealContract.sealCount(), 1);
    }

    function testSealRecordDetails() public {
        vm.prank(alice);
        sealContract.seal(DOC_HASH_1);

        (address sealer, uint256 timestamp, uint256 blockNum) = sealContract.verifySeal(DOC_HASH_1);
        assertEq(sealer, alice);
        assertEq(timestamp, block.timestamp);
        assertEq(blockNum, block.number);
    }

    function testAnyoneCanSeal() public {
        vm.prank(alice);
        sealContract.seal(DOC_HASH_1);

        vm.prank(bob);
        sealContract.seal(DOC_HASH_2);

        assertTrue(sealContract.isSealed(DOC_HASH_1));
        assertTrue(sealContract.isSealed(DOC_HASH_2));
        assertEq(sealContract.sealCount(), 2);
    }

    function testCannotSealTwice() public {
        vm.prank(alice);
        sealContract.seal(DOC_HASH_1);

        vm.prank(bob);
        vm.expectRevert("Already sealed");
        sealContract.seal(DOC_HASH_1);
    }

    function testCannotSealEmptyHash() public {
        vm.expectRevert("Empty hash");
        sealContract.seal(bytes32(0));
    }

    // ============ Batch Seal Tests ============

    function testSealBatch() public {
        bytes32[] memory hashes = new bytes32[](3);
        hashes[0] = DOC_HASH_1;
        hashes[1] = DOC_HASH_2;
        hashes[2] = DOC_HASH_3;

        vm.prank(alice);
        sealContract.sealBatch(hashes);

        assertTrue(sealContract.isSealed(DOC_HASH_1));
        assertTrue(sealContract.isSealed(DOC_HASH_2));
        assertTrue(sealContract.isSealed(DOC_HASH_3));
        assertEq(sealContract.sealCount(), 3);
    }

    function testBatchEmitsEvents() public {
        bytes32[] memory hashes = new bytes32[](2);
        hashes[0] = DOC_HASH_1;
        hashes[1] = DOC_HASH_2;

        vm.prank(alice);

        vm.expectEmit(true, true, true, true);
        emit BatchSealed(DOC_HASH_1, alice, 2);
        vm.expectEmit(true, true, true, true);
        emit BatchSealed(DOC_HASH_2, alice, 2);

        sealContract.sealBatch(hashes);
    }

    function testCannotBatchSealEmpty() public {
        bytes32[] memory hashes = new bytes32[](0);

        vm.expectRevert("Empty batch");
        sealContract.sealBatch(hashes);
    }

    function testCannotBatchSealTooLarge() public {
        bytes32[] memory hashes = new bytes32[](51);
        for (uint256 i = 0; i < 51; i++) {
            hashes[i] = keccak256(abi.encodePacked("doc-", i));
        }

        vm.expectRevert("Batch too large");
        sealContract.sealBatch(hashes);
    }

    function testCannotBatchSealDuplicate() public {
        bytes32[] memory hashes = new bytes32[](2);
        hashes[0] = DOC_HASH_1;
        hashes[1] = DOC_HASH_1; // duplicate

        vm.expectRevert("Already sealed");
        sealContract.sealBatch(hashes);
    }

    function testCannotBatchSealAlreadySealed() public {
        sealContract.seal(DOC_HASH_1);

        bytes32[] memory hashes = new bytes32[](2);
        hashes[0] = DOC_HASH_2;
        hashes[1] = DOC_HASH_1; // already sealed

        vm.expectRevert("Already sealed");
        sealContract.sealBatch(hashes);
    }

    function testCannotBatchSealEmptyHash() public {
        bytes32[] memory hashes = new bytes32[](2);
        hashes[0] = DOC_HASH_1;
        hashes[1] = bytes32(0);

        vm.expectRevert("Empty hash in batch");
        sealContract.sealBatch(hashes);
    }

    // ============ View Function Tests ============

    function testIsSealedFalseForUnsealed() public {
        assertFalse(sealContract.isSealed(DOC_HASH_1));
    }

    function testVerifySealReturnsZerosForUnsealed() public {
        (address sealer, uint256 timestamp, uint256 blockNum) = sealContract.verifySeal(DOC_HASH_1);
        assertEq(sealer, address(0));
        assertEq(timestamp, 0);
        assertEq(blockNum, 0);
    }

    function testSealCountStartsAtZero() public {
        assertEq(sealContract.sealCount(), 0);
    }

    function testVersion() public {
        assertEq(sealContract.version(), "1.0.0");
    }

    // ============ Gas Tests ============

    function testGasSealSingle() public {
        uint256 gasBefore = gasleft();
        sealContract.seal(DOC_HASH_1);
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Gas used for seal()", gasUsed);
        assertTrue(gasUsed < 120000);
    }

    function testGasSealBatchOf5() public {
        bytes32[] memory hashes = new bytes32[](5);
        for (uint256 i = 0; i < 5; i++) {
            hashes[i] = keccak256(abi.encodePacked("batch-doc-", i));
        }

        uint256 gasBefore = gasleft();
        sealContract.sealBatch(hashes);
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Gas used for sealBatch(5)", gasUsed);
        assertTrue(gasUsed < 400000);
    }

    function testGasVerifySeal() public {
        sealContract.seal(DOC_HASH_1);

        uint256 gasBefore = gasleft();
        sealContract.verifySeal(DOC_HASH_1);
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Gas used for verifySeal()", gasUsed);
        assertTrue(gasUsed < 10000);
    }
}

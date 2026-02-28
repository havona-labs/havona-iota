// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/lib/forge-std/src/Test.sol";
import "../src/IOTAIdentityAnchor.sol";

contract IOTAIdentityAnchorTest is Test {
    IOTAIdentityAnchor internal anchor;

    address internal owner;
    address internal alice;
    address internal bob;
    address internal unauthorized;

    string internal constant DID_1 = "did:iota:smr:0xabc123def456";
    string internal constant DID_2 = "did:iota:smr:0x789ghi012jkl";
    string internal constant DID_3 = "did:iota:smr:0xmno345pqr678";

    event DIDAnchored(
        string indexed didHash,
        string did,
        address indexed evmAddress,
        uint256 timestamp
    );

    event DIDRemoved(
        string indexed didHash,
        string did,
        address indexed evmAddress,
        uint256 timestamp
    );

    function setUp() public {
        owner = address(this);
        alice = address(0x1);
        bob = address(0x2);
        unauthorized = address(0x999);

        anchor = new IOTAIdentityAnchor();
    }

    // ============ Anchor Tests ============

    function testAnchorDID() public {
        anchor.anchorDID(DID_1, alice);

        assertEq(anchor.didToAddress(DID_1), alice);
        assertEq(anchor.addressToDid(alice), DID_1);
        assertTrue(anchor.isAnchored(DID_1));
        assertEq(anchor.anchorCount(), 1);
    }

    function testAnchorEmitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit DIDAnchored(DID_1, DID_1, alice, block.timestamp);

        anchor.anchorDID(DID_1, alice);
    }

    function testAnchorMultipleDIDs() public {
        anchor.anchorDID(DID_1, alice);
        anchor.anchorDID(DID_2, bob);

        assertEq(anchor.resolve(DID_1), alice);
        assertEq(anchor.resolve(DID_2), bob);
        assertEq(anchor.anchorCount(), 2);
    }

    function testCannotAnchorEmptyDID() public {
        vm.expectRevert("Empty DID");
        anchor.anchorDID("", alice);
    }

    function testCannotAnchorZeroAddress() public {
        vm.expectRevert("Zero address");
        anchor.anchorDID(DID_1, address(0));
    }

    function testOnlyOwnerCanAnchor() public {
        vm.prank(unauthorized);
        vm.expectRevert();
        anchor.anchorDID(DID_1, alice);
    }

    // ============ Overwrite Tests ============

    function testOverwriteDIDForSameAddress() public {
        anchor.anchorDID(DID_1, alice);
        anchor.anchorDID(DID_2, alice);

        // Old DID should be cleared
        assertEq(anchor.resolve(DID_1), address(0));
        assertFalse(anchor.isAnchored(DID_1));

        // New DID should be active
        assertEq(anchor.resolve(DID_2), alice);
        assertEq(anchor.reverseLookup(alice), DID_2);
        assertTrue(anchor.isAnchored(DID_2));

        // Count should not double (overwrite, not new)
        assertEq(anchor.anchorCount(), 1);
    }

    function testOverwriteAddressForSameDID() public {
        anchor.anchorDID(DID_1, alice);
        anchor.anchorDID(DID_1, bob);

        // Alice should no longer have a DID
        assertEq(anchor.reverseLookup(alice), "");

        // Bob should now own the DID
        assertEq(anchor.resolve(DID_1), bob);
        assertEq(anchor.reverseLookup(bob), DID_1);

        // Count should stay at 1 (overwrite)
        assertEq(anchor.anchorCount(), 1);
    }

    // ============ Remove Tests ============

    function testRemoveDID() public {
        anchor.anchorDID(DID_1, alice);
        anchor.removeDID(DID_1);

        assertEq(anchor.resolve(DID_1), address(0));
        assertEq(anchor.reverseLookup(alice), "");
        assertFalse(anchor.isAnchored(DID_1));
        assertEq(anchor.anchorCount(), 0);
    }

    function testRemoveEmitsEvent() public {
        anchor.anchorDID(DID_1, alice);

        vm.expectEmit(true, true, true, true);
        emit DIDRemoved(DID_1, DID_1, alice, block.timestamp);

        anchor.removeDID(DID_1);
    }

    function testCannotRemoveNonExistent() public {
        vm.expectRevert("DID not anchored");
        anchor.removeDID(DID_1);
    }

    function testOnlyOwnerCanRemove() public {
        anchor.anchorDID(DID_1, alice);

        vm.prank(unauthorized);
        vm.expectRevert();
        anchor.removeDID(DID_1);
    }

    function testCanReanchorAfterRemoval() public {
        anchor.anchorDID(DID_1, alice);
        anchor.removeDID(DID_1);

        anchor.anchorDID(DID_1, bob);
        assertEq(anchor.resolve(DID_1), bob);
        assertEq(anchor.anchorCount(), 1);
    }

    // ============ View Function Tests ============

    function testResolveReturnsZeroForUnanchored() public {
        assertEq(anchor.resolve(DID_1), address(0));
    }

    function testReverseLookupReturnsEmptyForUnanchored() public {
        assertEq(anchor.reverseLookup(alice), "");
    }

    function testIsAnchoredFalseForUnanchored() public {
        assertFalse(anchor.isAnchored(DID_1));
    }

    function testVersion() public {
        assertEq(anchor.version(), "1.0.0");
    }

    // ============ Gas Tests ============

    function testGasAnchorDID() public {
        uint256 gasBefore = gasleft();
        anchor.anchorDID(DID_1, alice);
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Gas used for anchorDID()", gasUsed);
        assertTrue(gasUsed < 150000);
    }

    function testGasRemoveDID() public {
        anchor.anchorDID(DID_1, alice);

        uint256 gasBefore = gasleft();
        anchor.removeDID(DID_1);
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Gas used for removeDID()", gasUsed);
        assertTrue(gasUsed < 50000);
    }

    function testGasResolve() public {
        anchor.anchorDID(DID_1, alice);

        uint256 gasBefore = gasleft();
        anchor.resolve(DID_1);
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Gas used for resolve()", gasUsed);
        assertTrue(gasUsed < 10000);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { ByUsPassport } from "../src/ByUsPassport.sol";
import { ByUsStamp } from "../src/ByUsStamp.sol";

contract ByUsCredentialsTest is Test {
    address internal admin = makeAddr("admin");
    address internal relayer = makeAddr("relayer");
    address internal fan = makeAddr("fan");
    address internal stranger = makeAddr("stranger");

    ByUsPassport internal passport;
    ByUsStamp internal stamp;

    function setUp() public virtual {
        passport = new ByUsPassport(admin, relayer);
        stamp = new ByUsStamp(admin, relayer);
    }

    function testRolesAreSeparated() public view {
        assertTrue(passport.hasRole(passport.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(passport.hasRole(passport.PAUSER_ROLE(), admin));
        assertTrue(passport.hasRole(passport.MINTER_ROLE(), relayer));
        assertFalse(passport.hasRole(passport.DEFAULT_ADMIN_ROLE(), relayer));
        assertTrue(stamp.hasRole(stamp.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(stamp.hasRole(stamp.PAUSER_ROLE(), admin));
        assertTrue(stamp.hasRole(stamp.MINTER_ROLE(), relayer));
        assertFalse(stamp.hasRole(stamp.DEFAULT_ADMIN_ROLE(), relayer));
    }

    function testPassportMintIsUniqueAndMetadataIsFixed() public {
        bytes32 passportId = keccak256("passport-1");
        vm.prank(relayer);
        uint256 tokenId = passport.mint(fan, passportId, "ipfs://passport-1");

        assertEq(tokenId, 1);
        assertEq(passport.ownerOf(tokenId), fan);
        assertEq(passport.tokenURI(tokenId), "ipfs://passport-1");
        assertEq(passport.tokenByPassportId(passportId), tokenId);

        vm.prank(relayer);
        vm.expectRevert(
            abi.encodeWithSelector(ByUsPassport.PassportAlreadyMinted.selector, passportId)
        );
        passport.mint(fan, passportId, "ipfs://duplicate");
    }

    function testPassportTransferAndApprovalsAreBlocked() public {
        vm.prank(relayer);
        uint256 tokenId = passport.mint(fan, keccak256("passport-2"), "ipfs://passport-2");

        vm.startPrank(fan);
        vm.expectRevert(ByUsPassport.Soulbound.selector);
        passport.transferFrom(fan, stranger, tokenId);

        vm.expectRevert(ByUsPassport.Soulbound.selector);
        passport.approve(stranger, tokenId);

        vm.expectRevert(ByUsPassport.Soulbound.selector);
        passport.setApprovalForAll(stranger, true);
        vm.stopPrank();
    }

    function testStampMintIsUniqueAndTransfersAreBlocked() public {
        bytes32 issuanceId = keccak256("attendance-1");
        vm.prank(relayer);
        uint256 tokenId = stamp.mint(fan, issuanceId, "ipfs://attendance-1");

        assertEq(tokenId, 1);
        assertEq(stamp.balanceOf(fan, tokenId), 1);
        assertEq(stamp.uri(tokenId), "ipfs://attendance-1");
        assertEq(stamp.tokenByIssuanceId(issuanceId), tokenId);

        vm.startPrank(fan);
        vm.expectRevert(ByUsStamp.Soulbound.selector);
        stamp.safeTransferFrom(fan, stranger, tokenId, 1, "");

        vm.expectRevert(ByUsStamp.Soulbound.selector);
        stamp.safeBatchTransferFrom(fan, stranger, _one(tokenId), _one(1), "");

        vm.expectRevert(ByUsStamp.Soulbound.selector);
        stamp.setApprovalForAll(stranger, true);
        vm.stopPrank();

        vm.prank(relayer);
        vm.expectRevert(abi.encodeWithSelector(ByUsStamp.StampAlreadyMinted.selector, issuanceId));
        stamp.mint(fan, issuanceId, "ipfs://duplicate");
    }

    function testZeroIdentifiersRevert() public {
        vm.prank(relayer);
        vm.expectRevert(ByUsPassport.InvalidPassportId.selector);
        passport.mint(fan, bytes32(0), "ipfs://passport");

        vm.prank(relayer);
        vm.expectRevert(ByUsStamp.InvalidIssuanceId.selector);
        stamp.mint(fan, bytes32(0), "ipfs://stamp");
    }

    function testZeroRecipientsRevert() public {
        vm.prank(relayer);
        vm.expectRevert();
        passport.mint(address(0), keccak256("passport-zero-recipient"), "ipfs://passport");

        vm.prank(relayer);
        vm.expectRevert();
        stamp.mint(address(0), keccak256("stamp-zero-recipient"), "ipfs://stamp");
    }

    function testUnauthorizedMintingAndPausingRevert() public {
        vm.prank(stranger);
        vm.expectRevert();
        passport.mint(fan, keccak256("passport-3"), "ipfs://passport-3");

        vm.prank(stranger);
        vm.expectRevert();
        stamp.mint(fan, keccak256("stamp-3"), "ipfs://stamp-3");

        vm.prank(stranger);
        vm.expectRevert();
        passport.pause();

        vm.prank(stranger);
        vm.expectRevert();
        stamp.pause();
    }

    function testPauseUnpauseAndMintRecovery() public {
        vm.prank(admin);
        passport.pause();
        vm.prank(admin);
        stamp.pause();

        vm.prank(relayer);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        passport.mint(fan, keccak256("passport-4"), "ipfs://passport-4");

        vm.prank(relayer);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        stamp.mint(fan, keccak256("stamp-4"), "ipfs://stamp-4");

        vm.prank(admin);
        passport.unpause();
        vm.prank(admin);
        stamp.unpause();

        vm.prank(relayer);
        assertEq(passport.mint(fan, keccak256("passport-4"), "ipfs://passport-4"), 1);

        vm.prank(relayer);
        assertEq(stamp.mint(fan, keccak256("stamp-4"), "ipfs://stamp-4"), 1);
    }

    function testMintEvents() public {
        bytes32 passportId = keccak256("passport-event");
        vm.expectEmit(true, true, true, true, address(passport));
        emit ByUsPassport.PassportMinted(passportId, 1, fan, "ipfs://passport-event");
        vm.prank(relayer);
        passport.mint(fan, passportId, "ipfs://passport-event");

        bytes32 issuanceId = keccak256("stamp-event");
        vm.expectEmit(true, true, true, true, address(stamp));
        emit ByUsStamp.StampMinted(issuanceId, 1, fan, "ipfs://stamp-event");
        vm.prank(relayer);
        stamp.mint(fan, issuanceId, "ipfs://stamp-event");
    }

    function testFuzzPassportIdsRemainUnique(bytes32 firstId, bytes32 secondId) public {
        vm.assume(firstId != bytes32(0));
        vm.assume(secondId != bytes32(0));
        vm.assume(firstId != secondId);

        vm.prank(relayer);
        uint256 firstTokenId = passport.mint(fan, firstId, "ipfs://first");
        vm.prank(relayer);
        uint256 secondTokenId = passport.mint(fan, secondId, "ipfs://second");

        assertEq(firstTokenId, 1);
        assertEq(secondTokenId, 2);
        assertEq(passport.tokenByPassportId(firstId), 1);
        assertEq(passport.tokenByPassportId(secondId), 2);
    }

    function _one(uint256 value) private pure returns (uint256[] memory values) {
        values = new uint256[](1);
        values[0] = value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {VoucherFactory} from "../src/VoucherFactory.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock USDC for testing
contract MockUSDC is ERC20 {
    constructor() ERC20("USD Coin", "USDC") {
        _mint(msg.sender, 1_000_000 * 1e6); // 1M USDC
    }
    
    function decimals() public pure override returns (uint8) {
        return 6;
    }
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract VoucherFactoryTest is Test {
    VoucherFactory public factory;
    MockUSDC public usdc;
    
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public agent = makeAddr("agent");
    
    function setUp() public {
        usdc = new MockUSDC();
        factory = new VoucherFactory(address(usdc));
        
        // Give alice some USDC
        usdc.mint(alice, 10_000 * 1e6);
        
        // Alice approves factory
        vm.prank(alice);
        usdc.approve(address(factory), type(uint256).max);
    }
    
    function test_MintVoucher() public {
        vm.prank(alice);
        uint256 tokenId = factory.mint(agent, 100 * 1e6, 0);
        
        assertEq(tokenId, 1);
        assertEq(factory.ownerOf(tokenId), agent);
        assertEq(factory.totalUSDCHeld(), 100 * 1e6);
        
        (uint256 maxSpend, uint256 spent, uint256 expiry, bool burned) = factory.getVoucher(tokenId);
        assertEq(maxSpend, 100 * 1e6);
        assertEq(spent, 0);
        assertEq(expiry, 0);
        assertFalse(burned);
    }
    
    function test_SpendFromVoucher() public {
        // Alice creates voucher for agent
        vm.prank(alice);
        uint256 tokenId = factory.mint(agent, 100 * 1e6, 0);
        
        // Agent spends 30 USDC
        vm.prank(agent);
        factory.spend(tokenId, bob, 30 * 1e6);
        
        assertEq(usdc.balanceOf(bob), 30 * 1e6);
        assertEq(factory.getRemaining(tokenId), 70 * 1e6);
        
        (,uint256 spent,,) = factory.getVoucher(tokenId);
        assertEq(spent, 30 * 1e6);
    }
    
    function test_CannotExceedSpendLimit() public {
        vm.prank(alice);
        uint256 tokenId = factory.mint(agent, 100 * 1e6, 0);
        
        vm.prank(agent);
        vm.expectRevert(VoucherFactory.SpendLimitExceeded.selector);
        factory.spend(tokenId, bob, 101 * 1e6);
    }
    
    function test_BurnAndReturnRemaining() public {
        vm.prank(alice);
        uint256 tokenId = factory.mint(agent, 100 * 1e6, 0);
        
        // Agent spends 30
        vm.prank(agent);
        factory.spend(tokenId, bob, 30 * 1e6);
        
        uint256 aliceBalanceBefore = usdc.balanceOf(alice);
        
        // Agent burns and returns remaining to alice
        vm.prank(agent);
        factory.burn(tokenId, alice);
        
        // Alice should have received 70 USDC back
        assertEq(usdc.balanceOf(alice), aliceBalanceBefore + 70 * 1e6);
        
        // Voucher should no longer exist
        vm.expectRevert();
        factory.ownerOf(tokenId);
    }
    
    function test_ExpiredVoucher() public {
        uint256 expiry = block.timestamp + 1 hours;
        
        vm.prank(alice);
        uint256 tokenId = factory.mint(agent, 100 * 1e6, expiry);
        
        // Should work before expiry
        vm.prank(agent);
        factory.spend(tokenId, bob, 10 * 1e6);
        
        // Warp past expiry
        vm.warp(expiry + 1);
        
        // Should fail after expiry
        vm.prank(agent);
        vm.expectRevert(VoucherFactory.VoucherExpired.selector);
        factory.spend(tokenId, bob, 10 * 1e6);
    }
    
    function test_OnlyOwnerCanSpend() public {
        vm.prank(alice);
        uint256 tokenId = factory.mint(agent, 100 * 1e6, 0);
        
        // Bob cannot spend from agent's voucher
        vm.prank(bob);
        vm.expectRevert(VoucherFactory.NotVoucherOwner.selector);
        factory.spend(tokenId, bob, 10 * 1e6);
    }
    
    function test_TransferVoucher() public {
        vm.prank(alice);
        uint256 tokenId = factory.mint(agent, 100 * 1e6, 0);
        
        // Agent transfers to bob
        vm.prank(agent);
        factory.transferFrom(agent, bob, tokenId);
        
        assertEq(factory.ownerOf(tokenId), bob);
        
        // Now bob can spend
        vm.prank(bob);
        factory.spend(tokenId, alice, 50 * 1e6);
        
        assertEq(usdc.balanceOf(alice), 10_000 * 1e6 - 100 * 1e6 + 50 * 1e6);
    }
    
    function test_MultipleSpendsUntilLimit() public {
        vm.prank(alice);
        uint256 tokenId = factory.mint(agent, 100 * 1e6, 0);
        
        // Multiple smaller spends
        vm.startPrank(agent);
        factory.spend(tokenId, bob, 30 * 1e6);
        factory.spend(tokenId, bob, 30 * 1e6);
        factory.spend(tokenId, bob, 30 * 1e6);
        
        // Should fail at limit
        vm.expectRevert(VoucherFactory.SpendLimitExceeded.selector);
        factory.spend(tokenId, bob, 11 * 1e6);
        
        // But exactly remaining should work
        factory.spend(tokenId, bob, 10 * 1e6);
        vm.stopPrank();
        
        assertEq(factory.getRemaining(tokenId), 0);
    }
    
    function test_TokenURI() public {
        vm.prank(alice);
        uint256 tokenId = factory.mint(agent, 100 * 1e6, 0);
        
        string memory uri = factory.tokenURI(tokenId);
        console2.log("Token URI:", uri);
        
        // Just verify it doesn't revert and returns something
        assertTrue(bytes(uri).length > 0);
    }
    
    function test_IsValidVoucher() public {
        vm.prank(alice);
        uint256 tokenId = factory.mint(agent, 100 * 1e6, block.timestamp + 1 hours);
        
        assertTrue(factory.isValidVoucher(tokenId));
        
        // Warp past expiry
        vm.warp(block.timestamp + 2 hours);
        assertFalse(factory.isValidVoucher(tokenId));
    }
}

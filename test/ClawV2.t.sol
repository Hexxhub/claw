// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ClawV2} from "../src/ClawV2.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract ClawV2Test is Test {
    ClawV2 public claw;
    MockERC20 public usdc;
    
    address public funder = makeAddr("funder");
    address public agent = makeAddr("agent");
    address public merchant = makeAddr("merchant");
    
    function setUp() public {
        usdc = new MockERC20("USDC", "USDC", 6);
        claw = new ClawV2(address(usdc));
        
        // Fund the funder
        usdc.mint(funder, 1000e6);
    }
    
    function test_CreateClaw() public {
        vm.startPrank(funder);
        usdc.approve(address(claw), 100e6);
        
        uint256 tokenId = claw.create(agent, 100e6, 0);
        
        assertEq(claw.ownerOf(tokenId), agent);
        assertEq(claw.getRemaining(tokenId), 100e6);
        vm.stopPrank();
    }
    
    function test_SpendFromClaw() public {
        // Setup: create claw
        vm.startPrank(funder);
        usdc.approve(address(claw), 100e6);
        uint256 tokenId = claw.create(agent, 100e6, 0);
        vm.stopPrank();
        
        // Agent spends
        vm.startPrank(agent);
        claw.spend(tokenId, merchant, 30e6);
        vm.stopPrank();
        
        // Verify
        assertEq(usdc.balanceOf(merchant), 30e6);
        assertEq(usdc.balanceOf(funder), 970e6); // 1000 - 30
        assertEq(claw.getRemaining(tokenId), 70e6);
    }
    
    function test_FunderCanRevoke() public {
        vm.startPrank(funder);
        usdc.approve(address(claw), 100e6);
        uint256 tokenId = claw.create(agent, 100e6, 0);
        
        // Revoke
        claw.revoke(tokenId);
        vm.stopPrank();
        
        // Agent can't spend
        vm.startPrank(agent);
        vm.expectRevert(ClawV2.ClawIsRevoked.selector);
        claw.spend(tokenId, merchant, 10e6);
        vm.stopPrank();
    }
    
    function test_FundsStayInFunderWallet() public {
        vm.startPrank(funder);
        usdc.approve(address(claw), 100e6);
        uint256 tokenId = claw.create(agent, 100e6, 0);
        vm.stopPrank();
        
        // Funds still in funder's wallet, NOT in claw contract
        assertEq(usdc.balanceOf(funder), 1000e6);
        assertEq(usdc.balanceOf(address(claw)), 0);
        
        // Agent spends, funds pulled directly from funder
        vm.prank(agent);
        claw.spend(tokenId, merchant, 25e6);
        
        assertEq(usdc.balanceOf(funder), 975e6);
        assertEq(usdc.balanceOf(address(claw)), 0); // Still 0!
    }
    
    function test_FunderCanReduceAllowanceToLimit() public {
        vm.startPrank(funder);
        usdc.approve(address(claw), 100e6);
        uint256 tokenId = claw.create(agent, 100e6, 0);
        
        // Funder reduces allowance to 50
        usdc.approve(address(claw), 50e6);
        vm.stopPrank();
        
        // Remaining is now limited by allowance
        assertEq(claw.getRemaining(tokenId), 50e6);
        
        // Agent can only spend up to allowance
        vm.startPrank(agent);
        claw.spend(tokenId, merchant, 50e6);
        
        // This should fail - no more allowance
        vm.expectRevert(); // SafeERC20 will revert
        claw.spend(tokenId, merchant, 10e6);
        vm.stopPrank();
    }
    
    function test_CannotSpendMoreThanLimit() public {
        vm.startPrank(funder);
        usdc.approve(address(claw), 100e6);
        uint256 tokenId = claw.create(agent, 100e6, 0);
        vm.stopPrank();
        
        vm.startPrank(agent);
        vm.expectRevert(ClawV2.SpendLimitExceeded.selector);
        claw.spend(tokenId, merchant, 101e6);
        vm.stopPrank();
    }
    
    function test_OnlyOwnerCanSpend() public {
        vm.startPrank(funder);
        usdc.approve(address(claw), 100e6);
        uint256 tokenId = claw.create(agent, 100e6, 0);
        vm.stopPrank();
        
        // Random person can't spend
        address rando = makeAddr("rando");
        vm.startPrank(rando);
        vm.expectRevert(ClawV2.NotClawOwner.selector);
        claw.spend(tokenId, merchant, 10e6);
        vm.stopPrank();
    }
    
    function test_BatchCreate() public {
        address[] memory agents = new address[](3);
        agents[0] = makeAddr("agent1");
        agents[1] = makeAddr("agent2");
        agents[2] = makeAddr("agent3");
        
        vm.startPrank(funder);
        usdc.approve(address(claw), 300e6); // 100 each
        
        uint256[] memory tokenIds = claw.createBatch(agents, 100e6, 0);
        vm.stopPrank();
        
        assertEq(tokenIds.length, 3);
        assertEq(claw.ownerOf(tokenIds[0]), agents[0]);
        assertEq(claw.ownerOf(tokenIds[1]), agents[1]);
        assertEq(claw.ownerOf(tokenIds[2]), agents[2]);
        assertEq(claw.getRemaining(tokenIds[0]), 100e6);
    }

    function test_TipAnotherAgent() public {
        address agent2 = makeAddr("agent2");
        
        // Setup: create claw for agent
        vm.startPrank(funder);
        usdc.approve(address(claw), 100e6);
        uint256 tokenId = claw.create(agent, 100e6, 0);
        vm.stopPrank();
        
        // Agent tips agent2
        vm.prank(agent);
        claw.tip(tokenId, agent2, 5e6, "thanks for the help!");
        
        // Verify
        assertEq(usdc.balanceOf(agent2), 5e6);
        assertEq(claw.getRemaining(tokenId), 95e6);
    }

    function test_ClawIsTradeable() public {
        vm.startPrank(funder);
        usdc.approve(address(claw), 100e6);
        uint256 tokenId = claw.create(agent, 100e6, 0);
        vm.stopPrank();
        
        // Agent transfers to new agent
        address newAgent = makeAddr("newAgent");
        vm.prank(agent);
        claw.transferFrom(agent, newAgent, tokenId);
        
        assertEq(claw.ownerOf(tokenId), newAgent);
        
        // New agent can spend
        vm.prank(newAgent);
        claw.spend(tokenId, merchant, 20e6);
        
        assertEq(usdc.balanceOf(merchant), 20e6);
    }
}

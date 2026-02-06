// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @title Claw V2 - Non-Custodial Spending Authority
/// @notice NFT represents spending permission, funds stay in user's wallet
/// @dev User approves this contract, agent owns NFT, contract pulls on spend
contract ClawV2 is ERC721Enumerable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    // ============ State ============

    IERC20 public immutable usdc;
    uint256 private _nextTokenId;

    struct ClawData {
        address funder;      // Wallet that funds this Claw (where USDC is pulled from)
        uint256 maxSpend;    // Maximum USDC spendable (6 decimals)
        uint256 spent;       // Amount already spent
        uint256 expiry;      // Unix timestamp (0 = no expiry)
        bool revoked;        // Funder can revoke anytime
    }

    mapping(uint256 => ClawData) public claws;

    // ============ Events ============

    event ClawCreated(
        uint256 indexed tokenId,
        address indexed funder,
        address indexed agent,
        uint256 maxSpend,
        uint256 expiry
    );

    event ClawSpent(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 remaining,
        string memo
    );

    event ClawRevoked(uint256 indexed tokenId, address indexed funder);
    
    event ClawLimitIncreased(uint256 indexed tokenId, uint256 newLimit);
    
    event ClawTipped(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        uint256 amount,
        string message
    );

    // ============ Errors ============

    error ClawExpired();
    error ClawIsRevoked();
    error SpendLimitExceeded();
    error NotClawOwner();
    error NotClawFunder();
    error ZeroAmount();
    error ZeroMaxSpend();
    error InsufficientAllowance();

    // ============ Constructor ============

    constructor(address _usdc) ERC721("Claw", "CLAW") {
        usdc = IERC20(_usdc);
        _nextTokenId = 1;
    }

    // ============ Funder Functions ============

    /// @notice Create a Claw - grant spending authority to an agent
    /// @dev Funder must have approved this contract for at least maxSpend
    /// @param agent Address to receive the Claw NFT (spending authority)
    /// @param maxSpend Maximum USDC the agent can spend
    /// @param expiry Unix timestamp (0 = no expiry)
    function create(
        address agent,
        uint256 maxSpend,
        uint256 expiry
    ) external returns (uint256 tokenId) {
        if (maxSpend == 0) revert ZeroMaxSpend();
        
        // Verify funder has approved enough
        uint256 allowance = usdc.allowance(msg.sender, address(this));
        if (allowance < maxSpend) revert InsufficientAllowance();
        
        tokenId = _nextTokenId++;
        
        claws[tokenId] = ClawData({
            funder: msg.sender,
            maxSpend: maxSpend,
            spent: 0,
            expiry: expiry,
            revoked: false
        });
        
        _safeMint(agent, tokenId);
        
        emit ClawCreated(tokenId, msg.sender, agent, maxSpend, expiry);
    }

    /// @notice Batch create Claws - fund multiple agents in one tx
    /// @dev Gas efficient for funding multiple agents with same params
    /// @param agents Array of agent addresses to receive Claws
    /// @param maxSpendEach Amount each agent can spend
    /// @param expiry Expiry timestamp (0 = no expiry)
    function createBatch(
        address[] calldata agents,
        uint256 maxSpendEach,
        uint256 expiry
    ) external returns (uint256[] memory tokenIds) {
        if (maxSpendEach == 0) revert ZeroMaxSpend();
        
        uint256 totalRequired = maxSpendEach * agents.length;
        uint256 allowance = usdc.allowance(msg.sender, address(this));
        if (allowance < totalRequired) revert InsufficientAllowance();
        
        tokenIds = new uint256[](agents.length);
        
        for (uint256 i = 0; i < agents.length; i++) {
            uint256 tokenId = _nextTokenId++;
            tokenIds[i] = tokenId;
            
            claws[tokenId] = ClawData({
                funder: msg.sender,
                maxSpend: maxSpendEach,
                spent: 0,
                expiry: expiry,
                revoked: false
            });
            
            _safeMint(agents[i], tokenId);
            emit ClawCreated(tokenId, msg.sender, agents[i], maxSpendEach, expiry);
        }
    }

    /// @notice Revoke a Claw - immediately disable spending authority
    /// @dev Only the funder can revoke. NFT still exists but is unusable.
    function revoke(uint256 tokenId) external {
        ClawData storage c = claws[tokenId];
        if (c.funder != msg.sender) revert NotClawFunder();
        
        c.revoked = true;
        emit ClawRevoked(tokenId, msg.sender);
    }

    /// @notice Increase spending limit on existing Claw
    /// @dev Only funder can increase. Must have sufficient allowance.
    function increaseLimit(uint256 tokenId, uint256 newMaxSpend) external {
        ClawData storage c = claws[tokenId];
        if (c.funder != msg.sender) revert NotClawFunder();
        require(newMaxSpend > c.maxSpend, "Must increase");
        
        uint256 allowance = usdc.allowance(msg.sender, address(this));
        if (allowance < newMaxSpend) revert InsufficientAllowance();
        
        c.maxSpend = newMaxSpend;
        emit ClawLimitIncreased(tokenId, newMaxSpend);
    }

    // ============ Agent Functions ============

    /// @notice Spend USDC using your Claw
    /// @dev Pulls from funder's wallet, sends to recipient
    /// @param tokenId The Claw to spend from
    /// @param to Recipient of USDC
    /// @param amount Amount to spend (6 decimals)
    /// @param memo Optional reason for spend (for audit trail)
    function spend(
        uint256 tokenId,
        address to,
        uint256 amount,
        string calldata memo
    ) external nonReentrant {
        if (amount == 0) revert ZeroAmount();
        if (ownerOf(tokenId) != msg.sender) revert NotClawOwner();
        
        ClawData storage c = claws[tokenId];
        if (c.revoked) revert ClawIsRevoked();
        if (c.expiry != 0 && block.timestamp > c.expiry) revert ClawExpired();
        if (c.spent + amount > c.maxSpend) revert SpendLimitExceeded();
        
        c.spent += amount;
        uint256 remainingAmt = c.maxSpend - c.spent;
        
        // Pull from funder's wallet, send to recipient
        usdc.safeTransferFrom(c.funder, to, amount);
        
        emit ClawSpent(tokenId, c.funder, to, amount, remainingAmt, memo);
    }

    /// @notice Tip another agent - A2A payment from your Claw
    /// @dev Pulls from funder, sends to recipient agent's address
    /// @param tokenId Your Claw to spend from
    /// @param toAgent Recipient agent address
    /// @param amount Tip amount (6 decimals)
    /// @param message Optional on-chain message (emitted in event)
    function tip(
        uint256 tokenId,
        address toAgent,
        uint256 amount,
        string calldata message
    ) external nonReentrant {
        if (amount == 0) revert ZeroAmount();
        if (ownerOf(tokenId) != msg.sender) revert NotClawOwner();
        
        ClawData storage c = claws[tokenId];
        if (c.revoked) revert ClawIsRevoked();
        if (c.expiry != 0 && block.timestamp > c.expiry) revert ClawExpired();
        if (c.spent + amount > c.maxSpend) revert SpendLimitExceeded();
        
        c.spent += amount;
        
        usdc.safeTransferFrom(c.funder, toAgent, amount);
        
        emit ClawTipped(tokenId, msg.sender, toAgent, amount, message);
    }

    // ============ View Functions ============

    /// @notice Get remaining spendable amount
    function getRemaining(uint256 tokenId) external view returns (uint256) {
        ClawData storage c = claws[tokenId];
        if (c.revoked) return 0;
        if (c.expiry != 0 && block.timestamp > c.expiry) return 0;
        
        // Also check current allowance
        uint256 allowance = usdc.allowance(c.funder, address(this));
        uint256 clawRemaining = c.maxSpend - c.spent;
        
        return allowance < clawRemaining ? allowance : clawRemaining;
    }

    /// @notice Check if Claw is currently usable
    function isActive(uint256 tokenId) external view returns (bool) {
        ClawData storage c = claws[tokenId];
        if (c.revoked) return false;
        if (c.expiry != 0 && block.timestamp > c.expiry) return false;
        if (c.spent >= c.maxSpend) return false;
        return true;
    }

    // ============ Metadata ============

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        ClawData storage c = claws[tokenId];
        
        string memory status = c.revoked ? "REVOKED" : 
            (c.expiry != 0 && block.timestamp > c.expiry) ? "EXPIRED" : "ACTIVE";
        
        uint256 remainingAmt = c.maxSpend - c.spent;
        uint256 percentUsed = c.maxSpend > 0 ? (c.spent * 100) / c.maxSpend : 0;
        
        string memory svg = _generateSVG(tokenId, c.maxSpend, c.spent, status, percentUsed);
        
        string memory json = string(abi.encodePacked(
            '{"name":"Claw #', tokenId.toString(),
            '","description":"Non-custodial spending authority. Funds stay in funder wallet.",',
            '"attributes":[',
                '{"trait_type":"Max Spend","value":', (c.maxSpend / 1e6).toString(), '},',
                '{"trait_type":"Spent","value":', (c.spent / 1e6).toString(), '},',
                '{"trait_type":"Remaining","value":', (remainingAmt / 1e6).toString(), '},',
                '{"trait_type":"Status","value":"', status, '"},',
                '{"trait_type":"Funder","value":"', _toHexString(c.funder), '"}',
            '],',
            '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'
        ));
        
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    function _generateSVG(
        uint256 tokenId,
        uint256 maxSpend,
        uint256 spent,
        string memory status,
        uint256 percentUsed
    ) internal pure returns (string memory) {
        uint256 barWidth = (percentUsed * 260) / 100;
        string memory statusColor = keccak256(bytes(status)) == keccak256("ACTIVE") 
            ? "#22c55e" : "#ef4444";
        
        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 300">',
            '<rect width="300" height="300" fill="#0f0f1a"/>',
            '<text x="20" y="40" font-family="monospace" font-size="24" fill="#fff">CLAW #', tokenId.toString(), '</text>',
            '<text x="20" y="70" font-family="monospace" font-size="12" fill="#888">NON-CUSTODIAL</text>',
            '<text x="20" y="120" font-family="monospace" font-size="14" fill="#888">LIMIT</text>',
            '<text x="20" y="145" font-family="monospace" font-size="28" fill="#fff">$', (maxSpend / 1e6).toString(), '</text>',
            '<text x="20" y="190" font-family="monospace" font-size="14" fill="#888">SPENT</text>',
            '<text x="20" y="215" font-family="monospace" font-size="28" fill="#dc2626">$', (spent / 1e6).toString(), '</text>',
            '<rect x="20" y="240" width="260" height="8" rx="4" fill="#1f1f3a"/>',
            '<rect x="20" y="240" width="', barWidth.toString(), '" height="8" rx="4" fill="#dc2626"/>',
            '<circle cx="270" cy="55" r="8" fill="', statusColor, '"/>',
            '<text x="20" y="280" font-family="monospace" font-size="10" fill="#666">USDC on Base</text>',
            '</svg>'
        ));
    }

    function _toHexString(address addr) internal pure returns (string memory) {
        bytes memory buffer = new bytes(42);
        buffer[0] = '0';
        buffer[1] = 'x';
        bytes memory hexChars = "0123456789abcdef";
        for (uint256 i = 0; i < 20; i++) {
            buffer[2 + i * 2] = hexChars[uint8(uint160(addr) >> (8 * (19 - i)) >> 4) & 0xf];
            buffer[3 + i * 2] = hexChars[uint8(uint160(addr) >> (8 * (19 - i))) & 0xf];
        }
        return string(buffer);
    }
}

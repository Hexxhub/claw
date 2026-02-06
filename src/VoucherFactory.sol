// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title VoucherFactory - One-Time USDC Spending Vouchers as NFTs
/// @notice ERC-7978 inspired NFAT factory for disposable agent spending power
/// @dev Each NFT represents a voucher with a spending limit. The factory holds USDC
///      and manages per-voucher spending limits. Voucher ownership = spending authority.
contract VoucherFactory is ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ State ============

    IERC20 public immutable usdc;
    uint256 private _nextTokenId;

    struct Voucher {
        uint256 maxSpend;    // Maximum USDC this voucher can spend (6 decimals)
        uint256 spent;       // Amount already spent
        uint256 expiry;      // Unix timestamp (0 = no expiry)
        bool burned;         // Whether voucher has been burned
    }

    mapping(uint256 => Voucher) public vouchers;

    // ============ Events ============

    event VoucherCreated(
        uint256 indexed tokenId,
        address indexed recipient,
        uint256 maxSpend,
        uint256 expiry
    );

    event VoucherSpent(
        uint256 indexed tokenId,
        address indexed to,
        uint256 amount,
        uint256 totalSpent,
        uint256 remaining
    );

    event VoucherBurned(
        uint256 indexed tokenId,
        address indexed returnTo,
        uint256 amountReturned
    );

    // ============ Errors ============

    error InvalidTokenId();
    error VoucherExpired();
    error VoucherAlreadyBurned();
    error SpendLimitExceeded();
    error NotVoucherOwner();
    error ZeroAmount();
    error ZeroMaxSpend();
    error InsufficientUSDC();

    // ============ Constructor ============

    constructor(address _usdc) ERC721("USDC Voucher", "VOUCHER") Ownable(msg.sender) {
        usdc = IERC20(_usdc);
        _nextTokenId = 1;
    }

    // ============ Core Functions ============

    /// @notice Creates a new voucher NFT funded with USDC
    /// @param recipient Address to receive the voucher NFT
    /// @param maxSpend Maximum USDC the voucher can spend (must transfer this amount)
    /// @param expiry Unix timestamp when voucher expires (0 = no expiry)
    /// @return tokenId The ID of the minted voucher
    function mint(
        address recipient,
        uint256 maxSpend,
        uint256 expiry
    ) external nonReentrant returns (uint256 tokenId) {
        if (maxSpend == 0) revert ZeroMaxSpend();
        
        // Transfer USDC from sender to this contract
        usdc.safeTransferFrom(msg.sender, address(this), maxSpend);
        
        tokenId = _nextTokenId++;
        
        vouchers[tokenId] = Voucher({
            maxSpend: maxSpend,
            spent: 0,
            expiry: expiry,
            burned: false
        });
        
        _safeMint(recipient, tokenId);
        
        emit VoucherCreated(tokenId, recipient, maxSpend, expiry);
    }

    /// @notice Spends USDC from a voucher (only owner of NFT can call)
    /// @param tokenId The voucher to spend from
    /// @param to Recipient of the USDC
    /// @param amount Amount to spend (6 decimals)
    function spend(
        uint256 tokenId,
        address to,
        uint256 amount
    ) external nonReentrant {
        if (amount == 0) revert ZeroAmount();
        _requireOwned(tokenId);
        if (ownerOf(tokenId) != msg.sender) revert NotVoucherOwner();
        
        Voucher storage v = vouchers[tokenId];
        if (v.burned) revert VoucherAlreadyBurned();
        if (v.expiry != 0 && block.timestamp > v.expiry) revert VoucherExpired();
        if (v.spent + amount > v.maxSpend) revert SpendLimitExceeded();
        
        v.spent += amount;
        uint256 remaining = v.maxSpend - v.spent;
        
        usdc.safeTransfer(to, amount);
        
        emit VoucherSpent(tokenId, to, amount, v.spent, remaining);
    }

    /// @notice Burns a voucher and returns remaining USDC
    /// @param tokenId The voucher to burn
    /// @param returnTo Address to receive remaining USDC
    function burn(uint256 tokenId, address returnTo) external nonReentrant {
        _requireOwned(tokenId);
        if (ownerOf(tokenId) != msg.sender) revert NotVoucherOwner();
        
        Voucher storage v = vouchers[tokenId];
        if (v.burned) revert VoucherAlreadyBurned();
        
        uint256 remaining = v.maxSpend - v.spent;
        v.burned = true;
        
        // Burn the NFT
        _burn(tokenId);
        
        // Return remaining USDC
        if (remaining > 0) {
            usdc.safeTransfer(returnTo, remaining);
        }
        
        emit VoucherBurned(tokenId, returnTo, remaining);
    }

    // ============ View Functions ============

    /// @notice Gets voucher details
    function getVoucher(uint256 tokenId) external view returns (
        uint256 maxSpend,
        uint256 spent,
        uint256 expiry,
        bool burned
    ) {
        Voucher storage v = vouchers[tokenId];
        return (v.maxSpend, v.spent, v.expiry, v.burned);
    }

    /// @notice Gets remaining spendable amount
    function getRemaining(uint256 tokenId) external view returns (uint256) {
        Voucher storage v = vouchers[tokenId];
        if (v.burned || (v.expiry != 0 && block.timestamp > v.expiry)) {
            return 0;
        }
        return v.maxSpend - v.spent;
    }

    /// @notice Checks if a voucher is still valid
    function isValidVoucher(uint256 tokenId) external view returns (bool) {
        try this.ownerOf(tokenId) returns (address) {
            Voucher storage v = vouchers[tokenId];
            if (v.burned) return false;
            if (v.expiry != 0 && block.timestamp > v.expiry) return false;
            if (v.spent >= v.maxSpend) return false;
            return true;
        } catch {
            return false;
        }
    }

    /// @notice Returns total USDC held by this contract
    function totalUSDCHeld() external view returns (uint256) {
        return usdc.balanceOf(address(this));
    }

    // ============ Metadata ============

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        
        Voucher storage v = vouchers[tokenId];
        uint256 remaining = v.maxSpend - v.spent;
        
        // Build a simple JSON metadata
        // In production, this would be more sophisticated
        return string(abi.encodePacked(
            'data:application/json;utf8,{"name":"USDC Voucher #',
            _toString(tokenId),
            '","description":"One-time USDC spending voucher for AI agents","attributes":[{"trait_type":"Max Spend","value":"',
            _toString(v.maxSpend / 1e6),
            ' USDC"},{"trait_type":"Spent","value":"',
            _toString(v.spent / 1e6),
            ' USDC"},{"trait_type":"Remaining","value":"',
            _toString(remaining / 1e6),
            ' USDC"},{"trait_type":"Status","value":"',
            v.burned ? "Burned" : (v.expiry != 0 && block.timestamp > v.expiry ? "Expired" : "Active"),
            '"}]}'
        ));
    }

    // ============ Internal ============

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // ============ Transfer Hook (ERC-7978 inspired) ============

    /// @dev Prevents transferring voucher to the factory contract itself
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        // Self-transfer lock (ERC-7978 pattern)
        if (to == address(this)) {
            revert("Cannot transfer to factory");
        }
        return super._update(to, tokenId, auth);
    }
}

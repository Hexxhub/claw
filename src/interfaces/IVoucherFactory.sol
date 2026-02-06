// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title IVoucherFactory - ERC-7978 NFAT Factory for USDC Vouchers
/// @notice Creates one-time-use USDC spending vouchers as tradable NFTs
interface IVoucherFactory is IERC721 {
    /// @notice Emitted when a new voucher and its wallet are created
    event VoucherCreated(
        uint256 indexed tokenId,
        address indexed wallet,
        address indexed recipient,
        uint256 maxSpend,
        uint256 expiry
    );

    /// @notice Emitted when a voucher is burned and remaining funds returned
    event VoucherBurned(
        uint256 indexed tokenId,
        address indexed wallet,
        uint256 amountReturned
    );

    /// @notice Emitted when funds are spent from a voucher
    event VoucherSpent(
        uint256 indexed tokenId,
        address indexed to,
        uint256 amount,
        uint256 totalSpent,
        uint256 remaining
    );

    error InvalidTokenId();
    error VoucherExpired();
    error SpendLimitExceeded();
    error NotVoucherOwner();
    error WalletDeploymentFailed();
    error SelfTransferNotAllowed();

    /// @notice Mints a new voucher NFT and deploys its associated wallet
    /// @param recipient Address to receive the voucher NFT
    /// @param maxSpend Maximum USDC the voucher can spend (6 decimals)
    /// @param expiry Unix timestamp when voucher expires (0 = no expiry)
    /// @return tokenId The ID of the minted voucher
    /// @return wallet The address of the deployed wallet
    function mint(
        address recipient,
        uint256 maxSpend,
        uint256 expiry
    ) external payable returns (uint256 tokenId, address wallet);

    /// @notice Burns a voucher and returns remaining USDC to specified address
    /// @param tokenId The voucher to burn
    /// @param returnTo Address to receive remaining USDC
    function burn(uint256 tokenId, address returnTo) external;

    /// @notice Spends USDC from a voucher's wallet
    /// @param tokenId The voucher to spend from
    /// @param to Recipient of the USDC
    /// @param amount Amount to spend (6 decimals)
    function spend(uint256 tokenId, address to, uint256 amount) external;

    /// @notice Gets the wallet address for a voucher
    /// @param tokenId The voucher token ID
    /// @return The deterministic wallet address
    function getWallet(uint256 tokenId) external view returns (address);

    /// @notice Gets voucher details
    /// @param tokenId The voucher token ID
    /// @return maxSpend Maximum spend limit
    /// @return spent Amount already spent
    /// @return expiry Expiry timestamp
    /// @return wallet Wallet address
    function getVoucher(uint256 tokenId) external view returns (
        uint256 maxSpend,
        uint256 spent,
        uint256 expiry,
        address wallet
    );

    /// @notice Checks if a voucher is still valid (not expired, has remaining balance)
    /// @param tokenId The voucher token ID
    /// @return isValid True if voucher can still be used
    function isValidVoucher(uint256 tokenId) external view returns (bool isValid);

    /// @notice Returns USDC token address
    function usdc() external view returns (address);
}

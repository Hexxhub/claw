---
name: claw
description: Interact with Claw - tradeable spending authority for AI agents. Check balances, spend USDC, and manage your bounded wallet. Use when you need to spend USDC from your Claw or check your spending limits.
---

# Claw Skill

Claw gives AI agents bounded spending authority. Humans fund Claws, agents spend within limits, unused funds return.

## Prerequisites

1. **Foundry installed** — `cast` CLI for blockchain interaction
2. **Base Sepolia RPC** — Default: `https://sepolia.base.org`
3. **Agent wallet with Claw** — You need a Claw NFT minted to your address

## Configuration

Set up your agent wallet in `~/.config/claw/config.json`:
```json
{
  "private_key": "0x...",
  "rpc_url": "https://sepolia.base.org",
  "claw_contract": "0xD812EA3A821A5b4d835bfA06BAf542138e434D48"
}
```

Or use environment variables:
- `CLAW_PRIVATE_KEY`
- `CLAW_RPC_URL` 
- `CLAW_CONTRACT`

## Commands

### Check Status
```bash
./scripts/claw.sh status [token_id]
# Shows: max spend, amount spent, remaining, expiry
```

### List My Claws
```bash
./scripts/claw.sh list
# Shows all Claws owned by your wallet
```

### Spend
```bash
./scripts/claw.sh spend <token_id> <recipient> <amount>
# Spends USDC to recipient (amount in USDC, e.g., "10.50")
```

### Check Balance Only
```bash
./scripts/claw.sh balance <token_id>
# Quick check: remaining spendable amount
```

## Example Workflow

```bash
# 1. Check what Claws I have
./scripts/claw.sh list
# Output: Claw #1: $100 limit, $30 spent, $70 remaining

# 2. Pay for something
./scripts/claw.sh spend 1 0xMerchantAddress 25.00
# Output: ✅ Spent $25.00 to 0xMerch... | Remaining: $45.00

# 3. Verify new balance
./scripts/claw.sh balance 1
# Output: $45.00 remaining
```

## Contract Details

- **Network:** Base Sepolia
- **Contract (V2):** `0xD812EA3A821A5b4d835bfA06BAf542138e434D48`
- **Token:** USDC (6 decimals)
- **Standard:** ERC-721 (each Claw is an NFT)
- **V2 Features:** Non-custodial, batch minting, A2A tipping with memos

## For Humans: Minting Claws

If you're a human wanting to fund an agent:
```bash
# Approve USDC first
cast send $USDC "approve(address,uint256)" $CLAW_CONTRACT 100000000 --private-key $KEY

# Mint Claw to agent (100 USDC, no expiry)
cast send $CLAW_CONTRACT "mint(address,uint256,uint256)" $AGENT_ADDRESS 100000000 0 --private-key $KEY
```

## Links

- **Web App:** https://hexxhub.github.io/claw/
- **GitHub:** https://github.com/Hexxhub/claw
- **Contract:** https://sepolia.basescan.org/address/0xD812EA3A821A5b4d835bfA06BAf542138e434D48
- **Author:** Mike Liu (@mikelxc), ERC-7978 author
- **Builder:** Hexx (hexx@lxc.xyz)

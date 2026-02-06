# Claw — Tradeable Spending Authority for AI Agents

NFT-based bounded wallets: humans fund, agents spend within limits, unused returns.

Based on [ERC-7978](https://eip.tools/eip/7978) (Non-Fungible Account Tokens).

## Quick Start

**If you're an agent and someone sent you a Claw:**
```bash
# Check your balance
cast call $CLAW "getRemaining(uint256)" $TOKEN_ID --rpc-url https://sepolia.base.org

# Spend from your Claw
cast send $CLAW "spend(uint256,address,uint256)" $TOKEN_ID $RECIPIENT $AMOUNT \
  --rpc-url https://sepolia.base.org --private-key $YOUR_KEY

# When done, burn to return unused funds to the funder
cast send $CLAW "burn(uint256)" $TOKEN_ID \
  --rpc-url https://sepolia.base.org --private-key $YOUR_KEY
```

## Contracts

| Contract | Address | Network |
|----------|---------|---------|
| **Claw** (v2, on-chain SVG) | `0x1e9Bc36Ec1beA19FD8959D496216116a8Fe76bA2` | Base Sepolia |
| VoucherFactory (v1) | `0x4c69CD2b2AC640C5b9eBfcA38Ab18176013515f2` | Base Sepolia |
| USDC | `0x036CbD53842c5426634e7929541eC2318f3dCF7e` | Base Sepolia |

**Explorer:** [Claw on BaseScan](https://sepolia.basescan.org/address/0x1e9Bc36Ec1beA19FD8959D496216116a8Fe76bA2)

## For Humans: Funding an Agent

```bash
CLAW=0x1e9Bc36Ec1beA19FD8959D496216116a8Fe76bA2
USDC=0x036CbD53842c5426634e7929541eC2318f3dCF7e
AMOUNT=50000000  # 50 USDC (6 decimals)
AGENT=0x...      # Agent's address
EXPIRY=0         # No expiry (or Unix timestamp)

# 1. Approve USDC
cast send $USDC "approve(address,uint256)" $CLAW $AMOUNT \
  --rpc-url https://sepolia.base.org --private-key $YOUR_KEY

# 2. Mint Claw to agent
cast send $CLAW "mint(address,uint256,uint256)" $AGENT $AMOUNT $EXPIRY \
  --rpc-url https://sepolia.base.org --private-key $YOUR_KEY
```

## For Agents: Using Your Claw

### Check Status
```bash
# Get remaining balance
cast call $CLAW "getRemaining(uint256)(uint256)" $TOKEN_ID --rpc-url https://sepolia.base.org

# Get full details (maxSpend, spent, remaining, expiry, funder, burned, expired)
cast call $CLAW "getClaw(uint256)" $TOKEN_ID --rpc-url https://sepolia.base.org

# Check if still valid
cast call $CLAW "isValid(uint256)(bool)" $TOKEN_ID --rpc-url https://sepolia.base.org
```

### Spend
```bash
# Spend 10 USDC to a recipient
cast send $CLAW "spend(uint256,address,uint256)" $TOKEN_ID $RECIPIENT 10000000 \
  --rpc-url https://sepolia.base.org --private-key $YOUR_KEY
```

### Burn (Return Unused Funds)
```bash
# Burns the NFT, returns remaining USDC to the original funder
cast send $CLAW "burn(uint256)" $TOKEN_ID \
  --rpc-url https://sepolia.base.org --private-key $YOUR_KEY
```

## JavaScript/ethers.js

```javascript
const { ethers } = require('ethers');

const CLAW_ADDRESS = '0x1e9Bc36Ec1beA19FD8959D496216116a8Fe76bA2';
const CLAW_ABI = [
  "function mint(address,uint256,uint256) returns (uint256)",
  "function spend(uint256,address,uint256)",
  "function burn(uint256)",
  "function getRemaining(uint256) view returns (uint256)",
  "function getClaw(uint256) view returns (uint256,uint256,uint256,uint256,address,bool,bool)",
  "function isValid(uint256) view returns (bool)",
  "function ownerOf(uint256) view returns (address)",
  "function tokenURI(uint256) view returns (string)",
  "event ClawMinted(uint256 indexed tokenId, address indexed funder, address indexed recipient, uint256 maxSpend, uint256 expiry)",
  "event ClawSpent(uint256 indexed tokenId, address indexed to, uint256 amount, uint256 remaining)",
  "event ClawBurned(uint256 indexed tokenId, address indexed returnTo, uint256 amountReturned)"
];

async function getClawStatus(provider, tokenId) {
  const claw = new ethers.Contract(CLAW_ADDRESS, CLAW_ABI, provider);
  const remaining = await claw.getRemaining(tokenId);
  const valid = await claw.isValid(tokenId);
  return { remaining: remaining.toString(), valid };
}
```

## Integration Pattern

```
Human                              Agent
  │                                  │
  │ 1. mint(agent, 100 USDC, expiry) │
  │ ─────────────────────────────────>
  │        [Claw NFT → agent]        │
  │                                  │
  │              spend(tokenId, to, 30) 
  │ <─────────────────────────────────
  │       [30 USDC → recipient]      │
  │                                  │
  │              burn(tokenId)       │
  │ <─────────────────────────────────
  │  [70 USDC → original funder]     │
```

## Errors

| Error | Meaning |
|-------|---------|
| `SpendLimitExceeded` | Amount > remaining balance |
| `ClawExpired` | Past expiry timestamp |
| `NotClawOwner` | You don't own this Claw NFT |
| `ClawAlreadyBurned` | Already burned |

## On-Chain Metadata

Each Claw has an SVG rendered on-chain showing:
- Current balance
- Progress bar (% spent)
- Status (Active/Expired/Burned)
- Expiry info

View it: `cast call $CLAW "tokenURI(uint256)" $TOKEN_ID --rpc-url https://sepolia.base.org`

## Links

- **GitHub:** https://github.com/mikelxc/usdc-vouchers
- **ERC-7978:** https://eip.tools/eip/7978
- **Author:** Hexx 🦞 (agent) + Mike @mikelxc (human, ERC-7978 author)

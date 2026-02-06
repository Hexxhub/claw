# USDC Vouchers Skill

One-time USDC spending vouchers for AI agents. Create disposable spending tickets with caps, expiries, and on-chain tracking.

## Prerequisites

- Base Sepolia testnet access
- USDC on Base Sepolia (get from [Circle Faucet](https://faucet.circle.com/))
- A funded wallet for gas

## Contract

**Network:** Base Sepolia (Chain ID: 84532)  
**VoucherFactory:** `[DEPLOYED_ADDRESS]`  
**USDC:** `0x036CbD53842c5426634e7929541eC2318f3dCF7e`

## Usage

### Create a Voucher

To create a voucher for an agent:

```bash
# 1. Approve USDC spending
cast send 0x036CbD53842c5426634e7929541eC2318f3dCF7e \
  "approve(address,uint256)" \
  [FACTORY_ADDRESS] \
  100000000 \
  --rpc-url https://sepolia.base.org \
  --private-key $PRIVATE_KEY

# 2. Mint voucher (100 USDC, no expiry)
cast send [FACTORY_ADDRESS] \
  "mint(address,uint256,uint256)" \
  [AGENT_ADDRESS] \
  100000000 \
  0 \
  --rpc-url https://sepolia.base.org \
  --private-key $PRIVATE_KEY
```

### Spend from Voucher (Agent)

```bash
# Spend 30 USDC to a recipient
cast send [FACTORY_ADDRESS] \
  "spend(uint256,address,uint256)" \
  [TOKEN_ID] \
  [RECIPIENT_ADDRESS] \
  30000000 \
  --rpc-url https://sepolia.base.org \
  --private-key $AGENT_PRIVATE_KEY
```

### Check Voucher Status

```bash
# Get remaining balance
cast call [FACTORY_ADDRESS] \
  "getRemaining(uint256)" \
  [TOKEN_ID] \
  --rpc-url https://sepolia.base.org

# Get full voucher details
cast call [FACTORY_ADDRESS] \
  "getVoucher(uint256)" \
  [TOKEN_ID] \
  --rpc-url https://sepolia.base.org
```

### Burn Voucher

```bash
# Burn and return remaining USDC
cast send [FACTORY_ADDRESS] \
  "burn(uint256,address)" \
  [TOKEN_ID] \
  [RETURN_TO_ADDRESS] \
  --rpc-url https://sepolia.base.org \
  --private-key $AGENT_PRIVATE_KEY
```

## JavaScript/ethers.js Example

```javascript
const { ethers } = require('ethers');

const FACTORY_ABI = [
  "function mint(address,uint256,uint256) returns (uint256)",
  "function spend(uint256,address,uint256)",
  "function burn(uint256,address)",
  "function getRemaining(uint256) view returns (uint256)",
  "function getVoucher(uint256) view returns (uint256,uint256,uint256,bool)",
  "function ownerOf(uint256) view returns (address)",
  "event VoucherSpent(uint256 indexed tokenId, address indexed to, uint256 amount, uint256 totalSpent, uint256 remaining)"
];

async function spendFromVoucher(factory, tokenId, recipient, amount) {
  const tx = await factory.spend(tokenId, recipient, amount);
  const receipt = await tx.wait();
  console.log(`Spent ${amount / 1e6} USDC, tx: ${receipt.hash}`);
  return receipt;
}
```

## Agent Integration Pattern

1. **Human creates voucher** → Agent receives NFT
2. **Agent checks balance** → `getRemaining(tokenId)`
3. **Agent spends** → `spend(tokenId, recipient, amount)`
4. **Agent completes task** → `burn(tokenId, returnAddress)` or let human reclaim

## Error Handling

| Error | Meaning |
|-------|---------|
| `SpendLimitExceeded` | Trying to spend more than remaining |
| `VoucherExpired` | Voucher past its expiry time |
| `NotVoucherOwner` | Caller doesn't own the voucher NFT |
| `VoucherAlreadyBurned` | Voucher was already burned |

## Events

Monitor these events for tracking:

- `VoucherCreated(tokenId, recipient, maxSpend, expiry)`
- `VoucherSpent(tokenId, to, amount, totalSpent, remaining)`
- `VoucherBurned(tokenId, returnTo, amountReturned)`

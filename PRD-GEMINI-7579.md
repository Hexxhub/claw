# PRD: Gemini Wallet — ERC-7579 + ERC-7978 Integration

**Author:** Mike Liu (@mikelxc), ERC-7978 Author  
**Date:** 2026-02-06  
**Status:** Draft  

---

## Executive Summary

This PRD outlines the integration of ERC-7579 (Modular Smart Accounts) with ERC-7978 (Non-Fungible Account Tokens / NFATs) to create **Gemini Wallet** — a modular smart account that can own and manage NFATs, enabling composable, shareable, and policy-governed spending authority.

**Core thesis:** A wallet that owns NFATs can delegate bounded spending authority to agents, sub-accounts, or other wallets, while retaining modular policy control over how that authority is exercised.

---

## Problem Statement

### Current Limitations

1. **Static Wallet Control**
   - Traditional wallets have binary access: you either have the key or you don't
   - No granular delegation of spending authority

2. **Agent Spending Problem**
   - Giving agents wallet access = unlimited risk
   - Per-transaction approval = kills autonomy
   - Current solutions (escrow, allowances) are inflexible

3. **Policy Fragmentation**
   - Spending rules are hard-coded per-wallet
   - No way to share/compose policies across accounts
   - No marketplace for policy modules

### Opportunity

By combining ERC-7579's modular architecture with ERC-7978's tradeable account tokens, we can create:

- **Wallets that own wallets** — hierarchical spending authority
- **Modular policies** — plug-and-play spending rules
- **Tradeable authority** — NFT-based delegation that can be transferred

---

## Solution Overview

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    GEMINI WALLET                         │
│                  (ERC-7579 Account)                      │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Validator   │  │   Executor   │  │   Fallback   │  │
│  │   Module     │  │    Module    │  │   Handler    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│                           │                              │
│  ┌────────────────────────┴────────────────────────┐   │
│  │              POLICY REGISTRY                      │   │
│  │  • Whitelist policies                            │   │
│  │  • Rate limit policies                           │   │
│  │  • Time-bound policies                           │   │
│  │  • Multi-sig policies                            │   │
│  └──────────────────────────────────────────────────┘   │
│                           │                              │
│                    OWNS / CONTROLS                       │
│                           ▼                              │
│  ┌──────────────────────────────────────────────────┐   │
│  │            NFAT VAULT (ERC-7978)                  │   │
│  │                                                    │   │
│  │  🦞 Claw #1     🦞 Claw #2     🦞 Claw #3        │   │
│  │  Agent A        Agent B        Sub-wallet         │   │
│  │  $100 limit     $50 limit      $500 limit        │   │
│  │  Exp: 7 days    Exp: 1 day     No expiry         │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### Key Components

#### 1. Gemini Wallet (ERC-7579 Account)

A modular smart account that implements:
- `IERC7579Execution` — execute transactions
- `IERC7579AccountConfig` — account configuration
- `IERC7579ModuleConfig` — module management

#### 2. NFAT Module (ERC-7978 Integration)

A 7579-compatible executor module that:
- Mints Claws (NFATs) with bounded spending authority
- Tracks NFAT ownership and spending
- Enforces policies on NFAT operations

#### 3. Policy Modules

Pluggable policy modules that govern NFAT behavior:

| Policy Type | Description | Example |
|-------------|-------------|---------|
| **Whitelist** | Restrict spending to approved addresses | Only pay vendors A, B, C |
| **Rate Limit** | Cap spending velocity | Max $100/day |
| **Time Bound** | Restrict spending to time windows | Business hours only |
| **Multi-sig** | Require multiple approvals for large spends | >$1000 needs 2/3 |
| **Category** | Restrict spending by merchant category | No gambling sites |

#### 4. Policy Registry

On-chain registry of:
- Available policy modules
- Policy templates (shareable configurations)
- Policy composition rules

---

## User Stories

### Story 1: Corporate Treasury Agent

> As a corporate treasury, I want to give our AI purchasing agent a $10,000 monthly budget that can only be spent on approved vendors, so that I maintain control while enabling autonomous procurement.

**Flow:**
1. Treasury creates Gemini Wallet
2. Installs Whitelist + Rate Limit policy modules
3. Configures: approved vendors, $10K/month cap
4. Mints Claw for purchasing agent
5. Agent spends autonomously within bounds
6. Treasury can revoke/adjust anytime

### Story 2: DAO Sub-Committee Funding

> As a DAO, I want to fund working groups with bounded budgets that auto-return unused funds, so we don't over-allocate capital.

**Flow:**
1. DAO Gemini Wallet mints Claws for each working group
2. Each Claw has: budget, expiry, category restrictions
3. Working groups operate autonomously
4. Unused funds return to DAO on expiry
5. Claws are tradeable — groups can sell unused authority

### Story 3: Family Spending Management

> As a parent, I want to give my kid an allowance with spending restrictions, trackable on-chain.

**Flow:**
1. Parent wallet mints Claw for child
2. Policies: $50/week, no adult content merchants, rate limited
3. Child spends using Claw
4. Parent sees all spending on-chain
5. Can adjust policies without minting new Claw

---

## Technical Specification

### Interface: IGeminiWallet

```solidity
interface IGeminiWallet is IERC7579Account {
    /// @notice Mint a new NFAT (Claw) with specified policies
    /// @param recipient Address to receive the NFAT
    /// @param amount USDC amount to fund
    /// @param expiry Expiration timestamp (0 = no expiry)
    /// @param policies Array of policy module addresses
    /// @param policyConfigs Encoded policy configurations
    /// @return tokenId The minted NFAT ID
    function mintClaw(
        address recipient,
        uint256 amount,
        uint256 expiry,
        address[] calldata policies,
        bytes[] calldata policyConfigs
    ) external returns (uint256 tokenId);
    
    /// @notice Update policies on an existing NFAT
    /// @param tokenId The NFAT to update
    /// @param policies New policy modules
    /// @param policyConfigs New policy configurations
    function updateClawPolicies(
        uint256 tokenId,
        address[] calldata policies,
        bytes[] calldata policyConfigs
    ) external;
    
    /// @notice Check if a spend is allowed by all policies
    /// @param tokenId The NFAT being spent
    /// @param to Recipient address
    /// @param amount Spend amount
    /// @return allowed Whether spend is permitted
    /// @return reason Rejection reason if not allowed
    function canSpend(
        uint256 tokenId,
        address to,
        uint256 amount
    ) external view returns (bool allowed, string memory reason);
}
```

### Interface: IPolicyModule

```solidity
interface IPolicyModule {
    /// @notice Check if a spend is allowed by this policy
    /// @param wallet The Gemini Wallet
    /// @param tokenId The NFAT being spent
    /// @param to Recipient address  
    /// @param amount Spend amount
    /// @param config Encoded policy configuration
    /// @return allowed Whether this policy allows the spend
    /// @return reason Rejection reason if not allowed
    function checkSpend(
        address wallet,
        uint256 tokenId,
        address to,
        uint256 amount,
        bytes calldata config
    ) external view returns (bool allowed, string memory reason);
    
    /// @notice Called after a successful spend (for rate tracking, etc.)
    function afterSpend(
        address wallet,
        uint256 tokenId,
        address to,
        uint256 amount,
        bytes calldata config
    ) external;
}
```

### Policy Composition

Policies compose via AND logic:
- All policies must approve for spend to succeed
- Any policy can block with reason
- Policies are evaluated in order (gas optimization)

```solidity
function _checkAllPolicies(uint256 tokenId, address to, uint256 amount) internal view returns (bool, string memory) {
    ClawData storage claw = claws[tokenId];
    
    for (uint i = 0; i < claw.policies.length; i++) {
        (bool allowed, string memory reason) = IPolicyModule(claw.policies[i])
            .checkSpend(address(this), tokenId, to, amount, claw.policyConfigs[i]);
        
        if (!allowed) return (false, reason);
    }
    
    return (true, "");
}
```

---

## Shared Policies & Marketplace

### Policy Templates

Pre-configured policies that can be shared:

```solidity
struct PolicyTemplate {
    string name;           // "Corporate Procurement v1"
    string description;    // "Approved vendors, rate limits, audit logging"
    address[] modules;     // Policy module addresses
    bytes[] configs;       // Default configurations
    address creator;       // Template creator
    uint256 useCount;      // Adoption metrics
}
```

### Policy Marketplace

- Creators publish policy templates
- Users browse/fork templates
- Usage fees possible (creator earns on adoption)
- Reputation system for policy quality

---

## Security Considerations

### Policy Upgrade Risks
- Policy upgrades could bypass restrictions
- **Mitigation:** Timelock on policy changes, notification to NFAT holder

### Module Malfunction
- Buggy modules could block all spends or allow unauthorized
- **Mitigation:** Module audits, emergency bypass with timelock

### Composability Attacks
- Malicious policy could extract information from other policies
- **Mitigation:** Isolated policy execution, no cross-policy state access

---

## Roadmap

### Phase 1: Core Integration (Q1 2026)
- [ ] Gemini Wallet base implementation
- [ ] Basic NFAT minting with single policy
- [ ] Whitelist policy module
- [ ] Rate limit policy module

### Phase 2: Policy Ecosystem (Q2 2026)
- [ ] Policy registry contract
- [ ] Policy template system
- [ ] Time-bound policies
- [ ] Multi-sig policies

### Phase 3: Marketplace (Q3 2026)
- [ ] Policy marketplace UI
- [ ] Creator incentives
- [ ] Cross-chain policy sync
- [ ] Advanced analytics

---

## Success Metrics

| Metric | Target (6mo) | Target (12mo) |
|--------|--------------|---------------|
| Wallets deployed | 1,000 | 10,000 |
| NFATs minted | 5,000 | 50,000 |
| Policy modules | 10 | 50 |
| Total value secured | $1M | $50M |
| Policy marketplace volume | - | $100K |

---

## Open Questions

1. **Policy versioning** — How do we handle policy upgrades without breaking existing Claws?
2. **Cross-chain NFATs** — Can a Claw on Base spend USDC on Optimism?
3. **Privacy** — Can we have private policies (ZK-based)?
4. **Compliance** — How do we handle regulatory requirements (KYC policies)?

---

## References

- [ERC-7579: Minimal Modular Smart Accounts](https://eips.ethereum.org/EIPS/eip-7579)
- [ERC-7978: Non-Fungible Account Tokens](https://eip.tools/eip/7978) — Mike Liu
- [ERC-4337: Account Abstraction](https://eips.ethereum.org/EIPS/eip-4337)
- [Claw Implementation](https://github.com/mikelxc/usdc-vouchers)

---

*"In an age we cannot trust, we need proof."*

— Built on the foundation that spending authority should be verifiable, composable, and recoverable.

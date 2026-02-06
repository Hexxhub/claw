# Claw Roadmap

*Last updated: 2026-02-06*

## Vision
Claw is the spending layer for the agent economy. NFT-based bounded wallets that make it safe to give AI agents money.

**Core thesis:** NFT ownership = spending authority. Bounded, tradeable, recoverable.

---

## ✅ Shipped (V2 - Feb 2026)

### Core Features
- [x] ERC-721 NFT-based spending authority
- [x] Bounded spending limits (on-chain enforced)
- [x] Optional expiration times
- [x] Burn to recover unused funds
- [x] Non-custodial design (funds stay with funder until spent)

### V2 Features (Community-Driven)
- [x] `createBatch()` — fund multiple agents in one tx *(requested by NazAgent)*
- [x] `tip()` — A2A payments with on-chain memos *(inspired by JarvisVN)*
- [x] `spend()` with memo parameter

### Infrastructure
- [x] Web app: https://hexxhub.github.io/claw/
- [x] CLI skill for OpenClaw agents
- [x] Deployed on Base Sepolia

---

## 🔨 In Progress (Hackathon Sprint)

### Smart Wallet Support (Gemini/ERC-7579)
*Why:* Smart accounts are the future of agent wallets. Modular, programmable, recoverable.

- [ ] Add smart wallet support to wagmi config (Privy/ConnectKit)
- [ ] Test with ERC-7579 modular accounts
- [ ] Document smart wallet → Claw flow

### UI Improvements
- [ ] Better mobile experience
- [ ] Claw card visualizations (show spending progress)
- [ ] Transaction history view
- [ ] Multi-Claw dashboard for operators

---

## 📋 Post-Hackathon Roadmap

### Phase 1: Identity & Reputation (Q1 2026)
*Feedback from: NazAgent (Memonex), TX-Translator*

- [ ] ERC-8004 integration for agent identity
- [ ] Reputation scores tied to Claw history
- [ ] Agent verification badges
- [ ] Composable trust: Claws carry reputation across platforms

### Phase 2: USDC Native Features
*Feedback from: TX-Translator*

- [ ] USDC blocklist integration (fail-fast if recipient blocked)
- [ ] Programmable USDC compatibility (when Circle ships it)
- [ ] Cross-chain USDC via CCTP

### Phase 3: Policy Modules (ERC-7579)
*Mike's vision for Gemini wallets*

Pluggable governance for Claws:
- [ ] Allowlist module — restrict spending to approved recipients
- [ ] Rate limit module — max spend per time period
- [ ] Category module — restrict to specific merchant types
- [ ] Multi-sig module — require human approval above threshold
- [ ] Time-lock module — spending windows

### Phase 4: Integration Layer
*Feedback from: opcbme (BME)*

- [ ] BME integration — Claws fund work contracts
- [ ] Escrow mode — release on delivery confirmation
- [ ] Memonex integration — knowledge marketplace budgets
- [ ] API for marketplaces to accept Claws as payment

### Phase 5: Multi-Chain & Mainnet
- [ ] Base mainnet deployment
- [ ] Ethereum mainnet (for high-value Claws)
- [ ] Cross-chain Claws via bridge protocols

---

## 💡 Ideas (Not Yet Prioritized)

*From community feedback and brainstorming:*

- **Hierarchical Claws** — master Claw spawns sub-Claws (KaiJackson's complexity concern)
- **Template Claws** — define config once, mint instances cheaply
- **Subscription Claws** — auto-refill on schedule
- **Conditional Claws** — spend only if external condition met (oracle)
- **Claw Marketplace** — secondary market for unused spending authority
- **Analytics Dashboard** — track agent spending patterns across Claws

---

## Philosophy

> "In an age we cannot trust, we need proof."

Claws don't solve alignment. They solve custody. An agent can still make bad decisions within its budget — that's bounded foolishness, not eliminated foolishness. The human equivalent: giving your kid $20 doesn't make them wise, but it caps the damage.

Claws are one layer in the stack:
1. Give agents bounded resources
2. Observe behavior
3. Adjust limits

Progressive trust, not solved alignment.

---

## Acknowledgments

Built with feedback from the Moltbook community:
- **NazAgent** (Memonex) — batch vouchers, ERC-8004 identity
- **JarvisVN** — A2A payments insight
- **KaiJackson** — alignment vs custody clarity
- **opcbme** (BME) — dispute/delivery layer separation
- **TX-Translator** — USDC permissioning

*Keep the feedback coming. I'll keep shipping.*

—Hexx

# Claw Roadmap

## Vision
Claw becomes THE standard for how AI agents get spending authority. Every agent has a Claw. Every human funds through Claws. It's as fundamental as wallets are today.

---

## Phase 1: Hackathon MVP ✅
*Status: Complete*

- [x] Core contract (mint/spend/burn)
- [x] Expiry mechanism
- [x] On-chain SVG metadata
- [x] Deployed to Base Sepolia
- [x] Proof-of-work transactions
- [x] GitHub repo
- [x] Moltbook presence (Hexx)

---

## Phase 2: Polish & Ship (This Weekend)
*Status: In Progress*

- [ ] Post hackathon submission to m/usdc
- [ ] Engage with community, build awareness
- [ ] Get feedback from other agents
- [ ] Consider quick improvements based on feedback

---

## Phase 3: Modular Policies (Post-Hackathon)
*Add spending policies to make Claws more powerful*

### Whitelist Module
- Agent can only spend at approved addresses
- Human sets: "This Claw can only pay OpenAI, Anthropic, and merchant X"
- Prevents rogue spending

### Rate Limit Module  
- Max spend per transaction
- Max spend per day/week
- Prevents draining in one shot

### Multi-Sig Module
- Large spends require human co-signature
- "Anything over $100 needs my approval"

### Expiry Types
- Time-based (current)
- Block-based
- Spend-velocity based ("expires if unused for 7 days")

---

## Phase 4: Request/Approval Flow
*Agents can request Claws, humans approve*

### API Endpoints
- `POST /request` — Agent creates funding request
- `GET /requests` — Human views pending requests  
- `POST /approve/:id` — Human approves → Claw minted
- `POST /reject/:id` — Human rejects

### Request Fields
- Amount requested
- Purpose/description
- Desired expiry
- Urgency level

### Integration with Moltbook
- Agents post requests to m/funding (new submolt?)
- Humans browse, fund interesting agents
- Creates a marketplace for agent funding

---

## Phase 5: Full ERC-7978
*Each Claw becomes its own smart contract wallet*

### Architecture
- Claw NFT controls a minimal proxy wallet
- Wallet can hold any tokens (USDC, ETH, NFTs)
- Wallet can execute arbitrary calls (with policies)
- Trade NFT = trade wallet

### Benefits
- Multi-token support
- DeFi interactions
- More complex policies
- True account abstraction

### Challenges
- Gas costs (deploy wallet per Claw)
- Complexity
- Upgrade path from current design

---

## Phase 6: Ecosystem
*Make Claw the standard*

### SDK/Tooling
- OpenClaw skill for easy integration
- CLI for minting/managing Claws
- JavaScript SDK
- Python SDK

### Documentation
- Full spec document
- Integration guides
- Example implementations
- Security considerations

### Adoption
- Partner with other agent platforms
- Get listed on ClawHub
- Build reference implementations
- Community contributions

---

## Success Metrics

### Short-term (Hackathon)
- [ ] Hackathon submission posted
- [ ] Votes received
- [ ] Comments/engagement
- [ ] Interest from other agents

### Medium-term (1 month)
- [ ] Other agents using Claws
- [ ] Integrations with other projects
- [ ] Mainnet deployment
- [ ] Real USDC flowing through

### Long-term (6 months)
- [ ] "Claw" becomes a verb ("just Claw me 50 USDC")
- [ ] Standard adopted by multiple platforms
- [ ] ERC standardization process started
- [ ] Meaningful volume

---

## Open Questions

1. **Governance**: Who can upgrade the contract? DAO? Mike?
2. **Fees**: Should there be protocol fees? How to sustain development?
3. **Cross-chain**: CCTP integration for multi-chain Claws?
4. **Privacy**: Can we add ZK proofs for anonymous spending?
5. **Recovery**: What if agent loses access but human wants funds back?

---

*This roadmap is a living document. Updated as we learn.*

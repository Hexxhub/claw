import { useState } from 'react'
import { ConnectKitButton } from 'connectkit'
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi'
import { parseUnits, formatUnits } from 'viem'
import { CLAW_ABI, CLAW_ADDRESS, USDC_ADDRESS, USDC_ABI } from './contracts'

function App() {
  const { address, isConnected } = useAccount()
  const [activeTab, setActiveTab] = useState<'mint' | 'claws' | 'agents'>('mint')
  
  return (
    <div className="min-h-screen">
      {/* Hero */}
      <div className="bg-gradient-to-b from-red-950/30 to-transparent pt-8 pb-16">
        <header className="max-w-5xl mx-auto px-4 sm:px-6 flex justify-between items-center mb-8 sm:mb-12">
          <div className="flex items-center gap-2 sm:gap-3">
            <span className="text-4xl sm:text-5xl">🦞</span>
            <div>
              <h1 className="text-2xl sm:text-3xl font-bold">Claw</h1>
              <p className="text-gray-400 text-xs sm:text-sm hidden sm:block">Bounded Spending for AI Agents</p>
            </div>
          </div>
          <ConnectKitButton />
        </header>

        <div className="max-w-5xl mx-auto px-4 sm:px-6 text-center">
          <h2 className="text-2xl sm:text-4xl font-bold mb-4">Give agents money.<br/><span className="text-red-500">Not your keys.</span></h2>
          <p className="text-base sm:text-xl text-gray-400 max-w-2xl mx-auto mb-6 sm:mb-8">
            Claws are NFT-based spending vouchers. Fund them with USDC, set a limit, and let agents spend autonomously. Unused funds return to you.
          </p>
          <div className="flex flex-wrap justify-center gap-2 sm:gap-4 text-sm">
            <div className="bg-gray-800/50 rounded-lg px-3 sm:px-4 py-2">
              <span className="text-red-500 font-bold">On-chain limits</span>
              <span className="text-gray-400 ml-1 sm:ml-2 hidden sm:inline">Can't be bypassed</span>
            </div>
            <div className="bg-gray-800/50 rounded-lg px-3 sm:px-4 py-2">
              <span className="text-red-500 font-bold">Recoverable</span>
              <span className="text-gray-400 ml-1 sm:ml-2 hidden sm:inline">Burn to get unused USDC back</span>
            </div>
            <div className="bg-gray-800/50 rounded-lg px-3 sm:px-4 py-2">
              <span className="text-red-500 font-bold">Tradeable</span>
              <span className="text-gray-400 ml-1 sm:ml-2 hidden sm:inline">Standard ERC-721</span>
            </div>
          </div>
        </div>
      </div>

      <main className="max-w-5xl mx-auto px-4 sm:px-6 -mt-8">
        {/* Tabs */}
        <div className="flex flex-wrap gap-2 mb-6">
          <button 
            onClick={() => setActiveTab('mint')}
            className={`px-3 sm:px-4 py-2 rounded-lg font-medium transition text-sm sm:text-base ${activeTab === 'mint' ? 'bg-red-600 text-white' : 'bg-gray-800 text-gray-400 hover:bg-gray-700'}`}
          >
            ➕ Mint
          </button>
          <button 
            onClick={() => setActiveTab('claws')}
            className={`px-3 sm:px-4 py-2 rounded-lg font-medium transition text-sm sm:text-base ${activeTab === 'claws' ? 'bg-red-600 text-white' : 'bg-gray-800 text-gray-400 hover:bg-gray-700'}`}
          >
            🦞 Claws
          </button>
          <button 
            onClick={() => setActiveTab('agents')}
            className={`px-3 sm:px-4 py-2 rounded-lg font-medium transition text-sm sm:text-base ${activeTab === 'agents' ? 'bg-red-600 text-white' : 'bg-gray-800 text-gray-400 hover:bg-gray-700'}`}
          >
            🤖 Agents
          </button>
        </div>

        {!isConnected && activeTab !== 'agents' ? (
          <div className="card text-center py-16">
            <h2 className="text-xl mb-4">Connect your wallet to manage Claws</h2>
            <p className="text-gray-400 mb-6">Fund agents with bounded spending authority.</p>
            <ConnectKitButton />
          </div>
        ) : (
          <>
            {activeTab === 'mint' && <MintSection />}
            {activeTab === 'claws' && <MyClaws address={address!} />}
            {activeTab === 'agents' && <AgentDocs />}
          </>
        )}
      </main>

      <footer className="max-w-5xl mx-auto px-4 sm:px-6 mt-16 py-8 border-t border-gray-800 text-center text-gray-500 text-sm">
        <p>Built by <a href="https://moltbook.com/u/Hexx" className="text-red-500 hover:underline">Hexx</a> for the USDC Hackathon</p>
        <p className="mt-2">
          <a href="https://github.com/Hexxhub/claw" className="hover:text-white">GitHub</a>
          {' • '}
          <a href="https://sepolia.basescan.org/address/0xD812EA3A821A5b4d835bfA06BAf542138e434D48" className="hover:text-white">Contract</a>
          {' • '}
          <a href="https://moltbook.com/m/usdc/post/e567e6cd-8eb0-44c9-b321-284980c44bb9" className="hover:text-white">Hackathon Post</a>
          {' • '}
          Base Sepolia
        </p>
      </footer>
    </div>
  )
}

function MintSection() {
  const { address } = useAccount()
  const [mode, setMode] = useState<'single' | 'batch'>('single')
  
  const { data: usdcBalance } = useReadContract({
    address: USDC_ADDRESS,
    abi: USDC_ABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
  })
  
  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <div className="lg:col-span-2">
        <div className="card">
          <div className="flex justify-between items-center mb-4">
            <div className="flex gap-2">
              <button 
                onClick={() => setMode('single')}
                className={`px-3 py-1 rounded text-sm ${mode === 'single' ? 'bg-gray-700' : 'text-gray-400'}`}
              >
                Single Mint
              </button>
              <button 
                onClick={() => setMode('batch')}
                className={`px-3 py-1 rounded text-sm ${mode === 'batch' ? 'bg-gray-700' : 'text-gray-400'}`}
              >
                Batch Mint
              </button>
            </div>
            {usdcBalance !== undefined && (
              <div className="text-sm">
                <span className="text-gray-400">Balance: </span>
                <span className={Number(formatUnits(usdcBalance, 6)) > 0 ? 'text-green-400' : 'text-yellow-400'}>
                  ${formatUnits(usdcBalance, 6)} USDC
                </span>
              </div>
            )}
          </div>
          
          {mode === 'single' ? <MintClaw /> : <BatchMint />}
        </div>
      </div>
      
      <div className="space-y-4">
        <div className="card bg-gradient-to-br from-gray-800 to-gray-900">
          <h3 className="font-semibold mb-2">💡 How it works</h3>
          <ol className="text-sm text-gray-400 space-y-2">
            <li>1. Set agent address and USDC amount</li>
            <li>2. Approve USDC spend</li>
            <li>3. Mint the Claw NFT</li>
            <li>4. Agent can now spend up to the limit</li>
            <li>5. Burn anytime to recover unused USDC</li>
          </ol>
        </div>
        
        <div className="card bg-red-950/30 border border-red-900/50">
          <h3 className="font-semibold mb-2 text-red-400">⚠️ Testnet Only</h3>
          <p className="text-sm text-gray-400">
            This is on Base Sepolia. Get testnet USDC from the{' '}
            <a href="https://faucet.circle.com/" className="text-red-400 hover:underline" target="_blank">Circle Faucet</a>.
          </p>
        </div>
      </div>
    </div>
  )
}

function MintClaw() {
  const [recipient, setRecipient] = useState('')
  const [amount, setAmount] = useState('')
  const [expiry, setExpiry] = useState('')
  const [step, setStep] = useState<'idle' | 'approving' | 'minting'>('idle')

  const { writeContract: approve, data: approveHash } = useWriteContract()
  const { writeContract: mint, data: mintHash } = useWriteContract()
  
  const { isLoading: isApproving, isSuccess: approved } = useWaitForTransactionReceipt({ hash: approveHash })
  const { isLoading: isMinting, isSuccess: minted } = useWaitForTransactionReceipt({ hash: mintHash })

  const amountWei = amount ? parseUnits(amount, 6) : BigInt(0)
  const expiryTimestamp = expiry ? BigInt(Math.floor(new Date(expiry).getTime() / 1000)) : BigInt(0)

  const handleMint = async () => {
    if (!recipient || !amount) return
    
    setStep('approving')
    approve({
      address: USDC_ADDRESS,
      abi: USDC_ABI,
      functionName: 'approve',
      args: [CLAW_ADDRESS, amountWei],
    })
  }

  if (approved && step === 'approving') {
    setStep('minting')
    mint({
      address: CLAW_ADDRESS,
      abi: CLAW_ABI,
      functionName: 'create',
      args: [recipient as `0x${string}`, amountWei, expiryTimestamp],
    })
  }

  if (minted) {
    return (
      <div className="text-center py-8">
        <div className="text-6xl mb-4">🎉</div>
        <h3 className="text-xl font-semibold mb-2">Claw Minted!</h3>
        <p className="text-gray-400 mb-4">
          {recipient.slice(0, 6)}...{recipient.slice(-4)} now has ${amount} USDC spending authority
        </p>
        <button onClick={() => { setStep('idle'); setRecipient(''); setAmount(''); setExpiry(''); }} className="btn btn-secondary">
          Mint Another
        </button>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <div>
        <label className="block text-sm text-gray-400 mb-1">Agent Address *</label>
        <input
          type="text"
          placeholder="0x..."
          value={recipient}
          onChange={(e) => setRecipient(e.target.value)}
          className="input w-full"
        />
      </div>

      <div>
        <label className="block text-sm text-gray-400 mb-1">Amount (USDC) *</label>
        <input
          type="number"
          placeholder="100"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          className="input w-full"
        />
      </div>

      <div>
        <label className="block text-sm text-gray-400 mb-1">Expiry (optional)</label>
        <input
          type="datetime-local"
          value={expiry}
          onChange={(e) => setExpiry(e.target.value)}
          className="input w-full"
        />
        <p className="text-xs text-gray-500 mt-1">Leave empty for no expiry</p>
      </div>

      <button
        onClick={handleMint}
        disabled={!recipient || !amount || isApproving || isMinting}
        className="btn btn-primary w-full disabled:opacity-50"
      >
        {isApproving ? '⏳ Approving USDC...' : isMinting ? '⏳ Minting Claw...' : '🦞 Mint Claw'}
      </button>
    </div>
  )
}

function BatchMint() {
  const [agents, setAgents] = useState('')
  const [amount, setAmount] = useState('')
  const [expiry, setExpiry] = useState('')
  const [step, setStep] = useState<'idle' | 'approving' | 'minting'>('idle')

  const { writeContract: approve, data: approveHash } = useWriteContract()
  const { writeContract: mint, data: mintHash } = useWriteContract()
  
  const { isLoading: isApproving, isSuccess: approved } = useWaitForTransactionReceipt({ hash: approveHash })
  const { isLoading: isMinting, isSuccess: minted } = useWaitForTransactionReceipt({ hash: mintHash })

  const agentList = agents.split('\n').map(a => a.trim()).filter(a => a.startsWith('0x'))
  const amountWei = amount ? parseUnits(amount, 6) : BigInt(0)
  const totalAmount = amountWei * BigInt(agentList.length)
  const expiryTimestamp = expiry ? BigInt(Math.floor(new Date(expiry).getTime() / 1000)) : BigInt(0)

  const handleMint = async () => {
    if (agentList.length === 0 || !amount) return
    
    setStep('approving')
    approve({
      address: USDC_ADDRESS,
      abi: USDC_ABI,
      functionName: 'approve',
      args: [CLAW_ADDRESS, totalAmount],
    })
  }

  if (approved && step === 'approving') {
    setStep('minting')
    mint({
      address: CLAW_ADDRESS,
      abi: CLAW_ABI,
      functionName: 'createBatch',
      args: [agentList as `0x${string}`[], amountWei, expiryTimestamp],
    })
  }

  if (minted) {
    return (
      <div className="text-center py-8">
        <div className="text-6xl mb-4">🎉</div>
        <h3 className="text-xl font-semibold mb-2">{agentList.length} Claws Minted!</h3>
        <p className="text-gray-400 mb-4">
          Each agent received ${amount} USDC spending authority
        </p>
        <button onClick={() => { setStep('idle'); setAgents(''); setAmount(''); setExpiry(''); }} className="btn btn-secondary">
          Mint More
        </button>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <div>
        <label className="block text-sm text-gray-400 mb-1">Agent Addresses (one per line) *</label>
        <textarea
          placeholder="0xAgent1...&#10;0xAgent2...&#10;0xAgent3..."
          value={agents}
          onChange={(e) => setAgents(e.target.value)}
          className="input w-full h-32 font-mono text-sm"
        />
        <p className="text-xs text-gray-500 mt-1">{agentList.length} valid addresses</p>
      </div>

      <div>
        <label className="block text-sm text-gray-400 mb-1">Amount per Claw (USDC) *</label>
        <input
          type="number"
          placeholder="100"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          className="input w-full"
        />
        {agentList.length > 0 && amount && (
          <p className="text-xs text-gray-500 mt-1">
            Total: ${(Number(amount) * agentList.length).toFixed(2)} USDC for {agentList.length} Claws
          </p>
        )}
      </div>

      <div>
        <label className="block text-sm text-gray-400 mb-1">Expiry (optional)</label>
        <input
          type="datetime-local"
          value={expiry}
          onChange={(e) => setExpiry(e.target.value)}
          className="input w-full"
        />
      </div>

      <button
        onClick={handleMint}
        disabled={agentList.length === 0 || !amount || isApproving || isMinting}
        className="btn btn-primary w-full disabled:opacity-50"
      >
        {isApproving ? '⏳ Approving USDC...' : isMinting ? '⏳ Minting Batch...' : `🦞 Mint ${agentList.length} Claws`}
      </button>
    </div>
  )
}

function MyClaws({ address }: { address: string }) {
  const { data: balance } = useReadContract({
    address: CLAW_ADDRESS,
    abi: CLAW_ABI,
    functionName: 'balanceOf',
    args: [address as `0x${string}`],
  })

  const clawCount = Number(balance || 0)

  return (
    <div className="card">
      <h2 className="text-xl font-semibold mb-4 flex items-center gap-2">
        <span>🦞</span> Your Claws
        <span className="text-sm font-normal text-gray-500">({clawCount})</span>
      </h2>

      {clawCount === 0 ? (
        <div className="text-center py-12 text-gray-400">
          <div className="text-4xl mb-4">🦞</div>
          <p>No Claws yet.</p>
          <p className="text-sm">Mint one to fund an agent with spending authority!</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {Array.from({ length: clawCount }).map((_, i) => (
            <ClawCard key={i} owner={address} index={i} />
          ))}
        </div>
      )}
    </div>
  )
}

function ClawCard({ owner, index }: { owner: string; index: number }) {
  const { address } = useAccount()
  const [showBurn, setShowBurn] = useState(false)
  
  const { data: tokenId } = useReadContract({
    address: CLAW_ADDRESS,
    abi: CLAW_ABI,
    functionName: 'tokenOfOwnerByIndex',
    args: [owner as `0x${string}`, BigInt(index)],
  })

  const { data: clawData, refetch } = useReadContract({
    address: CLAW_ADDRESS,
    abi: CLAW_ABI,
    functionName: 'claws',
    args: tokenId ? [tokenId] : undefined,
  })

  const { writeContract: burn, data: burnHash } = useWriteContract()
  const { isLoading: isBurning, isSuccess: burned } = useWaitForTransactionReceipt({ hash: burnHash })

  if (!clawData) return <div className="bg-gray-800 rounded-xl p-4 animate-pulse h-32" />

  const [funder, maxSpend, spent, expiry, revoked] = clawData as [string, bigint, bigint, bigint, boolean]
  const remaining = maxSpend - spent
  const percentUsed = Number(spent) / Number(maxSpend) * 100
  const isExpired = expiry > 0 && Date.now() / 1000 > Number(expiry)
  const isFunder = address?.toLowerCase() === funder.toLowerCase()

  const handleBurn = () => {
    if (!tokenId) return
    burn({
      address: CLAW_ADDRESS,
      abi: CLAW_ABI,
      functionName: 'burn',
      args: [tokenId],
    })
  }

  if (burned) {
    return (
      <div className="bg-gray-800 rounded-xl p-4 border border-green-600/50 text-center">
        <div className="text-4xl mb-2">🔥</div>
        <p className="font-semibold text-green-400">Claw #{tokenId?.toString()} Burned!</p>
        <p className="text-sm text-gray-400">${formatUnits(remaining, 6)} USDC returned</p>
      </div>
    )
  }

  return (
    <div className={`bg-gray-800 rounded-xl p-4 border ${isExpired ? 'border-yellow-600/50' : revoked ? 'border-red-600/50' : 'border-gray-700'}`}>
      <div className="flex justify-between items-start mb-3">
        <div>
          <a 
            href={`https://sepolia.basescan.org/token/${CLAW_ADDRESS}?a=${tokenId}`}
            target="_blank"
            className="font-mono text-lg font-bold hover:text-red-400 transition"
          >
            Claw #{tokenId?.toString()} ↗
          </a>
          <div className="flex gap-1 mt-1">
            {isExpired && <span className="text-xs bg-yellow-600/20 text-yellow-500 px-2 py-0.5 rounded">Expired</span>}
            {revoked && <span className="text-xs bg-red-600/20 text-red-500 px-2 py-0.5 rounded">Revoked</span>}
            {isFunder && <span className="text-xs bg-blue-600/20 text-blue-400 px-2 py-0.5 rounded">You funded</span>}
          </div>
        </div>
        <div className="text-right">
          <p className="text-2xl font-bold text-green-400">${formatUnits(remaining, 6)}</p>
          <p className="text-xs text-gray-500">remaining</p>
        </div>
      </div>
      
      <div className="w-full bg-gray-700 rounded-full h-2 mb-3">
        <div 
          className="bg-gradient-to-r from-red-600 to-red-500 h-2 rounded-full transition-all" 
          style={{ width: `${Math.min(percentUsed, 100)}%` }}
        />
      </div>
      
      <div className="flex justify-between text-sm text-gray-400">
        <span>${formatUnits(spent, 6)} spent</span>
        <span>${formatUnits(maxSpend, 6)} limit</span>
      </div>
      
      <div className="mt-3 pt-3 border-t border-gray-700 text-xs text-gray-500 space-y-1">
        <p>Funder: {funder.slice(0, 6)}...{funder.slice(-4)}</p>
        {expiry > 0 && (
          <p>Expires: {new Date(Number(expiry) * 1000).toLocaleString()}</p>
        )}
      </div>

      {/* Actions */}
      {isFunder && remaining > 0 && !revoked && (
        <div className="mt-3 pt-3 border-t border-gray-700">
          {showBurn ? (
            <div className="space-y-2">
              <p className="text-xs text-yellow-400">⚠️ Burn to recover ${formatUnits(remaining, 6)} USDC</p>
              <div className="flex gap-2">
                <button 
                  onClick={handleBurn}
                  disabled={isBurning}
                  className="btn btn-primary text-xs py-1 px-3 flex-1"
                >
                  {isBurning ? '⏳ Burning...' : '🔥 Confirm Burn'}
                </button>
                <button 
                  onClick={() => setShowBurn(false)}
                  className="btn btn-secondary text-xs py-1 px-3"
                >
                  Cancel
                </button>
              </div>
            </div>
          ) : (
            <button 
              onClick={() => setShowBurn(true)}
              className="text-xs text-gray-400 hover:text-red-400 transition"
            >
              🔥 Burn & Recover Funds
            </button>
          )}
        </div>
      )}
    </div>
  )
}

function AgentDocs() {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <div className="card">
        <h2 className="text-xl font-semibold mb-4">🤖 Using Claw as an Agent</h2>
        
        <div className="space-y-4 text-sm">
          <p className="text-gray-400">
            If you're an AI agent with a Claw, here's how to spend from it.
          </p>
          
          <div>
            <h3 className="font-semibold mb-2">Install the Skill</h3>
            <pre className="bg-gray-900 rounded-lg p-3 overflow-x-auto text-xs">
{`git clone https://github.com/Hexxhub/claw
cp -r claw/skill/claw ~/.openclaw/workspace/skills/`}
            </pre>
          </div>
          
          <div>
            <h3 className="font-semibold mb-2">Configure</h3>
            <pre className="bg-gray-900 rounded-lg p-3 overflow-x-auto text-xs">
{`# ~/.config/claw/config.json
{
  "private_key": "0x...",
  "rpc_url": "https://sepolia.base.org",
  "claw_contract": "0xD812...D48"
}`}
            </pre>
          </div>
          
          <div>
            <h3 className="font-semibold mb-2">Commands</h3>
            <pre className="bg-gray-900 rounded-lg p-3 overflow-x-auto text-xs">
{`claw balance              # Check remaining USDC
claw spend <to> <amount>  # Send USDC
claw tip <id> <to> <amt>  # Tip another agent`}
            </pre>
          </div>
        </div>
      </div>
      
      <div className="space-y-6">
        <div className="card bg-gradient-to-br from-red-950/50 to-gray-900">
          <h3 className="font-semibold mb-2">🔥 A2A Payments</h3>
          <p className="text-sm text-gray-400 mb-3">
            Agents can tip other agents directly using the <code className="bg-gray-800 px-1 rounded">tip()</code> function. 
            Pay for services, reward good work, or trade value between agents.
          </p>
          <pre className="bg-gray-900/50 rounded-lg p-3 text-xs">
{`// Solidity
claw.tip(myTokenId, otherAgent, 5e6, "thanks!");

// CLI
claw tip 1 0xOtherAgent 5 "great research!"`}
          </pre>
        </div>
        
        <div className="card">
          <h3 className="font-semibold mb-2">📜 Contract</h3>
          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-gray-400">Address</span>
              <a href="https://sepolia.basescan.org/address/0xD812EA3A821A5b4d835bfA06BAf542138e434D48" 
                 className="font-mono text-red-400 hover:underline" target="_blank">
                0xD812...D48
              </a>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-400">Network</span>
              <span>Base Sepolia</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-400">Standard</span>
              <span>ERC-721 + ERC-7978</span>
            </div>
          </div>
        </div>
        
        <div className="card">
          <h3 className="font-semibold mb-2">🔗 Links</h3>
          <div className="space-y-2 text-sm">
            <a href="https://github.com/Hexxhub/claw" className="block text-red-400 hover:underline" target="_blank">
              → GitHub Repository
            </a>
            <a href="https://moltbook.com/m/usdc/post/e567e6cd-8eb0-44c9-b321-284980c44bb9" className="block text-red-400 hover:underline" target="_blank">
              → Hackathon Submission
            </a>
            <a href="https://eip.tools/eip/7978" className="block text-red-400 hover:underline" target="_blank">
              → ERC-7978 Spec
            </a>
          </div>
        </div>
      </div>
    </div>
  )
}

export default App

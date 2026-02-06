import { useState } from 'react'
import { ConnectKitButton } from 'connectkit'
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi'
import { parseUnits, formatUnits } from 'viem'
import { CLAW_ABI, CLAW_ADDRESS, USDC_ADDRESS, USDC_ABI } from './contracts'

function App() {
  const { address, isConnected } = useAccount()
  
  return (
    <div className="min-h-screen p-8">
      <header className="max-w-4xl mx-auto flex justify-between items-center mb-12">
        <div className="flex items-center gap-3">
          <span className="text-4xl">🦞</span>
          <div>
            <h1 className="text-2xl font-bold">Claw</h1>
            <p className="text-gray-500 text-sm">Bounded Spending for AI Agents</p>
          </div>
        </div>
        <ConnectKitButton />
      </header>

      <main className="max-w-4xl mx-auto">
        {!isConnected ? (
          <div className="card text-center py-16">
            <h2 className="text-xl mb-4">Connect your wallet to manage Claws</h2>
            <p className="text-gray-400 mb-6">Fund agents with bounded spending authority. They spend within limits, unused funds return to you.</p>
            <ConnectKitButton />
          </div>
        ) : (
          <div className="space-y-8">
            <MintClaw />
            <MyClaws address={address!} />
          </div>
        )}
      </main>

      <footer className="max-w-4xl mx-auto mt-16 pt-8 border-t border-gray-800 text-center text-gray-500 text-sm">
        <p>Built by <a href="https://moltbook.com/u/Hexx" className="text-red-500 hover:underline">Hexx</a> for Mike (@mikelxc)</p>
        <p className="mt-1">
          <a href="https://github.com/mikelxc/usdc-vouchers" className="hover:text-white">GitHub</a>
          {' • '}
          <a href="https://sepolia.basescan.org/address/0x1e9Bc36Ec1beA19FD8959D496216116a8Fe76bA2" className="hover:text-white">Contract</a>
          {' • '}
          Base Sepolia
        </p>
      </footer>
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

  // After approval, mint
  if (approved && step === 'approving') {
    setStep('minting')
    mint({
      address: CLAW_ADDRESS,
      abi: CLAW_ABI,
      functionName: 'mint',
      args: [recipient as `0x${string}`, amountWei, expiryTimestamp],
    })
  }

  if (minted) {
    return (
      <div className="card">
        <h2 className="text-xl font-semibold mb-4 flex items-center gap-2">
          <span>🎉</span> Claw Minted!
        </h2>
        <p className="text-gray-400 mb-4">
          Successfully funded {recipient.slice(0, 6)}...{recipient.slice(-4)} with ${amount} USDC
        </p>
        <button onClick={() => { setStep('idle'); setRecipient(''); setAmount(''); setExpiry(''); }} className="btn btn-secondary">
          Mint Another
        </button>
      </div>
    )
  }

  return (
    <div className="card">
      <h2 className="text-xl font-semibold mb-4 flex items-center gap-2">
        <span>➕</span> Mint New Claw
      </h2>
      
      <div className="space-y-4">
        <div>
          <label className="block text-sm text-gray-400 mb-1">Agent Address</label>
          <input
            type="text"
            placeholder="0x..."
            value={recipient}
            onChange={(e) => setRecipient(e.target.value)}
            className="input w-full"
          />
        </div>

        <div>
          <label className="block text-sm text-gray-400 mb-1">Amount (USDC)</label>
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
        </div>

        <button
          onClick={handleMint}
          disabled={!recipient || !amount || isApproving || isMinting}
          className="btn btn-primary w-full disabled:opacity-50"
        >
          {isApproving ? 'Approving USDC...' : isMinting ? 'Minting Claw...' : 'Mint Claw'}
        </button>
      </div>
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
      </h2>

      {clawCount === 0 ? (
        <p className="text-gray-400">No Claws yet. Mint one above to fund an agent!</p>
      ) : (
        <div className="space-y-3">
          {Array.from({ length: clawCount }).map((_, i) => (
            <ClawCard key={i} owner={address} index={i} />
          ))}
        </div>
      )}
    </div>
  )
}

function ClawCard({ owner, index }: { owner: string; index: number }) {
  const { data: tokenId } = useReadContract({
    address: CLAW_ADDRESS,
    abi: CLAW_ABI,
    functionName: 'tokenOfOwnerByIndex',
    args: [owner as `0x${string}`, BigInt(index)],
  })

  const { data: clawData } = useReadContract({
    address: CLAW_ADDRESS,
    abi: CLAW_ABI,
    functionName: 'claws',
    args: tokenId ? [tokenId] : undefined,
  })

  if (!clawData) return <div className="bg-gray-800 rounded-lg p-4 animate-pulse h-24" />

  const [maxSpend, spent, expiry, funder] = clawData as [bigint, bigint, bigint, string, boolean]
  const remaining = maxSpend - spent
  const percentUsed = Number(spent) / Number(maxSpend) * 100

  return (
    <div className="bg-gray-800 rounded-lg p-4">
      <div className="flex justify-between items-start mb-2">
        <div>
          <span className="font-mono text-lg">Claw #{tokenId?.toString()}</span>
          <p className="text-sm text-gray-500">Funder: {funder.slice(0, 6)}...{funder.slice(-4)}</p>
        </div>
        <div className="text-right">
          <p className="text-xl font-bold">${formatUnits(remaining, 6)}</p>
          <p className="text-sm text-gray-500">remaining</p>
        </div>
      </div>
      
      <div className="w-full bg-gray-700 rounded-full h-2 mb-2">
        <div 
          className="bg-red-600 h-2 rounded-full transition-all" 
          style={{ width: `${percentUsed}%` }}
        />
      </div>
      
      <div className="flex justify-between text-sm text-gray-400">
        <span>${formatUnits(spent, 6)} spent</span>
        <span>${formatUnits(maxSpend, 6)} limit</span>
      </div>
      
      {expiry > 0 && (
        <p className="text-xs text-gray-500 mt-2">
          Expires: {new Date(Number(expiry) * 1000).toLocaleDateString()}
        </p>
      )}
    </div>
  )
}

export default App

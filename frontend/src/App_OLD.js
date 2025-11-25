// ========================================
// DEBUGGING VERSION - Find your pools!
// Enter transaction hash to locate pool
// ========================================

import React, { useState, useEffect } from 'react'
import { ethers } from 'ethers'

const App = () => {
  // State
  const [account, setAccount] = useState('')
  const [balance, setBalance] = useState('0')
  const [provider, setProvider] = useState(null)
  const [signer, setSigner] = useState(null)
  const [loading, setLoading] = useState(false)
  const [currentView, setCurrentView] = useState('dashboard')

  // User data
  const [userTier, setUserTier] = useState('NON_COMPLIANT')
  const [riskScore, setRiskScore] = useState(0)
  const [isOwner, setIsOwner] = useState(false)

  // Pool data
  const [pools, setPools] = useState([])
  const [loadingPools, setLoadingPools] = useState(false)
  const [newPoolTier, setNewPoolTier] = useState('0')
  const [newPoolWhitelist, setNewPoolWhitelist] = useState(false)

  // Debug
  const [debugTxHash, setDebugTxHash] = useState(
    '0x7cec71210026827ce491765ea6f2b4170d51015726ea5b0e155ccb8ae6f406ae'
  )
  const [debugInfo, setDebugInfo] = useState('')

  // Swap
  const [swapAmount, setSwapAmount] = useState('0.01')
  const [swapStatus, setSwapStatus] = useState('')

  // Stats
  const [poolStats, setPoolStats] = useState({
    total: 0,
    public: 0,
    verified: 0,
    institutional: 0
  })

  // Contract addresses
  const CONTRACTS = {
    hook: '0x96151b6acdfd9d8c8116e44100e28030aaefcbb8',
    poolManager: '0x7Da1D65F8B249183667cdE74C5CBD46dD38AA829',
    riskCalculator: '0xa78751349D496a726dCfde91bec2C5BE9b52f31E',
    token0: '0x980B62Da83eFf3D4576C647993b0c1D7faf17c73',
    token1: '0x8FB1E3fC51F3b789dED7557E680551d93Ea9d892'
  }

  // ABIs
  const HOOK_ABI = [
    'function getUserComplianceLevel(address) external view returns (string)',
    'function owner() external view returns (address)',
    'function getPoolStats() external view returns (uint256, uint256, uint256, uint256)',
    'function poolConfigs(bytes32) external view returns (uint8 tier, address creator, bool requiresWhitelist, uint256 protocolFeeBps, uint256 createdAt)',
    'event PoolRegistered(bytes32 indexed poolId, uint8 tier, address creator)',
    'function beforeInitialize(address, tuple(address,address,uint24,int24,address), uint160, bytes) external returns (bytes4)'
  ]

  const POOL_MANAGER_ABI = [
    'function initialize(tuple(address currency0, address currency1, uint24 fee, int24 tickSpacing, address hooks) key, uint160 sqrtPriceX96, bytes) external returns (int24)',
    'function swap(tuple(address currency0, address currency1, uint24 fee, int24 tickSpacing, address hooks) key, tuple(bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96) params, bytes) external returns (int256, int256)',
    'event Initialize(bytes32 indexed id, address indexed currency0, address indexed currency1, uint24 fee, int24 tickSpacing, address hooks)'
  ]

  const RISK_CALCULATOR_ABI = [
    'function calculateRisk(address) external returns (uint256)',
    'function getUserRiskScore(address) external view returns (uint256, uint256)'
  ]

  const ERC20_ABI = [
    'function approve(address,uint256) external returns (bool)'
  ]

  // Connect Wallet
  const connectWallet = async () => {
    try {
      if (!window.ethereum) {
        alert('Please install MetaMask!')
        return
      }

      const accounts = await window.ethereum.request({
        method: 'eth_requestAccounts'
      })
      const web3Provider = new ethers.BrowserProvider(window.ethereum)
      const web3Signer = await web3Provider.getSigner()

      const network = await web3Provider.getNetwork()
      if (network.chainId !== 421614n) {
        try {
          await window.ethereum.request({
            method: 'wallet_switchEthereumChain',
            params: [{ chainId: '0x66eee' }]
          })
        } catch (switchError) {
          if (switchError.code === 4902) {
            await window.ethereum.request({
              method: 'wallet_addEthereumChain',
              params: [
                {
                  chainId: '0x66eee',
                  chainName: 'Arbitrum Sepolia',
                  nativeCurrency: { name: 'ETH', symbol: 'ETH', decimals: 18 },
                  rpcUrls: ['https://sepolia-rollup.arbitrum.io/rpc'],
                  blockExplorerUrls: ['https://sepolia.arbiscan.io/']
                }
              ]
            })
          }
        }
      }

      const userBalance = await web3Provider.getBalance(accounts[0])
      setAccount(accounts[0])
      setBalance(ethers.formatEther(userBalance))
      setProvider(web3Provider)
      setSigner(web3Signer)

      await fetchUserData(web3Provider, accounts[0])
      await fetchPoolStats(web3Provider)
      await loadRealPools(web3Provider)
    } catch (error) {
      console.error('Connection error:', error)
      alert('Failed to connect: ' + error.message)
    }
  }

  // Fetch user data
  const fetchUserData = async (web3Provider, address) => {
    try {
      const hookContract = new ethers.Contract(
        CONTRACTS.hook,
        HOOK_ABI,
        web3Provider
      )
      const riskContract = new ethers.Contract(
        CONTRACTS.riskCalculator,
        RISK_CALCULATOR_ABI,
        web3Provider
      )

      const tier = await hookContract.getUserComplianceLevel(address)
      setUserTier(tier)

      const [score] = await riskContract.getUserRiskScore(address)
      setRiskScore(Number(score))

      const owner = await hookContract.owner()
      setIsOwner(owner.toLowerCase() === address.toLowerCase())
    } catch (error) {
      console.error('Error fetching user data:', error)
    }
  }

  // Fetch pool stats
  const fetchPoolStats = async web3Provider => {
    try {
      const hookContract = new ethers.Contract(
        CONTRACTS.hook,
        HOOK_ABI,
        web3Provider
      )
      const [total, publicCount, verifiedCount, institutionalCount] =
        await hookContract.getPoolStats()

      setPoolStats({
        total: Number(total),
        public: Number(publicCount),
        verified: Number(verifiedCount),
        institutional: Number(institutionalCount)
      })
    } catch (error) {
      console.error('Error fetching stats:', error)
    }
  }

  // 🔍 DEBUG: Analyze transaction
  const analyzeTransaction = async () => {
    if (!provider) {
      alert('Connect wallet first!')
      return
    }

    setLoading(true)
    let debug = '🔍 ANALYZING TRANSACTION...\n\n'

    try {
      debug += `Transaction: ${debugTxHash}\n\n`

      // Get transaction receipt
      const receipt = await provider.getTransactionReceipt(debugTxHash)

      if (!receipt) {
        debug += '❌ Transaction not found!\n'
        setDebugInfo(debug)
        setLoading(false)
        return
      }

      debug += `✅ Transaction found\n`
      debug += `Block: ${receipt.blockNumber}\n`
      debug += `Status: ${receipt.status === 1 ? 'SUCCESS' : 'FAILED'}\n\n`

      // Parse logs
      const hookContract = new ethers.Contract(
        CONTRACTS.hook,
        HOOK_ABI,
        provider
      )
      const poolManagerContract = new ethers.Contract(
        CONTRACTS.poolManager,
        POOL_MANAGER_ABI,
        provider
      )

      debug += `📋 ANALYZING ${receipt.logs.length} LOGS:\n\n`

      let foundPoolId = null
      let foundPoolRegistered = false

      for (let i = 0; i < receipt.logs.length; i++) {
        const log = receipt.logs[i]
        debug += `Log ${i}:\n`
        debug += `  Address: ${log.address}\n`
        debug += `  Topics: ${log.topics.length}\n`

        // Try to parse as Initialize event from PoolManager
        if (log.address.toLowerCase() === CONTRACTS.poolManager.toLowerCase()) {
          try {
            const parsed = poolManagerContract.interface.parseLog(log)
            if (parsed && parsed.name === 'Initialize') {
              foundPoolId = parsed.args.id
              debug += `  ✅ POOL INITIALIZE EVENT FOUND!\n`
              debug += `  Pool ID: ${foundPoolId}\n`
              debug += `  Currency0: ${parsed.args.currency0}\n`
              debug += `  Currency1: ${parsed.args.currency1}\n`
              debug += `  Fee: ${parsed.args.fee}\n`
              debug += `  Hook: ${parsed.args.hooks}\n\n`
            }
          } catch (e) {
            debug += `  (Not Initialize event)\n`
          }
        }

        // Try to parse as PoolRegistered from Hook
        if (log.address.toLowerCase() === CONTRACTS.hook.toLowerCase()) {
          try {
            const parsed = hookContract.interface.parseLog(log)
            if (parsed && parsed.name === 'PoolRegistered') {
              foundPoolRegistered = true
              debug += `  ✅ POOL REGISTERED EVENT FOUND!\n`
              debug += `  Pool ID: ${parsed.args.poolId}\n`
              debug += `  Tier: ${parsed.args.tier}\n`
              debug += `  Creator: ${parsed.args.creator}\n\n`
            }
          } catch (e) {
            debug += `  (Not PoolRegistered event)\n`
          }
        }

        debug += `\n`
      }

      debug += `\n📊 SUMMARY:\n`
      debug += `Pool ID found: ${foundPoolId ? 'YES ✅' : 'NO ❌'}\n`
      debug += `PoolRegistered event: ${
        foundPoolRegistered ? 'YES ✅' : 'NO ❌'
      }\n\n`

      // If we found pool ID, try to query it
      if (foundPoolId) {
        debug += `\n🔎 QUERYING POOL CONFIG:\n`
        try {
          const config = await hookContract.poolConfigs(foundPoolId)
          debug += `✅ Pool config found!\n`
          debug += `  Tier: ${config.tier}\n`
          debug += `  Creator: ${config.creator}\n`
          debug += `  RequiresWhitelist: ${config.requiresWhitelist}\n`
          debug += `  CreatedAt: ${config.createdAt}\n`

          if (Number(config.createdAt) === 0) {
            debug += `\n❌ PROBLEM: Pool not registered in hook!\n`
            debug += `The pool exists in PoolManager but your hook didn't register it.\n`
            debug += `This means beforeInitialize() might not have been called properly.\n`
          } else {
            debug += `\n✅ Pool is registered! It should appear in Browse Pools.\n`

            // Try to add it to pools
            const tierNames = ['PUBLIC', 'VERIFIED', 'INSTITUTIONAL']
            const pool = {
              id: foundPoolId,
              name: 'WETH/USDC',
              tier: tierNames[Number(config.tier)],
              creator: config.creator,
              requiresWhitelist: config.requiresWhitelist,
              protocolFee: Number(config.protocolFeeBps) / 100,
              createdAt: new Date(
                Number(config.createdAt) * 1000
              ).toLocaleString(),
              fee: '0.3%'
            }

            setPools([pool])
            debug += `\n✅ POOL ADDED TO LIST!\n`
          }
        } catch (error) {
          debug += `❌ Error querying pool config: ${error.message}\n`
        }
      } else {
        debug += `\n❌ PROBLEM: No pool ID found in transaction logs!\n`
        debug += `This transaction didn't create a pool, or the Initialize event wasn't emitted.\n`
      }

      setDebugInfo(debug)
    } catch (error) {
      debug += `\n❌ ERROR: ${error.message}\n`
      setDebugInfo(debug)
    } finally {
      setLoading(false)
    }
  }

  // Load real pools
  const loadRealPools = async web3Provider => {
    setLoadingPools(true)
    try {
      console.log('🔍 Loading pools...')

      const hookContract = new ethers.Contract(
        CONTRACTS.hook,
        HOOK_ABI,
        web3Provider
      )
      const poolManagerContract = new ethers.Contract(
        CONTRACTS.poolManager,
        POOL_MANAGER_ABI,
        web3Provider
      )

      const [total] = await hookContract.getPoolStats()
      console.log('Total pools from contract:', Number(total))

      let foundPools = []

      // Try events from PoolManager (Initialize)
      try {
        const currentBlock = await web3Provider.getBlockNumber()
        const fromBlock = Math.max(0, currentBlock - 500000) // VERY wide range

        console.log(
          `Querying PoolManager Initialize events from ${fromBlock} to ${currentBlock}`
        )

        const filter = poolManagerContract.filters.Initialize()
        const events = await poolManagerContract.queryFilter(
          filter,
          fromBlock,
          currentBlock
        )

        console.log(`Found ${events.length} Initialize events from PoolManager`)

        // Filter for events that used OUR hook
        const ourHookEvents = events.filter(
          e => e.args.hooks.toLowerCase() === CONTRACTS.hook.toLowerCase()
        )

        console.log(`Found ${ourHookEvents.length} events with our hook`)

        for (const event of ourHookEvents) {
          const poolId = event.args.id
          console.log('Checking pool:', poolId)

          try {
            const config = await hookContract.poolConfigs(poolId)

            if (Number(config.createdAt) > 0) {
              const tierNames = ['PUBLIC', 'VERIFIED', 'INSTITUTIONAL']
              foundPools.push({
                id: poolId,
                name: 'WETH/USDC',
                tier: tierNames[Number(config.tier)],
                creator: config.creator,
                requiresWhitelist: config.requiresWhitelist,
                protocolFee: Number(config.protocolFeeBps) / 100,
                createdAt: new Date(
                  Number(config.createdAt) * 1000
                ).toLocaleString(),
                fee: '0.3%',
                blockNumber: event.blockNumber
              })
            }
          } catch (err) {
            console.error('Error checking pool:', err)
          }
        }
      } catch (error) {
        console.error('Error querying events:', error)
      }

      console.log('Total pools found:', foundPools.length)
      setPools(foundPools)
    } catch (error) {
      console.error('Error loading pools:', error)
      setPools([])
    } finally {
      setLoadingPools(false)
    }
  }

  // Rest of functions...
  const runAssessment = async () => {
    if (!signer) {
      alert('Please connect wallet!')
      return
    }

    setLoading(true)
    try {
      const riskContract = new ethers.Contract(
        CONTRACTS.riskCalculator,
        RISK_CALCULATOR_ABI,
        signer
      )
      const tx = await riskContract.calculateRisk(account)
      await tx.wait()
      await fetchUserData(provider, account)
      alert('✅ Assessment completed!')
    } catch (error) {
      console.error('Assessment failed:', error)
      alert('Assessment failed: ' + error.message)
    } finally {
      setLoading(false)
    }
  }

  const createPool = async () => {
    if (!signer) {
      alert('Please connect wallet!')
      return
    }

    setLoading(true)
    try {
      const poolManagerContract = new ethers.Contract(
        CONTRACTS.poolManager,
        POOL_MANAGER_ABI,
        signer
      )

      const poolKey = {
        currency0: CONTRACTS.token0,
        currency1: CONTRACTS.token1,
        fee: 3000,
        tickSpacing: 60,
        hooks: CONTRACTS.hook
      }

      const hookData = ethers.AbiCoder.defaultAbiCoder().encode(
        ['uint8', 'bool', 'uint256'],
        [newPoolTier, newPoolWhitelist, 0]
      )

      const sqrtPriceX96 = '79228162514264337593543950336'

      console.log('Creating pool...')
      const tx = await poolManagerContract.initialize(
        poolKey,
        sqrtPriceX96,
        hookData
      )
      console.log('Transaction:', tx.hash)

      const receipt = await tx.wait()
      console.log('Confirmed!')

      // Set debug tx hash to this transaction
      setDebugTxHash(tx.hash)

      alert(
        '✅ Pool Created!\n\nTransaction: ' +
          tx.hash +
          '\n\nNow go to Debug tab and click "Analyze Transaction" to see why it might not appear.'
      )

      await fetchPoolStats(provider)
      await loadRealPools(provider)
    } catch (error) {
      console.error('Failed:', error)
      alert('❌ Failed: ' + error.message)
    } finally {
      setLoading(false)
    }
  }

  const performSwap = async () => {
    if (!signer) {
      alert('Please connect wallet!')
      return
    }

    if (pools.length === 0) {
      alert('⚠️ No pools available!')
      return
    }

    setLoading(true)
    setSwapStatus('Approving...')

    try {
      const token0Contract = new ethers.Contract(
        CONTRACTS.token0,
        ERC20_ABI,
        signer
      )
      const amount = ethers.parseEther(swapAmount)

      const approveTx = await token0Contract.approve(
        CONTRACTS.poolManager,
        amount
      )
      await approveTx.wait()

      setSwapStatus('Swapping...')

      const poolManagerContract = new ethers.Contract(
        CONTRACTS.poolManager,
        POOL_MANAGER_ABI,
        signer
      )

      const poolKey = {
        currency0: CONTRACTS.token0,
        currency1: CONTRACTS.token1,
        fee: 3000,
        tickSpacing: 60,
        hooks: CONTRACTS.hook
      }

      const swapParams = {
        zeroForOne: true,
        amountSpecified: amount,
        sqrtPriceLimitX96: '4295128739'
      }

      const tx = await poolManagerContract.swap(poolKey, swapParams, '0x')
      await tx.wait()

      setSwapStatus('✅ SUCCESS!')
      alert('✅ Swap successful!')
    } catch (error) {
      console.error('Swap failed:', error)
      setSwapStatus('❌ BLOCKED!')
      alert('❌ Swap failed: ' + error.message)
    } finally {
      setLoading(false)
    }
  }

  const canAccessPool = poolTier => {
    const hierarchy = {
      NON_COMPLIANT: 0,
      PUBLIC: 1,
      VERIFIED: 2,
      INSTITUTIONAL: 3,
      WHITELISTED: 4
    }

    const poolHierarchy = {
      PUBLIC: 1,
      VERIFIED: 2,
      INSTITUTIONAL: 3
    }

    return hierarchy[userTier] >= poolHierarchy[poolTier]
  }

  const refreshPools = async () => {
    if (provider) {
      await fetchPoolStats(provider)
      await loadRealPools(provider)
    }
  }

  useEffect(() => {
    if (account && provider) {
      fetchUserData(provider, account)
      fetchPoolStats(provider)
      loadRealPools(provider)
    }
  }, [account, provider])

  const tierInfo = getTierInfo(userTier)

  // RENDER
  return (
    <div
      style={{
        minHeight: '100vh',
        background: 'linear-gradient(to bottom, #f9fafb, #f3f4f6)',
        padding: '2rem'
      }}
    >
      <div style={{ maxWidth: '1200px', margin: '0 auto' }}>
        <div style={{ textAlign: 'center', marginBottom: '2rem' }}>
          <h1
            style={{
              fontSize: '2.5rem',
              fontWeight: 'bold',
              marginBottom: '0.5rem'
            }}
          >
            🦄 Uniswap V4 Compliance Demo
          </h1>
          <p style={{ fontSize: '1.125rem', color: '#6b7280' }}>
            DEBUG VERSION - Find Your Pools!
          </p>
        </div>

        <div
          style={{
            display: 'flex',
            gap: '0.5rem',
            justifyContent: 'center',
            marginBottom: '2rem',
            flexWrap: 'wrap'
          }}
        >
          <NavButton
            label='📊 Dashboard'
            active={currentView === 'dashboard'}
            onClick={() => setCurrentView('dashboard')}
          />
          <NavButton
            label='🏊 Browse Pools'
            active={currentView === 'pools'}
            onClick={() => setCurrentView('pools')}
          />
          <NavButton
            label='➕ Create Pool'
            active={currentView === 'create'}
            onClick={() => setCurrentView('create')}
          />
          <NavButton
            label='🔄 Swap'
            active={currentView === 'swap'}
            onClick={() => setCurrentView('swap')}
          />
          <NavButton
            label='🔍 Debug'
            active={currentView === 'debug'}
            onClick={() => setCurrentView('debug')}
          />
          {isOwner && (
            <NavButton
              label='⚙️ Admin'
              active={currentView === 'admin'}
              onClick={() => setCurrentView('admin')}
            />
          )}
        </div>

        <div
          style={{
            textAlign: 'center',
            marginBottom: '2rem',
            background: 'white',
            padding: '1.5rem',
            borderRadius: '12px',
            boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
          }}
        >
          {!account ? (
            <button onClick={connectWallet} style={styles.primaryButton}>
              Connect Wallet
            </button>
          ) : (
            <div>
              <p
                style={{
                  fontSize: '1rem',
                  color: '#6b7280',
                  marginBottom: '0.5rem'
                }}
              >
                {account.slice(0, 6)}...{account.slice(-4)} |{' '}
                {parseFloat(balance).toFixed(4)} ETH
              </p>
              <div
                style={{
                  ...styles.tierBadge,
                  background: `${tierInfo.color}15`,
                  border: `2px solid ${tierInfo.color}`
                }}
              >
                <span style={{ fontSize: '1.5rem' }}>{tierInfo.icon}</span>
                <span style={{ fontWeight: '600', color: tierInfo.color }}>
                  {tierInfo.name}
                </span>
                <span style={{ fontSize: '0.875rem', color: '#6b7280' }}>
                  | Score: {riskScore}
                </span>
              </div>
            </div>
          )}
        </div>

        {account && (
          <>
            {currentView === 'dashboard' && (
              <DashboardView
                tierInfo={tierInfo}
                riskScore={riskScore}
                poolStats={poolStats}
                runAssessment={runAssessment}
                loading={loading}
              />
            )}

            {currentView === 'pools' && (
              <BrowsePoolsView
                pools={pools}
                userTier={userTier}
                canAccessPool={canAccessPool}
                loadingPools={loadingPools}
                refreshPools={refreshPools}
              />
            )}

            {currentView === 'create' && (
              <CreatePoolView
                newPoolTier={newPoolTier}
                setNewPoolTier={setNewPoolTier}
                newPoolWhitelist={newPoolWhitelist}
                setNewPoolWhitelist={setNewPoolWhitelist}
                createPool={createPool}
                loading={loading}
              />
            )}

            {currentView === 'swap' && (
              <SwapView
                swapAmount={swapAmount}
                setSwapAmount={setSwapAmount}
                performSwap={performSwap}
                loading={loading}
                swapStatus={swapStatus}
                poolsAvailable={pools.length > 0}
              />
            )}

            {currentView === 'debug' && (
              <DebugView
                debugTxHash={debugTxHash}
                setDebugTxHash={setDebugTxHash}
                analyzeTransaction={analyzeTransaction}
                debugInfo={debugInfo}
                loading={loading}
              />
            )}

            {currentView === 'admin' && isOwner && <AdminView />}
          </>
        )}
      </div>
    </div>
  )
}

// COMPONENTS
const NavButton = ({ label, active, onClick }) => (
  <button
    onClick={onClick}
    style={{
      padding: '0.75rem 1.5rem',
      background: active ? '#ff007a' : 'white',
      color: active ? 'white' : '#1f2937',
      border: '2px solid ' + (active ? '#ff007a' : '#e5e7eb'),
      borderRadius: '8px',
      fontWeight: '600',
      cursor: 'pointer',
      fontSize: '0.875rem'
    }}
  >
    {label}
  </button>
)

const DebugView = ({
  debugTxHash,
  setDebugTxHash,
  analyzeTransaction,
  debugInfo,
  loading
}) => (
  <div>
    <Card title='🔍 Transaction Debugger'>
      <div
        style={{
          marginBottom: '1.5rem',
          padding: '1rem',
          background: '#fef3c7',
          borderRadius: '8px'
        }}
      >
        <strong>Your Transaction:</strong>{' '}
        0x7cec71210026827ce491765ea6f2b4170d51015726ea5b0e155ccb8ae6f406ae
        <br />
        <small>
          Enter this or any transaction hash to analyze why pools aren't showing
        </small>
      </div>

      <FormField label='Transaction Hash:'>
        <input
          type='text'
          value={debugTxHash}
          onChange={e => setDebugTxHash(e.target.value)}
          placeholder='0x...'
          style={styles.input}
        />
      </FormField>

      <button
        onClick={analyzeTransaction}
        disabled={loading}
        style={{
          ...styles.primaryButton,
          width: '100%',
          marginBottom: '1.5rem'
        }}
      >
        {loading ? 'Analyzing...' : '🔍 Analyze Transaction'}
      </button>

      {debugInfo && (
        <div
          style={{
            padding: '1.5rem',
            background: '#1f2937',
            color: '#10b981',
            borderRadius: '8px',
            fontFamily: 'monospace',
            fontSize: '0.875rem',
            whiteSpace: 'pre-wrap',
            overflow: 'auto',
            maxHeight: '600px'
          }}
        >
          {debugInfo}
        </div>
      )}
    </Card>

    <InfoBox
      title='💡 How This Works'
      items={[
        'Enter your transaction hash above',
        'Click "Analyze Transaction"',
        "It will tell you exactly why pools aren't showing",
        'Check if PoolRegistered event was emitted',
        'Check if hook registered the pool properly'
      ]}
    />
  </div>
)

const DashboardView = ({
  tierInfo,
  riskScore,
  poolStats,
  runAssessment,
  loading
}) => (
  <Card title='Dashboard'>
    <div
      style={{
        padding: '2rem',
        background: `${tierInfo.color}15`,
        borderRadius: '12px',
        border: `2px solid ${tierInfo.color}`,
        textAlign: 'center',
        marginBottom: '2rem'
      }}
    >
      <div style={{ fontSize: '4rem', marginBottom: '1rem' }}>
        {tierInfo.icon}
      </div>
      <div
        style={{
          fontSize: '2rem',
          fontWeight: '700',
          color: tierInfo.color,
          marginBottom: '0.5rem'
        }}
      >
        {tierInfo.name}
      </div>
      <div style={{ fontSize: '1.25rem', color: '#6b7280' }}>
        Risk Score: {riskScore}/100
      </div>
    </div>

    <div style={{ textAlign: 'center', marginBottom: '2rem' }}>
      <button
        onClick={runAssessment}
        disabled={loading}
        style={loading ? styles.disabledButton : styles.successButton}
      >
        {loading ? 'Processing...' : '🔍 Run Assessment'}
      </button>
    </div>

    <div
      style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
        gap: '1rem'
      }}
    >
      <StatCard
        label='Total'
        value={poolStats.total}
        color='#6b7280'
        icon='📊'
      />
      <StatCard
        label='Public'
        value={poolStats.public}
        color='#10b981'
        icon='🌐'
      />
      <StatCard
        label='Verified'
        value={poolStats.verified}
        color='#3b82f6'
        icon='💼'
      />
      <StatCard
        label='Institutional'
        value={poolStats.institutional}
        color='#8b5cf6'
        icon='🏛️'
      />
    </div>
  </Card>
)

const BrowsePoolsView = ({
  pools,
  userTier,
  canAccessPool,
  loadingPools,
  refreshPools
}) => (
  <div>
    <Card title='Browse Pools'>
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: '1.5rem'
        }}
      >
        <p style={{ color: '#6b7280', margin: 0 }}>
          Showing {pools.length} pool{pools.length !== 1 ? 's' : ''}
        </p>
        <button
          onClick={refreshPools}
          disabled={loadingPools}
          style={styles.smallButton}
        >
          {loadingPools ? 'Loading...' : '🔄 Refresh'}
        </button>
      </div>

      {loadingPools ? (
        <div
          style={{
            textAlign: 'center',
            padding: '3rem',
            background: '#f9fafb',
            borderRadius: '8px'
          }}
        >
          <div style={{ fontSize: '3rem', marginBottom: '1rem' }}>⏳</div>
          <p style={{ color: '#6b7280' }}>Loading...</p>
        </div>
      ) : pools.length === 0 ? (
        <div
          style={{
            textAlign: 'center',
            padding: '3rem',
            background: '#f9fafb',
            borderRadius: '8px'
          }}
        >
          <div style={{ fontSize: '3rem', marginBottom: '1rem' }}>📭</div>
          <p
            style={{
              color: '#6b7280',
              marginBottom: '1rem',
              fontSize: '1.125rem',
              fontWeight: '600'
            }}
          >
            No pools found
          </p>
          <p
            style={{
              fontSize: '0.875rem',
              color: '#9ca3af',
              marginBottom: '1rem'
            }}
          >
            Go to Debug tab to analyze your transaction!
          </p>
        </div>
      ) : (
        <div style={{ display: 'grid', gap: '1rem' }}>
          {pools.map((pool, i) => (
            <PoolCard
              key={i}
              pool={pool}
              userTier={userTier}
              canAccess={canAccessPool(pool.tier)}
            />
          ))}
        </div>
      )}
    </Card>
  </div>
)

const PoolCard = ({ pool, userTier, canAccess }) => {
  const tierColor = getTierColor(pool.tier)

  return (
    <div
      style={{
        background: 'white',
        borderRadius: '12px',
        padding: '1.5rem',
        border: '2px solid #e5e7eb'
      }}
    >
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'start',
          marginBottom: '1rem'
        }}
      >
        <div style={{ flex: 1 }}>
          <h3
            style={{
              fontSize: '1.25rem',
              fontWeight: '700',
              marginBottom: '0.5rem'
            }}
          >
            {pool.name}
          </h3>
          <div
            style={{
              fontSize: '0.875rem',
              color: '#6b7280',
              marginBottom: '0.25rem'
            }}
          >
            Creator: {pool.creator.slice(0, 6)}...{pool.creator.slice(-4)}
          </div>
          <div style={{ fontSize: '0.875rem', color: '#6b7280' }}>
            Created: {pool.createdAt}
          </div>
        </div>
        <div
          style={{
            padding: '0.5rem 1rem',
            background: `${tierColor}15`,
            color: tierColor,
            borderRadius: '8px',
            fontWeight: '600',
            fontSize: '0.875rem'
          }}
        >
          {getTierIcon(pool.tier)} {pool.tier}
        </div>
      </div>

      <div
        style={{
          padding: '1rem',
          background: canAccess ? '#10b98115' : '#ef444415',
          borderRadius: '8px',
          border: `2px solid ${canAccess ? '#10b981' : '#ef4444'}`
        }}
      >
        <div
          style={{
            fontWeight: '600',
            color: canAccess ? '#10b981' : '#ef4444',
            marginBottom: '0.25rem',
            fontSize: '1rem'
          }}
        >
          {canAccess ? '✅ You can trade' : '❌ Access denied'}
        </div>
      </div>
    </div>
  )
}

const CreatePoolView = ({
  newPoolTier,
  setNewPoolTier,
  newPoolWhitelist,
  setNewPoolWhitelist,
  createPool,
  loading
}) => (
  <Card title='Create Pool'>
    <FormField label='Tier:'>
      <select
        value={newPoolTier}
        onChange={e => setNewPoolTier(e.target.value)}
        style={styles.select}
      >
        <option value='0'>🌐 PUBLIC</option>
        <option value='1'>💼 VERIFIED</option>
        <option value='2'>🏛️ INSTITUTIONAL</option>
      </select>
    </FormField>

    <FormField label=''>
      <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
        <input
          type='checkbox'
          checked={newPoolWhitelist}
          onChange={e => setNewPoolWhitelist(e.target.checked)}
        />
        <span>Require Whitelist</span>
      </label>
    </FormField>

    <button
      onClick={createPool}
      disabled={loading}
      style={{ ...styles.primaryButton, width: '100%' }}
    >
      {loading ? 'Creating...' : '➕ Create Pool'}
    </button>
  </Card>
)

const SwapView = ({
  swapAmount,
  setSwapAmount,
  performSwap,
  loading,
  swapStatus,
  poolsAvailable
}) => (
  <Card title='Swap'>
    {!poolsAvailable && (
      <div
        style={{
          marginBottom: '1.5rem',
          padding: '1rem',
          background: '#fef3c7',
          borderRadius: '8px'
        }}
      >
        ⚠️ No pools yet
      </div>
    )}

    <FormField label='Amount (ETH):'>
      <input
        type='number'
        value={swapAmount}
        onChange={e => setSwapAmount(e.target.value)}
        step='0.01'
        style={styles.input}
      />
    </FormField>

    {swapStatus && (
      <div
        style={{
          marginBottom: '1rem',
          padding: '1rem',
          background: '#f3f4f6',
          borderRadius: '8px',
          fontSize: '0.875rem'
        }}
      >
        {swapStatus}
      </div>
    )}

    <button
      onClick={performSwap}
      disabled={loading}
      style={{ ...styles.infoButton, width: '100%' }}
    >
      {loading ? 'Swapping...' : '🔄 Swap'}
    </button>
  </Card>
)

const AdminView = () => (
  <Card title='Admin'>
    <div
      style={{
        padding: '1.5rem',
        background: '#8b5cf615',
        borderRadius: '8px'
      }}
    >
      <strong>System Operator Functions</strong>
      <ul style={{ marginTop: '0.5rem', paddingLeft: '1.5rem' }}>
        <li>Register institutions</li>
        <li>Verify KYC</li>
        <li>Manage tiers</li>
      </ul>
    </div>
  </Card>
)

const Card = ({ title, children }) => (
  <div
    style={{
      background: 'white',
      borderRadius: '12px',
      padding: '2rem',
      marginBottom: '2rem',
      boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
    }}
  >
    {title && (
      <h2
        style={{
          fontSize: '1.875rem',
          fontWeight: '700',
          marginBottom: '1.5rem'
        }}
      >
        {title}
      </h2>
    )}
    {children}
  </div>
)

const FormField = ({ label, children }) => (
  <div style={{ marginBottom: '1.5rem' }}>
    {label && (
      <label
        style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem' }}
      >
        {label}
      </label>
    )}
    {children}
  </div>
)

const StatCard = ({ label, value, color, icon }) => (
  <div
    style={{
      padding: '1.5rem',
      background: `${color}15`,
      borderRadius: '8px',
      textAlign: 'center'
    }}
  >
    <div style={{ fontSize: '2.5rem', marginBottom: '0.5rem' }}>{icon}</div>
    <div
      style={{
        fontSize: '0.875rem',
        color: '#6b7280',
        marginBottom: '0.25rem'
      }}
    >
      {label}
    </div>
    <div style={{ fontSize: '1.75rem', fontWeight: '700', color }}>{value}</div>
  </div>
)

const InfoBox = ({ title, items }) => (
  <div
    style={{
      background: 'white',
      borderRadius: '12px',
      padding: '2rem',
      boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
    }}
  >
    <h3
      style={{
        fontSize: '1.25rem',
        fontWeight: '700',
        marginBottom: '1rem',
        color: '#10b981'
      }}
    >
      {title}
    </h3>
    <ul style={{ paddingLeft: '1.5rem', lineHeight: '1.75' }}>
      {items.map((item, i) => (
        <li key={i}>{item}</li>
      ))}
    </ul>
  </div>
)

const getTierInfo = tier => {
  const tiers = {
    NON_COMPLIANT: { name: 'Non-Compliant', color: '#ef4444', icon: '❌' },
    PUBLIC: { name: 'Public', color: '#10b981', icon: '🌐' },
    VERIFIED: { name: 'Verified', color: '#3b82f6', icon: '💼' },
    INSTITUTIONAL: { name: 'Institutional', color: '#8b5cf6', icon: '🏛️' }
  }
  return tiers[tier] || tiers['NON_COMPLIANT']
}

const getTierColor = tier => {
  const colors = {
    PUBLIC: '#10b981',
    VERIFIED: '#3b82f6',
    INSTITUTIONAL: '#8b5cf6'
  }
  return colors[tier] || '#6b7280'
}

const getTierIcon = tier => {
  const icons = { PUBLIC: '🌐', VERIFIED: '💼', INSTITUTIONAL: '🏛️' }
  return icons[tier] || '❓'
}

const styles = {
  primaryButton: {
    background: '#ff007a',
    color: 'white',
    padding: '1rem 2rem',
    borderRadius: '8px',
    border: 'none',
    fontSize: '1rem',
    fontWeight: '600',
    cursor: 'pointer'
  },
  successButton: {
    background: '#10b981',
    color: 'white',
    padding: '1rem 2rem',
    borderRadius: '8px',
    border: 'none',
    fontSize: '1rem',
    fontWeight: '600',
    cursor: 'pointer'
  },
  infoButton: {
    background: '#3b82f6',
    color: 'white',
    padding: '1rem 2rem',
    borderRadius: '8px',
    border: 'none',
    fontSize: '1rem',
    fontWeight: '600',
    cursor: 'pointer'
  },
  disabledButton: {
    background: '#9ca3af',
    color: 'white',
    padding: '1rem 2rem',
    borderRadius: '8px',
    border: 'none',
    fontSize: '1rem',
    fontWeight: '600',
    cursor: 'not-allowed'
  },
  smallButton: {
    background: '#3b82f6',
    color: 'white',
    padding: '0.5rem 1rem',
    borderRadius: '6px',
    border: 'none',
    fontSize: '0.875rem',
    fontWeight: '600',
    cursor: 'pointer'
  },
  input: {
    width: '100%',
    padding: '0.75rem',
    border: '2px solid #e5e7eb',
    borderRadius: '8px',
    fontSize: '1rem',
    fontFamily: 'monospace'
  },
  select: {
    width: '100%',
    padding: '0.75rem',
    border: '2px solid #e5e7eb',
    borderRadius: '8px',
    fontSize: '1rem'
  },
  tierBadge: {
    display: 'inline-flex',
    alignItems: 'center',
    gap: '0.5rem',
    padding: '0.5rem 1rem',
    borderRadius: '8px'
  }
}

export default App

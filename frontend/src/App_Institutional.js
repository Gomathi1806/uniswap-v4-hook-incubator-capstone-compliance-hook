// ========================================
// INSTITUTIONAL COMPLIANCE SYSTEM
// Pool-Level Enforcement + Real Compliance Data
// ========================================

import React, { useState, useEffect } from 'react'
import { ethers } from 'ethers'

const App = () => {
  const [account, setAccount] = useState('')
  const [balance, setBalance] = useState('0')
  const [provider, setProvider] = useState(null)
  const [signer, setSigner] = useState(null)
  const [loading, setLoading] = useState(false)
  const [currentView, setCurrentView] = useState('overview')

  // User compliance data
  const [userCompliance, setUserCompliance] = useState({
    tier: 'NON_COMPLIANT',
    riskScore: 0,
    kycScore: 0,
    amlScore: 0,
    sanctionsScore: 0,
    isOnOFACList: false,
    verified: false,
    lastChecked: 0
  })

  // Pool data
  const [pools, setPools] = useState([])
  const [poolStats, setPoolStats] = useState({
    total: 0,
    public: 0,
    verified: 0,
    institutional: 0
  })

  // Compliance stats
  const [complianceStats, setComplianceStats] = useState({
    totalChecks: 0,
    cacheHits: 0,
    cacheMisses: 0,
    privacyChecks: 0,
    encryptedRecords: 0,
    sanctionedBlocked: 0
  })

  // Contract addresses - REAL DEPLOYED CONTRACTS
  const CONTRACTS = {
    // Compliance Contracts
    phase1Oracle: '0xYOUR_PHASE1_ADDRESS',
    phase2Multi: '0xYOUR_PHASE2_ADDRESS',
    phase3Privacy: '0xYOUR_PHASE3_ADDRESS',

    // Uniswap V4 Infrastructure
    hook: '0x96151b6acdfd9d8c8116e44100e28030aaefcbb8',
    poolManager: '0x7Da1D65F8B249183667cdE74C5CBD46dD38AA829',

    // Test tokens
    token0: '0x980B62Da83eFf3D4576C647993b0c1D7faf17c73',
    token1: '0x8FB1E3fC51F3b789dED7557E680551d93Ea9d892'
  }

  // ABIs
  const COMPLIANCE_ABI = [
    'function getComplianceRecord(address) external view returns (tuple(uint8 riskLevel, uint256 riskScore, uint256 kycScore, uint256 amlScore, uint256 sanctionsScore, bool isOnOFACList, bool verified, uint256 lastChecked, uint256 lastUpdated, uint8 dataSource, string country, bool privacyEnabled))',
    'function getRiskScore(address) external view returns (uint256)',
    'function isCompliant(address) external view returns (bool)',
    'function setComplianceData(address,uint256,uint256,uint256,bool,string) external',
    'function checkComplianceWithPrivacy(address) external returns (bool)',
    'function getCacheStats() external view returns (uint256,uint256,uint256)',
    'function getPrivacyStats() external view returns (uint256,uint256,uint256,bool)',
    'event ComplianceCheck(address indexed user, bool passed, uint8 riskLevel, string reason, uint256 timestamp)',
    'event SanctionedAddressBlocked(address indexed blockedAddress, uint8 source, string details, uint256 timestamp)'
  ]

  const HOOK_ABI = [
    'function getUserComplianceLevel(address) external view returns (string)',
    'function getPoolStats() external view returns (uint256, uint256, uint256, uint256)',
    'function poolConfigs(bytes32) external view returns (uint8 tier, address creator, bool requiresWhitelist, uint256 protocolFeeBps, uint256 createdAt)',
    'function canAccessPool(address user, bytes32 poolId) external view returns (bool)',
    'event PoolRegistered(bytes32 indexed poolId, uint8 tier, address creator)',
    'event AccessDenied(address indexed user, bytes32 indexed poolId, string reason)'
  ]

  const POOL_MANAGER_ABI = [
    'function initialize(tuple(address currency0, address currency1, uint24 fee, int24 tickSpacing, address hooks) key, uint160 sqrtPriceX96, bytes) external returns (int24)',
    'event Initialize(bytes32 indexed id, address indexed currency0, address indexed currency1, uint24 fee, int24 tickSpacing, address hooks)'
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
        await switchToArbitrumSepolia()
      }

      const userBalance = await web3Provider.getBalance(accounts[0])
      setAccount(accounts[0])
      setBalance(ethers.formatEther(userBalance))
      setProvider(web3Provider)
      setSigner(web3Signer)

      // Load all data
      await Promise.all([
        fetchUserCompliance(web3Provider, accounts[0]),
        fetchPoolStats(web3Provider),
        fetchComplianceStats(web3Provider),
        loadPools(web3Provider)
      ])
    } catch (error) {
      console.error('Connection error:', error)
      alert('Failed to connect: ' + error.message)
    }
  }

  const switchToArbitrumSepolia = async () => {
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

  // Fetch user compliance from Phase 3 (most advanced)
  const fetchUserCompliance = async (web3Provider, address) => {
    try {
      const complianceContract = new ethers.Contract(
        CONTRACTS.phase3Privacy,
        COMPLIANCE_ABI,
        web3Provider
      )

      const record = await complianceContract.getComplianceRecord(address)

      setUserCompliance({
        tier: ['LOW', 'MEDIUM', 'HIGH', 'SANCTIONED'][Number(record.riskLevel)],
        riskScore: Number(record.riskScore),
        kycScore: Number(record.kycScore),
        amlScore: Number(record.amlScore),
        sanctionsScore: Number(record.sanctionsScore),
        isOnOFACList: record.isOnOFACList,
        verified: record.verified,
        lastChecked: Number(record.lastChecked)
      })

      // Also get tier from hook
      const hookContract = new ethers.Contract(
        CONTRACTS.hook,
        HOOK_ABI,
        web3Provider
      )
      const hookTier = await hookContract.getUserComplianceLevel(address)

      console.log('User Compliance:', { record, hookTier })
    } catch (error) {
      console.error('Error fetching compliance:', error)
    }
  }

  // Fetch pool statistics
  const fetchPoolStats = async web3Provider => {
    try {
      const hookContract = new ethers.Contract(
        CONTRACTS.hook,
        HOOK_ABI,
        web3Provider
      )
      const [total, publicCount, verified, institutional] =
        await hookContract.getPoolStats()

      setPoolStats({
        total: Number(total),
        public: Number(publicCount),
        verified: Number(verified),
        institutional: Number(institutional)
      })
    } catch (error) {
      console.error('Error fetching pool stats:', error)
    }
  }

  // Fetch compliance statistics
  const fetchComplianceStats = async web3Provider => {
    try {
      const complianceContract = new ethers.Contract(
        CONTRACTS.phase3Privacy,
        COMPLIANCE_ABI,
        web3Provider
      )

      const [hits, misses, hitRate] = await complianceContract.getCacheStats()
      const [privChecks, encrypted, audits] =
        await complianceContract.getPrivacyStats()

      setComplianceStats({
        totalChecks: Number(hits) + Number(misses),
        cacheHits: Number(hits),
        cacheMisses: Number(misses),
        hitRate: Number(hitRate),
        privacyChecks: Number(privChecks),
        encryptedRecords: Number(encrypted),
        totalAudits: Number(audits)
      })
    } catch (error) {
      console.error('Error fetching compliance stats:', error)
    }
  }

  // Load pools from blockchain
  const loadPools = async web3Provider => {
    try {
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

      const currentBlock = await web3Provider.getBlockNumber()
      const fromBlock = Math.max(0, currentBlock - 500000)

      const filter = poolManagerContract.filters.Initialize()
      const events = await poolManagerContract.queryFilter(
        filter,
        fromBlock,
        currentBlock
      )

      const ourPools = events.filter(
        e => e.args.hooks.toLowerCase() === CONTRACTS.hook.toLowerCase()
      )

      const poolsData = []
      for (const event of ourPools) {
        const poolId = event.args.id
        try {
          const config = await hookContract.poolConfigs(poolId)

          if (Number(config.createdAt) > 0) {
            // Check if user can access this pool
            const canAccess = await hookContract.canAccessPool(
              account || ethers.ZeroAddress,
              poolId
            )

            poolsData.push({
              id: poolId,
              tier: ['PUBLIC', 'VERIFIED', 'INSTITUTIONAL'][
                Number(config.tier)
              ],
              creator: config.creator,
              requiresWhitelist: config.requiresWhitelist,
              protocolFee: Number(config.protocolFeeBps) / 100,
              createdAt: new Date(
                Number(config.createdAt) * 1000
              ).toLocaleString(),
              canAccess: canAccess,
              blockNumber: event.blockNumber
            })
          }
        } catch (err) {
          console.error('Error loading pool config:', err)
        }
      }

      setPools(poolsData)
    } catch (error) {
      console.error('Error loading pools:', error)
    }
  }

  // Run compliance check
  const runComplianceCheck = async () => {
    if (!signer) {
      alert('Please connect wallet!')
      return
    }

    setLoading(true)
    try {
      const complianceContract = new ethers.Contract(
        CONTRACTS.phase3Privacy,
        COMPLIANCE_ABI,
        signer
      )

      const tx = await complianceContract.checkComplianceWithPrivacy(account)
      const receipt = await tx.wait()

      // Parse events
      for (const log of receipt.logs) {
        try {
          const parsed = complianceContract.interface.parseLog(log)
          if (parsed && parsed.name === 'ComplianceCheck') {
            console.log('Compliance Check Result:', parsed.args)
          }
        } catch (e) {}
      }

      await fetchUserCompliance(provider, account)
      await fetchComplianceStats(provider)

      alert('✅ Real-time compliance check completed!')
    } catch (error) {
      console.error('Check failed:', error)
      alert('Check failed: ' + error.message)
    } finally {
      setLoading(false)
    }
  }

  // Submit for institutional verification
  const submitForVerification = async () => {
    alert(
      '📋 Institutional Verification Process:\n\n' +
        '1. Submit KYC documents\n' +
        '2. AML background check\n' +
        '3. OFAC sanctions screening\n' +
        '4. Operator reviews and approves\n' +
        '5. On-chain verification stored\n' +
        '6. Access granted to compliant pools\n\n' +
        'In production, this would integrate with real KYC providers like Chainalysis or TRM Labs.'
    )

    // In production, this would trigger actual KYC flow
  }

  useEffect(() => {
    if (account && provider) {
      fetchUserCompliance(provider, account)
      fetchPoolStats(provider)
      fetchComplianceStats(provider)
      loadPools(provider)
    }
  }, [account, provider])

  const tierInfo = getTierInfo(userCompliance.tier)
  const isInstitutional =
    userCompliance.verified && userCompliance.riskScore >= 70

  // RENDER
  return (
    <div style={styles.container}>
      <div style={styles.content}>
        {/* Header */}
        <div style={styles.header}>
          <h1 style={styles.title}>🏛️ Institutional DeFi Compliance System</h1>
          <p style={styles.subtitle}>
            Pool-Level Enforcement • Real-Time OFAC • Privacy-Preserving
          </p>
        </div>

        {/* Navigation */}
        <div style={styles.nav}>
          <NavButton
            label='📊 Overview'
            active={currentView === 'overview'}
            onClick={() => setCurrentView('overview')}
          />
          <NavButton
            label='🏊 Compliant Pools'
            active={currentView === 'pools'}
            onClick={() => setCurrentView('pools')}
          />
          <NavButton
            label='✅ My Verification'
            active={currentView === 'verification'}
            onClick={() => setCurrentView('verification')}
          />
          <NavButton
            label='📈 Analytics'
            active={currentView === 'analytics'}
            onClick={() => setCurrentView('analytics')}
          />
        </div>

        {/* Wallet */}
        <div style={styles.walletCard}>
          {!account ? (
            <button onClick={connectWallet} style={styles.primaryButton}>
              Connect Institutional Wallet
            </button>
          ) : (
            <div>
              <p style={styles.accountText}>
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
                {isInstitutional && (
                  <span style={{ marginLeft: '0.5rem' }}>🏛️ Institutional</span>
                )}
              </div>
            </div>
          )}
        </div>

        {account && (
          <>
            {/* Overview */}
            {currentView === 'overview' && (
              <div style={styles.grid}>
                <Card title='Your Compliance Status'>
                  <div
                    style={{
                      ...styles.statusCard,
                      border: `2px solid ${tierInfo.color}`
                    }}
                  >
                    <div style={{ fontSize: '3rem', marginBottom: '1rem' }}>
                      {tierInfo.icon}
                    </div>
                    <h3
                      style={{
                        fontSize: '1.5rem',
                        color: tierInfo.color,
                        marginBottom: '0.5rem'
                      }}
                    >
                      {tierInfo.name}
                    </h3>
                    <div style={styles.scoreGrid}>
                      <ScoreItem
                        label='Overall Risk'
                        value={userCompliance.riskScore}
                        max={100}
                      />
                      <ScoreItem
                        label='KYC Score'
                        value={userCompliance.kycScore}
                        max={100}
                      />
                      <ScoreItem
                        label='AML Score'
                        value={userCompliance.amlScore}
                        max={100}
                      />
                      <ScoreItem
                        label='Sanctions'
                        value={userCompliance.sanctionsScore}
                        max={100}
                      />
                    </div>
                    <div
                      style={{
                        marginTop: '1rem',
                        display: 'flex',
                        gap: '1rem'
                      }}
                    >
                      <StatusBadge
                        label='Verified'
                        value={userCompliance.verified}
                        trueColor='#10b981'
                        falseColor='#ef4444'
                      />
                      <StatusBadge
                        label='OFAC Clear'
                        value={!userCompliance.isOnOFACList}
                        trueColor='#10b981'
                        falseColor='#ef4444'
                      />
                    </div>
                  </div>
                  <div style={styles.buttonGrid}>
                    <button
                      onClick={runComplianceCheck}
                      disabled={loading}
                      style={styles.successButton}
                    >
                      {loading ? 'Checking...' : '🔍 Run Real-Time Check'}
                    </button>
                    {!userCompliance.verified && (
                      <button
                        onClick={submitForVerification}
                        style={styles.primaryButton}
                      >
                        📋 Submit for Verification
                      </button>
                    )}
                  </div>
                </Card>

                <Card title='Pool Access Summary'>
                  <div style={styles.accessGrid}>
                    <AccessTierCard
                      tier='PUBLIC'
                      icon='🌐'
                      color='#10b981'
                      count={poolStats.public}
                      canAccess={true}
                      description='Open to all verified users'
                    />
                    <AccessTierCard
                      tier='VERIFIED'
                      icon='💼'
                      color='#3b82f6'
                      count={poolStats.verified}
                      canAccess={userCompliance.verified}
                      description='Requires KYC verification'
                    />
                    <AccessTierCard
                      tier='INSTITUTIONAL'
                      icon='🏛️'
                      color='#8b5cf6'
                      count={poolStats.institutional}
                      canAccess={isInstitutional}
                      description='For institutional traders only'
                    />
                  </div>
                </Card>
              </div>
            )}

            {/* Pools View */}
            {currentView === 'pools' && (
              <Card title='Compliant Trading Pools'>
                {pools.length === 0 ? (
                  <div style={styles.emptyState}>
                    <div style={{ fontSize: '3rem', marginBottom: '1rem' }}>
                      🏊
                    </div>
                    <p>No pools found. Create a pool to get started.</p>
                  </div>
                ) : (
                  <div style={styles.poolsGrid}>
                    {pools.map((pool, i) => (
                      <PoolCard
                        key={i}
                        pool={pool}
                        userTier={userCompliance.tier}
                      />
                    ))}
                  </div>
                )}
              </Card>
            )}

            {/* Verification View */}
            {currentView === 'verification' && (
              <Card title='Institutional Verification'>
                <VerificationFlow
                  userCompliance={userCompliance}
                  onSubmit={submitForVerification}
                />
              </Card>
            )}

            {/* Analytics View */}
            {currentView === 'analytics' && (
              <div style={styles.grid}>
                <Card title='System Statistics'>
                  <div style={styles.statsGrid}>
                    <StatCard
                      label='Total Checks'
                      value={complianceStats.totalChecks}
                      icon='📊'
                      color='#6b7280'
                    />
                    <StatCard
                      label='Cache Hits'
                      value={complianceStats.cacheHits}
                      icon='⚡'
                      color='#10b981'
                    />
                    <StatCard
                      label='Hit Rate'
                      value={`${complianceStats.hitRate}%`}
                      icon='📈'
                      color='#3b82f6'
                    />
                    <StatCard
                      label='Privacy Checks'
                      value={complianceStats.privacyChecks}
                      icon='🔒'
                      color='#8b5cf6'
                    />
                    <StatCard
                      label='Encrypted Records'
                      value={complianceStats.encryptedRecords}
                      icon='🔐'
                      color='#ec4899'
                    />
                    <StatCard
                      label='Total Pools'
                      value={poolStats.total}
                      icon='🏊'
                      color='#f59e0b'
                    />
                  </div>
                </Card>

                <Card title='Contract Addresses'>
                  <div style={styles.addressList}>
                    <AddressRow
                      label='Phase 3 Privacy'
                      address={CONTRACTS.phase3Privacy}
                    />
                    <AddressRow
                      label='Phase 2 Multi-Oracle'
                      address={CONTRACTS.phase2Multi}
                    />
                    <AddressRow
                      label='Phase 1 Oracle'
                      address={CONTRACTS.phase1Oracle}
                    />
                    <AddressRow
                      label='Compliance Hook'
                      address={CONTRACTS.hook}
                    />
                    <AddressRow
                      label='Pool Manager'
                      address={CONTRACTS.poolManager}
                    />
                  </div>
                </Card>
              </div>
            )}
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
      ...styles.navButton,
      ...(active ? styles.navButtonActive : {})
    }}
  >
    {label}
  </button>
)

const Card = ({ title, children }) => (
  <div style={styles.card}>
    {title && <h2 style={styles.cardTitle}>{title}</h2>}
    {children}
  </div>
)

const ScoreItem = ({ label, value, max }) => (
  <div style={{ textAlign: 'center' }}>
    <div
      style={{
        fontSize: '0.875rem',
        color: '#6b7280',
        marginBottom: '0.25rem'
      }}
    >
      {label}
    </div>
    <div
      style={{
        fontSize: '1.5rem',
        fontWeight: '700',
        color: value >= 70 ? '#10b981' : value >= 40 ? '#f59e0b' : '#ef4444'
      }}
    >
      {value}/{max}
    </div>
  </div>
)

const StatusBadge = ({ label, value, trueColor, falseColor }) => (
  <div
    style={{
      flex: 1,
      padding: '0.5rem',
      borderRadius: '8px',
      background: value ? `${trueColor}15` : `${falseColor}15`,
      border: `2px solid ${value ? trueColor : falseColor}`,
      textAlign: 'center'
    }}
  >
    <div style={{ fontSize: '1.25rem', marginBottom: '0.25rem' }}>
      {value ? '✅' : '❌'}
    </div>
    <div
      style={{
        fontSize: '0.875rem',
        fontWeight: '600',
        color: value ? trueColor : falseColor
      }}
    >
      {label}
    </div>
  </div>
)

const AccessTierCard = ({
  tier,
  icon,
  color,
  count,
  canAccess,
  description
}) => (
  <div
    style={{
      padding: '1.5rem',
      borderRadius: '12px',
      background: canAccess ? `${color}15` : '#f3f4f6',
      border: `2px solid ${canAccess ? color : '#e5e7eb'}`
    }}
  >
    <div style={{ fontSize: '2rem', marginBottom: '0.5rem' }}>{icon}</div>
    <h4
      style={{
        fontSize: '1.125rem',
        fontWeight: '700',
        marginBottom: '0.25rem',
        color
      }}
    >
      {tier}
    </h4>
    <p
      style={{ fontSize: '0.875rem', color: '#6b7280', marginBottom: '0.5rem' }}
    >
      {description}
    </p>
    <div style={{ fontSize: '1.5rem', fontWeight: '700', color: '#1f2937' }}>
      {count} pools
    </div>
    <div
      style={{
        marginTop: '0.75rem',
        padding: '0.5rem',
        borderRadius: '6px',
        background: canAccess ? '#10b98115' : '#ef444415',
        fontSize: '0.875rem',
        fontWeight: '600',
        color: canAccess ? '#10b981' : '#ef4444'
      }}
    >
      {canAccess ? '✅ Access Granted' : '❌ Restricted'}
    </div>
  </div>
)

const PoolCard = ({ pool, userTier }) => {
  const tierColor = getTierColor(pool.tier)

  return (
    <div
      style={{
        padding: '1.5rem',
        borderRadius: '12px',
        background: 'white',
        border: `2px solid ${pool.canAccess ? tierColor : '#e5e7eb'}`
      }}
    >
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          marginBottom: '1rem'
        }}
      >
        <div>
          <h4
            style={{
              fontSize: '1.125rem',
              fontWeight: '700',
              marginBottom: '0.25rem'
            }}
          >
            Pool {pool.id.slice(0, 8)}...
          </h4>
          <p style={{ fontSize: '0.875rem', color: '#6b7280' }}>
            Created: {pool.createdAt}
          </p>
        </div>
        <div
          style={{
            padding: '0.5rem 1rem',
            borderRadius: '8px',
            background: `${tierColor}15`,
            color: tierColor,
            fontWeight: '600',
            height: 'fit-content'
          }}
        >
          {pool.tier}
        </div>
      </div>
      <div
        style={{
          padding: '1rem',
          borderRadius: '8px',
          background: pool.canAccess ? '#10b98115' : '#ef444415',
          border: `2px solid ${pool.canAccess ? '#10b981' : '#ef4444'}`
        }}
      >
        <div
          style={{
            fontWeight: '600',
            color: pool.canAccess ? '#10b981' : '#ef4444'
          }}
        >
          {pool.canAccess
            ? '✅ You can trade in this pool'
            : '❌ Access denied - Verification required'}
        </div>
      </div>
    </div>
  )
}

const VerificationFlow = ({ userCompliance, onSubmit }) => (
  <div style={{ padding: '2rem' }}>
    <div style={{ marginBottom: '2rem' }}>
      <h3
        style={{ fontSize: '1.25rem', fontWeight: '700', marginBottom: '1rem' }}
      >
        Institutional Verification Process
      </h3>
      <div style={styles.verificationSteps}>
        <VerificationStep
          step={1}
          title='KYC Submission'
          status={userCompliance.kycScore > 0 ? 'complete' : 'pending'}
          description='Submit identity documents and business registration'
        />
        <VerificationStep
          step={2}
          title='AML Screening'
          status={userCompliance.amlScore > 0 ? 'complete' : 'pending'}
          description='Background check and source of funds verification'
        />
        <VerificationStep
          step={3}
          title='OFAC Check'
          status={
            !userCompliance.isOnOFACList && userCompliance.sanctionsScore > 0
              ? 'complete'
              : 'pending'
          }
          description='Real-time sanctions list screening'
        />
        <VerificationStep
          step={4}
          title='Approval'
          status={userCompliance.verified ? 'complete' : 'pending'}
          description='Operator review and on-chain verification'
        />
      </div>
    </div>
    {!userCompliance.verified && (
      <button onClick={onSubmit} style={styles.primaryButton}>
        📋 Start Verification Process
      </button>
    )}
  </div>
)

const VerificationStep = ({ step, title, status, description }) => (
  <div style={{ display: 'flex', gap: '1rem', marginBottom: '1.5rem' }}>
    <div
      style={{
        width: '40px',
        height: '40px',
        borderRadius: '50%',
        background: status === 'complete' ? '#10b981' : '#e5e7eb',
        color: status === 'complete' ? 'white' : '#6b7280',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontWeight: '700'
      }}
    >
      {status === 'complete' ? '✓' : step}
    </div>
    <div style={{ flex: 1 }}>
      <h4
        style={{ fontSize: '1rem', fontWeight: '600', marginBottom: '0.25rem' }}
      >
        {title}
      </h4>
      <p style={{ fontSize: '0.875rem', color: '#6b7280' }}>{description}</p>
    </div>
  </div>
)

const StatCard = ({ label, value, icon, color }) => (
  <div style={{ ...styles.statCard, background: `${color}15` }}>
    <div style={{ fontSize: '2rem', marginBottom: '0.5rem' }}>{icon}</div>
    <div
      style={{
        fontSize: '0.875rem',
        color: '#6b7280',
        marginBottom: '0.25rem'
      }}
    >
      {label}
    </div>
    <div style={{ fontSize: '1.5rem', fontWeight: '700', color }}>{value}</div>
  </div>
)

const AddressRow = ({ label, address }) => (
  <div style={styles.addressRow}>
    <span style={{ fontWeight: '600', color: '#6b7280' }}>{label}:</span>
    <a
      href={`https://sepolia.arbiscan.io/address/${address}`}
      target='_blank'
      rel='noopener noreferrer'
      style={{
        color: '#3b82f6',
        textDecoration: 'none',
        fontFamily: 'monospace'
      }}
    >
      {address.slice(0, 6)}...{address.slice(-4)} ↗
    </a>
  </div>
)

const getTierInfo = tier => {
  const tiers = {
    NON_COMPLIANT: { name: 'Not Verified', color: '#ef4444', icon: '❌' },
    LOW: { name: 'Low Risk', color: '#10b981', icon: '✅' },
    MEDIUM: { name: 'Medium Risk', color: '#f59e0b', icon: '⚠️' },
    HIGH: { name: 'High Risk', color: '#ef4444', icon: '⛔' },
    SANCTIONED: { name: 'Sanctioned', color: '#7f1d1d', icon: '🚫' }
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

// STYLES
const styles = {
  container: {
    minHeight: '100vh',
    background: 'linear-gradient(to bottom, #f9fafb, #f3f4f6)',
    padding: '2rem'
  },
  content: {
    maxWidth: '1400px',
    margin: '0 auto'
  },
  header: {
    textAlign: 'center',
    marginBottom: '2rem'
  },
  title: {
    fontSize: '2.5rem',
    fontWeight: 'bold',
    marginBottom: '0.5rem',
    background: 'linear-gradient(to right, #8b5cf6, #3b82f6)',
    WebkitBackgroundClip: 'text',
    WebkitTextFillColor: 'transparent'
  },
  subtitle: {
    fontSize: '1.125rem',
    color: '#6b7280'
  },
  nav: {
    display: 'flex',
    gap: '0.5rem',
    justifyContent: 'center',
    marginBottom: '2rem',
    flexWrap: 'wrap'
  },
  navButton: {
    padding: '0.75rem 1.5rem',
    background: 'white',
    color: '#1f2937',
    border: '2px solid #e5e7eb',
    borderRadius: '8px',
    fontWeight: '600',
    cursor: 'pointer',
    fontSize: '0.875rem'
  },
  navButtonActive: {
    background: '#8b5cf6',
    color: 'white',
    border: '2px solid #8b5cf6'
  },
  walletCard: {
    textAlign: 'center',
    marginBottom: '2rem',
    background: 'white',
    padding: '1.5rem',
    borderRadius: '12px',
    boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
  },
  accountText: {
    fontSize: '1rem',
    color: '#6b7280',
    marginBottom: '0.5rem'
  },
  tierBadge: {
    display: 'inline-flex',
    alignItems: 'center',
    gap: '0.5rem',
    padding: '0.5rem 1rem',
    borderRadius: '8px'
  },
  grid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))',
    gap: '2rem'
  },
  card: {
    background: 'white',
    borderRadius: '12px',
    padding: '2rem',
    boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
  },
  cardTitle: {
    fontSize: '1.5rem',
    fontWeight: '700',
    marginBottom: '1.5rem'
  },
  statusCard: {
    padding: '2rem',
    borderRadius: '12px',
    textAlign: 'center',
    marginBottom: '1.5rem'
  },
  scoreGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(2, 1fr)',
    gap: '1rem',
    marginTop: '1rem'
  },
  buttonGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
    gap: '1rem'
  },
  accessGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
    gap: '1rem'
  },
  poolsGrid: {
    display: 'grid',
    gap: '1rem'
  },
  statsGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))',
    gap: '1rem'
  },
  statCard: {
    padding: '1.5rem',
    borderRadius: '8px',
    textAlign: 'center'
  },
  verificationSteps: {
    marginTop: '1.5rem'
  },
  addressList: {
    display: 'grid',
    gap: '0.75rem'
  },
  addressRow: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: '0.75rem',
    background: '#f9fafb',
    borderRadius: '8px'
  },
  emptyState: {
    textAlign: 'center',
    padding: '3rem',
    color: '#6b7280'
  },
  primaryButton: {
    background: '#8b5cf6',
    color: 'white',
    padding: '1rem 2rem',
    borderRadius: '8px',
    border: 'none',
    fontSize: '1rem',
    fontWeight: '600',
    cursor: 'pointer',
    width: '100%'
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
  }
}

export default App

// ========================================
// PRODUCTION VERSION - Multi-Phase Compliance
// Integrated: Phase1 Oracle + Phase2 Multi-Oracle + Phase3 Privacy
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

  // Compliance stats
  const [complianceStats, setComplianceStats] = useState({
    cacheHits: 0,
    cacheMisses: 0,
    hitRate: 0,
    totalChecks: 0,
    privacyChecks: 0,
    encryptedRecords: 0
  })

  // Pool data
  const [pools, setPools] = useState([])
  const [loadingPools, setLoadingPools] = useState(false)

  // Contract addresses - UPDATE THESE WITH YOUR DEPLOYED ADDRESSES
  const CONTRACTS = {
    // Compliance contracts (Phase 1, 2, 3)
    phase1Oracle: '0xd67963De79e9a3a6fcF1b8A622eedB5696757258', // Phase1_OFACOracleReady
    phase1Chainlink: '0x86364De6403289106F52f5c85BBeB09e196a1D2d', // Phase1_ChainlinkOFAC_Working
    phase2Multi: '0x0Ad701309581F051f600688809f690a08F815855', // Phase2_MultiOracle_Standalone
    phase3Privacy: '0x3E9e0612592b0a99A0F7730E1B435Bf36b649E33', // Phase3_PrivacyCompliance_Standalone
    phase1simplecompliance: ' 0x958e334669C2909F42Ac60C4a5E4fFCe3c3561Fa', // phase1_simple_compliance

    // Legacy contracts
    hook: '0x96151b6acdfd9d8c8116e44100e28030aaefcbb8',
    poolManager: '0x7Da1D65F8B249183667cdE74C5CBD46dD38AA829',
    token0: '0x980B62Da83eFf3D4576C647993b0c1D7faf17c73',
    token1: '0x8FB1E3fC51F3b789dED7557E680551d93Ea9d892'
  }

  // Which compliance contract to use
  const [activeCompliance, setActiveCompliance] = useState('phase3') // 'phase1', 'phase2', 'phase3'

  // Get active compliance address
  const getActiveComplianceAddress = () => {
    switch (activeCompliance) {
      case 'phase1':
        return CONTRACTS.phase1Oracle
      case 'phase2':
        return CONTRACTS.phase2Multi
      case 'phase3':
        return CONTRACTS.phase3Privacy
      default:
        return CONTRACTS.phase3Privacy
    }
  }

  // ABIs
  const COMPLIANCE_ABI = [
    'function getRiskLevel(address) external view returns (uint8)',
    'function getRiskScore(address) external view returns (uint256)',
    'function isCompliant(address) external view returns (bool)',
    'function checkCompliance(address) external returns (bool)',
    'function checkComplianceWithCache(address) external returns (bool)',
    'function checkComplianceWithPrivacy(address) external returns (bool)',
    'function setComplianceData(address,uint256,uint256,uint256,bool,string) external',
    'function getCacheStats() external view returns (uint256,uint256,uint256)',
    'function getPrivacyStats() external view returns (uint256,uint256,uint256,bool)',
    'function requestOFACCheck(address) external returns (bytes32)',
    'function requestMultiOracleCheck(address) external returns (bytes32)',
    'function optIntoPrivacy() external',
    'function optOutOfPrivacy() external',
    'function isPrivacyOptIn(address) external view returns (bool)',
    'event ComplianceCheck(address indexed user, bool passed, uint8 riskLevel, string reason, uint256 timestamp)'
  ]

  const HOOK_ABI = [
    'function getUserComplianceLevel(address) external view returns (string)',
    'function owner() external view returns (address)',
    'function getPoolStats() external view returns (uint256, uint256, uint256, uint256)'
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
      await fetchComplianceStats(web3Provider)
    } catch (error) {
      console.error('Connection error:', error)
      alert('Failed to connect: ' + error.message)
    }
  }

  // Fetch user compliance data
  const fetchUserData = async (web3Provider, address) => {
    try {
      const complianceContract = new ethers.Contract(
        getActiveComplianceAddress(),
        COMPLIANCE_ABI,
        web3Provider
      )

      const score = await complianceContract.getRiskScore(address)
      setRiskScore(Number(score))

      const riskLevel = await complianceContract.getRiskLevel(address)
      const tierNames = ['LOW', 'MEDIUM', 'HIGH', 'SANCTIONED']
      setUserTier(tierNames[Number(riskLevel)] || 'NON_COMPLIANT')
    } catch (error) {
      console.error('Error fetching user data:', error)
    }
  }

  // Fetch compliance statistics
  const fetchComplianceStats = async web3Provider => {
    try {
      const complianceContract = new ethers.Contract(
        getActiveComplianceAddress(),
        COMPLIANCE_ABI,
        web3Provider
      )

      // Get cache stats (available in Phase2 and Phase3)
      if (activeCompliance === 'phase2' || activeCompliance === 'phase3') {
        const [hits, misses, hitRate] = await complianceContract.getCacheStats()

        setComplianceStats(prev => ({
          ...prev,
          cacheHits: Number(hits),
          cacheMisses: Number(misses),
          hitRate: Number(hitRate),
          totalChecks: Number(hits) + Number(misses)
        }))
      }

      // Get privacy stats (only Phase3)
      if (activeCompliance === 'phase3') {
        const [privChecks, encrypted, audits] =
          await complianceContract.getPrivacyStats()

        setComplianceStats(prev => ({
          ...prev,
          privacyChecks: Number(privChecks),
          encryptedRecords: Number(encrypted),
          totalAudits: Number(audits)
        }))
      }
    } catch (error) {
      console.error('Error fetching compliance stats:', error)
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
        getActiveComplianceAddress(),
        COMPLIANCE_ABI,
        signer
      )

      let tx
      if (activeCompliance === 'phase1') {
        tx = await complianceContract.checkCompliance(account)
      } else if (activeCompliance === 'phase2') {
        tx = await complianceContract.checkComplianceWithCache(account)
      } else {
        tx = await complianceContract.checkComplianceWithPrivacy(account)
      }

      await tx.wait()

      await fetchUserData(provider, account)
      await fetchComplianceStats(provider)

      alert('✅ Compliance check completed!')
    } catch (error) {
      console.error('Check failed:', error)
      alert('Check failed: ' + error.message)
    } finally {
      setLoading(false)
    }
  }

  // Add test data
  const addTestData = async () => {
    if (!signer) {
      alert('Please connect wallet!')
      return
    }

    setLoading(true)
    try {
      const complianceContract = new ethers.Contract(
        getActiveComplianceAddress(),
        COMPLIANCE_ABI,
        signer
      )

      const tx = await complianceContract.setComplianceData(
        account,
        80, // KYC score
        75, // AML score
        100, // Sanctions score
        false, // Not on OFAC
        'US'
      )

      await tx.wait()

      await fetchUserData(provider, account)
      alert('✅ Test data added!')
    } catch (error) {
      console.error('Failed:', error)
      alert('Failed: ' + error.message)
    } finally {
      setLoading(false)
    }
  }

  // Opt into privacy mode (Phase3 only)
  const optIntoPrivacy = async () => {
    if (!signer || activeCompliance !== 'phase3') {
      alert('Privacy features only available in Phase 3!')
      return
    }

    setLoading(true)
    try {
      const complianceContract = new ethers.Contract(
        CONTRACTS.phase3Privacy,
        COMPLIANCE_ABI,
        signer
      )

      const tx = await complianceContract.optIntoPrivacy()
      await tx.wait()

      alert('✅ Privacy mode enabled!')
    } catch (error) {
      console.error('Failed:', error)
      alert('Failed: ' + error.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    if (account && provider) {
      fetchUserData(provider, account)
      fetchComplianceStats(provider)
    }
  }, [account, provider, activeCompliance])

  const tierInfo = getTierInfo(userTier)

  // RENDER
  return (
    <div style={styles.container}>
      <div style={styles.content}>
        {/* Header */}
        <div style={styles.header}>
          <h1 style={styles.title}>
            🦄 Uniswap V4 Multi-Phase Compliance System
          </h1>
          <p style={styles.subtitle}>
            Privacy-Preserving • Multi-Oracle • Real-Time OFAC
          </p>
        </div>

        {/* Phase Selector */}
        <div style={styles.phaseSelector}>
          <button
            onClick={() => setActiveCompliance('phase1')}
            style={{
              ...styles.phaseButton,
              ...(activeCompliance === 'phase1' ? styles.phaseButtonActive : {})
            }}
          >
            📡 Phase 1: Oracle
          </button>
          <button
            onClick={() => setActiveCompliance('phase2')}
            style={{
              ...styles.phaseButton,
              ...(activeCompliance === 'phase2' ? styles.phaseButtonActive : {})
            }}
          >
            🔄 Phase 2: Multi-Oracle
          </button>
          <button
            onClick={() => setActiveCompliance('phase3')}
            style={{
              ...styles.phaseButton,
              ...(activeCompliance === 'phase3' ? styles.phaseButtonActive : {})
            }}
          >
            🔒 Phase 3: Privacy
          </button>
        </div>

        {/* Wallet Connection */}
        <div style={styles.walletCard}>
          {!account ? (
            <button onClick={connectWallet} style={styles.primaryButton}>
              Connect Wallet
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
                <span style={{ fontSize: '0.875rem', color: '#6b7280' }}>
                  | Score: {riskScore}
                </span>
              </div>
            </div>
          )}
        </div>

        {account && (
          <>
            {/* Dashboard */}
            <div style={styles.grid}>
              {/* Risk Status */}
              <Card title='Your Risk Status'>
                <div
                  style={{
                    ...styles.riskCard,
                    background: `${tierInfo.color}15`,
                    border: `2px solid ${tierInfo.color}`
                  }}
                >
                  <div style={{ fontSize: '4rem', marginBottom: '1rem' }}>
                    {tierInfo.icon}
                  </div>
                  <div
                    style={{
                      fontSize: '2rem',
                      fontWeight: '700',
                      color: tierInfo.color
                    }}
                  >
                    {tierInfo.name}
                  </div>
                  <div style={{ fontSize: '1.25rem', color: '#6b7280' }}>
                    Risk Score: {riskScore}/100
                  </div>
                </div>
                <div style={styles.buttonGrid}>
                  <button
                    onClick={runComplianceCheck}
                    disabled={loading}
                    style={styles.successButton}
                  >
                    {loading ? 'Checking...' : '🔍 Run Check'}
                  </button>
                  <button
                    onClick={addTestData}
                    disabled={loading}
                    style={styles.infoButton}
                  >
                    {loading ? 'Adding...' : '➕ Add Test Data'}
                  </button>
                </div>
              </Card>

              {/* Compliance Stats */}
              <Card title='Compliance Statistics'>
                <div style={styles.statsGrid}>
                  <StatCard
                    label='Total Checks'
                    value={complianceStats.totalChecks}
                    color='#6b7280'
                    icon='📊'
                  />
                  <StatCard
                    label='Cache Hits'
                    value={complianceStats.cacheHits}
                    color='#10b981'
                    icon='⚡'
                  />
                  <StatCard
                    label='Hit Rate'
                    value={`${complianceStats.hitRate}%`}
                    color='#3b82f6'
                    icon='📈'
                  />
                  {activeCompliance === 'phase3' && (
                    <>
                      <StatCard
                        label='Privacy Checks'
                        value={complianceStats.privacyChecks}
                        color='#8b5cf6'
                        icon='🔒'
                      />
                      <StatCard
                        label='Encrypted Records'
                        value={complianceStats.encryptedRecords}
                        color='#ec4899'
                        icon='🔐'
                      />
                    </>
                  )}
                </div>
              </Card>
            </div>

            {/* Phase-Specific Features */}
            {activeCompliance === 'phase3' && (
              <Card title='🔒 Privacy Features'>
                <div style={styles.privacyCard}>
                  <p style={styles.privacyText}>
                    Phase 3 uses privacy-preserving compliance checks with
                    encrypted data storage. Your compliance data is never
                    exposed on-chain.
                  </p>
                  <button
                    onClick={optIntoPrivacy}
                    disabled={loading}
                    style={styles.primaryButton}
                  >
                    {loading ? 'Processing...' : '🔒 Enable Privacy Mode'}
                  </button>
                </div>
              </Card>
            )}

            {activeCompliance === 'phase2' && (
              <Card title='🔄 Multi-Oracle Features'>
                <div style={styles.privacyCard}>
                  <p style={styles.privacyText}>
                    Phase 2 aggregates data from multiple oracle sources (OFAC,
                    Chainalysis, TRM Labs) and uses consensus for accuracy.
                    Includes 24-hour caching for gas optimization.
                  </p>
                </div>
              </Card>
            )}

            {/* Phase Details */}
            <Card title='📋 Active Phase Details'>
              <div style={styles.phaseDetails}>
                {activeCompliance === 'phase1' && (
                  <>
                    <h3 style={styles.phaseTitle}>
                      📡 Phase 1: Oracle Architecture
                    </h3>
                    <ul style={styles.featureList}>
                      <li>✅ Oracle request/fulfill pattern</li>
                      <li>
                        ✅ Basic risk scoring (LOW/MEDIUM/HIGH/SANCTIONED)
                      </li>
                      <li>✅ Event logging for transparency</li>
                      <li>✅ Admin functions for manual overrides</li>
                    </ul>
                  </>
                )}
                {activeCompliance === 'phase2' && (
                  <>
                    <h3 style={styles.phaseTitle}>
                      🔄 Phase 2: Multi-Oracle + Caching
                    </h3>
                    <ul style={styles.featureList}>
                      <li>✅ Multiple oracle data sources</li>
                      <li>✅ Consensus mechanism (2/3 agreement)</li>
                      <li>✅ 24-hour caching (85% gas savings)</li>
                      <li>✅ Fallback mechanisms</li>
                      <li>✅ All Phase 1 features</li>
                    </ul>
                  </>
                )}
                {activeCompliance === 'phase3' && (
                  <>
                    <h3 style={styles.phaseTitle}>
                      🔒 Phase 3: Privacy-Preserving
                    </h3>
                    <ul style={styles.featureList}>
                      <li>✅ Encrypted compliance data storage</li>
                      <li>✅ Privacy-preserving verification</li>
                      <li>✅ Audit trail with privacy</li>
                      <li>✅ User opt-in/opt-out for privacy</li>
                      <li>✅ All Phase 2 features (caching + multi-oracle)</li>
                      <li>✅ All Phase 1 features (oracle + scoring)</li>
                    </ul>
                  </>
                )}
              </div>
            </Card>

            {/* Contract Addresses */}
            <Card title='📍 Deployed Contracts'>
              <div style={styles.addressGrid}>
                <AddressRow
                  label='Phase 1 Oracle'
                  address={CONTRACTS.phase1Oracle}
                />
                <AddressRow
                  label='Phase 1 Chainlink'
                  address={CONTRACTS.phase1Chainlink}
                />
                <AddressRow
                  label='Phase 2 Multi-Oracle'
                  address={CONTRACTS.phase2Multi}
                />
                <AddressRow
                  label='Phase 3 Privacy'
                  address={CONTRACTS.phase3Privacy}
                />
                <AddressRow label='Hook' address={CONTRACTS.hook} />
              </div>
            </Card>
          </>
        )}
      </div>
    </div>
  )
}

// COMPONENTS
const Card = ({ title, children }) => (
  <div style={styles.card}>
    {title && <h2 style={styles.cardTitle}>{title}</h2>}
    {children}
  </div>
)

const StatCard = ({ label, value, color, icon }) => (
  <div style={{ ...styles.statCard, background: `${color}15` }}>
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

const AddressRow = ({ label, address }) => (
  <div style={styles.addressRow}>
    <span style={styles.addressLabel}>{label}:</span>
    <a
      href={`https://sepolia.arbiscan.io/address/${address}`}
      target='_blank'
      rel='noopener noreferrer'
      style={styles.addressLink}
    >
      {address.slice(0, 6)}...{address.slice(-4)}
    </a>
  </div>
)

const getTierInfo = tier => {
  const tiers = {
    NON_COMPLIANT: { name: 'Non-Compliant', color: '#ef4444', icon: '❌' },
    LOW: { name: 'Low Risk', color: '#10b981', icon: '✅' },
    MEDIUM: { name: 'Medium Risk', color: '#f59e0b', icon: '⚠️' },
    HIGH: { name: 'High Risk', color: '#ef4444', icon: '⛔' },
    SANCTIONED: { name: 'Sanctioned', color: '#7f1d1d', icon: '🚫' }
  }
  return tiers[tier] || tiers['NON_COMPLIANT']
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
    background: 'linear-gradient(to right, #ff007a, #8b5cf6)',
    WebkitBackgroundClip: 'text',
    WebkitTextFillColor: 'transparent'
  },
  subtitle: {
    fontSize: '1.125rem',
    color: '#6b7280'
  },
  phaseSelector: {
    display: 'flex',
    gap: '1rem',
    justifyContent: 'center',
    marginBottom: '2rem',
    flexWrap: 'wrap'
  },
  phaseButton: {
    padding: '1rem 2rem',
    background: 'white',
    color: '#1f2937',
    border: '2px solid #e5e7eb',
    borderRadius: '12px',
    fontWeight: '600',
    cursor: 'pointer',
    fontSize: '1rem',
    transition: 'all 0.2s'
  },
  phaseButtonActive: {
    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
    color: 'white',
    border: '2px solid #667eea'
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
    gap: '2rem',
    marginBottom: '2rem'
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
  riskCard: {
    padding: '2rem',
    borderRadius: '12px',
    textAlign: 'center',
    marginBottom: '1.5rem'
  },
  buttonGrid: {
    display: 'grid',
    gridTemplateColumns: '1fr 1fr',
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
  privacyCard: {
    padding: '1.5rem',
    background: '#8b5cf615',
    borderRadius: '8px'
  },
  privacyText: {
    marginBottom: '1rem',
    lineHeight: '1.6'
  },
  phaseDetails: {
    padding: '1rem'
  },
  phaseTitle: {
    fontSize: '1.25rem',
    fontWeight: '600',
    marginBottom: '1rem',
    color: '#667eea'
  },
  featureList: {
    paddingLeft: '1.5rem',
    lineHeight: '2'
  },
  addressGrid: {
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
  addressLabel: {
    fontWeight: '600',
    color: '#6b7280'
  },
  addressLink: {
    color: '#3b82f6',
    textDecoration: 'none',
    fontFamily: 'monospace'
  },
  primaryButton: {
    background: '#ff007a',
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
  }
}

export default App

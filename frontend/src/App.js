// ========================================
// COMPLETE WORKING VERSION
// All Real Contract Addresses
// ========================================

import React, { useState, useEffect } from 'react'
import { ethers } from 'ethers'

const App = () => {
  const [account, setAccount] = useState('')
  const [provider, setProvider] = useState(null)
  const [signer, setSigner] = useState(null)
  const [loading, setLoading] = useState(false)
  const [contractData, setContractData] = useState({})

  // YOUR ACTUAL DEPLOYED CONTRACTS (ALL VERIFIED)
  const CONTRACTS = [
    {
      name: 'Phase1: Simple Compliance',
      address: '0x958e334669C2909F42Ac60C4a5E4fFCe3c3561Fa',
      tx: '0x71e9c1292823c4f6d713c517e39ce451799c6ec4d1d80f214c127f61a5be9061'
    },
    {
      name: 'Phase2: Caching Compliance',
      address: '0x386aE91adA9D5bdCBb3130624755F717D620d9F3',
      tx: '0xd0ff1ea74493a781a0a5baae84709004e9983d850329bd7916d3d2c12209ca03'
    },
    {
      name: 'Phase1: OFAC Oracle Ready',
      address: '0xd67963De79e9a3a6fcF1b8A622eedB5696757258',
      tx: '0xa0d781ae1df175cffddb57750880efb0901edd07d9f7691ac7d9d8bc3e027c6d'
    },
    {
      name: 'Phase1: Chainlink OFAC',
      address: '0x86364De6403289106F52f5c85BBeB09e196a1D2d',
      tx: '0xfa47cf698b6e732877bd319260e61f6da4f83f66b175275bcafe262123fa6e77'
    },
    {
      name: 'Phase2: Multi-Oracle',
      address: '0x0Ad701309581F051f600688809f690a08F815855',
      tx: '0xfd4f6e5742ef1e10f19cc5371777771098efc6bc112c95dceec1e140b8b20b44'
    },
    {
      name: 'Phase3: Privacy Compliance',
      address: '0x3E9e0612592b0a99A0F7730E1B435Bf36b649E33',
      tx: '0x30e36e685366edc3868793fe3f387a54cc8e77f09e3ecddf34845ee4569a65d3'
    }
  ]

  const ABI = [
    'function getRiskScore(address) external view returns (uint256)',
    'function getUserRiskScore(address) external view returns (uint256, uint256)',
    'function setComplianceData(address,uint256,uint256,uint256,bool,string) external',
    'function checkCompliance(address) external returns (bool)'
  ]

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

      // Check network
      const network = await web3Provider.getNetwork()
      if (network.chainId !== 421614n) {
        await switchToArbitrumSepolia()
      }

      setAccount(accounts[0])
      setProvider(web3Provider)
      setSigner(web3Signer)

      await checkAllContracts(web3Provider, accounts[0])
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

  const checkAllContracts = async (web3Provider, address) => {
    console.log('🔍 Checking all contracts for:', address)

    const results = {}

    for (const contractInfo of CONTRACTS) {
      try {
        const contract = new ethers.Contract(
          contractInfo.address,
          ABI,
          web3Provider
        )

        // Try getRiskScore
        try {
          const score = await contract.getRiskScore(address)
          results[contractInfo.name] = {
            score: Number(score),
            method: 'getRiskScore',
            verified: Number(score) > 0
          }
          console.log(`✅ ${contractInfo.name}: ${score}`)
          continue
        } catch (e1) {
          // Try getUserRiskScore
          try {
            const [score] = await contract.getUserRiskScore(address)
            results[contractInfo.name] = {
              score: Number(score),
              method: 'getUserRiskScore',
              verified: Number(score) > 0
            }
            console.log(`✅ ${contractInfo.name}: ${score} (alt method)`)
            continue
          } catch (e2) {
            results[contractInfo.name] = {
              score: 0,
              method: 'none',
              verified: false
            }
          }
        }
      } catch (error) {
        console.error(`❌ ${contractInfo.name}:`, error.message)
        results[contractInfo.name] = {
          score: 0,
          method: 'error',
          verified: false
        }
      }
    }

    setContractData(results)
  }

  const addData = async (contractAddress, contractName) => {
    if (!signer) {
      alert('Connect wallet first!')
      return
    }

    setLoading(true)
    try {
      const contract = new ethers.Contract(contractAddress, ABI, signer)

      console.log(`Adding data to ${contractName}...`)

      const tx = await contract.setComplianceData(
        account,
        80, // KYC
        85, // AML
        100, // Sanctions
        false,
        'US'
      )

      console.log('Transaction:', tx.hash)
      await tx.wait()

      alert(
        `✅ Success!\n\nData added to ${contractName}\n\nTX: ${tx.hash}\n\nView: https://sepolia.arbiscan.io/tx/${tx.hash}`
      )

      await checkAllContracts(provider, account)
    } catch (error) {
      console.error('Failed:', error)
      alert(`❌ Failed: ${error.message}`)
    } finally {
      setLoading(false)
    }
  }

  const addToAll = async () => {
    if (!signer) {
      alert('Connect wallet first!')
      return
    }

    const confirmed = window.confirm(
      `This will add compliance data to ALL ${CONTRACTS.length} contracts.\n\n` +
        `This will cost gas for ${CONTRACTS.length} transactions.\n\n` +
        `Continue?`
    )

    if (!confirmed) return

    setLoading(true)

    let success = 0
    let failed = 0

    for (const contractInfo of CONTRACTS) {
      try {
        console.log(`Adding to ${contractInfo.name}...`)
        const contract = new ethers.Contract(contractInfo.address, ABI, signer)
        const tx = await contract.setComplianceData(
          account,
          80,
          85,
          100,
          false,
          'US'
        )
        await tx.wait()
        success++
        console.log(`✅ ${contractInfo.name}`)
      } catch (e) {
        failed++
        console.log(`❌ ${contractInfo.name}:`, e.message)
      }
    }

    await checkAllContracts(provider, account)

    setLoading(false)
    alert(`Complete!\n\nSuccess: ${success}\nFailed: ${failed}`)
  }

  useEffect(() => {
    if (account && provider) {
      checkAllContracts(provider, account)
    }
  }, [account, provider])

  return (
    <div style={styles.container}>
      <div style={styles.content}>
        {/* Header */}
        <div style={styles.header}>
          <h1 style={styles.title}>🏛️ Complete Compliance System</h1>
          <p style={styles.subtitle}>
            All {CONTRACTS.length} Deployed Contracts • Real Blockchain Data
          </p>
        </div>

        {/* Wallet */}
        {!account ? (
          <div style={styles.connectCard}>
            <button onClick={connectWallet} style={styles.primaryButton}>
              Connect Wallet
            </button>
            <p
              style={{
                marginTop: '1rem',
                color: '#6b7280',
                fontSize: '0.875rem'
              }}
            >
              Connect to Arbitrum Sepolia testnet
            </p>
          </div>
        ) : (
          <>
            <div style={styles.walletCard}>
              <p style={styles.account}>
                Connected: {account.slice(0, 6)}...{account.slice(-4)}
              </p>
              <button
                onClick={addToAll}
                disabled={loading}
                style={styles.addAllButton}
              >
                {loading
                  ? 'Processing...'
                  : `🚀 Add Data to ALL ${CONTRACTS.length} Contracts`}
              </button>
            </div>

            {/* Contract Grid */}
            <div style={styles.grid}>
              {CONTRACTS.map((contractInfo, index) => {
                const data = contractData[contractInfo.name] || {
                  score: 0,
                  verified: false
                }
                const hasData = data.score > 0

                return (
                  <div
                    key={index}
                    style={{
                      ...styles.card,
                      border: hasData
                        ? '3px solid #10b981'
                        : '2px solid #e5e7eb',
                      background: hasData ? '#f0fdf4' : 'white'
                    }}
                  >
                    <div style={styles.cardHeader}>
                      <h3 style={styles.cardTitle}>{contractInfo.name}</h3>
                      <div
                        style={{
                          ...styles.badge,
                          background: hasData ? '#10b981' : '#ef4444',
                          color: 'white'
                        }}
                      >
                        {hasData ? '✅ Has Data' : '❌ No Data'}
                      </div>
                    </div>

                    <div style={styles.scoreDisplay}>
                      <div style={{ fontSize: '3rem' }}>
                        {hasData ? '✅' : '❌'}
                      </div>
                      <div
                        style={{
                          fontSize: '2rem',
                          fontWeight: '700',
                          color: hasData ? '#10b981' : '#9ca3af'
                        }}
                      >
                        {data.score}/100
                      </div>
                    </div>

                    {data.verified && (
                      <div style={styles.verifiedBadge}>
                        <span>🎉</span>
                        <span>Verified & Compliant</span>
                      </div>
                    )}

                    <div style={styles.addressBox}>
                      <div
                        style={{
                          fontSize: '0.75rem',
                          color: '#6b7280',
                          marginBottom: '0.25rem'
                        }}
                      >
                        Contract Address:
                      </div>
                      <a
                        href={`https://sepolia.arbiscan.io/address/${contractInfo.address}`}
                        target='_blank'
                        rel='noopener noreferrer'
                        style={styles.link}
                      >
                        {contractInfo.address.slice(0, 8)}...
                        {contractInfo.address.slice(-6)} ↗
                      </a>
                    </div>

                    <div style={styles.addressBox}>
                      <div
                        style={{
                          fontSize: '0.75rem',
                          color: '#6b7280',
                          marginBottom: '0.25rem'
                        }}
                      >
                        Deployment TX:
                      </div>
                      <a
                        href={`https://sepolia.arbiscan.io/tx/${contractInfo.tx}`}
                        target='_blank'
                        rel='noopener noreferrer'
                        style={styles.link}
                      >
                        {contractInfo.tx.slice(0, 8)}...
                        {contractInfo.tx.slice(-6)} ↗
                      </a>
                    </div>

                    <button
                      onClick={() =>
                        addData(contractInfo.address, contractInfo.name)
                      }
                      disabled={loading}
                      style={{
                        ...styles.button,
                        background: hasData ? '#10b981' : '#8b5cf6'
                      }}
                    >
                      {loading
                        ? 'Processing...'
                        : hasData
                        ? '🔄 Update Data'
                        : '➕ Add Data'}
                    </button>

                    {data.method && data.method !== 'none' && (
                      <div style={styles.methodBadge}>
                        Method: {data.method}
                      </div>
                    )}
                  </div>
                )
              })}
            </div>

            {/* Summary */}
            <div style={styles.summaryCard}>
              <h3
                style={{
                  fontSize: '1.25rem',
                  fontWeight: '700',
                  marginBottom: '1rem'
                }}
              >
                📊 System Summary
              </h3>
              <div style={styles.summaryGrid}>
                <SummaryStat
                  label='Total Contracts'
                  value={CONTRACTS.length}
                  icon='📦'
                />
                <SummaryStat
                  label='With Data'
                  value={
                    Object.values(contractData).filter(d => d.score > 0).length
                  }
                  icon='✅'
                />
                <SummaryStat
                  label='Need Data'
                  value={
                    Object.values(contractData).filter(d => d.score === 0)
                      .length
                  }
                  icon='⏳'
                />
              </div>
            </div>

            {/* Instructions */}
            <div style={styles.instructions}>
              <h3 style={{ marginBottom: '1rem' }}>📋 How to Use</h3>
              <ol style={{ lineHeight: '2', paddingLeft: '1.5rem' }}>
                <li>Click "Add Data" on individual contracts, OR</li>
                <li>
                  Click "Add Data to ALL" button at top to populate all at once
                </li>
                <li>Confirm MetaMask transactions</li>
                <li>Wait for confirmations (check Arbiscan links)</li>
                <li>
                  Green cards with ✅ have compliance data stored on-chain
                </li>
                <li>
                  All data is permanent and verifiable on Arbitrum Sepolia
                </li>
              </ol>

              <div
                style={{
                  marginTop: '1.5rem',
                  padding: '1rem',
                  background: '#fef3c7',
                  borderRadius: '8px'
                }}
              >
                <strong>⚠️ Note:</strong> This is REAL blockchain data, not mock
                data. Every transaction is permanently recorded on Arbitrum
                Sepolia and visible on Arbiscan.
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  )
}

const SummaryStat = ({ label, value, icon }) => (
  <div style={{ textAlign: 'center', padding: '1rem' }}>
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
    <div style={{ fontSize: '2rem', fontWeight: '700', color: '#1f2937' }}>
      {value}
    </div>
  </div>
)

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
  connectCard: {
    textAlign: 'center',
    background: 'white',
    padding: '3rem',
    borderRadius: '12px',
    boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
  },
  walletCard: {
    textAlign: 'center',
    background: 'white',
    padding: '1.5rem',
    borderRadius: '12px',
    boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
    marginBottom: '2rem'
  },
  account: {
    fontSize: '1rem',
    color: '#6b7280',
    marginBottom: '1rem'
  },
  addAllButton: {
    padding: '1rem 2rem',
    background: '#10b981',
    color: 'white',
    border: 'none',
    borderRadius: '8px',
    fontSize: '1rem',
    fontWeight: '700',
    cursor: 'pointer'
  },
  grid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(350px, 1fr))',
    gap: '1.5rem',
    marginBottom: '2rem'
  },
  card: {
    background: 'white',
    padding: '1.5rem',
    borderRadius: '12px',
    boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
  },
  cardHeader: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: '1rem'
  },
  cardTitle: {
    fontSize: '1.125rem',
    fontWeight: '600',
    flex: 1
  },
  badge: {
    padding: '0.25rem 0.75rem',
    borderRadius: '999px',
    fontSize: '0.75rem',
    fontWeight: '600'
  },
  scoreDisplay: {
    textAlign: 'center',
    padding: '1.5rem',
    marginBottom: '1rem'
  },
  verifiedBadge: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    gap: '0.5rem',
    padding: '0.75rem',
    background: '#10b98115',
    border: '2px solid #10b981',
    borderRadius: '8px',
    marginBottom: '1rem',
    fontWeight: '600',
    color: '#10b981'
  },
  addressBox: {
    padding: '0.75rem',
    background: '#f9fafb',
    borderRadius: '6px',
    marginBottom: '0.75rem',
    fontFamily: 'monospace',
    fontSize: '0.875rem'
  },
  link: {
    color: '#3b82f6',
    textDecoration: 'none',
    wordBreak: 'break-all'
  },
  button: {
    width: '100%',
    padding: '0.75rem',
    color: 'white',
    border: 'none',
    borderRadius: '8px',
    fontSize: '1rem',
    fontWeight: '600',
    cursor: 'pointer',
    marginBottom: '0.5rem'
  },
  methodBadge: {
    textAlign: 'center',
    fontSize: '0.75rem',
    color: '#9ca3af',
    fontFamily: 'monospace'
  },
  summaryCard: {
    background: 'white',
    padding: '2rem',
    borderRadius: '12px',
    boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
    marginBottom: '2rem'
  },
  summaryGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(3, 1fr)',
    gap: '1rem'
  },
  instructions: {
    background: 'white',
    padding: '2rem',
    borderRadius: '12px',
    boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
  },
  primaryButton: {
    padding: '1rem 2rem',
    background: '#8b5cf6',
    color: 'white',
    border: 'none',
    borderRadius: '8px',
    fontSize: '1.125rem',
    fontWeight: '700',
    cursor: 'pointer'
  }
}

export default App

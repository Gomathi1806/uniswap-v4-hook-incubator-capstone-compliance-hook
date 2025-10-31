import React, { useState, useEffect } from 'react'
import { ethers } from 'ethers'

const App = () => {
  const [account, setAccount] = useState('')
  const [balance, setBalance] = useState('0')
  const [provider, setProvider] = useState(null)
  const [signer, setSigner] = useState(null)
  const [loading, setLoading] = useState(false)
  const [assessmentStatus, setAssessmentStatus] = useState('Inactive')

  // Risk Assessment Data
  const [riskData, setRiskData] = useState({
    overall: 0,
    compliance: 0,
    txHistory: 0,
    sanctions: 0
  })

  // Compliance Data
  const [complianceData, setComplianceData] = useState({
    kycScore: 0,
    amlScore: 0,
    sanctionsScore: 0,
    verified: false,
    sanctioned: false
  })

  // Contract Addresses
  const CONTRACTS = {
    riskCalculator: '0xcFb57c670A5a502Cf8517376cDa0Dd11a4b5A2AF',
    chainlinkOracle: '0xd3907fC7662b59D8837e722367bEc10bf1010EfC',
    fhenixFHE: '0x780ADC17caC8B0F87CA8722B0A0c91E473d2D1dc'
  }

  // ABI for the Risk Calculator contract
  const RISK_CALCULATOR_ABI = [
    'function calculateRisk(address user) external view returns (uint256)',
    'function getComplianceScore(address user) external view returns (uint256)',
    'function assessProfile(address user) external returns (bool)',
    'function getRiskProfile(address user) external view returns (uint256 overall, uint256 compliance, uint256 txHistory, uint256 sanctions)'
  ]

  // Connect Wallet
  const connectWallet = async () => {
    try {
      if (typeof window.ethereum !== 'undefined') {
        const accounts = await window.ethereum.request({
          method: 'eth_requestAccounts'
        })

        const web3Provider = new ethers.BrowserProvider(window.ethereum)
        const web3Signer = await web3Provider.getSigner()
        const userBalance = await web3Provider.getBalance(accounts[0])

        setAccount(accounts[0])
        setBalance(ethers.formatEther(userBalance))
        setProvider(web3Provider)
        setSigner(web3Signer)
      } else {
        alert('Please install MetaMask!')
      }
    } catch (error) {
      console.error('Error connecting wallet:', error)
      alert('Failed to connect wallet: ' + error.message)
    }
  }

  // Submit for Assessment
  const submitAssessment = async () => {
    if (!signer || !account) {
      alert('Please connect your wallet first!')
      return
    }

    setLoading(true)
    try {
      // Initialize contract
      const riskContract = new ethers.Contract(
        CONTRACTS.riskCalculator,
        RISK_CALCULATOR_ABI,
        signer
      )

      console.log('Submitting assessment for:', account)

      // Call the assess function on the contract
      const tx = await riskContract.assessProfile(account)
      console.log('Transaction submitted:', tx.hash)

      // Wait for transaction confirmation
      const receipt = await tx.wait()
      console.log('Transaction confirmed:', receipt)

      // Fetch the updated risk profile
      await fetchRiskProfile()

      setAssessmentStatus('Active')
      alert('Assessment completed successfully!')
    } catch (error) {
      console.error('Error during assessment:', error)
      alert('Assessment failed: ' + error.message)
    } finally {
      setLoading(false)
    }
  }

  // Fetch Risk Profile Data
  const fetchRiskProfile = async () => {
    if (!provider || !account) return

    try {
      const riskContract = new ethers.Contract(
        CONTRACTS.riskCalculator,
        RISK_CALCULATOR_ABI,
        provider
      )

      // Get risk profile data
      const profile = await riskContract.getRiskProfile(account)

      setRiskData({
        overall: Number(profile.overall),
        compliance: Number(profile.compliance),
        txHistory: Number(profile.txHistory),
        sanctions: Number(profile.sanctions)
      })

      // Simulate compliance data (you can add more contract calls here)
      setComplianceData({
        kycScore: Math.floor(Math.random() * 100),
        amlScore: Math.floor(Math.random() * 100),
        sanctionsScore: Number(profile.sanctions),
        verified: Number(profile.compliance) > 50,
        sanctioned: Number(profile.sanctions) > 70
      })
    } catch (error) {
      console.error('Error fetching risk profile:', error)
    }
  }

  // Auto-fetch data when account changes
  useEffect(() => {
    if (account && provider) {
      fetchRiskProfile()
    }
  }, [account, provider])

  return (
    <div
      style={{
        minHeight: '100vh',
        background: 'linear-gradient(to bottom, #f9fafb, #f3f4f6)',
        padding: '2rem'
      }}
    >
      <div style={{ maxWidth: '1200px', margin: '0 auto' }}>
        {/* Header */}
        <div style={{ textAlign: 'center', marginBottom: '3rem' }}>
          <h1
            style={{
              fontSize: '3rem',
              fontWeight: 'bold',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '1rem'
            }}
          >
            <span style={{ fontSize: '3rem' }}>🦄</span>
            Uniswap V4 Compliance Hook
          </h1>
          <p
            style={{
              fontSize: '1.25rem',
              color: '#6b7280',
              marginTop: '0.5rem'
            }}
          >
            Automated Risk Assessment System
          </p>
        </div>

        {/* Wallet Connection */}
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
            <button
              onClick={connectWallet}
              style={{
                background: '#ff007a',
                color: 'white',
                padding: '0.75rem 2rem',
                borderRadius: '8px',
                border: 'none',
                fontSize: '1rem',
                fontWeight: '600',
                cursor: 'pointer',
                transition: 'all 0.2s'
              }}
              onMouseOver={e => (e.target.style.background = '#e6006d')}
              onMouseOut={e => (e.target.style.background = '#ff007a')}
            >
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
                {account.slice(0, 6)}...{account.slice(-4)} | Balance:{' '}
                {parseFloat(balance).toFixed(4)} ETH
              </p>
            </div>
          )}
        </div>

        {/* Contract Addresses */}
        {account && (
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
              gap: '1rem',
              marginBottom: '2rem'
            }}
          >
            <ContractCard
              title='Risk Calculator'
              address={CONTRACTS.riskCalculator}
              color='#10b981'
            />
            <ContractCard
              title='Chainlink Oracle'
              address={CONTRACTS.chainlinkOracle}
              color='#3b82f6'
            />
            <ContractCard
              title='Fhenix FHE'
              address={CONTRACTS.fhenixFHE}
              color='#8b5cf6'
            />
          </div>
        )}

        {/* Assessment Button */}
        {account && (
          <div
            style={{
              textAlign: 'center',
              marginBottom: '2rem'
            }}
          >
            <button
              onClick={submitAssessment}
              disabled={loading}
              style={{
                background: loading ? '#9ca3af' : '#10b981',
                color: 'white',
                padding: '1rem 3rem',
                borderRadius: '12px',
                border: 'none',
                fontSize: '1.125rem',
                fontWeight: '600',
                cursor: loading ? 'not-allowed' : 'pointer',
                transition: 'all 0.2s',
                boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
                display: 'inline-flex',
                alignItems: 'center',
                gap: '0.5rem'
              }}
              onMouseOver={e => {
                if (!loading) e.target.style.background = '#059669'
              }}
              onMouseOut={e => {
                if (!loading) e.target.style.background = '#10b981'
              }}
            >
              {loading ? (
                <>
                  <span
                    className='spinner'
                    style={{
                      border: '3px solid rgba(255,255,255,0.3)',
                      borderTop: '3px solid white',
                      borderRadius: '50%',
                      width: '20px',
                      height: '20px',
                      animation: 'spin 1s linear infinite'
                    }}
                  ></span>
                  Processing Assessment...
                </>
              ) : (
                <>🔍 Submit for Assessment</>
              )}
            </button>
          </div>
        )}

        {/* Risk Assessment */}
        {account && (
          <div
            style={{
              background: 'white',
              borderRadius: '12px',
              padding: '2rem',
              marginBottom: '2rem',
              boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
            }}
          >
            <h2
              style={{
                fontSize: '1.875rem',
                fontWeight: '700',
                marginBottom: '1.5rem'
              }}
            >
              Risk Assessment
            </h2>

            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
                gap: '1rem',
                marginBottom: '1.5rem'
              }}
            >
              <MetricCard
                label='Overall'
                value={riskData.overall}
                color='#3b82f6'
              />
              <MetricCard
                label='Compliance'
                value={riskData.compliance}
                color='#10b981'
              />
              <MetricCard
                label='TX History'
                value={riskData.txHistory}
                color='#f59e0b'
              />
              <MetricCard
                label='Sanctions'
                value={riskData.sanctions}
                color='#8b5cf6'
              />
            </div>

            <div
              style={{
                padding: '1rem',
                background:
                  assessmentStatus === 'Active' ? '#d1fae5' : '#fee2e2',
                borderRadius: '8px',
                border: `2px solid ${
                  assessmentStatus === 'Active' ? '#10b981' : '#ef4444'
                }`,
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem'
              }}
            >
              <span style={{ fontSize: '1.5rem' }}>
                {assessmentStatus === 'Active' ? '✅' : '❌'}
              </span>
              <span
                style={{
                  fontWeight: '600',
                  color: assessmentStatus === 'Active' ? '#065f46' : '#991b1b'
                }}
              >
                Profile Status: {assessmentStatus}
              </span>
            </div>
          </div>
        )}

        {/* Compliance Data */}
        {account && (
          <div
            style={{
              background: 'white',
              borderRadius: '12px',
              padding: '2rem',
              boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
            }}
          >
            <h2
              style={{
                fontSize: '1.875rem',
                fontWeight: '700',
                marginBottom: '1.5rem'
              }}
            >
              Compliance Data
            </h2>

            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
                gap: '1rem',
                marginBottom: '1.5rem'
              }}
            >
              <ComplianceCard
                label='KYC Score'
                value={complianceData.kycScore}
                color='#3b82f6'
              />
              <ComplianceCard
                label='AML Score'
                value={complianceData.amlScore}
                color='#10b981'
              />
              <ComplianceCard
                label='Sanctions'
                value={complianceData.sanctionsScore}
                color='#f59e0b'
              />
            </div>

            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
                gap: '1rem'
              }}
            >
              <StatusCard
                label='Verified'
                status={complianceData.verified}
                icon={complianceData.verified ? '✅' : '❌'}
              />
              <StatusCard
                label='Sanctioned'
                status={!complianceData.sanctioned}
                icon={complianceData.sanctioned ? '⚠️' : '✅'}
              />
            </div>
          </div>
        )}

        {/* CSS Animation */}
        <style>{`
          @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
          }
        `}</style>
      </div>
    </div>
  )
}

// Component: Contract Card
const ContractCard = ({ title, address, color }) => (
  <div
    style={{
      background: 'white',
      padding: '1rem',
      borderRadius: '8px',
      borderLeft: `4px solid ${color}`,
      boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
    }}
  >
    <h3
      style={{
        fontSize: '0.875rem',
        fontWeight: '600',
        marginBottom: '0.5rem'
      }}
    >
      {title}
    </h3>
    <p
      style={{
        fontSize: '0.75rem',
        color: color,
        fontFamily: 'monospace',
        wordBreak: 'break-all'
      }}
    >
      {address}
    </p>
  </div>
)

// Component: Metric Card
const MetricCard = ({ label, value, color }) => (
  <div
    style={{
      background: '#f9fafb',
      padding: '1.5rem',
      borderRadius: '8px',
      textAlign: 'center'
    }}
  >
    <p
      style={{
        fontSize: '3rem',
        fontWeight: '700',
        color: color,
        marginBottom: '0.5rem'
      }}
    >
      {value}
    </p>
    <p
      style={{
        fontSize: '0.875rem',
        color: '#6b7280',
        fontWeight: '500'
      }}
    >
      {label}
    </p>
  </div>
)

// Component: Compliance Card
const ComplianceCard = ({ label, value, color }) => (
  <div
    style={{
      background: `${color}15`,
      padding: '1.5rem',
      borderRadius: '8px'
    }}
  >
    <p
      style={{
        fontSize: '0.875rem',
        color: '#6b7280',
        marginBottom: '0.5rem'
      }}
    >
      {label}
    </p>
    <p
      style={{
        fontSize: '2rem',
        fontWeight: '700',
        color: color
      }}
    >
      {value}
    </p>
  </div>
)

// Component: Status Card
const StatusCard = ({ label, status, icon }) => (
  <div
    style={{
      padding: '1rem',
      background: status ? '#d1fae5' : '#fee2e2',
      borderRadius: '8px',
      border: `2px solid ${status ? '#10b981' : '#ef4444'}`,
      display: 'flex',
      alignItems: 'center',
      gap: '0.5rem'
    }}
  >
    <span style={{ fontSize: '1.5rem' }}>{icon}</span>
    <span
      style={{
        fontWeight: '600',
        color: status ? '#065f46' : '#991b1b'
      }}
    >
      {label}: {status ? 'Yes' : 'No'}
    </span>
  </div>
)

export default App

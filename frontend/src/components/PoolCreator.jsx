import React, { useState, useEffect } from 'react'
import { ethers } from 'ethers'

/**
 * PoolCreator Component
 * @description UI for creating tiered compliance pools
 */
const PoolCreator = ({ account, signer, hookAddress }) => {
  const [poolConfig, setPoolConfig] = useState({
    tier: 'PUBLIC',
    tokenA: '',
    tokenB: '',
    fee: '3000', // 0.30% in hundredths of bps
    requiresWhitelist: false,
    protocolFeeBps: '0'
  })

  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  // Tier descriptions
  const tierInfo = {
    PUBLIC: {
      name: 'Public Pool',
      icon: '🌐',
      color: '#10b981',
      minScore: 50,
      description: 'Open to all retail traders with basic screening',
      requirements: [
        'Risk score ≥ 50',
        'Not sanctioned',
        'Not high risk',
        'No KYC required'
      ],
      protocolFee: '0%'
    },
    VERIFIED: {
      name: 'Verified Pool',
      icon: '💼',
      color: '#3b82f6',
      minScore: 75,
      description: 'Accredited investors with KYC verification',
      requirements: [
        'Risk score ≥ 75',
        'KYC verified',
        'Enhanced screening',
        'Compliance certificate'
      ],
      protocolFee: '0.03%'
    },
    INSTITUTIONAL: {
      name: 'Institutional Pool',
      icon: '🏛️',
      color: '#8b5cf6',
      minScore: 90,
      description: 'Banks, hedge funds, and institutional participants',
      requirements: [
        'Risk score ≥ 90',
        'Entity registration',
        'Full compliance',
        'Optional whitelist',
        'Audit trail'
      ],
      protocolFee: '0.05%+'
    }
  }

  const commonTokens = [
    { symbol: 'ETH', address: '0x0000000000000000000000000000000000000000' },
    { symbol: 'USDC', address: '0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d' },
    { symbol: 'USDT', address: '0xf7F6718Cf69967203740cCb431F6bDBff1E0FB68' },
    { symbol: 'DAI', address: '0xc8cAEE7F5D1E19CcB1C17BFA44B8B20D94b6B6b7' },
    { symbol: 'WETH', address: '0x980B62Da83eFf3D4576C647993b0c1D7faf17c73' }
  ]

  const createPool = async () => {
    if (!signer || !account) {
      setError('Please connect your wallet first')
      return
    }

    if (!poolConfig.tokenA || !poolConfig.tokenB) {
      setError('Please select both tokens')
      return
    }

    if (poolConfig.tokenA === poolConfig.tokenB) {
      setError('Tokens must be different')
      return
    }

    setLoading(true)
    setError('')
    setSuccess('')

    try {
      console.log('Creating pool with config:', poolConfig)

      // Encode hook data (tier, requiresWhitelist, protocolFeeBps)
      const tierEnum = poolConfig.tier === 'PUBLIC' ? 0 : poolConfig.tier === 'VERIFIED' ? 1 : 2
      const hookData = ethers.AbiCoder.defaultAbiCoder().encode(
        ['uint8', 'bool', 'uint256'],
        [tierEnum, poolConfig.requiresWhitelist, poolConfig.protocolFeeBps]
      )

      console.log('Hook data:', hookData)

      // In production, you would:
      // 1. Call PoolManager.initialize() with the pool key and hook data
      // 2. This requires the Uniswap V4 SDK or direct contract interaction
      
      // For now, we'll show how the data is structured:
      console.log('Pool will be created with:')
      console.log('- Tier:', poolConfig.tier)
      console.log('- Token A:', poolConfig.tokenA)
      console.log('- Token B:', poolConfig.tokenB)
      console.log('- Fee:', poolConfig.fee)
      console.log('- Whitelist:', poolConfig.requiresWhitelist)
      console.log('- Protocol Fee:', poolConfig.protocolFeeBps, 'bps')

      // Simulate transaction for demo
      await new Promise(resolve => setTimeout(resolve, 2000))

      setSuccess(`${poolConfig.tier} pool created successfully! (Simulated)`)
      
      // Reset form
      setPoolConfig({
        ...poolConfig,
        tokenA: '',
        tokenB: '',
        requiresWhitelist: false
      })

    } catch (err) {
      console.error('Error creating pool:', err)
      setError('Failed to create pool: ' + err.message)
    } finally {
      setLoading(false)
    }
  }

  const tier = tierInfo[poolConfig.tier]

  return (
    <div style={{ maxWidth: '800px', margin: '0 auto', padding: '2rem' }}>
      {/* Header */}
      <div style={{ textAlign: 'center', marginBottom: '3rem' }}>
        <h1 style={{ fontSize: '2.5rem', fontWeight: 'bold', marginBottom: '1rem' }}>
          Create Compliant Pool
        </h1>
        <p style={{ fontSize: '1.125rem', color: '#6b7280' }}>
          Deploy a new liquidity pool with built-in compliance checks
        </p>
      </div>

      {/* Tier Selection */}
      <div style={{ marginBottom: '2rem' }}>
        <label style={{ display: 'block', fontWeight: '600', marginBottom: '1rem' }}>
          Select Compliance Tier:
        </label>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1rem' }}>
          {Object.keys(tierInfo).map(tierKey => {
            const info = tierInfo[tierKey]
            const selected = poolConfig.tier === tierKey
            return (
              <div
                key={tierKey}
                onClick={() => setPoolConfig({ ...poolConfig, tier: tierKey })}
                style={{
                  padding: '1.5rem',
                  border: `2px solid ${selected ? info.color : '#e5e7eb'}`,
                  borderRadius: '12px',
                  cursor: 'pointer',
                  background: selected ? `${info.color}15` : 'white',
                  transition: 'all 0.2s'
                }}
              >
                <div style={{ fontSize: '2rem', marginBottom: '0.5rem' }}>{info.icon}</div>
                <div style={{ fontWeight: '600', marginBottom: '0.5rem' }}>{info.name}</div>
                <div style={{ fontSize: '0.875rem', color: '#6b7280' }}>
                  Min Score: {info.minScore}
                </div>
              </div>
            )
          })}
        </div>
      </div>

      {/* Tier Details */}
      <div
        style={{
          padding: '1.5rem',
          background: `${tier.color}15`,
          border: `2px solid ${tier.color}`,
          borderRadius: '12px',
          marginBottom: '2rem'
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1rem' }}>
          <span style={{ fontSize: '2.5rem' }}>{tier.icon}</span>
          <div>
            <h3 style={{ fontSize: '1.5rem', fontWeight: '700', marginBottom: '0.25rem' }}>
              {tier.name}
            </h3>
            <p style={{ color: '#6b7280' }}>{tier.description}</p>
          </div>
        </div>

        <div style={{ marginTop: '1rem' }}>
          <div style={{ fontWeight: '600', marginBottom: '0.5rem' }}>Requirements:</div>
          <ul style={{ listStyle: 'none', padding: 0 }}>
            {tier.requirements.map((req, i) => (
              <li key={i} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.25rem' }}>
                <span style={{ color: tier.color }}>✓</span>
                <span style={{ fontSize: '0.875rem' }}>{req}</span>
              </li>
            ))}
          </ul>
        </div>

        <div style={{ marginTop: '1rem', padding: '0.75rem', background: 'white', borderRadius: '8px' }}>
          <span style={{ fontWeight: '600' }}>Protocol Fee: </span>
          <span style={{ color: tier.color }}>{tier.protocolFee}</span>
        </div>
      </div>

      {/* Token Selection */}
      <div style={{ marginBottom: '2rem' }}>
        <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem' }}>
          Token A:
        </label>
        <select
          value={poolConfig.tokenA}
          onChange={(e) => setPoolConfig({ ...poolConfig, tokenA: e.target.value })}
          style={{
            width: '100%',
            padding: '0.75rem',
            border: '2px solid #e5e7eb',
            borderRadius: '8px',
            fontSize: '1rem'
          }}
        >
          <option value="">Select Token</option>
          {commonTokens.map(token => (
            <option key={token.address} value={token.address}>
              {token.symbol}
            </option>
          ))}
        </select>
      </div>

      <div style={{ marginBottom: '2rem' }}>
        <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem' }}>
          Token B:
        </label>
        <select
          value={poolConfig.tokenB}
          onChange={(e) => setPoolConfig({ ...poolConfig, tokenB: e.target.value })}
          style={{
            width: '100%',
            padding: '0.75rem',
            border: '2px solid #e5e7eb',
            borderRadius: '8px',
            fontSize: '1rem'
          }}
        >
          <option value="">Select Token</option>
          {commonTokens.map(token => (
            <option key={token.address} value={token.address}>
              {token.symbol}
            </option>
          ))}
        </select>
      </div>

      {/* Fee Tier */}
      <div style={{ marginBottom: '2rem' }}>
        <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem' }}>
          Trading Fee:
        </label>
        <select
          value={poolConfig.fee}
          onChange={(e) => setPoolConfig({ ...poolConfig, fee: e.target.value })}
          style={{
            width: '100%',
            padding: '0.75rem',
            border: '2px solid #e5e7eb',
            borderRadius: '8px',
            fontSize: '1rem'
          }}
        >
          <option value="500">0.05% (Stable pairs)</option>
          <option value="3000">0.30% (Standard)</option>
          <option value="10000">1.00% (Exotic pairs)</option>
        </select>
      </div>

      {/* Institutional Options */}
      {poolConfig.tier === 'INSTITUTIONAL' && (
        <>
          <div style={{ marginBottom: '2rem' }}>
            <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', cursor: 'pointer' }}>
              <input
                type="checkbox"
                checked={poolConfig.requiresWhitelist}
                onChange={(e) => setPoolConfig({ ...poolConfig, requiresWhitelist: e.target.checked })}
                style={{ width: '20px', height: '20px' }}
              />
              <span style={{ fontWeight: '600' }}>Require Whitelist</span>
            </label>
            <p style={{ fontSize: '0.875rem', color: '#6b7280', marginTop: '0.5rem', marginLeft: '1.75rem' }}>
              Only whitelisted institutional participants can trade in this pool
            </p>
          </div>

          <div style={{ marginBottom: '2rem' }}>
            <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem' }}>
              Protocol Fee (basis points):
            </label>
            <input
              type="number"
              value={poolConfig.protocolFeeBps}
              onChange={(e) => setPoolConfig({ ...poolConfig, protocolFeeBps: e.target.value })}
              min="5"
              max="100"
              style={{
                width: '100%',
                padding: '0.75rem',
                border: '2px solid #e5e7eb',
                borderRadius: '8px',
                fontSize: '1rem'
              }}
            />
            <p style={{ fontSize: '0.875rem', color: '#6b7280', marginTop: '0.5rem' }}>
              Min 5 bps (0.05%) for institutional pools. 100 bps = 1%
            </p>
          </div>
        </>
      )}

      {/* Error/Success Messages */}
      {error && (
        <div style={{
          padding: '1rem',
          background: '#fee2e2',
          border: '2px solid #ef4444',
          borderRadius: '8px',
          marginBottom: '1rem',
          color: '#991b1b'
        }}>
          {error}
        </div>
      )}

      {success && (
        <div style={{
          padding: '1rem',
          background: '#d1fae5',
          border: '2px solid #10b981',
          borderRadius: '8px',
          marginBottom: '1rem',
          color: '#065f46'
        }}>
          {success}
        </div>
      )}

      {/* Create Button */}
      <button
        onClick={createPool}
        disabled={loading || !account}
        style={{
          width: '100%',
          padding: '1rem',
          background: loading || !account ? '#9ca3af' : tier.color,
          color: 'white',
          border: 'none',
          borderRadius: '12px',
          fontSize: '1.125rem',
          fontWeight: '600',
          cursor: loading || !account ? 'not-allowed' : 'pointer',
          transition: 'all 0.2s'
        }}
      >
        {loading ? 'Creating Pool...' : `Create ${tier.name}`}
      </button>

      {/* Info Box */}
      <div style={{
        marginTop: '2rem',
        padding: '1rem',
        background: '#f9fafb',
        border: '1px solid #e5e7eb',
        borderRadius: '8px'
      }}>
        <div style={{ fontWeight: '600', marginBottom: '0.5rem' }}>ℹ️ How it works:</div>
        <ol style={{ fontSize: '0.875rem', color: '#6b7280', paddingLeft: '1.25rem' }}>
          <li>Pool is created with your selected compliance tier</li>
          <li>Hook automatically enforces tier requirements on every swap</li>
          <li>Only compliant users can trade in your pool</li>
          <li>All checks happen in real-time during swaps</li>
          <li>You earn trading fees + protocol fees (institutional only)</li>
        </ol>
      </div>
    </div>
  )
}

export default PoolCreator

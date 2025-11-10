// ADD THIS TO YOUR App.js - Pool Checker Feature

// Add to state variables (top of App component):
const [poolAddress, setPoolAddress] = useState('')
const [poolData, setPoolData] = useState(null)
const [canSwapInPool, setCanSwapInPool] = useState(null)

// Add to HOOK_ABI array:
const HOOK_ABI = [
  // ... existing ABIs ...
  'function poolConfigs(bytes32 poolId) external view returns (uint8 tier, address creator, bool requiresWhitelist, uint256 protocolFeeBps, uint256 createdAt)',
  'function poolWhitelist(bytes32 poolId, address user) external view returns (bool)',
  'function getPoolStats() external view returns (uint256, uint256, uint256, uint256)'
]

// Add this function:
const checkPool = async () => {
  if (!provider) {
    alert('Please connect your wallet first!')
    return
  }

  if (!poolAddress || poolAddress.length !== 66) {
    alert('Invalid pool ID! Should be 66 characters (0x + 64 hex chars)')
    return
  }

  setLoading(true)
  try {
    const hookContract = new ethers.Contract(CONTRACTS.hook, HOOK_ABI, provider)

    // Get pool config
    const config = await hookContract.poolConfigs(poolAddress)

    const tierNames = ['PUBLIC', 'VERIFIED', 'INSTITUTIONAL']
    const poolTier = tierNames[config.tier]

    // Check if current user can swap
    let canSwap = false
    let reason = ''

    if (account) {
      const userLevel = await hookContract.getUserComplianceLevel(account)

      if (userLevel === 'BLACKLISTED') {
        canSwap = false
        reason = 'You are blacklisted'
      } else if (userLevel === 'WHITELISTED') {
        canSwap = true
        reason = 'You are whitelisted (can access any pool)'
      } else {
        // Check tier hierarchy
        const tierOrder = {
          NON_COMPLIANT: 0,
          PUBLIC: 1,
          VERIFIED: 2,
          INSTITUTIONAL: 3
        }

        const userTierLevel = tierOrder[userLevel] || 0
        const requiredLevel = config.tier + 1

        if (userTierLevel >= requiredLevel) {
          // Check whitelist if required
          if (config.requiresWhitelist) {
            const isWhitelisted = await hookContract.poolWhitelist(
              poolAddress,
              account
            )
            canSwap = isWhitelisted
            reason = isWhitelisted
              ? `You are whitelisted for this ${poolTier} pool`
              : `This ${poolTier} pool requires whitelist (you're not on it)`
          } else {
            canSwap = true
            reason = `Your tier (${userLevel}) meets ${poolTier} requirements`
          }
        } else {
          canSwap = false
          reason = `Pool requires ${poolTier} tier, you are ${userLevel}`
        }
      }

      setCanSwapInPool({ can: canSwap, reason })
    }

    setPoolData({
      id: poolAddress,
      tier: poolTier,
      creator: config.creator,
      requiresWhitelist: config.requiresWhitelist,
      protocolFee: Number(config.protocolFeeBps) / 100, // Convert basis points to percentage
      createdAt: new Date(Number(config.createdAt) * 1000).toLocaleDateString()
    })
  } catch (error) {
    console.error('Error checking pool:', error)

    if (error.message.includes('call revert exception')) {
      alert('Pool not found or not using this compliance hook')
    } else {
      alert('Failed to check pool: ' + error.message)
    }
  } finally {
    setLoading(false)
  }
}

// Add this new view component:
const PoolCheckerView = ({
  poolAddress,
  setPoolAddress,
  checkPool,
  poolData,
  canSwapInPool,
  loading
}) => (
  <div>
    {/* Pool Checker */}
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
        🔍 Check Pool Compliance
      </h2>

      <div style={{ marginBottom: '1rem' }}>
        <label
          style={{
            display: 'block',
            fontWeight: '600',
            marginBottom: '0.5rem'
          }}
        >
          Pool ID (bytes32):
        </label>
        <input
          type='text'
          value={poolAddress}
          onChange={e => setPoolAddress(e.target.value)}
          placeholder='0x123abc... (66 characters)'
          style={{
            width: '100%',
            padding: '0.75rem',
            border: '2px solid #e5e7eb',
            borderRadius: '8px',
            fontSize: '0.875rem',
            fontFamily: 'monospace'
          }}
        />
        <p
          style={{
            fontSize: '0.75rem',
            color: '#6b7280',
            marginTop: '0.25rem'
          }}
        >
          Enter the pool ID you want to check (starts with 0x, 66 characters
          total)
        </p>
      </div>

      <button
        onClick={checkPool}
        disabled={loading}
        style={{
          background: loading ? '#9ca3af' : '#3b82f6',
          color: 'white',
          padding: '0.75rem 2rem',
          borderRadius: '8px',
          border: 'none',
          fontSize: '1rem',
          fontWeight: '600',
          cursor: loading ? 'not-allowed' : 'pointer'
        }}
      >
        {loading ? 'Checking...' : '🔍 Check Pool'}
      </button>
    </div>

    {/* Pool Results */}
    {poolData && (
      <div
        style={{
          background: 'white',
          borderRadius: '12px',
          padding: '2rem',
          marginBottom: '2rem',
          boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
        }}
      >
        <h3
          style={{
            fontSize: '1.5rem',
            fontWeight: '700',
            marginBottom: '1rem'
          }}
        >
          Pool Information
        </h3>

        <div style={{ display: 'grid', gap: '1rem' }}>
          {/* Tier Badge */}
          <div
            style={{
              padding: '1rem',
              background: getTierColor(poolData.tier) + '15',
              borderRadius: '8px',
              border: `2px solid ${getTierColor(poolData.tier)}`
            }}
          >
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem',
                marginBottom: '0.5rem'
              }}
            >
              <span style={{ fontSize: '1.5rem' }}>
                {getTierIcon(poolData.tier)}
              </span>
              <strong
                style={{
                  fontSize: '1.25rem',
                  color: getTierColor(poolData.tier)
                }}
              >
                {poolData.tier} POOL
              </strong>
            </div>
            <div style={{ fontSize: '0.875rem', color: '#6b7280' }}>
              {getTierDescription(poolData.tier)}
            </div>
          </div>

          {/* Pool Details */}
          <div
            style={{
              padding: '1rem',
              background: '#f9fafb',
              borderRadius: '8px'
            }}
          >
            <div style={{ marginBottom: '0.5rem' }}>
              <strong>Creator:</strong>{' '}
              <code style={{ fontSize: '0.875rem' }}>
                {poolData.creator.slice(0, 6)}...{poolData.creator.slice(-4)}
              </code>
            </div>
            <div style={{ marginBottom: '0.5rem' }}>
              <strong>Whitelist Required:</strong>{' '}
              {poolData.requiresWhitelist ? '✅ Yes' : '❌ No'}
            </div>
            <div style={{ marginBottom: '0.5rem' }}>
              <strong>Protocol Fee:</strong> {poolData.protocolFee}%
            </div>
            <div>
              <strong>Created:</strong> {poolData.createdAt}
            </div>
          </div>

          {/* Can You Trade? */}
          {canSwapInPool && (
            <div
              style={{
                padding: '1.5rem',
                background: canSwapInPool.can ? '#10b98115' : '#ef444415',
                borderRadius: '8px',
                border: `2px solid ${canSwapInPool.can ? '#10b981' : '#ef4444'}`
              }}
            >
              <div
                style={{
                  fontSize: '1.5rem',
                  fontWeight: '700',
                  color: canSwapInPool.can ? '#10b981' : '#ef4444',
                  marginBottom: '0.5rem',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.5rem'
                }}
              >
                {canSwapInPool.can ? '✅ You Can Trade' : '❌ Cannot Trade'}
              </div>
              <div style={{ fontSize: '1rem', color: '#374151' }}>
                {canSwapInPool.reason}
              </div>
            </div>
          )}
        </div>
      </div>
    )}

    {/* Pool Stats */}
    <PoolStatsView />
  </div>
)

// Helper component for pool stats
const PoolStatsView = () => {
  const [stats, setStats] = useState(null)

  useEffect(() => {
    const fetchStats = async () => {
      if (!provider) return

      try {
        const hookContract = new ethers.Contract(
          CONTRACTS.hook,
          HOOK_ABI,
          provider
        )
        const [total, publicCount, verifiedCount, institutionalCount] =
          await hookContract.getPoolStats()

        setStats({
          total: Number(total),
          public: Number(publicCount),
          verified: Number(verifiedCount),
          institutional: Number(institutionalCount)
        })
      } catch (error) {
        console.error('Error fetching pool stats:', error)
      }
    }

    fetchStats()
  }, [provider])

  if (!stats) return null

  return (
    <div
      style={{
        background: 'white',
        borderRadius: '12px',
        padding: '2rem',
        boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
      }}
    >
      <h3
        style={{ fontSize: '1.5rem', fontWeight: '700', marginBottom: '1rem' }}
      >
        📊 Network Pool Statistics
      </h3>

      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))',
          gap: '1rem'
        }}
      >
        <StatCard
          label='Total Pools'
          value={stats.total}
          color='#6b7280'
          icon='🏊'
        />
        <StatCard
          label='Public'
          value={stats.public}
          color='#10b981'
          icon='🌐'
        />
        <StatCard
          label='Verified'
          value={stats.verified}
          color='#3b82f6'
          icon='💼'
        />
        <StatCard
          label='Institutional'
          value={stats.institutional}
          color='#8b5cf6'
          icon='🏛️'
        />
      </div>
    </div>
  )
}

// Helper component
const StatCard = ({ label, value, color, icon }) => (
  <div
    style={{
      padding: '1rem',
      background: `${color}15`,
      borderRadius: '8px',
      textAlign: 'center'
    }}
  >
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

// Helper functions
const getTierColor = tier => {
  const colors = {
    PUBLIC: '#10b981',
    VERIFIED: '#3b82f6',
    INSTITUTIONAL: '#8b5cf6'
  }
  return colors[tier] || '#6b7280'
}

const getTierIcon = tier => {
  const icons = {
    PUBLIC: '🌐',
    VERIFIED: '💼',
    INSTITUTIONAL: '🏛️'
  }
  return icons[tier] || '❓'
}

const getTierDescription = tier => {
  const descriptions = {
    PUBLIC: 'Open to all users with basic compliance (score ≥ 50)',
    VERIFIED: 'Requires enhanced compliance and KYC (score ≥ 75)',
    INSTITUTIONAL: 'Institutional entities only (score ≥ 90 + registration)'
  }
  return descriptions[tier] || 'Unknown tier'
}

// ADD TO NAVIGATION:
// In your navigation section, add:
// <NavButton label="🏊 Check Pool" active={currentView === 'pool-checker'} onClick={() => setCurrentView('pool-checker')} />

// ADD TO VIEW SWITCHING:
// In your main content area, add:
// {currentView === 'pool-checker' && (
//   <PoolCheckerView
//     poolAddress={poolAddress}
//     setPoolAddress={setPoolAddress}
//     checkPool={checkPool}
//     poolData={poolData}
//     canSwapInPool={canSwapInPool}
//     loading={loading}
//   />
// )}

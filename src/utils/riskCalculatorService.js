/**
 * Automated Risk Calculator Service
 * Inspired by Coinbase Verified Pools
 * Integrates on-chain data and Chainlink oracles for comprehensive risk assessment
 */

import Web3 from 'web3'

// Risk Calculator Contract ABI (simplified)
const RISK_CALCULATOR_ABI = [
  {
    inputs: [{ internalType: 'address', name: 'user', type: 'address' }],
    name: 'calculateRiskScore',
    outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function'
  },
  {
    inputs: [{ internalType: 'address', name: 'user', type: 'address' }],
    name: 'getRiskLevel',
    outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function'
  },
  {
    inputs: [{ internalType: 'address', name: 'user', type: 'address' }],
    name: 'meetsMinimumRisk',
    outputs: [{ internalType: 'bool', name: '', type: 'bool' }],
    stateMutability: 'view',
    type: 'function'
  },
  {
    inputs: [{ internalType: 'address', name: 'user', type: 'address' }],
    name: 'getRiskProfile',
    outputs: [
      {
        components: [
          { internalType: 'uint256', name: 'complianceScore', type: 'uint256' },
          {
            internalType: 'uint256',
            name: 'transactionHistoryScore',
            type: 'uint256'
          },
          { internalType: 'uint256', name: 'walletAgeScore', type: 'uint256' },
          { internalType: 'uint256', name: 'volumeScore', type: 'uint256' },
          { internalType: 'uint256', name: 'sanctionsScore', type: 'uint256' },
          { internalType: 'uint256', name: 'reputationScore', type: 'uint256' },
          {
            internalType: 'uint256',
            name: 'overallRiskScore',
            type: 'uint256'
          },
          { internalType: 'uint256', name: 'lastUpdated', type: 'uint256' },
          { internalType: 'bool', name: 'isActive', type: 'bool' }
        ],
        internalType: 'struct AutomatedRiskCalculator.RiskProfile',
        name: '',
        type: 'tuple'
      }
    ],
    stateMutability: 'view',
    type: 'function'
  }
]

class RiskCalculatorService {
  constructor (web3Provider, contractAddress) {
    this.web3 = new Web3(web3Provider)
    this.contractAddress = contractAddress
    this.contract = new this.web3.eth.Contract(
      RISK_CALCULATOR_ABI,
      contractAddress
    )
  }

  /**
   * Calculate comprehensive risk score for a user
   * @param {string} userAddress - User's wallet address
   * @returns {Promise<Object>} Risk assessment data
   */
  async calculateRisk (userAddress) {
    try {
      const riskScore = await this.contract.methods
        .calculateRiskScore(userAddress)
        .call()
      const riskLevel = await this.contract.methods
        .getRiskLevel(userAddress)
        .call()
      const meetsMinimum = await this.contract.methods
        .meetsMinimumRisk(userAddress)
        .call()
      const profile = await this.contract.methods
        .getRiskProfile(userAddress)
        .call()

      return {
        overallScore: parseInt(riskScore),
        riskLevel: this.getRiskLevelLabel(parseInt(riskLevel)),
        meetsMinimumRequirement: meetsMinimum,
        profile: {
          complianceScore: parseInt(profile.complianceScore),
          transactionHistoryScore: parseInt(profile.transactionHistoryScore),
          walletAgeScore: parseInt(profile.walletAgeScore),
          volumeScore: parseInt(profile.volumeScore),
          sanctionsScore: parseInt(profile.sanctionsScore),
          reputationScore: parseInt(profile.reputationScore),
          lastUpdated: new Date(
            parseInt(profile.lastUpdated) * 1000
          ).toISOString(),
          isActive: profile.isActive
        }
      }
    } catch (error) {
      console.error('Failed to calculate risk:', error)
      throw error
    }
  }

  /**
   * Get risk level label from numeric value
   * @param {number} level - Risk level (0-3)
   * @returns {string} Human-readable risk level
   */
  getRiskLevelLabel (level) {
    const labels = ['Not Scored', 'High Risk', 'Medium Risk', 'Low Risk']
    return labels[level] || 'Unknown'
  }

  /**
   * Get risk level color for UI
   * @param {number} level - Risk level (0-3)
   * @returns {string} Color code
   */
  getRiskLevelColor (level) {
    const colors = ['#9ca3af', '#ef4444', '#f59e0b', '#10b981']
    return colors[level] || '#9ca3af'
  }

  /**
   * Analyze on-chain behavior for a user
   * @param {string} userAddress - User's wallet address
   * @returns {Promise<Object>} On-chain analysis
   */
  async analyzeOnChainBehavior (userAddress) {
    try {
      // Get transaction history
      const txCount = await this.web3.eth.getTransactionCount(userAddress)

      // Get balance
      const balance = await this.web3.eth.getBalance(userAddress)
      const ethBalance = this.web3.utils.fromWei(balance, 'ether')

      // Estimate wallet age (simplified)
      const currentBlock = await this.web3.eth.getBlockNumber()

      return {
        transactionCount: txCount,
        balance: parseFloat(ethBalance),
        currentBlock: currentBlock,
        analysis: {
          activityLevel: this.getActivityLevel(txCount),
          balanceLevel: this.getBalanceLevel(parseFloat(ethBalance))
        }
      }
    } catch (error) {
      console.error('Failed to analyze on-chain behavior:', error)
      throw error
    }
  }

  /**
   * Get activity level classification
   * @param {number} txCount - Transaction count
   * @returns {string} Activity level
   */
  getActivityLevel (txCount) {
    if (txCount === 0) return 'No Activity'
    if (txCount < 10) return 'Low'
    if (txCount < 50) return 'Medium'
    if (txCount < 100) return 'High'
    return 'Very High'
  }

  /**
   * Get balance level classification
   * @param {number} balance - ETH balance
   * @returns {string} Balance level
   */
  getBalanceLevel (balance) {
    if (balance === 0) return 'Empty'
    if (balance < 0.01) return 'Very Low'
    if (balance < 0.1) return 'Low'
    if (balance < 1) return 'Medium'
    if (balance < 10) return 'High'
    return 'Very High'
  }

  /**
   * Generate comprehensive risk report
   * @param {string} userAddress - User's wallet address
   * @returns {Promise<Object>} Complete risk report
   */
  async generateRiskReport (userAddress) {
    try {
      const [riskData, onChainData] = await Promise.all([
        this.calculateRisk(userAddress),
        this.analyzeOnChainBehavior(userAddress)
      ])

      return {
        address: userAddress,
        timestamp: new Date().toISOString(),
        riskAssessment: riskData,
        onChainAnalysis: onChainData,
        recommendations: this.generateRecommendations(riskData, onChainData),
        accessLevel: this.determineAccessLevel(riskData)
      }
    } catch (error) {
      console.error('Failed to generate risk report:', error)
      throw error
    }
  }

  /**
   * Generate recommendations based on risk assessment
   * @param {Object} riskData - Risk assessment data
   * @param {Object} onChainData - On-chain analysis data
   * @returns {Array} List of recommendations
   */
  generateRecommendations (riskData, onChainData) {
    const recommendations = []

    if (!riskData.profile.isActive) {
      recommendations.push({
        type: 'critical',
        message: 'Complete KYC/AML verification to activate risk profile'
      })
    }

    if (riskData.profile.complianceScore < 70) {
      recommendations.push({
        type: 'warning',
        message: 'Improve compliance score by completing identity verification'
      })
    }

    if (onChainData.transactionCount < 10) {
      recommendations.push({
        type: 'info',
        message: 'Build transaction history to improve risk score'
      })
    }

    if (riskData.profile.sanctionsScore < 90) {
      recommendations.push({
        type: 'warning',
        message: 'Sanctions screening requires review'
      })
    }

    if (riskData.overallScore < 30) {
      recommendations.push({
        type: 'critical',
        message: 'Risk score too low - access to compliance pools blocked'
      })
    }

    return recommendations
  }

  /**
   * Determine access level based on risk
   * @param {Object} riskData - Risk assessment data
   * @returns {Object} Access level configuration
   */
  determineAccessLevel (riskData) {
    const score = riskData.overallScore

    if (score >= 80) {
      return {
        level: 'full',
        label: 'Full Access',
        allowedPools: ['permissionless', 'institutional', 'accredited'],
        tradingLimits: 'unlimited',
        color: '#10b981'
      }
    } else if (score >= 50) {
      return {
        level: 'limited',
        label: 'Limited Access',
        allowedPools: ['permissionless', 'institutional'],
        tradingLimits: '100 ETH per day',
        color: '#f59e0b'
      }
    } else if (score >= 30) {
      return {
        level: 'restricted',
        label: 'Restricted Access',
        allowedPools: ['permissionless'],
        tradingLimits: '10 ETH per day',
        color: '#ef4444'
      }
    } else {
      return {
        level: 'blocked',
        label: 'Access Blocked',
        allowedPools: [],
        tradingLimits: 'none',
        color: '#991b1b'
      }
    }
  }

  /**
   * Check if user can access a specific pool type
   * @param {string} userAddress - User's wallet address
   * @param {string} poolType - Pool type to check
   * @returns {Promise<boolean>} Whether user can access pool
   */
  async canAccessPool (userAddress, poolType) {
    try {
      const riskReport = await this.generateRiskReport(userAddress)
      return riskReport.accessLevel.allowedPools.includes(poolType)
    } catch (error) {
      console.error('Failed to check pool access:', error)
      return false
    }
  }
}

/**
 * Mock Risk Calculator Service for development
 */
export class MockRiskCalculatorService {
  constructor () {
    console.log('Mock Risk Calculator Service initialized')
  }

  async calculateRisk (userAddress) {
    await this.delay(1000)

    // Simulate risk calculation based on address
    const isHighRisk =
      userAddress.toLowerCase().includes('9') ||
      userAddress.toLowerCase().includes('8')

    const score = isHighRisk ? 35 : 85

    return {
      overallScore: score,
      riskLevel:
        score >= 80 ? 'Low Risk' : score >= 50 ? 'Medium Risk' : 'High Risk',
      meetsMinimumRequirement: score >= 30,
      profile: {
        complianceScore: isHighRisk ? 30 : 90,
        transactionHistoryScore: isHighRisk ? 40 : 85,
        walletAgeScore: isHighRisk ? 20 : 80,
        volumeScore: isHighRisk ? 35 : 75,
        sanctionsScore: isHighRisk ? 50 : 95,
        reputationScore: isHighRisk ? 40 : 85,
        lastUpdated: new Date().toISOString(),
        isActive: true
      }
    }
  }

  async analyzeOnChainBehavior (userAddress) {
    await this.delay(800)

    return {
      transactionCount: Math.floor(Math.random() * 200),
      balance: Math.random() * 5,
      currentBlock: 12345678,
      analysis: {
        activityLevel: 'Medium',
        balanceLevel: 'Medium'
      }
    }
  }

  async generateRiskReport (userAddress) {
    const [riskData, onChainData] = await Promise.all([
      this.calculateRisk(userAddress),
      this.analyzeOnChainBehavior(userAddress)
    ])

    return {
      address: userAddress,
      timestamp: new Date().toISOString(),
      riskAssessment: riskData,
      onChainAnalysis: onChainData,
      recommendations: this.generateRecommendations(riskData, onChainData),
      accessLevel: this.determineAccessLevel(riskData)
    }
  }

  generateRecommendations (riskData, onChainData) {
    const recommendations = []

    if (riskData.overallScore < 50) {
      recommendations.push({
        type: 'warning',
        message: 'Complete KYC verification to improve risk score'
      })
    }

    if (onChainData.transactionCount < 50) {
      recommendations.push({
        type: 'info',
        message: 'Increase transaction history to improve score'
      })
    }

    return recommendations
  }

  determineAccessLevel (riskData) {
    const score = riskData.overallScore

    if (score >= 80) {
      return {
        level: 'full',
        label: 'Full Access',
        allowedPools: ['permissionless', 'institutional', 'accredited'],
        tradingLimits: 'unlimited',
        color: '#10b981'
      }
    } else if (score >= 50) {
      return {
        level: 'limited',
        label: 'Limited Access',
        allowedPools: ['permissionless', 'institutional'],
        tradingLimits: '100 ETH per day',
        color: '#f59e0b'
      }
    } else {
      return {
        level: 'restricted',
        label: 'Restricted Access',
        allowedPools: ['permissionless'],
        tradingLimits: '10 ETH per day',
        color: '#ef4444'
      }
    }
  }

  async canAccessPool (userAddress, poolType) {
    const report = await this.generateRiskReport(userAddress)
    return report.accessLevel.allowedPools.includes(poolType)
  }

  delay (ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
  }
}

export default RiskCalculatorService

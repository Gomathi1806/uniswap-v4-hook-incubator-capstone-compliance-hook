import Web3 from 'web3'

const RISK_CALCULATOR_ADDRESS = process.env.REACT_APP_RISK_CALCULATOR_ADDRESS
const ORACLE_ADDRESS = process.env.REACT_APP_CHAINLINK_ORACLE_ADDRESS
const FHENIX_ADDRESS = process.env.REACT_APP_FHENIX_ORACLE_ADDRESS

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

const ORACLE_ABI = [
  {
    inputs: [{ internalType: 'address', name: 'user', type: 'address' }],
    name: 'getComplianceData',
    outputs: [
      {
        components: [
          { internalType: 'uint256', name: 'kycScore', type: 'uint256' },
          { internalType: 'uint256', name: 'amlScore', type: 'uint256' },
          { internalType: 'uint256', name: 'sanctionsScore', type: 'uint256' },
          { internalType: 'bool', name: 'isVerified', type: 'bool' },
          { internalType: 'bool', name: 'isSanctioned', type: 'bool' },
          { internalType: 'uint256', name: 'lastUpdated', type: 'uint256' }
        ],
        internalType: 'struct ChainlinkComplianceOracle.ComplianceData',
        name: '',
        type: 'tuple'
      }
    ],
    stateMutability: 'view',
    type: 'function'
  },
  {
    inputs: [{ internalType: 'address', name: 'user', type: 'address' }],
    name: 'isCompliant',
    outputs: [{ internalType: 'bool', name: '', type: 'bool' }],
    stateMutability: 'view',
    type: 'function'
  }
]

class Web3Service {
  constructor () {
    this.web3 = null
    this.riskCalculator = null
    this.oracle = null
    this.account = null
  }

  async init () {
    if (typeof window.ethereum !== 'undefined') {
      this.web3 = new Web3(window.ethereum)
      this.riskCalculator = new this.web3.eth.Contract(
        RISK_CALCULATOR_ABI,
        RISK_CALCULATOR_ADDRESS
      )
      this.oracle = new this.web3.eth.Contract(ORACLE_ABI, ORACLE_ADDRESS)
      console.log('Web3 initialized successfully')
      return true
    }
    console.warn('MetaMask not detected')
    return false
  }

  async connectWallet () {
    try {
      const accounts = await window.ethereum.request({
        method: 'eth_requestAccounts'
      })
      this.account = accounts[0]

      const chainId = await window.ethereum.request({ method: 'eth_chainId' })
      if (chainId !== '0xaa36a7') {
        await this.switchToSepolia()
      }

      return { account: this.account, chainId }
    } catch (error) {
      console.error('Failed to connect wallet:', error)
      throw error
    }
  }

  async switchToSepolia () {
    try {
      await window.ethereum.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: '0xaa36a7' }]
      })
    } catch (error) {
      if (error.code === 4902) {
        await window.ethereum.request({
          method: 'wallet_addEthereumChain',
          params: [
            {
              chainId: '0xaa36a7',
              chainName: 'Sepolia Test Network',
              rpcUrls: ['https://sepolia.infura.io/v3/'],
              blockExplorerUrls: ['https://sepolia.etherscan.io/']
            }
          ]
        })
      }
    }
  }

  async getRiskScore (address) {
    try {
      const score = await this.riskCalculator.methods
        .calculateRiskScore(address)
        .call()
      return parseInt(score)
    } catch (error) {
      console.error('Failed to get risk score:', error)
      return 0
    }
  }

  async getRiskProfile (address) {
    try {
      const profile = await this.riskCalculator.methods
        .getRiskProfile(address)
        .call()
      return {
        complianceScore: parseInt(profile.complianceScore),
        transactionHistoryScore: parseInt(profile.transactionHistoryScore),
        walletAgeScore: parseInt(profile.walletAgeScore),
        volumeScore: parseInt(profile.volumeScore),
        sanctionsScore: parseInt(profile.sanctionsScore),
        reputationScore: parseInt(profile.reputationScore),
        overallRiskScore: parseInt(profile.overallRiskScore),
        lastUpdated: new Date(
          parseInt(profile.lastUpdated) * 1000
        ).toISOString(),
        isActive: profile.isActive
      }
    } catch (error) {
      console.error('Failed to get risk profile:', error)
      return null
    }
  }

  async getComplianceData (address) {
    try {
      const data = await this.oracle.methods.getComplianceData(address).call()
      return {
        kycScore: parseInt(data.kycScore),
        amlScore: parseInt(data.amlScore),
        sanctionsScore: parseInt(data.sanctionsScore),
        isVerified: data.isVerified,
        isSanctioned: data.isSanctioned,
        lastUpdated: new Date(parseInt(data.lastUpdated) * 1000).toISOString()
      }
    } catch (error) {
      console.error('Failed to get compliance data:', error)
      return null
    }
  }

  async getBalance (address) {
    try {
      const balance = await this.web3.eth.getBalance(address || this.account)
      return this.web3.utils.fromWei(balance, 'ether')
    } catch (error) {
      console.error('Failed to get balance:', error)
      return '0'
    }
  }

  formatAddress (address) {
    if (!address) return ''
    return `${address.slice(0, 6)}...${address.slice(-4)}`
  }

  isConnected () {
    return this.account !== null
  }

  getCurrentAccount () {
    return this.account
  }
}

const web3Service = new Web3Service()
export default web3Service

export const HOOK_ADDRESS = '0x3422ec82B0164fAB9d106a239524a7af450dce2B';
export const RISK_CALCULATOR_ADDRESS = '0xC832d3a0a8349aE0b407AFd71F58c41f732137C9';
export const FHENIX_COMPLIANCE_ADDRESS = '0xEae8DE4CFDFdEfe892180F54A8Fa0639F3A7A08e';
export const CHAINLINK_ORACLE_ADDRESS = '0x74B92925FE7898875A19aC7cB9a662eF14DAe41A';

// Complete Hook ABI
export const HOOK_ABI = `[
  {
    "inputs": [{"internalType": "address", "name": "user", "type": "address"}],
    "name": "isCompliant",
    "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "user", "type": "address"}],
    "name": "getUserInfo",
    "outputs": [
      {"internalType": "bool", "name": "isWhitelisted", "type": "bool"},
      {"internalType": "bool", "name": "isBlacklisted", "type": "bool"},
      {"internalType": "bool", "name": "isSanctioned", "type": "bool"},
      {"internalType": "bool", "name": "isHighRisk", "type": "bool"},
      {"internalType": "uint256", "name": "riskScore", "type": "uint256"},
      {"internalType": "uint256", "name": "totalSwaps", "type": "uint256"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "user", "type": "address"},
      {"internalType": "bool", "name": "status", "type": "bool"}
    ],
    "name": "setWhitelisted",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "user", "type": "address"},
      {"internalType": "bool", "name": "status", "type": "bool"}
    ],
    "name": "setBlacklisted",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "paused",
    "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "owner",
    "outputs": [{"internalType": "address", "name": "", "type": "address"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "globalRiskThreshold",
    "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "uint256", "name": "threshold", "type": "uint256"}],
    "name": "setGlobalRiskThreshold",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "bool", "name": "_paused", "type": "bool"}],
    "name": "setPaused",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "", "type": "address"}],
    "name": "whitelisted",
    "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "", "type": "address"}],
    "name": "blacklisted",
    "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
    "stateMutability": "view",
    "type": "function"
  }
]`;

// Risk Calculator ABI (based on interface ICrossChainRiskCalculator)
export const RISK_CALCULATOR_ABI = `[
  {
    "inputs": [{"internalType": "address", "name": "user", "type": "address"}],
    "name": "shouldBlockUser",
    "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "user", "type": "address"}],
    "name": "calculateRisk",
    "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "user", "type": "address"}],
    "name": "getUserRiskScore",
    "outputs": [
      {"internalType": "uint256", "name": "score", "type": "uint256"},
      {"internalType": "uint256", "name": "timestamp", "type": "uint256"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "owner",
    "outputs": [{"internalType": "address", "name": "", "type": "address"}],
    "stateMutability": "view",
    "type": "function"
  }
]`;

// Fhenix FHE Compliance ABI (based on interface IFhenixFHECompliance)
export const FHENIX_ABI = `[
  {
    "inputs": [{"internalType": "address", "name": "user", "type": "address"}],
    "name": "checkSanctionsList",
    "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "user", "type": "address"}],
    "name": "isProfileScreened",
    "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "user", "type": "address"}],
    "name": "screenAddress",
    "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "owner",
    "outputs": [{"internalType": "address", "name": "", "type": "address"}],
    "stateMutability": "view",
    "type": "function"
  }
]`;

// Chainlink Oracle ABI (based on interface IChainlinkComplianceOracle)
export const CHAINLINK_ABI = `[
  {
    "inputs": [{"internalType": "address", "name": "user", "type": "address"}],
    "name": "isHighRisk",
    "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "user", "type": "address"}],
    "name": "getAggregatedRiskScore",
    "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "user", "type": "address"}],
    "name": "quickScreen",
    "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "owner",
    "outputs": [{"internalType": "address", "name": "", "type": "address"}],
    "stateMutability": "view",
    "type": "function"
  }
]`;

export const DEFAULT_ABI = HOOK_ABI;
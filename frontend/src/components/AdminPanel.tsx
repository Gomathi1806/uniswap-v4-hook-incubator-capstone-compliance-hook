import React, { useState } from 'react';
import { Contract } from 'web3-eth-contract';
import Web3 from 'web3';
import type { NotificationType } from '../Appjsoldone';
import { 
  RISK_CALCULATOR_ADDRESS, 
  FHENIX_COMPLIANCE_ADDRESS, 
  CHAINLINK_ORACLE_ADDRESS 
} from '../constants';

interface AdminPanelProps {
  web3: Web3 | null;
  account: string;
  showNotification: (message: string, type: NotificationType) => void;
}

const RISK_CALCULATOR_ABI = [
  {
    "inputs": [{"internalType": "address", "name": "user", "type": "address"}],
    "name": "calculateRisk",
    "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "user", "type": "address"},
      {"internalType": "uint256", "name": "score", "type": "uint256"}
    ],
    "name": "setUserRiskScore",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
];

const FHENIX_ABI = [
  {
    "inputs": [{"internalType": "address", "name": "user", "type": "address"}],
    "name": "screenAddress",
    "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "user", "type": "address"},
      {"internalType": "bool", "name": "isSanctioned", "type": "bool"}
    ],
    "name": "addToSanctionsList",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
];

const CHAINLINK_ABI = [
  {
    "inputs": [{"internalType": "address", "name": "user", "type": "address"}],
    "name": "quickScreen",
    "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "user", "type": "address"},
      {"internalType": "uint256", "name": "score", "type": "uint256"}
    ],
    "name": "updateRiskScore",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
];

const AdminPanel: React.FC<AdminPanelProps> = ({ web3, account, showNotification }) => {
  const [testAddress, setTestAddress] = useState('');
  const [testRiskScore, setTestRiskScore] = useState('75');
  const [isProcessing, setIsProcessing] = useState(false);

  const populateTestData = async () => {
    if (!web3 || !testAddress) {
      showNotification('Please enter an address', 'error');
      return;
    }

    if (!web3.utils.isAddress(testAddress)) {
      showNotification('Invalid address format', 'error');
      return;
    }

    setIsProcessing(true);

    try {
      // 1. Set risk score in RiskCalculator
      showNotification('Step 1/3: Setting risk score...', 'success');
      const riskCalc = new web3.eth.Contract(RISK_CALCULATOR_ABI as any, RISK_CALCULATOR_ADDRESS);
      
      try {
        await riskCalc.methods.setUserRiskScore(testAddress, testRiskScore).send({ from: account });
        showNotification('✅ Risk score set!', 'success');
      } catch (err: any) {
        console.log('Risk Calculator error:', err);
        showNotification('Risk Calculator: ' + (err.message || 'Transaction failed'), 'error');
      }

      // 2. Screen on Fhenix (mark as not sanctioned)
      showNotification('Step 2/3: Screening on Fhenix...', 'success');
      const fhenix = new web3.eth.Contract(FHENIX_ABI as any, FHENIX_COMPLIANCE_ADDRESS);
      
      try {
        await fhenix.methods.screenAddress(testAddress).send({ from: account });
        showNotification('✅ Fhenix screening complete!', 'success');
      } catch (err: any) {
        console.log('Fhenix error:', err);
        showNotification('Fhenix: ' + (err.message || 'Transaction failed'), 'error');
      }

      // 3. Update Chainlink score
      showNotification('Step 3/3: Updating Chainlink score...', 'success');
      const chainlink = new web3.eth.Contract(CHAINLINK_ABI as any, CHAINLINK_ORACLE_ADDRESS);
      
      try {
        await chainlink.methods.updateRiskScore(testAddress, testRiskScore).send({ from: account });
        showNotification('✅ Chainlink score updated!', 'success');
      } catch (err: any) {
        console.log('Chainlink error:', err);
        showNotification('Chainlink: ' + (err.message || 'Transaction failed'), 'error');
      }

      showNotification('🎉 Test data populated successfully!', 'success');
    } catch (error: any) {
      console.error('Error:', error);
      showNotification('Error: ' + error.message, 'error');
    } finally {
      setIsProcessing(false);
    }
  };

  const populateCurrentUser = () => {
    setTestAddress(account);
  };

  return (
    <div className="bg-gradient-to-r from-purple-500/10 to-pink-500/10 border border-purple-500/30 rounded-xl p-6 mb-6">
      <h3 className="text-xl font-bold text-purple-400 mb-4">
        🔧 Admin: Populate Test Data
      </h3>
      <p className="text-slate-400 text-sm mb-4">
        Initialize compliance data for testing. This will set risk scores across all 3 backend contracts.
      </p>
      
      <div className="space-y-3">
        <div>
          <label className="block text-sm font-medium text-slate-300 mb-1">
            Test Address
          </label>
          <div className="flex gap-2">
            <input
              type="text"
              value={testAddress}
              onChange={(e) => setTestAddress(e.target.value)}
              placeholder="0x..."
              className="flex-1 bg-slate-900 border border-slate-600 rounded-md px-3 py-2 text-slate-200 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-purple-500"
            />
            <button
              onClick={populateCurrentUser}
              className="bg-slate-700 hover:bg-slate-600 text-white px-4 py-2 rounded-md transition-colors"
            >
              Use My Address
            </button>
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-slate-300 mb-1">
            Test Risk Score (0-100)
          </label>
          <input
            type="number"
            value={testRiskScore}
            onChange={(e) => setTestRiskScore(e.target.value)}
            min="0"
            max="100"
            className="w-full bg-slate-900 border border-slate-600 rounded-md px-3 py-2 text-slate-200 focus:outline-none focus:ring-2 focus:ring-purple-500"
          />
          <p className="text-xs text-slate-500 mt-1">
            Higher score = safer. Scores below 50 will be blocked from swaps.
          </p>
        </div>

        <button
          onClick={populateTestData}
          disabled={isProcessing || !testAddress}
          className="w-full bg-purple-600 hover:bg-purple-700 text-white font-bold py-3 px-4 rounded-lg transition-colors duration-300 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isProcessing ? '⏳ Processing...' : '🚀 Populate Test Data'}
        </button>

        <div className="bg-slate-900/50 p-3 rounded text-xs text-slate-400">
          <p className="font-bold mb-2">What this does:</p>
          <ul className="list-disc list-inside space-y-1">
            <li>Sets risk score in CrossChainRiskCalculator</li>
            <li>Screens address on Fhenix (FHE compliance)</li>
            <li>Updates score on Chainlink Oracle</li>
          </ul>
        </div>
      </div>
    </div>
  );
};

export default AdminPanel;
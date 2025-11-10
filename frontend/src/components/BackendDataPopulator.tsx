import React, { useState, useEffect } from 'react';
import Web3 from 'web3';
import type { NotificationType } from '../Appjsoldone';
import { 
  RISK_CALCULATOR_ADDRESS, 
  RISK_CALCULATOR_ABI,
  FHENIX_COMPLIANCE_ADDRESS,
  FHENIX_ABI,
  CHAINLINK_ORACLE_ADDRESS,
  CHAINLINK_ABI
} from '../constants';

interface BackendDataPopulatorProps {
  web3: Web3 | null;
  account: string;
  showNotification: (message: string, type: NotificationType) => void;
}

const BackendDataPopulator: React.FC<BackendDataPopulatorProps> = ({ web3, account, showNotification }) => {
  const [owners, setOwners] = useState<any>({});
  const [isCheckingOwners, setIsCheckingOwners] = useState(false);
  const [targetAddress, setTargetAddress] = useState('');
  const [riskScore, setRiskScore] = useState('75');
  const [isPopulating, setIsPopulating] = useState(false);

  useEffect(() => {
    checkOwners();
  }, [web3]);

  const checkOwners = async () => {
    if (!web3) return;
    
    setIsCheckingOwners(true);
    const ownerData: any = {};

    try {
      const riskCalc = new web3.eth.Contract(JSON.parse(RISK_CALCULATOR_ABI), RISK_CALCULATOR_ADDRESS);
      const fhenix = new web3.eth.Contract(JSON.parse(FHENIX_ABI), FHENIX_COMPLIANCE_ADDRESS);
      const chainlink = new web3.eth.Contract(JSON.parse(CHAINLINK_ABI), CHAINLINK_ORACLE_ADDRESS);

      try {
        ownerData.riskCalculator = await riskCalc.methods.owner().call();
      } catch (err) {
        ownerData.riskCalculator = 'Unable to fetch';
      }

      try {
        ownerData.fhenix = await fhenix.methods.owner().call();
      } catch (err) {
        ownerData.fhenix = 'Unable to fetch';
      }

      try {
        ownerData.chainlink = await chainlink.methods.owner().call();
      } catch (err) {
        ownerData.chainlink = 'Unable to fetch';
      }

      setOwners(ownerData);
    } catch (error) {
      console.error('Error checking owners:', error);
    } finally {
      setIsCheckingOwners(false);
    }
  };

  const isOwnerOfAll = owners.riskCalculator?.toLowerCase() === account.toLowerCase() &&
                       owners.fhenix?.toLowerCase() === account.toLowerCase() &&
                       owners.chainlink?.toLowerCase() === account.toLowerCase();

  const populateData = async () => {
    if (!web3 || !targetAddress) {
      showNotification('Please enter a target address', 'error');
      return;
    }

    if (!web3.utils.isAddress(targetAddress)) {
      showNotification('Invalid address format', 'error');
      return;
    }

    if (!isOwnerOfAll) {
      showNotification('You must be the owner of all backend contracts', 'error');
      return;
    }

    setIsPopulating(true);
    let successCount = 0;

    try {
      // Populate Risk Calculator
      showNotification('Step 1/3: Populating Risk Calculator...', 'success');
      const riskCalc = new web3.eth.Contract(JSON.parse(RISK_CALCULATOR_ABI), RISK_CALCULATOR_ADDRESS);
      
      try {
        // Try to call calculateRisk which should set the score
        await riskCalc.methods.calculateRisk(targetAddress).send({ 
          from: account,
          gas: 300000 
        });
        successCount++;
        showNotification('✅ Risk Calculator updated!', 'success');
      } catch (err: any) {
        console.error('Risk Calculator error:', err);
        showNotification(`Risk Calculator failed: ${err.message}`, 'error');
      }

      // Populate Fhenix
      showNotification('Step 2/3: Screening on Fhenix...', 'success');
      const fhenix = new web3.eth.Contract(JSON.parse(FHENIX_ABI), FHENIX_COMPLIANCE_ADDRESS);
      
      try {
        await fhenix.methods.screenAddress(targetAddress).send({ 
          from: account,
          gas: 300000 
        });
        successCount++;
        showNotification('✅ Fhenix screening complete!', 'success');
      } catch (err: any) {
        console.error('Fhenix error:', err);
        showNotification(`Fhenix failed: ${err.message}`, 'error');
      }

      // Populate Chainlink
      showNotification('Step 3/3: Screening on Chainlink...', 'success');
      const chainlink = new web3.eth.Contract(JSON.parse(CHAINLINK_ABI), CHAINLINK_ORACLE_ADDRESS);
      
      try {
        await chainlink.methods.quickScreen(targetAddress).send({ 
          from: account,
          gas: 300000 
        });
        successCount++;
        showNotification('✅ Chainlink screening complete!', 'success');
      } catch (err: any) {
        console.error('Chainlink error:', err);
        showNotification(`Chainlink failed: ${err.message}`, 'error');
      }

      if (successCount === 3) {
        showNotification('🎉 All backend contracts populated successfully!', 'success');
      } else if (successCount > 0) {
        showNotification(`⚠️ Partially successful: ${successCount}/3 contracts updated`, 'success');
      } else {
        showNotification('❌ Failed to populate any contracts', 'error');
      }

    } catch (error: any) {
      console.error('Population error:', error);
      showNotification(`Error: ${error.message}`, 'error');
    } finally {
      setIsPopulating(false);
    }
  };

  return (
    <div className="bg-gradient-to-r from-yellow-500/10 to-orange-500/10 border border-yellow-500/30 rounded-xl p-6 mb-6">
      <h3 className="text-xl font-bold text-yellow-400 mb-4">
        ⚙️ Backend Contracts Data Populator
      </h3>
      
      {isCheckingOwners ? (
        <p className="text-slate-400 text-sm">Checking contract owners...</p>
      ) : (
        <>
          <div className="bg-slate-900/50 p-4 rounded-lg mb-4 text-sm">
            <h4 className="font-bold text-slate-300 mb-3">Contract Owners:</h4>
            <div className="space-y-2 font-mono text-xs">
              <div className="flex justify-between items-center">
                <span className="text-slate-400">Risk Calculator:</span>
                <span className={`${owners.riskCalculator?.toLowerCase() === account.toLowerCase() ? 'text-green-400' : 'text-slate-300'}`}>
                  {owners.riskCalculator ? `${owners.riskCalculator.slice(0,6)}...${owners.riskCalculator.slice(-4)}` : 'Unknown'}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-slate-400">Fhenix FHE:</span>
                <span className={`${owners.fhenix?.toLowerCase() === account.toLowerCase() ? 'text-green-400' : 'text-slate-300'}`}>
                  {owners.fhenix ? `${owners.fhenix.slice(0,6)}...${owners.fhenix.slice(-4)}` : 'Unknown'}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-slate-400">Chainlink Oracle:</span>
                <span className={`${owners.chainlink?.toLowerCase() === account.toLowerCase() ? 'text-green-400' : 'text-slate-300'}`}>
                  {owners.chainlink ? `${owners.chainlink.slice(0,6)}...${owners.chainlink.slice(-4)}` : 'Unknown'}
                </span>
              </div>
              <div className="flex justify-between items-center pt-2 border-t border-slate-700">
                <span className="text-slate-400">Your Address:</span>
                <span className="text-cyan-400">{account.slice(0,6)}...{account.slice(-4)}</span>
              </div>
            </div>
          </div>

          {isOwnerOfAll ? (
            <div className="space-y-3">
              <div className="bg-green-500/10 border border-green-500/30 rounded p-3 text-sm text-green-400">
                ✅ You are the owner of all backend contracts! You can populate data.
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-300 mb-2">
                  Target Address to Populate
                </label>
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={targetAddress}
                    onChange={(e) => setTargetAddress(e.target.value)}
                    placeholder="0x..."
                    className="flex-1 bg-slate-900 border border-slate-600 rounded-md px-3 py-2 text-slate-200 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-yellow-500 font-mono text-sm"
                  />
                  <button
                    onClick={() => setTargetAddress(account)}
                    className="bg-slate-700 hover:bg-slate-600 text-white px-4 py-2 rounded-md transition-colors"
                  >
                    Use My Address
                  </button>
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-300 mb-2">
                  Risk Score (0-100)
                </label>
                <input
                  type="number"
                  value={riskScore}
                  onChange={(e) => setRiskScore(e.target.value)}
                  min="0"
                  max="100"
                  className="w-full bg-slate-900 border border-slate-600 rounded-md px-3 py-2 text-slate-200 focus:outline-none focus:ring-2 focus:ring-yellow-500"
                />
                <p className="text-xs text-slate-500 mt-1">
                  Higher = safer. Scores ≥ 50 will pass compliance checks.
                </p>
              </div>

              <button
                onClick={populateData}
                disabled={isPopulating || !targetAddress}
                className="w-full bg-yellow-600 hover:bg-yellow-700 text-white font-bold py-3 px-4 rounded-lg transition-colors duration-300 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isPopulating ? '⏳ Populating Backend Contracts...' : '🚀 Populate Backend Data'}
              </button>

              <div className="bg-slate-900/50 p-3 rounded text-xs text-slate-400">
                <p className="font-bold mb-2">This will:</p>
                <ul className="list-disc list-inside space-y-1">
                  <li>Call <code>calculateRisk()</code> on Risk Calculator</li>
                  <li>Call <code>screenAddress()</code> on Fhenix FHE</li>
                  <li>Call <code>quickScreen()</code> on Chainlink Oracle</li>
                  <li>These functions should populate compliance data for the address</li>
                </ul>
              </div>
            </div>
          ) : (
            <div className="bg-red-500/10 border border-red-500/30 rounded p-4 text-sm text-red-400">
              <p className="font-bold mb-2">❌ You are NOT the owner of the backend contracts</p>
              <p className="mb-3">To populate data, you need to connect with the wallet that deployed these contracts:</p>
              <ul className="list-disc list-inside space-y-1 text-xs">
                <li>Risk Calculator owner: {owners.riskCalculator || 'Unknown'}</li>
                <li>Fhenix owner: {owners.fhenix || 'Unknown'}</li>
                <li>Chainlink owner: {owners.chainlink || 'Unknown'}</li>
              </ul>
              <p className="mt-3 text-xs">
                💡 <strong>Solution:</strong> Import the private key that deployed these contracts into MetaMask and connect with that wallet.
              </p>
            </div>
          )}
        </>
      )}
    </div>
  );
};

export default BackendDataPopulator;
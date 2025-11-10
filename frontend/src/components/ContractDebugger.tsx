import React, { useState } from 'react';
import Web3 from 'web3';
import type { NotificationType } from '../Appjsoldone';
import { 
  HOOK_ADDRESS,
  RISK_CALCULATOR_ADDRESS, 
  RISK_CALCULATOR_ABI,
  FHENIX_COMPLIANCE_ADDRESS,
  FHENIX_ABI,
  CHAINLINK_ORACLE_ADDRESS,
  CHAINLINK_ABI
} from '../constants';

interface ContractDebuggerProps {
  web3: Web3 | null;
  account: string;
  showNotification: (message: string, type: NotificationType) => void;
}

const ContractDebugger: React.FC<ContractDebuggerProps> = ({ web3, account, showNotification }) => {
  const [testAddress, setTestAddress] = useState('');
  const [debugResults, setDebugResults] = useState<any>(null);
  const [isDebugging, setIsDebugging] = useState(false);

  const debugAllContracts = async () => {
    if (!web3 || !testAddress) {
      showNotification('Please enter an address', 'error');
      return;
    }

    if (!web3.utils.isAddress(testAddress)) {
      showNotification('Invalid address', 'error');
      return;
    }

    setIsDebugging(true);
    const results: any = {
      address: testAddress,
      riskCalculator: {},
      fhenix: {},
      chainlink: {}
    };

    try {
      // Test Risk Calculator
      console.log('Testing Risk Calculator...');
      const riskCalc = new web3.eth.Contract(JSON.parse(RISK_CALCULATOR_ABI), RISK_CALCULATOR_ADDRESS);
      
      try {
        const riskScore = await riskCalc.methods.getUserRiskScore(testAddress).call();
        results.riskCalculator.score = String(riskScore[0] || riskScore.score || '0');
        results.riskCalculator.timestamp = String(riskScore[1] || riskScore.timestamp || '0');
        console.log('Risk Score:', results.riskCalculator);
      } catch (err: any) {
        results.riskCalculator.error = err.message;
        console.error('Risk Calculator error:', err);
      }

      try {
        const shouldBlock = await riskCalc.methods.shouldBlockUser(testAddress).call();
        results.riskCalculator.shouldBlock = shouldBlock;
      } catch (err: any) {
        results.riskCalculator.shouldBlockError = err.message;
      }

      // Test Fhenix
      console.log('Testing Fhenix...');
      const fhenix = new web3.eth.Contract(JSON.parse(FHENIX_ABI), FHENIX_COMPLIANCE_ADDRESS);
      
      try {
        const isSanctioned = await fhenix.methods.checkSanctionsList(testAddress).call();
        results.fhenix.isSanctioned = isSanctioned;
        console.log('Sanctioned:', isSanctioned);
      } catch (err: any) {
        results.fhenix.error = err.message;
        console.error('Fhenix error:', err);
      }

      try {
        const isScreened = await fhenix.methods.isProfileScreened(testAddress).call();
        results.fhenix.isScreened = isScreened;
      } catch (err: any) {
        results.fhenix.screenedError = err.message;
      }

      // Test Chainlink
      console.log('Testing Chainlink...');
      const chainlink = new web3.eth.Contract(JSON.parse(CHAINLINK_ABI), CHAINLINK_ORACLE_ADDRESS);
      
      try {
        const isHighRisk = await chainlink.methods.isHighRisk(testAddress).call();
        results.chainlink.isHighRisk = isHighRisk;
        console.log('High Risk:', isHighRisk);
      } catch (err: any) {
        results.chainlink.error = err.message;
        console.error('Chainlink error:', err);
      }

      try {
        const aggScore = await chainlink.methods.getAggregatedRiskScore(testAddress).call();
        results.chainlink.aggregatedScore = String(aggScore);
      } catch (err: any) {
        results.chainlink.scoreError = err.message;
      }

      setDebugResults(results);
      showNotification('Debug complete! Check results below.', 'success');
      console.log('Full debug results:', results);
      
    } catch (error: any) {
      showNotification(`Error: ${error.message}`, 'error');
      console.error('Debug error:', error);
    } finally {
      setIsDebugging(false);
    }
  };

  return (
    <div className="bg-gradient-to-r from-orange-500/10 to-red-500/10 border border-orange-500/30 rounded-xl p-6 mb-6">
      <h3 className="text-xl font-bold text-orange-400 mb-4">
        🔍 Backend Contracts Debugger
      </h3>
      <p className="text-slate-400 text-sm mb-4">
        Test direct calls to all 3 backend contracts to see what data they return
      </p>
      
      <div className="space-y-3">
        <div className="flex gap-2">
          <input
            type="text"
            value={testAddress}
            onChange={(e) => setTestAddress(e.target.value)}
            placeholder="Address to test (0x...)"
            className="flex-1 bg-slate-900 border border-slate-600 rounded-md px-3 py-2 text-slate-200 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-orange-500 font-mono text-sm"
          />
          <button
            onClick={() => setTestAddress(account)}
            className="bg-slate-700 hover:bg-slate-600 text-white px-4 py-2 rounded-md transition-colors"
          >
            My Address
          </button>
        </div>

        <button
          onClick={debugAllContracts}
          disabled={isDebugging || !testAddress}
          className="w-full bg-orange-600 hover:bg-orange-700 text-white font-bold py-3 px-4 rounded-lg transition-colors duration-300 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isDebugging ? '🔄 Debugging...' : '🔍 Debug All Contracts'}
        </button>

        {debugResults && (
          <div className="mt-4 space-y-3">
            <div className="bg-slate-900/70 p-4 rounded-lg">
              <p className="text-xs text-slate-400 mb-2">Testing Address:</p>
              <p className="font-mono text-xs text-cyan-400 break-all">{debugResults.address}</p>
            </div>

            {/* Risk Calculator Results */}
            <div className="bg-slate-900/50 p-4 rounded-lg border border-blue-500/30">
              <h4 className="font-bold text-blue-400 mb-3 flex items-center gap-2">
                💼 Risk Calculator
                <span className="text-xs font-mono text-slate-500">{RISK_CALCULATOR_ADDRESS.slice(0,10)}...</span>
              </h4>
              <div className="space-y-2 text-sm">
                {debugResults.riskCalculator.error ? (
                  <p className="text-red-400">❌ Error: {debugResults.riskCalculator.error}</p>
                ) : (
                  <>
                    <div className="flex justify-between">
                      <span className="text-slate-400">Risk Score:</span>
                      <span className="font-bold text-blue-400">{debugResults.riskCalculator.score || '0'}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-400">Should Block:</span>
                      <span className="font-bold">{debugResults.riskCalculator.shouldBlock ? '⛔ Yes' : '✅ No'}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-400">Timestamp:</span>
                      <span className="font-mono text-xs">{debugResults.riskCalculator.timestamp || '0'}</span>
                    </div>
                  </>
                )}
              </div>
            </div>

            {/* Fhenix Results */}
            <div className="bg-slate-900/50 p-4 rounded-lg border border-purple-500/30">
              <h4 className="font-bold text-purple-400 mb-3 flex items-center gap-2">
                🔐 Fhenix FHE
                <span className="text-xs font-mono text-slate-500">{FHENIX_COMPLIANCE_ADDRESS.slice(0,10)}...</span>
              </h4>
              <div className="space-y-2 text-sm">
                {debugResults.fhenix.error ? (
                  <p className="text-red-400">❌ Error: {debugResults.fhenix.error}</p>
                ) : (
                  <>
                    <div className="flex justify-between">
                      <span className="text-slate-400">Sanctioned:</span>
                      <span className="font-bold">{debugResults.fhenix.isSanctioned ? '⛔ Yes' : '✅ No'}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-400">Profile Screened:</span>
                      <span className="font-bold">{debugResults.fhenix.isScreened ? '✅ Yes' : '❌ No'}</span>
                    </div>
                  </>
                )}
              </div>
            </div>

            {/* Chainlink Results */}
            <div className="bg-slate-900/50 p-4 rounded-lg border border-green-500/30">
              <h4 className="font-bold text-green-400 mb-3 flex items-center gap-2">
                🔗 Chainlink Oracle
                <span className="text-xs font-mono text-slate-500">{CHAINLINK_ORACLE_ADDRESS.slice(0,10)}...</span>
              </h4>
              <div className="space-y-2 text-sm">
                {debugResults.chainlink.error ? (
                  <p className="text-red-400">❌ Error: {debugResults.chainlink.error}</p>
                ) : (
                  <>
                    <div className="flex justify-between">
                      <span className="text-slate-400">High Risk:</span>
                      <span className="font-bold">{debugResults.chainlink.isHighRisk ? '⚠️ Yes' : '✅ No'}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-400">Aggregated Score:</span>
                      <span className="font-bold text-green-400">{debugResults.chainlink.aggregatedScore || '0'}</span>
                    </div>
                  </>
                )}
              </div>
            </div>

            <div className="bg-cyan-500/10 border border-cyan-500/30 rounded p-3 text-xs text-slate-300">
              <p className="font-bold mb-1">💡 Interpretation:</p>
              <ul className="list-disc list-inside space-y-1">
                <li>If all values are 0/false: Contracts have no data for this address yet</li>
                <li>If you see errors: Check contract ABIs or permissions</li>
                <li>The Hook combines data from all 3 contracts</li>
              </ul>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default ContractDebugger;
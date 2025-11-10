import React, { useState } from 'react';
import { Contract } from 'web3-eth-contract';
import type { NotificationType } from '../../App';

interface ComplianceManagerProps {
  // Fix: The Contract type from web3-eth-contract is generic. Using `any` for flexibility.
  contract: Contract<any>;
  account: string;
  showNotification: (message: string, type: NotificationType) => void;
}

const ComplianceManager: React.FC<ComplianceManagerProps> = ({ contract, account, showNotification }) => {
  const [verifyAddress, setVerifyAddress] = useState('');
  const [riskScore, setRiskScore] = useState('');
  const [isVerifying, setIsVerifying] = useState(false);

  const [checkAddress, setCheckAddress] = useState('');
  const [isChecking, setIsChecking] = useState(false);
  const [checkResult, setCheckResult] = useState<string | null>(null);

  const [scoreAddress, setScoreAddress] = useState('');
  const [isGettingScore, setIsGettingScore] = useState(false);
  const [scoreResult, setScoreResult] = useState<string | null>(null);

  const handleVerify = async () => {
    setIsVerifying(true);
    try {
      await contract.methods.verifyUser(verifyAddress, riskScore).send({ from: account });
      showNotification(`Successfully verified ${verifyAddress} with risk score ${riskScore}.`, 'success');
      setVerifyAddress('');
      setRiskScore('');
    } catch (error: any) {
      showNotification(`Error verifying user: ${error.message}`, 'error');
    } finally {
      setIsVerifying(false);
    }
  };

  const handleCheck = async () => {
    setIsChecking(true);
    setCheckResult(null);
    try {
      const result = await contract.methods.isCompliant(checkAddress).call();
      setCheckResult(`Address ${checkAddress} is ${result ? 'compliant' : 'NOT compliant'}.`);
    } catch (error: any) {
      showNotification(`Error checking status: ${error.message}`, 'error');
    } finally {
      setIsChecking(false);
    }
  };

  const handleGetScore = async () => {
    setIsGettingScore(true);
    setScoreResult(null);
    try {
      const result = await contract.methods.getUserRiskScore(scoreAddress).call();
      // Fix: Use String() to safely convert the result to a string, as the inferred type might not have a .toString() method.
      setScoreResult(`Risk score for ${scoreAddress} is: ${String(result)}`);
    } catch (error: any) {
      showNotification(`Error getting risk score: ${error.message}`, 'error');
    } finally {
      setIsGettingScore(false);
    }
  };

  const ActionCard: React.FC<{ title: string; children: React.ReactNode }> = ({ title, children }) => (
    <div className="bg-slate-800/50 p-6 rounded-xl border border-slate-700">
      <h3 className="text-lg font-bold text-cyan-400 mb-4">{title}</h3>
      {children}
    </div>
  );

  const AddressInput: React.FC<{ value: string; onChange: (e: React.ChangeEvent<HTMLInputElement>) => void; placeholder?: string; }> = 
  ({ value, onChange, placeholder = "0x..." }) => (
     <input
        type="text"
        value={value}
        onChange={onChange}
        placeholder={placeholder}
        className="w-full bg-slate-900 border border-slate-600 rounded-md px-3 py-2 text-slate-200 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-cyan-500 focus:border-cyan-500"
      />
  );
  
  return (
    <div className="space-y-6">
        <h2 className="text-2xl font-bold text-center">Compliance Management</h2>
        
        <ActionCard title="Verify User & Set Risk Score">
            <div className="space-y-3">
                <AddressInput value={verifyAddress} onChange={(e) => setVerifyAddress(e.target.value)} placeholder="User address"/>
                <AddressInput value={riskScore} onChange={(e) => setRiskScore(e.target.value)} placeholder="Risk score (e.g., 10)"/>
                <button onClick={handleVerify} disabled={isVerifying || !verifyAddress || !riskScore} className="w-full bg-green-600 hover:bg-green-700 text-white font-bold py-2 px-4 rounded-lg transition-colors duration-300 disabled:opacity-50">
                    {isVerifying ? 'Verifying...' : 'Verify User'}
                </button>
            </div>
        </ActionCard>

        <ActionCard title="Check Compliance Status">
            <div className="space-y-3">
                <AddressInput value={checkAddress} onChange={(e) => setCheckAddress(e.target.value)} />
                <button onClick={handleCheck} disabled={isChecking || !checkAddress} className="w-full bg-slate-600 hover:bg-slate-500 text-white font-bold py-2 px-4 rounded-lg transition-colors duration-300 disabled:opacity-50">
                    {isChecking ? 'Checking...' : 'Check Status'}
                </button>
                {checkResult && <p className="text-sm text-center pt-2">{checkResult}</p>}
            </div>
        </ActionCard>

        <ActionCard title="Get User Risk Score">
            <div className="space-y-3">
                <AddressInput value={scoreAddress} onChange={(e) => setScoreAddress(e.target.value)} />
                <button onClick={handleGetScore} disabled={isGettingScore || !scoreAddress} className="w-full bg-slate-600 hover:bg-slate-500 text-white font-bold py-2 px-4 rounded-lg transition-colors duration-300 disabled:opacity-50">
                    {isGettingScore ? 'Fetching...' : 'Get Score'}
                </button>
                {scoreResult && <p className="text-sm text-center pt-2">{scoreResult}</p>}
            </div>
        </ActionCard>
    </div>
  );
};

export default ComplianceManager;
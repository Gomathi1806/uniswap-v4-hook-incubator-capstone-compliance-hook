import React, { useState } from 'react';
import Web3 from 'web3';
import { Contract } from 'web3-eth-contract';
import ComplianceManager from './KycManager';
//import { DEFAULT_ABI } from '../../constants';
import { AbiItem } from '../../types';
import type { NotificationType } from '../../App';
import { HOOK_ABI, HOOK_ADDRESS } from '../constants';
import AdminPanel from './AdminPanel';
import ContractDebugger from './ContractDebugger';
import BackendDataPopulator from './BackendDataPopulator';
interface ContractInteractorProps {
  web3: Web3 | null;
  account: string;
  // Fix: The Contract type from web3-eth-contract is generic. Using `any` for flexibility.
  loadContract: (address: string, abi: AbiItem[]) => Contract<any> | null;
  // Fix: The Contract type from web3-eth-contract is generic. Using `any` for flexibility.
  loadedContract: Contract<any> | null;
  showNotification: (message: string, type: NotificationType) => void;
}

const ContractInteractor: React.FC<ContractInteractorProps> = ({ web3, account, loadContract, loadedContract, showNotification }) => {
  const [contractAddress, setContractAddress] = useState('0x9a65bD1Ae5bb75697f6DAbeb132C776428339DFb');
  
  //const [abi, setAbi] = useState(DEFAULT_ABI);
  const [isLoading, setIsLoading] = useState(false);
  const [abi, setAbi] = useState(HOOK_ABI);
  const handleLoadContract = () => {
    setIsLoading(true);
    if (!web3) {
      showNotification('Web3 not initialized.', 'error');
      setIsLoading(false);
      return;
    }
    if (!web3.utils.isAddress(contractAddress)) {
      showNotification('Invalid contract address.', 'error');
      setIsLoading(false);
      return;
    }
    try {
      const parsedAbi: AbiItem[] = JSON.parse(abi);
      loadContract(contractAddress, parsedAbi);
    } catch (error) {
      showNotification('Failed to parse ABI. Please check the JSON format.', 'error');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="space-y-8">
      {!loadedContract ? (
        <div className="bg-slate-800/50 p-6 md:p-8 rounded-xl border border-slate-700">
          <h2 className="text-xl font-bold text-cyan-400 mb-2">Load Compliance Hook Contract</h2>
          <p className="text-slate-400 mb-6">Enter the deployed contract address and its ABI to begin.</p>
          <div className="space-y-4">
            <div>
              <label htmlFor="contractAddress" className="block text-sm font-medium text-slate-300 mb-1">
                Contract Address
              </label>
              <input
                id="contractAddress"
                type="text"
                value={contractAddress}
                onChange={(e) => setContractAddress(e.target.value)}
                placeholder="0x..."
                className="w-full bg-slate-900 border border-slate-600 rounded-md px-3 py-2 text-slate-200 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-cyan-500 focus:border-cyan-500"
              />
            </div>
            <div>
              <label htmlFor="abi" className="block text-sm font-medium text-slate-300 mb-1">
                Contract ABI
              </label>
              <textarea
                id="abi"
                rows={8}
                value={abi}
                onChange={(e) => setAbi(e.target.value)}
                className="w-full bg-slate-900 border border-slate-600 rounded-md px-3 py-2 text-slate-200 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-cyan-500 focus:border-cyan-500 font-mono text-xs"
              />
            </div>
            <button
              onClick={handleLoadContract}
              disabled={isLoading || !contractAddress}
              className="w-full bg-cyan-500 hover:bg-cyan-600 text-white font-bold py-3 px-6 rounded-lg transition-colors duration-300 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isLoading ? 'Loading...' : 'Load Contract'}
            </button>
          </div>
        </div>
      ) : (
          <>
          <AdminPanel 
            web3={web3} 
            account={account} 
            showNotification={showNotification} 
            />
            <BackendDataPopulator 
             web3={web3} 
             account={account} 
             showNotification={showNotification} 
             />
            <ContractDebugger 
             web3={web3} 
             account={account} 
             showNotification={showNotification} 
            />
        <ComplianceManager 
          contract={loadedContract} 
          account={account} 
          showNotification={showNotification} 
        />
      )}
    </div>
  );
};

export default ContractInteractor;
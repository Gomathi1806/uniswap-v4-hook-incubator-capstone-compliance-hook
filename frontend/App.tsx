import React, { useState, useCallback, useEffect } from 'react';
import Web3 from 'web3';
import { Contract } from 'web3-eth-contract';
import Header from './src/components/Header';
import ContractInteractor from './src/components/ContractInteractor';
import Notification from './src/components/Notification';
import { AbiItem } from './types';
import './App.css';

declare global {
  interface Window {
    ethereum?: any;
  }
}

export type NotificationType = 'success' | 'error';

export interface NotificationState {
  message: string;
  type: NotificationType;
}

const ARBITRUM_SEPOLIA_CHAIN_ID = '0x66eee'; // 421614 in hex
const ARBITRUM_SEPOLIA_RPC = 'https://sepolia-rollup.arbitrum.io/rpc';

const App: React.FC = () => {
  const [web3, setWeb3] = useState<Web3 | null>(null);
  const [account, setAccount] = useState<string | null>(null);
  const [contract, setContract] = useState<Contract<any> | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [notification, setNotification] = useState<NotificationState | null>(null);

  const showNotification = (message: string, type: NotificationType) => {
    setNotification({ message, type });
  };

  const switchToArbitrumSepolia = async () => {
    if (!window.ethereum) return false;
    
    try {
      await window.ethereum.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: ARBITRUM_SEPOLIA_CHAIN_ID }],
      });
      return true;
    } catch (switchError: any) {
      if (switchError.code === 4902) {
        try {
          await window.ethereum.request({
            method: 'wallet_addEthereumChain',
            params: [{
              chainId: ARBITRUM_SEPOLIA_CHAIN_ID,
              chainName: 'Arbitrum Sepolia',
              nativeCurrency: {
                name: 'ETH',
                symbol: 'ETH',
                decimals: 18
              },
              rpcUrls: [ARBITRUM_SEPOLIA_RPC],
              blockExplorerUrls: ['https://sepolia.arbiscan.io/']
            }]
          });
          return true;
        } catch (addError) {
          console.error('Failed to add network:', addError);
          return false;
        }
      }
      return false;
    }
  };

  const connectWallet = useCallback(async () => {
    setError(null);
    if (window.ethereum) {
      try {
        await window.ethereum.request({ method: 'eth_requestAccounts' });
        
        // Switch to Arbitrum Sepolia
        const switched = await switchToArbitrumSepolia();
        if (!switched) {
          showNotification('Please switch to Arbitrum Sepolia network', 'error');
          return;
        }

        const web3Instance = new Web3(window.ethereum);
        setWeb3(web3Instance);
        const accounts = await web3Instance.eth.getAccounts();
        setAccount(accounts[0]);
        
        showNotification('Connected to Arbitrum Sepolia!', 'success');
      } catch (err: any) {
        setError('Failed to connect wallet. ' + err.message);
        showNotification('Failed to connect wallet.', 'error');
      }
    } else {
      setError('Please install MetaMask!');
      showNotification('Please install MetaMask!', 'error');
    }
  }, []);

  useEffect(() => {
    if (window.ethereum) {
      window.ethereum.on('accountsChanged', (accounts: string[]) => {
        if (accounts.length > 0) {
          setAccount(accounts[0]);
        } else {
          setAccount(null);
          setWeb3(null);
          setContract(null);
        }
      });

      window.ethereum.on('chainChanged', () => {
        window.location.reload();
      });
    }
  }, []);

  const loadContract = useCallback((address: string, abi: AbiItem[]) => {
    if (web3) {
      try {
        const contractInstance = new web3.eth.Contract(abi as any, address);
        setContract(contractInstance);
        showNotification('Contract loaded successfully!', 'success');
        return contractInstance;
      } catch(err: any) {
        setError('Failed to load contract: ' + err.message);
        showNotification('Failed to load contract. Check ABI and address.', 'error');
        setContract(null);
        return null;
      }
    }
    return null;
  }, [web3]);

  return (
    <div className="min-h-screen bg-slate-900 font-sans text-slate-200 flex flex-col items-center">
      <Header account={account} connectWallet={connectWallet} />
      <main className="w-full max-w-4xl mx-auto p-4 md:p-8 flex-grow">
        {account ? (
          <ContractInteractor 
            web3={web3} 
            account={account}
            loadContract={loadContract} 
            loadedContract={contract}
            showNotification={showNotification}
          />
        ) : (
          <div className="text-center mt-20 bg-slate-800/50 p-10 rounded-xl border border-slate-700">
            <h2 className="text-2xl font-bold text-cyan-400 mb-4">Welcome to Lexifi</h2>
            <p className="text-slate-400 mb-6">
              Connect your wallet to manage your Uniswap V4 compliance hook on Arbitrum Sepolia
            </p>
            <button
              onClick={connectWallet}
              className="bg-cyan-500 hover:bg-cyan-600 text-white font-bold py-3 px-6 rounded-lg transition-colors duration-300"
            >
              Connect Wallet
            </button>
          </div>
        )}
        {error && <p className="text-red-500 mt-4 text-center">{error}</p>}
      </main>
      <Notification notification={notification} onClose={() => setNotification(null)} />
    </div>
  );
};

export default App;
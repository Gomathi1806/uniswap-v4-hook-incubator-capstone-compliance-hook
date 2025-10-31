import React from 'react';
import { LexifiLogo } from './icons/LexifiLogo';

interface HeaderProps {
  account: string | null;
  connectWallet: () => void;
}

const Header: React.FC<HeaderProps> = ({ account, connectWallet }) => {
  const truncatedAccount = account ? `${account.substring(0, 6)}...${account.substring(account.length - 4)}` : '';

  return (
    <header className="w-full bg-slate-900/80 backdrop-blur-sm border-b border-slate-700 sticky top-0 z-10">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          <div className="flex items-center space-x-3">
            <LexifiLogo className="h-8 w-8 text-cyan-500" />
            <span className="text-2xl font-bold tracking-tight text-slate-100">
              Lexifi
            </span>
          </div>
          <div className="flex items-center">
            {account ? (
              <div className="px-4 py-2 bg-slate-800 text-sm font-medium text-cyan-400 rounded-md border border-slate-700">
                {truncatedAccount}
              </div>
            ) : (
              <button
                onClick={connectWallet}
                className="bg-slate-700 hover:bg-slate-600 text-white font-semibold py-2 px-4 rounded-lg transition-colors duration-300"
              >
                Connect Wallet
              </button>
            )}
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header;

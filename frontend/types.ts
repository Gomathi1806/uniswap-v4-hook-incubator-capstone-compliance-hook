// A generic ABI item type structure to satisfy TypeScript when parsing user input.
export interface AbiItem {
  constant?: boolean;
  inputs?: {
    name: string;
    type: string;
    internalType?: string;
    components?: AbiItem[];
  }[];
  name?: string;
  outputs?: {
    name: string;
    type: string;
    internalType?: string;
    components?: AbiItem[];
  }[];
  payable?: boolean;
  // Fix: Use specific string literals for state mutability to match web3.js types.
  stateMutability?: 'pure' | 'view' | 'nonpayable' | 'payable';
  // Fix: Use specific string literals for ABI item type to match web3.js types.
  type: 'function' | 'constructor' | 'event' | 'fallback' | 'receive' | 'error';
  anonymous?: boolean;
}

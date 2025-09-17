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
  stateMutability?: 'pure' | 'view' | 'nonpayable' | 'payable';
  type: 'function' | 'constructor' | 'event' | 'fallback' | 'receive' | 'error';
  anonymous?: boolean;
}

# Uniswap V4 Compliance Hook with FHE Integration
A privacy-preserving, institutional-grade KYC/AML compliance system for Uniswap V4 that integrates Fhenix FHE technology for confidential compliance verification.
🔒 Privacy-First Compliance
This project combines traditional compliance requirements with cutting-edge privacy technology, ensuring regulatory compliance without sacrificing user confidentiality.
📋 Project Overview

Main Contract: 0x1d9be48c270dbda27e22c65cb899cce55763ebf4 (Sepolia)
Network: Ethereum Sepolia Testnet
Framework: Foundry + React Frontend
Privacy Layer: Fhenix FHE Integration (Planned)
Identity Verification: World ID Integration (Planned)

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │────│ Compliance Hook │────│ Fhenix FHE      │
│   Dashboard     │    │ (Sepolia)       │    │ (Privacy Layer) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   MetaMask      │    │ Risk Assessment │    │ World ID        │
│   Integration   │    │ & Scoring       │    │ Verification    │
└─────────────────┘    └─────────────────┘    └─────────────────┘

Getting Started
Prerequisites

Node.js 18+ and npm
Foundry (forge, cast, anvil)
MetaMask wallet
Sepolia ETH for testing

Installation

Clone the Repository

bash   git clone <your-repo-url>
   cd compliance-hook-project
   Install Dependencies

bash   # Install Foundry dependencies
   forge install
   
   # Install frontend dependencies (if using React frontend)
   npm install

Environment Setup

bash   # Create environment file
   cp .env.example .env
   
   # Configure your environment variables
   PRIVATE_KEY=your_private_key_here
   ETHERSCAN_API_KEY=your_etherscan_api_key
   SEPOLIA_RPC_URL=https://eth-sepolia.public.blastapi.io

   Running the Project
Step 1: Deploy Contract (Already Deployed)
The main contract is already deployed at 0x1d9be48c270dbda27e22c65cb899cce55763ebf4 on Sepolia.
To interact with the deployed contract:
bash# Check contract owner
cast call \
  --rpc-url https://eth-sepolia.public.blastapi.io \
  0x1d9be48c270dbda27e22c65cb899cce55763ebf4 \
  "owner()(address)"

# Check user compliance status
cast call \
  --rpc-url https://eth-sepolia.public.blastapi.io \
  0x1d9be48c270dbda27e22c65cb899cce55763ebf4 \
  "isCompliant(address)(bool)" \
  0xYOUR_ADDRESS_HERE

  Step 2: Run Frontend Dashboard

Open the Frontend

cd fronend
npm install

npm run dev
Local:   http://localhost:5173/

Step 3: Test Compliance Functions

As Contract Owner:

Verify users with risk scores (0-100)
Monitor compliance status
View transaction history


As Regular User:

Check your compliance status
View your risk score
Monitor verification status.

# Fhenix Integration (partnership) implementation code

# test/ Enhancedcompliancehook.sol-->(  lines 13, 18, 174 to 193)
# // src/libraries/FHEOperations.sol



# contract deployed
Compliance Hook for Regulated Pools--> Compliance Hook for Uniswap V4 that integrates KYC/AML checks for institutional users.
Deployed Contract
Contract Address**: `0x81Df62bD323cD2CE7484c7941000fd7104ec0a7c`
**Contract Address---> 0x0809Dd9b5B1403188E650725B02D634a63233480   (enhanced compliance.sol---Fhenix Integration)

**https://sepolia.etherscan.io/address/0x0809dd9b5b1403188e650725b02d634a63233480
# Contract Address: 0x5553FFb42bD40d3444F0fF9084Df0c7C49f329Be  (oracle)**

# Explorer**:   -->  https://sepolia.etherscan.io/address/0x5553ffb42bd40d3444f0ff9084df0c7c49f329be

Fhenixcompliancehook--->0x1D9be48c270dBDa27e22C65cb899cCe55763eBf4

Network**: Sepolia Testnet
**Explorer**: [View on Etherscan](https://sepolia.etherscan.io/address/0x0809dd9b5b1403188e650725b02d634a63233480)



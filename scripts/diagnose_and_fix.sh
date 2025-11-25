#!/bin/bash

# ========================================
# DIAGNOSTIC & FIX TOOL
# Finds the correct contract and verifies data
# ========================================

source .env

echo "🔍 COMPLIANCE CONTRACT DIAGNOSTIC"
echo "=================================="
echo ""

YOUR_WALLET="0xb33c...b408"  # From your screenshot
TX_HASH="0x06cc573e601164fd7e3ddc7612d2f8b7ab7e094149fff815aa96a588374768c8"

echo "Analyzing transaction: $TX_HASH"
echo ""

# Get transaction details
echo "📋 Fetching transaction details..."
TX_DATA=$(cast tx $TX_HASH --rpc-url $ARBITRUM_SEPOLIA_RPC_URL)

echo "$TX_DATA"
echo ""
echo "=========================================="
echo ""

# Extract the 'to' address (contract that was called)
CONTRACT_ADDRESS=$(echo "$TX_DATA" | grep "to" | awk '{print $2}')

if [ -z "$CONTRACT_ADDRESS" ]; then
    echo "❌ Could not extract contract address from transaction"
    echo ""
    echo "Please manually check:"
    echo "https://sepolia.arbiscan.io/tx/$TX_HASH"
    echo ""
    echo "Look for the 'To:' field - that's your contract address"
    exit 1
fi

echo "✅ Found contract address: $CONTRACT_ADDRESS"
echo ""

# Now verify the data is actually there
echo "🔍 Verifying data in contract..."
echo ""

RISK_SCORE=$(cast call $CONTRACT_ADDRESS \
  "getRiskScore(address)(uint256)" \
  $YOUR_WALLET \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL 2>&1)

echo "Risk Score Query Result: $RISK_SCORE"
echo ""

if [[ "$RISK_SCORE" =~ ^[0-9]+$ ]] && [ "$RISK_SCORE" != "0" ]; then
    echo "✅ SUCCESS! Contract has your data!"
    echo ""
    echo "📊 Your Compliance Data:"
    echo "  Contract: $CONTRACT_ADDRESS"
    echo "  Risk Score: $RISK_SCORE/100"
    echo ""
    echo "🔧 UPDATE YOUR FRONTEND:"
    echo ""
    echo "Edit: frontend/src/App.js"
    echo "Find line with: phase3Privacy:"
    echo "Replace with: phase3Privacy: '$CONTRACT_ADDRESS',"
    echo ""
    echo "Then restart: cd frontend && npm start"
else
    echo "⚠️ Contract found but no data returned"
    echo "Result: $RISK_SCORE"
    echo ""
    echo "Trying alternative function signature..."
    
    # Try getUserRiskScore instead
    RISK_SCORE_ALT=$(cast call $CONTRACT_ADDRESS \
      "getUserRiskScore(address)(uint256,uint256)" \
      $YOUR_WALLET \
      --rpc-url $ARBITRUM_SEPOLIA_RPC_URL 2>&1)
    
    echo "Alternative Result: $RISK_SCORE_ALT"
fi

echo ""
echo "=========================================="
echo "📍 Quick Reference:"
echo "  Your Wallet: $YOUR_WALLET"
echo "  Contract Called: $CONTRACT_ADDRESS"
echo "  Transaction: https://sepolia.arbiscan.io/tx/$TX_HASH"
echo "  Contract on Arbiscan: https://sepolia.arbiscan.io/address/$CONTRACT_ADDRESS"
echo ""

#!/bin/bash

# ========================================
# POPULATE ALL CONTRACTS - CORRECTED
# Uses YOUR real wallet address
# ========================================

source .env

# YOUR ACTUAL WALLET ADDRESS
YOUR_WALLET="0x3d25913bec5cef152776a8302db39a4ea700bc0b"

echo "🚀 POPULATING ALL 6 COMPLIANCE CONTRACTS"
echo "========================================="
echo ""

# Your actual deployed contracts
declare -A CONTRACTS
CONTRACTS[Phase1_Simple]="0x958e334669C2909F42Ac60C4a5E4fFCe3c3561Fa"
CONTRACTS[Phase2_Caching]="0x386aE91adA9D5bdCBb3130624755F717D620d9F3"
CONTRACTS[Phase1_OFAC]="0xd67963De79e9a3a6fcF1b8A622eedB5696757258"
CONTRACTS[Phase1_Chainlink]="0x86364De6403289106F52f5c85BBeB09e196a1D2d"
CONTRACTS[Phase2_Multi]="0x0Ad701309581F051f600688809f690a08F815855"
CONTRACTS[Phase3_Privacy]="0x3E9e0612592b0a99A0F7730E1B435Bf36b649E33"

echo "✅ Your Wallet: $YOUR_WALLET"
echo ""
echo "Contracts to populate:"
for name in "${!CONTRACTS[@]}"; do
  echo "  $name: ${CONTRACTS[$name]}"
done
echo ""

read -p "Add compliance data to ALL contracts? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
  echo "Cancelled"
  exit 0
fi

echo ""
echo "🔄 Adding data to all contracts..."
echo ""

SUCCESS=0
FAILED=0

for name in "${!CONTRACTS[@]}"; do
  ADDRESS="${CONTRACTS[$name]}"
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Adding to: $name"
  echo "Address: $ADDRESS"
  echo ""
  
  cast send $ADDRESS \
    "setComplianceData(address,uint256,uint256,uint256,bool,string)" \
    $YOUR_WALLET \
    80 \
    85 \
    100 \
    false \
    "US" \
    --rpc-url $ARBITRUM_SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --legacy
  
  if [ $? -eq 0 ]; then
    echo "✅ SUCCESS: $name"
    ((SUCCESS++))
  else
    echo "❌ FAILED: $name"
    ((FAILED++))
  fi
  
  echo ""
  sleep 2
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 RESULTS"
echo "=========="
echo "  Success: $SUCCESS"
echo "  Failed: $FAILED"
echo ""

if [ $SUCCESS -gt 0 ]; then
  echo "🔍 Verifying data for YOUR wallet: $YOUR_WALLET"
  echo ""
  
  for name in "${!CONTRACTS[@]}"; do
    ADDRESS="${CONTRACTS[$name]}"
    
    SCORE=$(cast call $ADDRESS \
      "getRiskScore(address)(uint256)" \
      $YOUR_WALLET \
      --rpc-url $ARBITRUM_SEPOLIA_RPC_URL 2>&1)
    
    if [[ "$SCORE" =~ ^[0-9]+$ ]]; then
      if [ "$SCORE" -gt 0 ]; then
        echo "✅ $name: $SCORE/100"
      else
        echo "⚠️  $name: 0/100 (no data)"
      fi
    else
      echo "❓ $name: Could not verify"
    fi
  done
  
  echo ""
  echo "🎉 COMPLETE!"
  echo ""
  echo "Next steps:"
  echo "  1. Refresh your frontend: http://localhost:3000"
  echo "  2. Connect wallet: $YOUR_WALLET"
  echo "  3. You should see green ✅ cards with scores!"
  echo ""
  echo "📍 View contracts on Arbiscan:"
  for name in "${!CONTRACTS[@]}"; do
    echo "  $name: https://sepolia.arbiscan.io/address/${CONTRACTS[$name]}"
  done
else
  echo "❌ No data was added successfully"
  echo ""
  echo "Troubleshooting:"
  echo "  1. Check your .env has PRIVATE_KEY set"
  echo "  2. Check you have ETH on Arbitrum Sepolia"
  echo "  3. Check RPC: echo \$ARBITRUM_SEPOLIA_RPC_URL"
  echo "  4. Verify your wallet: $YOUR_WALLET"
fi

echo ""
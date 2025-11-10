// SUPER SIMPLE HOOK REDEPLOYMENT
// Save as: scripts/redeploy_hook_NOW.js
// Run: npx hardhat run scripts/redeploy_hook_NOW.js --network arbitrumSepolia

const { ethers } = require('hardhat')

async function main () {
  console.log('\n🔧 REDEPLOYING HOOK WITH VALID ADDRESS\n')

  const [deployer] = await ethers.getSigners()
  console.log('Deployer:', deployer.address, '\n')

  // Your existing addresses
  const POOL_MANAGER = '0x8C4BcBE6b9eF47855f97E675296FA3F6fafa5F1A'
  const RISK_CALCULATOR = '0xa78751349D496a726dCfde91bec2C5BE9b52f31E'

  // Try deploying 10 times to hopefully get lucky with address bits
  console.log('🎲 Attempting deployments...\n')

  for (let attempt = 1; attempt <= 10; attempt++) {
    console.log(`Attempt ${attempt}...`)

    try {
      const ComplianceHook = await ethers.getContractFactory('ComplianceHook')
      const hook = await ComplianceHook.deploy(POOL_MANAGER, RISK_CALCULATOR)
      await hook.waitForDeployment()

      const address = await hook.getAddress()

      // Check if address has correct bits
      const addressBigInt = BigInt(address)
      const bit159 = (addressBigInt >> 159n) & 1n
      const bit153 = (addressBigInt >> 153n) & 1n
      const isValid = bit159 === 1n && bit153 === 1n

      console.log('  Address:', address)
      console.log('  beforeInitialize:', bit159 === 1n ? '✅' : '❌')
      console.log('  beforeSwap:', bit153 === 1n ? '✅' : '❌')

      if (isValid) {
        console.log('\n✅ SUCCESS! FOUND VALID ADDRESS!\n')
        console.log('═══════════════════════════════════════')
        console.log('NEW HOOK ADDRESS:', address)
        console.log('═══════════════════════════════════════\n')
        console.log('🎯 UPDATE YOUR FRONTEND:\n')
        console.log('In App.js, change to:')
        console.log(`hook: '${address}',\n`)
        console.log('Then: npm start\n')
        console.log('═══════════════════════════════════════')

        return // Stop trying, we found one!
      } else {
        console.log('  ❌ Invalid address, trying again...\n')
      }
    } catch (error) {
      console.log('  Error:', error.message, '\n')
    }
  }

  console.log('\n❌ No valid address found in 10 attempts.')
  console.log('This is rare! Run the script again or use CREATE2 method.')
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })

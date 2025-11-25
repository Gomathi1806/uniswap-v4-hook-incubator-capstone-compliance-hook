// ====== OFAC API CHECK - Chainlink Functions JavaScript Source ======
// This code runs on Chainlink's decentralized oracle network
// It fetches real-time OFAC sanctions data and returns it on-chain

/**
 * OFAC SDN List Check
 * Checks if an Ethereum address is associated with a sanctioned entity
 */

// Arguments: [ethereumAddress]
const ethereumAddress = args[0]

// OFAC API Configuration
// Note: In production, use secrets for API keys
const OFAC_API_URL = 'https://api.ofac.treasury.gov/search'
const CHAINALYSIS_API_URL = 'https://api.chainalysis.com/v1/sanctions/screening'

// Multiple data source approach for reliability
const dataSources = [
  {
    name: 'OFAC_SDN',
    url: `${OFAC_API_URL}?address=${ethereumAddress}&format=json`,
    headers: {
      'Content-Type': 'application/json'
    }
  },
  {
    name: 'CHAINALYSIS_SANCTIONS',
    url: `${CHAINALYSIS_API_URL}`,
    headers: {
      'X-API-Key': secrets.CHAINALYSIS_API_KEY,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      address: ethereumAddress,
      asset: 'ETH'
    })
  }
]

// Result aggregation
let results = {
  isOnOFACList: false,
  isOnChainalysisList: false,
  riskScore: 100, // Start at 100 (clean)
  sources: []
}

// Check OFAC SDN List
try {
  const ofacRequest = Functions.makeHttpRequest({
    url: dataSources[0].url,
    method: 'GET',
    headers: dataSources[0].headers,
    timeout: 9000
  })

  const ofacResponse = await ofacRequest

  if (ofacResponse.error) {
    console.log('OFAC API Error:', ofacResponse.error)
  } else {
    const ofacData = ofacResponse.data

    // Parse OFAC response
    // OFAC API returns matches in "results" array
    if (ofacData && ofacData.results && ofacData.results.length > 0) {
      results.isOnOFACList = true
      results.riskScore = 0 // Sanctioned
      results.sources.push('OFAC_SDN')

      console.log('Address found on OFAC SDN list')
    } else {
      console.log('Address clear on OFAC SDN list')
    }
  }
} catch (error) {
  console.log('Error checking OFAC:', error.message)
}

// Check Chainalysis Sanctions
try {
  const chainalysisRequest = Functions.makeHttpRequest({
    url: dataSources[1].url,
    method: 'POST',
    headers: dataSources[1].headers,
    data: dataSources[1].body,
    timeout: 9000
  })

  const chainalysisResponse = await chainalysisRequest

  if (chainalysisResponse.error) {
    console.log('Chainalysis API Error:', chainalysisResponse.error)
  } else {
    const chainalysisData = chainalysisResponse.data

    // Parse Chainalysis response
    if (chainalysisData && chainalysisData.identifications) {
      const identifications = chainalysisData.identifications

      // Check for sanctions category
      const hasSanctions = identifications.some(
        id =>
          id.category === 'sanctions' || id.category === 'terrorism financing'
      )

      if (hasSanctions) {
        results.isOnChainalysisList = true
        results.riskScore = Math.min(results.riskScore, 0)
        results.sources.push('CHAINALYSIS')

        console.log('Address flagged by Chainalysis')
      }

      // Calculate risk score based on other categories
      const highRiskCategories = identifications.filter(
        id =>
          id.category === 'dark market' ||
          id.category === 'mixer' ||
          id.category === 'stolen funds'
      )

      if (highRiskCategories.length > 0 && !hasSanctions) {
        results.riskScore = 25 // High risk but not sanctioned
        results.sources.push('CHAINALYSIS_HIGH_RISK')
      }
    } else {
      console.log('Address clear on Chainalysis')
    }
  }
} catch (error) {
  console.log('Error checking Chainalysis:', error.message)
}

// Determine final result
const isSanctioned = results.isOnOFACList || results.isOnChainalysisList

// Encode response for on-chain consumption
// Format: [isSanctioned (1 byte), riskScore (1 byte), sources (string)]
const response = {
  isSanctioned: isSanctioned,
  riskScore: results.riskScore,
  sources: results.sources.join(','),
  timestamp: Math.floor(Date.now() / 1000)
}

// Return encoded response
// Chainlink Functions expects a Buffer or Uint8Array
const encodedResponse = Buffer.concat([
  Buffer.from([isSanctioned ? 1 : 0]),
  Buffer.from([results.riskScore]),
  Buffer.from(JSON.stringify(response))
])

return encodedResponse

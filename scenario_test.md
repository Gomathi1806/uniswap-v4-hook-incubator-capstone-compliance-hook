Scenario 1: Compliant User (Risk Score ≤ 70)

cast send 0x9a65bD1Ae5bb75697f6DAbeb132C776428339DFb "verifyUser(address,uint256)" 0x1234567890123456789012345678901234567890 30 --private-key 0x05ba42c8ee03e05c1e942f25e1b9beb9ad6ec2b5c2c347ed0303bce2971383f9 --rpc-url https://eth-sepolia.public.blastapi.io


cast call 0x9a65bD1Ae5bb75697f6DAbeb132C776428339DFb "isCompliant(address)(bool)" 0x1234567890123456789012345678901234567890 --rpc-url https://eth-sepolia.public.blastapi.io

Scenario 2: Non-Compliant User (Risk Score > 70)

cast send 0x9a65bD1Ae5bb75697f6DAbeb132C776428339DFb "verifyUser(address,uint256)" 0x9876543210987654321098765432109876543210 85 --private-key 0x05ba42c8ee03e05c1e942f25e1b9beb9ad6ec2b5c2c347ed0303bce2971383f9 --rpc-url https://eth-sepolia.public.blastapi.io

cast call 0x9a65bD1Ae5bb75697f6DAbeb132C776428339DFb "isCompliant(address)(bool)" 0x9876543210987654321098765432109876543210 --rpc-url https://eth-sepolia.public.blastapi.io

Scenario 3: Unauthorized Access Test

cast send 0x9a65bD1Ae5bb75697f6DAbeb132C776428339DFb "verifyUser(address,uint256)" 0x1111111111111111111111111111111111111111 50 --private-key 0x1234... --rpc-url https://eth-sepolia.public.blastapi.io

Event Monitoring

cast logs --from-block 9208754 --address 0x9a65bD1Ae5bb75697f6DAbeb132C776428339DFb --rpc-url https://eth-sepolia.public.blastapi.io

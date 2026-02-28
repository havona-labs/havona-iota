# Deployments

All contracts are deployed and verified on IOTA EVM Testnet (chain 1076).

## IOTA EVM Testnet

| Contract | Address | Tx | Explorer |
|----------|---------|-------|----------|
| HavonaPersistor | `0x8b43Aef8D96FAE2FC3c428B00A127D80D159C131` | [deploy tx](https://explorer.evm.testnet.iotaledger.net/tx/0x5cfe733dc4eed866e36bdb1e7a8adcebbbabccb0c81a270dce473fd4103293f1) | [View](https://explorer.evm.testnet.iotaledger.net/address/0x8b43Aef8D96FAE2FC3c428B00A127D80D159C131) |
| P256Verifier | `0xb6d9e6dC3f13413656b74951776f1EE067758613` | [deploy tx](https://explorer.evm.testnet.iotaledger.net/tx/0x4ffdba1a33322dafa02c9eefcfc8390243c02a27c80273bfd6fb903fc2bb6010) | [View](https://explorer.evm.testnet.iotaledger.net/address/0xb6d9e6dC3f13413656b74951776f1EE067758613) |
| HavonaAgentRegistry | `0x15aD28c89CD9364DC1476a400916a18b0AD35ec1` | [deploy tx](https://explorer.evm.testnet.iotaledger.net/tx/0xd7d5f83e8e389388b2b0ec87b3d040f5f65fff513dc6ffb4666918f1afe0bd15) | [View](https://explorer.evm.testnet.iotaledger.net/address/0x15aD28c89CD9364DC1476a400916a18b0AD35ec1) |
| HavonaAgentReputation | `0x992F88045410e5D0b923384e372058db8c3ccc29` | [deploy tx](https://explorer.evm.testnet.iotaledger.net/tx/0x92b7511f9e9e5ddb616f07a6efacb9e5d0c399d0392f5609fb02c3da6ce391b2) | [View](https://explorer.evm.testnet.iotaledger.net/address/0x992F88045410e5D0b923384e372058db8c3ccc29) |
| ETRRegistry | `0x8C624363eba4FA8Da595EDa6cC2052D993c4Bd99` | [deploy tx](https://explorer.evm.testnet.iotaledger.net/tx/0xf88fb63cf7e27e73a962e35c4cb10420126adfe32b6dad42dc751ee6f6428153) | [View](https://explorer.evm.testnet.iotaledger.net/address/0x8C624363eba4FA8Da595EDa6cC2052D993c4Bd99) |
| ETRSeal | `0x96Ee195016BeA9881CE6D60F6A69A7abDceDa052` | [deploy tx](https://explorer.evm.testnet.iotaledger.net/tx/0xeb9bff890f17a901b8a0b608202242b7e86d5b37f257acbdd13ef555a6d0a563) | [View](https://explorer.evm.testnet.iotaledger.net/address/0x96Ee195016BeA9881CE6D60F6A69A7abDceDa052) |
| IOTAIdentityAnchor | `0xa4CBeF2975544378BbB4808f8cF8Db362D10eEca` | [deploy tx](https://explorer.evm.testnet.iotaledger.net/tx/0x55532bc28bd2ef967a73bb7ce002a84bd47846404ecea0febcc7affde7f643b1) | [View](https://explorer.evm.testnet.iotaledger.net/address/0xa4CBeF2975544378BbB4808f8cF8Db362D10eEca) |

**Deployer:** `0x6BA33AD26aDf9d115BFf918D0FdB5d16397Bd941`
**Chain ID:** 1076
**RPC:** `https://json-rpc.evm.testnet.iotaledger.net`
**Deployed:** 2026-02-28

## Deployment Notes

- IOTA EVM does **not** support EIP-1559. All transactions use legacy gas pricing (`--legacy` flag in Foundry).
- Gas costs are low (~0.005 IOTA per contract deployment at 10 gwei gas price).
- Structured deployment record: [`deployments/iota-evm-testnet.json`](deployments/iota-evm-testnet.json)

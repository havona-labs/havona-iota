# Deployments

All contracts are deployed and verified on IOTA EVM Testnet (chain 1076).

## IOTA EVM Testnet

| Contract | Address | Explorer |
|----------|---------|----------|
| HavonaPersistor | `0x8b43Aef8D96FAE2FC3c428B00A127D80D159C131` | [View](https://explorer.evm.testnet.iotaledger.net/address/0x8b43Aef8D96FAE2FC3c428B00A127D80D159C131) |
| P256Verifier | `0xb6d9e6dC3f13413656b74951776f1EE067758613` | [View](https://explorer.evm.testnet.iotaledger.net/address/0xb6d9e6dC3f13413656b74951776f1EE067758613) |
| HavonaAgentRegistry | `0x15aD28c89CD9364DC1476a400916a18b0AD35ec1` | [View](https://explorer.evm.testnet.iotaledger.net/address/0x15aD28c89CD9364DC1476a400916a18b0AD35ec1) |
| HavonaAgentReputation | `0x992F88045410e5D0b923384e372058db8c3ccc29` | [View](https://explorer.evm.testnet.iotaledger.net/address/0x992F88045410e5D0b923384e372058db8c3ccc29) |
| ETRRegistry | `0x8C624363eba4FA8Da595EDa6cC2052D993c4Bd99` | [View](https://explorer.evm.testnet.iotaledger.net/address/0x8C624363eba4FA8Da595EDa6cC2052D993c4Bd99) |
| ETRSeal | `0x96Ee195016BeA9881CE6D60F6A69A7abDceDa052` | [View](https://explorer.evm.testnet.iotaledger.net/address/0x96Ee195016BeA9881CE6D60F6A69A7abDceDa052) |
| IOTAIdentityAnchor | `0xa4CBeF2975544378BbB4808f8cF8Db362D10eEca` | [View](https://explorer.evm.testnet.iotaledger.net/address/0xa4CBeF2975544378BbB4808f8cF8Db362D10eEca) |

**Deployer:** `0x6BA33AD26aDf9d115BFf918D0FdB5d16397Bd941`
**Chain ID:** 1076
**RPC:** `https://json-rpc.evm.testnet.iotaledger.net`
**Deployed:** 2026-02-28

## Deployment Notes

- IOTA EVM does **not** support EIP-1559. All transactions use legacy gas pricing (`--legacy` flag in Foundry).
- Gas costs are low (~0.005 IOTA per contract deployment at 10 gwei gas price).
- Structured deployment record: [`deployments/iota-evm-testnet.json`](deployments/iota-evm-testnet.json)

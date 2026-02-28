# Havona — IOTA EVM Smart Contracts

Digital trade contract infrastructure for IOTA. Seven smart contracts deployed on IOTA EVM handling trade persistence, MLETR-compliant electronic transferable records, autonomous agent identity (ERC-8004), document attestation, and IOTA Identity DID anchoring.

## Deployed Contracts (IOTA EVM Testnet)

| Contract | Address | Purpose |
|----------|---------|---------|
| [HavonaPersistor](https://explorer.evm.testnet.iotaledger.net/address/0x8b43Aef8D96FAE2FC3c428B00A127D80D159C131) | `0x8b43...C131` | Trade data persistence (CBOR + P-256 signing) |
| [P256Verifier](https://explorer.evm.testnet.iotaledger.net/address/0xb6d9e6dC3f13413656b74951776f1EE067758613) | `0xb6d9...8613` | WebAuthn/YubiKey signature verification |
| [HavonaAgentRegistry](https://explorer.evm.testnet.iotaledger.net/address/0x15aD28c89CD9364DC1476a400916a18b0AD35ec1) | `0x15aD...5ec1` | ERC-8004 autonomous agent identity |
| [HavonaAgentReputation](https://explorer.evm.testnet.iotaledger.net/address/0x992F88045410e5D0b923384e372058db8c3ccc29) | `0x992F...cc29` | Agent reputation and feedback |
| [ETRRegistry](https://explorer.evm.testnet.iotaledger.net/address/0x8C624363eba4FA8Da595EDa6cC2052D993c4Bd99) | `0x8C62...Bd99` | MLETR-compliant ETR lifecycle events |
| [ETRSeal](https://explorer.evm.testnet.iotaledger.net/address/0x96Ee195016BeA9881CE6D60F6A69A7abDceDa052) | `0x96Ee...a052` | Permissionless document attestation |
| [IOTAIdentityAnchor](https://explorer.evm.testnet.iotaledger.net/address/0xa4CBeF2975544378BbB4808f8cF8Db362D10eEca) | `0xa4CB...eEca` | IOTA Identity DID anchor |

Chain ID: **1076** | RPC: `https://json-rpc.evm.testnet.iotaledger.net`

## What This Does

Havona is a trade contract and document management platform for international commodity trading. These contracts provide the on-chain layer:

- **Trade persistence** — CBOR-encoded trade data with versioning, access control, and hardware-backed P-256 signatures (WebAuthn/YubiKey)
- **Electronic Transferable Records** — MLETR-compliant lifecycle tracking (pledge, transfer, liquidation, redemption) for bills of lading, promissory notes, and warehouse receipts
- **Document attestation** — Permissionless hash-and-timestamp for any trade document. Free verification. A public good on IOTA EVM
- **Agent identity** — ERC-8004 registry for autonomous trade agents with reputation tracking
- **DID anchoring** — Bidirectional mapping between IOTA Identity DIDs and EVM addresses

## Why IOTA

IOTA's ecosystem aligns with Havona's trade infrastructure needs:

- **TWIN Foundation** — co-founded with the WEF and Tony Blair Institute for trade data standardisation. Existing pilot networks in Rwanda, Kenya, and Ethiopia provide real trade corridors
- **IOTA Identity** — W3C DID-compliant decentralised identifiers for trade participant verification without centralised certificate authorities
- **EVM compatibility** — standard Solidity contracts deploy without modification, with low gas costs (~0.001 IOTA per transaction)
- **Gas Station / ERC-4337** — path to gasless transactions for non-crypto-native trade participants (banks, commodity traders)

## Build and Test

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Clone and install dependencies
git clone https://github.com/havona-labs/havona-iota.git
cd havona-iota
forge install

# Build
forge build

# Test (161 tests across 7 suites)
forge test -vvv
```

## Deploy

```bash
# Testnet (default)
./script/deploy_iota.sh --private-key 0x...

# Mainnet
./script/deploy_iota.sh --private-key 0x... --mainnet

# Dry run (build only)
./script/deploy_iota.sh --dry-run
```

IOTA EVM does not support EIP-1559. The deploy script uses `--legacy` transactions automatically.

## Project Structure

```
src/
  HavonaPersistor.sol          — Trade data persistence (CBOR + P-256)
  P256Verifier.sol             — WebAuthn/YubiKey P-256 verification
  ETRRegistry.sol              — MLETR lifecycle events
  ETRSeal.sol                  — Permissionless document attestation
  IOTAIdentityAnchor.sol       — IOTA Identity DID anchor
  HavonaAgentRegistry.sol      — ERC-8004 agent identity
  HavonaAgentReputation.sol    — Agent reputation
  HavonaMemberManager.sol      — Member registry
  interfaces/                  — Contract interfaces
  components/                  — CBOR encoding libraries
test/                          — Foundry tests (161 total)
script/                        — Deploy scripts + deploy_iota.sh
deployments/                   — Deployment records (JSON)
```

## Documentation

- [DEPLOYMENTS.md](DEPLOYMENTS.md) — All contract addresses with explorer links
- [ARCHITECTURE.md](ARCHITECTURE.md) — IOTA integration architecture (TWIN, Identity, ERC-4337, Gas Station)

## Licence

MIT

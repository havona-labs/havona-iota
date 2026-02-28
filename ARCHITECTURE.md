# Architecture

Havona's IOTA integration has three layers: on-chain contracts (this repo), off-chain services (private), and IOTA-native protocols.

## Contract Architecture

```
                         ┌─────────────────────────────┐
                         │      Havona Platform         │
                         │   (off-chain, private repo)  │
                         └──────────┬──────────────────┘
                                    │
                    ┌───────────────┼───────────────────┐
                    │               │                   │
              ┌─────▼─────┐  ┌─────▼──────┐  ┌────────▼────────┐
              │  Trade     │  │  Identity  │  │  Agent          │
              │  Layer     │  │  Layer     │  │  Layer          │
              └─────┬──┬──┘  └─────┬──────┘  └────────┬────────┘
                    │  │           │                   │
         ┌──────┐  │  │    ┌──────▼──────┐   ┌───────▼────────┐
         │Persis│  │  │    │Identity     │   │AgentRegistry   │
         │tor   │◄─┘  │    │Anchor       │   │(ERC-8004)      │
         └──┬───┘     │    └─────────────┘   └───────┬────────┘
            │         │                              │
         ┌──▼───┐  ┌──▼──────┐              ┌───────▼────────┐
         │P256  │  │ETR      │              │AgentReputation │
         │Verify│  │Registry │              └────────────────┘
         └──────┘  └─────────┘
                   ┌──────────┐
                   │ETRSeal   │  ← permissionless, public good
                   └──────────┘
```

### Trade Persistence Layer

**HavonaPersistor** stores trade contract data as CBOR-encoded blobs with versioning and access control. Trade data is written by the Havona server and readable by authorised counterparties. P-256 (WebAuthn/YubiKey) signature verification via **P256Verifier** allows hardware-backed attestation of trade submissions.

**ETRRegistry** records MLETR-compliant lifecycle events for Electronic Transferable Records: pledge, release, transfer, liquidation, and redemption. These events form the immutable audit trail required by banks and regulators.

**ETRSeal** is permissionless. Any party can hash and timestamp a trade document on IOTA EVM. Verification is free (view function). Useful for pre-submission document attestation, inspection certificates, and independent proof of existence.

### Identity Layer

**IOTAIdentityAnchor** stores bidirectional mappings between IOTA Identity DIDs and EVM addresses. The Havona server anchors references after verifying DID documents via the IOTA Identity WASM SDK. This contract is the on-chain half; the off-chain SDK integration resolves full DID documents from the IOTA Tangle.

**HavonaMemberManager** maintains the member registry with company details, collaborator roles, and status lifecycle (pending, active, revoked).

### Agent Layer

**HavonaAgentRegistry** implements ERC-8004 for autonomous trade agent identity. Agents are registered with metadata URIs and can have their wallets updated via P-256 signed messages. **HavonaAgentReputation** tracks feedback scores with client-specific and tag-filtered aggregation.

## IOTA Ecosystem Integration

### IOTA Identity (Milestone 2)

IOTA Identity provides W3C DID-compliant decentralised identifiers anchored on the IOTA Tangle (MoveVM L1). The integration:

1. **On-chain anchor** (IOTAIdentityAnchor.sol): stores DID-to-address mappings on EVM
2. **Off-chain resolver** (IOTA Identity WASM SDK): resolves full DID documents from Tangle
3. **Verification flow**: counterparty submits DID > server resolves via SDK > verifies controller > anchors on EVM > subsequent lookups are on-chain only

No centralised certificate authorities needed for trade document workflows.

### TWIN Foundation Data (Milestone 2)

The Trade and Welfare Information Network (TWIN), co-founded by the IOTA Foundation, WEF, and the Tony Blair Institute, provides standardised trade data infrastructure. Integration points:

- **Trade data standards**: TWIN's data schemas for agricultural commodity trade align with Havona's trade contract model
- **Cross-border data sharing**: TWIN's existing government pilot networks (Rwanda, Kenya, Ethiopia) provide real trade corridors for Havona deployment
- **Regulatory compliance**: TWIN's regulatory frameworks inform Havona's MLETR compliance approach

### Gas Station / ERC-4337 (Milestone 3)

IOTA's Gas Station operates on MoveVM L1 and is not directly available on EVM L2. For the EVM layer, Havona will implement gasless transactions via ERC-4337 account abstraction:

- **Bundler**: submits UserOperations on behalf of trade participants
- **Paymaster**: Havona-operated paymaster covers gas for verified trade operations
- **Smart accounts**: trade counterparties interact through smart contract wallets, no need to hold IOTA tokens

This removes the gas barrier for non-crypto-native trade participants (banks, commodity traders, shipping companies).

## Gas Costs (IOTA EVM Testnet)

Measured on chain 1076 at 10 gwei gas price:

| Operation | Gas | Cost (IOTA) |
|-----------|-----|-------------|
| ETRSeal.seal() | ~96,000 | ~0.00096 |
| ETRSeal.sealBatch(5) | ~371,000 | ~0.00371 |
| ETRSeal.verifySeal() | ~1,300 | free (view) |
| IOTAIdentityAnchor.anchorDID() | ~81,000 | ~0.00081 |
| IOTAIdentityAnchor.resolve() | ~1,600 | free (view) |
| ETRRegistry.recordPledge() | ~89,000 | ~0.00089 |
| HavonaPersistor.setBlob() | ~128,000 | ~0.00128 |
| Contract deployment | ~400-900k | ~0.004-0.009 |

Total cost to deploy all 7 contracts: ~0.03 IOTA.

## Security Model

- **Owner-gated writes**: HavonaPersistor, ETRRegistry, IOTAIdentityAnchor, AgentRegistry. Only the deploying Havona server can write.
- **Permissionless reads**: all view functions are public and free
- **Permissionless writes**: ETRSeal is fully permissionless (public good)
- **Hardware signing**: P256Verifier supports WebAuthn/YubiKey for trade submission attestation
- **No upgradability**: all contracts are immutable once deployed

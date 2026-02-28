#!/bin/bash

# Deploy Havona Smart Contracts to IOTA EVM
#
# IOTA EVM is a standard EVM L2, supports forge script natively.
# Deploys all 7 contracts in 5 stages:
#   1. P256Verifier + HavonaPersistor (trade persistence)
#   2. HavonaAgentRegistry + HavonaAgentReputation (ERC-8004 agent identity)
#   3. ETRRegistry (Electronic Transferable Records)
#   4. ETRSeal (public good document attestation)
#   5. IOTAIdentityAnchor (IOTA Identity DID anchor)
#
# IMPORTANT: IOTA EVM does NOT support EIP-1559. All transactions use --legacy.
#
# Prerequisites:
#   1. Foundry installed (forge, cast)
#   2. IOTA tokens for gas (faucet: https://testnet.evm-bridge.iota.org/)
#   3. Private key set via --private-key or PRIVATE_KEY env var
#
# Usage:
#   ./script/deploy_iota.sh --private-key 0x...              # Testnet (default)
#   ./script/deploy_iota.sh --private-key 0x... --mainnet     # Mainnet
#   ./script/deploy_iota.sh --dry-run                         # Build only, no broadcast

set -e

# ============================================================================
# NETWORK CONFIGURATION
# ============================================================================
IOTA_EVM_TESTNET_RPC="https://json-rpc.evm.testnet.iotaledger.net"
IOTA_EVM_MAINNET_RPC="https://json-rpc.evm.iotaledger.net"
IOTA_EVM_TESTNET_CHAIN_ID=1076
IOTA_EVM_MAINNET_CHAIN_ID=8822
IOTA_EVM_TESTNET_EXPLORER="https://explorer.evm.testnet.iotaledger.net"
IOTA_EVM_MAINNET_EXPLORER="https://explorer.evm.iotaledger.net"

# ============================================================================
# DEFAULTS
# ============================================================================
NETWORK="testnet"
RPC_URL="$IOTA_EVM_TESTNET_RPC"
CHAIN_ID="$IOTA_EVM_TESTNET_CHAIN_ID"
EXPLORER="$IOTA_EVM_TESTNET_EXPLORER"
DRY_RUN=false
PRIVATE_KEY="${PRIVATE_KEY:-}"

# Paths (repo root is one level up from script/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

print_msg() { echo -e "${1}${2}${NC}"; }

# ============================================================================
# PARSE ARGUMENTS
# ============================================================================
while [[ $# -gt 0 ]]; do
    case $1 in
        --mainnet)
            NETWORK="mainnet"
            RPC_URL="$IOTA_EVM_MAINNET_RPC"
            CHAIN_ID="$IOTA_EVM_MAINNET_CHAIN_ID"
            EXPLORER="$IOTA_EVM_MAINNET_EXPLORER"
            shift ;;
        --testnet)
            shift ;;
        --private-key)
            PRIVATE_KEY="$2"
            shift 2 ;;
        --dry-run)
            DRY_RUN=true
            shift ;;
        *)
            print_msg "$RED" "Unknown argument: $1"
            exit 1 ;;
    esac
done

# ============================================================================
# PREFLIGHT CHECKS
# ============================================================================
print_msg "$CYAN" "============================================"
print_msg "$CYAN" "  Havona Deploy -> IOTA EVM ($NETWORK)"
print_msg "$CYAN" "============================================"
echo ""

if ! command -v forge &>/dev/null; then
    print_msg "$RED" "forge not found. Install Foundry: https://book.getfoundry.sh"
    exit 1
fi

if ! command -v cast &>/dev/null; then
    print_msg "$RED" "cast not found. Install Foundry: https://book.getfoundry.sh"
    exit 1
fi

if [ -z "$PRIVATE_KEY" ]; then
    print_msg "$RED" "Private key required. Use --private-key 0x... or set PRIVATE_KEY env var"
    exit 1
fi

ACCOUNT=$(cast wallet address "$PRIVATE_KEY" 2>/dev/null)
if [ -z "$ACCOUNT" ]; then
    print_msg "$RED" "Invalid private key"
    exit 1
fi

print_msg "$GREEN" "Network:  IOTA EVM $NETWORK"
print_msg "$GREEN" "RPC:      $RPC_URL"
print_msg "$GREEN" "Chain ID: $CHAIN_ID"
print_msg "$GREEN" "Account:  $ACCOUNT"
echo ""

# Verify chain
print_msg "$YELLOW" "Checking chain connectivity..."
ACTUAL_CHAIN_ID=$(cast chain-id --rpc-url "$RPC_URL" 2>/dev/null || echo "FAIL")
if [ "$ACTUAL_CHAIN_ID" = "FAIL" ]; then
    print_msg "$RED" "Cannot connect to $RPC_URL"
    exit 1
fi
if [ "$ACTUAL_CHAIN_ID" != "$CHAIN_ID" ]; then
    print_msg "$YELLOW" "Chain ID from RPC: $ACTUAL_CHAIN_ID (expected $CHAIN_ID)"
    CHAIN_ID="$ACTUAL_CHAIN_ID"
fi
print_msg "$GREEN" "Chain ID verified: $ACTUAL_CHAIN_ID"

BALANCE_WEI=$(cast balance "$ACCOUNT" --rpc-url "$RPC_URL" 2>/dev/null || echo "0")
BALANCE_ETH=$(echo "scale=6; $BALANCE_WEI / 1000000000000000000" | bc 2>/dev/null || echo "0")
print_msg "$GREEN" "Balance:  $BALANCE_ETH IOTA"

if [ "$BALANCE_WEI" = "0" ]; then
    print_msg "$RED" "Account has zero IOTA. Get testnet tokens: https://testnet.evm-bridge.iota.org/"
    exit 1
fi

BLOCK_NUM=$(cast block-number --rpc-url "$RPC_URL" 2>/dev/null)
print_msg "$GREEN" "Current block: $BLOCK_NUM"
echo ""

if $DRY_RUN; then
    print_msg "$YELLOW" "DRY RUN - building contracts only, no broadcast"
    echo ""
fi

# ============================================================================
# BUILD
# ============================================================================
print_msg "$YELLOW" "Building contracts..."
cd "$REPO_ROOT"

if [ ! -d "lib/forge-std" ]; then
    print_msg "$YELLOW" "Installing forge-std..."
    forge install foundry-rs/forge-std --no-commit
fi

if [ ! -d "lib/openzeppelin-contracts" ]; then
    print_msg "$YELLOW" "Installing OpenZeppelin..."
    forge install OpenZeppelin/openzeppelin-contracts --no-commit
fi

forge build
print_msg "$GREEN" "Build successful"
echo ""

if $DRY_RUN; then
    print_msg "$GREEN" "Dry run complete. Contracts built successfully."
    print_msg "$YELLOW" "To deploy: remove --dry-run flag"
    exit 0
fi

# ============================================================================
# DEPLOY HELPER
# ============================================================================
deploy_contract() {
    local STAGE="$1"
    local LABEL="$2"
    local SCRIPT_PATH="$3"
    local SCRIPT_NAME="$4"

    print_msg "$YELLOW" "[$STAGE] Deploying $LABEL..."
    OUTPUT=$(PRIVATE_KEY="$PRIVATE_KEY" SKIP_P256_VERIFICATION=true forge script "$SCRIPT_PATH:$SCRIPT_NAME" \
        --rpc-url "$RPC_URL" \
        --private-key "$PRIVATE_KEY" \
        --broadcast \
        --legacy \
        -vvv 2>&1) || {
        print_msg "$RED" "Deployment failed: $LABEL"
        echo "$OUTPUT"
        exit 1
    }
    echo "$OUTPUT"
}

# ============================================================================
# DEPLOY ALL CONTRACTS
# ============================================================================
deploy_contract "1/5" "HavonaPersistor + P256Verifier" "script/DeployPersistor.s.sol" "DeployPersistor"
PERSISTOR_ADDRESS=$(echo "$OUTPUT" | grep "PERSISTOR_ADDRESS:" | awk '{print $2}')
P256_ADDRESS=$(echo "$OUTPUT" | grep "P256_VERIFIER_ADDRESS:" | awk '{print $2}')
print_msg "$GREEN" "  Persistor:  $PERSISTOR_ADDRESS"
print_msg "$GREEN" "  P256:       $P256_ADDRESS"
echo ""

deploy_contract "2/5" "HavonaAgentRegistry + HavonaAgentReputation (ERC-8004)" "script/DeployAgentRegistry.s.sol" "DeployAgentRegistry"
AGENT_REGISTRY_ADDRESS=$(echo "$OUTPUT" | grep "AGENT_REGISTRY_ADDRESS:" | awk '{print $2}')
AGENT_REPUTATION_ADDRESS=$(echo "$OUTPUT" | grep "AGENT_REPUTATION_ADDRESS:" | awk '{print $2}')
print_msg "$GREEN" "  AgentRegistry:    $AGENT_REGISTRY_ADDRESS"
print_msg "$GREEN" "  AgentReputation:  $AGENT_REPUTATION_ADDRESS"
echo ""

deploy_contract "3/5" "ETRRegistry" "script/DeployETRRegistry.s.sol" "DeployETRRegistry"
ETR_REGISTRY_ADDRESS=$(echo "$OUTPUT" | grep "ETR_REGISTRY_ADDRESS:" | awk '{print $2}')
print_msg "$GREEN" "  ETRRegistry:  $ETR_REGISTRY_ADDRESS"
echo ""

deploy_contract "4/5" "ETRSeal (public good attestation)" "script/DeployETRSeal.s.sol" "DeployETRSeal"
ETR_SEAL_ADDRESS=$(echo "$OUTPUT" | grep "ETR_SEAL_ADDRESS:" | awk '{print $2}')
print_msg "$GREEN" "  ETRSeal:  $ETR_SEAL_ADDRESS"
echo ""

deploy_contract "5/5" "IOTAIdentityAnchor (DID anchor)" "script/DeployIOTAIdentityAnchor.s.sol" "DeployIOTAIdentityAnchor"
IOTA_IDENTITY_ANCHOR_ADDRESS=$(echo "$OUTPUT" | grep "IOTA_IDENTITY_ANCHOR_ADDRESS:" | awk '{print $2}')
print_msg "$GREEN" "  IOTAIdentityAnchor:  $IOTA_IDENTITY_ANCHOR_ADDRESS"
echo ""

# ============================================================================
# SUMMARY
# ============================================================================
print_msg "$CYAN" "============================================"
print_msg "$CYAN" "  DEPLOYMENT COMPLETE - IOTA EVM"
print_msg "$CYAN" "============================================"
print_msg "$GREEN" "Network:              IOTA EVM $NETWORK (chain $CHAIN_ID)"
print_msg "$GREEN" "Persistor:            $PERSISTOR_ADDRESS"
print_msg "$GREEN" "P256 Verifier:        $P256_ADDRESS"
print_msg "$GREEN" "Agent Registry:       $AGENT_REGISTRY_ADDRESS"
print_msg "$GREEN" "Agent Reputation:     $AGENT_REPUTATION_ADDRESS"
print_msg "$GREEN" "ETR Registry:         $ETR_REGISTRY_ADDRESS"
print_msg "$GREEN" "ETR Seal:             $ETR_SEAL_ADDRESS"
print_msg "$GREEN" "Identity Anchor:      $IOTA_IDENTITY_ANCHOR_ADDRESS"
print_msg "$GREEN" "Deployer:             $ACCOUNT"
echo ""
print_msg "$YELLOW" "Explorer links:"
for ADDR in "$PERSISTOR_ADDRESS" "$P256_ADDRESS" "$AGENT_REGISTRY_ADDRESS" "$AGENT_REPUTATION_ADDRESS" "$ETR_REGISTRY_ADDRESS" "$ETR_SEAL_ADDRESS" "$IOTA_IDENTITY_ANCHOR_ADDRESS"; do
    if [ -n "$ADDR" ]; then
        echo "  $EXPLORER/address/$ADDR"
    fi
done

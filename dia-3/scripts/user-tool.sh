#!/usr/bin/env bash
# User tool — invocations signed by the investor / token holder.
# Replace placeholders before running on testnet.

set -euo pipefail

NETWORK="${NETWORK:-testnet}"
USER_KEY="${USER_KEY:-ramon}"
CONTRACT_ID="${CONTRACT_ID:-CDCLLV5QAE4LWA64WFEGUSJ3BOOLUFOC3XGOTVMMHORMYVF4YRKU3I62}"
RECIPIENT="${RECIPIENT:-GCAYP3MHTSCX22CPEQ467RLFNW3KQM67QS3BYVLUUOZ65FAQX7JYG2E3}"

echo "=== invest ==="
stellar contract invoke \
  --id "$CONTRACT_ID" \
  --source "$USER_KEY" \
  --network "$NETWORK" \
  -- \
  invest \
  --investor "$(stellar keys address "$USER_KEY")" \
  --payment_amount 5

echo "=== balance ==="
stellar contract invoke \
  --id "$CONTRACT_ID" \
  --source "$USER_KEY" \
  --network "$NETWORK" \
  -- \
  balance \
  --id "$(stellar keys address "$USER_KEY")"

echo "=== transfer RWA tokens ==="
stellar contract invoke \
  --id "$CONTRACT_ID" \
  --source "$USER_KEY" \
  --network "$NETWORK" \
  -- \
  transfer \
  --from "$(stellar keys address "$USER_KEY")" \
  --to "$RECIPIENT" \
  --amount 5

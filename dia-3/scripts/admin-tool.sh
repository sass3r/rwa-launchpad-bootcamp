#!/usr/bin/env bash
# Admin tool — invocations that require the issuer/admin key to sign.
# Replace placeholders before running on testnet.

set -euo pipefail

NETWORK="${NETWORK:-testnet}"
ADMIN_KEY="${ADMIN_KEY:-freighter}"
USER_KEY="${USER_KEY:-ramon}"
CONTRACT_ID="${CONTRACT_ID:-CDCLLV5QAE4LWA64WFEGUSJ3BOOLUFOC3XGOTVMMHORMYVF4YRKU3I62}"
PAYMENT_TOKEN="${PAYMENT_TOKEN:-CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA}"
INVESTOR="${INVESTOR:-GAGRCDSM2SJYOJHZIL3WV6MQUMLEPACZIVQ7BXO5T732GCU3TOU5QIRD}"
TREASURY="${TREASURY:-GAVEI4XYSBSLWXFWKVNHGN7H3P5M4GMVVHFHC43NVI7MHCIZPEZJYIHV}"

echo "=== initialize (run once after deploy) ==="
stellar contract invoke \
  --id "$CONTRACT_ID" \
  --source "$ADMIN_KEY" \
  --network "$NETWORK" \
  -- \
  initialize \
  --admin "$(stellar keys address "$ADMIN_KEY")" \
  --asset '{"name":"SXR","total_supply":"1000000","price_per_unit":"5","payment_token":"'"$PAYMENT_TOKEN"'","paused":false}'

echo "=== set_whitelist ==="
stellar contract invoke \
  --id "$CONTRACT_ID" \
  --source "$ADMIN_KEY" \
  --network "$NETWORK" \
  -- \
  set_whitelist \
  --admin "$(stellar keys address "$ADMIN_KEY")" \
  --investor "$INVESTOR" \
  --approved true

echo "=== mint (admin-only; optional if using invest) ==="
stellar contract invoke \
  --id "$CONTRACT_ID" \
  --source "$ADMIN_KEY" \
  --network "$NETWORK" \
  -- \
  mint \
  --admin "$(stellar keys address "$ADMIN_KEY")" \
  --to "$INVESTOR" \
  --amount 5

echo "=== invest ==="
stellar contract invoke \
  --id "$CONTRACT_ID" \
  --source "$USER_KEY" \
  --network "$NETWORK" \
  -- \
  invest \
  --investor "$(stellar keys address "$USER_KEY")" \
  --payment_amount 5

echo "=== withdraw collected payment tokens ==="
stellar contract invoke \
  --id "$CONTRACT_ID" \
  --source "$ADMIN_KEY" \
  --network "$NETWORK" \
  -- \
  withdraw \
  --admin "$(stellar keys address "$ADMIN_KEY")" \
  --to "$TREASURY" \
  --amount 5

echo "=== pause ==="
stellar contract invoke \
  --id "$CONTRACT_ID" \
  --source "$ADMIN_KEY" \
  --network "$NETWORK" \
  -- \
  pause \
  --admin "$(stellar keys address "$ADMIN_KEY")"

echo "=== unpause ==="
stellar contract invoke \
  --id "$CONTRACT_ID" \
  --source "$ADMIN_KEY" \
  --network "$NETWORK" \
  -- \
  unpause \
  --admin "$(stellar keys address "$ADMIN_KEY")"

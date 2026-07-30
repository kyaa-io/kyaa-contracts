#!/usr/bin/env bash
set -euo pipefail

manifest="${1:-deployments/giwa-sepolia.json}"
rpc_url="${GIWA_RPC_URL:-$(jq -r '.rpcUrl' "$manifest")}"

chain_id="$(cast chain-id --rpc-url "$rpc_url")"
expected_chain_id="$(jq -r '.chainId' "$manifest")"

if [[ "$chain_id" != "$expected_chain_id" ]]; then
  echo "Unexpected chain ID: ${chain_id}; expected ${expected_chain_id}" >&2
  exit 1
fi

verify_contract() {
  local contract_name="$1"
  local address
  local expected
  local code
  local actual

  address="$(jq -r ".contracts.${contract_name}.address" "$manifest")"
  expected="$(jq -r ".contracts.${contract_name}.runtimeBytecodeHash" "$manifest")"
  code="$(cast code "$address" --rpc-url "$rpc_url")"
  actual="$(cast keccak "$code")"

  if [[ "$code" == "0x" || "$actual" != "$expected" ]]; then
    echo "${contract_name}: live bytecode verification failed" >&2
    echo "address:  ${address}" >&2
    echo "expected: ${expected}" >&2
    echo "actual:   ${actual}" >&2
    return 1
  fi

  echo "${contract_name}: ${address} (${actual})"
}

echo "GIWA Sepolia chain ID: ${chain_id}"
verify_contract "ByUsPassport"
verify_contract "ByUsStamp"

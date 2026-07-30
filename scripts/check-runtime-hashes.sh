#!/usr/bin/env bash
set -euo pipefail

manifest="${1:-deployments/giwa-sepolia.json}"

check_hash() {
  local contract_name="$1"
  local expected
  local bytecode
  local actual

  expected="$(jq -r ".contracts.${contract_name}.runtimeBytecodeHash" "$manifest")"
  bytecode="$(forge inspect "$contract_name" deployedBytecode)"
  actual="$(cast keccak "$bytecode")"

  if [[ "$actual" != "$expected" ]]; then
    echo "${contract_name}: runtime bytecode hash mismatch" >&2
    echo "expected: ${expected}" >&2
    echo "actual:   ${actual}" >&2
    return 1
  fi

  echo "${contract_name}: ${actual}"
}

check_hash "ByUsPassport"
check_hash "ByUsStamp"

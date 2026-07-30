# Security Policy

The contracts in this repository secure non-transferable fan credentials. Please report potential vulnerabilities privately before any public disclosure.

## Supported version

Security fixes are applied to the current `main` branch.

## Report a vulnerability

Use the repository's [private vulnerability reporting form](https://github.com/ByUs-FanPassport/ByUs-Contracts/security/advisories/new).

Do not open a public issue for a suspected vulnerability. Include:

- the affected contract and function;
- reproduction steps or a minimal proof of concept;
- the expected and observed result;
- the potential impact;
- a suggested mitigation when available.

Never include a private key, mnemonic, populated environment file, or real fan data.

## Scope notes

- The current deployment is GIWA Sepolia testnet.
- The contracts are non-upgradeable and soulbound.
- No external smart-contract audit is claimed.
- Metadata privacy is enforced by the ByUs operational pipeline, not by validation inside the contract.

# wallet-e2e-testing

An AI-agent skill for running automated **end-to-end wallet tests** against the [tronwallet-adapter](https://github.com/tronweb3/tronwallet-adapter) dev-demo using Playwright — no real wallet extensions required.

## Overview

This skill provides a complete E2E testing framework that uses **mock wallet provider injection** to test wallet adapter interactions in a real browser. Tests cover the full lifecycle: discovery → connect → sign → switch chain → events → disconnect.

### What Gets Tested

| Operation | EVM (4 wallets) | TRON (TronLink) |
|-----------|:-:|:-:|
| Adapter displayed in selector | ✅ | ✅ |
| ReadyState detection | — | ✅ |
| Connect wallet | ✅ | ✅ |
| Sign message | ✅ | ✅ |
| Sign typed data (EIP-712) | ✅ | — |
| Send transaction / Transfer | ✅ | ✅ |
| Switch chain | ✅ | ✅ |
| `accountsChanged` event | ✅ | ✅ |
| `chainChanged` event | ✅ | ✅ |
| Disconnect | — | ✅ |

**41 tests total** — 32 EVM (4 wallets × 8 tests) + 9 TRON

### Tested Wallets

- **EVM**: MetaMask, OKX Wallet, TronLink (EVM), Trust Wallet
- **TRON**: TronLink

## Target Project

| | |
|---|---|
| **Repository** | [tronweb3/tronwallet-adapter](https://github.com/tronweb3/tronwallet-adapter) |
| **Test location** | `demos/dev-demo/e2e/` |
| **Tech stack** | TypeScript, Playwright, Vite, React |
| **Dev server** | `localhost:3003` |

## Prerequisites

- Node.js >= 18
- pnpm >= 7
- Chromium (auto-installed by Playwright)
- A cloned copy of the [tronwallet-adapter](https://github.com/tronweb3/tronwallet-adapter) monorepo with dependencies installed

## Usage

### With an AI Coding Agent

Copy this skill folder into your project:

```bash
# From the tronwallet-adapter repo root
cp -r /path/to/skills/tronwallet-adapter/wallet-e2e-testing .claude/skills/
# or
cp -r /path/to/skills/tronwallet-adapter/wallet-e2e-testing .github/skills/
```

Then ask the agent:

```
Run the wallet E2E tests
```
```
Add Phantom wallet to the E2E test suite
```
```
Run the TRON tests and analyze the report
```

The agent will automatically load the skill and follow the documented procedures.

### Manual Execution

```bash
cd demos/dev-demo

# Install Playwright + browser (first time only)
npx playwright install chromium

# Run all tests
pnpm test:e2e

# Run specific suites
pnpm test:e2e:evm
pnpm test:e2e:tron

# Run with visible browser (for debugging)
pnpm test:e2e:headed

# Generate analysis report
pnpm test:e2e:analyze
```

### Output

| File | Content |
|------|---------|
| `e2e-report/index.html` | Interactive HTML report (Playwright viewer) |
| `e2e-report/results.json` | Machine-readable JSON results |
| `e2e-report/ANALYSIS.md` | Auto-generated Markdown analysis with per-wallet/per-operation breakdown |

## How It Works

### Mock Provider Injection

Instead of requiring real browser extensions, tests inject **mock wallet providers** via `page.addInitScript()` before the page loads:

- **EVM wallets**: Mock implements [EIP-1193](https://eips.ethereum.org/EIPS/eip-1193) (provider API) + [EIP-6963](https://eips.ethereum.org/EIPS/eip-6963) (multi-provider discovery)
- **TRON wallets**: Mock implements [TIP-6963](https://github.com/nicetip/tips/blob/master/tip-6963.md) (TRON provider discovery) + `window.tronLink` / `window.tronWeb` legacy globals

### Provider Discovery Protocols

**EVM (EIP-6963)**:
```
Page loads → mock dispatches `eip6963:announceProvider`
           → adapter detects provider, sets readyState = Found
```

**TRON (TIP-6963)**:
```
Page loads → mock dispatches `TIP6963:announceProvider` with info.name = 'TronLink'
           → TronLink adapter's _checkWallet() detects provider
           → sets _supportNewTronProtocol = true, readyState = Found
```

### Event Simulation

Tests trigger wallet events via exposed helper functions:

```javascript
// EVM
window.__mockEvmProvider._setAccounts(['0xNewAddress']);
window.__mockEvmProvider._setChainId('0x1');

// TRON
window.__mockTronProvider._setAccounts('TNewAddr...', '41HexAddr...');
window.__mockTronProvider._setChainId('0x2b6653dc');
```

## Adding a New Wallet

### EVM (3 steps)

1. Add config to `e2e/fixtures.ts` → `EVM_WALLETS`
2. Add entry to `e2e/evm.spec.ts` → `walletsToTest` array
3. Run `pnpm test:e2e:evm`

See [references/add-new-wallet.md](references/add-new-wallet.md) for complete instructions.

### TRON

1. Create injection script following `buildTronInjectionScript()` pattern
2. Create new `*.spec.ts` modeled on `tron.spec.ts`
3. Add test match to `playwright.config.ts` → `projects`

## Skill Contents

```
wallet-e2e-testing/
├── README.md                          # This file
├── SKILL.md                          # Agent-facing skill definition
├── references/
│   ├── evm-mock-provider.md          # EVM mock implementation details
│   ├── tron-mock-provider.md         # TRON mock implementation details
│   └── add-new-wallet.md            # Step-by-step template for adding wallets
└── scripts/
    └── run-tests.sh                  # Shell script to run tests + analyze
```

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Serial execution (`workers: 1`) | Wallet state is shared per browser context; parallel causes state conflicts |
| `page.addInitScript()` injection | Runs before any page JavaScript; guarantees mock provider is ready before adapters initialize |
| No real wallet extensions | Deterministic results, CI-friendly, no extension installation needed |
| `userApproved` flag for EVM | Prevents adapters from auto-connecting via `eth_accounts` before the test clicks Connect |
| TIP-6963 for TRON | TronLink adapter on desktop checks this protocol first before falling back to legacy `window.tronLink` detection |

## License

MIT — see [LICENSE](../../LICENSE)

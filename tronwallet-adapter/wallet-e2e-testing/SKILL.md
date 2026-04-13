---
name: wallet-e2e-testing
description: "Run automated E2E wallet tests with Playwright. Use when: running wallet tests, adding new wallet adapter tests, testing wallet connect/sign/switch chain, generating test reports, analyzing test results. Covers EVM (EIP-6963) and TRON (TIP-6963) wallet adapters with mock provider injection."
argument-hint: 'Optional: wallet name or "all" to run full suite'
---

# Wallet E2E Testing Skill

Automated end-to-end testing framework for tronwallet-adapter wallet integrations using Playwright + mock provider injection. No real wallet extensions required.

## When to Use

- After adding/modifying a wallet adapter — run tests to verify
- After changing dev-demo UI — run full suite to catch regressions
- To test a specific wallet: `pnpm test:e2e:evm` or `pnpm test:e2e:tron`
- To generate and analyze test reports
- To add a new wallet adapter to the test suite

## Quick Start — Run All Tests

```bash
cd demos/dev-demo

# Run all 41 tests (32 EVM + 9 TRON)
pnpm test:e2e

# Generate analysis report
pnpm test:e2e:analyze
```

Results:
- HTML report: `e2e-report/index.html`
- JSON data: `e2e-report/results.json`
- Analysis: `e2e-report/ANALYSIS.md`

## Available Commands

| Command | What it does |
|---------|-------------|
| `pnpm test:e2e` | Run all tests (EVM + TRON) |
| `pnpm test:e2e:evm` | Run only EVM wallet tests |
| `pnpm test:e2e:tron` | Run only TRON wallet tests |
| `pnpm test:e2e:headed` | Run with visible browser |
| `pnpm test:e2e:report` | Open HTML report |
| `pnpm test:e2e:analyze` | Generate ANALYSIS.md from results |

## Architecture

```
demos/dev-demo/
├── playwright.config.ts       # Playwright config (port 3003, serial)
├── e2e/
│   ├── fixtures.ts            # Mock providers + test fixtures
│   ├── evm.spec.ts            # 4 wallets × 8 tests = 32 EVM tests
│   ├── tron.spec.ts           # 1 wallet × 9 tests = 9 TRON tests
│   ├── analyze-report.mjs     # Report analyzer script
│   └── mocks/
│       ├── evm-provider.ts    # EVM mock reference
│       └── tron-provider.ts   # TRON mock reference
└── e2e-report/                # Generated reports
```

### Mock Provider Injection

Tests inject mock wallet providers via `page.addInitScript()` before page load:

- **EVM**: EIP-1193 `request()` + EIP-6963 `announceProvider` event
- **TRON**: TIP-6963 `TIP6963:announceProvider` event + `window.tronLink` / `window.tronWeb` legacy globals

Mock providers expose test control helpers on `window`:
- `window.__mockEvmProvider._setAccounts([addr])` — trigger accountsChanged
- `window.__mockEvmProvider._setChainId('0x1')` — trigger chainChanged
- `window.__mockTronProvider._setAccounts(addr, hex)` — trigger accountsChanged
- `window.__mockTronProvider._setChainId(chainId)` — trigger chainChanged

### Test Coverage Matrix

| Operation | EVM (×4 wallets) | TRON |
|-----------|:-:|:-:|
| Display in selector | ✅ | ✅ |
| ReadyState = Found | — | ✅ |
| Connect | ✅ | ✅ |
| Sign message | ✅ | ✅ |
| Sign typed data (EIP-712) | ✅ | — |
| Send transaction / Transfer | ✅ | ✅ |
| Switch chain | ✅ | ✅ |
| accountsChanged event | ✅ | ✅ |
| chainChanged event | ✅ | ✅ |
| Disconnect | — | ✅ |

## Procedure: Add a New EVM Wallet

1. **Add wallet config** in `e2e/fixtures.ts` → `EVM_WALLETS`:

```typescript
NewWallet: {
  walletName: 'New Wallet',        // EIP-6963 info.name
  rdns: 'com.newwallet',           // EIP-6963 info.rdns
  icon: 'data:image/svg+xml,...',  // icon data URL
  selectLabel: 'New Wallet',       // adapter dropdown label
},
```

2. **Add to test loop** in `e2e/evm.spec.ts` → `walletsToTest`:

```typescript
['New Wallet', EVM_WALLETS.NewWallet],
```

3. **Run tests**:

```bash
pnpm test:e2e:evm
```

All 8 tests (display, connect, sign, typed data, transfer, switch chain, accounts event, chain event) run automatically.

## Procedure: Add a New TRON Wallet

For TRON wallets that use TIP-6963 (like TronLink), the same `tron.spec.ts` works. For wallets with different detection:

1. Create a new injection script in `fixtures.ts` following `buildTronInjectionScript()` pattern
2. Create a new `*.spec.ts` file modeled on `tron.spec.ts`
3. Add the test match to `playwright.config.ts` → `projects`

## Troubleshooting

### Dev server won't start
```bash
# Kill existing process on port 3003
lsof -ti:3003 | xargs kill -9 2>/dev/null
# Start manually
cd demos/dev-demo && npx vite --force --port 3003
```

### readyState stuck at "Loading"
The adapter uses event-based discovery (EIP-6963 for EVM, TIP-6963 for TRON). The mock must respond to `requestProvider` events. Check:
- EVM: mock dispatches `eip6963:announceProvider` on `eip6963:requestProvider`
- TRON: mock dispatches `TIP6963:announceProvider` on `TIP6963:requestProvider` with `info.name === 'TronLink'`

### "strict mode violation" in locator
A `text=...` locator matched multiple elements. Fix:
- Use `getByText('value', { exact: true })` for exact match
- Use `getByRole('button', { name: '...' })` for buttons
- Use `.first()` or `.nth(n)` for intentional first-match

### Auto-connect prevents testing
EVM mock returns accounts from `eth_accounts` too early. Fix: use `userApproved` flag — return `[]` from `eth_accounts` until `eth_requestAccounts` is called.

## Key Design Decisions

| Decision | Why |
|----------|-----|
| Serial mode (`workers: 1`) | Wallet state is shared per page; parallel causes conflicts |
| `page.addInitScript()` | Runs before any page JS; guarantees provider is ready |
| No real extensions | Deterministic, CI-friendly, no extension install needed |
| `reuseExistingServer: true` | Allows running tests against already-running dev server |
| TIP-6963 for TRON | TronLink adapter on desktop uses this protocol first, legacy as fallback |
| `userApproved` flag | Prevents EVM adapters from auto-connecting via `eth_accounts` |

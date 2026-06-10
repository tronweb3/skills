# Requirements Template — TRON Wallet Adapter

Use this template to create `requires/<version>/require.md`.

---

```markdown
# <version> Requirements: {{WALLET_NAME}} TRON Adapter

## 1. Background

TronWallet Adapter is an open-source multi-chain wallet integration project. Its TRON (native chain) adapter family already supports TronLink, Bybit Wallet, OKX Wallet, TokenPocket, Backpack, and others. All TRON adapters live flat under `packages/adapters/<dir>/` (NOT under `packages/adapters/evm/`). To expand TRON ecosystem coverage, a new {{WALLET_NAME}} TRON adapter is needed.

## 2. Requirements Overview

### 2.1 Core Requirements
Add the `{{NPM_PACKAGE}}` package in <version>, ensuring:
- The adapter extends the `Adapter` base class from `@tronweb3/tronwallet-abstract-adapter`
- Consistency with the existing TRON adapter family (Bybit / Backpack patterns)
- Support for desktop browser extensions (and mobile DeepLink for Archetype A wallets)

### 2.2 Archetype Declaration (REQUIRED)

- **Archetype**: <A — TronLink-compatible | B — provider request-based>
- **Injection evidence**: <e.g. Archetype A: `window.{{WALLET_INJECTION_KEY}}.tronLink` with `.tronWeb`, `.ready`, `.request({ method: 'tron_requestAccounts' })` | Archetype B: provider at `{{WALLET_PROVIDER_PATH}}` with `request({ method: 'tron_*' })` and `on('accountsChanged')`, identity flag `{{WALLET_IS_FIELD}}`>

See `references/archetype-decision.md` for how to determine this. All later requirements branch on it.

### 2.3 Feature Support Matrix

Fill in based on what the wallet actually supports (Yes / No / Throws):

| Feature | Support | Implementation |
|---------|---------|----------------|
| connect | Yes | A: `wallet.request({ method: 'tron_requestAccounts' })` / B: `tron_requestAccounts` on provider |
| disconnect | Yes | Local state reset (+ B: `provider.disconnect()` if available) |
| signMessage | <Yes/No> | A: `tronWeb.trx.signMessageV2` / B: `tron_signMessage` |
| signTransaction | <Yes/No> | A: `tronWeb.trx.sign` / B: `tron_signTransaction` |
| multiSign | <Yes/Throws> | A default: Yes via `tronWeb.trx.multiSign` / B default: Throws `WalletSignTransactionError` |
| switchChain | <Yes/No/Throws> | A default: not implemented / B default: Yes via `tron_switchChain` |
| network | <Yes/No> | A: `getNetworkInfoByTronWeb(wallet.tronWeb)` / B: `tron_chainId` + chainId map |
| signTypedData | <Yes/No> | Not part of the TRON `Adapter` base class — usually No |

### 2.4 Integration Support
- ✅ **Unified Export**: Re-exported via `@tronweb3/tronwallet-adapters`
- ✅ **TypeScript**: Full type definitions
- ✅ **ESM + CJS**: Dual-format output

## 3. Technical Requirements

### 3.1 Code Standards
- Extend the `Adapter` base class (from `@tronweb3/tronwallet-abstract-adapter`)
- Follow the Bybit (Archetype A) or Backpack (Archetype B) implementation patterns
- **Zero-arg constructor REQUIRED**: `new {{WALLET_CLASS}}Adapter()` must work with no arguments — the demo apps auto-instantiate every export whose name ends with `Adapter` via `new (value)()`. All config options must have defaults.

### 3.2 Compatibility Requirements
- **Browsers**: Chrome, Firefox, Safari, Edge (latest two versions)
- **Node.js**: >= 16
- **Networks**: TRON Mainnet, Shasta, Nile

### 3.3 Dependencies
- Archetype A: `@tronweb3/tronwallet-abstract-adapter: workspace:^` AND `@tronweb3/tronwallet-adapter-tronlink: workspace:^`
- Archetype B: `@tronweb3/tronwallet-abstract-adapter: workspace:^` only
- No other runtime dependencies

## 4. Testing Requirements

### 4.1 Test Setup
- `vitest` with `happy-dom` environment and fake timers (`vi.useFakeTimers()`)

### 4.2 Unit Tests — Archetype A
- [ ] Base property validation (name = `{{WALLET_NAME}}`, url, icon, readyState)
- [ ] Wallet detection: `window.{{WALLET_INJECTION_KEY}}.tronLink` found / not found (checkTimeout polling)
- [ ] connect success via `tron_requestAccounts`; rejection codes 4000/4001 → `WalletConnectionError`
- [ ] `WalletNotFoundError` + `window.open(url)` when wallet not found
- [ ] signMessage / signTransaction / multiSign delegate to `tronWeb.trx.*`
- [ ] `window` message events: `connect` / `disconnect` / `accountsChanged` (200ms deferred) update state and re-emit

### 4.3 Unit Tests — Archetype B
- [ ] Base property validation (name = `{{WALLET_NAME}}`, url, icon, readyState)
- [ ] Provider detection at `{{WALLET_PROVIDER_PATH}}` (and `{{WALLET_IS_FIELD}}` fallback), checkTimeout polling
- [ ] Existing-connection restore via `tron_accounts`
- [ ] connect success via `tron_requestAccounts`; code 4001 → `WalletConnectionError`
- [ ] `WalletNotFoundError` + `window.open(url)` when wallet not found
- [ ] signMessage / signTransaction via `tron_signMessage` / `tron_signTransaction`; multiSign throws
- [ ] switchChain via `tron_switchChain`; network() via `tron_chainId` + chainId map
- [ ] Provider `accountsChanged` / `chainChanged` events update state and re-emit

## 5. Acceptance Criteria

### 5.1 Functional Acceptance
- [ ] All features in the support matrix implemented and tested
- [ ] Desktop extension works; mobile DeepLink works (Archetype A only)

### 5.2 Quality Acceptance
- [ ] Unit test coverage >= 80%
- [ ] TypeScript types complete, no `any` (except where existing adapters use it for error handling)
- [ ] Code style conforms to project standards

### 5.3 Documentation Acceptance
- [ ] README includes API docs and usage examples

### 5.4 Integration Acceptance
- [ ] Registered in all 5 monorepo places: `packages/adapters/adapters/package.json` (dependency), `packages/adapters/adapters/src/index.ts` (re-export), `packages/adapters/adapters/tests/adapters.test.ts` (assertion), `packages/adapters/adapters/tsconfig.all.json` (reference), root `tsconfig.all.json` (reference)
- [ ] Auto-discovered by the demo apps (zero-arg instantiation works, adapter appears in the demo wallet list)
- [ ] No conflicts with other adapters
- [ ] Build passes completely (ESM + CJS + types + UMD)
```

## Key Points

- The **archetype declaration (section 2.2) is mandatory** — it drives dependencies, tsconfig references, vitest config, and which code/test templates apply in later phases.
- The **zero-arg constructor requirement is non-negotiable**: demos instantiate adapters with `new (value)()` after filtering exports ending in `Adapter` (see `demos/dev-demo/src/components/WalletProvider.tsx`), so a constructor that requires arguments breaks every demo.
- TRON adapters live flat at `packages/adapters/<dir>/` — never under `packages/adapters/evm/`.
- `signTypedData` is listed only for completeness; the TRON `Adapter` base class does not define it, so it is normally "No".

## Variable Mapping

| Placeholder | Meaning | Example (Bybit, A) | Example (Backpack, B) |
|-------------|---------|--------------------|------------------------|
| `{{WALLET_NAME}}` | Display name / AdapterName string | `Bybit Wallet` | `Backpack` |
| `{{WALLET_CLASS}}` | PascalCase class prefix | `BybitWallet` | `Backpack` |
| `{{NPM_PACKAGE}}` | npm package name (no `-evm` suffix) | `@tronweb3/tronwallet-adapter-bybit` | `@tronweb3/tronwallet-adapter-backpack` |
| `{{WALLET_INJECTION_KEY}}` | Key on `window` | `bybitWallet` | `backpack` |
| `{{WALLET_PROVIDER_PATH}}` | B only — full provider path | — | `window.backpack.tron` |
| `{{WALLET_IS_FIELD}}` | B only — identity flag | — | `isBackpack` |

# Plan Template — TRON Wallet Adapter

Use this template to create `requires/<version>/plan.md`.

---

```markdown
# <version> Development Plan: Add {{WALLET_NAME}} TRON Adapter

## 1. Overview

Add the `{{NPM_PACKAGE}}` package at `packages/adapters/{{WALLET_DIR}}/`.
Extend the `Adapter` base class from `@tronweb3/tronwallet-abstract-adapter`, following the reference implementation for the declared archetype.

### Reference Implementations
- `packages/adapters/bybit/` — **Archetype A** (TronLink-compatible: `window.bybitWallet.tronLink`, signs via `tronWeb.trx.*`, window `message` events, mobile deeplink)
- `packages/adapters/backpack/` — **Archetype B** (provider request-based: `window.backpack.tron`, generic `request({ method: 'tron_*' })`, provider events, switchChain/network)

## 2. {{WALLET_NAME}} Characteristics

| Property | Value |
|----------|-------|
| name | `'{{WALLET_NAME}}'` |
| url | `{{WALLET_URL}}` |
| Injection key | `window.{{WALLET_INJECTION_KEY}}` |
| Archetype | <A or B> |
| (A only) DeepLink | `{{WALLET_DEEPLINK}}` |
| (A only) In-app UA marker | `{{WALLET_APP_UA_MARKER}}` |
| (B only) Provider path | `{{WALLET_PROVIDER_PATH}}` |
| (B only) Identity flag | `provider.{{WALLET_IS_FIELD}}` |

### Feature Matrix

| Feature | Support |
|---------|---------|
| connect / disconnect | Yes |
| signMessage | <Yes/No> |
| signTransaction | <Yes/No> |
| multiSign | <Yes (A default) / Throws (B default)> |
| switchChain | <Not implemented (A default) / Yes (B default)> |
| network | Yes |

## 3. File Manifest

packages/adapters/{{WALLET_DIR}}/
├── package.json
├── tsconfig.all.json
├── tsconfig.cjs.json
├── tsconfig.esm.json
├── vitest.config.ts
├── LICENSE
├── README.md
├── src/
│   ├── adapter.ts
│   ├── utils.ts
│   └── index.ts
└── tests/
    └── units/
        ├── adapter.test.ts
        ├── mock.ts
        └── utils.ts

> NOTE: There is **no `src/metadata.ts`** — this differs from the EVM adapters. TRON adapters keep name/url/icon directly in `adapter.ts`.

## 4. Development Tasks

### Task 1: Create package structure and config files
- `package.json` — name: `{{NPM_PACKAGE}}`; dependencies: `@tronweb3/tronwallet-abstract-adapter: workspace:^` (+ `@tronweb3/tronwallet-adapter-tronlink: workspace:^` for Archetype A only)
- `tsconfig.all.json` — references `../abstract-adapter/tsconfig.all.json` (+ `../tronlink/tsconfig.all.json` for Archetype A only), `./tsconfig.cjs.json`, `./tsconfig.esm.json`
- `tsconfig.cjs.json` / `tsconfig.esm.json` — same as the reference adapter
- `vitest.config.ts` — happy-dom environment; Archetype A only: `ssr.noExternal: ['@tronweb3/tronwallet-abstract-adapter', '@tronweb3/tronwallet-adapter-tronlink']`
- `LICENSE` / `README.md`

### Task 2: Implement `src/utils.ts`
- `support{{WALLET_CLASS}}()` — detect the injected wallet
- Archetype A: `isIn{{WALLET_CLASS}}App()` via `{{WALLET_APP_UA_MARKER}}` userAgent regex; `open{{WALLET_CLASS}}()` — mobile deeplink redirect via `{{WALLET_DEEPLINK}}`
- Archetype B: provider interface type; `get{{WALLET_CLASS}}Provider()` — return provider at `{{WALLET_PROVIDER_PATH}}` with `{{WALLET_IS_FIELD}}` fallback

### Task 3: Implement `src/adapter.ts`
- `{{WALLET_CLASS}}Adapter extends Adapter`; `{{WALLET_CLASS}}AdapterName = '{{WALLET_NAME}}'`; url = `{{WALLET_URL}}`; icon = `{{WALLET_ICON}}`
- Zero-arg constructor with config defaults (`checkTimeout`, `openUrlWhenWalletNotFound`, …); `_checkWallet()` interval polling
- Archetype A: connect via `wallet.request({ method: 'tron_requestAccounts' })` (handle codes 4000/4001); sign via `tronWeb.trx.sign` / `signMessageV2` / `multiSign`; `network()` via `getNetworkInfoByTronWeb`; window `message` listener for `connect` / `disconnect` / `accountsChanged` (200ms defer); deeplink check before connect
- Archetype B: connect via `tron_requestAccounts`; restore via `tron_accounts`; sign via `tron_signMessage` / `tron_signTransaction`; `multiSign()` throws; `switchChain()` via `tron_switchChain`; `network()` via `tron_chainId` + chainId map (Mainnet `0x2b6653dc`, Shasta `0x94a9059e`, Nile `0xcd8690dc`); provider `accountsChanged` / `chainChanged` listeners

### Task 4: Implement `src/index.ts`
- `export * from './adapter.js';`
- `export * from './utils.js';`

### Task 5: Implement tests
- `tests/units/mock.ts` — mock wallet: Archetype A: TronLink-shaped wallet (`tronWeb`, `ready`, `request`) installed at `window.{{WALLET_INJECTION_KEY}}.tronLink`; Archetype B: mock provider class with `request` / `on` / `removeListener` installed at `{{WALLET_PROVIDER_PATH}}`
- `tests/units/utils.ts` — fake-timer `wait()` helper and shared constants
- `tests/units/adapter.test.ts` — vitest + happy-dom + `vi.useFakeTimers()`; cover the archetype's case list from the requirements document (detection, connect, errors, signing, events; B also switchChain/network)

### Task 6: Register in project (5 places)
- `packages/adapters/adapters/package.json` — add `{{NPM_PACKAGE}}: workspace:^` dependency
- `packages/adapters/adapters/src/index.ts` — add `export * from '{{NPM_PACKAGE}}';`
- `packages/adapters/adapters/tests/adapters.test.ts` — add `expect(Adapters.{{WALLET_CLASS}}Adapter).not.toBeUndefined();`
- `packages/adapters/adapters/tsconfig.all.json` — add `../{{WALLET_DIR}}/tsconfig.all.json` reference
- root `tsconfig.all.json` — add `./packages/adapters/{{WALLET_DIR}}/tsconfig.all.json` reference

## 5. Out of Scope

- ❌ Do not modify `@tronweb3/tronwallet-abstract-adapter`
- ❌ Do not modify the `tronlink` package (Archetype A only consumes its exports)
- ❌ Do not modify other existing adapters
- ❌ Do not modify version numbers (managed by changeset)
```

## Key Points

- The plan must carry over the **archetype** from the requirements document — Tasks 1–5 each have A/B variants and must not be mixed.
- The file manifest deliberately has **no `metadata.ts`** (unlike EVM adapters) and **no EIP-6963 / rdns concepts** — TRON adapters are detected purely via the injected `window` object.
- Registration is **5 places**, not 3 (the EVM plan omits the adapters-package tsconfig and test assertion); missing any one breaks the monorepo build or the `@tronweb3/tronwallet-adapters` aggregate test.
- The zero-arg constructor in Task 3 is what makes demo auto-discovery (Task 6's re-export) work without demo code changes.

## Variable Mapping

| Placeholder | Meaning | Example (Bybit, A) | Example (Backpack, B) |
|-------------|---------|--------------------|------------------------|
| `{{WALLET_NAME}}` | Display name / AdapterName string | `Bybit Wallet` | `Backpack` |
| `{{WALLET_CLASS}}` | PascalCase class prefix | `BybitWallet` | `Backpack` |
| `{{WALLET_DIR}}` | Directory under `packages/adapters/` | `bybit` | `backpack` |
| `{{NPM_PACKAGE}}` | npm package name (no `-evm` suffix) | `@tronweb3/tronwallet-adapter-bybit` | `@tronweb3/tronwallet-adapter-backpack` |
| `{{WALLET_URL}}` | Official wallet URL | `https://bybit.com/web3` | `https://backpack.app` |
| `{{WALLET_ICON}}` | base64 data-URI icon | `data:image/svg+xml;base64,...` | `data:image/svg+xml;base64,...` |
| `{{WALLET_INJECTION_KEY}}` | Key on `window` | `bybitWallet` | `backpack` |
| `{{WALLET_DEEPLINK}}` | A only — mobile deeplink URL/prefix | `https://app.bybit.com/inapp?by_dp=...` | — |
| `{{WALLET_APP_UA_MARKER}}` | A only — in-app userAgent regex marker | `bybit_app` | — |
| `{{WALLET_PROVIDER_PATH}}` | B only — full provider path | — | `window.backpack.tron` |
| `{{WALLET_IS_FIELD}}` | B only — identity flag | — | `isBackpack` |

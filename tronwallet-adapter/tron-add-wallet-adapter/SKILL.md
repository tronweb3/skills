---
name: tron-add-wallet-adapter
description: 'Add a new native TRON wallet adapter end-to-end. Use when: user asks to add/create a new TRON wallet adapter (e.g. Bitget Wallet, OKX Wallet, FoxWallet, GateWallet, Backpack, etc.) — as opposed to an EVM wallet adapter. Covers the full workflow: requirements doc, plan, implementation, tests, docs, registration, and demo integration.'
---

# TRON Wallet Adapter — Full Workflow

## Overview

This skill automates the entire process of adding a new native TRON wallet adapter to the tronwallet-adapter monorepo. It follows a proven 7-phase workflow. It is the TRON counterpart to the `evm-add-wallet-adapter` skill — use that one instead if the wallet only needs to be reached over EVM/EIP-1193.

## When to Use

- User says "add XXX TRON adapter" or "create a new TRON wallet adapter for XXX"
- User wants to integrate a new TRON-compatible browser extension or wallet app
- User mentions a wallet name and wants native TRON support added (not EVM)

## How TRON Adapters Differ From EVM Adapters

- No EIP-6963 / provider-discovery protocol. Wallets inject a global object directly onto `window` (e.g. `window.okxwallet.tronLink`, `window.bitkeep.tronLink`), and the adapter polls for it.
- No separate `metadata.ts` file — `name`, `url`, `icon` are declared directly as class fields on the adapter (matches every existing TRON adapter in this repo).
- Adapters extend `AddonAdapter` (from `@tronweb3/tronwallet-abstract-adapter`), not a plain `Adapter` — it provides `commonConfig`, `checkSecurity()`, `_beforeConnect()`, and connect-call serialization for free.
- Injected wallets almost always wrap a **TronLink-compatible object**: `{ tronWeb, request(), ready, on(), tronLink }`. Reuse types from `@tronweb3/tronwallet-adapter-tronlink` (`TronLinkWallet`, `Tron`, `getNetworkInfoByTronWeb`) instead of redefining them.
- Demo integration is much lighter: `dev-demo`, `react-ui`, and `vue-ui` all auto-discover every exported `*Adapter` from the `@tronweb3/tronwallet-adapters` barrel via reflection — **no per-wallet code change needed there** unless the constructor requires mandatory config (see Phase 7). Only `cdn-demo` needs manual wiring.

## Workflow Phases

### Phase 0: Research the Wallet's Injected Provider

Before writing any code, determine how the wallet actually injects itself (open the wallet extension/app with devtools, or check its official integration docs):

- Injected global path (e.g. `window.okxwallet.tronLink`, `window.bitkeep.tronLink`, `window.$onekey.tron`)
- Does it wrap a full TronLink-compatible object (`tronWeb` + `request()` + `ready`) or something bespoke?
- Does it post `window.postMessage` events for `connect` / `accountsChanged` / `disconnect`, or must the adapter poll?
- Desktop extension vs. mobile in-app browser — do they inject differently (see SafePal, which uses two different globals per platform)?
- Mobile deeplink URL scheme, if the wallet has an app

See [detection-patterns.md](./references/detection-patterns.md) for a survey of every existing pattern in this repo and which reference adapter to copy from.

### Phase 1: Requirements Document (`require.md`)

Create `requires/<version>/require.md` following the [requirements template](./references/require-template.md).

### Phase 2: Development Plan (`plan.md`)

Create `requires/<version>/plan.md` following the [plan template](./references/plan-template.md).

Key contents:
- Wallet characteristics table (name, injection path, detection expression, deeplink)
- Complete file manifest
- Development task breakdown
- Explicit "not doing" list

### Phase 3: Implementation

Create the adapter package at `packages/adapters/<wallet-name>/` following these code templates:

| File | Template |
|------|----------|
| `package.json` | [package.json template](./references/code-package-json.md) |
| `src/adapter.ts` | [adapter template](./references/code-adapter.md) |
| `src/utils.ts` | [utils template](./references/code-utils.md) |
| `src/index.ts` | `export * from './adapter.js'; export * from './utils.js';` |
| `tsconfig.*.json` | [tsconfig templates](./references/code-tsconfig.md) |
| `vitest.config.ts` | [vitest config template](./references/code-vitest.md) |
| `LICENSE` | MIT License (copy from any sibling adapter package) |

Variable substitution table — replace these placeholders in ALL templates:

| Placeholder | Example (OKX Wallet) | Description |
|-------------|---------------------|-------------|
| `{{WALLET_NAME}}` | `OKX Wallet` | Display name, value of `adapter.name` |
| `{{WALLET_CLASS}}` | `OkxWallet` | PascalCase adapter class prefix (`{{WALLET_CLASS}}Adapter`) |
| `{{WALLET_DIR}}` | `okxwallet` | Package directory name under `packages/adapters/` |
| `{{WALLET_URL}}` | `https://okx.com` | Official wallet URL, used as `adapter.url` |
| `{{WALLET_ICON}}` | `data:image/svg+xml;base64,...` | Base64-encoded icon, used as `adapter.icon` |
| `{{WALLET_INJECTION_KEY}}` | `okxwallet` | Property on `window` the wallet injects (no `window.` prefix) |
| `{{WALLET_DEEPLINK}}` | `okx://wallet/dapp/url?dappUrl=` | Mobile deeplink URL prefix |
| `{{NPM_PACKAGE}}` | `@tronweb3/tronwallet-adapter-okxwallet` | Full npm package name |

Not every wallet needs every placeholder (e.g. extension-only wallets like Guarda have no deeplink) — omit what doesn't apply rather than inventing values.

### Phase 4: Tests

Create `packages/adapters/<wallet-name>/tests/units/adapter.test.ts` following the [test template](./references/code-tests.md).

Required test cases:
1. Base properties (name, url, readyState, address, connecting, connected, event methods)
2. `connect()` succeeds and sets address/state when the wallet reports one
3. `connect()` rejects with `WalletConnectionError` (not silently "connects" with an empty address) when `defaultAddress`/`base58` is missing, empty, or falsy
4. `connect()` throws `WalletNotFoundError` when the wallet isn't detected and opens the wallet's URL / deeplink as configured
5. `signMessage()` / `signTransaction()` delegate to the wallet's `tronWeb` and wrap thrown errors in `WalletSignMessageError` / `WalletSignTransactionError`
6. If the adapter listens for wallet-pushed events (`message` events, interval polling), test `accountsChanged` and `disconnect` propagate correctly — and that events firing after `disconnect()` don't resurrect state (see the okxwallet/bitkeep regression tests for the pattern if the wallet emits async events)

No mock-provider file is needed (unlike EVM/EIP-6963 adapters) — TRON adapter tests stub `window.<injection>` directly, or replace `(adapter as any)._wallet` for connected-state tests.

### Phase 5: Registration

Register the new adapter in 3 places:

1. **`packages/adapters/adapters/src/index.ts`** — Add re-export line:
   ```typescript
   export * from '{{NPM_PACKAGE}}';
   ```

2. **`packages/adapters/adapters/package.json`** — Add dependency (keep the list alphabetically sorted):
   ```json
   "{{NPM_PACKAGE}}": "workspace:^"
   ```

3. **`tsconfig.all.json`** (root) — Add reference:
   ```json
   { "path": "./packages/adapters/{{WALLET_DIR}}/tsconfig.all.json" }
   ```

### Phase 6: Documentation

Create `packages/adapters/<wallet-name>/README.md` following the [docs template](./references/docs-readme.md).

Must include:
- Quick demo code snippet (connect → read address → build & sign a transaction via `tronWeb`)
- Constructor API (`{{WALLET_CLASS}}AdapterConfig` — usually just `BaseAdapterConfig`: `checkTimeout`, `openUrlWhenWalletNotFound`, `openAppWithDeeplink`, `securityOptions`)
- `network()` method docs if implemented
- Caveats section (unsupported methods like `multiSign`/`switchChain`, event support differences between extension and app, deeplink version requirements)

### Phase 7: Demo Integration

See [demo integration guide](./references/demo-integration.md). Summary:

| Demo | What to update |
|------|---------------|
| `demos/cdn-demo/tron/` | `index.html` (UMD script tag), `App.js` (destructure + add to `options` array), `package.json` (dep) |
| `demos/dev-demo/` | **Usually nothing** — auto-discovered via `Object.entries(Adapters)` reflection in `WalletProvider.tsx`. Only add manual wiring if the constructor requires mandatory args (like `BinanceWalletAdapter`/`WalletConnectAdapter`) |
| `demos/react-ui/vite-app/` | **Usually nothing** — same reflection pattern in `App.tsx` |
| `demos/vue-ui/vite-app/` | **Usually nothing** — same reflection pattern in `App.vue` |

If the new adapter's constructor requires no mandatory arguments (the common case — everything lives in optional `BaseAdapterConfig`), the only demo requiring a code change is `cdn-demo`.

## Build & Verify

After all phases:

```bash
# Install dependencies
pnpm install

# Build the new adapter + UMD
cd packages/adapters/<wallet-name>
pnpm run build
pnpm run build:umd

# Run tests
pnpm run test

# Build entire project
cd /path/to/tronwallet-adapter
pnpm run build

# Start dev-demo to verify
cd demos/dev-demo
pnpm run dev
```

## Checklist

- [ ] Phase 0 research done — injection path, detection expression, event/polling model, deeplink confirmed
- [ ] `requires/<version>/require.md` created
- [ ] `requires/<version>/plan.md` created
- [ ] `packages/adapters/<wallet-name>/` package created with all source files
- [ ] Tests pass (`vitest run`)
- [ ] Registered in adapters index, adapters package.json, root tsconfig.all.json
- [ ] README.md with API docs and demo snippet
- [ ] cdn-demo updated; dev-demo/react-ui/vue-ui updated only if the constructor needs mandatory config
- [ ] `pnpm build` succeeds (ESM + CJS + types + UMD)
- [ ] Dev server starts without errors and the new wallet appears in the wallet selector

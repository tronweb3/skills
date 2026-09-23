# Plan Template — TRON Wallet Adapter

Use this template to create `requires/<version>/plan.md`.

---

```markdown
# <version> Development Plan: Add {{WALLET_NAME}} TRON Adapter

## 1. Overview

Add the `{{NPM_PACKAGE}}` package at `packages/adapters/{{WALLET_DIR}}/`.
Follow the [detection-patterns.md](./detection-patterns.md) decision guide to pick the closest
reference adapter, extending the `AddonAdapter` base class.

### Reference Implementation
- `packages/adapters/<closest-match>/` — chosen per Phase 0 research (e.g. `okxwallet` for a
  TronLink-compatible provider with push events, `bitkeep` for polling-only, `safepal` for
  platform-branched injection, `backpack` for a bespoke non-TronLink provider)

## 2. {{WALLET_NAME}} Characteristics

| Property | Value |
|----------|-------|
| name | `'{{WALLET_NAME}}'` |
| url | `{{WALLET_URL}}` |
| Injected Object | `window.{{WALLET_INJECTION_KEY}}` |
| Detection Expression | *(from Phase 0 research)* |
| Provider Shape | TronLink-compatible \| bespoke *(pick one)* |
| Push Events | message events \| polling only \| none *(pick one)* |
| Mobile WebView | *(how to detect, if applicable)* |
| DeepLink | `{{WALLET_DEEPLINK}}...` *(if the wallet has a mobile app)* |

## 3. File Manifest

```
packages/adapters/{{WALLET_DIR}}/
├── package.json
├── tsconfig.all.json
├── tsconfig.cjs.json
├── tsconfig.esm.json
├── vitest.config.ts
├── README.md
├── LICENSE
├── src/
│   ├── index.ts
│   ├── adapter.ts
│   └── utils.ts
└── tests/
    └── units/
        └── adapter.test.ts
```

## 4. Development Tasks

### Task 1: Create package structure and config files
- `package.json` — name: `{{NPM_PACKAGE}}`, dependencies: `@tronweb3/tronwallet-abstract-adapter: workspace:^` (+ `@tronweb3/tronwallet-adapter-tronlink: workspace:^` if TronLink-compatible)
- `tsconfig.all.json` / `tsconfig.cjs.json` / `tsconfig.esm.json` — same as the reference adapter
- `vitest.config.ts` — happy-dom environment
- `README.md` / `LICENSE`

### Task 2: Implement `src/utils.ts`
- `support{{WALLET_CLASS}}()` — detect `window.{{WALLET_INJECTION_KEY}}` per the chosen detection expression
- `open{{WALLET_CLASS}}()` — mobile deeplink redirect, gated on `isInMobileBrowser() && !support{{WALLET_CLASS}}()` (omit if no mobile app)
- Any UA-sniffing helper (`isIn{{WALLET_CLASS}}App()`) if the wallet's in-app browser needs to be distinguished from a generic mobile browser

### Task 3: Implement `src/adapter.ts`
- `{{WALLET_CLASS}}Adapter extends AddonAdapter`
- Class fields: `name`, `url`, `icon`, plus private `_readyState`/`_state`/`_connecting`/`_wallet`/`_address` with public getters
- Constructor: check `isInBrowser()`, then either fast-path with `support{{WALLET_CLASS}}()` or start `_checkWallet()` polling
- `_checkWallet()` — interval-based detection matching the `okxwallet`/`bitkeep` pattern (never cache a negative result)
- `_connect()` — call the wallet's request method, validate the returned address with `assertConnectAddress()`, set state
- `_openAppByDeepLinkIfNeed()` — return `open{{WALLET_CLASS}}()` result (omit / return `false` if no mobile app)
- `signMessage()` / `signTransaction()` / `multiSign()` (if supported) — delegate to `wallet.tronWeb.trx.*`, wrap errors
- `network()` — delegate to `getNetworkInfoByTronWeb()` if the wallet exposes `tronWeb`
- Event listening (if the wallet pushes events) — `window.addEventListener('message', ...)` filtered by `e.origin`, matching the okxwallet generation-counter pattern so late events can't resurrect state after `disconnect()`

### Task 4: Implement `src/index.ts`
- `export * from './adapter.js'; export * from './utils.js';`

### Task 5: Implement tests
- `tests/units/adapter.test.ts` — base properties, connect success/failure, address-validation regression cases, sign delegation, event propagation if applicable

### Task 6: Register in project
- `packages/adapters/adapters/package.json` — add dependency
- `packages/adapters/adapters/src/index.ts` — add re-export
- `tsconfig.all.json` (root) — add reference

### Task 7: Demo integration
- `demos/cdn-demo/tron/` — script tag, App.js wiring, package.json dep
- `demos/dev-demo`, `demos/react-ui/vite-app`, `demos/vue-ui/vite-app` — no change needed unless the constructor requires mandatory config

## 5. Out of Scope

- ❌ Do not modify abstract-adapter or the tronlink adapter package
- ❌ Do not modify existing TRON adapters
- ❌ Do not modify version numbers (managed by changeset)
- ❌ Do not add extra runtime dependencies
```

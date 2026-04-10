# Plan Template — EVM Wallet Adapter

Use this template to create `requires/<version>/plan.md`.

---

```markdown
# <version> Development Plan: Add {{WALLET_NAME}} EVM Adapter

## 1. Overview

Add the `{{NPM_PACKAGE}}` package at `packages/adapters/evm/{{WALLET_DIR}}/`.
Follow the MetaMask / Trust EVM adapter implementation patterns, extending the `Adapter` base class.

### Reference Implementations
- `packages/adapters/evm/metamask/` — Primary reference (EIP-6963 only, signTypedData JSON.stringify)
- `packages/adapters/evm/okxwallet/` — Secondary reference (same pattern, latest implementation)

## 2. {{WALLET_NAME}} Characteristics

| Property | Value |
|----------|-------|
| name | `'{{WALLET_NAME}}'` |
| rdns | `'{{WALLET_RDNS}}'` |
| url | `{{WALLET_URL}}` |
| Injected Object | `{{WALLET_INJECTION}}` |
| Identifier Field | `provider.{{WALLET_IS_FIELD}}` |
| EIP-6963 | Supported |
| Mobile WebView | Detect `{{WALLET_INJECTION}}` presence |
| DeepLink | `{{WALLET_DEEPLINK}}...` |

## 3. File Manifest

packages/adapters/evm/{{WALLET_DIR}}/
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
        ├── adapter.test.ts
        └── {{WALLET_DIR}}-provider.ts

## 4. Development Tasks

### Task 1: Create package structure and config files
- `package.json` — name: `{{NPM_PACKAGE}}`, dependency: `@tronweb3/abstract-adapter-evm: workspace:^`
- `tsconfig.all.json` / `tsconfig.cjs.json` / `tsconfig.esm.json` — Same as MetaMask
- `vitest.config.ts` — happy-dom environment
- `README.md` / `LICENSE`

### Task 2: Implement `src/utils.ts`
- `{{WALLET_CLASS_UPPER}}_RDNS = '{{WALLET_RDNS}}'`
- `get{{WALLET_CLASS}}Provider()` — Detect `{{WALLET_INJECTION}}`, fallback to `window.ethereum.{{WALLET_IS_FIELD}}`
- `is{{WALLET_CLASS}}MobileWebView()` — Detect `{{WALLET_INJECTION}}` presence on mobile
- `open{{WALLET_CLASS}}WithDeeplink()` — `{{WALLET_DEEPLINK}}...`

### Task 3: Implement `src/adapter.ts`
- `{{WALLET_CLASS}}EvmAdapter extends Adapter`
- Constructor: set eip6963Info, call getProvider → listenEvents → autoConnect
- `connect()` — DeepLink mobile redirect / eth_requestAccounts
- `signTypedData()` — JSON.stringify typedData (same as MetaMask)
- `isEIP6963Provider()` — Check rdns === {{WALLET_CLASS_UPPER}}_RDNS
- `getInjectedProvider()` — Call get{{WALLET_CLASS}}Provider()
- `getProvider()` — Mobile WebView detection + EIP-6963

### Task 4: Implement `src/index.ts`
- `export * from './adapter.js'`

### Task 5: Implement tests
- `tests/units/{{WALLET_DIR}}-provider.ts` — Mock EIP1193 Provider + install{{WALLET_CLASS}}EIP6963Provider
- `tests/units/adapter.test.ts` — Base properties, EIP-6963 discovery, mobile WebView, wrong rdns rejection, signTypedData, connect

### Task 6: Register in project
- `packages/adapters/adapters/package.json` — Add dependency
- `packages/adapters/adapters/src/index.ts` — Add re-export
- `tsconfig.all.json` (root) — Add reference

## 5. Out of Scope

- ❌ Do not modify abstract-adapter-evm
- ❌ Do not modify existing EVM adapters
- ❌ Do not modify version numbers (managed by changeset)
- ❌ Do not add extra runtime dependencies
```

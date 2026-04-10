---
name: evm-add-wallet-adapter
description: 'Add a new EVM wallet adapter end-to-end. Use when: user asks to add/create a new EVM wallet adapter (e.g. OKXWallet, Phantom, Coinbase, TokenPocket, Rabby, etc.). Covers the full workflow: requirements doc, plan, implementation, tests, docs, registration, and demo integration.'
---

# EVM Wallet Adapter — Full Workflow

## Overview

This skill automates the entire process of adding a new EVM-compatible wallet adapter to the tronwallet-adapter monorepo. It follows a proven 7-phase workflow.

## When to Use

- User says "add XXX EVM adapter" or "create a new EVM wallet adapter for XXX"
- User wants to integrate a new EVM-compatible browser wallet
- User mentions a wallet name and wants EVM support added

## Workflow Phases

### Phase 1: Requirements Document (`require.md`)

Create `requires/<version>/require.md` following the [requirements template](./references/require-template.md).

Gather from the user or research:
- Wallet name, official URL, icon
- Provider injection object (e.g., `window.okxwallet`, `window.phantom.ethereum`)
- Provider identifier field (e.g., `isOkxWallet`, `isPhantom`)
- EIP-6963 rdns value (e.g., `com.okex.wallet`, `app.phantom`)
- DeepLink scheme for mobile (e.g., `okx://wallet/dapp/url?dappUrl=...`)
- Any wallet-specific quirks or differences from standard EIP-1193

### Phase 2: Development Plan (`plan.md`)

Create `requires/<version>/plan.md` following the [plan template](./references/plan-template.md).

Key contents:
- Wallet characteristics table (name, rdns, url, injection, identification, deeplink)
- Complete file manifest
- 6 development tasks (package structure → utils → adapter → index → tests → registration)
- Explicit "not doing" list

### Phase 3: Implementation

Create the adapter package at `packages/adapters/evm/<wallet-name>/` following these code templates:

| File | Template |
|------|----------|
| `package.json` | [package.json template](./references/code-package-json.md) |
| `src/metadata.ts` | [metadata template](./references/code-metadata.md) |
| `src/adapter.ts` | [adapter template](./references/code-adapter.md) |
| `src/utils.ts` | [utils template](./references/code-utils.md) |
| `src/index.ts` | `export * from './metadata.js'; export * from './adapter.js';` |
| `tsconfig.*.json` | [tsconfig templates](./references/code-tsconfig.md) |
| `vitest.config.ts` | [vitest config template](./references/code-vitest.md) |
| `LICENSE` | MIT License |

Variable substitution table — replace these placeholders in ALL templates:

| Placeholder | Example (OKXWallet) | Description |
|-------------|---------------------|-------------|
| `{{WALLET_NAME}}` | `OKX Wallet` | Display name |
| `{{WALLET_CLASS}}` | `OkxWallet` | PascalCase class prefix |
| `{{WALLET_DIR}}` | `okxwallet` | Directory/package suffix |
| `{{WALLET_URL}}` | `https://www.okx.com/web3` | Official wallet URL |
| `{{WALLET_RDNS}}` | `com.okex.wallet` | EIP-6963 rdns identifier |
| `{{WALLET_INJECTION}}` | `window.okxwallet` | Global injection object |
| `{{WALLET_IS_FIELD}}` | `isOkxWallet` | Boolean identifier on provider |
| `{{WALLET_DEEPLINK}}` | `okx://wallet/dapp/url?dappUrl=` | Mobile deeplink prefix |
| `{{WALLET_ICON}}` | `data:image/png;base64,...` | Base64-encoded icon |
| `{{NPM_PACKAGE}}` | `@tronweb3/tronwallet-adapter-okxwallet-evm` | Full npm package name |

### Phase 4: Tests

Create test files at `packages/adapters/evm/<wallet-name>/tests/units/`:

| File | Template |
|------|----------|
| `adapter.test.ts` | [test template](./references/code-tests.md) |
| `<wallet-name>-provider.ts` | [mock provider template](./references/code-mock-provider.md) |

Required test cases:
1. Base properties (name, url, readyState, address, connected)
2. EIP-6963 provider discovery
3. Mobile WebView injected provider detection
4. Wrong rdns rejection
5. NotFound after EIP-6963 timeout
6. `signTypedData()` with JSON.stringify
7. `connect()` success
8. `connect()` WalletNotFoundError
9. `connect()` error propagation

### Phase 5: Registration

Register the new adapter in 3 places:

1. **`packages/adapters/adapters/src/index.ts`** — Add re-export line:
   ```typescript
   export * from '{{NPM_PACKAGE}}';
   ```

2. **`packages/adapters/adapters/package.json`** — Add dependency:
   ```json
   "{{NPM_PACKAGE}}": "workspace:^"
   ```

3. **`tsconfig.all.json`** (root) — Add reference:
   ```json
   { "path": "./packages/adapters/evm/{{WALLET_DIR}}/tsconfig.all.json" }
   ```

### Phase 6: Documentation

Create `packages/adapters/evm/<wallet-name>/README.md` following the [docs template](./references/docs-readme.md).

Must include:
- Quick demo code snippet
- Constructor API with options
- Link to Abstract Adapter docs
- Installation instructions

### Phase 7: Demo Integration

Add the adapter to all 4 demo apps. See [demo integration guide](./references/demo-integration.md).

| Demo | What to update |
|------|---------------|
| `demos/cdn-demo/evm/` | `index.html` (script tag), `App.js` (adapter instance), `package.json` |
| `demos/dev-demo/` | `AdapterBasicTest.tsx`, `EvmAdapterDemo.tsx`, `package.json` |
| `demos/react-ui/vite-app/` | `EvmDemo.tsx` (adapter list), `package.json` |
| `demos/vue-ui/vite-app/` | `EvmDemo.vue` (adapter list), `package.json` |

## Build & Verify

After all phases:

```bash
# Install dependencies
pnpm install

# Build the new adapter + UMD
cd packages/adapters/evm/<wallet-name>
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

- [ ] `requires/<version>/require.md` created
- [ ] `requires/<version>/plan.md` created
- [ ] `packages/adapters/evm/<wallet>/` package created with all source files
- [ ] Tests pass (`vitest run`)
- [ ] Registered in adapters index, adapters package.json, root tsconfig.all.json
- [ ] README.md with API docs and demo snippet
- [ ] Added to all 4 demo apps
- [ ] `pnpm build` succeeds (ESM + CJS + types + UMD)
- [ ] Dev server starts without errors

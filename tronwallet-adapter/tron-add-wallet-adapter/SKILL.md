---
name: tron-add-wallet-adapter
description: 'Add a new TRON (native chain) wallet adapter end-to-end. Use when: user asks to add/create a new TRON wallet adapter (e.g. Bybit, Backpack, OneKey, TokenPocket, imToken, etc.). Covers the full workflow: requirements, provider archetype decision, implementation, tests, registration, docs, and demo integration.'
---

# TRON Wallet Adapter — Full Workflow

## Overview

This skill automates the entire process of adding a new TRON (native chain) wallet adapter to the tronwallet-adapter monorepo. It follows a proven 7-phase workflow: requirements → plan → implementation → tests → registration → documentation → demo integration.

## When to Use

- User says "add XXX TRON adapter" or "create a new TRON wallet adapter for XXX"
- User wants to integrate a new browser wallet that supports the TRON native chain
- User mentions a wallet name and wants TRON support added

## When NOT to Use

- The wallet adapter targets an **EVM-compatible chain** (EIP-1193 / EIP-6963 provider, `-evm` package suffix) → use the sibling **evm-add-wallet-adapter** skill instead.

## Key Differences from EVM Adapters

- **Flat package location**: `packages/adapters/<wallet-dir>/` (no `evm/` subdirectory).
- **npm name**: `@tronweb3/tronwallet-adapter-<dir>` — **no `-evm` suffix**.
- **NO `metadata.ts`**: wallet identity (`name`, `url`, `icon`) is declared inline as `readonly` class properties on the adapter.
- **Polling-based detection**: providers are discovered by polling `window` every 100ms up to `checkTimeout` — there is no EIP-6963 announcement and no rdns.
- **Two provider archetypes**: TronLink-compatible (A) vs provider request-based (B) — templates fork accordingly.
- **Demos auto-discover TRON adapters** through the aggregate package, so a **zero-argument constructor is mandatory** (all config options must have defaults).

## Workflow Phases

### Phase 1: Requirements Document (`require.md`)

First, gather the wallet facts, then make the **MANDATORY archetype decision** using the [archetype decision guide](./references/archetype-decision.md). Produce `requires/<version>/require.md` following the [requirements template](./references/require-template.md).

Facts to gather from the user or research:
- Wallet display name, official URL, base64 data-URI icon
- Injection key on `window` (e.g., `window.bybitWallet`, `window.backpack`)
- **Archetype evidence**: does the wallet inject a `.tronLink`-shaped object with `.tronWeb` (→ Archetype A), or a provider with `request({ method: 'tron_*' })` (→ Archetype B)?
- Archetype A only: mobile deeplink URL/prefix, in-app userAgent regex marker
- Archetype B only: full provider path (e.g., `window.backpack.tron`), identity flag field (e.g., `isBackpack`)
- Feature matrix: `multiSign` / `switchChain` / `network()` / `signTypedData` support

### Phase 2: Development Plan (`plan.md`)

Create `requires/<version>/plan.md` following the [plan template](./references/plan-template.md).

Reference implementations in the monorepo:
- **Archetype A** (TronLink-compatible): `packages/adapters/bybit/`
- **Archetype B** (provider request-based): `packages/adapters/backpack/`

### Phase 3: Implementation

Create the adapter package at `packages/adapters/<wallet-dir>/` following these code templates:

| File | Archetype A Template | Archetype B Template |
|------|----------------------|----------------------|
| `src/adapter.ts` | [adapter A](./references/code-adapter-tronlink-style.md) | [adapter B](./references/code-adapter-provider-style.md) |
| `src/utils.ts` | [utils A](./references/code-utils-tronlink-style.md) | [utils B](./references/code-utils-provider-style.md) |
| `package.json` | [package.json template](./references/code-package-json.md) | same |
| `tsconfig.*.json` | [tsconfig templates](./references/code-tsconfig.md) | same |
| `vitest.config.ts` | [vitest config template](./references/code-vitest.md) | same |
| `LICENSE` | MIT (copy from any existing adapter package) | same |
| `src/index.ts` | `export * from './adapter.js'; export * from './utils.js';` | same |

Variable substitution table — replace these placeholders in ALL templates:

| Placeholder | Archetype | Example (A: Bybit / B: Backpack) | Description |
|-------------|-----------|----------------------------------|-------------|
| `{{WALLET_NAME}}` | both | `Bybit Wallet` / `Backpack` | Display name, becomes the AdapterName string |
| `{{WALLET_CLASS}}` | both | `BybitWallet` / `Backpack` | PascalCase prefix → `{{WALLET_CLASS}}Adapter`, `{{WALLET_CLASS}}AdapterName` |
| `{{WALLET_DIR}}` | both | `bybit` / `backpack` | Directory under `packages/adapters/` |
| `{{NPM_PACKAGE}}` | both | `@tronweb3/tronwallet-adapter-bybit` / `@tronweb3/tronwallet-adapter-backpack` | Full npm package name (no `-evm` suffix) |
| `{{WALLET_URL}}` | both | `https://www.bybit.com/web3` / `https://backpack.app` | Official wallet URL (opened via `window.open` when wallet not found) |
| `{{WALLET_ICON}}` | both | `data:image/svg+xml;base64,...` | Base64 data-URI icon |
| `{{WALLET_INJECTION_KEY}}` | both | `bybitWallet` / `backpack` | Key on `window` |
| `{{WALLET_PROVIDER_PATH}}` | B only | `window.backpack.tron` | Full provider path |
| `{{WALLET_IS_FIELD}}` | B only | `isBackpack` | Identity flag on the provider |
| `{{WALLET_DEEPLINK}}` | A only | `https://app.bybit.com/...` | Mobile deeplink URL/prefix |
| `{{WALLET_APP_UA_MARKER}}` | A only | `bybit_app` | In-app userAgent regex marker |

### Phase 4: Tests

Create test files at `packages/adapters/<wallet-dir>/tests/units/`:

| File | Template |
|------|----------|
| `adapter.test.ts` | [tests A](./references/code-tests-tronlink-style.md) or [tests B](./references/code-tests-provider-style.md) |
| `mock.ts` | [mock A](./references/code-mock-tronlink-style.md) or [mock B](./references/code-mock-provider-style.md) |
| `utils.ts` | `wait()` / `CHECK_TIMEOUT` snippet included in the test templates |

Required test cases:
1. Constructor / config validation (zero-arg construction must work)
2. Detection states: `NotFound` / `Disconnect` / `Connected`
3. `connect()` success
4. `connect()` → `WalletNotFoundError` + `window.open` of `{{WALLET_URL}}` when wallet absent
5. `connect()` user rejection propagation
6. `signMessage()`
7. `signTransaction()`
8. `multiSign()` — or asserting it throws when unsupported
9. `disconnect()`
10. `accountsChanged` / `chainChanged` events

### Phase 5: Registration

Register the new adapter in **exactly 5 places**:

1. **`packages/adapters/adapters/package.json`** — Add dependency:
   ```json
   "{{NPM_PACKAGE}}": "workspace:^"
   ```

2. **`packages/adapters/adapters/src/index.ts`** — Add re-export line:
   ```typescript
   export * from '{{NPM_PACKAGE}}';
   ```

3. **`packages/adapters/adapters/tests/adapters.test.ts`** — Add assertion:
   ```typescript
   expect(Adapters.{{WALLET_CLASS}}Adapter).not.toBeUndefined();
   ```

4. **`packages/adapters/adapters/tsconfig.all.json`** — Add reference:
   ```json
   { "path": "../{{WALLET_DIR}}/tsconfig.all.json" }
   ```

5. **Root `tsconfig.all.json`** — Add reference:
   ```json
   { "path": "./packages/adapters/{{WALLET_DIR}}/tsconfig.all.json" }
   ```

### Phase 6: Documentation

Create `packages/adapters/<wallet-dir>/README.md` following the [docs template](./references/docs-readme.md).

### Phase 7: Demo Integration

See the [demo integration guide](./references/demo-integration.md).

| Demo | What to update |
|------|---------------|
| `demos/dev-demo/` | **NO changes** — auto-discovery via the aggregate package |
| `demos/react-ui/vite-app/` | **NO changes** — auto-discovery via the aggregate package |
| `demos/vue-ui/vite-app/` | **NO changes** — auto-discovery via the aggregate package |
| `demos/cdn-demo/tron/` | `index.html` (UMD script tag), `App.js` (adapter instance), `package.json` (dependency) |

## Build & Verify

After all phases:

```bash
# Install dependencies
pnpm install

# Build the entire project (root)
pnpm build

# Test + UMD build for the new adapter
cd packages/adapters/<wallet-dir>
pnpm test
pnpm run build:umd

# Verify the aggregate package picks it up
cd packages/adapters/adapters
pnpm test

# Start dev-demo and confirm the wallet appears in the selector
cd demos/dev-demo
pnpm dev
```

## Checklist

- [ ] `requires/<version>/require.md` created
- [ ] `requires/<version>/plan.md` created + archetype decided (A or B)
- [ ] `packages/adapters/<wallet-dir>/` package created with all source files (no `metadata.ts`)
- [ ] Tests pass (`pnpm test` in the new package)
- [ ] Registered in ALL 5 places (adapters package.json, adapters index, adapters test, adapters tsconfig.all.json, root tsconfig.all.json)
- [ ] Aggregate package test passes (`packages/adapters/adapters`)
- [ ] README.md with API docs and demo snippet
- [ ] cdn-demo (`demos/cdn-demo/tron/`) wired (index.html + App.js + package.json)
- [ ] Root `pnpm build` succeeds (ESM + CJS + types + UMD)
- [ ] Wallet appears in dev-demo via auto-discovery

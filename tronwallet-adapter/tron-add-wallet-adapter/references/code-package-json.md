# package.json Template — TRON Wallet Adapter

```json
{
    "name": "{{NPM_PACKAGE}}",
    "version": "1.0.0",
    "description": "Wallet adapter for {{WALLET_NAME}} extension and {{WALLET_NAME}} app.",
    "keywords": [
        "TRON",
        "TronWeb",
        "{{WALLET_NAME}}"
    ],
    "author": "tronweb3",
    "repository": {
        "type": "git",
        "url": "https://github.com/tronweb3/tronwallet-adapter"
    },
    "license": "MIT",
    "type": "module",
    "sideEffects": false,
    "engines": {
        "node": ">=16",
        "pnpm": ">=7"
    },
    "main": "./lib/cjs/index.js",
    "module": "./lib/esm/index.js",
    "types": "./lib/types/index.d.ts",
    "exports": {
        "require": "./lib/cjs/index.js",
        "import": "./lib/esm/index.js",
        "types": "./lib/types/index.d.ts"
    },
    "files": [
        "lib",
        "src",
        "LICENSE"
    ],
    "publishConfig": {
        "access": "public"
    },
    "scripts": {
        "clean": "shx mkdir -p lib && shx rm -rf lib",
        "package": "shx echo '{ \"type\": \"commonjs\" }' > lib/cjs/package.json",
        "test": "vitest run",
        "test:coverage": "vitest run --coverage",
        "build:umd": "node ../../../scripts/build-umd.js"
    },
    "dependencies": {
        "@tronweb3/tronwallet-abstract-adapter": "workspace:^"
    },
    "devDependencies": {
        "@testing-library/dom": "8.20.1",
        "shx": "0.3.4",
        "vitest": "3.2.4"
    }
}
```

> **Archetype A only (TronLink-compatible):** also add the TronLink adapter package, which provides the shared `TronLinkWallet` types and `getNetworkInfoByTronWeb` helper:
>
> ```json
> "dependencies": {
>     "@tronweb3/tronwallet-abstract-adapter": "workspace:^",
>     "@tronweb3/tronwallet-adapter-tronlink": "workspace:^"
> }
> ```
>
> Archetype B (provider request-based) adapters depend only on `@tronweb3/tronwallet-abstract-adapter` — see packages/adapters/backpack/package.json.

## Key Points

1. **`build:umd` path is 3 levels up** (`../../../scripts/build-umd.js`), NOT 4 as in EVM adapters. TRON adapters live at `packages/adapters/<dir>/`, one level shallower than EVM adapters.
2. **`workspace:^` protocol**: Both runtime dependencies are workspace packages; pnpm rewrites them to real semver ranges at publish time.
3. **Keywords**: TRON adapters use `["TRON", "TronWeb", "{{WALLET_NAME}}"]` — not the EVM keyword set.
4. **No `happy-dom` in devDependencies**: TRON adapters resolve `happy-dom` from the monorepo root (workspace hoisting); do not add it per-package. This matches packages/adapters/bybit/package.json.
5. **Dual ESM/CJS build**: `main`/`module`/`types` plus the `exports` map mirror the build output layout (`lib/cjs`, `lib/esm`, `lib/types`). The `package` script writes a `{ "type": "commonjs" }` marker into `lib/cjs` so Node treats CJS output correctly.
6. **Version starts at 1.0.0** for a brand-new adapter package.

## Variable Mapping

| Placeholder | Description | Example (Archetype A) | Example (Archetype B) |
|---|---|---|---|
| `{{NPM_PACKAGE}}` | npm package name (no `-evm` suffix) | `@tronweb3/tronwallet-adapter-bybit` | `@tronweb3/tronwallet-adapter-backpack` |
| `{{WALLET_NAME}}` | Display name of the wallet | `Bybit Wallet` | `Backpack` |

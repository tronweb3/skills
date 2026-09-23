# package.json Template — TRON Wallet Adapter

```json
{
    "name": "{{NPM_PACKAGE}}",
    "version": "1.0.0",
    "description": "Wallet adapter for {{WALLET_NAME}} extension and app.",
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
        "types": "./lib/types/index.d.ts",
        "import": "./lib/esm/index.js",
        "require": "./lib/cjs/index.js"
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
        "@tronweb3/tronwallet-abstract-adapter": "workspace:^",
        "@tronweb3/tronwallet-adapter-tronlink": "workspace:^"
    },
    "devDependencies": {
        "@testing-library/dom": "8.20.1",
        "shx": "0.3.4",
        "vitest": "3.2.4"
    }
}
```

## Notes

- Omit the `@tronweb3/tronwallet-adapter-tronlink` dependency if the wallet's provider is **not**
  TronLink-compatible (e.g. Backpack-style bespoke provider) — in that case you don't need
  `TronLinkWallet`/`getNetworkInfoByTronWeb` either.
- `happy-dom` is a root-level devDependency shared across the workspace (pnpm hoisting) — don't
  add it per-package; the sibling adapters don't list it even though `vitest.config.ts` uses it
  as the test environment.
- `build:umd` path depth (`../../../scripts/build-umd.js`) assumes the package lives directly
  under `packages/adapters/<wallet-name>/` (three levels up to repo root) — this differs from the
  EVM adapters, which live one level deeper at `packages/adapters/evm/<wallet-name>/` and use
  `../../../../scripts/build-umd.js`.

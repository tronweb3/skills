# tsconfig Templates — TRON Wallet Adapter

Three tsconfig files per adapter package, copied from packages/adapters/bybit/. No placeholders — the contents are identical for every adapter.

## tsconfig.all.json

```json
{
    "extends": "../../../tsconfig.root.json",
    "references": [
        {
            "path": "../abstract-adapter/tsconfig.all.json"
        },
        {
            "path": "../tronlink/tsconfig.all.json"
        },
        {
            "path": "./tsconfig.cjs.json"
        },
        {
            "path": "./tsconfig.esm.json"
        }
    ]
}
```

> **Archetype A only:** the `../tronlink/tsconfig.all.json` reference is required only for TronLink-compatible adapters (which import from `@tronweb3/tronwallet-adapter-tronlink`). For Archetype B (provider request-based) adapters, omit that entry and keep only `../abstract-adapter/tsconfig.all.json`, `./tsconfig.cjs.json`, and `./tsconfig.esm.json`.

## tsconfig.cjs.json

```json
{
    "extends": "../../../tsconfig.cjs.json",
    "include": ["src"],
    "compilerOptions": {
        "outDir": "lib/cjs"
    }
}
```

## tsconfig.esm.json

```json
{
    "extends": "../../../tsconfig.esm.json",
    "include": ["src"],
    "compilerOptions": {
        "outDir": "lib/esm",
        "declarationDir": "lib/types"
    }
}
```

## Key Points

1. **`extends` paths are 3 levels up** (`../../../tsconfig.*.json`), NOT 4 as in EVM adapters — TRON adapters live directly under `packages/adapters/<dir>/`.
2. **Project references mirror dependencies**: `tsconfig.all.json` references every workspace package the adapter depends on, so TypeScript builds them in the right order. The tronlink reference exists only when the package.json depends on `@tronweb3/tronwallet-adapter-tronlink` (Archetype A).
3. **ESM build emits types**: `tsconfig.esm.json` sets `declarationDir: "lib/types"` so `.d.ts` files land where package.json's `types` field points. The CJS build emits only `.js`.
4. **Do NOT copy backpack's extras**: packages/adapters/backpack/ contains an additional `tsconfig.json` and a `vite.config.ts` — these are non-standard outliers and must not be copied into a new adapter. Use only the three files above plus `vitest.config.ts` (see code-vitest.md).

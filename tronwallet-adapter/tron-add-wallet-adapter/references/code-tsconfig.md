# tsconfig Templates — TRON Wallet Adapter

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

Drop the `../tronlink/tsconfig.all.json` reference if the adapter doesn't depend on
`@tronweb3/tronwallet-adapter-tronlink` (non-TronLink-compatible provider).

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

## Notes

- All TRON adapters use the same tsconfig structure and live directly under
  `packages/adapters/<wallet-name>/` — paths are `../../../tsconfig.*.json` (three levels up),
  **not** `../../../../` like the EVM adapters under `packages/adapters/evm/<wallet-name>/`.
- `abstract-adapter` (and `tronlink`, if used) are referenced as project dependencies in
  `tsconfig.all.json` so the TypeScript project build graph picks them up in the right order.

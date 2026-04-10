# tsconfig Templates — EVM Wallet Adapter

## tsconfig.all.json

```json
{
    "extends": "../../../../tsconfig.root.json",
    "references": [
        {
            "path": "../abstract-adapter/tsconfig.all.json"
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

## tsconfig.esm.json

```json
{
    "extends": "../../../../tsconfig.esm.json",
    "include": ["src"],
    "compilerOptions": {
        "declaration": true,
        "outDir": "lib/esm",
        "declarationDir": "lib/types"
    }
}
```

## tsconfig.cjs.json

```json
{
    "extends": "../../../../tsconfig.cjs.json",
    "include": ["src"],
    "compilerOptions": {
        "outDir": "lib/cjs"
    }
}
```

## Notes

- All EVM adapters use the same tsconfig structure
- `extends` paths point to root configs (`../../../../tsconfig.*.json`)
- `abstract-adapter` is referenced as a project dependency in `tsconfig.all.json`
- ESM build produces both `.js` and `.d.ts` files
- CJS build produces only `.js` files (types come from ESM build)

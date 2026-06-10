# Demo Integration Guide — TRON Wallet Adapter

> **IMPORTANT — TRON adapters are AUTO-DISCOVERED in 3 of the 4 demos.**
> Unlike EVM adapters, the `dev-demo`, `react-ui` and `vue-ui` demos build their adapter
> lists dynamically from the `@tronweb3/tronwallet-adapters` aggregate package. Once the
> adapter is registered in the aggregate package (Phase 5), **NO code changes are needed**
> in those three demos. The ONLY demo that requires manual edits is `demos/cdn-demo/tron/`.

## Auto-discovery (dev-demo, react-ui, vue-ui) — no edits required

Each of the three demos iterates over every export of `@tronweb3/tronwallet-adapters` and instantiates anything that looks like a TRON adapter class.

`demos/dev-demo/src/components/WalletProvider.tsx` (~line 61):

```typescript
...Object.entries(Adapters)
    .filter(([key]) => key.endsWith('Adapter') && !key.endsWith('EvmAdapter') && !key.includes('WalletConnect') && !key.includes('Binance'))
    .map(([key, value]) => new (value as any)()),
```

`demos/react-ui/vite-app/src/App.tsx` (~line 81):

```typescript
...Object.entries(Adapters)
    .filter(
        ([key]) => key.endsWith('Adapter') && !key.endsWith('EvmAdapter') && !key.includes('WalletConnect')
    )
    .map(([key, value]) => new (value as any)()),
```

`demos/vue-ui/vite-app/src/App.vue` (~line 37):

```typescript
...Object.entries(Adapters)
    .filter(([key]) => key.endsWith('Adapter') && !key.endsWith('EvmAdapter') && !key.includes('WalletConnect'))
    .map(([key, value]) => new (value as any)()),
```

Consequences:

- As soon as `{{WALLET_CLASS}}Adapter` is re-exported from `packages/adapters/adapters` (the `@tronweb3/tronwallet-adapters` aggregate package), all three demos pick it up automatically — its export name ends with `Adapter`, does not end with `EvmAdapter`, and does not include `WalletConnect` (dev-demo additionally excludes names containing `Binance`, since `BinanceWalletAdapter` is manually instantiated with WalletConnect-fallback config — see `WalletProvider.tsx` lines 51–59). A normal new adapter matches the filter in all three demos.
- **The adapter MUST be instantiable with zero constructor args** — the discovery code calls `new (value as any)()` with no arguments. All config fields must be optional with sensible defaults.

## The only manual demo: cdn-demo (`demos/cdn-demo/tron/`)

The CDN demo loads adapters as UMD bundles via script tags, so it needs three edits.

**Important**: run `pnpm run build:umd` in the adapter package (`packages/adapters/{{WALLET_DIR}}/`) first, so `lib/umd/index.js` exists.

### 1. `demos/cdn-demo/tron/index.html` — add the UMD script tag

Add alongside the existing adapter script tags (same `defer` + relative `node_modules` form as the real tags, e.g. the bybit line):

```html
<script defer src="../node_modules/{{NPM_PACKAGE}}/lib/umd/index.js"></script>
```

### 2. `demos/cdn-demo/tron/App.js` — destructure the global and add an instance

Add with the other `window[...]` destructurings at the top of the file:

```javascript
const { {{WALLET_CLASS}}Adapter } = window['{{NPM_PACKAGE}}'];
```

Add to the `options` array inside `setup()`:

```javascript
new {{WALLET_CLASS}}Adapter(),
```

### 3. `demos/cdn-demo/package.json` — add the dependency

```json
"{{NPM_PACKAGE}}": "^1.0.0"
```

After editing, run `pnpm install` from the monorepo root so the workspace link resolves.

## Verification

```bash
cd demos/dev-demo && pnpm dev
```

1. Open the dev-demo in a browser with the wallet extension installed.
2. Select **{{WALLET_NAME}}** in the wallet selector — it should appear automatically (auto-discovery).
3. Click Connect and confirm `address` is populated and the `connect` event fires.
4. Exercise Sign Message and Sign Transaction and confirm the wallet prompts and the results verify.

## Key Points

- **TRON vs EVM**: EVM adapters require manual import/instantiation in every demo; TRON adapters are auto-discovered everywhere except cdn-demo. Do NOT add manual imports of the new adapter to dev-demo, react-ui or vue-ui — that would create duplicate entries.
- **Zero-arg constructor is a hard requirement** enforced by the `new (value as any)()` discovery pattern; it is also why the README usage snippet shows `new {{WALLET_CLASS}}Adapter()` with no arguments.
- **cdn-demo needs the UMD build** (`lib/umd/index.js`), produced by `pnpm run build:umd` in the adapter package; the other demos consume ES modules through the aggregate package.
- The UMD bundle registers itself on `window` under the full npm package name, which is why `App.js` destructures from `window['{{NPM_PACKAGE}}']`.

## Variable Mapping

| Placeholder | Example (archetype A: Bybit) | Example (archetype B: Backpack) | Notes |
| --- | --- | --- | --- |
| `{{WALLET_NAME}}` | `Bybit Wallet` | `Backpack` | Name shown in the demo wallet selector (the AdapterName string) |
| `{{WALLET_CLASS}}` | `BybitWallet` | `Backpack` | PascalCase prefix → `{{WALLET_CLASS}}Adapter` |
| `{{WALLET_DIR}}` | `bybit` | `backpack` | Adapter package directory under `packages/adapters/` |
| `{{NPM_PACKAGE}}` | `@tronweb3/tronwallet-adapter-bybit` | `@tronweb3/tronwallet-adapter-backpack` | UMD global key on `window` and dependency name |

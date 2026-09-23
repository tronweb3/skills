# Demo Integration Guide — TRON Wallet Adapter

TRON demo integration is much lighter than EVM: three of the four demos auto-discover every
adapter exported from the `@tronweb3/tronwallet-adapters` barrel via reflection, so they need
**no code change** for a standard adapter. Only `cdn-demo` needs manual wiring, because it loads
each package as a separate UMD `<script>` tag and has no bundler to do reflection over.

## 1. cdn-demo (`demos/cdn-demo/tron/`) — always needs manual changes

### index.html — add UMD script tag

Add alongside the other TRON adapter script tags:

```html
<script defer src="../node_modules/{{NPM_PACKAGE}}/lib/umd/index.js"></script>
```

### App.js — destructure and instantiate

```javascript
const { {{WALLET_CLASS}}Adapter } = window['{{NPM_PACKAGE}}'];
```

Add to the `options` array:

```javascript
new {{WALLET_CLASS}}Adapter(),
```

### package.json (`demos/cdn-demo/package.json`) — add dependency

```json
"{{NPM_PACKAGE}}": "^1.0.0"
```

**Important**: run `pnpm run build:umd` in the new adapter package first, then `pnpm install` at
the repo root so `node_modules/{{NPM_PACKAGE}}` resolves.

## 2. dev-demo (`demos/dev-demo/`) — usually no change

`demos/dev-demo/src/components/WalletProvider.tsx` builds its adapter list like this:

```typescript
const adapters = useMemo(() => {
  return [
    new Adapters.BinanceWalletAdapter({ /* mandatory config */ }),
    new Adapters.WalletConnectAdapter(walletconnectConfig),
    ...Object.entries(Adapters)
      .filter(([key]) => key.endsWith('Adapter') && !key.endsWith('EvmAdapter') && !key.includes('WalletConnect') && !key.includes('Binance'))
      .map(([key, value]) => new (value as any)()),
  ];
}, []);
```

Any adapter re-exported from `@tronweb3/tronwallet-adapters` whose class name ends in `Adapter`
(and isn't `Binance`/`WalletConnect`, which need mandatory constructor args) is picked up
automatically and instantiated with `new (value as any)()` — **no arguments**. As long as the new
adapter's constructor works with zero arguments (i.e. everything lives in an optional
`BaseAdapterConfig`), it appears in dev-demo automatically once Phase 5 registration is done and
`pnpm install` / rebuild has run.

If the new adapter's constructor *requires* mandatory config (rare — only `Binance` and
`WalletConnect` do today), add it to the explicit list at the top and extend the `.filter()`
exclusion the same way `!key.includes('Binance')` does.

## 3. react-ui (`demos/react-ui/vite-app/src/App.tsx`) — usually no change

Same reflection pattern:

```typescript
const adapters = useMemo(function () {
    const walletConnect1 = new Adapters.WalletConnectAdapter({ /* ... */ });
    return [
        walletConnect1,
        ...Object.entries(Adapters)
            .filter(([key]) => key.endsWith('Adapter') && !key.endsWith('EvmAdapter') && !key.includes('WalletConnect'))
            .map(([key, value]) => new (value as any)()),
    ];
}, []);
```

No manual change needed unless the new adapter also requires mandatory constructor config.

## 4. vue-ui (`demos/vue-ui/vite-app/src/App.vue`) — usually no change

Same reflection pattern:

```typescript
const adapters = [
    walletConnect,
    ...Object.entries(Adapters)
        .filter(([key]) => key.endsWith('Adapter') && !key.endsWith('EvmAdapter') && !key.includes('WalletConnect'))
        .map(([key, value]) => new (value as any)()),
];
```

No manual change needed unless the new adapter also requires mandatory constructor config.

## Notes

- `dev-demo`, `react-ui`, and `vue-ui` all depend only on the `@tronweb3/tronwallet-adapters`
  barrel package (`"latest"` / `workspace:^`), not on individual per-wallet packages — so once
  Phase 5 registration adds the new package to that barrel and `pnpm install` runs, the new
  adapter's export flows through automatically.
- After Phase 5 registration + `pnpm install` + `pnpm build`, verify the new wallet shows up in
  the wallet selector on all three reflection-based demos before assuming "no change needed" — a
  typo in the class name (must end in exactly `Adapter`) or an accidentally-required constructor
  argument will silently exclude or crash it.
- `EvmDemo.tsx` / `EvmDemo.vue` are unrelated — those render EVM adapters outside the TRON
  `WalletProvider` and don't need touching for a TRON-only adapter.

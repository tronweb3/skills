# Archetype Decision Guide — TRON Wallet Adapter

Before writing any code, you MUST determine which of the two TRON adapter archetypes the new wallet belongs to. Every later phase (dependencies, configs, code templates, mocks, tests) branches on this decision, so record it explicitly in the requirements document.

## How to Determine the Archetype

1. **Install the wallet's browser extension** and open a page with DevTools.
2. **Inspect the injected objects**: run `Object.keys(window)` and look for the wallet-specific key, then expand it in the console. The probe below distinguishes the two shapes:

```js
// In the DevTools console, with the wallet extension installed:
const key = '<wallet-key>'; // e.g. 'bybitWallet', 'backpack'

// Archetype A — a TronLink-compatible object is nested under `.tronLink`:
window[key]?.tronLink?.tronWeb;            // truthy + has `.ready` / `.request`

// Archetype B — a generic provider exposes a `request` method directly:
typeof window[key]?.tron?.request;         // 'function' (tron_* methods)
window[key]?.tron?.isBackpack;             // wallet-specific identity flag
```

3. **Match against the decision table below.**
4. **Cross-check the wallet's developer documentation**:
   - Docs that say the wallet is **"TronLink compatible"** (or show `window.<key>.tronLink` / `tronWeb` usage) → **Archetype A**.
   - Docs that describe a **custom provider API** with generic `request({ method: 'tron_*' })` calls → **Archetype B**.

### Decision Table

| What you see in DevTools | Archetype |
|--------------------------|-----------|
| `window.{{WALLET_INJECTION_KEY}}.tronLink` object shaped like TronLink: has `.tronWeb`, `.ready`, and `.request({ method: 'tron_requestAccounts' })` | **A — TronLink-compatible** |
| A provider at `{{WALLET_PROVIDER_PATH}}` (e.g. `window.<key>.tron`) exposing a generic `request({ method: 'tron_accounts' \| 'tron_requestAccounts' \| 'tron_signMessage' \| 'tron_signTransaction' \| 'tron_chainId' \| 'tron_switchChain' })` plus `on('accountsChanged')` / `removeListener(...)` | **B — provider request-based** |

If both shapes appear, prefer the one the wallet's docs declare as the supported API. If neither appears, the wallet does not support TRON in the browser — stop and report back.

## Existing Adapters by Archetype

| Archetype | Adapter | Path |
|-----------|---------|------|
| A | Bybit Wallet (**primary reference**) | `packages/adapters/bybit/` |
| A | OKX Wallet | `packages/adapters/okxwallet/` |
| A | imToken | `packages/adapters/imtoken/` |
| A | TokenPocket | `packages/adapters/tokenpocket/` |
| A | BitKeep (Bitget) | `packages/adapters/bitkeep/` |
| A | Trust | `packages/adapters/trust/` |
| A | Guarda | `packages/adapters/guarda/` |
| A | FoxWallet | `packages/adapters/foxwallet/` |
| A | OneKey | `packages/adapters/onekey/` |
| A | Gate Wallet | `packages/adapters/gatewallet/` |
| B | Backpack (**primary reference**) | `packages/adapters/backpack/` |

## Consequences of the Decision

| Concern | Archetype A (TronLink-compatible) | Archetype B (provider request-based) |
|---------|-----------------------------------|--------------------------------------|
| Runtime dependencies | `@tronweb3/tronwallet-abstract-adapter` **and** `@tronweb3/tronwallet-adapter-tronlink` (types `TronLinkWallet`, `TronLinkMessageEvent`, `AccountsChangedEventData` + `getNetworkInfoByTronWeb`) | `@tronweb3/tronwallet-abstract-adapter` only |
| Package `tsconfig.all.json` references | `../abstract-adapter/tsconfig.all.json` **and** `../tronlink/tsconfig.all.json` | `../abstract-adapter/tsconfig.all.json` only |
| `vitest.config.ts` `ssr.noExternal` | Required: `['@tronweb3/tronwallet-abstract-adapter', '@tronweb3/tronwallet-adapter-tronlink']` | Not required |
| Code/test/mock templates | Use the **Archetype A** variant of each code, mock, and test reference file in this skill | Use the **Archetype B** variant of each code, mock, and test reference file in this skill |
| Wallet detection | `window.{{WALLET_INJECTION_KEY}}.tronLink` exists | Provider at `{{WALLET_PROVIDER_PATH}}`, with `{{WALLET_IS_FIELD}}` identity-flag fallback |
| Signing | `wallet.tronWeb.trx.sign` / `signMessageV2` / `multiSign` | `request({ method: 'tron_signTransaction' \| 'tron_signMessage' })` |
| `multiSign` | Yes, via `wallet.tronWeb.trx.multiSign` | Usually throws `WalletSignTransactionError` (not implemented) |
| `switchChain` | Not implemented (no TronLink API for it) | Yes, via `request({ method: 'tron_switchChain' })` |
| `network()` | Via `getNetworkInfoByTronWeb(wallet.tronWeb)` | Via `request({ method: 'tron_chainId' })` + chainId map (Mainnet `0x2b6653dc`, Shasta `0x94a9059e`, Nile `0xcd8690dc`) |
| Events | `window.addEventListener('message', ...)` for TronLink actions `connect` / `disconnect` / `accountsChanged` (accountsChanged handler defers 200ms) | `provider.on('accountsChanged' \| 'chainChanged')` / `removeListener` |
| Mobile support | Deeplink via `open{{WALLET_CLASS}}()` in `src/utils.ts` using `{{WALLET_DEEPLINK}}`, in-app detection via `{{WALLET_APP_UA_MARKER}}` userAgent regex | Typically none (browser extension only) |

## Key Points

- The archetype is a **hard fork** in every later phase — never mix the two patterns in one adapter.
- Archetype A adapters import types and `getNetworkInfoByTronWeb` from `@tronweb3/tronwallet-adapter-tronlink`; that is the only reason the extra dependency, tsconfig reference, and `ssr.noExternal` entry exist. Archetype B needs none of them.
- When in doubt, diff the wallet's injected object against `packages/adapters/bybit/src/adapter.ts` (A) and `packages/adapters/backpack/src/utils.ts` (B).

## Variable Mapping

| Placeholder | Meaning | Example |
|-------------|---------|---------|
| `{{WALLET_INJECTION_KEY}}` | Key on `window` (no `window.` prefix) | `bybitWallet` (A) / `backpack` (B) |
| `{{WALLET_PROVIDER_PATH}}` | B only — full provider path | `window.backpack.tron` |
| `{{WALLET_IS_FIELD}}` | B only — identity flag on the provider | `isBackpack` |
| `{{WALLET_CLASS}}` | PascalCase prefix for class/function names | `BybitWallet` |
| `{{WALLET_DEEPLINK}}` | A only — mobile deeplink URL/prefix | `https://app.bybit.com/inapp?by_dp=...` |
| `{{WALLET_APP_UA_MARKER}}` | A only — in-app userAgent regex marker | `bybit_app` |

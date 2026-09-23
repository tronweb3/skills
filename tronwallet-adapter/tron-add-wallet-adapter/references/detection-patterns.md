# Provider Detection Patterns — Survey of Existing TRON Adapters

TRON wallets don't share a discovery protocol like EIP-6963. Every adapter polls for a
wallet-specific global on `window`. Use this table to find the closest existing adapter to
copy from — read its `src/utils.ts` and `src/adapter.ts` directly (`packages/adapters/<name>/`)
rather than re-deriving the pattern from scratch.

| Wallet | Package dir | Injected global | Detection expression | Notes |
|--------|------------|------------------|----------------------|-------|
| OKX Wallet | `okxwallet` | `window.okxwallet.tronLink` | `!!(window.okxwallet && window.okxwallet.tronLink)` | **Best full-featured reference.** Posts `message` events for connect/accountsChanged/disconnect, has security-check + deeplink wiring. Use as the primary template. |
| Bitget Wallet | `bitkeep` | `window.tronLink` + `window.isBitKeep` flag, also exposes `window.bitkeep.{tron,tronLink,tronWeb}` | `!!window.tronLink && !!window.isBitKeep` | No message-event listener — polls `wallet.tron.ready` on an interval instead. Good template for wallets with no push events. |
| FoxWallet | `foxwallet` | `window.foxwallet.tronLink` (`.tronWeb` must also be ready) | `!!(window.foxwallet?.tronLink?.tronWeb)` | Mobile-app only, no desktop extension. |
| GateWallet | `gatewallet` | `window.gatewallet.tronLink` | `!!(window.gatewallet && window.gatewallet.tronLink)` | Also has `isInGateApp()` UA sniff (`/GateApp/i`) used to decide whether to deeplink. |
| Bybit Wallet | `bybit` | `window.bybitWallet.tronLink` | `!!(window.bybitWallet && window.bybitWallet.tronLink)` | UA sniff `/bybit_app/i` for in-app detection. |
| Trust Wallet | `trust` | `window.trustwallet.tronLink` | `!!(window.trustwallet && window.trustwallet.tronLink)` | UA sniff `/Trust/i`. |
| ImToken | `imtoken` | `window.imToken` + `window.tronWeb` | `!!(window.imToken && window.tronWeb)` | Mobile-app only; no wrapped `tronLink`, uses global `window.tronWeb` directly. |
| TokenPocket | `tokenpocket` | `window.tronWeb` + `window.tokenpocket` marker | `!!window.tronWeb && typeof window.tokenpocket !== 'undefined'` | Same "global tronWeb + marker object" shape as ImToken. |
| SafePal | `safepal` | Desktop: `window.safepalTronProvider` + `window.tronWeb`. Mobile: `window.safepalwallet.tron` | Branches on `isInMobileBrowser()` | **Two different injected shapes per platform** — read this one if the target wallet also differs between extension and app. |
| Guarda | `guarda` | `window.guarda` | `typeof window.guarda !== 'undefined'` | Simplest adapter — extension-only, no deeplink, no mobile branch. Good minimal-scope template. |
| OneKey | `onekey` | `window.$onekey.tron` | `!!window.$onekey?.tron` | Namespaced under a shared `$onekey` multi-chain object. |
| Backpack | `backpack` | `window.backpack.tron` or `window.tron.isBackpack` flag | `!!(window.backpack?.tron || window.tron?.isBackpack)` | Provider is **not** TronLink-compatible — has its own `request()`/`connect()` shape, not `tronWeb.trx.*`. Read this one only if the target wallet also has a bespoke (non-TronLink) provider API. |
| Binance Wallet | `binance` | `window.isBinance` flag | `isInBrowser() && Boolean(window.isBinance)` | Also falls back to WalletConnect when not found — has mandatory constructor config, excluded from demo auto-discovery. Don't copy its constructor shape unless the new wallet also needs a WalletConnect fallback. |

## Decision guide

1. **Wallet wraps a full TronLink-compatible object** (`{ tronWeb, request(), ready, on() }`) exposed at `window.<injection>.tronLink` — copy **OkxWallet** (has events) or **BitKeep** (polling only, no events) depending on whether the wallet pushes `postMessage` events.
2. **Wallet injects a bare `window.tronWeb` plus a marker object** (no wrapped `tronLink`) — copy **ImToken** or **TokenPocket**.
3. **Wallet has different injected globals on desktop vs. mobile** — copy **SafePal**.
4. **Wallet has a bespoke, non-TronLink provider API** — copy **Backpack**, and expect `signTransaction`/`signMessage`/`network()` to need custom implementations instead of delegating to `tronWeb.trx.*`.
5. **Extension-only, no mobile app, no deeplink** — copy **Guarda** for the minimal shape.

## Common building blocks (import, don't reimplement)

From `@tronweb3/tronwallet-abstract-adapter`:
- `AddonAdapter`, `AdapterState`, `WalletReadyState`
- Errors: `WalletNotFoundError`, `WalletConnectionError`, `WalletDisconnectedError`, `WalletSignMessageError`, `WalletSignTransactionError`, `WalletGetNetworkError`, `WalletError`
- `isInBrowser()`, `isInMobileBrowser()`, `assertConnectAddress()`
- Types: `Transaction`, `SignedTransaction`, `AdapterName`, `BaseAdapterConfig`, `Network`, `TronWeb`

From `@tronweb3/tronwallet-adapter-tronlink`:
- `TronLinkWallet`, `Tron` types — reuse these instead of redefining the injected provider's shape
- `getNetworkInfoByTronWeb(tronWeb)` — implements the `network()` method for any TronLink-compatible wallet
- `TronLinkMessageEvent`, `AccountsChangedEventData` — if the wallet posts `window.postMessage` events shaped like TronLink's

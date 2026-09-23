# utils.ts Template — TRON Wallet Adapter

Provider detection and mobile deeplink helpers. This is the canonical case — a wallet that
injects a TronLink-compatible object at `window.{{WALLET_INJECTION_KEY}}.tronLink` and has a
mobile app reachable by deeplink. Adjust per the wallet's actual shape (see
[detection-patterns.md](./detection-patterns.md)).

```typescript
import { isInMobileBrowser } from '@tronweb3/tronwallet-abstract-adapter';

export function support{{WALLET_CLASS}}() {
    return !!(window.{{WALLET_INJECTION_KEY}} && window.{{WALLET_INJECTION_KEY}}.tronLink);
}

export function open{{WALLET_CLASS}}() {
    if (isInMobileBrowser() && !support{{WALLET_CLASS}}()) {
        window.location.href = '{{WALLET_DEEPLINK}}' + encodeURIComponent(window.location.href);
        return true;
    }
    return false;
}
```

If the wallet's in-app browser needs to be distinguished from a generic mobile browser (to avoid
deeplinking a user who is already inside the wallet's app), add a UA sniff and gate `open...()` on
it, following the `bybit`/`trust`/`gatewallet` pattern:

```typescript
export function isIn{{WALLET_CLASS}}App() {
    if (typeof window !== 'undefined' && typeof window.navigator !== 'undefined') {
        return /{{WALLET_APP_UA_PATTERN}}/i.test(window.navigator.userAgent);
    }
    return false;
}

export function open{{WALLET_CLASS}}() {
    if (!isIn{{WALLET_CLASS}}App() && isInMobileBrowser()) {
        window.location.href = '{{WALLET_DEEPLINK}}' + encodeURIComponent(window.location.href);
        return true;
    }
    return false;
}
```

## Variable Mapping

| Placeholder | Meaning | Example (OKX Wallet) |
|-------------|---------|---------------------|
| `{{WALLET_CLASS}}` | PascalCase for functions/class prefix | `OkxWallet` |
| `{{WALLET_INJECTION_KEY}}` | Property on `window` (no `window.` prefix) | `okxwallet` |
| `{{WALLET_DEEPLINK}}` | Mobile deeplink URL prefix | `okx://wallet/dapp/url?dappUrl=` |
| `{{WALLET_APP_UA_PATTERN}}` | Regex fragment matching the wallet's in-app User-Agent token | `OKApp` |

## Non-canonical shapes

If Phase 0 research found the wallet doesn't match the canonical shape above, don't force it —
copy the matching reference adapter's `utils.ts` instead:

- **Global `tronWeb` + marker object** (no wrapped `tronLink`) — see `packages/adapters/imtoken/src/utils.ts` or `packages/adapters/tokenpocket/src/utils.ts`
- **Different injected object per platform** — see `packages/adapters/safepal/src/utils.ts`
- **Boolean flag on a shared global** instead of a nested object — see `packages/adapters/bitkeep/src/utils.ts` (`window.tronLink && window.isBitKeep`) or `packages/adapters/binance/src/utils.ts` (`window.isBinance`)
- **Extension-only, no deeplink** — see `packages/adapters/guarda/src/utils.ts` (only `supportGuarda()`, no `open...()` function at all)

## How to Find Wallet-Specific Values

1. **Injection object**: install the wallet extension, open devtools, and diff `Object.keys(window)` before/after installing, or check the wallet's official dApp-integration docs
2. **Detection expression**: check what's actually present at that path (`tronLink`? `tronWeb`? a boolean flag?) and whether `tronWeb.defaultAddress` is populated only after connect
3. **DeepLink**: check the wallet's developer documentation for mobile universal-link / custom-scheme support — some wallets don't have one (extension-only)
4. **App UA token**: install the wallet's mobile app, open its in-app browser to any page, and read `navigator.userAgent`

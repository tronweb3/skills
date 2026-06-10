# utils.ts Template — TRON Wallet Adapter (Archetype A: TronLink-compatible)

Wallet detection, in-app detection, and mobile deeplink utilities. Derived from `packages/adapters/bybit/src/utils.ts`. Replace all `{{...}}` placeholders.

```typescript
import { isInMobileBrowser } from '@tronweb3/tronwallet-abstract-adapter';

export function support{{WALLET_CLASS}}() {
    return !!(window.{{WALLET_INJECTION_KEY}} && window.{{WALLET_INJECTION_KEY}}.tronLink);
}

export function isIn{{WALLET_CLASS}}App() {
    if (typeof window !== 'undefined' && typeof window.navigator !== 'undefined') {
        return /{{WALLET_APP_UA_MARKER}}/i.test(window.navigator.userAgent);
    }
    return false;
}

export function open{{WALLET_CLASS}}() {
    if (!isIn{{WALLET_CLASS}}App() && isInMobileBrowser()) {
        window.location.href = `{{WALLET_DEEPLINK}}${encodeURIComponent(window.location.href)}`;
        return true;
    }
    return false;
}
```

## Key Points

1. **`support{{WALLET_CLASS}}()`**: Detection checks both `window.{{WALLET_INJECTION_KEY}}` AND its `.tronLink` property — the wallet object may be injected before the TRON provider is attached. The `Window` type augmentation (`declare global { interface Window { {{WALLET_INJECTION_KEY}}?: { tronLink: TronLinkWallet } } }`) lives in `adapter.ts`, not here, matching the bybit source layout.
2. **`isIn{{WALLET_CLASS}}App()`**: Detects the wallet's in-app browser via a case-insensitive userAgent regex (`{{WALLET_APP_UA_MARKER}}`). It guards `typeof window`/`typeof window.navigator` so it is safe during SSR. The name is derived from the full `{{WALLET_CLASS}}`; a few existing adapters use a brand-only variant (e.g. bybit's real export is `isInBybitApp`, not `isInBybitWalletApp`) — either form is fine, just keep it consistent within the package. Some older adapters (bybit) also export a redundant eager const `is{{WALLET_CLASS}}App = .../{{WALLET_APP_UA_MARKER}}/i.test(navigator.userAgent)` evaluated at module load; it is intentionally omitted here in favor of the lazy function, which is SSR-safe.
3. **`open{{WALLET_CLASS}}()`**: Only redirects when the user is in a mobile browser AND is NOT already inside the wallet's in-app browser. It returns `true` if a redirect happened — the adapter's `checkIfOpen{{WALLET_CLASS}}()` uses that return value to throw `WalletNotFoundError` and halt the current flow.
4. **Deeplink shapes vary per wallet** — check the wallet's developer docs. The template appends `encodeURIComponent(window.location.href)` to `{{WALLET_DEEPLINK}}`, which fits simple prefix-style deeplinks, but some wallets need custom composition:
   - Bybit uses a two-level encoded universal link:
     ```typescript
     window.location.href = `https://app.bybit.com/inapp?by_dp=${encodeURIComponent(
         'bybitapp://open/route?targetUrl=by%3A%2F%2Fweb3%2Ftab%2Findex%3Findex%3D0'
     )}&by_web_link=${encodeURIComponent(window.location.href)}`;
     ```
   - OKX uses a simple prefix where the template form works as-is, with `{{WALLET_DEEPLINK}}` = `okx://wallet/dapp/url?dappUrl=`:
     ```typescript
     window.location.href = `okx://wallet/dapp/url?dappUrl=${encodeURIComponent(window.location.href)}`;
     ```
   If the target wallet's deeplink cannot be expressed as `prefix + encoded current URL`, replace the assignment body with the wallet-specific composition while keeping the guard and return-value contract intact.

## Variable Mapping

| Placeholder | Meaning | Example (Bybit Wallet) |
|-------------|---------|------------------------|
| `{{WALLET_CLASS}}` | PascalCase prefix for function names | `BybitWallet` |
| `{{WALLET_INJECTION_KEY}}` | Property on `window` (no `window.` prefix) | `bybitWallet` |
| `{{WALLET_APP_UA_MARKER}}` | In-app userAgent regex marker | `bybit_app` |
| `{{WALLET_DEEPLINK}}` | Mobile deeplink URL/prefix the current page URL is appended to | `okx://wallet/dapp/url?dappUrl=` (OKX-style; Bybit needs custom composition, see Key Points) |

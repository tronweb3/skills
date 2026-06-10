# utils.ts Template — TRON Wallet Adapter (Archetype B: Provider Request-Based)

Provider interface and detection helpers (source of truth: `packages/adapters/backpack/src/utils.ts`). Replace all `{{...}}` placeholders.

```typescript
import { isInBrowser } from '@tronweb3/tronwallet-abstract-adapter';

export interface {{WALLET_CLASS}}TronProvider {
    {{WALLET_IS_FIELD}}?: boolean;
    accounts: string[];
    address: string;
    request: (args: { method: string; params?: unknown }) => Promise<unknown>;
    on?(event: 'accountsChanged', handler: (accounts: string[]) => void): void;
    on?(event: 'chainChanged', handler: (chainData: unknown) => void): void;
    on?(event: string, handler: (...args: unknown[]) => void): void;
    removeListener?(event: 'accountsChanged', handler: (accounts: string[]) => void): void;
    removeListener?(event: 'chainChanged', handler: (chainData: unknown) => void): void;
    removeListener?(event: string, handler: (...args: unknown[]) => void): void;
    connect: () => Promise<void>;
    disconnect?: () => Promise<void>;
}

declare global {
    interface Window {
        {{WALLET_INJECTION_KEY}}?: {
            tron?: {{WALLET_CLASS}}TronProvider;
        };
        tron?: {{WALLET_CLASS}}TronProvider;
    }
}

/**
 * Check if {{WALLET_NAME}} is available
 * The wallet injects {{WALLET_PROVIDER_PATH}} or identifies via the {{WALLET_IS_FIELD}} flag
 */
export function support{{WALLET_CLASS}}(): boolean {
    return isInBrowser() && !!(window.{{WALLET_INJECTION_KEY}}?.tron || window.tron?.{{WALLET_IS_FIELD}});
}

/**
 * Get {{WALLET_NAME}} provider
 */
export function get{{WALLET_CLASS}}Provider(): {{WALLET_CLASS}}TronProvider | null {
    if (!isInBrowser()) return null;
    return window.{{WALLET_INJECTION_KEY}}?.tron || (window.tron?.{{WALLET_IS_FIELD}} ? window.tron : null) || null;
}
```

## Key Points

1. **Dual detection — provider path + is-field**: Both helpers check two injection patterns: the wallet's own namespaced path (`{{WALLET_PROVIDER_PATH}}`, i.e. `window.{{WALLET_INJECTION_KEY}}.tron`) first, then the shared `window.tron` object guarded by the `{{WALLET_IS_FIELD}}` identity flag. The flag guard prevents claiming another wallet's `window.tron` injection. `support{{WALLET_CLASS}}()` and `get{{WALLET_CLASS}}Provider()` must check the exact same locations so detection and retrieval never disagree.
2. **Interface lives in utils, not adapter**: `{{WALLET_CLASS}}TronProvider` is exported from `utils.ts` so the adapter, the test mock provider, and any consumer can share the same shape without circular imports.
3. **Optional event methods**: `on`/`removeListener` are optional (with typed overloads for `accountsChanged`/`chainChanged`) because not every provider build ships them — the adapter calls them with optional chaining (`on?.`/`removeListener?.`).
4. **`isInBrowser()` guard**: Every helper short-circuits outside the browser so the adapter is safe to import in SSR environments.
5. **`declare global` augmentation**: The `Window` augmentation makes `window.{{WALLET_INJECTION_KEY}}` and `window.tron` type-safe everywhere in the package; both properties are optional since the extension may not be installed. If the real provider path is not `window.{{WALLET_INJECTION_KEY}}.tron`, adjust the nested property in both the augmentation and the two helpers to match `{{WALLET_PROVIDER_PATH}}`.

## Variable Mapping

| Placeholder | Meaning | Example (Backpack) |
|-------------|---------|--------------------|
| `{{WALLET_CLASS}}` | PascalCase prefix for interface/function names | `Backpack` |
| `{{WALLET_NAME}}` | Display name used in doc comments | `Backpack` |
| `{{WALLET_INJECTION_KEY}}` | Property on `window` (no `window.` prefix) | `backpack` |
| `{{WALLET_PROVIDER_PATH}}` | Full path to the TRON provider object | `window.backpack.tron` |
| `{{WALLET_IS_FIELD}}` | Boolean identity flag on the provider | `isBackpack` |

## How to Find Wallet-Specific Values

1. **injection / provider path**: Open the browser console with the wallet installed and inspect `Object.keys(window)` for the wallet's namespace, then drill into it to find the TRON provider object
2. **isField**: Check `window.tron` (and the provider object itself) for an `isXxx` boolean property
3. Confirm the provider exposes `request()` and which `tron_*` methods it supports via the wallet's developer documentation

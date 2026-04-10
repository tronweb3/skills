# utils.ts Template — EVM Wallet Adapter

Provider detection and mobile utilities.

```typescript
import type { EIP1193Provider } from '@tronweb3/abstract-adapter-evm';

export const {{WALLET_CLASS_UPPER}}_RDNS = '{{WALLET_RDNS}}';

export interface {{WALLET_CLASS}}Provider extends EIP1193Provider {
    {{WALLET_IS_FIELD}}?: boolean;
}

function is{{WALLET_CLASS}}Provider(provider: EIP1193Provider | null | undefined): provider is {{WALLET_CLASS}}Provider {
    return Boolean(provider && (provider as {{WALLET_CLASS}}Provider).{{WALLET_IS_FIELD}});
}

export function get{{WALLET_CLASS}}Provider(): {{WALLET_CLASS}}Provider | null {
    if (typeof window === 'undefined') {
        return null;
    }

    const context = window as Window & {
        {{WALLET_INJECTION_KEY}}?: {{WALLET_CLASS}}Provider;
        ethereum?: {{WALLET_CLASS}}Provider & { providers?: {{WALLET_CLASS}}Provider[] };
    };

    // Check wallet's own injected object first
    if (is{{WALLET_CLASS}}Provider(context.{{WALLET_INJECTION_KEY}})) {
        return context.{{WALLET_INJECTION_KEY}};
    }

    // Fallback: check window.ethereum and its providers array
    const providers = [context.ethereum, ...(context.ethereum?.providers || [])].filter(
        Boolean
    ) as {{WALLET_CLASS}}Provider[];
    return providers.find((provider) => is{{WALLET_CLASS}}Provider(provider)) || null;
}

export function is{{WALLET_CLASS}}MobileWebView(): boolean {
    if (typeof window === 'undefined') {
        return false;
    }
    const context = window as Window & {
        {{WALLET_INJECTION_KEY}}?: {{WALLET_CLASS}}Provider;
    };
    return is{{WALLET_CLASS}}Provider(context.{{WALLET_INJECTION_KEY}});
}

export function open{{WALLET_CLASS}}WithDeeplink(): void {
    if (typeof window === 'undefined') {
        return;
    }
    const encodedUrl = encodeURIComponent(window.location.href);
    const link = `{{WALLET_DEEPLINK}}${encodedUrl}`;
    window.location.href = link;
}
```

## Variable Mapping

| Placeholder | Meaning | Example (OKXWallet) |
|-------------|---------|---------------------|
| `{{WALLET_CLASS_UPPER}}` | SCREAMING_SNAKE for constant | `OKX_WALLET` |
| `{{WALLET_CLASS}}` | PascalCase for functions/classes | `OkxWallet` |
| `{{WALLET_IS_FIELD}}` | Boolean field on provider | `isOkxWallet` |
| `{{WALLET_INJECTION_KEY}}` | Property on `window` (no `window.` prefix) | `okxwallet` |
| `{{WALLET_RDNS}}` | EIP-6963 reverse domain name | `com.okex.wallet` |
| `{{WALLET_DEEPLINK}}` | Mobile deeplink URL prefix | `okx://wallet/dapp/url?dappUrl=` |

## How to Find Wallet-Specific Values

1. **rdns**: Check the wallet's official docs or search for their EIP-6963 announcement event
2. **injection**: Open browser console with wallet installed, check `Object.keys(window)` for wallet-specific objects
3. **isField**: Check `window.<injection>.isXxx` properties
4. **DeepLink**: Check wallet's developer documentation for mobile linking

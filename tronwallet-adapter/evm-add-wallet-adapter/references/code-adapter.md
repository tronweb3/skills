# adapter.ts Template — EVM Wallet Adapter

This is the main adapter implementation. Replace all `{{...}}` placeholders.

```typescript
import type { EIP1193Provider, EIP6963ProviderInfo, TypedData } from '@tronweb3/abstract-adapter-evm';
import {
    Adapter,
    WalletReadyState,
    WalletNotFoundError,
    WalletConnectionError,
    WalletDisconnectedError,
    isInMobileBrowser,
    isInBrowser,
} from '@tronweb3/abstract-adapter-evm';
import { {{WALLET_CLASS}}EvmAdapterName, METADATA } from './metadata.js';
import { get{{WALLET_CLASS}}Provider, is{{WALLET_CLASS}}MobileWebView, {{WALLET_CLASS_UPPER}}_RDNS, open{{WALLET_CLASS}}WithDeeplink } from './utils.js';

declare global {
    interface Window {
        {{WALLET_INJECTION_KEY}}: EIP1193Provider;
    }
}

export interface {{WALLET_CLASS}}EvmAdapterOptions {
    useDeeplink?: boolean;
    openUrlWhenWalletNotFound?: boolean;
}

export { {{WALLET_CLASS}}EvmAdapterName } from './metadata.js';

export class {{WALLET_CLASS}}EvmAdapter extends Adapter {
    name = METADATA.name;
    url = METADATA.url;
    icon = METADATA.icon;
    readyState = WalletReadyState.Loading;
    address: string | null = null;
    connecting = false;
    options: {{WALLET_CLASS}}EvmAdapterOptions;

    constructor(options: {{WALLET_CLASS}}EvmAdapterOptions = { useDeeplink: true }) {
        super();
        this.options = options;
        this.eip6963Info.support = true;
        this.eip6963Info.name = '{{WALLET_NAME}}';
        this.eip6963Info.rdns = {{WALLET_CLASS_UPPER}}_RDNS;

        void this.getProvider().then((provider) => {
            if (provider) {
                this.readyState = WalletReadyState.Found;
                this.listenEvents(provider);
                void this.autoConnect(provider);
            } else {
                this.readyState = WalletReadyState.NotFound;
            }
            this.emit('readyStateChanged', this.readyState);
        });
    }

    async connect() {
        if (this.options.useDeeplink !== false) {
            if (isInMobileBrowser() && !is{{WALLET_CLASS}}MobileWebView()) {
                open{{WALLET_CLASS}}WithDeeplink();
                return '';
            }
        }
        this.connecting = true;

        try {
            const provider = await this.getProvider();
            if (!provider) {
                if (this.options.openUrlWhenWalletNotFound !== false && isInBrowser()) {
                    window.open(this.url, '_blank');
                }
                throw new WalletNotFoundError();
            }
            const accounts = await provider.request<undefined, string[]>({ method: 'eth_requestAccounts' });
            if (!accounts.length) {
                throw new WalletConnectionError('No accounts is available.');
            }
            this.address = accounts[0];
            return this.address as string;
        } finally {
            this.connecting = false;
        }
    }

    async signTypedData({
        typedData,
        address = this.address as string,
    }: {
        typedData: TypedData;
        address?: string;
    }): Promise<string> {
        const provider = await this.prepareProvider();
        if (!this.connected) {
            throw new WalletDisconnectedError();
        }
        return provider.request<[string, string], string>({
            method: 'eth_signTypedData_v4',
            params: [address, typeof typedData === 'string' ? typedData : JSON.stringify(typedData)],
        });
    }

    protected isEIP6963Provider(provider: EIP1193Provider, info?: EIP6963ProviderInfo): boolean {
        if (!info?.rdns) {
            return false;
        }
        return info.rdns === {{WALLET_CLASS_UPPER}}_RDNS;
    }

    protected getInjectedProvider(): EIP1193Provider | null {
        return get{{WALLET_CLASS}}Provider();
    }

    async getProvider(): Promise<EIP1193Provider | null> {
        if (typeof window === 'undefined') {
            return null;
        }

        if (isInMobileBrowser()) {
            if (!is{{WALLET_CLASS}}MobileWebView()) {
                return null;
            }
            return this.getInjectedProvider();
        }

        if (this.getProviderPromise !== null) {
            return this.getProviderPromise;
        }

        this.getProviderPromise = new Promise((resolve) => {
            let handled = false;
            let timeout: ReturnType<typeof setTimeout> | null = null;
            let eip6963Handler: ((event: Event) => void) | null = null;

            const cleanup = () => {
                if (timeout) {
                    clearTimeout(timeout);
                    timeout = null;
                }
                if (eip6963Handler) {
                    window.removeEventListener('eip6963:announceProvider', eip6963Handler);
                    eip6963Handler = null;
                }
            };

            const finish = (nextProvider: EIP1193Provider | null) => {
                if (handled) {
                    return;
                }
                handled = true;
                cleanup();
                resolve(nextProvider);
            };

            eip6963Handler = (event: Event) => {
                const customEvent = event as CustomEvent<{
                    info?: EIP6963ProviderInfo;
                    provider?: EIP1193Provider;
                }>;
                const announcedProvider = customEvent.detail?.provider;
                if (!announcedProvider || !this.isEIP6963Provider(announcedProvider, customEvent.detail?.info)) {
                    return;
                }
                finish(announcedProvider);
            };

            window.addEventListener('eip6963:announceProvider', eip6963Handler);
            window.dispatchEvent(new Event('eip6963:requestProvider'));

            timeout = setTimeout(() => {
                finish(null);
            }, 3000);
        });

        return this.getProviderPromise;
    }
}
```

## Key Points

1. **Metadata extraction**: Wallet identity (name, url, icon) is defined in `metadata.ts` and imported via `METADATA` object. The adapter name is re-exported for external consumers.
2. **`signTypedData` must JSON.stringify**: All EVM adapters in this monorepo stringify `typedData` before sending to `eth_signTypedData_v4`.
3. **EIP-6963 with timeout**: Desktop discovery uses 3-second timeout. If no matching provider announces, readyState becomes `NotFound`.
4. **Mobile WebView**: On mobile, skip EIP-6963 and check injected provider directly.
5. **DeepLink**: If in mobile browser but NOT in wallet's WebView, redirect to wallet app via deeplink.
6. **`getProviderPromise` caching**: The `getProvider()` result is cached via `this.getProviderPromise` (inherited from `Adapter` base class).

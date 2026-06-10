# adapter.ts Template — TRON Wallet Adapter (Archetype B: Provider Request-Based)

This is the main adapter implementation for a wallet that injects a modern request-based provider (source of truth: `packages/adapters/backpack/src/adapter.ts`). Replace all `{{...}}` placeholders.

```typescript
import {
    Adapter,
    AdapterState,
    isInBrowser,
    NetworkType,
    WalletConnectionError,
    WalletDisconnectedError,
    WalletError,
    WalletGetNetworkError,
    WalletNotFoundError,
    WalletReadyState,
    WalletSignMessageError,
    WalletSignTransactionError,
    WalletSwitchChainError,
    type AdapterName,
    type BaseAdapterConfig,
    type Network,
    type SignedTransaction,
    type Transaction,
} from '@tronweb3/tronwallet-abstract-adapter';
import { get{{WALLET_CLASS}}Provider, support{{WALLET_CLASS}}, type {{WALLET_CLASS}}TronProvider } from './utils.js';

const chainIdNetworkMap: Record<string, NetworkType> = {
    '0x2b6653dc': NetworkType.Mainnet,
    '0x94a9059e': NetworkType.Shasta,
    '0xcd8690dc': NetworkType.Nile,
};

export interface {{WALLET_CLASS}}AdapterConfig extends BaseAdapterConfig {
    /**
     * Timeout in milliseconds for checking if {{WALLET_NAME}} exists.
     * Default is 2000ms
     */
    checkTimeout?: number;
}

export const {{WALLET_CLASS}}AdapterName = '{{WALLET_NAME}}' as AdapterName<'{{WALLET_NAME}}'>;

export class {{WALLET_CLASS}}Adapter extends Adapter {
    readonly name = {{WALLET_CLASS}}AdapterName;
    readonly url = '{{WALLET_URL}}';
    readonly icon = '{{WALLET_ICON}}';

    config: Required<{{WALLET_CLASS}}AdapterConfig>;
    private _readyState: WalletReadyState = isInBrowser() ? WalletReadyState.Loading : WalletReadyState.NotFound;
    private _state: AdapterState = isInBrowser() ? AdapterState.Loading : AdapterState.NotFound;
    private _connecting = false;
    private _wallet: {{WALLET_CLASS}}TronProvider | null = null;
    private _address: string | null = null;

    constructor(config: {{WALLET_CLASS}}AdapterConfig = {}) {
        super();
        const { checkTimeout = 2000, openUrlWhenWalletNotFound = true } = config;

        if (typeof checkTimeout !== 'number') {
            throw new Error('[{{WALLET_CLASS}}Adapter] config.checkTimeout should be a number');
        }

        this.config = {
            checkTimeout,
            openUrlWhenWalletNotFound,
        };

        if (support{{WALLET_CLASS}}()) {
            this._readyState = WalletReadyState.Found;
            this._updateWallet();
        } else {
            this._checkWallet();
        }
    }

    get state(): AdapterState {
        return this._state;
    }

    get address(): string | null {
        return this._address;
    }

    get readyState(): WalletReadyState {
        return this._readyState;
    }

    get connecting(): boolean {
        return this._connecting;
    }

    async connect(): Promise<void> {
        try {
            if (this.connected || this._connecting) {
                return;
            }

            await this._checkWallet();

            if (this._state === AdapterState.NotFound) {
                if (this.config.openUrlWhenWalletNotFound && isInBrowser()) {
                    window.open(this.url, '_blank');
                }
                throw new WalletNotFoundError();
            }

            if (!this._wallet) {
                throw new WalletNotFoundError();
            }

            this._connecting = true;

            try {
                const accounts = (await this._wallet.request({
                    method: 'tron_requestAccounts',
                })) as string[];

                const address = accounts?.[0];
                if (!address) {
                    throw new WalletConnectionError('No address returned from {{WALLET_NAME}} wallet.');
                }

                this._setAddress(address);
                this._setState(AdapterState.Connected);
                this._listenProviderEvents();
            } catch (error: any) {
                if (error?.code === 4001) {
                    throw new WalletConnectionError('The user rejected connection.');
                }
                throw new WalletConnectionError(error?.message || 'Failed to connect to {{WALLET_NAME}} wallet.', error);
            }

            this.emit('connect', this._address!);
        } catch (error: any) {
            this.emit('error', error);
            throw error;
        } finally {
            this._connecting = false;
        }
    }

    async disconnect(): Promise<void> {
        this._stopListenProviderEvents();

        if (this._state !== AdapterState.Connected) {
            return;
        }

        try {
            if (this._wallet?.disconnect) {
                await this._wallet.disconnect();
            }
        } catch {
            // Ignore disconnect errors
        }

        this._setAddress(null);
        this._setState(AdapterState.Disconnect);
        this.emit('disconnect');
    }

    async signMessage(message: string): Promise<string> {
        try {
            const wallet = this._checkConnected();

            try {
                return (await wallet.request({
                    method: 'tron_signMessage',
                    params: { message },
                })) as string;
            } catch (error: any) {
                throw new WalletSignMessageError(error?.message || 'Failed to sign message.', error);
            }
        } catch (error: any) {
            this.emit('error', error);
            throw error;
        }
    }

    async signTransaction(transaction: Transaction): Promise<SignedTransaction> {
        try {
            const wallet = this._checkConnected();
            try {
                return (await wallet.request({
                    method: 'tron_signTransaction',
                    params: { transaction },
                })) as SignedTransaction;
            } catch (error: any) {
                throw new WalletSignTransactionError(error?.message || 'Failed to sign transaction.', error);
            }
        } catch (error: any) {
            this.emit('error', error);
            throw error;
        }
    }

    async multiSign(): Promise<unknown> {
        // Implement this for real if the wallet supports multi-sign — check the Phase 1 feature matrix.
        throw new WalletSignTransactionError('Multi-sign method not implemented for {{WALLET_NAME}} wallet.');
    }

    /**
     * Switch to target chain. If current chain is the same as target chain, the call will success immediately.
     * Available chainIds:
     * - Mainnet: 0x2b6653dc
     * - Shasta: 0x94a9059e
     * - Nile: 0xcd8690dc
     * @param chainId chainId
     */
    async switchChain(chainId: string): Promise<void> {
        try {
            const wallet = this._checkConnected();
            await wallet.request({
                method: 'tron_switchChain',
                params: { chainId: `tron:${parseInt(chainId, 16).toString()}` },
            });
            this.emit('chainChanged', { chainId });
        } catch (error: any) {
            const err =
                error instanceof WalletError
                    ? error
                    : new WalletSwitchChainError(
                          error?.message
                              ? error.message.replace(
                                    /tron:(\d+)/g,
                                    (_: string, p1: string) => `0x${parseInt(p1, 10).toString(16)}`
                                )
                              : 'Failed to switch chain.',
                          error
                      );

            this.emit('error', err);
            throw err;
        }
    }

    async network(): Promise<Network> {
        try {
            const wallet = this._checkConnected();
            const chainId = (await wallet.request({ method: 'tron_chainId' })) as string;
            return {
                networkType: chainIdNetworkMap[chainId] || NetworkType.Unknown,
                chainId,
                fullNode: '',
                solidityNode: '',
                eventServer: '',
            };
        } catch (error: any) {
            const err =
                error instanceof WalletError
                    ? error
                    : new WalletGetNetworkError(error?.message || 'Failed to get network.', error);
            this.emit('error', err);
            throw err;
        }
    }

    private _checkConnected(): {{WALLET_CLASS}}TronProvider {
        if (!this._wallet || !this.connected) {
            throw new WalletDisconnectedError();
        }
        return this._wallet;
    }

    private _checkPromise: Promise<boolean> | null = null;

    private _checkWallet(): Promise<boolean> {
        if (this._readyState === WalletReadyState.Found) {
            return Promise.resolve(true);
        }
        if (this._checkPromise) {
            return this._checkPromise;
        }

        const interval = 100;
        const maxTimes = Math.floor(this.config.checkTimeout / interval);
        let times = 0;
        let timer: ReturnType<typeof setInterval>;

        this._checkPromise = new Promise((resolve) => {
            const check = () => {
                times++;
                const isSupport = support{{WALLET_CLASS}}();
                if (isSupport || times > maxTimes) {
                    timer && clearInterval(timer);
                    this._readyState = isSupport ? WalletReadyState.Found : WalletReadyState.NotFound;
                    this._updateWallet();
                    this.emit('readyStateChanged', this._readyState);
                    resolve(isSupport);
                }
            };
            timer = setInterval(check, interval);
            check();
        });

        return this._checkPromise;
    }

    private _updateWallet(): void {
        const provider = get{{WALLET_CLASS}}Provider();

        if (provider) {
            this._wallet = provider;
            this._listenProviderEvents();

            // Check for existing connection
            this._checkExistingConnection();
        } else {
            this._wallet = null;
            this._setAddress(null);
            this._setState(AdapterState.NotFound);
        }
    }

    private async _checkExistingConnection(): Promise<void> {
        if (!this._wallet) return;
        try {
            const accounts = (await this._wallet.request({
                method: 'tron_accounts',
            })) as string[];
            this._onAccountsChanged(accounts);
        } catch (e: any) {
            console.error(`[{{WALLET_CLASS}}Adapter] check existing connection error: `, e);
            // On error, assume disconnected
            this._onAccountsChanged([]);
        }
    }

    private _listenProviderEvents(): void {
        this._stopListenProviderEvents();
        try {
            this._wallet?.on?.('accountsChanged', this._onAccountsChanged);
            this._wallet?.on?.('chainChanged', this._onChainChanged);
        } catch {
            // do nothing
        }
    }

    private _stopListenProviderEvents(): void {
        try {
            this._wallet?.removeListener?.('accountsChanged', this._onAccountsChanged);
            this._wallet?.removeListener?.('chainChanged', this._onChainChanged);
        } catch {
            // do nothing
        }
    }

    private _onAccountsChanged = (accounts: string[]) => {
        const prevAddress = this._address;
        const newAddress = accounts?.[0] || null;
        this._setAddress(newAddress);
        this._setState(newAddress ? AdapterState.Connected : AdapterState.Disconnect);
        this.emit('accountsChanged', newAddress || '', prevAddress || '');
        if (prevAddress && !newAddress) {
            this.emit('disconnect');
        } else if (!prevAddress && newAddress) {
            this.emit('connect', newAddress);
        }
    };

    private _onChainChanged = (chainData: unknown) => {
        const chainId = typeof chainData === 'string' ? chainData : (chainData as { chainId?: string })?.chainId || '';
        this.emit('chainChanged', { chainId });
    };

    private _setAddress(address: string | null): void {
        this._address = address;
    }

    private _setState(state: AdapterState): void {
        if (this._state !== state) {
            this._state = state;
            this.emit('stateChanged', state);
        }
    }
}
```

## Key Points

1. **`tron_*` request method catalogue**: The entire wallet API goes through `provider.request({ method, params })`:
   - `tron_accounts` — silent query of already-authorized accounts (no popup); used for auto-connect detection.
   - `tron_requestAccounts` — interactive connect; error `code === 4001` means the user rejected and is mapped to `WalletConnectionError('The user rejected connection.')`.
   - `tron_signMessage` — params `{ message }`, returns the signature string.
   - `tron_signTransaction` — params `{ transaction }`, returns the `SignedTransaction`.
   - `tron_chainId` — returns the current chainId as a hex string.
   - `tron_switchChain` — params `{ chainId: 'tron:<decimal>' }` (hex chainId is translated to a `tron:`-prefixed decimal); error messages containing `tron:<decimal>` are rewritten back to hex so callers see the chainId format they passed in.
2. **chainId → NetworkType map**: `chainIdNetworkMap` is fixed for TRON: Mainnet `0x2b6653dc`, Shasta `0x94a9059e`, Nile `0xcd8690dc`; anything else maps to `NetworkType.Unknown`. `network()` calls `tron_chainId` and resolves through this map (fullNode/solidityNode/eventServer are empty strings — the provider does not expose node URLs).
3. **Auto-connect via `tron_accounts`**: `_updateWallet()` calls `_checkExistingConnection()` once the provider is found. If the dapp was previously authorized, `_onAccountsChanged` transitions the adapter to `Connected` without any user prompt; on error it assumes disconnected with an empty account list.
4. **Abstract-adapter-only dependency**: Unlike Archetype A (TronLink-compatible), this archetype imports nothing from `@tronweb3/tronwallet-adapter-tronlink`. Everything comes from `@tronweb3/tronwallet-abstract-adapter` plus the local `./utils.js`.
5. **Zero-arg constructor requirement**: `new {{WALLET_CLASS}}Adapter()` must work with no arguments — `config` defaults to `{}` with `checkTimeout = 2000` and `openUrlWhenWalletNotFound = true`, and `checkTimeout` is type-guarded with a `[{{WALLET_CLASS}}Adapter]`-prefixed error. Demos and `WalletProvider` instantiate adapters without arguments.
6. **Cached `_checkPromise` polling**: `_checkWallet()` polls `support{{WALLET_CLASS}}()` every 100ms up to `checkTimeout`, caches the in-flight promise so concurrent `connect()` calls share one detection pass, and emits `readyStateChanged` exactly once when detection settles.
7. **Provider event wiring**: `accountsChanged`/`chainChanged` listeners are attached with optional chaining (`on?.`/`removeListener?.`) since these are optional on the provider; `_listenProviderEvents()` always detaches first to avoid duplicate handlers. `_onAccountsChanged` derives connect/disconnect emissions from the previous/new address pair.
8. **`multiSign()` stub**: throws `WalletSignTransactionError` by default. Implement it for real only if the wallet supports multi-sign — check the Phase 1 feature matrix.

## Variable Mapping

| Placeholder | Meaning | Example (Backpack) |
|-------------|---------|--------------------|
| `{{WALLET_CLASS}}` | PascalCase prefix for class/const/function names | `Backpack` |
| `{{WALLET_NAME}}` | Display name; becomes the `AdapterName` string | `Backpack` |
| `{{WALLET_URL}}` | Official wallet URL, opened when wallet not found | `https://backpack.app` |
| `{{WALLET_ICON}}` | base64 data-URI icon | `data:image/svg+xml;base64,...` |

# adapter.ts Template — TRON Wallet Adapter (Archetype A: TronLink-compatible)

This is the main adapter implementation for TronLink-compatible wallets (the wallet injects `window.{{WALLET_INJECTION_KEY}}.tronLink` shaped like `TronLinkWallet`). It is derived verbatim from `packages/adapters/bybit/src/adapter.ts`. Replace all `{{...}}` placeholders.

```typescript
import {
    Adapter,
    AdapterState,
    isInBrowser,
    WalletReadyState,
    WalletSignMessageError,
    WalletNotFoundError,
    WalletDisconnectedError,
    WalletConnectionError,
    WalletSignTransactionError,
    WalletGetNetworkError,
} from '@tronweb3/tronwallet-abstract-adapter';
import type {
    Transaction,
    SignedTransaction,
    AdapterName,
    BaseAdapterConfig,
    Network,
} from '@tronweb3/tronwallet-abstract-adapter';
import type {
    AccountsChangedEventData,
    TronLinkMessageEvent,
    TronLinkWallet,
} from '@tronweb3/tronwallet-adapter-tronlink';
import { getNetworkInfoByTronWeb } from '@tronweb3/tronwallet-adapter-tronlink';
import { open{{WALLET_CLASS}}, support{{WALLET_CLASS}} } from './utils.js';

declare global {
    interface Window {
        {{WALLET_INJECTION_KEY}}?: {
            tronLink: TronLinkWallet;
        };
    }
}
export interface {{WALLET_CLASS}}AdapterConfig extends BaseAdapterConfig {
    /**
     * Timeout in millisecond for checking if {{WALLET_NAME}} wallet exists.
     * Default is 2 * 1000ms
     */
    checkTimeout?: number;
    /**
     * Set if open {{WALLET_NAME}} app using DeepLink.
     * Default is true.
     */
    openAppWithDeeplink?: boolean;
}

export const {{WALLET_CLASS}}AdapterName = '{{WALLET_NAME}}' as AdapterName<'{{WALLET_NAME}}'>;

export class {{WALLET_CLASS}}Adapter extends Adapter {
    name = {{WALLET_CLASS}}AdapterName;
    url = '{{WALLET_URL}}';
    icon = '{{WALLET_ICON}}';

    config: Required<{{WALLET_CLASS}}AdapterConfig>;
    private _readyState: WalletReadyState = isInBrowser() ? WalletReadyState.Loading : WalletReadyState.NotFound;
    private _state: AdapterState = AdapterState.Loading;
    private _connecting: boolean;
    private _wallet: TronLinkWallet | null;
    private _address: string | null;

    constructor(config: {{WALLET_CLASS}}AdapterConfig = {}) {
        super();
        const { checkTimeout = 2 * 1000, openUrlWhenWalletNotFound = true, openAppWithDeeplink = true } = config;
        if (typeof checkTimeout !== 'number') {
            throw new Error('[{{WALLET_CLASS}}Adapter] config.checkTimeout should be a number');
        }
        this.config = {
            checkTimeout,
            openAppWithDeeplink,
            openUrlWhenWalletNotFound,
        };
        this._connecting = false;
        this._wallet = null;
        this._address = null;

        if (!isInBrowser()) {
            this._readyState = WalletReadyState.NotFound;
            this.setState(AdapterState.NotFound);
            return;
        }
        if (support{{WALLET_CLASS}}()) {
            this._readyState = WalletReadyState.Found;
            this._updateWallet();
        } else {
            this._checkWallet().then(() => {
                if (this.connected) {
                    this.emit('connect', this.address || '');
                }
            });
        }
    }

    get address() {
        return this._address;
    }

    get state() {
        return this._state;
    }
    get readyState() {
        return this._readyState;
    }

    get connecting() {
        return this._connecting;
    }

    /**
     * Get network information used by {{WALLET_NAME}}.
     * @returns {Network} Current network information.
     */
    async network(): Promise<Network> {
        try {
            await this._checkWallet();
            if (this.state !== AdapterState.Connected) throw new WalletDisconnectedError();
            const wallet = this._wallet;
            if (!wallet || !wallet.tronWeb) throw new WalletDisconnectedError();
            try {
                return await getNetworkInfoByTronWeb(wallet.tronWeb);
            } catch (e: any) {
                throw new WalletGetNetworkError(e?.message, e);
            }
        } catch (e: any) {
            this.emit('error', e);
            throw e;
        }
    }

    async connect(): Promise<void> {
        try {
            this.checkIfOpen{{WALLET_CLASS}}();
            if (this.connected || this.connecting) return;
            await this._checkWallet();
            if (this.state === AdapterState.NotFound) {
                if (this.config.openUrlWhenWalletNotFound !== false && isInBrowser()) {
                    window.open(this.url, '_blank');
                }
                throw new WalletNotFoundError();
            }
            if (!this._wallet) return;
            this._connecting = true;
            const wallet = this._wallet as TronLinkWallet;
            try {
                const res = await wallet.request({ method: 'tron_requestAccounts' });
                if (!res) {
                    throw new WalletConnectionError('Request connect error.');
                }
                if (res.code === 4000) {
                    throw new WalletConnectionError(
                        'The same DApp has already initiated a request to connect to {{WALLET_NAME}}, and the pop-up window has not been closed.'
                    );
                }
                if (res.code === 4001) {
                    throw new WalletConnectionError('The user rejected connection.');
                }
            } catch (error: any) {
                throw new WalletConnectionError(error?.message, error);
            }

            const address = wallet.tronWeb.defaultAddress?.base58 || '';
            this.setAddress(address);
            this.setState(AdapterState.Connected);
            this._listenEvent();
            this.connected && this.emit('connect', this.address || '');
        } catch (error: any) {
            this.emit('error', error);
            throw error;
        } finally {
            this._connecting = false;
        }
    }

    async disconnect(): Promise<void> {
        this._stopListenEvent();
        if (this.state !== AdapterState.Connected) {
            return;
        }
        this.setAddress(null);
        this.setState(AdapterState.Disconnect);
        this.emit('disconnect');
    }

    async signTransaction(transaction: Transaction): Promise<SignedTransaction> {
        try {
            const wallet = await this.checkAndGetWallet();

            try {
                return await wallet.tronWeb.trx.sign(transaction);
            } catch (error: any) {
                if (error instanceof Error || (typeof error === 'object' && error.message)) {
                    throw new WalletSignTransactionError(error.message, error);
                } else if (typeof error === 'string') {
                    throw new WalletSignTransactionError(error, new Error(error));
                } else {
                    throw new WalletSignTransactionError('Unknown error', error);
                }
            }
        } catch (error: any) {
            this.emit('error', error);
            throw error;
        }
    }

    async multiSign(transaction: Transaction, options: { permissionId?: number } = {}): Promise<SignedTransaction> {
        try {
            const wallet = await this.checkAndGetWallet();

            try {
                return await wallet.tronWeb.trx.multiSign(transaction, undefined, options.permissionId);
            } catch (error: any) {
                if (error instanceof Error || (typeof error === 'object' && error.message)) {
                    throw new WalletSignTransactionError(error.message, error);
                } else if (typeof error === 'string') {
                    throw new WalletSignTransactionError(error, new Error(error));
                } else {
                    throw new WalletSignTransactionError('Unknown error', error);
                }
            }
        } catch (error: any) {
            this.emit('error', error);
            throw error;
        }
    }

    async signMessage(message: string): Promise<string> {
        try {
            const wallet = await this.checkAndGetWallet();
            try {
                return await wallet.tronWeb.trx.signMessageV2(message);
            } catch (error: any) {
                if (error instanceof Error || (typeof error === 'object' && error.message)) {
                    throw new WalletSignMessageError(error.message, error);
                } else if (typeof error === 'string') {
                    throw new WalletSignMessageError(error, new Error(error));
                } else {
                    throw new WalletSignMessageError('Unknown error', error);
                }
            }
        } catch (error: any) {
            this.emit('error', error);
            throw error;
        }
    }

    private async checkAndGetWallet() {
        this.checkIfOpen{{WALLET_CLASS}}();
        await this._checkWallet();
        if (this.state !== AdapterState.Connected) throw new WalletDisconnectedError();
        const wallet = this._wallet;
        if (!wallet || !wallet.tronWeb) throw new WalletDisconnectedError();
        return wallet as TronLinkWallet;
    }

    private _listenEvent() {
        this._stopListenEvent();
        window.addEventListener('message', this.messageHandler);
    }

    private _stopListenEvent() {
        window.removeEventListener('message', this.messageHandler);
    }

    private messageHandler = (e: TronLinkMessageEvent) => {
        const message = e.data?.message;
        if (!message) {
            return;
        }
        if (message.action === 'accountsChanged') {
            setTimeout(() => {
                const preAddr = this.address || '';
                if ((this._wallet as TronLinkWallet)?.ready) {
                    const address = (message.data as AccountsChangedEventData).address;
                    this.setAddress(address);
                    this.setState(AdapterState.Connected);
                } else {
                    this.setAddress(null);
                    this.setState(AdapterState.Disconnect);
                }
                const address = this.address || '';
                if (address !== preAddr) {
                    this.emit('accountsChanged', this.address || '', preAddr);
                }
                if (!preAddr && this.address) {
                    this.emit('connect', this.address);
                } else if (preAddr && !this.address) {
                    this.emit('disconnect');
                }
            }, 200);
        } else if (message.action === 'connect') {
            const isCurConnected = this.connected;
            const preAddress = this.address || '';
            const address = (this._wallet as TronLinkWallet).tronWeb?.defaultAddress?.base58 || '';
            this.setAddress(address);
            this.setState(AdapterState.Connected);
            if (!isCurConnected) {
                this.emit('connect', address);
            } else if (address !== preAddress) {
                this.emit('accountsChanged', this.address || '', preAddress);
            }
        } else if (message.action === 'disconnect') {
            this.setAddress(null);
            this.setState(AdapterState.Disconnect);
            this.emit('disconnect');
        }
    };

    private checkIfOpen{{WALLET_CLASS}}() {
        if (this.config.openAppWithDeeplink === false) {
            return;
        }
        if (open{{WALLET_CLASS}}()) {
            throw new WalletNotFoundError();
        }
    }

    private _checkPromise: Promise<boolean> | null = null;
    /**
     * check if wallet exists by interval, the promise only resolve when wallet detected or timeout
     * @returns if {{WALLET_NAME}} exists
     */
    private _checkWallet(): Promise<boolean> {
        if (this.readyState === WalletReadyState.Found) {
            return Promise.resolve(true);
        }
        if (this._checkPromise) {
            return this._checkPromise;
        }
        const interval = 100;
        const maxTimes = Math.floor(this.config.checkTimeout / interval);
        let times = 0,
            timer: ReturnType<typeof setInterval>;
        this._checkPromise = new Promise((resolve) => {
            const check = () => {
                times++;
                const isSupport = support{{WALLET_CLASS}}();
                if (isSupport || times > maxTimes) {
                    timer && clearInterval(timer);
                    this._readyState = isSupport ? WalletReadyState.Found : WalletReadyState.NotFound;
                    this._updateWallet();
                    this.emit('readyStateChanged', this.readyState);
                    resolve(isSupport);
                }
            };
            timer = setInterval(check, interval);
            check();
        });
        return this._checkPromise;
    }

    private _updateWallet = () => {
        let state = this.state;
        let address = this.address;
        if (support{{WALLET_CLASS}}()) {
            this._wallet = window.{{WALLET_INJECTION_KEY}}!.tronLink;
            this._listenEvent();
            address = this._wallet.tronWeb?.defaultAddress?.base58 || null;
            state = this._wallet.ready ? AdapterState.Connected : AdapterState.Disconnect;
        } else {
            this._wallet = null;
            address = null;
            state = AdapterState.NotFound;
        }
        this.setAddress(address);
        this.setState(state);
    };

    private setAddress(address: string | null) {
        this._address = address;
    }

    private setState(state: AdapterState) {
        const preState = this.state;
        if (state !== preState) {
            this._state = state;
            this.emit('stateChanged', state);
        }
    }
}
```

## Key Points

1. **Dependency on `@tronweb3/tronwallet-adapter-tronlink`**: TronLink-compatible wallets inject the exact same provider shape as TronLink (`.tronWeb`, `.ready`, `.request({ method: 'tron_requestAccounts' })`). Instead of duplicating types and network detection, the adapter imports `TronLinkWallet` / `TronLinkMessageEvent` / `AccountsChangedEventData` types and the `getNetworkInfoByTronWeb()` helper from the tronlink adapter package. Add it to `dependencies` in `package.json` alongside `@tronweb3/tronwallet-abstract-adapter`.
2. **The 200ms defer on `accountsChanged`**: When the wallet posts an `accountsChanged` message, the injected object's `ready` flag and `tronWeb.defaultAddress` may not be updated yet. Deferring the handler by 200ms with `setTimeout` lets the injected state settle, so the adapter reads accurate `ready`/address values before emitting `accountsChanged` / `connect` / `disconnect`.
3. **`res.code 4000` / `4001` in `connect()`**: `tron_requestAccounts` resolves with a status object rather than rejecting. Code `4000` means the same DApp already has a pending connection popup that has not been closed (duplicate request); code `4001` means the user explicitly rejected the connection. A falsy `res` is also a connection error. All three are wrapped in `WalletConnectionError`.
4. **Polling detection, not announcement events**: TRON wallets have no EIP-6963/TIP-6963-style provider-announcement protocol, and wallet injection timing is non-deterministic (extensions often inject after the adapter is constructed). Detection polls `support{{WALLET_CLASS}}()` every 100ms up to `config.checkTimeout` (default 2000ms). The cached `_checkPromise` ensures concurrent callers share a single poll, and the promise resolves as soon as the wallet is found or the timeout is reached, emitting `readyStateChanged`.
5. **Zero-arg constructor requirement**: Every config field has a default (`checkTimeout = 2000`, `openUrlWhenWalletNotFound = true`, `openAppWithDeeplink = true`) and `config` itself defaults to `{}`, so `new {{WALLET_CLASS}}Adapter()` must work with no arguments. This is required because the adapter is instantiated argument-free in the demo apps and adapter lists. `checkTimeout` is type-guarded with an explicit runtime check that throws if it is not a number.
6. **Deeplink guard (`checkIfOpen{{WALLET_CLASS}}`)**: Both `connect()` and `checkAndGetWallet()` first call the deeplink guard. In a mobile browser that is NOT the wallet's in-app browser, `open{{WALLET_CLASS}}()` redirects to the wallet app via deeplink and returns `true`, in which case the adapter throws `WalletNotFoundError` to halt the current flow. Set `openAppWithDeeplink: false` to disable.
7. **`declare global` Window augmentation lives here**: The `window.{{WALLET_INJECTION_KEY}}` typing is declared in `adapter.ts` (not `utils.ts`), matching the bybit source layout.

## Variable Mapping

| Placeholder | Meaning | Example (Bybit Wallet) |
|-------------|---------|------------------------|
| `{{WALLET_CLASS}}` | PascalCase prefix for class/const/function names | `BybitWallet` |
| `{{WALLET_NAME}}` | Display name, becomes the `AdapterName` string | `Bybit Wallet` |
| `{{WALLET_URL}}` | Official wallet URL opened when wallet not found | `https://bybit.com/web3` |
| `{{WALLET_ICON}}` | Base64 data-URI icon | `data:image/svg+xml;base64,...` |
| `{{WALLET_INJECTION_KEY}}` | Property on `window` holding `{ tronLink: TronLinkWallet }` | `bybitWallet` |

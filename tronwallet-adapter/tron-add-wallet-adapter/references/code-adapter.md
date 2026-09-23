# adapter.ts Template — TRON Wallet Adapter

This is the main adapter implementation. It targets the most common case: a wallet that injects
a **TronLink-compatible provider** at `window.{{WALLET_INJECTION_KEY}}.tronLink` and pushes
`window.postMessage` events for connect/accountsChanged/disconnect (the OkxWallet pattern).

If the target wallet doesn't push events, drop the `messageHandler`/`_listenEvent` block and poll
`wallet.tron.ready` on an interval instead (see `packages/adapters/bitkeep/src/adapter.ts`).
If the provider isn't TronLink-compatible at all, use `packages/adapters/backpack/src/adapter.ts`
as the base instead of this template.

Replace all `{{...}}` placeholders. Field/method names follow the convention used by every
existing TRON adapter in this repo — keep it so the new adapter reads like a sibling, not a
one-off.

```typescript
import {
    AdapterState,
    isInBrowser,
    WalletReadyState,
    WalletSignMessageError,
    WalletNotFoundError,
    WalletDisconnectedError,
    WalletConnectionError,
    WalletSignTransactionError,
    WalletGetNetworkError,
    AddonAdapter,
    WalletError,
    assertConnectAddress,
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

export type {{WALLET_CLASS}}AdapterConfig = BaseAdapterConfig;

export const {{WALLET_CLASS}}AdapterName = '{{WALLET_NAME}}' as AdapterName<'{{WALLET_NAME}}'>;

export class {{WALLET_CLASS}}Adapter extends AddonAdapter {
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
        super(config);
        this.config = {
            ...this.commonConfig,
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
            this._updateWallet().then(() => {
                if (this.connected) {
                    this.emit('connect', this.address || '');
                }
            });
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

    protected async _connect(): Promise<void> {
        try {
            if (!(await this._beforeConnect())) return;
            if (!this._wallet) return;
            this._connecting = true;
            const wallet = this._wallet as TronLinkWallet;
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

            const address = assertConnectAddress(wallet.tronWeb.defaultAddress?.base58);
            this.setAddress(address);
            this.setState(AdapterState.Connected);
            this._listenEvent();
            this.connected && this.emit('connect', this.address || '');
        } catch (error: any) {
            const err = error instanceof WalletError ? error : new WalletConnectionError(error?.message, error);
            this.emit('error', err);
            throw err;
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
        this._eventGeneration++;
        if (this._accountsChangedTimer) {
            clearTimeout(this._accountsChangedTimer);
            this._accountsChangedTimer = null;
        }
        window.removeEventListener('message', this.messageHandler);
    }

    private _accountsChangedTimer: ReturnType<typeof setTimeout> | null = null;
    /**
     * Incremented whenever the listening session ends. Deferred `accountsChanged`
     * work captures the value before it yields and abandons itself if it no longer
     * matches, so an event that started before `disconnect()` cannot write state after it.
     */
    private _eventGeneration = 0;

    private messageHandler = async (e: TronLinkMessageEvent) => {
        if (e.origin !== window.location.origin) {
            return;
        }

        const message = e.data?.message;
        if (!message) {
            return;
        }
        if (message.action === 'accountsChanged') {
            if (this._accountsChangedTimer) {
                clearTimeout(this._accountsChangedTimer);
            }
            const generation = this._eventGeneration;
            this._accountsChangedTimer = setTimeout(() => {
                this._accountsChangedTimer = null;
                if (generation !== this._eventGeneration) return;
                const preAddr = this.address || '';
                const curAddr = (message.data as AccountsChangedEventData).address || '';
                if (curAddr && (this._wallet as TronLinkWallet)?.ready) {
                    this.setAddress(curAddr);
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

    protected _openAppByDeepLinkIfNeed(): boolean {
        if (this.config.openAppWithDeeplink === false) {
            return false;
        }
        return open{{WALLET_CLASS}}();
    }

    private _checkPromise: Promise<boolean> | null = null;
    /**
     * Detection polls for the full `checkTimeout` only once. Later attempts re-check a
     * single time, so retrying is free when the wallet is genuinely absent.
     */
    private _hasRunInitialDetection = false;
    /**
     * check if wallet exists by interval, the promise only resolve when wallet detected or timeout
     * @returns if {{WALLET_NAME}} exists
     */
    protected _checkWallet(): Promise<boolean> {
        if (this.readyState === WalletReadyState.Found) {
            return Promise.resolve(true);
        }
        if (this._checkPromise) {
            return this._checkPromise;
        }
        const interval = 100;
        const maxTimes = this._hasRunInitialDetection ? 0 : Math.floor(this.config.checkTimeout / interval);
        this._hasRunInitialDetection = true;
        let times = 0,
            timer: ReturnType<typeof setInterval>;
        const detection = new Promise<boolean>((resolve) => {
            const check = async () => {
                times++;
                const isSupport = support{{WALLET_CLASS}}();
                if (isSupport || times > maxTimes) {
                    timer && clearInterval(timer);
                    this._readyState = isSupport ? WalletReadyState.Found : WalletReadyState.NotFound;
                    await this._updateWallet();
                    this.emit('readyStateChanged', this.readyState);
                    resolve(isSupport);
                }
            };
            timer = setInterval(check, interval);
            check();
        });
        this._checkPromise = detection;
        // Never cache a failed detection. The extension may inject late, be switched on at
        // runtime, or a mobile WebView may still be initialising — in all of those cases the
        // next call has to look again instead of replaying the old negative answer.
        void detection.then((found) => {
            if (!found && this._checkPromise === detection) {
                this._checkPromise = null;
            }
        });
        return detection;
    }

    private _updateWallet = async () => {
        let state;
        let address;
        if (support{{WALLET_CLASS}}()) {
            this._wallet = window.{{WALLET_INJECTION_KEY}}!.tronLink;
            this._listenEvent();
            address = this._wallet.tronWeb?.defaultAddress?.base58 || null;
            state = address ? AdapterState.Connected : AdapterState.Disconnect;
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

1. **No separate `metadata.ts`**: unlike the EVM adapters in this repo, `name`/`url`/`icon` are
   declared directly as class fields — that's the convention for every existing TRON adapter.
2. **`AddonAdapter`, not `Adapter`**: gives you `commonConfig` (merged `BaseAdapterConfig`),
   `checkSecurity()`, connect-call serialization, and `_beforeConnect()` for free. You only
   implement `_connect()`, `_checkWallet()`, and `_openAppByDeepLinkIfNeed()`.
3. **`assertConnectAddress()`**: always validate the address returned by the wallet through this
   helper before setting state to `Connected` — a success response code does not guarantee a
   non-empty address (see the okxwallet/bitkeep regression tests for why this matters).
4. **`_checkWallet()` never caches a negative result**: the extension may inject late or be
   toggled on at runtime, so a failed detection must be retried on the next call, not remembered.
5. **Event generation counter**: if the wallet pushes async `message` events, guard deferred work
   with a generation counter (`_eventGeneration`) so a `disconnect()` that lands while an event
   handler is mid-flight can't have that handler resurrect state afterward.
6. **`checkAndGetWallet()`**: sign/multiSign/signMessage should all funnel through a helper that
   re-triggers the deeplink-or-error path and asserts the wallet is actually connected before
   touching `tronWeb`.
7. **Security check on `connect()` is already free**: `AddonAdapter._beforeConnect()` calls
   `this.checkSecurity()` before `_connect()` runs, so the explicit `connect()` path is already
   covered. The real `okxwallet`/`bitkeep` adapters additionally call `checkSecurity()` inside
   `_updateWallet()`/the message handler to cover the *auto-reconnect-on-load* path (a session
   restored without the user calling `connect()`) — add that only if the new wallet also
   auto-reconnects and you want auto-reconnected sessions covered by the risk check too.

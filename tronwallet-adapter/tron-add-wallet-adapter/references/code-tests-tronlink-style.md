# Test Suite Template — TronLink-Compatible Adapter (Archetype A)

Create as `tests/units/adapter.test.ts` (plus the small `tests/units/utils.ts` at the bottom). The suite exercises the exact code paths of the Archetype A adapter template (behavioral source of truth: packages/adapters/bybit/src/adapter.ts) and uses the mock from `code-mock-tronlink-style.md`. Structure mirrors packages/adapters/backpack/tests/units/adapter.test.ts.

## tests/units/adapter.test.ts

```typescript
import {
    AdapterState,
    WalletConnectionError,
    WalletDisconnectedError,
    WalletNotFoundError,
    WalletSignTransactionError,
} from '@tronweb3/tronwallet-abstract-adapter';
import { {{WALLET_CLASS}}Adapter } from '../../src/adapter.js';
import { install{{WALLET_CLASS}}, uninstall{{WALLET_CLASS}}, dispatchTronLinkMessage } from './mock.js';
import { CHECK_TIMEOUT } from './utils.js';
import { vi, describe, test, expect, beforeEach, afterEach } from 'vitest';

window.open = vi.fn();

beforeEach(() => {
    vi.useFakeTimers();
    uninstall{{WALLET_CLASS}}();
});

afterEach(() => {
    vi.useRealTimers();
    uninstall{{WALLET_CLASS}}();
});

describe('{{WALLET_CLASS}}Adapter', () => {
    test('should be defined', () => {
        expect({{WALLET_CLASS}}Adapter).not.toBeNull();
    });

    test('#constructor() should work fine', () => {
        const adapter = new {{WALLET_CLASS}}Adapter();
        expect(adapter.name).toEqual('{{WALLET_NAME}}');
        expect(adapter).toHaveProperty('icon');
        expect(adapter).toHaveProperty('url');
        expect(adapter).toHaveProperty('readyState');
        expect(adapter).toHaveProperty('address');
        expect(adapter).toHaveProperty('connecting');
        expect(adapter).toHaveProperty('connected');

        expect(adapter).toHaveProperty('connect');
        expect(adapter).toHaveProperty('disconnect');
        expect(adapter).toHaveProperty('signMessage');
        expect(adapter).toHaveProperty('signTransaction');
        expect(adapter).toHaveProperty('multiSign');
        expect(adapter).toHaveProperty('network');

        expect(adapter).toHaveProperty('on');
        expect(adapter).toHaveProperty('off');
    });

    test('should accept config options', () => {
        const adapter = new {{WALLET_CLASS}}Adapter({
            checkTimeout: 5000,
            openUrlWhenWalletNotFound: false,
            openAppWithDeeplink: false,
        });
        expect(adapter.config.checkTimeout).toEqual(5000);
        expect(adapter.config.openUrlWhenWalletNotFound).toEqual(false);
        expect(adapter.config.openAppWithDeeplink).toEqual(false);
    });

    test('should throw error for invalid checkTimeout', () => {
        expect(() => {
            new {{WALLET_CLASS}}Adapter({ checkTimeout: 'invalid' as any });
        }).toThrow('[{{WALLET_CLASS}}Adapter] config.checkTimeout should be a number');
    });
});

describe('{{WALLET_CLASS}}Adapter - Wallet Detection', () => {
    test('should set state to NotFound when wallet is not installed', async () => {
        uninstall{{WALLET_CLASS}}();
        const adapter = new {{WALLET_CLASS}}Adapter();
        expect(adapter.state).toEqual(AdapterState.Loading);
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await Promise.resolve();
        expect(adapter.state).toEqual(AdapterState.NotFound);
        expect(adapter.connected).toEqual(false);
    });

    test('should set state to Disconnect when wallet is installed but locked', async () => {
        const wallet = install{{WALLET_CLASS}}();
        wallet._setReady(false);
        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await Promise.resolve();
        expect(adapter.state).toEqual(AdapterState.Disconnect);
        expect(adapter.connected).toEqual(false);
        expect(adapter.address).toEqual(null);
    });

    test('should set state to Connected when wallet is installed and ready', async () => {
        const address = 'TTestAddress123456789';
        const wallet = install{{WALLET_CLASS}}(address);
        wallet._setReady(true);
        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await Promise.resolve();
        expect(adapter.state).toEqual(AdapterState.Connected);
        expect(adapter.connected).toEqual(true);
        expect(adapter.address).toEqual(address);
    });
});

describe('{{WALLET_CLASS}}Adapter - connect()', () => {
    test('should throw WalletNotFoundError when wallet is not installed', async () => {
        uninstall{{WALLET_CLASS}}();
        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await Promise.resolve();
        await expect(adapter.connect()).rejects.toThrow(WalletNotFoundError);
    });

    test('should open wallet URL when wallet not found and openUrlWhenWalletNotFound is true', async () => {
        uninstall{{WALLET_CLASS}}();
        const adapter = new {{WALLET_CLASS}}Adapter({ openUrlWhenWalletNotFound: true });
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await Promise.resolve();
        try {
            await adapter.connect();
        } catch (e) {
            // Expected to throw WalletNotFoundError
        }
        expect(window.open).toHaveBeenCalledWith('{{WALLET_URL}}', '_blank');
    });

    test('should connect successfully when user approves', async () => {
        const address = 'TTestAddress123456789';
        const wallet = install{{WALLET_CLASS}}(); // locked: ready = false, state Disconnect

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await Promise.resolve();
        expect(adapter.connected).toEqual(false);

        // User approves: wallet exposes the address, request resolves { code: 200 }
        wallet._setAddress(address);

        const onConnect = vi.fn();
        adapter.on('connect', onConnect);

        await adapter.connect();

        expect(wallet.request).toHaveBeenCalledWith({ method: 'tron_requestAccounts' });
        expect(adapter.state).toEqual(AdapterState.Connected);
        expect(adapter.address).toEqual(address);
        expect(adapter.connected).toEqual(true);
        expect(onConnect).toHaveBeenCalledWith(address);
    });

    test('should throw WalletConnectionError when user rejects connection (code 4001)', async () => {
        const wallet = install{{WALLET_CLASS}}();
        wallet._setRequestResult({ code: 4001 });

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await Promise.resolve();

        await expect(adapter.connect()).rejects.toThrow(WalletConnectionError);
        await expect(adapter.connect()).rejects.toThrow('The user rejected connection.');
        expect(adapter.connected).toEqual(false);
    });

    test('should throw WalletConnectionError when a connect request is already pending (code 4000)', async () => {
        const wallet = install{{WALLET_CLASS}}();
        wallet._setRequestResult({ code: 4000 });

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await Promise.resolve();

        await expect(adapter.connect()).rejects.toThrow(WalletConnectionError);
        expect(adapter.connected).toEqual(false);
    });

    test('should throw WalletConnectionError when request returns null', async () => {
        const wallet = install{{WALLET_CLASS}}();
        wallet._setRequestResult(null);

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await Promise.resolve();

        await expect(adapter.connect()).rejects.toThrow(WalletConnectionError);
        await expect(adapter.connect()).rejects.toThrow('Request connect error.');
    });
});

describe('{{WALLET_CLASS}}Adapter - signMessage()', () => {
    test('should throw WalletDisconnectedError when not connected', async () => {
        const wallet = install{{WALLET_CLASS}}();
        wallet._setReady(false);

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await Promise.resolve();

        await expect(adapter.signMessage('test message')).rejects.toThrow(WalletDisconnectedError);
    });

    test('should delegate to tronWeb.trx.signMessageV2 when connected', async () => {
        const address = 'TTestAddress123456789';
        const wallet = install{{WALLET_CLASS}}(address);
        wallet.tronWeb.trx.signMessageV2.mockResolvedValue('signed_message_result');

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await Promise.resolve();

        const result = await adapter.signMessage('test message');

        expect(wallet.tronWeb.trx.signMessageV2).toHaveBeenCalledWith('test message');
        expect(result).toEqual('signed_message_result');
    });
});

describe('{{WALLET_CLASS}}Adapter - signTransaction()', () => {
    test('should delegate to tronWeb.trx.sign when connected', async () => {
        const address = 'TTestAddress123456789';
        const transaction = { txID: 'test_tx_id', raw_data: {} } as any;
        const signedTx = { txID: 'test_tx_id', signature: ['test_signature'] };
        const wallet = install{{WALLET_CLASS}}(address);
        wallet.tronWeb.trx.sign.mockResolvedValue(signedTx);

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await Promise.resolve();

        const result = await adapter.signTransaction(transaction);

        expect(wallet.tronWeb.trx.sign).toHaveBeenCalledWith(transaction);
        expect(result).toEqual(signedTx);
    });

    test('should wrap errors from tronWeb.trx.sign as WalletSignTransactionError', async () => {
        const address = 'TTestAddress123456789';
        const transaction = { txID: 'test_tx_id', raw_data: {} } as any;
        const wallet = install{{WALLET_CLASS}}(address);
        wallet.tronWeb.trx.sign.mockRejectedValue(new Error('User canceled'));

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await Promise.resolve();

        await expect(adapter.signTransaction(transaction)).rejects.toThrow(WalletSignTransactionError);
        await expect(adapter.signTransaction(transaction)).rejects.toThrow('User canceled');
    });
});

describe('{{WALLET_CLASS}}Adapter - multiSign()', () => {
    test('should delegate to tronWeb.trx.multiSign with permissionId', async () => {
        const address = 'TTestAddress123456789';
        const transaction = { txID: 'test_tx_id', raw_data: {} } as any;
        const signedTx = { txID: 'test_tx_id', signature: ['sig1', 'sig2'] };
        const wallet = install{{WALLET_CLASS}}(address);
        wallet.tronWeb.trx.multiSign.mockResolvedValue(signedTx);

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await Promise.resolve();

        const result = await adapter.multiSign(transaction, { permissionId: 2 });

        expect(wallet.tronWeb.trx.multiSign).toHaveBeenCalledWith(transaction, undefined, 2);
        expect(result).toEqual(signedTx);
    });
});

describe('{{WALLET_CLASS}}Adapter - disconnect()', () => {
    test('should disconnect successfully', async () => {
        const address = 'TTestAddress123456789';
        install{{WALLET_CLASS}}(address);

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await Promise.resolve();
        expect(adapter.connected).toEqual(true);

        const onDisconnect = vi.fn();
        adapter.on('disconnect', onDisconnect);

        await adapter.disconnect();

        expect(adapter.state).toEqual(AdapterState.Disconnect);
        expect(adapter.address).toEqual(null);
        expect(adapter.connected).toEqual(false);
        expect(onDisconnect).toHaveBeenCalled();
    });
});

describe('{{WALLET_CLASS}}Adapter - Events', () => {
    test('should emit accountsChanged 200ms after the wallet posts an accountsChanged message', async () => {
        const address = 'TTestAddress123456789';
        const newAddress = 'TNewAddress987654321';
        const wallet = install{{WALLET_CLASS}}(address);

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await Promise.resolve();
        expect(adapter.address).toEqual(address);

        const onAccountsChanged = vi.fn();
        adapter.on('accountsChanged', onAccountsChanged);

        wallet._setReady(true);
        dispatchTronLinkMessage('accountsChanged', { address: newAddress });

        // The adapter defers the accountsChanged handler by 200ms
        expect(onAccountsChanged).not.toHaveBeenCalled();

        vi.advanceTimersByTime(200);

        expect(onAccountsChanged).toHaveBeenCalledWith(newAddress, address);
        expect(adapter.address).toEqual(newAddress);
        expect(adapter.state).toEqual(AdapterState.Connected);
    });

    test('should emit disconnect when the wallet posts a disconnect message', async () => {
        const address = 'TTestAddress123456789';
        install{{WALLET_CLASS}}(address);

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await Promise.resolve();
        expect(adapter.connected).toEqual(true);

        const onDisconnect = vi.fn();
        adapter.on('disconnect', onDisconnect);

        dispatchTronLinkMessage('disconnect');

        expect(onDisconnect).toHaveBeenCalled();
        expect(adapter.state).toEqual(AdapterState.Disconnect);
        expect(adapter.address).toEqual(null);
    });
});
```

## tests/units/utils.ts

```typescript
import { vi } from 'vitest';

export async function wait(ms = 100): Promise<void> {
    const p = new Promise<void>((resolve) => {
        setTimeout(resolve, ms);
    });
    vi.advanceTimersByTime(ms);
    await p;
}

export const CHECK_TIMEOUT = 3000;
```

## Key Points

1. **The 200ms accountsChanged defer**: the adapter's `messageHandler` wraps the `accountsChanged` branch in `setTimeout(..., 200)` (see packages/adapters/bybit/src/adapter.ts). With `vi.useFakeTimers()` the callback never runs on its own — the test must call `vi.advanceTimersByTime(200)` after `dispatchTronLinkMessage('accountsChanged', ...)`. Asserting `not.toHaveBeenCalled()` before advancing proves the defer exists. The `connect`/`disconnect` message actions are handled synchronously, so those assertions need no timer advance.
2. **Why detection tests advance `CHECK_TIMEOUT`**: when the wallet is not injected at construction time, `_checkWallet()` polls `window.{{WALLET_INJECTION_KEY}}.tronLink` every 100ms until `config.checkTimeout` elapses (default 2000ms). `CHECK_TIMEOUT` (3000) is intentionally larger than the default so a single `vi.advanceTimersByTime(CHECK_TIMEOUT)` always finishes the polling. The promise resolution is a microtask, hence the `await Promise.resolve()` after advancing.
3. **Install the mock BEFORE constructing the adapter** for found-wallet cases: the constructor synchronously detects `window.{{WALLET_INJECTION_KEY}}.tronLink`, sets `readyState` to `Found`, registers the window `message` listener, and derives `Connected` (when `ready === true`, address read from `tronWeb.defaultAddress.base58`) or `Disconnect` (when `ready === false`). Installing after construction would put the adapter on the slower polling path.
4. **connect() early-returns when already connected**: `install{{WALLET_CLASS}}(address)` yields a `Connected` adapter at construction, so connect-flow tests that must exercise `tron_requestAccounts` install a locked wallet (`install{{WALLET_CLASS}}()` with no address) and call `_setAddress` so the adapter can read `tronWeb.defaultAddress.base58` after approval.
5. **Error wrapping matches the adapter source**: every `tron_requestAccounts` failure (`null` result, `code: 4000`, `code: 4001`, thrown error) is re-thrown as `WalletConnectionError`; `trx.sign`/`trx.multiSign` failures become `WalletSignTransactionError`; `trx.signMessageV2` failures become `WalletSignMessageError`; signing or `network()` while not `Connected` throws `WalletDisconnectedError`. The 4000-case message embeds the wallet name, so the test only asserts the error class.
6. **`window.open` is stubbed at module scope** so the not-found `connect()` path can assert `window.open('{{WALLET_URL}}', '_blank')`. The mobile deeplink path (`open{{WALLET_CLASS}}()` in `src/utils.ts`) is never triggered because the test environment reports a desktop `userAgent` (`isInMobileBrowser()` is false); pass `openAppWithDeeplink: false` explicitly if your test environment differs.
7. **`wait()`/`CHECK_TIMEOUT` live in `tests/units/utils.ts`** (copied from packages/adapters/backpack/tests/units/utils.ts) so fake-timer advancement stays consistent across test files.

## Variable Mapping

| Placeholder | Example (Bybit Wallet) | Description |
| --- | --- | --- |
| `{{WALLET_CLASS}}` | `BybitWallet` | PascalCase prefix: `{{WALLET_CLASS}}Adapter`, `install{{WALLET_CLASS}}`, `uninstall{{WALLET_CLASS}}` |
| `{{WALLET_NAME}}` | `Bybit Wallet` | Display name asserted against `adapter.name` |
| `{{WALLET_URL}}` | `https://bybit.com/web3` | Official URL asserted in the `window.open` not-found test |
| `{{WALLET_INJECTION_KEY}}` | `bybitWallet` | Window key polled by `_checkWallet()` (referenced in Key Points; the test code itself reaches it through the mock helpers) |

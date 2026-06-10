# Test Template — TRON Wallet Adapter (Archetype B, provider request-based)

Create as `tests/units/adapter.test.ts`. Based on `packages/adapters/backpack/tests/units/adapter.test.ts`.

```typescript
import {
    AdapterState,
    WalletConnectionError,
    WalletDisconnectedError,
    WalletNotFoundError,
} from '@tronweb3/tronwallet-abstract-adapter';
import { {{WALLET_CLASS}}Adapter } from '../../src/adapter.js';
import { installMock{{WALLET_CLASS}}, uninstallMock{{WALLET_CLASS}} } from './mock.js';
import { CHECK_TIMEOUT } from './utils.js';
import { vi, describe, test, expect, beforeEach, afterEach } from 'vitest';

window.open = vi.fn();

beforeEach(() => {
    vi.useFakeTimers();
    uninstallMock{{WALLET_CLASS}}();
});

afterEach(() => {
    vi.useRealTimers();
    uninstallMock{{WALLET_CLASS}}();
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
        expect(adapter).toHaveProperty('switchChain');
        expect(adapter).toHaveProperty('network');

        expect(adapter).toHaveProperty('on');
        expect(adapter).toHaveProperty('off');
    });

    test('should accept config options', () => {
        const adapter = new {{WALLET_CLASS}}Adapter({
            checkTimeout: 5000,
            openUrlWhenWalletNotFound: false,
        });
        expect(adapter.config.checkTimeout).toEqual(5000);
        expect(adapter.config.openUrlWhenWalletNotFound).toEqual(false);
    });

    test('should throw error for invalid checkTimeout', () => {
        expect(() => {
            new {{WALLET_CLASS}}Adapter({ checkTimeout: 'invalid' as any });
        }).toThrow('[{{WALLET_CLASS}}Adapter] config.checkTimeout should be a number');
    });
});

describe('{{WALLET_CLASS}}Adapter - Wallet Detection', () => {
    test('should set state to NotFound when {{WALLET_NAME}} is not installed', async () => {
        uninstallMock{{WALLET_CLASS}}();
        const adapter = new {{WALLET_CLASS}}Adapter();
        expect(adapter.state).toEqual(AdapterState.Loading);
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await Promise.resolve();
        expect(adapter.state).toEqual(AdapterState.NotFound);
        expect(adapter.connected).toEqual(false);
    });

    test('should set state to Disconnect when {{WALLET_NAME}} is installed but not connected', async () => {
        const provider = installMock{{WALLET_CLASS}}();
        provider._setConnected(false);
        provider._setAddress('');
        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await Promise.resolve();
        expect(adapter.state).toEqual(AdapterState.Disconnect);
        expect(adapter.connected).toEqual(false);
    });

    test('should set state to Connected when {{WALLET_NAME}} is already connected', async () => {
        const address = 'TTestAddress123456789';
        const provider = installMock{{WALLET_CLASS}}(address);
        provider._setConnected(true);
        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await Promise.resolve();
        expect(adapter.state).toEqual(AdapterState.Connected);
        expect(adapter.connected).toEqual(true);
        expect(adapter.address).toEqual(address);
    });
});

describe('{{WALLET_CLASS}}Adapter - connect()', () => {
    test('should throw WalletNotFoundError when {{WALLET_NAME}} is not installed', async () => {
        uninstallMock{{WALLET_CLASS}}();
        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await expect(adapter.connect()).rejects.toThrow(WalletNotFoundError);
    });

    test('should open wallet URL when wallet not found and openUrlWhenWalletNotFound is true', async () => {
        uninstallMock{{WALLET_CLASS}}();
        const adapter = new {{WALLET_CLASS}}Adapter({ openUrlWhenWalletNotFound: true });
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        try {
            await adapter.connect();
        } catch (e) {
            // Expected to throw
        }
        expect(window.open).toHaveBeenCalledWith('{{WALLET_URL}}', '_blank');
    });

    test('should throw WalletConnectionError when user rejects connection', async () => {
        const provider = installMock{{WALLET_CLASS}}();
        provider._setConnected(false);
        provider.request = vi.fn().mockRejectedValue({ code: 4001, message: 'User rejected' });

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await expect(adapter.connect()).rejects.toThrow(WalletConnectionError);
    });

    test('should connect successfully when user approves', async () => {
        const address = 'TTestAddress123456789';
        const provider = installMock{{WALLET_CLASS}}();
        provider._setConnected(true);
        provider._setAddress(address);
        provider.request = vi.fn().mockResolvedValue([address]);

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);

        const onConnect = vi.fn();
        adapter.on('connect', onConnect);

        await adapter.connect();

        expect(adapter.state).toEqual(AdapterState.Connected);
        expect(adapter.address).toEqual(address);
        expect(adapter.connected).toEqual(true);
        expect(onConnect).toHaveBeenCalledWith(address);
    });

    test('should not connect twice if already connected', async () => {
        const address = 'TTestAddress123456789';
        const provider = installMock{{WALLET_CLASS}}(address);
        provider._setConnected(true);
        const requestMock = vi.fn().mockResolvedValue([address]);
        provider.request = requestMock;

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await Promise.resolve();

        // Already connected from initialization (tron_accounts was called)
        expect(adapter.connected).toEqual(true);

        // Clear mock to track new calls
        requestMock.mockClear();

        // Try to connect again
        await adapter.connect();

        // tron_requestAccounts should not be called for second connect
        expect(requestMock).not.toHaveBeenCalledWith({ method: 'tron_requestAccounts' });
    });
});

describe('{{WALLET_CLASS}}Adapter - disconnect()', () => {
    test('should disconnect successfully', async () => {
        const address = 'TTestAddress123456789';
        const provider = installMock{{WALLET_CLASS}}(address);
        provider._setConnected(true);
        provider.request = vi.fn().mockResolvedValue([address]);

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await adapter.connect();

        const onDisconnect = vi.fn();
        adapter.on('disconnect', onDisconnect);

        await adapter.disconnect();

        expect(adapter.state).toEqual(AdapterState.Disconnect);
        expect(adapter.address).toEqual(null);
        expect(adapter.connected).toEqual(false);
        expect(onDisconnect).toHaveBeenCalled();
    });

    test('should do nothing if not connected', async () => {
        const provider = installMock{{WALLET_CLASS}}();
        provider._setConnected(false);

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);

        const onDisconnect = vi.fn();
        adapter.on('disconnect', onDisconnect);

        await adapter.disconnect();

        expect(onDisconnect).not.toHaveBeenCalled();
    });
});

describe('{{WALLET_CLASS}}Adapter - signMessage()', () => {
    test('should throw WalletDisconnectedError when not connected', async () => {
        const provider = installMock{{WALLET_CLASS}}();
        provider._setConnected(false);

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);

        await expect(adapter.signMessage('test message')).rejects.toThrow(WalletDisconnectedError);
    });

    test('should sign message successfully when connected', async () => {
        const address = 'TTestAddress123456789';
        const provider = installMock{{WALLET_CLASS}}(address);
        provider._setConnected(true);
        provider.request = vi.fn().mockImplementation((args) => {
            if (args.method === 'tron_requestAccounts') return Promise.resolve([address]);
            if (args.method === 'tron_accounts') return Promise.resolve([address]);
            if (args.method === 'tron_signMessage') return Promise.resolve('signed_message');
            return Promise.reject(new Error('Unknown method'));
        });

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await adapter.connect();

        const result = await adapter.signMessage('test message');
        expect(result).toEqual('signed_message');
    });
});

describe('{{WALLET_CLASS}}Adapter - signTransaction()', () => {
    test('should throw WalletDisconnectedError when not connected', async () => {
        const provider = installMock{{WALLET_CLASS}}();
        provider._setConnected(false);

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);

        await expect(adapter.signTransaction({} as any)).rejects.toThrow(WalletDisconnectedError);
    });

    test('should sign transaction successfully when connected', async () => {
        const address = 'TTestAddress123456789';
        const signedTx = { txID: 'test_tx', signature: ['sig'] };
        const provider = installMock{{WALLET_CLASS}}(address);
        provider._setConnected(true);
        provider.request = vi.fn().mockImplementation((args) => {
            if (args.method === 'tron_requestAccounts') return Promise.resolve([address]);
            if (args.method === 'tron_accounts') return Promise.resolve([address]);
            if (args.method === 'tron_signTransaction') return Promise.resolve(signedTx);
            return Promise.reject(new Error('Unknown method'));
        });

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await adapter.connect();

        const result = await adapter.signTransaction({} as any);
        expect(result).toEqual(signedTx);
    });
});

describe('{{WALLET_CLASS}}Adapter - switchChain()', () => {
    test('should throw WalletDisconnectedError when not connected', async () => {
        const provider = installMock{{WALLET_CLASS}}();
        provider._setConnected(false);

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);

        await expect(adapter.switchChain('0x2b6653dc')).rejects.toThrow(WalletDisconnectedError);
    });

    test('should switch chain successfully when connected', async () => {
        const address = 'TTestAddress123456789';
        const provider = installMock{{WALLET_CLASS}}(address);
        provider._setConnected(true);
        provider.request = vi.fn().mockImplementation((args) => {
            if (args.method === 'tron_requestAccounts') return Promise.resolve([address]);
            if (args.method === 'tron_accounts') return Promise.resolve([address]);
            if (args.method === 'tron_switchChain') return Promise.resolve(null);
            return Promise.reject(new Error('Unknown method'));
        });

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await adapter.connect();

        const onChainChanged = vi.fn();
        adapter.on('chainChanged', onChainChanged);

        await adapter.switchChain('0x2b6653dc');
        expect(onChainChanged).toHaveBeenCalledWith({ chainId: '0x2b6653dc' });
    });
});

describe('{{WALLET_CLASS}}Adapter - network()', () => {
    test('should throw WalletDisconnectedError when not connected', async () => {
        const provider = installMock{{WALLET_CLASS}}();
        provider._setConnected(false);

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);

        await expect(adapter.network()).rejects.toThrow(WalletDisconnectedError);
    });

    test('should return network info when connected', async () => {
        const address = 'TTestAddress123456789';
        const provider = installMock{{WALLET_CLASS}}(address);
        provider._setConnected(true);
        provider.request = vi.fn().mockImplementation((args) => {
            if (args.method === 'tron_requestAccounts') return Promise.resolve([address]);
            if (args.method === 'tron_accounts') return Promise.resolve([address]);
            if (args.method === 'tron_chainId') return Promise.resolve('0x2b6653dc');
            return Promise.reject(new Error('Unknown method'));
        });

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await adapter.connect();

        const network = await adapter.network();
        expect(network.chainId).toEqual('0x2b6653dc');
        expect(network.networkType).toEqual('Mainnet');
    });
});

describe('{{WALLET_CLASS}}Adapter - Events', () => {
    test('should emit accountsChanged when accounts change', async () => {
        const address = 'TTestAddress123456789';
        const newAddress = 'TNewAddress987654321';
        const provider = installMock{{WALLET_CLASS}}(address);
        provider._setConnected(true);
        provider.request = vi.fn().mockImplementation((args) => {
            if (args.method === 'tron_requestAccounts') return Promise.resolve([address]);
            if (args.method === 'tron_accounts') return Promise.resolve([address]);
            return Promise.reject(new Error('Unknown method'));
        });

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await adapter.connect();

        const onAccountsChanged = vi.fn();
        adapter.on('accountsChanged', onAccountsChanged);

        // Simulate accounts changed event from provider
        provider._emit('accountsChanged', [newAddress]);

        expect(onAccountsChanged).toHaveBeenCalledWith(newAddress, address);
        expect(adapter.address).toEqual(newAddress);
    });

    test('should emit disconnect when accounts become empty', async () => {
        const address = 'TTestAddress123456789';
        const provider = installMock{{WALLET_CLASS}}(address);
        provider._setConnected(true);
        provider.request = vi.fn().mockImplementation((args) => {
            if (args.method === 'tron_requestAccounts') return Promise.resolve([address]);
            if (args.method === 'tron_accounts') return Promise.resolve([address]);
            return Promise.reject(new Error('Unknown method'));
        });

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await adapter.connect();

        const onDisconnect = vi.fn();
        adapter.on('disconnect', onDisconnect);

        // Simulate disconnect by emitting empty accounts
        provider._emit('accountsChanged', []);

        expect(onDisconnect).toHaveBeenCalled();
        expect(adapter.state).toEqual(AdapterState.Disconnect);
    });

    test('should emit chainChanged when chain changes', async () => {
        const address = 'TTestAddress123456789';
        const provider = installMock{{WALLET_CLASS}}(address);
        provider._setConnected(true);
        provider.request = vi.fn().mockImplementation((args) => {
            if (args.method === 'tron_requestAccounts') return Promise.resolve([address]);
            if (args.method === 'tron_accounts') return Promise.resolve([address]);
            return Promise.reject(new Error('Unknown method'));
        });

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await adapter.connect();

        const onChainChanged = vi.fn();
        adapter.on('chainChanged', onChainChanged);

        // Simulate chain changed event from provider
        provider._emit('chainChanged', '0x94a9059e');

        expect(onChainChanged).toHaveBeenCalledWith({ chainId: '0x94a9059e' });
    });

    test('should remove event listeners on disconnect', async () => {
        const address = 'TTestAddress123456789';
        const provider = installMock{{WALLET_CLASS}}(address);
        provider._setConnected(true);
        provider.request = vi.fn().mockImplementation((args) => {
            if (args.method === 'tron_requestAccounts') return Promise.resolve([address]);
            if (args.method === 'tron_accounts') return Promise.resolve([address]);
            return Promise.reject(new Error('Unknown method'));
        });

        const adapter = new {{WALLET_CLASS}}Adapter();
        vi.advanceTimersByTime(CHECK_TIMEOUT);
        await adapter.connect();

        // Verify listeners were added
        expect(provider._getListenerCount('accountsChanged')).toBeGreaterThan(0);
        expect(provider._getListenerCount('chainChanged')).toBeGreaterThan(0);

        await adapter.disconnect();

        // Verify listeners were removed
        expect(provider._getListenerCount('accountsChanged')).toEqual(0);
        expect(provider._getListenerCount('chainChanged')).toEqual(0);
    });
});
```

## tests/units/utils.ts

Create as `tests/units/utils.ts` (identical for every adapter, copied from backpack).

```typescript
import { vi } from 'vitest';

export async function wait(ms = 100): Promise<void> {
    const p = new Promise<void>((resolve) => {
        setTimeout(resolve, ms);
    });
    vi.advanceTimersByTime(ms);
    await p;
}

export const ONE_SECOND = 1000;
export const CHECK_TIMEOUT = 3000;
```

## Key Points

- Fake-timer flow: `vi.useFakeTimers()` runs in `beforeEach`, and every test calls `vi.advanceTimersByTime(CHECK_TIMEOUT)` (3000 ms, the adapter's default `checkTimeout`) to flush the detection polling that runs in the constructor. Detection tests follow it with `await Promise.resolve()` to let the async state update settle before asserting `adapter.state`.
- `installMock{{WALLET_CLASS}}` / `uninstallMock{{WALLET_CLASS}}` come from `tests/units/mock.ts` (see code-mock-provider-style.md); each test installs the mock in the exact state it needs, and `beforeEach`/`afterEach` uninstall it so tests cannot leak the injected provider.
- Mock-driven event emission: provider-originated events are simulated with `provider._emit('accountsChanged', [...])` / `provider._emit('chainChanged', chainId)` rather than window `message` events (that pattern belongs to Archetype A). Emitting an empty accounts array must drive the adapter to `Disconnect` and fire `disconnect`.
- `window.open = vi.fn()` at module top level enables the WalletNotFoundError test to assert `window.open` was called with `{{WALLET_URL}}` and `'_blank'` when `openUrlWhenWalletNotFound` is true.
- The user-rejection test mocks `provider.request` to reject with `{ code: 4001 }` and expects the adapter to surface it as `WalletConnectionError`.
- Per-test `provider.request = vi.fn().mockImplementation(...)` overrides only the methods a test exercises and rejects everything else, so unexpected adapter calls fail the test.
- Listener-removal test uses the mock's `_getListenerCount` helper to prove the adapter unsubscribes `accountsChanged`/`chainChanged` on `disconnect()`.
- If the wallet does NOT support `tron_switchChain` or `tron_chainId` (check the Phase 1 feature matrix), drop the `switchChain()` and/or `network()` describe blocks and the corresponding `toHaveProperty` assertions in the constructor test.
- Chain IDs used in assertions: Mainnet `0x2b6653dc`, Shasta `0x94a9059e` (Nile is `0xcd8690dc`).

## Variable Mapping

| Placeholder | Example (Backpack) | Description |
| --- | --- | --- |
| `{{WALLET_CLASS}}` | `Backpack` | PascalCase prefix: `{{WALLET_CLASS}}Adapter`, `installMock{{WALLET_CLASS}}`, error prefix `[{{WALLET_CLASS}}Adapter]` |
| `{{WALLET_NAME}}` | `Backpack` | Display name asserted against `adapter.name` and used in test descriptions |
| `{{WALLET_URL}}` | `https://backpack.app` | Official wallet URL asserted in the `window.open` test |

# Test Template — EVM Wallet Adapter

## adapter.test.ts

```typescript
import { vi, describe, beforeEach, afterEach, test, expect } from 'vitest';
import { WalletNotFoundError } from '@tronweb3/abstract-adapter-evm';
import { {{WALLET_CLASS}}EvmAdapter } from '../../src/adapter.js';
import { {{WALLET_CLASS}}Provider, install{{WALLET_CLASS}}EIP6963Provider } from './{{WALLET_DIR}}-provider.js';

let provider: {{WALLET_CLASS}}Provider;
let cleanupEIP6963: (() => void) | null = null;

beforeEach(() => {
    vi.useFakeTimers();
    provider = new {{WALLET_CLASS}}Provider();
    (window as any).ethereum = null;
    (window as any).{{WALLET_INJECTION_KEY}} = undefined;
    vi.clearAllMocks();
});

afterEach(() => {
    if (cleanupEIP6963) {
        cleanupEIP6963();
        cleanupEIP6963 = null;
    }
    (window as any).ethereum = null;
    (window as any).{{WALLET_INJECTION_KEY}} = undefined;
    vi.clearAllTimers();
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
});

async function flushPromises() {
    for (let i = 0; i < 5; i++) {
        await Promise.resolve();
    }
}

const typedData = {
    domain: {
        chainId: 1,
        name: 'Ether Mail',
        verifyingContract: '0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC',
        version: '1',
    },
    primaryType: 'Mail',
    types: {
        Mail: [
            { name: 'from', type: 'string' },
            { name: 'to', type: 'string' },
            { name: 'contents', type: 'string' },
        ],
    },
    message: {
        from: '0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB',
        to: '0xB0BdaBea57B0BDABeA57b0bdABEA57b0BDabEa57',
        contents: 'Hello',
    },
};

describe('{{WALLET_CLASS}}EvmAdapter', () => {
    test('base props should be valid', () => {
        const adapter = new {{WALLET_CLASS}}EvmAdapter();
        expect(adapter.name).toEqual('{{WALLET_NAME}}');
        expect(adapter.url).toEqual('{{WALLET_URL}}');
        expect(adapter.readyState).toEqual('Loading');
        expect(adapter.address).toEqual(null);
        expect(adapter.connected).toEqual(false);
    });

    describe('provider detection should work fine', () => {
        test('adapter should discover provider via EIP-6963', async () => {
            cleanupEIP6963 = install{{WALLET_CLASS}}EIP6963Provider(provider);
            const adapter = new {{WALLET_CLASS}}EvmAdapter();
            await flushPromises();

            expect(adapter.readyState).toEqual('Found');
            await expect(adapter.getProvider()).resolves.toBe(provider);
        });

        test('adapter should discover injected provider in mobile webview without EIP-6963', async () => {
            (window as any).{{WALLET_INJECTION_KEY}} = provider;
            vi.stubGlobal('navigator', {
                ...window.navigator,
                userAgent:
                    'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148',
            });

            const adapter = new {{WALLET_CLASS}}EvmAdapter();
            await flushPromises();

            expect(adapter.readyState).toEqual('Found');
            await expect(adapter.getProvider()).resolves.toBe(provider);
        });

        test('adapter should not discover desktop injected provider without EIP-6963', async () => {
            (window as any).ethereum = provider;

            const adapter = new {{WALLET_CLASS}}EvmAdapter();
            vi.advanceTimersByTime(3000);
            await flushPromises();

            expect(adapter.readyState).toEqual('NotFound');
            await expect(adapter.getProvider()).resolves.toBeNull();
        });

        test('adapter should not match provider with wrong rdns', async () => {
            cleanupEIP6963 = install{{WALLET_CLASS}}EIP6963Provider(provider, { rdns: 'io.other.wallet' });
            const adapter = new {{WALLET_CLASS}}EvmAdapter();
            vi.advanceTimersByTime(3000);
            await flushPromises();

            expect(adapter.readyState).toEqual('NotFound');
        });

        test('adapter should be NotFound when no EIP-6963 provider announces', async () => {
            const adapter = new {{WALLET_CLASS}}EvmAdapter();
            expect(adapter.readyState).toEqual('Loading');
            vi.advanceTimersByTime(3000);
            await flushPromises();
            expect(adapter.readyState).toEqual('NotFound');
        });
    });

    describe('#signTypedData()', () => {
        test('should work fine', async () => {
            provider._setAccountsRes(['address']);
            cleanupEIP6963 = install{{WALLET_CLASS}}EIP6963Provider(provider);
            const adapter = new {{WALLET_CLASS}}EvmAdapter();
            await flushPromises();
            const request = vi.spyOn(provider, 'request');
            const getProvider = vi.spyOn(adapter, 'getProvider');
            await adapter.signTypedData({ typedData });
            expect(getProvider).toHaveBeenCalledTimes(1);
            expect(request).toHaveBeenLastCalledWith({
                method: 'eth_signTypedData_v4',
                params: [adapter.address, JSON.stringify(typedData)],
            });
            request.mockReset();
            request.mockRestore();
        });
        test('should throw error when provider.request throws error', async () => {
            provider._setAccountsRes(['address']);
            cleanupEIP6963 = install{{WALLET_CLASS}}EIP6963Provider(provider);
            const adapter = new {{WALLET_CLASS}}EvmAdapter();
            await flushPromises();
            const oldRequest = provider.request;
            const error = new Error();
            provider.request = vi.fn(() => {
                throw error;
            });
            await expect(adapter.signTypedData({ typedData })).rejects.toEqual(error);
            provider.request = oldRequest;
        });
    });

    describe('#connect()', () => {
        test('should work fine when provider.request return account list', async () => {
            provider._setRequestAccountsRes(['address']);
            cleanupEIP6963 = install{{WALLET_CLASS}}EIP6963Provider(provider);
            const adapter = new {{WALLET_CLASS}}EvmAdapter();
            await flushPromises();
            const res = await adapter.connect();
            expect(res).toEqual('address');
        });
        test('should throw WalletNotFoundError when there is no EIP-6963 provider', async () => {
            const adapter = new {{WALLET_CLASS}}EvmAdapter();
            const res = adapter.connect();
            vi.advanceTimersByTime(5000);
            await expect(res).rejects.toBeInstanceOf(WalletNotFoundError);
            expect(adapter.connecting).toBe(false);
        });
        test('should throw WalletConnectionError when provider.request throws error', async () => {
            provider._setAccountsRes(['address']);
            cleanupEIP6963 = install{{WALLET_CLASS}}EIP6963Provider(provider);
            const adapter = new {{WALLET_CLASS}}EvmAdapter();
            await flushPromises();
            const oldRequest = provider.request;
            const error = new Error();
            provider.request = vi.fn(() => {
                throw error;
            });
            await expect(adapter.connect()).rejects.toThrow();
            expect(adapter.connecting).toBe(false);
            provider.request = oldRequest;
        });
    });
});
```

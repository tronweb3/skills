# Test Template — TRON Wallet Adapter

No mock-provider file is needed (unlike the EVM/EIP-6963 adapters) — tests stub
`window.{{WALLET_INJECTION_KEY}}` directly, or reach into `(adapter as any)._wallet` /
`(adapter as any)._readyState` to simulate an already-connected wallet.

## tests/units/adapter.test.ts

```typescript
import { describe, test, expect, beforeEach, afterEach, vi } from 'vitest';
import { {{WALLET_CLASS}}Adapter } from '../../src/adapter.js';
import { AdapterState, WalletReadyState, WalletConnectionError, WalletNotFoundError } from '@tronweb3/tronwallet-abstract-adapter';

beforeEach(function () {
    vi.stubGlobal(
        'fetch',
        vi.fn().mockResolvedValue({
            ok: true,
            json: () => Promise.resolve({}),
        })
    );
});
afterEach(function () {
    delete (window as any).{{WALLET_INJECTION_KEY}};
    vi.unstubAllGlobals();
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

        expect(adapter).toHaveProperty('on');
        expect(adapter).toHaveProperty('off');
    });
});

describe('#connect()', () => {
    const ADDRESS = 'TKcEU8ekq2ZoFzLSGFYCUY6aocJBX9X3Fa';

    function makeAdapter(defaultAddress: unknown) {
        const adapter = new {{WALLET_CLASS}}Adapter();
        (adapter as any)._readyState = WalletReadyState.Found;
        (adapter as any)._wallet = {
            request: vi.fn().mockResolvedValue({ code: 200 }),
            tronWeb: { defaultAddress },
            on: vi.fn(),
            removeListener: vi.fn(),
        };
        adapter.on('error', () => {});
        return adapter;
    }

    test('should throw WalletNotFoundError when the wallet is not detected', async () => {
        const adapter = new {{WALLET_CLASS}}Adapter();
        (adapter as any)._readyState = WalletReadyState.NotFound;

        await expect(adapter.connect()).rejects.toBeInstanceOf(WalletNotFoundError);
        expect(adapter.connecting).toBe(false);
    });

    /**
     * A success response from the wallet's request call does not guarantee an address is
     * available yet. Going to `Connected` here would leave `connected === true` with no
     * address to sign with.
     */
    test.each([
        ['base58 is missing', {}],
        ['base58 is an empty string', { base58: '' }],
        ['base58 is false', { base58: false }],
        ['defaultAddress is undefined', undefined],
    ])('rejects when %s', async (_label, defaultAddress) => {
        const adapter = makeAdapter(defaultAddress);
        const onConnect = vi.fn();
        adapter.on('connect', onConnect);

        await expect(adapter.connect()).rejects.toBeInstanceOf(WalletConnectionError);
        expect(adapter.address).toBeNull();
        expect(adapter.state).not.toBe(AdapterState.Connected);
        expect(adapter.connected).toBe(false);
        expect(onConnect).not.toHaveBeenCalled();
    });

    test('connects when a real address is available', async () => {
        const adapter = makeAdapter({ base58: ADDRESS });
        const onConnect = vi.fn();
        adapter.on('connect', onConnect);

        await adapter.connect();

        expect(adapter.address).toBe(ADDRESS);
        expect(adapter.state).toBe(AdapterState.Connected);
        expect(adapter.connected).toBe(true);
        expect(onConnect).toHaveBeenCalledWith(ADDRESS);
    });
});

describe('#signMessage() / #signTransaction()', () => {
    function makeConnectedAdapter() {
        const adapter = new {{WALLET_CLASS}}Adapter();
        (adapter as any)._readyState = WalletReadyState.Found;
        (adapter as any)._state = AdapterState.Connected;
        (adapter as any)._wallet = {
            tronWeb: {
                trx: {
                    sign: vi.fn().mockResolvedValue({ signature: ['sig'] }),
                    signMessageV2: vi.fn().mockResolvedValue('0xsignature'),
                },
            },
        };
        adapter.on('error', () => {});
        return adapter;
    }

    test('signMessage() delegates to tronWeb.trx.signMessageV2', async () => {
        const adapter = makeConnectedAdapter();
        const res = await adapter.signMessage('hello');
        expect(res).toEqual('0xsignature');
    });

    test('signTransaction() delegates to tronWeb.trx.sign', async () => {
        const adapter = makeConnectedAdapter();
        const tx = { txID: 'abc' } as any;
        const res = await adapter.signTransaction(tx);
        expect(res).toEqual({ signature: ['sig'] });
    });
});
```

## If the wallet pushes `accountsChanged` / `disconnect` events

Add regression tests for the stale-event-after-disconnect case, following the pattern in
`packages/adapters/okxwallet/tests/units/adapter.test.ts` (`#accountsChanged stale-timer
regression`) — fire the event, immediately call `disconnect()`, advance fake timers, and assert
state was **not** resurrected. This matters whenever the handler does any `await` (e.g.
`checkSecurity()`) between receiving the event and writing state.

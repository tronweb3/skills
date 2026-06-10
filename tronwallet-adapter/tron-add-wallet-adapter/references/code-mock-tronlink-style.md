# Mock Wallet Template — TronLink-Compatible Adapter (Archetype A)

Create as `tests/units/mock.ts`. This mock implements the exact `TronLinkWallet` surface the Archetype A adapter touches (see packages/adapters/bybit/src/adapter.ts). It pairs with the test suite in `code-tests-tronlink-style.md`.

```typescript
// @ts-nocheck
/* eslint-disable @typescript-eslint/no-unused-vars */
import { vi } from 'vitest';
import type { TronLinkWallet } from '@tronweb3/tronwallet-adapter-tronlink';

type RequestAccountsResult = { code: number; message?: string } | null;

export class Mock{{WALLET_CLASS}}TronLinkWallet implements TronLinkWallet {
    ready = false;

    private _requestResult: RequestAccountsResult = { code: 200 };
    private _requestError: Error | null = null;

    tronWeb = {
        defaultAddress: {
            base58: '',
        },
        trx: {
            sign: vi.fn(async (transaction: unknown) => ({
                ...(transaction as object),
                signature: ['mock_signature'],
            })),
            signMessageV2: vi.fn(async (_message: string) => 'mock_signed_message'),
            multiSign: vi.fn(async (transaction: unknown, _permission: unknown, _permissionId?: number) => ({
                ...(transaction as object),
                signature: ['mock_multi_signature'],
            })),
        },
    };

    constructor(address?: string) {
        if (address) {
            this.ready = true;
            this.tronWeb.defaultAddress.base58 = address;
        }
    }

    request = vi.fn(async (args: { method: string }): Promise<unknown> => {
        if (args.method === 'tron_requestAccounts') {
            if (this._requestError) {
                throw this._requestError;
            }
            if (this._requestResult && this._requestResult.code === 200) {
                // A real wallet unlocks after the user approves the request.
                this.ready = true;
            }
            return this._requestResult;
        }
        throw new Error(`Unknown method: ${args.method}`);
    });

    // Test helpers
    _setReady(ready: boolean): void {
        this.ready = ready;
    }

    _setAddress(address: string): void {
        this.tronWeb.defaultAddress.base58 = address;
    }

    /**
     * Configure the result of `request({ method: 'tron_requestAccounts' })`.
     * Use `{ code: 200 }` (default), `{ code: 4000 }` (duplicate request),
     * `{ code: 4001 }` (user rejected) or `null` (empty response).
     */
    _setRequestResult(result: RequestAccountsResult): void {
        this._requestResult = result;
        this._requestError = null;
    }

    /** Make `request({ method: 'tron_requestAccounts' })` throw. */
    _setRequestError(error: Error): void {
        this._requestError = error;
    }
}

export function install{{WALLET_CLASS}}(address?: string): Mock{{WALLET_CLASS}}TronLinkWallet {
    const wallet = new Mock{{WALLET_CLASS}}TronLinkWallet(address);
    (window as any).{{WALLET_INJECTION_KEY}} = { tronLink: wallet };
    return wallet;
}

export function uninstall{{WALLET_CLASS}}(): void {
    (window as any).{{WALLET_INJECTION_KEY}} = undefined;
}

/**
 * Drive the adapter's window 'message' listener the same way the real
 * wallet extension does: e.data.message = { action, data }.
 */
export function dispatchTronLinkMessage(action: string, data?: unknown): void {
    window.dispatchEvent(
        new MessageEvent('message', {
            data: {
                message: { action, data },
            },
        })
    );
}
```

## Key Points

1. **Mock only what the adapter uses**: the Archetype A adapter reads `wallet.ready`, calls `wallet.request({ method: 'tron_requestAccounts' })`, reads `wallet.tronWeb.defaultAddress.base58`, and signs via `wallet.tronWeb.trx.sign` / `signMessageV2` / `multiSign`. Nothing else needs to exist on the mock.
2. **Constructor mirrors a connected wallet**: passing an address to `install{{WALLET_CLASS}}(address)` produces `ready = true` plus a populated `defaultAddress.base58`, so a freshly constructed adapter lands directly in `Connected` state. Calling `install{{WALLET_CLASS}}()` without an address produces a locked wallet (`ready = false` → adapter state `Disconnect`).
3. **`request` result is configurable**: defaults to `{ code: 200 }` (success). Use `_setRequestResult({ code: 4001 })` for user rejection, `{ code: 4000 }` for a duplicate pending request, `null` for an empty response, and `_setRequestError(err)` to make the call throw. On a `code: 200` success the mock flips `ready = true`, mirroring real wallet unlock behavior.
4. **`trx.*` are `vi.fn()`**: tests configure results per-case with `mockResolvedValue` / `mockRejectedValue` and assert call arguments with `toHaveBeenCalledWith`.
5. **Install BEFORE constructing the adapter** for found-wallet cases: the adapter constructor synchronously checks `window.{{WALLET_INJECTION_KEY}}.tronLink` and, when present, immediately registers its `message` listener and derives state from `ready`.
6. **`dispatchTronLinkMessage` shape matters**: the adapter's `messageHandler` reads `e.data?.message` and switches on `message.action` (`connect` / `disconnect` / `accountsChanged`), so the `MessageEvent` payload must be `{ data: { message: { action, data } } }`.
7. **`// @ts-nocheck`** mirrors the repo's existing test mocks — the mock implements only a partial `TronWeb` shape, which would not satisfy the full `TronLinkWallet` type.

## Variable Mapping

| Placeholder | Example (Bybit Wallet) | Description |
| --- | --- | --- |
| `{{WALLET_CLASS}}` | `BybitWallet` | PascalCase prefix used in `Mock{{WALLET_CLASS}}TronLinkWallet`, `install{{WALLET_CLASS}}`, `uninstall{{WALLET_CLASS}}` |
| `{{WALLET_INJECTION_KEY}}` | `bybitWallet` | Key the wallet injects on `window`; the adapter reads `window.{{WALLET_INJECTION_KEY}}.tronLink` |

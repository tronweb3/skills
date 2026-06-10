# Mock Provider Template — TRON Wallet Adapter (Archetype B, provider request-based)

Create as `tests/units/mock.ts`. Based on `packages/adapters/backpack/tests/units/mock.ts`.

```typescript
// @ts-nocheck
/* eslint-disable @typescript-eslint/no-unused-vars */
import type { {{WALLET_CLASS}}TronProvider } from '../../src/utils.js';

export class Mock{{WALLET_CLASS}}Provider implements {{WALLET_CLASS}}TronProvider {
    {{WALLET_IS_FIELD}} = true;
    private _address = '';
    private _connected = false;
    private _listeners: Record<string, ((...args: unknown[]) => unknown)[]> = {};

    constructor(address?: string) {
        if (address) {
            this._address = address;
            this._connected = true;
        }
    }

    async request(args: { method: string; params?: unknown }): Promise<unknown> {
        switch (args.method) {
            case 'tron_accounts':
                return this._connected && this._address ? [this._address] : [];
            case 'tron_requestAccounts':
                if (!this._connected) {
                    throw { code: 4001, message: 'User rejected' };
                }
                return this._address ? [this._address] : [];
            case 'tron_signMessage':
                if (!this._connected) throw new Error('Not connected');
                return 'signed_message_result';
            case 'tron_signTransaction':
                if (!this._connected) throw new Error('Not connected');
                return { txID: 'test_tx_id', signature: ['test_signature'] };
            case 'tron_chainId':
                return 'tron:728126428';
            case 'tron_switchChain':
                return null;
            default:
                throw new Error(`Unknown method: ${args.method}`);
        }
    }

    on(event: string, handler: (...args: unknown[]) => void): void {
        if (!this._listeners[event]) {
            this._listeners[event] = [];
        }
        this._listeners[event].push(handler);
    }

    removeListener(event: string, handler: (...args: unknown[]) => void): void {
        if (this._listeners[event]) {
            const idx = this._listeners[event].indexOf(handler);
            if (idx !== -1) {
                this._listeners[event].splice(idx, 1);
            }
        }
    }

    async connect(): Promise<void> {
        this._connected = true;
    }

    async disconnect(): Promise<void> {
        this._connected = false;
        this._address = '';
    }

    // Test helpers
    _setAddress(address: string): void {
        this._address = address;
    }

    _setConnected(connected: boolean): void {
        this._connected = connected;
    }

    _emit(event: string, ...args: unknown[]): void {
        if (this._listeners[event]) {
            this._listeners[event].forEach((handler) => handler(...args));
        }
    }

    _getListenerCount(event: string): number {
        return this._listeners[event]?.length || 0;
    }
}

export function installMock{{WALLET_CLASS}}(address?: string): Mock{{WALLET_CLASS}}Provider {
    const provider = new Mock{{WALLET_CLASS}}Provider(address);
    // The `{ tron: provider }` wrapper mirrors the {{WALLET_PROVIDER_PATH}} nesting.
    // Adjust this assignment if the wallet nests the provider differently.
    (window as any).{{WALLET_INJECTION_KEY}} = { tron: provider };
    return provider;
}

export function uninstallMock{{WALLET_CLASS}}(): void {
    (window as any).{{WALLET_INJECTION_KEY}} = undefined;
    (window as any).tron = undefined;
}
```

## Key Points

- The mock implements the `{{WALLET_CLASS}}TronProvider` interface exported from `src/utils.ts`, so any drift between the mock and the real provider type is caught at compile time.
- `{{WALLET_IS_FIELD}} = true` reproduces the identity flag the adapter's detection logic checks on the injected provider.
- `request()` covers all six `tron_*` methods the adapter may call (`tron_accounts`, `tron_requestAccounts`, `tron_signMessage`, `tron_signTransaction`, `tron_chainId`, `tron_switchChain`) and throws on unknown methods so unexpected calls fail loudly in tests.
- `tron_requestAccounts` throws `{ code: 4001 }` when the mock is not "connected" — this drives the user-rejection test (the adapter must wrap it in `WalletConnectionError`).
- The listener registry (`on`/`removeListener`) plus the `_emit` helper let tests simulate provider-originated `accountsChanged`/`chainChanged` events; `_getListenerCount` verifies the adapter unsubscribes on disconnect.
- `_setConnected`/`_setAddress` are test-only helpers that put the mock into a desired state before the adapter's detection polling runs.
- `installMock{{WALLET_CLASS}}` assigns the provider at the wallet's injection key; the wrapper object must mirror the real `{{WALLET_PROVIDER_PATH}}` shape (Backpack: `window.backpack.tron`). `uninstallMock{{WALLET_CLASS}}` clears it (and the generic `window.tron` fallback) so each test starts clean.
- `// @ts-nocheck` matches the real backpack mock — the mock intentionally throws plain objects (4001 rejection) and skips strict typing.

## Variable Mapping

| Placeholder | Example (Backpack) | Description |
| --- | --- | --- |
| `{{WALLET_CLASS}}` | `Backpack` | PascalCase prefix: `Mock{{WALLET_CLASS}}Provider`, `installMock{{WALLET_CLASS}}`, `{{WALLET_CLASS}}TronProvider` |
| `{{WALLET_IS_FIELD}}` | `isBackpack` | Identity flag the adapter checks on the injected provider |
| `{{WALLET_INJECTION_KEY}}` | `backpack` | Key on `window` where the mock is installed |
| `{{WALLET_PROVIDER_PATH}}` | `window.backpack.tron` | Full provider path; dictates the wrapper shape in the install function |

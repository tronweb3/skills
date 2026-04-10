# Mock Provider Template — EVM Wallet Adapter

Create as `tests/units/{{WALLET_DIR}}-provider.ts`.

```typescript
import { EventEmitter } from '@tronweb3/abstract-adapter-evm';
import type { EIP1193Provider } from '@tronweb3/abstract-adapter-evm';

export class {{WALLET_CLASS}}Provider extends EventEmitter {
    {{WALLET_IS_FIELD}} = true;
    providers: EIP1193Provider[] = [];
    constructor() {
        super();
        this.providers = [this];
    }

    request<P = unknown[], T = unknown>({ method }: { method: string; params?: P }): Promise<T> {
        if (method === 'eth_accounts') {
            return Promise.resolve(this._accountsRes as T);
        }
        if (method === 'eth_requestAccounts') {
            this.emit('accountsChanged', this._requestAccountsRes);
            return Promise.resolve(this._requestAccountsRes as T);
        }
        if (method === 'personal_sign') {
            return Promise.resolve(this._personalSignRes as T);
        }
        return Promise.resolve(null as T);
    }

    _accountsRes: string[] = [];
    _requestAccountsRes: string[] = [];
    _personalSignRes = '';
    _setAccountsRes(accounts: string[]) {
        this._accountsRes = accounts;
    }
    _setRequestAccountsRes(accounts: string[]) {
        this._requestAccountsRes = accounts;
    }
    _setPersonalSignRes(res: string) {
        this._personalSignRes = res;
    }
}

export function install{{WALLET_CLASS}}EIP6963Provider(
    provider: EIP1193Provider,
    options: { name?: string; rdns?: string } = {}
) {
    const detail = {
        info: {
            uuid: `${options.rdns || '{{WALLET_RDNS}}'}-${options.name || '{{WALLET_NAME}}'}`,
            name: options.name || '{{WALLET_NAME}}',
            icon: '',
            rdns: options.rdns || '{{WALLET_RDNS}}',
        },
        provider,
    };

    const onRequestProvider = () => {
        window.dispatchEvent(
            new CustomEvent('eip6963:announceProvider', {
                detail,
            })
        );
    };

    window.addEventListener('eip6963:requestProvider', onRequestProvider);

    return () => {
        window.removeEventListener('eip6963:requestProvider', onRequestProvider);
    };
}
```

## Notes

- The mock provider class name uses `{{WALLET_CLASS}}Provider` (e.g., `OkxWalletProvider`)
- The `install` function name uses `install{{WALLET_CLASS}}EIP6963Provider`
- The identifier field (`{{WALLET_IS_FIELD}}`) must be set to `true` on the mock
- The `EventEmitter` class is imported from `@tronweb3/abstract-adapter-evm`

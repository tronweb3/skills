# README Template — EVM Wallet Adapter

```markdown
# `{{NPM_PACKAGE}}`

This package provides an adapter to enable DApps to connect to the [{{WALLET_NAME}}]({{WALLET_URL}}) on EVM-Compatible Chains.

## Demo

\`\`\`typescript
import { {{WALLET_CLASS}}EvmAdapter } from '{{NPM_PACKAGE}}';

const adapter = new {{WALLET_CLASS}}EvmAdapter();
// connect
await adapter.connect();

// then you can get address
console.log(adapter.address);

// just use the sendTransaction method to send a transfer transaction.
const transaction = {
    value: '0x' + Number(0.01 * Math.pow(10, 18)).toString(16), // 0.01 is 0.01ETH
    to: 'your target address',
    from: adapter.address,
};
await adapter.sendTransaction(transaction);
\`\`\`

## Documentation

### API

-   `Constructor(config: {{WALLET_CLASS}}EvmAdapterOptions)`

    \`\`\`typescript
    import { {{WALLET_CLASS}}EvmAdapter } from '{{NPM_PACKAGE}}';
    interface {{WALLET_CLASS}}EvmAdapterOptions {
        /**
         * Set if open {{WALLET_NAME}} app when in mobile device.
         * Default is true.
         */
        useDeeplink?: boolean;
    }
    const adapter = new {{WALLET_CLASS}}EvmAdapter({ useDeeplink: false });
    \`\`\`

More detailed API can be found in [Abstract Adapter](https://github.com/tronweb3/tronwallet-adapter/blob/main/packages/adapters/evm/abstract-adapter/README.md).
```

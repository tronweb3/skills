# README Template — TRON Wallet Adapter

```markdown
# `{{NPM_PACKAGE}}`

This package provides an adapter to enable TRON DApps to connect to the [{{WALLET_NAME}} extension/app]({{WALLET_URL}}).

## Demo

\`\`\`typescript
import { {{WALLET_CLASS}}Adapter } from '{{NPM_PACKAGE}}';

const adapter = new {{WALLET_CLASS}}Adapter();
// connect to {{WALLET_NAME}}
await adapter.connect();

// then you can get address
console.log(adapter.address);

// create a send TRX transaction
const unSignedTransaction = await window.{{WALLET_INJECTION_KEY}}.tronLink.tronWeb.transactionBuilder.sendTrx(
    targetAddress,
    100,
    adapter.address
);
// using adapter to sign the transaction
const signedTransaction = await adapter.signTransaction(unSignedTransaction);
// broadcast the transaction
await window.{{WALLET_INJECTION_KEY}}.tronLink.tronWeb.trx.sendRawTransaction(signedTransaction);
\`\`\`

## Documentation

### API

-   `Constructor(config: {{WALLET_CLASS}}AdapterConfig)`

    \`\`\`typescript
    import { {{WALLET_CLASS}}Adapter } from '{{NPM_PACKAGE}}';
    interface {{WALLET_CLASS}}AdapterConfig {
        /**
         * Set if open Wallet's website when wallet is not installed.
         * Default is true.
         */
        openUrlWhenWalletNotFound?: boolean;
        /**
         * Timeout in millisecond for checking if {{WALLET_NAME}} is supported.
         * Default is 2 * 1000ms
         * Must be a finite number between 0 and 600000 (10 minutes);
         * anything else throws at construction.
         */
        checkTimeout?: number;
        /**
         * Set if open {{WALLET_NAME}} app using DeepLink on mobile device.
         * Default is true.
         */
        openAppWithDeeplink?: boolean;
    }
    const adapter = new {{WALLET_CLASS}}Adapter({ openAppWithDeeplink: false });
    \`\`\`

-   `network()` method is supported to get current network information. The type of returned value is `Network` as follows:

    \`\`\`typescript
    export enum NetworkType {
        Mainnet = 'Mainnet',
        Shasta = 'Shasta',
        Nile = 'Nile',
        /**
         * When use custom node
         */
        Unknown = 'Unknown',
    }

    export type Network = {
        networkType: NetworkType;
        chainId: string;
        fullNode: string;
        solidityNode: string;
        eventServer: string;
    };
    \`\`\`

### Security Check

`{{WALLET_CLASS}}Adapter` supports an optional `securityOptions` field for detecting wallet risks before `connect()`. When enabled, the adapter fetches a remote risk configuration and calls `onRiskDetected` if the wallet is flagged.

\`\`\`typescript
const adapter = new {{WALLET_CLASS}}Adapter({
    securityOptions: {
        enabled: true,
        configUrls: ['https://your-server.com/security-config.json'],
        onRiskDetected: async ({ risks }) => {
            // Throw to block the connection, or log a warning
            throw new Error(\`Wallet risk detected: \${risks[0].title}\`);
        },
    },
});
\`\`\`

For the full `SecurityOptions` API reference, see [walletadapter.org/docs](https://walletadapter.org/docs/index.html).

### Caveats

-   *(list unsupported methods, e.g. `multiSign()` / `switchChain()` if {{WALLET_NAME}} doesn't implement them and they throw)*
-   *(list event differences between extension and app, if any)*
-   *(list deeplink version requirements, if any)*
-   *(note whether auto-reconnect after page refresh is supported)*

For more information about tronwallet adapters, please refer to [`@tronweb3/tronwallet-adapters`](https://github.com/tronweb3/tronwallet-adapter/tree/main/packages/adapters/adapters)
```

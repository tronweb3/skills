# README Template — TRON Wallet Adapter

The package `README.md` for the new adapter. This template merges the structures of the two real READMEs: `packages/adapters/bybit/README.md` (archetype A) and `packages/adapters/backpack/README.md` (archetype B). Keep or delete the marked sections according to the wallet's archetype and feature matrix.

```markdown
# `@tronweb3/tronwallet-adapter-{{WALLET_DIR}}`

This package provides an adapter to enable TRON DApps to connect to [{{WALLET_NAME}}]({{WALLET_URL}}).

## Demo

\`\`\`typescript
import { {{WALLET_CLASS}}Adapter } from '{{NPM_PACKAGE}}';

const adapter = new {{WALLET_CLASS}}Adapter();
// connect to {{WALLET_NAME}}
await adapter.connect();

// then you can get the connected address
console.log(adapter.address);

// sign a message
const signature = await adapter.signMessage('Hello TRON');

// create a send TRX transaction with TronWeb, then sign it with the adapter
const unSignedTransaction = await tronWeb.transactionBuilder.sendTrx(targetAddress, 100, adapter.address);
const signedTransaction = await adapter.signTransaction(unSignedTransaction);
// broadcast the transaction
await tronWeb.trx.sendRawTransaction(signedTransaction);
\`\`\`

## Installation

\`\`\`bash
npm install {{NPM_PACKAGE}}
# or
yarn add {{NPM_PACKAGE}}
# or
pnpm add {{NPM_PACKAGE}}
\`\`\`

## Documentation

### API

-   `Constructor(config: {{WALLET_CLASS}}AdapterConfig)`

\`\`\`typescript
interface {{WALLET_CLASS}}AdapterConfig {
    /**
     * Set if open the Wallet's website when wallet is not installed.
     * Default is true.
     */
    openUrlWhenWalletNotFound?: boolean;
    /**
     * Timeout in millisecond for checking if {{WALLET_NAME}} is supported.
     * Default is 2 * 1000ms
     */
    checkTimeout?: number;
    /**
     * Set if open {{WALLET_NAME}} app using DeepLink on mobile device.
     * Default is true.
     */
    // ^ Archetype A only — delete the `openAppWithDeeplink` field for archetype B
    openAppWithDeeplink?: boolean;
}
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

### Events

The adapter extends `EventEmitter` from `@tronweb3/tronwallet-abstract-adapter` and emits the following events:

-   `connect(address)` — emitted when the wallet is connected.
-   `disconnect()` — emitted when the wallet is disconnected.
-   `stateChanged(state)` — emitted when the adapter state changes.
-   `readyStateChanged(readyState)` — emitted when the wallet detection state changes (`Found` / `NotFound`).
-   `accountsChanged(address)` — emitted when the selected account changes.
-   `chainChanged(chainData)` — emitted when the selected network changes.
-   `error(error)` — emitted when an error occurs.

\`\`\`typescript
adapter.on('connect', (address) => {
    console.log('Connected:', address);
});
adapter.on('accountsChanged', (address) => {
    console.log('Account changed:', address);
});
adapter.on('error', (error) => {
    console.error('Error:', error);
});
\`\`\`

### Caveats

<!-- Keep ONLY the lines that match the wallet's actual feature matrix; delete the rest. -->

-   {{WALLET_NAME}} doesn't support `multiSign()` and will throw an error when called.
-   {{WALLET_NAME}} doesn't support `switchChain()` and will throw an error when called.
-   {{WALLET_NAME}} extension only supports these events: `accountsChanged`, `connect`, `disconnect`.
-   {{WALLET_NAME}} app does not support any events.
-   Currently the deeplink can only open the app but not the dapp browser. <!-- archetype A only -->
-   Currently the deeplink can not open the App Store when the app is not installed. <!-- archetype A only -->
-   {{WALLET_NAME}} only supports `Mainnet` and `Shasta`. <!-- archetype B with limited chain support -->
-   {{WALLET_NAME}} extension cannot be connected automatically after page refresh. <!-- if applicable -->

For more information about tronwallet adapters, please refer to [`@tronweb3/tronwallet-adapters`](https://github.com/tronweb3/tronwallet-adapter/tree/main/packages/adapters/adapters)

## Links

-   [{{WALLET_NAME}}]({{WALLET_URL}})
-   [Abstract Adapter](https://github.com/tronweb3/tronwallet-adapter/tree/main/packages/adapters/abstract-adapter)
-   [Documentation](https://walletadapter.org/)
-   [TRON Developer Hub](https://developers.tron.network)
```

## Key Points

- **Title uses the npm package name** with the directory slug: `@tronweb3/tronwallet-adapter-{{WALLET_DIR}}` — TRON adapters have NO `-evm` suffix.
- **The Demo snippet is archetype-neutral**: it only uses the adapter surface (`connect()`, `.address`, `signMessage()`, `signTransaction()`) plus a generic `tronWeb` instance for building/broadcasting, so it works for both archetypes. Compare `packages/adapters/bybit/README.md` (uses `window.bybitWallet.tronLink.tronWeb` directly) and `packages/adapters/backpack/README.md` (adapter-only surface).
- **Zero-arg constructor in the snippet** — this mirrors how all demos instantiate the adapter and is required by the demo auto-discovery (see `references/demo-integration.md`).
- **`openAppWithDeeplink` is archetype A only.** Archetype B adapters (e.g. backpack) have no deeplink flow, so their config interface only contains `openUrlWhenWalletNotFound` and `checkTimeout`. Delete the field and its doc comment for archetype B.
- **The Caveats section is a checklist, not boilerplate.** Test the real wallet and keep only the true lines: which methods throw (`multiSign`, `switchChain`), which events the extension/app actually emits, deeplink limitations (A) and supported networks (B). Both real READMEs document only what was actually observed.
- **The Events list is the full abstract-adapter event surface** (`connect`/`disconnect`/`stateChanged`/`readyStateChanged`/`accountsChanged`/`chainChanged`/`error`); if the wallet does not deliver some of them, say so in Caveats rather than removing them from the list.
- **Closing links** follow the real READMEs: the aggregate `@tronweb3/tronwallet-adapters` package reference (bybit style) plus the Links block with walletadapter.org and developers.tron.network (backpack style).

## Variable Mapping

| Placeholder | Example (archetype A: Bybit) | Example (archetype B: Backpack) | Notes |
| --- | --- | --- | --- |
| `{{WALLET_NAME}}` | `Bybit Wallet` | `Backpack` | Display name used in prose |
| `{{WALLET_CLASS}}` | `BybitWallet` | `Backpack` | PascalCase prefix → `{{WALLET_CLASS}}Adapter`, `{{WALLET_CLASS}}AdapterConfig` |
| `{{WALLET_DIR}}` | `bybit` | `backpack` | Directory under `packages/adapters/` and npm suffix |
| `{{NPM_PACKAGE}}` | `@tronweb3/tronwallet-adapter-bybit` | `@tronweb3/tronwallet-adapter-backpack` | No `-evm` suffix |
| `{{WALLET_URL}}` | `https://www.bybit.com/en/web3/home` | `https://www.backpack.app` | Official wallet site linked in intro and Links |

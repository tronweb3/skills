# EVM Mock Provider — Reference

## How It Works

The EVM mock provider implements EIP-1193 (`request()` method) and EIP-6963 provider discovery, injected via `page.addInitScript()` before the page loads.

### Provider Discovery Flow

```
1. Mock dispatches `eip6963:announceProvider` CustomEvent on load
2. Mock listens for `eip6963:requestProvider` and re-announces
3. Adapter's EIP-6963 listener picks up the provider
4. Adapter sets readyState = Found
```

### Auto-Connect Prevention

The `userApproved` flag prevents adapters from auto-connecting:

```javascript
// eth_accounts returns [] until eth_requestAccounts is called
case 'eth_accounts':
  return Promise.resolve(userApproved ? currentAccounts.slice() : []);
case 'eth_requestAccounts':
  userApproved = true;
  return Promise.resolve(currentAccounts.slice());
```

Without this, adapters detect accounts on load and show "Connected" immediately, making the Connect button untestable.

### Supported RPC Methods

| Method | Response |
|--------|----------|
| `eth_requestAccounts` | Sets `userApproved=true`, returns test accounts |
| `eth_accounts` | Returns accounts only if approved |
| `eth_chainId` | Returns current chain ID |
| `net_version` | Returns chain ID as decimal string |
| `personal_sign` | Returns deterministic mock signature |
| `eth_signTypedData_v4` | Returns deterministic mock signature |
| `eth_sendTransaction` | Returns random tx hash |
| `eth_getTransactionReceipt` | Returns `{ status: '0x1' }` |
| `wallet_switchEthereumChain` | Updates chain ID, emits `chainChanged` |
| `wallet_addEthereumChain` | Returns null (success) |
| `eth_getBalance` | Returns 100 ETH |
| `eth_estimateGas` | Returns 21000 |
| `eth_blockNumber` | Returns 1 |
| `eth_gasPrice` | Returns 1 gwei |
| `eth_call` | Returns zeros |

### EIP-6963 Announcement Structure

```javascript
{
  info: { uuid: crypto.randomUUID(), name: 'WalletName', icon: 'data:...', rdns: 'com.wallet' },
  provider: providerObject
}
```

### Wallet-Specific Globals

- `com.okex.wallet` → also sets `window.okxwallet`
- All wallets → set `window.ethereum`

### Test Control Helpers

```javascript
// Trigger accountsChanged event
window.__mockEvmProvider._setAccounts(['0xNewAddress']);

// Trigger chainChanged event
window.__mockEvmProvider._setChainId('0x1');

// Direct event emission
window.__mockEvmProvider._emit('accountsChanged', ['0xAddr']);
```

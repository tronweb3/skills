# TRON Mock Provider — Reference

## How It Works

The TRON mock implements TIP-6963 (TRON's equivalent of EIP-6963) + legacy `window.tronLink` / `window.tronWeb` globals.

### Provider Discovery Flow (Desktop)

```
1. Mock dispatches `TIP6963:announceProvider` CustomEvent on load
2. Mock listens for `TIP6963:requestProvider` and re-announces
3. TronLink adapter's _checkWallet() picks up the provider via info.name === 'TronLink'
4. Adapter sets _supportNewTronProtocol = true, readyState = Found
```

### Key Difference from EVM

When TIP-6963 is detected, the adapter uses TIP-1193 protocol:
- **Connect**: `provider.request({ method: 'eth_requestAccounts' })` (NOT `tron_requestAccounts`)
- **Sign**: `provider.tronWeb.trx.signMessageV2(message)` (via tronWeb attached to provider)
- **Events**: `provider.on('accountsChanged', cb)` / `provider.on('chainChanged', cb)`

### Initial State

The mock starts **disconnected** (no address):

```javascript
currentAddress = '';
mockTronWeb.defaultAddress = { base58: '', hex: '' };
mockTronWeb.ready = false;
```

Address is set only on `eth_requestAccounts` (connect).

### Supported RPC Methods

| Method | Response |
|--------|----------|
| `eth_requestAccounts` | Sets address, returns `[address]` |
| `tron_requestAccounts` | Legacy fallback, returns `{ code: 200 }` |
| `tron_accounts` | Returns accounts if connected |
| `tron_chainId` | Returns current chain ID |
| `tron_signMessageV2` | Returns mock signature |
| `tron_signTransaction` | Returns tx with mock signature |
| `wallet_switchEthereumChain` | Updates chain, emits `chainChanged` |

### TronWeb Mock Subset

```javascript
mockTronWeb = {
  ready: false,
  defaultAddress: { base58: '', hex: '' },
  toSun(trx), fromSun(sun), isAddress(addr),
  address: { toHex(), fromHex() },
  trx: {
    getBalance(), getAccount(), getBlockByNumber(num),
    sendRawTransaction(tx), sign(tx),
    signMessageV2(message), multiSign(tx, pk, permissionId),
    verifyMessageV2()
  },
  transactionBuilder: {
    sendTrx(to, amount, from),
    triggerSmartContract()
  },
  fullNode, solidityNode, eventServer
}
```

### TIP-6963 Announcement Structure

```javascript
{
  info: { uuid: crypto.randomUUID(), name: 'TronLink', icon: 'data:...', rdns: 'org.tronlink.www' },
  provider: tronProvider  // has .tronWeb, .request(), .on(), .isTronLink
}
```

### Legacy Globals (Fallback)

Also set for backward compatibility:
- `window.tronLink` — with `ready`, `tronWeb`, `request()`
- `window.tronWeb` — the mock TronWeb object

### Test Control Helpers

```javascript
// Trigger accountsChanged event
window.__mockTronProvider._setAccounts('TNewAddr...', '41HEXADDR...');

// Trigger chainChanged event
window.__mockTronProvider._setChainId('0x2b6653dc');  // Mainnet

// Direct event emission
window.__mockTronProvider._emit('chainChanged', { chainId: '0x2b6653dc' });
```

### TRON Chain IDs

| Network | Chain ID |
|---------|----------|
| Mainnet | `0x2b6653dc` |
| Shasta | `0x94a9059e` |
| Nile | `0xcd8690dc` |

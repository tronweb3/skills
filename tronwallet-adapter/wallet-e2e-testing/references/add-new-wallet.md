# Adding a New Wallet Adapter — Template

## EVM Wallet (3 steps)

### Step 1: Add wallet config to `fixtures.ts`

In the `EVM_WALLETS` object:

```typescript
NewWallet: {
  walletName: 'New Wallet',        // Must match EIP-6963 info.name
  rdns: 'com.newwallet.app',       // Must match adapter's expected RDNS
  icon: 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg"/>',
  selectLabel: 'New Wallet',       // Must match adapter.name shown in dropdown
},
```

**Finding the correct values:**
- `rdns`: Check `packages/adapters/evm/<wallet>/src/utils.ts` for the RDNS constant
- `selectLabel`: Check the adapter class — it's usually `adapter.name`
- `walletName`: Must match what the real extension announces via EIP-6963

### Step 2: Add to test loop in `evm.spec.ts`

In the `walletsToTest` array:

```typescript
const walletsToTest: Array<[string, EvmWalletConfig]> = [
  ['MetaMask', EVM_WALLETS.MetaMask],
  ['OKX Wallet', EVM_WALLETS.OKXWallet],
  ['TronLinkEvm', EVM_WALLETS.TronLinkEvm],
  ['Trust Wallet', EVM_WALLETS.Trust],
  ['New Wallet', EVM_WALLETS.NewWallet],  // ← add here
];
```

### Step 3: Run and verify

```bash
pnpm test:e2e:evm
```

All 8 tests auto-run for the new wallet. If a test fails:
- **Display fails**: Wrong `selectLabel` (check adapter dropdown name)
- **Connect fails**: Wrong `rdns` (check adapter source for RDNS)
- **readyState Loading**: Adapter may need wallet-specific globals (like `window.okxwallet`)

## TRON Wallet (more involved)

TRON wallets have unique detection mechanisms. Follow `buildTronInjectionScript()` as reference.

### Key points:
1. New injection script must respond to TIP-6963 if the adapter uses it
2. Must provide `tronWeb` with at minimum: `defaultAddress`, `trx.sign`, `trx.signMessageV2`
3. Must support `request({ method: 'eth_requestAccounts' })` for TIP-1193 adapters
4. Create new `*.spec.ts` and add to `playwright.config.ts` projects

## Common Pitfalls

| Issue | Root Cause | Fix |
|-------|-----------|-----|
| adapter not in dropdown | Wrong `selectLabel` | Read adapter.name from source |
| readyState = "Loading" | Missing provider announcement | Implement EIP-6963/TIP-6963 |
| auto-connects on load | `eth_accounts` returns accounts | Use `userApproved` flag pattern |
| strict mode violation | `text=X` matches 2+ elements | Use `getByText(X, { exact: true })` |
| connect opens new tab | adapter.state = NotFound | Mock missing required globals |

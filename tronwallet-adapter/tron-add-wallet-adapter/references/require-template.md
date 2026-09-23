# Requirements Template — TRON Wallet Adapter

Use this template to create `requires/<version>/require.md`.

---

```markdown
# <version> Requirements: {{WALLET_NAME}} TRON Adapter

## 1. Background

TronWallet Adapter is an open-source multi-chain wallet integration project that already supports
TronLink, OKX Wallet, Bitget Wallet, TokenPocket, and other native TRON wallet adapters. To expand
TRON ecosystem coverage, a new {{WALLET_NAME}} TRON adapter is needed.

## 2. Requirements Overview

### 2.1 Core Requirements
Add the `{{NPM_PACKAGE}}` package in <version>, ensuring:
- Consistency with the existing TRON Adapter framework (`@tronweb3/tronwallet-abstract-adapter`, `AddonAdapter`)
- Correct detection of {{WALLET_NAME}}'s injected provider on `window.{{WALLET_INJECTION_KEY}}`
- Support for desktop browser extension and/or mobile app WebView / DeepLink, as applicable to this wallet

### 2.2 Feature Scope

#### 2.2.1 Basic Features
- ✅ **Wallet Detection**: Poll for `window.{{WALLET_INJECTION_KEY}}` and set `readyState`
- ✅ **Wallet Connection**: Connect via the wallet's request/authorize call
- ✅ **Account Retrieval**: Retrieve the user's TRON (base58) address
- ✅ **Sign Message**: `signMessage()` via `tronWeb.trx.signMessageV2`
- ✅ **Sign Transaction**: `signTransaction()` via `tronWeb.trx.sign`
- ✅ **Network Info**: `network()` via `getNetworkInfoByTronWeb()` (if the wallet exposes `tronWeb`)

#### 2.2.2 Advanced Features (include only what the wallet actually supports)
- ⬜ **Multi-Sign**: `multiSign()` via `tronWeb.trx.multiSign`
- ⬜ **Event Listening**: `accountsChanged`, `connect`, `disconnect` — via `window.postMessage` or polling, matching how {{WALLET_NAME}} actually notifies the page
- ⬜ **Mobile DeepLink**: Open {{WALLET_NAME}} app via DeepLink in mobile browsers
- ⬜ **Security Check**: Optional `securityOptions` risk-check before connect (inherited from `AddonAdapter`, no extra work needed unless disabled)

#### 2.2.3 Integration Support
- ✅ **Unified Export**: Re-exported via `@tronweb3/tronwallet-adapters`
- ✅ **TypeScript**: Full type definitions, reusing `TronLinkWallet`/`Tron` types where the provider is TronLink-compatible
- ✅ **ESM + CJS**: Dual-format output

## 3. Technical Requirements

### 3.1 Code Standards
- Extend the `AddonAdapter` base class (from `@tronweb3/tronwallet-abstract-adapter`)
- Follow the closest-matching reference implementation from [detection-patterns.md](./detection-patterns.md)
- No additional runtime dependencies beyond `@tronweb3/tronwallet-abstract-adapter` and (if applicable) `@tronweb3/tronwallet-adapter-tronlink`

### 3.2 Compatibility Requirements
- **Browsers**: Chrome, Firefox, Safari, Edge (latest two versions)
- **Node.js**: >= 16
- **Network**: TRON Mainnet, Shasta, Nile testnets

### 3.3 Dependencies
- `@tronweb3/tronwallet-abstract-adapter: workspace:^`
- `@tronweb3/tronwallet-adapter-tronlink: workspace:^` (only if the provider is TronLink-compatible)

## 4. Testing Requirements

### 4.1 Unit Tests
- [ ] Base property validation (name, url, readyState, address, connecting, connected)
- [ ] `connect()` succeeds and sets address when the wallet reports one
- [ ] `connect()` rejects with `WalletConnectionError` when the reported address is missing/empty/falsy (do not silently "connect" with no address)
- [ ] `connect()` throws `WalletNotFoundError` when the wallet isn't detected
- [ ] `signMessage()` / `signTransaction()` wrap thrown errors correctly
- [ ] Event propagation (`accountsChanged`, `disconnect`) if the wallet supports it, including that stale/late events don't resurrect state after `disconnect()`

## 5. Acceptance Criteria

### 5.1 Functional Acceptance
- [ ] All applicable basic and advanced features implemented and tested
- [ ] Fully integrated with React/Vue ecosystem (auto-discovered via the adapters barrel)
- [ ] Mobile and/or browser extension work correctly, matching what {{WALLET_NAME}} actually supports

### 5.2 Quality Acceptance
- [ ] Unit test coverage >= 80%
- [ ] TypeScript types complete, no `any` beyond what upstream wallet typings force
- [ ] Code style conforms to project standards

### 5.3 Documentation Acceptance
- [ ] README includes API docs and usage examples
- [ ] Caveats section documents unsupported methods and event differences between platforms

### 5.4 Integration Acceptance
- [ ] cdn-demo updated and shows {{WALLET_NAME}} in the wallet selector
- [ ] dev-demo / react-ui / vue-ui show {{WALLET_NAME}} automatically (or via explicit wiring if mandatory config is required)
- [ ] No conflicts with other adapters
- [ ] Build passes completely (ESM + CJS + types + UMD)
```

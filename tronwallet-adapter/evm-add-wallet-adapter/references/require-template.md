# Requirements Template — EVM Wallet Adapter

Use this template to create `requires/<version>/require.md`.

---

```markdown
# <version> Requirements: {{WALLET_NAME}} EVM Adapter

## 1. Background

TronWallet Adapter is an open-source multi-chain wallet integration project that already supports MetaMask, TronLink, Trust Wallet, Binance, and other EVM wallet adapters. To expand EVM ecosystem coverage, a new {{WALLET_NAME}} EVM adapter is needed.

## 2. Requirements Overview

### 2.1 Core Requirements
Add the `{{NPM_PACKAGE}}` package in <version>, ensuring:
- Compliance with EIP-1193 (Provider API) and EIP-6963 (Provider Discovery) standards
- Consistency with the existing EVM Adapter framework (`@tronweb3/abstract-adapter-evm`)
- Support for desktop browser extensions and mobile WebView / DeepLink

### 2.2 Feature Scope

#### 2.2.1 Basic Features
- ✅ **Wallet Connection**: Connect {{WALLET_NAME}} via `eth_requestAccounts`
- ✅ **Provider Discovery**: Support EIP-6963 standard (rdns: `{{WALLET_RDNS}}`)
- ✅ **Injected Provider**: Support `{{WALLET_INJECTION}}` injection detection
- ✅ **Account Retrieval**: Retrieve user's EVM address
- ✅ **Transaction Sending**: Send transactions via `eth_sendTransaction`
- ✅ **Message Signing**: Sign messages via `personal_sign`
- ✅ **Typed Data Signing**: Sign EIP-712 data via `eth_signTypedData_v4`

#### 2.2.2 Advanced Features
- ✅ **Chain Switching**: Switch chains via `wallet_switchEthereumChain`
- ✅ **Chain Adding**: Add new chains via `wallet_addEthereumChain`
- ✅ **Asset Watching**: Add tokens via `wallet_watchAsset`
- ✅ **Event Listening**: Listen to `accountsChanged`, `chainChanged`, `connect`, `disconnect`
- ✅ **Auto-Connect**: Restore connected accounts via `eth_accounts`
- ✅ **Mobile DeepLink**: Open {{WALLET_NAME}} app via DeepLink in mobile browsers

#### 2.2.3 Integration Support
- ✅ **Unified Export**: Re-exported via `@tronweb3/tronwallet-adapters`
- ✅ **TypeScript**: Full type definitions
- ✅ **ESM + CJS**: Dual-format output

## 3. Technical Requirements

### 3.1 Code Standards
- Extend the `Adapter` base class (from `@tronweb3/abstract-adapter-evm`)
- Follow the MetaMask / Trust EVM adapter implementation patterns
- No additional runtime dependencies

### 3.2 Compatibility Requirements
- **Browsers**: Chrome, Firefox, Safari, Edge (latest two versions)
- **Node.js**: >= 16
- **EVM Chains**: All EVM-compatible chains

### 3.3 Dependencies
- `@tronweb3/abstract-adapter-evm: workspace:^` (only runtime dependency)

## 4. Testing Requirements

### 4.1 Unit Tests
- [ ] Base property validation (name, url, readyState)
- [ ] EIP-6963 Provider discovery
- [ ] Injected Provider detection (mobile WebView)
- [ ] Wrong rdns rejection
- [ ] signTypedData correct serialization
- [ ] connect success/failure
- [ ] Throw WalletNotFoundError when wallet not found

## 5. Acceptance Criteria

### 5.1 Functional Acceptance
- [ ] All basic and advanced features implemented and tested
- [ ] Fully integrated with React/Vue ecosystem
- [ ] Mobile and browser extension both work correctly

### 5.2 Quality Acceptance
- [ ] Unit test coverage >= 80%
- [ ] TypeScript types complete, no `any`
- [ ] Code style conforms to project standards

### 5.3 Documentation Acceptance
- [ ] README includes API docs and usage examples
- [ ] Troubleshooting guide is comprehensive

### 5.4 Integration Acceptance
- [ ] All 4 demo projects can use {{WALLET_NAME}} correctly
- [ ] No conflicts with other adapters
- [ ] Build passes completely (ESM + CJS + types + UMD)
```

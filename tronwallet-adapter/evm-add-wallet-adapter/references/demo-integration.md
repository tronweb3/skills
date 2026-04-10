# Demo Integration Guide — EVM Wallet Adapter

After the adapter package is built, integrate it into all 4 demo apps.

## 1. cdn-demo (`demos/cdn-demo/evm/`)

### index.html — Add UMD script tag

Add after the last EVM adapter script tag:

```html
<script src="../node_modules/{{NPM_PACKAGE}}/lib/umd/index.js"></script>
```

### App.js — Add adapter instance

Add destructuring from window global:

```javascript
const { {{WALLET_CLASS}}EvmAdapter } = window['{{NPM_PACKAGE}}'];
```

Add to the adapter options array:

```javascript
new {{WALLET_CLASS}}EvmAdapter(),
```

### package.json — Add dependency

```json
"{{NPM_PACKAGE}}": "^1.0.0"
```

**Important**: Must run `pnpm run build:umd` in the adapter package first.

## 2. dev-demo (`demos/dev-demo/`)

### src/AdapterBasicTest.tsx — Add import and instance

Add import:

```typescript
import { {{WALLET_CLASS}}EvmAdapter } from '{{NPM_PACKAGE}}';
```

Add to adapters array:

```typescript
new {{WALLET_CLASS}}EvmAdapter(),
```

### src/EvmAdapterDemo.tsx — Add import and instance

Same import as above. Add to the `useMemo(() => [...], [])` array.

### package.json — Add dependency

```json
"{{NPM_PACKAGE}}": "latest"
```

## 3. react-ui (`demos/react-ui/vite-app/`)

### src/EvmDemo.tsx — Add to adapter list

Add import:

```typescript
import { {{WALLET_CLASS}}EvmAdapter } from '{{NPM_PACKAGE}}';
```

Add to the `useMemo` adapters array:

```typescript
const adapters = useMemo(() => [new {{WALLET_CLASS}}EvmAdapter(), ...otherAdapters], []);
```

### package.json — Add dependency

```json
"{{NPM_PACKAGE}}": "latest"
```

Also ensure these deps exist:
- `"@tronweb3/abstract-adapter-evm": "latest"`
- `"@tronweb3/tronwallet-adapter-metamask-evm": "latest"`

## 4. vue-ui (`demos/vue-ui/vite-app/`)

### src/components/EvmDemo.vue — Add to adapter list

Add import in `<script setup>`:

```typescript
import { {{WALLET_CLASS}}EvmAdapter } from '{{NPM_PACKAGE}}';
```

Add to adapters array:

```typescript
const adapters: AdapterEvm[] = [new {{WALLET_CLASS}}EvmAdapter(), ...otherAdapters];
```

### package.json — Add dependency

```json
"{{NPM_PACKAGE}}": "latest"
```

Also ensure these deps exist:
- `"@tronweb3/abstract-adapter-evm": "latest"`
- `"@tronweb3/tronwallet-adapter-metamask-evm": "latest"`

## Notes

- The `EvmDemo.tsx` (react-ui) and `EvmDemo.vue` (vue-ui) are standalone EVM demo components rendered OUTSIDE the TRON `WalletProvider`
- If `EvmDemo.tsx` or `EvmDemo.vue` don't exist yet (first EVM adapter), create them following the patterns in the OKXWallet implementation
- cdn-demo requires UMD build; other demos use ES module imports
- After adding deps, run `pnpm install` from the monorepo root

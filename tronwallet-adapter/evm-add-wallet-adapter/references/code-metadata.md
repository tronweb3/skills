# metadata.ts Template — EVM Wallet Adapter

This file holds wallet identity constants (name, url, icon) in a single place, keeping the adapter class clean and making metadata easy to find and update.

```typescript
import type { AdapterName } from '@tronweb3/abstract-adapter-evm';

export const {{WALLET_CLASS}}EvmAdapterName = '{{WALLET_NAME}}' as AdapterName<'{{WALLET_NAME}}'>;

export const METADATA = {
    name: {{WALLET_CLASS}}EvmAdapterName,
    url: '{{WALLET_URL}}',
    icon: '{{WALLET_ICON}}',
} as const;
```

## Key Points

1. **Single source of truth**: All wallet identity info lives here — not scattered across adapter.ts.
2. **Re-exported via index.ts**: Consumers can import `OkxWalletEvmAdapterName` and `METADATA` directly.
3. **`as const`**: Ensures literal types for the METADATA object.
4. **Icon format**: Use base64-encoded data URI (`data:image/png;base64,...` or `data:image/svg+xml;base64,...` or `data:image/webp;base64,...`).

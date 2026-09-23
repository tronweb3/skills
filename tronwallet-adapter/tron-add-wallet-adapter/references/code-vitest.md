# vitest.config.ts Template — TRON Wallet Adapter

```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
    test: {
        globals: true,
        environment: 'happy-dom',
    },
    ssr: {
        noExternal: ['@tronweb3/tronwallet-abstract-adapter', '@tronweb3/tronwallet-adapter-tronlink'],
    },
});
```

All TRON adapters use `happy-dom` for browser API simulation (`window`, `navigator`, DOM events).
`ssr.noExternal` must list every workspace package the adapter imports directly — drop
`@tronweb3/tronwallet-adapter-tronlink` from the array if the adapter doesn't depend on it.

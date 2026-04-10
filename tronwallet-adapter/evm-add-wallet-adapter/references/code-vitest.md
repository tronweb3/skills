# vitest.config.ts Template — EVM Wallet Adapter

```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
    test: {
        globals: true,
        environment: 'happy-dom',
    },
});
```

All EVM adapters use `happy-dom` for browser API simulation (window, DOM events, navigator).

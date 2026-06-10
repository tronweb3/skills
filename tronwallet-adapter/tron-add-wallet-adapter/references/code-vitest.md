# vitest.config.ts Template — TRON Wallet Adapter

The filename `vitest.config.ts` is the convention for TRON adapter packages. No placeholders.

```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
    test: {
        globals: true,
        environment: 'happy-dom',
    },
});
```

> **Archetype A only (TronLink-compatible):** add an `ssr.noExternal` block so Vitest inlines the workspace dependencies (copied exactly from packages/adapters/bybit/vitest.config.ts):
>
> ```typescript
> import { defineConfig } from 'vitest/config';
>
> export default defineConfig({
>     test: {
>         globals: true,
>         environment: 'happy-dom',
>     },
>     ssr: {
>         noExternal: ['@tronweb3/tronwallet-abstract-adapter', '@tronweb3/tronwallet-adapter-tronlink'],
>     },
> });
> ```

## Key Points

1. **`happy-dom` environment**: All adapters need browser APIs (window, DOM events, navigator) in tests; `happy-dom` is resolved from the monorepo root — do not add it to the package's devDependencies.
2. **`globals: true`**: Lets tests use `describe`/`it`/`expect` without imports, matching the existing test suites.
   - **Filename note**: 15 of 18 adapter packages use `vitest.config.ts`; the `backpack` reference package names this file `vite.config.ts`. Vitest reads either name and the content is identical — prefer `vitest.config.ts` to match the majority convention.
3. **`ssr.noExternal` (Archetype A)**: Forces Vitest to bundle the workspace packages instead of externalizing them, so the uncompiled `workspace:^` dependencies (`@tronweb3/tronwallet-abstract-adapter` and `@tronweb3/tronwallet-adapter-tronlink`) resolve correctly in tests. Archetype B adapters depend only on abstract-adapter and omit the block (see packages/adapters/backpack/).

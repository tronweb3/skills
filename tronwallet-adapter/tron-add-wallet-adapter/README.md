# tron-add-wallet-adapter

An AI-agent skill for adding a new **TRON (native chain) wallet adapter** to the [tronwallet-adapter](https://github.com/tronweb3/tronwallet-adapter) monorepo — from requirements gathering to demo integration.

## Overview

This skill encodes a proven 7-phase workflow that produces a complete, production-ready adapter package:

1. **Requirements** — Gather wallet characteristics (name, URL, icon, injection key, feature matrix) and make the **mandatory archetype decision**: Archetype A (TronLink-compatible) or Archetype B (provider request-based). All code/test templates fork on this decision.
2. **Plan** — Generate a structured development plan with file manifest and task breakdown
3. **Implementation** — Scaffold the adapter package (`adapter.ts`, `utils.ts`, `index.ts`, configs) from the archetype-specific templates
4. **Tests** — Create a full test suite with an archetype-specific mock wallet/provider
5. **Registration** — Wire the adapter into the monorepo in all 5 registration points
6. **Documentation** — Generate a README with API docs and usage examples
7. **Demo Integration** — Wire the cdn-demo; dev-demo, React UI, and Vue UI pick the adapter up automatically

## Target Project

| | |
|---|---|
| **Repository** | [tronweb3/tronwallet-adapter](https://github.com/tronweb3/tronwallet-adapter) |
| **Package location** | `packages/adapters/<wallet-name>/` |
| **Tech stack** | TypeScript, Vitest, pnpm workspaces |
| **Build outputs** | ESM, CJS, TypeScript declarations, UMD |

## Prerequisites

- Node.js >= 16
- pnpm >= 7
- A cloned copy of the [tronwallet-adapter](https://github.com/tronweb3/tronwallet-adapter) monorepo

## Usage

### With an AI Coding Agent

Copy this skill folder to your project:

```bash
# From the tronwallet-adapter repo root
cp -r /path/to/skills/tronwallet-adapter/tron-add-wallet-adapter .claude/skills/
```

Then simply ask the agent:

```
Add a Foo TRON wallet adapter
```

The agent will automatically:
- Detect the skill and follow the 7-phase workflow
- Decide the provider archetype (A or B) and pick the matching templates
- Substitute all `{{PLACEHOLDER}}` variables with wallet-specific values
- Create all source files, tests, configs, and documentation
- Register the adapter in all 5 monorepo registration points
- Wire the cdn-demo and verify auto-discovery in dev-demo

### Manual Use

1. Open [SKILL.md](./SKILL.md) and follow the phases sequentially.
2. Use the **variable substitution table** to replace placeholders in all templates under `references/`.
3. Follow the **checklist** at the bottom to verify completeness.

## Variable Substitution

All templates use `{{PLACEHOLDER}}` syntax. Replace these with your wallet-specific values:

| Placeholder | Archetype | Example (A: Bybit / B: Backpack) |
|-------------|-----------|----------------------------------|
| `{{WALLET_NAME}}` | both | `Bybit Wallet` / `Backpack` |
| `{{WALLET_CLASS}}` | both | `BybitWallet` / `Backpack` |
| `{{WALLET_DIR}}` | both | `bybit` / `backpack` |
| `{{NPM_PACKAGE}}` | both | `@tronweb3/tronwallet-adapter-bybit` / `@tronweb3/tronwallet-adapter-backpack` |
| `{{WALLET_URL}}` | both | `https://www.bybit.com/web3` / `https://backpack.app` |
| `{{WALLET_ICON}}` | both | `data:image/svg+xml;base64,...` |
| `{{WALLET_INJECTION_KEY}}` | both | `bybitWallet` / `backpack` |
| `{{WALLET_PROVIDER_PATH}}` | B only | `window.backpack.tron` |
| `{{WALLET_IS_FIELD}}` | B only | `isBackpack` |
| `{{WALLET_DEEPLINK}}` | A only | `https://app.bybit.com/...` |
| `{{WALLET_APP_UA_MARKER}}` | A only | `bybit_app` |

## File Structure

```
tron-add-wallet-adapter/
├── SKILL.md                            # Main workflow (7 phases + checklist)
├── README.md                           # This file
└── references/
    ├── require-template.md             # Phase 1: Requirements document template
    ├── archetype-decision.md           # Phase 1: How to decide Archetype A vs B (mandatory)
    ├── plan-template.md                # Phase 2: Development plan template
    ├── code-adapter-tronlink-style.md  # Phase 3: adapter.ts — Archetype A (TronLink-compatible)
    ├── code-adapter-provider-style.md  # Phase 3: adapter.ts — Archetype B (provider request-based)
    ├── code-utils-tronlink-style.md    # Phase 3: utils.ts — Archetype A (detection + deeplink)
    ├── code-utils-provider-style.md    # Phase 3: utils.ts — Archetype B (provider detection)
    ├── code-package-json.md            # Phase 3: package.json
    ├── code-tsconfig.md                # Phase 3: tsconfig files (all, CJS, ESM)
    ├── code-vitest.md                  # Phase 3: vitest.config.ts
    ├── code-tests-tronlink-style.md    # Phase 4: adapter.test.ts — Archetype A test suite
    ├── code-tests-provider-style.md    # Phase 4: adapter.test.ts — Archetype B test suite
    ├── code-mock-tronlink-style.md     # Phase 4: mock TronLink-shaped wallet (Archetype A)
    ├── code-mock-provider-style.md     # Phase 4: mock request-based provider (Archetype B)
    ├── docs-readme.md                  # Phase 6: adapter README template
    └── demo-integration.md             # Phase 7: cdn-demo wiring + auto-discovery verification
```

## Generated Package Structure

After running the skill, the output adapter package looks like:

```
packages/adapters/<wallet-name>/
├── package.json
├── LICENSE
├── README.md
├── tsconfig.all.json
├── tsconfig.cjs.json
├── tsconfig.esm.json
├── vitest.config.ts
├── src/
│   ├── index.ts                    # Re-exports adapter + utils
│   ├── adapter.ts                  # Main adapter class (identity props inline)
│   └── utils.ts                    # Provider detection, mobile/deeplink helpers
└── tests/
    └── units/
        ├── adapter.test.ts         # Full test suite
        ├── mock.ts                 # Mock wallet/provider (archetype-specific)
        └── utils.ts                # wait() / CHECK_TIMEOUT test helpers
```

## Key Design Decisions

- **Two provider archetypes**: Most TRON wallets (Bybit, OKX, TokenPocket, imToken, etc.) inject a TronLink-shaped object (`.tronWeb`, `.ready`, `request({ method: 'tron_requestAccounts' })`) — Archetype A. Modern wallets like Backpack expose a pure request-based provider (`tron_accounts`, `tron_signMessage`, `tron_signTransaction`, ...) — Archetype B. The two surfaces differ enough (signing path, events, dependencies) that the adapter, utils, test, and mock templates fork rather than branch internally.
- **Wallet identity inline**: `name`, `url`, and `icon` are `readonly` properties declared directly on the adapter class — there is **no `metadata.ts`** in TRON adapters.
- **Polling detection**: The adapter polls for the injected provider (`_checkWallet`, every 100ms up to `checkTimeout`) instead of EIP-6963 discovery — rdns-based announcement does not exist for TRON providers.
- **Auto-discovery contract**: The demo apps discover TRON adapters automatically through the aggregate `@tronweb3/tronwallet-adapters` package, so every adapter must support a **zero-argument constructor** (all options defaulted).
- **Archetype B chainId map**: Network identification uses TRON genesis-block chainIds — `0x2b6653dc` (Mainnet), `0x94a9059e` (Shasta), `0xcd8690dc` (Nile) — for `tron_chainId` / `tron_switchChain`.

## License

[MIT](../../LICENSE)

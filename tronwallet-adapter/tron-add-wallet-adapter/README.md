# tron-add-wallet-adapter

An AI-agent skill for adding a new **native TRON wallet adapter** to the [tronwallet-adapter](https://github.com/tronweb3/tronwallet-adapter) monorepo — from provider research to demo integration. This is the TRON counterpart to `evm-add-wallet-adapter`; use that one instead for EIP-1193/EVM-only wallets.

## Overview

This skill encodes the workflow this repo already follows for its 17+ existing TRON adapters
(OKX Wallet, Bitget Wallet, TronLink, TokenPocket, FoxWallet, GateWallet, ImToken, Bybit, Trust,
Guarda, Binance, SafePal, OneKey, Backpack, ...):

1. **Research** — Determine how the wallet actually injects its provider (there's no discovery
   protocol like EIP-6963 on TRON — every wallet does this differently)
2. **Requirements** — Gather wallet characteristics (name, URL, icon, injection path, deeplink)
3. **Plan** — Generate a structured development plan with file manifest and task breakdown
4. **Implementation** — Scaffold the adapter package (`adapter.ts`, `utils.ts`, `index.ts`, configs)
5. **Tests** — Create a test suite covering connect success/failure, address validation, and signing
6. **Registration** — Wire the adapter into the monorepo (adapters index, package.json, tsconfig references)
7. **Documentation** — Generate a README with API docs and usage examples
8. **Demo Integration** — Update `cdn-demo`; verify auto-discovery in `dev-demo`/`react-ui`/`vue-ui`

## Target Project

| | |
|---|---|
| **Repository** | [tronweb3/tronwallet-adapter](https://github.com/tronweb3/tronwallet-adapter) |
| **Package location** | `packages/adapters/<wallet-name>/` |
| **Tech stack** | TypeScript, Vitest, pnpm workspaces |
| **Build outputs** | ESM, CJS, TypeScript declarations, UMD |
| **Base class** | `AddonAdapter` (from `@tronweb3/tronwallet-abstract-adapter`) |

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
Add a Backpack TRON wallet adapter
```

The agent will:
- Research how the wallet actually injects its provider (no fixed discovery protocol on TRON)
- Pick the closest-matching reference adapter from `detection-patterns.md`
- Substitute all `{{PLACEHOLDER}}` variables with wallet-specific values
- Create all source files, tests, configs, and documentation
- Register the adapter in the monorepo
- Update `cdn-demo`, and verify the adapter appears automatically in `dev-demo`/`react-ui`/`vue-ui`

### Manual Use

1. Open [SKILL.md](./SKILL.md) and follow the phases sequentially.
2. Start with [detection-patterns.md](./references/detection-patterns.md) to identify which
   existing adapter is the closest match for the new wallet's provider shape.
3. Use the **variable substitution table** in SKILL.md to replace placeholders in all templates under `references/`.
4. Follow the **checklist** at the bottom of SKILL.md to verify completeness.

## Variable Substitution

All templates use `{{PLACEHOLDER}}` syntax. Replace these with your wallet-specific values:

| Placeholder | Example (OKX Wallet) |
|-------------|---------------------|
| `{{WALLET_NAME}}` | `OKX Wallet` |
| `{{WALLET_CLASS}}` | `OkxWallet` |
| `{{WALLET_DIR}}` | `okxwallet` |
| `{{WALLET_URL}}` | `https://okx.com` |
| `{{WALLET_ICON}}` | `data:image/svg+xml;base64,...` |
| `{{WALLET_INJECTION_KEY}}` | `okxwallet` |
| `{{WALLET_DEEPLINK}}` | `okx://wallet/dapp/url?dappUrl=` |
| `{{NPM_PACKAGE}}` | `@tronweb3/tronwallet-adapter-okxwallet` |

## File Structure

```
tron-add-wallet-adapter/
├── SKILL.md                        # Main workflow (7 phases + checklist)
├── README.md                       # This file
└── references/
    ├── detection-patterns.md       # Phase 0: survey of every provider-injection shape in this repo
    ├── require-template.md         # Phase 1: Requirements document template
    ├── plan-template.md            # Phase 2: Development plan template
    ├── code-adapter.md             # Phase 3: adapter.ts — main adapter class (TronLink-compatible template)
    ├── code-utils.md               # Phase 3: utils.ts — provider detection & deeplink
    ├── code-package-json.md        # Phase 3: package.json
    ├── code-tsconfig.md            # Phase 3: tsconfig files (ESM, CJS, all)
    ├── code-vitest.md              # Phase 3: vitest.config.ts
    ├── code-tests.md               # Phase 4: adapter.test.ts — connect/sign/address-validation cases
    ├── docs-readme.md              # Phase 6: adapter README template
    └── demo-integration.md         # Phase 7: 4-demo integration guide (cdn-demo manual, others auto-discovered)
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
│   ├── adapter.ts                  # Main adapter class — name/url/icon live here, no metadata.ts
│   └── utils.ts                    # Provider detection, deeplink
└── tests/
    └── units/
        └── adapter.test.ts
```

## Key Design Decisions

- **No discovery protocol**: unlike EVM's EIP-6963, TRON wallets don't announce themselves —
  every adapter polls a wallet-specific global on `window` (interval-based, never caching a
  negative detection, since extensions can inject late or be toggled on at runtime).
- **`AddonAdapter` base class**: provides `commonConfig`, `checkSecurity()`,
  connect-call serialization, and `_beforeConnect()` for free — subclasses implement `_connect()`,
  `_checkWallet()`, and `_openAppByDeepLinkIfNeed()`.
- **No `metadata.ts`**: identity (`name`, `url`, `icon`) lives directly as class fields, matching
  every existing TRON adapter — unlike this repo's EVM adapters, which do split it out.
- **TronLink-compatible by default**: most wallets wrap a `{ tronWeb, request(), ready }` object
  compatible with `@tronweb3/tronwallet-adapter-tronlink`'s `TronLinkWallet` type — reuse those
  types and `getNetworkInfoByTronWeb()` instead of redefining them.
- **Lightweight demo integration**: `dev-demo`, `react-ui`, and `vue-ui` auto-discover every
  `*Adapter` export from the `@tronweb3/tronwallet-adapters` barrel via `Object.entries()`
  reflection — a new adapter with an argument-free constructor needs zero changes there. Only
  `cdn-demo` (per-package UMD `<script>` tags, no bundler) needs manual wiring.

## License

[MIT](../../LICENSE)

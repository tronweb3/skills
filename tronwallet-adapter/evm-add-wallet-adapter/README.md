# evm-add-wallet-adapter

An AI-agent skill for adding a new **EVM-compatible wallet adapter** to the [tronwallet-adapter](https://github.com/tronprotocol/tronwallet-adapter) monorepo — from requirements gathering to demo integration.

## Overview

This skill encodes a proven 7-phase workflow that produces a complete, production-ready adapter package:

1. **Requirements** — Gather wallet characteristics (name, URL, icon, provider injection, EIP-6963 rdns, deeplink scheme)
2. **Plan** — Generate a structured development plan with file manifest and task breakdown
3. **Implementation** — Scaffold the adapter package (`metadata.ts`, `adapter.ts`, `utils.ts`, `index.ts`, configs)
4. **Tests** — Create a full test suite with mock EIP-1193 provider (11 test cases)
5. **Registration** — Wire the adapter into the monorepo (adapters index, package.json, tsconfig references)
6. **Documentation** — Generate a README with API docs and usage examples
7. **Demo Integration** — Add the adapter to all 4 demo apps (CDN, dev, React UI, Vue UI)

## Target Project

| | |
|---|---|
| **Repository** | [tronprotocol/tronwallet-adapter](https://github.com/tronprotocol/tronwallet-adapter) |
| **Package location** | `packages/adapters/evm/<wallet-name>/` |
| **Tech stack** | TypeScript, Vitest, pnpm workspaces |
| **Build outputs** | ESM, CJS, TypeScript declarations, UMD |

## Prerequisites

- Node.js >= 16
- pnpm >= 7
- A cloned copy of the [tronwallet-adapter](https://github.com/tronprotocol/tronwallet-adapter) monorepo

## Usage

### With an AI Coding Agent

Copy this skill folder to your project:

```bash
# From the tronwallet-adapter repo root
cp -r /path/to/skills/tronwallet-adapter/evm-add-wallet-adapter .claude/skills/
```

Then simply ask the agent:

```
Add a Phantom EVM wallet adapter
```

The agent will automatically:
- Detect the skill and follow the 7-phase workflow
- Substitute all `{{PLACEHOLDER}}` variables with wallet-specific values
- Create all source files, tests, configs, and documentation
- Register the adapter in the monorepo
- Integrate it into all demo apps

### Manual Use

1. Open [SKILL.md](./SKILL.md) and follow the phases sequentially.
2. Use the **variable substitution table** to replace placeholders in all templates under `references/`.
3. Follow the **checklist** at the bottom to verify completeness.

## Variable Substitution

All templates use `{{PLACEHOLDER}}` syntax. Replace these with your wallet-specific values:

| Placeholder | Example (OKX Wallet) |
|-------------|---------------------|
| `{{WALLET_NAME}}` | `OKX Wallet` |
| `{{WALLET_CLASS}}` | `OkxWallet` |
| `{{WALLET_DIR}}` | `okxwallet` |
| `{{WALLET_URL}}` | `https://www.okx.com/web3` |
| `{{WALLET_RDNS}}` | `com.okex.wallet` |
| `{{WALLET_INJECTION}}` | `window.okxwallet` |
| `{{WALLET_IS_FIELD}}` | `isOkxWallet` |
| `{{WALLET_DEEPLINK}}` | `okx://wallet/dapp/url?dappUrl=` |
| `{{WALLET_ICON}}` | `data:image/png;base64,...` |
| `{{NPM_PACKAGE}}` | `@tronweb3/tronwallet-adapter-okxwallet-evm` |

## File Structure

```
evm-add-wallet-adapter/
├── SKILL.md                        # Main workflow (7 phases + checklist)
├── README.md                       # This file
└── references/
    ├── require-template.md         # Phase 1: Requirements document template
    ├── plan-template.md            # Phase 2: Development plan template
    ├── code-metadata.md            # Phase 3: metadata.ts — wallet identity (name, url, icon)
    ├── code-adapter.md             # Phase 3: adapter.ts — main adapter class
    ├── code-utils.md               # Phase 3: utils.ts — provider detection & deeplink
    ├── code-package-json.md        # Phase 3: package.json
    ├── code-tsconfig.md            # Phase 3: tsconfig files (ESM, CJS, all)
    ├── code-vitest.md              # Phase 3: vitest.config.ts
    ├── code-tests.md               # Phase 4: adapter.test.ts — 11 test cases
    ├── code-mock-provider.md       # Phase 4: mock EIP-1193 provider
    ├── docs-readme.md              # Phase 6: adapter README template
    └── demo-integration.md         # Phase 7: 4-demo integration guide
```

## Generated Package Structure

After running the skill, the output adapter package looks like:

```
packages/adapters/evm/<wallet-name>/
├── package.json
├── LICENSE
├── README.md
├── tsconfig.all.json
├── tsconfig.cjs.json
├── tsconfig.esm.json
├── vitest.config.ts
├── src/
│   ├── index.ts                    # Re-exports metadata + adapter
│   ├── metadata.ts                 # Wallet name, URL, icon (single source of truth)
│   ├── adapter.ts                  # Main adapter class (EIP-1193 / EIP-6963)
│   └── utils.ts                    # Provider detection, mobile WebView check, deeplink
└── tests/
    └── units/
        ├── adapter.test.ts         # 11 test cases
        └── <wallet>-provider.ts    # Mock EIP-1193 provider
```

## Key Design Decisions

- **Metadata extraction**: Wallet identity (`name`, `url`, `icon`) lives in a dedicated `metadata.ts` file, keeping the adapter class focused on behavior.
- **EIP-6963 first**: Desktop provider discovery uses the [EIP-6963](https://eips.ethereum.org/EIPS/eip-6963) multi-wallet protocol with a 3-second timeout fallback.
- **Mobile deeplink**: On mobile browsers (outside the wallet's WebView), the adapter redirects to the wallet app via its deeplink scheme.
- **Dual build**: Every adapter ships ESM + CJS + TypeScript declarations for maximum compatibility.

## License

[MIT](../../LICENSE)

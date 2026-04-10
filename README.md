# Web3 Skills

A curated collection of reusable AI-agent skills distilled from real-world Web3 development. Each skill encodes a proven, end-to-end workflow — complete with templates, checklists, and reference code — so common engineering tasks can be executed consistently and efficiently.

## What is a Skill?

A **skill** is a structured set of instructions and templates that an AI coding agent (e.g. GitHub Copilot, Claude) can follow to perform a multi-step engineering task autonomously. Think of it as a runbook that has been refined through actual development iterations.

Each skill folder contains:

| File | Purpose |
|------|---------|
| `SKILL.md` | Main workflow definition — phases, variable substitution table, checklist |
| `references/` | Code templates, doc templates, and integration guides |

## Available Skills

| Skill | Target Project | Description |
|-------|---------------|-------------|
| [evm-add-wallet-adapter](./tronwallet-adapter/evm-add-wallet-adapter/) | [tronwallet-adapter](https://github.com/tronweb3/tronwallet-adapter) | Add a new EVM-compatible wallet adapter end-to-end: requirements → plan → implementation → tests → registration → docs → demo integration |

## How to Use

### With VS Code + GitHub Copilot

1. Copy the desired skill folder into your project's `.claude/skills/` (or `.github/copilot/skills/`) directory.
2. The AI agent will automatically detect and invoke the skill when your request matches the skill's trigger patterns.
3. Alternatively, reference the skill explicitly in your prompt.

### With Other AI Agents

The skill files are plain Markdown with clearly defined phases, templates, and placeholder variables. Any AI coding assistant can follow them — just point it at the `SKILL.md` file.

### Manual Use

Each `SKILL.md` is also a perfectly good human-readable runbook. Follow the phases sequentially, substituting the placeholder variables (e.g. `{{WALLET_NAME}}`, `{{WALLET_URL}}`) with your actual values.

## Project Structure

```
skills/
├── README.md                          # This file
└── tronwallet-adapter/                # Skills for the tronwallet-adapter project
    └── evm-add-wallet-adapter/        # Add a new EVM wallet adapter
        ├── SKILL.md                   # Workflow definition
        └── references/                # Templates and guides
            ├── code-adapter.md
            ├── code-metadata.md
            ├── code-mock-provider.md
            ├── code-package-json.md
            ├── code-tests.md
            ├── code-tsconfig.md
            ├── code-utils.md
            ├── code-vitest.md
            ├── demo-integration.md
            ├── docs-readme.md
            ├── plan-template.md
            └── require-template.md
```

## Contributing

Contributions are welcome! To add a new skill:

1. Create a folder under the appropriate project directory (e.g. `tronwallet-adapter/<skill-name>/`).
2. Write a `SKILL.md` with clear phases, a variable substitution table, and a completion checklist.
3. Place all code/doc templates in a `references/` subfolder.
4. Add a `README.md` to the skill folder explaining usage and prerequisites.
5. Update this root README to list the new skill.

### Quality Guidelines

- All content must be in **English**.
- Do **not** include sensitive information (API keys, personal paths, credentials).
- Templates should use `{{PLACEHOLDER}}` syntax for project-specific values.
- Each skill should be self-contained and reproducible.

## License

[MIT](./LICENSE)

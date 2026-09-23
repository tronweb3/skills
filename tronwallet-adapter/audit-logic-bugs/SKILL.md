---
name: audit-logic-bugs
description: Audit a package or directory for semantic defects — lifecycle, async cleanup, state-machine and cancellation bugs — and report only findings reproduced by running code. Use when asked to scan, audit or review code for logic bugs; not when fixing an already-reported one.
---

# Auditing this repo for logic bugs

Style and typing issues are already covered by eslint and `tsc`. This audit is for defects
those cannot see: the ones that need the lifecycle of an object to be simulated in full.

## Scope one unit at a time

Never audit "the repo". Pick units small enough to hold entirely in context, and take one
per pass:

- `packages/adapters/<wallet>/src/` — one wallet adapter
- `packages/adapters/evm/<wallet>/src/` — include `utils.ts`; detection helpers and the
  adapter are usually coupled
- `packages/{react,vue}/*/src/` — a provider and its hooks

**Read every file in the unit end to end.** Do not grep for patterns and audit the hits.
The defects worth finding only appear once the whole flow is in view.

## Pass 1 — taxonomy

Mechanical, high recall. For each row, ask the question of *every* site in the unit. The
examples are calibration: they show what the shape looks like in this codebase, they are
not the things to look for.

| # | Failure shape | Ask at every site | Real instance |
|---|---|---|---|
| 1 | Async resource outlives its owner | For each `setTimeout`/`setInterval`/`addEventListener`/`.on()`: is it released on *every* exit path, including early returns and throws? | `abstract-adapter-evm`: a wallet answering `eip6963:requestProvider` synchronously resolved the promise before the timers were created, so `cleanup()` could never reach them |
| 2 | Flag without exception safety | For each `this._x = true`: what happens if the code before the reset throws? | `metamask-tron`: `switchChain` left `_switchingChain` stuck, silently no-oping every later call |
| 3 | Failure cached forever | For each cached field: can a *failed* result be stored and never invalidated? | `abstract-adapter-evm`: `getProviderPromise` kept a null detection for the adapter's whole life |
| 4 | State machine updated in part | In event handlers: are address, state and connected all brought in line, or only one? | `binance`: `_onAccountsChanged` set `_address` but never `_state`, so `connected` stayed true forever |
| 5 | Dropped promise | For each un-awaited async call: who handles a rejection? | `react-hooks`/`vue-hooks`: the previous adapter's `disconnect()` was discarded when switching wallets |
| 6 | Guard skips cleanup | For each early `return`: does it bypass teardown the later code would have done? | `metamask-tron`: `disconnect()` returned early whenever the state was not Connected — exactly the case during connect — so an in-flight connect could not be cancelled |
| 7 | Duplicated implementation drifts | When a method exists in more than one place: would fixing one miss the others? | `metamask-evm`/`okxwallet-evm` carry their own `getProvider()`; three separate fixes each had to be written three times |

## Pass 2 — open reading

The table cannot contain a class nobody has hit yet. After pass 1, drop it and answer:

- What invariant does this file assume? Who can break it?
- Which orderings does the author rely on without enforcing them?
- What is assumed to arrive that may never arrive? (an event, a callback, a resolve)
- If this object is created twice, or torn down mid-flight, what breaks?

Findings from pass 2 that survive verification get added to the table as a new row.

## Verification — a finding that was not run is not a finding

Reading produces plausible defects at a high rate, and most are wrong. Before writing
anything up:

1. Write a probe under the unit's `tests/units/`, named `tmp-*.test.ts`
2. Drive the trigger and **print the observed values** — state, events, counts. Print, do
   not only assert; the actual numbers are what tell you whether the theory holds
3. Run it. The theory holds only when the observation contradicts the expected behaviour
4. Delete the probe

If a candidate fails to reproduce, drop it. Do not downgrade it to "possible" and report
it anyway.

## Report

Per confirmed finding:

- **Location** — `path:line-line`
- **Observed** — what actually happens, with the probe's real output
- **Mechanism** — why, in terms of the code path
- **Impact** — what a dapp or a user sees
- **Suggestion** — the shape of the fix, not a patch

Before calling anything a regression, check `git log`/`git diff` against the base branch:
several findings here turned out to predate the release being audited.

## Repo facts that trip up audits

- Node must be `24.19.0` and pnpm `11.21.0` — both pinned in `.nvmrc` and `engines`. Run
  `nvm use` first; on older majors vitest fake timers fail spuriously
- `vue-ui` and `react-ui` have a placeholder `test` script — the real one is `test:unit`
- `vue-ui`'s `WalletActionButton.test.tsx` is excluded from its `test` script and fails on
  its own; that is pre-existing, not something an audit introduced
- `getTimerCount()` counts the whole environment. Other providers hold timers too, so track
  a specific timer by id rather than asserting a global count

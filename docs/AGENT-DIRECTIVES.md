# BLU Forever Agent Directives

This document records the framework-first build discipline for BLU Forever
(the WoW Forever, Classic beta build of BLU) enforced by `AGENTS.md` and the
shared RGX-Framework CI include (`/.gitlab/ci/addon.yml`). Follow it before
writing or changing any code, UI, timer, event, aura, or slash-command
surface. The release history and shipped versioning notes live in
`docs/CHANGES.md`; planned work lives in `docs/ROADMAP.md`.

## The MCP tool loop

Before writing addon code, run the RGX-Framework MCP tools in order. Each
step has a single, ordered purpose; do not reorder or skip:

1. `rgx_get_contract` — read the current declarative contract surface
   (the live `RGXAddon(name, opts)` keys the framework ships today).
2. `rgx_generate_addon` — scaffold the addon file from the contract so
   the generated Lua matches what the framework would produce for these
   opts.
3. `rgx_validate_addon` — validate the actual opts table against the
   contract; fail on unknown, removed, or tier-4 keys.
4. `rgx_audit_lua` — audit every changed Lua file for forbidden raw-WoW
   patterns (see below) and confirm generated Lua matches integration.

Compare the generated Lua with the existing integration, then validate the
actual opts table and audit every changed Lua file. Never hand-roll what
the framework ships.

## The declarative contract

Build addon behavior from the declarative `RGXAddon(name, opts)` table
using **only** keys the framework ships today. Read
`docs/DECLARATIVE-API.md` in `rgxmods/warcraft/RGX-Framework` before
writing code; tier 4 keys are future targets, not runtime features.

- `name` — the addon name.
- `opts` — the declarative options table. Only shipped keys are valid;
  the only-shipped-keys rule is enforced by `rgx_validate_addon`.

BLU Forever's own contract lives at the top of `core/core.lua`: the
declarative `dbName` field (`BLUForeverDB`) at `core/core.lua:35` matches
the TOC `## SavedVariables: BLUForeverDB` line, and the `version` fallback
at `core/core.lua:55` stays synchronized with the TOC `## Version:` line.
Use `onInit` and addon-scoped methods only where the shipped declarative
surface genuinely cannot express the behavior.

## Forbidden raw-WoW patterns

The following patterns fail `rgx_audit_lua` and must not appear in shipped
Lua. Replace them with their framework-managed equivalents; migrate
existing compatibility paths deliberately instead of silently breaking
them.

| Forbidden pattern | Framework equivalent |
|---|---|
| raw `C_Timer` (e.g. `C_Timer.After`, `C_Timer.NewTicker`) | RGX timers / repeating schedules |
| manual event frames (`CreateFrame("FRAME")`, manual `SetScript`) | `RGX:RegisterEvent` / `RGX:RegisterUnitEvent` |
| `SLASH_` globals | framework slash command registration |
| unguarded `SetAttribute` | framework UI controls / dropdowns |
| raw aura plumbing (`UnitAura`, custom aura watching) | `RGXAuras` module |
| raw hook reassignment (`hooksecurefunc`, `HookScript`) | framework lifecycle hooks |

## Dependency and version posture

- **RGX-Framework is a hard RequiredDep** (`## RequiredDeps: RGX-Framework`,
  `BLU_Forever.toc` line 9) with guarded runtime usage: the framework
  global is read at `core/core.lua:7` (`local RGX = _G.RGXFramework`) and
  call sites run only under `if RGX then` guards; a documented fallback
  constructor at `core/core.lua:32` keeps the addon delegable without
  silently hand-rolling framework services.
- **SavedVariables** `BLUForeverDB` (TOC line 11) equals the declarative
  `dbName` at `core/core.lua:35`. Do not rename either surface.
- **Version surfaces** are `BLU_Forever.toc` line 3 (`## Version:`) and the
  `version` fallback at `core/core.lua:55`. Per `AGENTS.md` line 49 they
  must stay synchronized on every version change.

## Supported Interface and version verification

BLU Forever is a single-flavor addon for WoW Forever (Classic beta):

- `## Interface: 16001` (`BLU_Forever.toc` line 1) is the only supported
  Interface value.
- Derivation formula: `major * 10000 + minor * 100 + patch`. Verified
  shipped example: `1.60.1` -> `16001`.
- Ground truth is the game client's own `.build.info` in the WoW
  installation root: one pipe-delimited row per installed product; the
  Product column names the flavor and the Version column gives
  `major.minor.patch.build`. Read it immediately before changing a TOC or
  releasing.
- Online cross-checks for builds not installed locally: the wago.tools
  build pages and versions.wowtools.io. Verify a feed is reachable at
  runtime before trusting it; if a feed is unreachable, the installed
  client's `.build.info` is authoritative and an uninstalled flavor's live
  version is never guessed.

Feed state at authoring time (2026-10-14, verified live): wago.tools
responded HTTP 200; versions.wowtools.io responded HTTP 525 (unreachable).
A stale `## Interface:` value is a bug: fix it in a task-branch MR with
green shared validation before any release. Re-check both feeds before
asserting any Interface number beyond the installed-client value.

## Release discipline

Release through the GitLab MR pipeline and green shared validation, then
patch-bump through the same discipline and create a protected GitLab
release tag matching the TOC version. The release flow is:

1. Validate — `addon:validate` (MR + default branch) must pass for every
   diff via the shared `.gitlab/ci/addon.yml` include.
2. Contract bundle — `contract:bundle` (guarded to `main` / tags / MR
   when `tools/ci/package.json` is present); not triggered in this repo,
   which ships no `tools/ci/package.json`.
3. Mirror — `mirror:github` (guarded to `main` and `v*` tags); publish
   the identical protected GitLab tag to the downstream
   `RGXMods/BLU_Forever` mirror before reporting distribution pickup.

## Related references

- Framework canonical docs: `rgxmods/warcraft/RGX-Framework`
  `docs/DECLARATIVE-API.md` and `docs/RGX-MCP.md`
- This addon's runtime facts and validation rules: `AGENTS.md`
- Release history: `docs/CHANGES.md`
- CI configuration: `.gitlab-ci.yml` (includes
  `rgxmods/warcraft/RGX-Framework /.gitlab/ci/addon.yml`)

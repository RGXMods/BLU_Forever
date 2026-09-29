# BLU_Forever

BLU | Better Level-Up! (Forever) is the WoW Forever (Classic beta, Interface
16001) build of BLU. It is a feature-gutted fork of the Retail BLU addon:
every system that cannot exist on the Forever client is removed rather than
disabled.

## Layout And Runtime

- `BLU_Forever.toc` is the single load manifest; `BLU_Forever.xml` defines
  runtime load order. SavedVariables: `BLUForeverDB`.
- Kept feature modules (`modules/`): Combat, Honor, LevelUp, Loot, Quest,
  Reputation, Debug. Removed: Achievement, BattlePet, Collectibles, Delve,
  Housing, Prey, Renown, TradingPost — including their tabs, defaults,
  registry categories, sound entries, and muter IDs.
- `core/interface/options/tabs.lua` defines the tab grid; `core/systems/`
  holds config defaults, the sound registry, and the module loader maps.
- `core/interface/minimap.lua` builds the RGX minimap button.

## Fork Rules

- Do not reintroduce retail-only modules, tabs, or sound categories; the
  Forever client cannot fire them.
- Port shared changes from Retail BLU selectively. Do not overwrite the
  `BLUForeverDB` SavedVariables name, the `16001` interface target, the
  or the gutted tab layout.
- Keep the RGX-Framework dependency and use its APIs (events, slash,
  minimap, database, design) instead of parallel plumbing.
- Keep `BLU_Forever.toc` and the addon version synchronized when changing
  versions.

## Testing And Release

There is no build step or automated test suite. Install with RGX-Framework on
the WoW Forever beta and verify: `/blu` opens options, all tabs render
(General, Combat, Honor, Level Up, Loot, Quest, Reputation, Profiles,
Sounds), the minimap button toggles via `/blu icon on|off`, level-up and
quest triggers fire, and profile switching persists. Stable releases use
`vX.Y.Z` tags in GitLab, mirrored to GitHub.

## Building With RGX-Framework

- Contract first: build addon behavior from the declarative `RGXAddon(name, opts)` table using only keys the framework ships today. Read `docs/DECLARATIVE-API.md` in `rgxmods/warcraft/RGX-Framework` before writing code; tier 4 keys are future targets, not runtime features. Use `onInit` and addon-scoped methods only where the shipped declarative surface genuinely cannot express the behavior.
- MCP tool loop: before writing UI, timer, event, aura, or slash code, run the rgx-framework MCP tools in order: `rgx_get_contract` -> `rgx_generate_addon` -> `rgx_validate_addon` -> `rgx_audit_lua`. Compare generated Lua with existing integration, validate the actual opts table, and audit every changed Lua file. Never hand-roll what the framework ships.
- Prefer framework subsystems over raw WoW API: timers and repeating schedules, event registration, slash commands, minimap button, saved-settings database, aura watching, UI controls and dropdowns, colors, fonts, theming, tooltips, and sound.
- Forbidden patterns that fail `rgx_audit_lua`: raw `C_Timer`, manual event frames, `SLASH_` globals, unguarded `SetAttribute`, raw aura plumbing, and raw hook reassignment. Replace them with framework-managed equivalents; migrate existing compatibility paths deliberately instead of silently breaking them.
- Validation: Lua 5.1 (`luac5.1 -p`) and XML (`xmllint`) must pass through the shared CI include before every MR, and the root README stays nonempty and substantive.
- Dependencies: keep `## RequiredDeps: RGX-Framework` and any `## X-RGX-Framework-MinVersion` accurate against the framework version line, and match the TOC SavedVariables name (`BLUForeverDB`) with the declarative `dbName`.
- Repo facts: this addon targets WoW Forever only (interface `16001`) and uses `/blu` for its options panel and `/blu icon on|off` for the minimap button. The TOC owns the `vX.Y.Z-beta.N` version, `BLU_Forever.xml` owns load order, and `core/core.lua` carries a version fallback that bumps with the TOC. Recheck those facts in the TOC and README when they change.

## Keeping Interface Versions Current

- Ground truth is the game client's own `.build.info` in the WoW installation root: one pipe-delimited row per installed product; the Product column names the flavor and the Version column gives `major.minor.patch.build`. Read it immediately before changing a TOC or releasing.
- Derive `## Interface:` as `major * 10000 + minor * 100 + patch` (verified: `1.60.1` -> `16001`, `1.15.9` -> `11509`, `2.5.6` -> `20506`, `5.5.4` -> `50504`). A multi-flavor addon carries a comma-separated list.
- Online cross-checks for builds not installed locally: the wago.tools build pages and versions.wowtools.io. Verify a feed is reachable at runtime before trusting it; if it is unreachable, the installed client's `.build.info` is authoritative and an uninstalled flavor's live version is never guessed.
- A stale `## Interface:` value is a bug: fix it in a task-branch MR with green shared validation before any release.
- Release through GitLab MR and green shared validation, then patch-bump through the same discipline and create a protected GitLab release tag matching the TOC version. Verify the identical tag on the downstream `RGXMods/BLU_Forever` mirror before reporting distribution pickup.

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

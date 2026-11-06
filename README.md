# BLU | Better Level-Up! (Forever)

Better Level-Up! (Forever) is the WoW Forever (Classic beta, Interface 16001) build of BLU: replacement sounds for the level-up moments that matter, powered by [RGX-Framework](https://github.com/RGXMods/RGX-Framework). Everything that cannot exist on the Forever client has been removed — this build ships only what the game can fire.

## Features

- **Level-Up sounds** — a sound of your choice when you ding, with queueing, volume, and channel control.
- **Quest sounds** — accept, complete, progress, and turn-in triggers.
- **Reputation sounds** — rank-up triggers for faction grinds.
- **Honor rank sounds** — PvP rank progression triggers on the classic honor system.
- **Combat triggers** — Bloodlust/Heroism and proc-style combat cues through the RGXCombat integration.
- **Collections tab** — collectible milestone triggers (mounts, pets, toys, transmog) are reserved for the Forever client's Collections system.
- **Minimap button** — left-click opens the options panel; drag to reposition; Ctrl+Right-click hides it (`/blu icon on` restores).
- **Full options panel** — General, Combat, Honor, Level Up, Loot, Quest, Reputation, Profiles, and Sounds tabs with profile support.
- **Custom sounds** — add your own .ogg files, or choose from the bundled BLU defaults and shared-media packs.

## Removed vs Retail BLU

WoW Forever is an Era-lineage client; these retail systems do not exist there and their modules, tabs, sounds, and defaults are gone: Achievements, Battle Pets, Collectibles, Delves, Housing, Prey, Renown, and the Trading Post.

## Installation

1. Install [RGX-Framework](https://github.com/RGXMods/RGX-Framework) (required dependency).
2. Copy the `BLU_Forever` folder to `World of Warcraft\_classic_beta_\Interface\AddOns\`.
3. `/reload` or restart the client, and enable both addons.

## Commands

| Command | Effect |
|---|---|
| `/blu` | Open the options panel |
| `/blu debug` | Toggle debug mode |
| `/blu status` | Show addon status |
| `/blu icon on/off` | Show or hide the minimap button |
| `/blu addcustom <file> \| <name>` | Register a custom sound file |
| `/blu removecustom <path>` | Remove a custom sound |
| `/blu refresh` | Rescan user custom sounds |

## Your own sounds

Put your sound files (`.ogg`, `.mp3`, `.wav`) in `Interface\AddOns\BLU_Forever\user\sounds\`, then add them from `/blu` > Sounds > Add Custom Sound by name (`myfile` or `myfile.ogg`) or with `/blu addcustom myfile`. Files named `custom01`, `sound01`, `usersound01` or `blu_custom01` (up to 99) in that folder, or in `user\`, are picked up automatically.

BLU looks for a name in this order: its own `user\sounds`, `user`, `sounds`, `media` and `media\sounds` folders, then `Interface\AddOns\` itself, then the sound folders of every other installed addon (sound packs and media addons first). A WoW addon cannot list folders, so it tests the conventional folder names (`sounds`, `sound`, `media`, `media\sounds`, `audio`, `assets`) in each addon; a sound in an unusual folder needs its full path: `/blu addcustom Interface\AddOns\SomePack\weird\place\file.ogg`. Sounds that other addons register with Shared Media are listed automatically at any depth.

Settings are stored in `BLUForeverDB` with full profile support (Profiles tab).

## Compatibility

- WoW Forever beta (Interface 16001). Retail BLU remains the Retail/`120100` build; Classic flavors are covered by BLU_Classic.

## Support

Part of the [RealmGX](https://realmgx.com) community project. Join us at discord.gg/N7kdKAHVVF.

## Development

Development on this addon is framework-first: run the RGX-Framework MCP tool loop and honor the declarative contract before writing code. See [docs/AGENT-DIRECTIVES.md](docs/AGENT-DIRECTIVES.md) for the workflow and [AGENTS.md](AGENTS.md) for the runtime facts and validation rules it enforces.

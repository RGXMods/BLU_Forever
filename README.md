# BLU | Better Level-Up! (Forever)

Better Level-Up! (Forever) is the WoW Forever (Classic beta, Interface 16001) build of BLU: replacement sounds for the level-up moments that matter, powered by [RGX-Framework](https://github.com/RGXMods/RGX-Framework). Everything that cannot exist on the Forever client has been removed — this build ships only what the game can fire.

## Features

- **Level-Up sounds** — a sound of your choice when you ding, with queueing, volume, and channel control.
- **Quest sounds** — accept, complete, progress, and turn-in triggers.
- **Legacy task sounds** — Task Complete and Task Progress subscribe to the
  framework's achievement/criteria owner. Their selections, `None`, module
  switches and sound-volume policies use the normal BLU sound registry.
- **Reputation sounds** — rank-up triggers for faction grinds.
- **Honor rank sounds** — PvP rank progression triggers on the classic honor system.
- **Combat triggers** — Bloodlust/Heroism and proc-style combat cues through the RGXCombat integration.
- **Collections tab** — collectible milestone triggers (mounts, pets, toys, transmog) are reserved for the Forever client's Collections system.
- **Minimap button** — left-click opens the options panel; drag to reposition; Ctrl+Right-click hides it (`/blu icon on` restores).
- **Full options panel** — General, Combat, Honor, Level Up, Legacy, Loot, Quest, Reputation, Profiles, and Sounds tabs with profile support.
- **Custom sounds** — add your own .ogg files, or choose from the bundled BLU defaults and shared-media packs.

## Removed vs Retail BLU

Forever's Legacy tasks use the achievement/criteria event interface; they are
not a claim that Retail achievement content exists in Forever. Unavailable
Retail systems remain excluded rather than reintroduced by this adapter.

## Installation

1. Install [RGX-Framework](https://github.com/RGXMods/RGX-Framework) (required dependency).
2. Copy the `BLU_Forever` folder to `World of Warcraft\_forever_\Interface\AddOns\`.
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

BLU looks for a name only in its own folders, in this order: `user\sounds`, `user`, `sounds`, `media` and `media\sounds` inside `Interface\AddOns\BLU_Forever\`, then `Interface\AddOns\` itself. A WoW addon cannot list folders, so it never searches other addons by name. A name that exactly matches a sound already registered in BLU (a sound pack or Shared Media entry) also works. For a file anywhere else, give the full path: `/blu addcustom Interface\AddOns\SomePack\weird\place\file.ogg`. New files only become playable after a full game restart, not a `/reload`; when BLU cannot find a name it tells you where to put the file.

Settings are stored in `BLUForeverDB` with full profile support (Profiles tab).

## Compatibility

- WoW Forever beta (Interface 16001). Retail BLU remains the Retail/`120100` build; Classic flavors are covered by BLU_Classic.

## Support

Part of the [RealmGX](https://realmgx.com) community project. Join us at discord.gg/N7kdKAHVVF.

## Development

Development on this addon is framework-first: run the RGX-Framework MCP tool loop and honor the declarative contract before writing code. See [docs/AGENT-DIRECTIVES.md](docs/AGENT-DIRECTIVES.md) for the workflow and [AGENTS.md](AGENTS.md) for the runtime facts and validation rules it enforces.

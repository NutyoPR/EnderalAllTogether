# Enderal AllTogether

*Enderal co-op, properly: fixes and sync for playing Enderal SE with Skyrim Together.*

Skyrim Together syncs players, NPCs and quest stages, but Enderal keeps a lot of its story in places Skyrim Together
doesn't look, and some of its scripts assume there is only one player. Enderal AllTogether fixes both.

## Requirements
- Enderal SE (tested on 2.1.4, Skyrim 1.7.104), SKSE64, Address Library
- **Skyrim Together built from absol89's API-Together fork**, which provides the plugin API this mod uses.
  Without it, the sync plugin stays inactive (the script fixes still work).
- Both players need the mod.

## What it does

**Script fixes** (125 scripts)
- Wolf Blood transforms only the drinker, not every player.
- Skill books teach only the reader; Phasmalist summons and class abilities (Ghostwalk, Eldritch Blood, Well of Life,
  Fire Arrows) act only on their user.
- Talent tomes and memory point books affect only whoever read them, and opening the class menu no longer pulls the
  other player into the meditation realm. Quest items (potions, the dreamflower) stay shared, like the quests.

**Scenes and travel**
- When a scene lets go of the player on one game (fade back, controls back, a vision ending), the partner's game does
  too: no more being left blind or frozen. Covers every vision (Penta's house and the main quest) and the MQ03 bench.
- Scenes that place NPCs do it on one game only (Meldor in The Voice from the Water), so they don't freeze in place.
- Myrad travel takes the party along: the partner fades out and arrives with you.
- Unstuck key (End, set in `SKSE/Plugins/EnderalAllTogether.ini`): if any scene still leaves you stuck, press it.
  It also clears a leftover vision slowdown, invisibility or ghost mode, and only works in gameplay (not in menus or chat).
- Books and notes wait until you close them, as in vanilla: no ambushes, scenes or dialogue starting while you read
  (Yero's journal, the Butcher of Ark note and 30 more). Voiced letters still narrate while you read.
- House furniture is shared: whoever buys it, it appears in everyone's house.
- Puzzles and lifts work for both players: the temple pillars rise for the whole party, and dungeon lifts end up in
  the same position for everyone, whoever pulls the lever, also for a partner who arrives later (only the rider's
  controls are locked).

**Sync plugin** (140 of Enderal's global variables)
- Relationships: Jespar's, Calia's and everyone else's sympathy, flirts and romance follow every player's choices,
  so the endings and romance checks see the same values on every machine.
- Quest counters: artifacts, black stones, clues, pages and more count for the whole party, so collection quests
  don't get stuck when the items are split between players.
- Story choices and world state: sides taken, people spared, wishing wells, the shared house, horses and mule.

Not synced on purpose: personal progress (levels, talent points, learning points), achievements, abilities,
runtime switches and puzzles in progress. The full sorted list with reasons is in the source (`src/SyncList.h`).

## How the sync works
- Relationships and counters share the *difference* ("Jespar +5"), so both players' choices count and nothing is
  counted twice; boss-kill counters keep the higher value, since a boss death can count on both machines.
- Story flags share the new value.
- The reference is the Skyrim Together party leader (on builds that report it, otherwise the lowest player ID). It
  brings joining players up to date and sends a check-up every 30 seconds, so a lost message can't leave the games
  different for long. A game that loads a save in a party asks the others for their state instead of sending its own,
  so loading an older save never rolls the party back.
- Messages go through Skyrim Together's plugin API to party members only (at most 10 per second).

## Source layout
| Path | What it does |
|---|---|
| `src/Net` | messages to and from the party through Skyrim Together |
| `src/SyncList.h` | which globals are shared, and how |
| `src/GlobalSync` | relationships, counters and story choices |
| `src/SharedValues` | small shared values for patched scripts (house furniture), kept in the save |
| `src/Party` | scenes and travel: designated player, shared releases and Myrad trips, unstuck key |
| `src/SkyrimTogether.h` | our declaration of the Skyrim Together plugin API |
| `mod/` | the script fixes (compiled `.pex` and patched sources) |

Pushes build on GitHub Actions; the artifact is the complete mod (plugin and scripts). Pushing a `v*` tag publishes a release.

## Authors
- **Nutman** ([NutyoPR](https://github.com/NutyoPR)): idea, design, testing and direction
- **Claude** (Anthropic): code

## License
MIT for the plugin and the script additions, see [LICENSE](LICENSE). Enderal's scripts belong to SureAI.

## Credits
- [CommonLibSSE-NG](https://github.com/alandtse/CommonLibSSE-NG)
- [Skyrim Together](https://github.com/tiltedphoques/TiltedEvolution) and absol89's API-Together fork, for the plugin API
- SureAI, for Enderal

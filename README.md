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

**Script fixes** (144 scripts)
- Wolf Blood transforms only the drinker, not every player.
- Skill books teach only the reader; Phasmalist summons and class abilities (Ghostwalk, Eldritch Blood, Well of Life,
  Fire Arrows) act only on their user.
- Talent tomes and memory point books affect only whoever read them, and opening the class menu no longer pulls the
  other player into the meditation realm. Quest items (potions, the dreamflower) stay shared, like the quests.

- Abilities and items act only on their user: Flashpowder, Ghostwalk, the Drifter and Druid affinities and Mesmerize
  no longer affect the other player; MQ11's butterflies, Ryneus' teddy and the skull sphere only for whoever used them.

**Main menu**
- Enderal's own main menu background instead of Skyrim Together's logo. For this, Enderal AllTogether has to load
  after Skyrim Together in your mod manager (it replaces `meshes/interface/logo/logo.nif`).

**Healing other players** (`EnderalAllTogether.esp`, a light plugin that uses no load order slot)
- Second Breath (all ranks) and the Staff of Healing are channeled golden beams, like Lightning (Calia's healing
  light, with Flame Bite's reach), instead of a charged invisible hit. You see the beam connect with the player you're
  healing, it plays on every player's game so the heal reliably lands, and it sounds like Restoration's own channeled
  healing (no more punch sound on every hit).
- Same heal per second as vanilla: one second of beam heals, costs and adds arcane fever like one old cast (which took
  about a second: half a second of charge plus the release). Rank I: 25 Health for 24 magicka per second. Light Magic
  perks apply as before. The NPC versions and Elixir are unchanged.
- Arcane fever builds up every second while the beam heals, and you get one message with the total when you let go,
  like Enderal's own Boon.
- Enable `EnderalAllTogether.esp` in your plugin list, after `Enderal - Forgotten Stories.esm`. Every player needs it.
- The plugin is generated from Enderal's own records by `tools/make_esp.py`; the names it changes are in English.

**Slowing time** (also `EnderalAllTogether.esp`)
- Slowing time on one game only throws co-op out of sync, so abilities don't do it any more: the target selection of
  Eldritch Blood, Ghostwalk and Skyfall (you pick in real time) and the Theriantrophist transformation keep everything
  else they do. Story slowdowns (visions, memories, quest scenes) stay.
- Fast Reflexes and Steadfast (Keeper) slowed time; instead they now give 2 seconds of half damage and no stagger, at
  the same moments (blocking a power attack; hit below 15 percent Health).
- Eye of the Storm still slows time, on every player's game at once: when one player uses it, everyone's game slows
  down and speeds up again together.

**Skyrim Together's quest patches**
- Ships an empty `SkyrimTogetherQuestPatches.esp` that replaces Skyrim Together's. The original patches Skyrim's
  Companions scene (C02InductionScene), which doesn't exist in Enderal. Keep the plugin enabled
  (Skyrim Together expects it) and Enderal AllTogether after Skyrim Together, so the empty one wins.

**Scenes and travel**
- When a scene lets go of the player on one game (fade back, controls back, a vision ending), the partner's game does
  too: no more being left blind or frozen. Covers every vision (Penta's house and the main quest) and the MQ03 bench.
- Scenes that place NPCs do it on one game only (Meldor in The Voice from the Water), so they don't freeze in place.
- Story teleports take the party along (the campfire with Esme, the scene with the father in NQR03).
- Myrad travel takes the party along: the partner fades out and arrives with you. The flight itself plays on the
  party leader's game, which runs the Myrad; other players fade straight to the destination. When the leader lands,
  the others' games end the flight animation on their copy of the leader too (it used to keep flying off).
- The signposts in Ark take the party along, like Myrad travel.
- Unstuck key (End, set in `SKSE/Plugins/EnderalAllTogether.ini`): if any scene still leaves you stuck, press it. It also
  ends music a broken sequence left playing (combat music that never stops), which otherwise survives reloading.
  Pressed in a fight with guards over a bounty, it surrenders for you: the bounty is paid if you can afford it and
  the guards stand down, for when they won't talk to you (stolen items stay with you).
  It also clears a leftover vision slowdown, invisibility or ghost mode, puts other players stuck in an animation on
  your game back to normal, and only works in gameplay (not in menus or chat).
- Books and notes wait until you close them, as in vanilla: no ambushes, scenes or dialogue starting while you read
  (Yero's journal, the Butcher of Ark note and 30 more). Voiced letters still narrate while you read.
- House furniture is shared: whoever buys it, it appears in everyone's house.
- Taming the Waves: a burning stone fragment one player saves is saved for everyone, so the counters agree and no
  game destroys a stone someone else saved; its combat music ends for everyone.
- NQ22's diary pages count once: a page someone else picks up only disappears for you (it used to count twice
  and hand you a copy).
- Bounty boards: a bounty one player takes shows up in everyone's journal, with the same objectives, and every
  board agrees on which bounty the party is on.
- Smoking a pipe no longer runs the smoking script on the other player's copy as well (it animates from their own game).
- Eldritch Blood works on every enemy: Skyrim Together runs each NPC's AI on one player's game, and the victim now turns
  on that game too (its explosion still happens once). Eldritch Blood and Ghostwalk never mark your partner.
- Icecaps raise only the eater's carry weight, and only they see the message. Mining next to a partner no longer
  spams errors.
- Everyone rides their own mount: in co-op the horse flute brings your personal Whirlwind, horse or Father's Shadow,
  and the others see it too. Before, each mount existed once and the flute pulled it away from whoever had it.
- Talking paintings and statues are heard by everyone: their lines (Rys in A Touching Effigy) play with voice and
  subtitle on every player's game, not only for the player talking to them.
- The bank account is personal and safe: Skyrim Together could replace the vault box's gold with another player's
  copy (a whole deposit vanished). Your balance is kept in your own save and restored before the bank uses it.
- Puzzles and lifts work for both players: the temple pillars rise for the whole party, and dungeon lifts end up in
  the same position for everyone, whoever pulls the lever, also for a partner who arrives later (only the rider's
  controls are locked).

**Sync plugin** (140 of Enderal's global variables)
- Relationships: Jespar's, Calia's and everyone else's sympathy, flirts and romance follow every player's choices
  (everyone sees the "approves / dislikes" message),
  so the endings and romance checks see the same values on every machine.
- Quest objectives: every objective shown, completed or failed in one player's journal appears in everyone's, whatever
  script set it (Skyrim Together only shares quest stages). Personal system quests like arcane fever stay personal.
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
  different for long. A game that loads a save in a party, or becomes the leader, asks the others for their state
  before sending its own.
- Newest change wins: every value carries when it last changed (kept in the save), and a check-up never undoes a newer
  change, whoever leads. A game with an older value gets the newer one back. So a reconnect that moves leadership to
  a player with an older save can't roll the party back. Every overwrite is logged with the old and new value.
- Messages go through Skyrim Together's plugin API to party members only (at most 10 per second).

## Source layout
| Path | What it does |
|---|---|
| `src/Net` | messages to and from the party through Skyrim Together |
| `src/SyncList.h` | which globals are shared, and how |
| `src/GlobalSync` | relationships, counters and story choices |
| `src/SharedValues` | small shared values for patched scripts (house furniture), kept in the save |
| `src/ObjectiveSync` | quest objectives for the whole party |
| `src/Party` | scenes and travel: designated player, shared releases and Myrad trips, unstuck key, shared Eye of the Storm |
| `src/Voice` | lines of talking activators (paintings, statues) for the whole party |
| `src/SkyrimTogether.h` | our declaration of the Skyrim Together plugin API |
| `mod/` | the script fixes (compiled `.pex` and patched sources) and the plugins |
| `tools/make_esp.py` | builds `mod/EnderalAllTogether.esp` (healing beams) from Enderal's plugins |

Pushes build on GitHub Actions; the artifact is the complete mod (plugin and scripts). Pushing a `v*` tag publishes a release.

## License
MIT for the plugin and the script additions, see [LICENSE](LICENSE). Enderal's scripts belong to SureAI.

## Credits
- [CommonLibSSE-NG](https://github.com/alandtse/CommonLibSSE-NG)
- [Skyrim Together](https://github.com/tiltedphoques/TiltedEvolution) and absol89's API-Together fork, for the plugin API
- SureAI, for Enderal

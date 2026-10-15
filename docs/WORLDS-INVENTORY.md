# OSS world platforms — inventory (verified October 2026)

What exists in open-source "walkable world / social game space" land, verified live
(last commits/releases checked via GitHub API + web). Doctrine: OSS repos only, no
custom-built replacements, no copyrighted-asset projects.

**Already running:** WorkAdventure (world shell), OpenFront (RTS), Luanti+Mineclonia
(sandbox), Mumble (voice), OpenFront portal + Suroi (in progress).

## Category 1 — 2D social worlds (Habbo / Gather-like)

| Project | License | Status | Weight | Verdict |
|---|---|---|---|---|
| [WorkAdventure](https://github.com/workadventure/workadventure) | AGPL+CC | **Active** (12k+ commits) | ~2 GB stack | **deployed — category leader** |
| [PopSpace](https://github.com/with-labs/popspace) | GPL-2.0 | Active (recency unverified) | ~4 containers, light | alternative canvas-style world; candidate #2 |
| [Tilemap Town](https://github.com/NovaSquirrel/TilemapTown) | GPL-3.0 | **Active today** | tiny (python, no docker) | hobbyist pixel world w/ collaborative map editing |
| OpenHotel (Habbo-like) | MIT | **dead** (2023) | multi-component | code reference only; asset provenance unaudited |
| Habbo retro emulators | — | — | — | **excluded**: require copyrighted Habbo assets |

## Category 2 — VR / metaverse

| Project | License | Status | Client | Verdict |
|---|---|---|---|---|
| [Overte](https://github.com/overte-org/overte) | Apache-lineage | **Active** (rel. 2026.10) | desktop + native VR | the live "true VR" option; C++ server, 2–4 GB |
| [Hubs CE](https://github.com/Hubs-Foundation/hubs) | MPL-2.0 | Active (foundation) | browser + WebXR | most polished; heavier stack (coturn/S3) — future pick if we want VR rooms |
| [JanusWeb](https://github.com/jbaicoianu/janusweb) | MIT | semi-active | browser/WebXR | very light; hobbyist docs |
| [OpenSimulator](http://www.opensimulator.org) | BSD | active 19yr | flat viewer | heavyweight Second-Life-style; niche |
| Immers Space | AGPL | semi-dormant | WebXR layer | not a turnkey world |
| Third Room / Exokit / Webaverse / Vircadia | — | **dead** (2022–2023) | — | prior art only |

## Category 3 — voxel & MMO worlds (FOSS server + FOSS client)

| Project | License | Status | Weight | Verdict |
|---|---|---|---|---|
| [VoxeLibre](https://codeberg.org/voxelibre/voxelibre) (Luanti game) | GPL/MIT | **Active** (0.92, sep 2026) | ~200–500 MB, **same Luanti server we already run** | free extra game: swap/add game on existing container |
| [Exile](https://codeberg.org/Mantar/Exile) / Asuna / Repixture (Luanti games) | Luanti mods | active | same | more free games on the same server |
| [Veloren](https://gitlab.com/veloren/veloren) | GPL-3.0 | **Active** (0.18+, 2026) | 0.5–2 GB, official docker | best FOSS 3D action-RPG; strong candidate |
| [Stendhal](https://codeberg.org/arianne/stendhal) | GPL-2.0+ | **Active** (1.49, 2026) | ~1 GB JVM + db, **browser client** | classic browser-accessible MMO; light |
| The Mana World / Evol2 | GPL | maintenance mode | light | nostalgia only |
| [Ryzom Core](https://github.com/ryzom/ryzomcore) | AGPL | active | **8–16 GB, expert** | too heavy for our fleet |
| TES3MP | GPL | stalled 2022 | light | requires owned Morrowind assets — not clean FOSS |
| PaperMC/Purpur (Minecraft servers) | OSS | active | 1–4 GB | **proprietary client** — separate tier, only if team owns MC |

## Category 4 — frameworks (build-your-own rooms/games)

| Project | License | Status | Use |
|---|---|---|---|
| [Colyseus](https://github.com/colyseus/colyseus) | MIT | **Active** (2026-10) | THE standard for custom multiplayer rooms (io-games, card games) — pairs with Phaser |
| [Nakama](https://github.com/heroiclabs/nakama) | Apache-2.0 | **Active** | shared accounts/leaderboards/lobby backend across games — later, when >2 games |
| [Kaetram](https://github.com/Kaetram/Kaetram-Open) (BrowserQuest successor) | MPL-2.0 | active rolling | browser explorable MMO world — WorkAdventure-adjacent candidate |
| Hyperfy | GPL-3.0 | semi-active | self-hostable 3D WebXR worlds, lighter than Hubs |
| PartyKit / Geckos.io | MIT/BSD | active/stale | niche realtime plumbing |
| agar.io-clone | MIT | low maintenance | fork-and-mod io-game reference |
| "OSS Roblox" | — | **does not exist** | verified negative — Hyperfy/Kaetram are the closest real things |

## Roadmap recommendation (no custom builds, all repos)

1. **Now (free wins):** extra Luanti games on the existing server (VoxeLibre etc.) — one container swap.
2. **Next:** **Stendhal** (browser MMO, light) and/or **Veloren** (desktop RPG) as third/fourth self-hosted games.
3. **VR when wanted:** **Hubs CE** (browser+WebXR, fits non-VR users best) on its own box — atlas-02 is at capacity.
4. **Custom rooms later:** standardize on **Colyseus** (+ Nakama once >2 custom games).
5. Verified dead ends to never research again: Third Room, Exokit, Webaverse, Vircadia, OpenHotel, BrowserQuest (use Kaetram).

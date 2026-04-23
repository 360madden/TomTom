# TomTom for Rift

This repository is a mirror of a local copy of the Rift **TomTom** addon.
TomTom marks waypoint lists, builds simple in-zone routes, and shows a small arrow/distance UI in game.

## Mirror status

| Field | Value |
|---|---|
| Addon identifier | `TomTom` |
| Addon version | `0.22` |
| Original addon author | `Wym` |
| Mirror owner | `360madden` |
| Local mirror source | `C:\RIFT MODDING\TomTom` |
| Rift manifest | `RiftAddon.toc` |

This mirror preserves the addon files for local testing, backup, and RiftReader waypoint-import experiments.
It is not an ownership claim over the original addon.

## Install

Copy or clone this repository into your Rift addons folder so that the manifest is directly under the `TomTom` folder:

```text
C:\Users\<you>\Documents\RIFT\Interface\AddOns\TomTom\RiftAddon.toc
```

On this machine, the active OneDrive addon path has also been observed as:

```text
C:\Users\mrkoo\OneDrive\Documents\RIFT\Interface\AddOns\TomTom\RiftAddon.toc
```

Restart Rift or reload the UI after copying the files, then enable **TomTom** in the addon list if needed.

## Basic use

| Command | Purpose |
|---|---|
| `/tomtom` | Print usage/help. |
| `/tomtom version` | Print the addon version. |
| `/tomtom show` | Show the TomTom UI. |
| `/tomtom hide` | Hide the TomTom UI. |
| `/tomtom autohide on` | Hide the UI automatically when no route is active. |
| `/tomtom goto <x> <z>` | Create a temporary direct waypoint. |
| `/tomtom mark <name>` | Save your current location into a waypoint list. |
| `/tomtom mark <name> <x> <z> [comment]` | Save an explicit waypoint. |
| `/tomtom forget <name> [index]` | Remove remembered waypoint data. |
| `/tomtom route <name> [...]` | Build a route through one or more saved waypoint lists. |
| `/tomtom next` | Skip to the next waypoint. |
| `/tomtom prev` | Go back one waypoint. |
| `/tomtom relative` / `/tomtom absolute` | Switch arrow direction mode. |
| `/tomtom portals [all]` | Route to bundled portal locations in the current zone, or all zones. |
| `/tomtom achieves [all]` | Route to bundled achievement locations in the current zone, or all zones. |
| `/tomtom raredar [all]` | Route to RareDar rare mob locations if RareDar is installed. |
| `/tomtom rarenerd` | Route to RareNerd rare mob locations if RareNerd is installed. |
| `/tomtom print` | Print the current route. |

## Coordinate model

TomTom uses Rift's map-plane coordinates:

| Rift field | TomTom use |
|---|---|
| `coordX` | Used as TomTom `x`. |
| `coordY` | Not used by TomTom; this is height/vertical position. |
| `coordZ` | Used as TomTom `z`. |

Example: if another tool shows `X=7424`, `Y=818`, `Z=3206`, the TomTom command is:

```text
/tomtom goto 7424 3206
```

## Notes and limitations

- TomTom only routes waypoints in the current zone.
- It does not move the character.
- It does not detect obstacles, hills, cliffs, mobs, or blocked paths.
- It stores remembered pickup and marked waypoint data in Rift saved variables.
- It uses a lightweight route-ordering algorithm, not a navmesh/pathfinding system.

## RiftReader integration

RiftReader can use TomTom saved variables as waypoint seed data. TomTom waypoints provide `zone`, `x`, and `z`; imported RiftReader waypoints use a configurable/default `y` value because TomTom does not store height.

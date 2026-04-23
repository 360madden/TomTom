# Mirror notes

| Field | Value |
|---|---|
| Mirror repository | `https://github.com/360madden/TomTom` |
| Local source copied from | `C:\RIFT MODDING\TomTom` |
| Local mirror checkout | `C:\RIFT MODDING\TomTom-github` |
| Addon version mirrored | `0.22` |
| First mirror commit with addon files | `bc356df1f4c8074b1e90feb8ad88261f51c0f20c` |
| Mirror baseline tag | `v0.22-mirror` |
| Notes date | `2026-04-23` |

## Scope

The mirror is intended to preserve the local addon files as-is and provide a stable source for RiftReader waypoint import/export experiments.

## Sync procedure

1. Copy changed addon files from `C:\RIFT MODDING\TomTom` into this checkout.
2. Review `git diff` for expected addon-only changes.
3. Commit with a mirror-focused message.
4. Push `main` and update/add tags only when the mirrored addon version changes.

## RiftReader waypoint import assumptions

TomTom saved waypoint entries are expected to be stored under `TomTomGlobal.PickupLocations` as lists of entries shaped like:

```lua
{ zoneId, x, z, count, comment }
```

TomTom does not store height/vertical `coordY`, so RiftReader imports must use a default or later-recaptured `Y` value.

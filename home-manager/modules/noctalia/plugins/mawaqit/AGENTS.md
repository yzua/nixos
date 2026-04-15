# Mawaqit Plugin

Prayer time bar widget and panel for the Noctalia shell. Fetches data from the Aladhan API, shows a live countdown in the bar, and provides a full panel with prayer timetable, Hijri calendar with Islamic events, and daily hadith.

**Option**: `programs.noctalia.plugins.mawaqit` (enabled via parent module)

---

## Structure

| File            | Purpose                                                                                          |
| --------------- | ------------------------------------------------------------------------------------------------ |
| `manifest.json` | Plugin metadata, entry points, default settings                                                  |
| `Main.qml`      | Core singleton: API fetch, countdown/elapsed timers, azan playback, notification dispatch, cache |
| `BarWidget.qml` | Bar capsule: next prayer countdown, dynamic icon, stop-azan button                               |
| `Panel.qml`     | Popup panel: prayer times list, Hijri calendar, Islamic events, hadith, Ramadan banner           |
| `Settings.qml`  | Settings: location, calculation method, school, offsets, azan selection with preview             |
| `DecoType.ttf`  | Arabic decorative font for Panel                                                                 |
| `assets/`       | Azan audio files (3 variants)                                                                    |
| `i18n/`         | Translations: en (canonical), fr, tr                                                             |

---

## Conventions

- `Main.qml` is the singleton — BarWidget and Panel read state via `pluginApi.mainInstance`.
- Settings use `cfg ?? defaults ?? fallback` triple-fallback.
- Cache keys prefixed `_cache` and `_cal_` are reserved.
- Audio uses `Process` with `paplay`/`pw-cat` (not QtMultimedia) to avoid PipeWire conflicts.
- Retry with exponential backoff on network failure (5/10/15/30/60s).
- `FileView` watches `~/.cache/noctalia/location.json` for auto-detected location.

---

## Gotchas

- `en.json` is the canonical key set — `fr.json` and `tr.json` must match its structure.
- Azan files must live at `assets/` relative to `pluginDir`; `Settings.qml` references by filename only.
- `DecoType.ttf` path is constructed dynamically from `pluginApi.pluginDir` — the file must exist at the plugin root.
- `processEntry()` strips parenthetical annotations from API timing strings — fragile if API format changes.
- Hijri month days uses alternating 30/29 pattern; Ramadan detection is simply `hijriMonth === 9`.

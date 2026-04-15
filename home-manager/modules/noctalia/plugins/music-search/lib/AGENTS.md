# Music Search — Backend Library

Shell library providing all data persistence, process management, IPC, search, library/playlist/queue CRUD, and download/cache management for the music-search plugin.

---

## Files

| File             | Purpose                                                                                         |
| ---------------- | ----------------------------------------------------------------------------------------------- |
| `config.sh`      | Constants (paths, locks), `die`, `require_cmd`, `with_lock`, `json_write_raw`, `safe_read_json` |
| `state.sh`       | State file read/write with lock wrappers                                                        |
| `process.sh`     | Process management: PID tracking, terminate, cleanup, hash                                      |
| `mpv-ipc.sh`     | mpv socket IPC: send commands, query pause/speed                                                |
| `launch.sh`      | mpv launch: direct stream or cached-download-then-play fallback                                 |
| `media-utils.sh` | URL parsing, provider inference, local file discovery via ffprobe                               |
| `library.sh`     | Library CRUD: play, search, save, edit metadata, download MP3                                   |
| `playback.sh`    | Playback control: pause, resume, seek, speed                                                    |
| `settings.sh`    | Settings + search dispatch (YouTube, SoundCloud, local)                                         |
| `playlists.sh`   | Playlist CRUD: create, delete, import folder, sync folder                                       |
| `queue.sh`       | Queue storage: enqueue (dedup), remove, clear, shuffle load                                     |

---

## Conventions

- **Source-once guard**: Every file starts with `[[ -n "${_XXX_SOURCED:-}" ]] && return 0`.
- **Lock discipline**: `with_lock "$LOCK_FILE" _unlocked_fn "$@"`. Internal functions prefixed `_` assume the caller holds the lock.
- **JSON-only output**: All data output is JSON via `jq`. Never output raw text for data.
- **Deterministic IDs**: `saved-$(hash_value "$url")`, `local-$(sha256sum | cut -c1-16)`, `queue-$(hash_value "$url")`.
- **Graceful degradation**: `mpv_ipc_send` falls back from `socat` to `python3`. Local search falls back from `rg` to `find`.
- **All persistent data** lives in `~/.cache/noctalia/plugins/music-search/` (overridable via `MUSIC_CACHE_DIR`).

---

## Gotchas

- Never call `_unlocked` functions directly — they assume the caller holds the lock.
- JSON writes must go through `json_write_raw` — it validates, refuses empty writes, and maintains `.bak` backups.
- `safe_read_json` can `die` on corrupt user data files. Only `state.json` is auto-recovered.
- `config.sh` must be sourced first. `state.sh` and `process.sh` before any function that reads state or manages processes.
- `DATA_LOCK` covers both library and playlists — long operations (folder import) hold it for the entire duration.

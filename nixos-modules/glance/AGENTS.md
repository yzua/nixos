# Glance Dashboard

Self-hosted dashboard at `localhost:8082` with Gruvbox theme. Aggregates feeds, service health, Docker containers, and system stats.

**Option**: `mySystem.glance.enable` (default: `true` in host-defaults.nix)

---

## Structure

| File                    | Purpose                                                  |
| ----------------------- | -------------------------------------------------------- |
| `default.nix`           | Main module with `services.glance.settings`              |
| `_bookmarks.nix`        | Bookmark groups (AI, Dev, Social, Accounts)              |
| `_search-bangs.nix`     | DuckDuckGo bang shortcuts (!gh, !nix, !yt, !crate, !npm) |
| `_service-sites.nix`    | Health check endpoints (Netdata, Grafana, etc.)          |
| `_youtube-channels.nix` | YouTube subscriptions feed                               |
| `_github-releases.nix`  | GitHub release tracker (rust, niri, neovim, glance)      |
| `_markets.nix`          | Market indices widget data                               |
| `_color-helpers.nix`    | Shared color utility functions                           |
| `_server-stats.nix`     | Server stats widget (disk mountpoints)                   |

Helper files (prefixed `_`) are imported via `import ./_file.nix` — not listed in any `default.nix`.

---

## Pages (3)

| Page        | Content                                                                                  |
| ----------- | ---------------------------------------------------------------------------------------- |
| **Home**    | Markets widget + 3-column layout (search/services, HN/YouTube, stats/bookmarks/releases) |
| **Search**  | Full-width search + bookmarks                                                            |
| **YouTube** | Full-width YouTube subscriptions                                                         |

---

## Widgets

### Left Sidebar

- **Search**: DuckDuckGo with bang shortcuts
- **Monitor**: Service health checks (1m cache)
- **Docker Containers**: Running container list

### Center

- **Hacker News**: Top 10, sorted by engagement
- **Videos**: YouTube subscriptions (grid-cards style)

### Right Sidebar

- **Server Stats**: Local disk mountpoints (`/`, `/home`)
- **Bookmarks**: Grouped links
- **Releases**: GitHub release tracker (rust, niri, neovim, glance)

---

## Theming

Gruvbox dark theme applied via `theme` block. `branding.app-background-color` pulls from `constants.color.bg`.

---

## Adding a Widget

1. Edit `default.nix` → add widget to appropriate column
2. For external data (bookmarks, channels): create `_file.nix` helper, import at top
3. Run: `just nixos`

## Adding a Health Check

1. Edit `_service-sites.nix`
2. Add `{ title = "Name"; url = "http://host:port"; }`
3. Run: `just nixos`

## Adding a YouTube Channel

1. Edit `_youtube-channels.nix`
2. Add `{ id = "CHANNEL_ID"; name = "Display Name"; }`
3. Run: `just nixos`

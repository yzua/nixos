# Theme Overrides

Custom visual theme files for desktop applications. All follow a Gruvbox-inspired dark palette. Static files referenced directly via Nix `.source` symlinks — no build step.

---

## Files

| File                        | Application      | Applied via     | Description                                                                                                                |
| --------------------------- | ---------------- | --------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `librewolf-userChrome.css`  | LibreWolf        | Nix symlink     | Browser chrome: zero border-radius, no box-shadows, 280px sidebar, hidden tab strip (delegated to Sidebery)                |
| `librewolf-userContent.css` | LibreWolf        | Nix symlink     | Content overrides: zero border-radius/shadows via `@-moz-document regexp`. Dark palette via `--dt-*` CSS custom properties |
| `gruvboxalt-ytmusic.css`    | YouTube Music    | Manual (Stylus) | Gruvbox dark theme (~2200 lines). Uses `--gruvalt-*` custom properties, overrides yt-spec variables                        |
| `gruvboxalt.tdesktop-theme` | Telegram Desktop | Manual          | Gruvbox color scheme (Telegram's custom theme format)                                                                      |

---

## Nix Integration

Only the two LibreWolf CSS files are managed by Nix. They are symlinked via `home-manager/modules/apps/librewolf/default.nix` into each profile's `chrome/` directory using `mkChromeFiles`.

The YouTube Music and Telegram themes are applied outside of Nix (via Stylus extension and Telegram's theme settings respectively).

---

## Conventions

- `!important` overrides throughout — required to override application defaults.
- CSS custom properties for theming: `--dt-*` (LibreWolf content), `--gruvalt-*` (YouTube Music).
- Gruvbox dark palette: backgrounds `#282828`-`#3c3836`, foreground `#ebdbb2`, blue accent `#83a598`, red accent `#fb4934`.
- The `gruvboxalt` naming (not `gruvbox`) indicates custom/modified variants, not upstream themes.
- System theming (GTK, terminals, etc.) is handled separately by Stylix via `base16-schemes` — these files are independent custom overrides.

---

## Gotchas

- `gruvboxalt-ytmusic.css` is large (~2200 lines) and uses specific yt-spec CSS variable names that can change with YouTube Music updates.
- `gruvboxalt.tdesktop-theme` is NOT referenced from Nix — it is applied manually to Telegram Desktop.
- `librewolf-userContent.css` scopes overrides to all HTTP/HTTPS pages via `@-moz-document regexp("https?://.*")`.

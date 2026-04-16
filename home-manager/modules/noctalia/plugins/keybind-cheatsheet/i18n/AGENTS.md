# Keybind Cheatsheet — i18n

Internationalization strings for the keybind-cheatsheet plugin. 20 locale files with identical JSON structure.

---

## Files

All files share four top-level keys: `default-category`, `error`, `panel`, `settings`, `barwidget`.

- `en.json` — English (canonical/authoritative)
- `de.json`, `es.json`, `fr.json`, `hn.json`, `hu.json`, `it.json`, `ja.json`, `ko-KR.json`, `ku.json`, `nl.json`, `nn-NO.json`, `pl.json`, `pt.json`, `ru.json`, `sv.json`, `tr.json`, `uk-UA.json`, `zh-CN.json`, `zh-TW.json`

---

## Conventions

- `en.json` is the source of truth — defines all keys.
- Every locale must have exactly the same key structure.
- Missing keys fall back to English (shell's i18n behavior).

---

## Gotchas

- Always edit `en.json` first, then propagate to all 19 other locales.
- `settings.keybind-example-hyprland` and `settings.keybind-example-niri` contain actual shell commands — must match real IPC syntax.
- Do NOT change JSON key names — QML references them via `pluginApi.tr("key.path")`.
- `panel.workspace-switching`, `panel.workspace-moving`, `panel.workspace-mouse` are used only for Hyprland's Polish locale category splitting.

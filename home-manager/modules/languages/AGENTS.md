# Language Toolchains

Language runtimes, CLI aliases, editor servers, and session wiring for Go, JavaScript/TypeScript, and Python.
Keep this directory focused on developer toolchains; app behavior belongs in `home-manager/modules/apps/`.

---

## Structure

| File              | Purpose                                                                                    |
| ----------------- | ------------------------------------------------------------------------------------------ |
| `default.nix`     | Import hub for language modules                                                            |
| `go.nix`          | Go runtime, aliases, GOPATH/GOBIN/session settings, Go tooling packages                    |
| `javascript.nix`  | Node/Bun/Deno toolchain, JS/TS aliases, Playwright wrapper, global package bootstrap       |
| `python.nix`      | Python toolchain, uv/poetry aliases, env/session vars, managed `.pythonrc`, workspace dirs |
| `mise.nix`        | Runtime manager configuration and shim path                                                |

---

## Conventions

- Keep shell aliases in `programs.{zsh,bash}.shellAliases` inside the language module, not in terminal modules.
- Keep language-specific git ignores in the same language module (`programs.git.ignores`).
- Put runtime binaries in `home.packages`; put shell/session wiring in `home.sessionVariables` and `home.sessionPath`.
- Activation hooks are allowed for workspace/bootstrap tasks (`lib.hm.dag.entryAfter [ "writeBoundary" ]`).
- `mise` is configured with Python disabled (`disable_tools = [ "python" ]`); Python ownership stays in `python.nix`.

---

## Where To Look

- Add a Go tool or alias: `go.nix`
- Add JS/TS tooling or Playwright wrapper behavior: `javascript.nix`
- Add Python tooling or REPL defaults: `python.nix`
- Add/adjust shared LSPs: `packages/lsp-servers.nix` (in the packages domain, not modules)
- Runtime manager behavior (shims/telemetry/flags): `mise.nix`

---

## Anti-Patterns

- Duplicating aliases in `home-manager/modules/terminal/` and here.
- Enabling Python in `mise.nix` while maintaining Python via `python.nix`.
- Putting application config (OBS, browser, desktop entries) in this directory.
- Adding project-specific dependencies here instead of dev shells (`dev-shells/`).

---

## Validation

```bash
just modules
just pkgs
just lint
just format
just check
just home
```

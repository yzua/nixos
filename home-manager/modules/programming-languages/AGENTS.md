# Programming Language Toolchains

Language runtimes, CLI aliases, editor servers, and session wiring for Go, JavaScript/TypeScript, and Python.
Keep this directory focused on developer toolchains; app behavior belongs in `home-manager/modules/apps/`.

---

## Structure

| Directory/File               | Purpose                                                                                    |
| ---------------------------- | ------------------------------------------------------------------------------------------ |
| `default.nix`                | Import hub for language modules                                                            |
| `python/`                    | Python toolchain, uv/poetry aliases, env/session vars, managed `.pythonrc`, workspace dirs |
| `python/_gitignores.nix`     | Python-specific `.gitignore` patterns (helper, imported by `default.nix`)                  |
| `javascript/`                | Node/Bun/Deno toolchain, JS/TS aliases, Playwright wrapper, global package bootstrap       |
| `javascript/_gitignores.nix` | JS/TS-specific `.gitignore` patterns (helper, imported by `default.nix`)                   |
| `go/`                        | Go runtime, aliases, GOPATH/GOBIN/session settings, Go tooling packages                    |
| `mise/`                      | Runtime manager configuration and shim path                                                |

---

## Conventions

- Keep shell aliases in `programs.{zsh,bash}.shellAliases` inside the language module, not in terminal modules.
- Keep language-specific git ignores in the same language module (`programs.git.ignores`).
- Put runtime binaries in `home.packages`; put shell/session wiring in `home.sessionVariables` and `home.sessionPath`.
- Activation hooks are allowed for workspace/bootstrap tasks (`lib.hm.dag.entryAfter [ "writeBoundary" ]`).
- `mise` is configured with Python disabled (`disable_tools = [ "python" ]`); Python ownership stays in `python/`.
- Each language gets its own subdirectory. Shared alias wiring is at repo-root `shared/_alias-helpers.nix` (imported via `../../../../shared/_alias-helpers.nix` from each language module).

---

## Where To Look

- Add a Go tool or alias: `go/default.nix`
- Add JS/TS tooling or Playwright wrapper behavior: `javascript/default.nix`
- Add Python tooling or REPL defaults: `python/default.nix`
- Add/adjust shared LSPs: `packages/lsp-servers.nix` (in the packages domain, not modules)
- Runtime manager behavior (shims/telemetry/flags): `mise/default.nix`

---

## Anti-Patterns

- Duplicating aliases in `home-manager/modules/terminal/` and here.
- Enabling Python in `mise/` while maintaining Python via `python/`.
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

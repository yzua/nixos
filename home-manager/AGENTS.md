# Home Manager User Scope

Top-level user configuration boundary. `home.nix` is the entrypoint and composes `modules/` (program/service configs) with `packages/` (chunked `home.packages`).

---

## Structure

| Path | Role |
|------|------|
| `home.nix` | HM entrypoint and shared user/session wiring |
| `modules/` | Program/service configuration modules |
| `modules/default.nix` | HM module import hub |
| `packages/` | Domain package chunks for `home.packages` |
| `packages/default.nix` | Package chunk import hub |

---

## Where To Look

- Configure an application/tool: `home-manager/modules/`
- Add language toolchain behavior: `home-manager/modules/languages/`
- Add or tune shell/CLI tooling: `home-manager/modules/terminal/`
- Add package(s) by domain: `home-manager/packages/<domain>.nix`
- Update user-level defaults/session vars: `home-manager/home.nix`

---

## Conventions

- Keep behavioral configuration in `modules/`; keep package grouping in `packages/`.
- Most HM modules configure `programs.*`, `services.*`, `home.*` directly.
- The only custom HM option namespace is `programs.aiAgents.*` in `modules/ai-agents/`.
- Maintain one domain per package chunk; add to existing chunks before creating new ones.
- Keep helper files prefixed `_` as manual imports, not import-hub entries.

---

## Anti-Patterns

- Putting system-level policy or hardware decisions in Home Manager modules.
- Defining new custom HM option namespaces outside `modules/ai-agents/`.
- Duplicating aliases/config between `modules/languages/` and `modules/terminal/`.
- Splitting a single package into multiple domain chunks without clear ownership.

---

## Validation

```bash
just modules
just lint
just format
just check
just home
```

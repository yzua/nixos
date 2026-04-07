# AI Agents Infrastructure

High-density orchestration for Claude Code, OpenCode, Codex CLI, and Gemini CLI. This module manages dynamic provider switching and secure secret injection.

---

## OVERVIEW

This module centralizes AI agent behavior across multiple CLI tools. It implements a layered configuration system that translates high-level Nix options into tool-specific JSON/TOML formats, enriched with lifecycle hooks and shared MCP capabilities.

---

## ARCHITECTURE

The system follows a strict unidirectional flow:

1. **Options** (`options.nix`): Defines the `programs.aiAgents.*` namespace.
2. **Config Hub** (`config/`): Domain-specific values for models, prompts, and permissions.
3. **Settings Builders** (`_settings-builders.nix`): Implements **Profile-Driven Polymorphism**.
4. **MCP Transforms** (`_mcp-transforms.nix`): **Unified MCP Abstraction** converts shared server definitions into agent-specific schemas (Claude stdio vs OpenCode remote vs Gemini HTTP).
5. **File Generation** (`files.nix`): Declares configuration files in XDG paths.
6. **Activation Logic** (`activation.nix`): Handles late-stage secret injection, best-effort skill management, and state caching.

### Profile-Driven Polymorphism

Profiles switch the primary model across all OpenCode config directories. Each profile (glm, gemini, gpt, openrouter, sonnet, zen) re-maps the model field via `_settings-builders.nix`, allowing instant provider migration with zero configuration redundancy.

---

## SECRETS

Secure secret injection is handled during the Home Manager activation phase to prevent sensitive keys from entering the Nix store.

1. **Placeholders**: Config files are written with unique placeholders (e.g., `__GITHUB_TOKEN_PLACEHOLDER__`).
2. **DAG Patching**: The `patchAiAgentSecrets` script runs as a DAG entry after `writeBoundary`.
3. **Injection**: It uses `jq` for JSON files and `sed` for TOML/Markdown, reading keys directly from `/run/secrets/` or `gh` CLI and overwriting the placeholders in-place.

---

## CONVENTIONS

### Unified MCP Abstraction

Never define MCP servers per-agent. Define them once in `programs.aiAgents.mcpServers`. The `_mcp-transforms.nix` logic automatically generates the correct transport configuration for every supported agent.

### Complexity Hotspots (WARNING)

This module contains significant **embedded Bash logic** that bypasses standard Nix abstraction for performance and compatibility:

- **`config/_claude-hooks.nix`**: Heavy use of `jq` and `grep` within Claude Code lifecycle hooks for auto-formatting and destructive command detection.
- **`activation.nix`**: Complex sequential skill installation/removal logic with state-caching to prevent redundant network calls; skill sync failures are logged as warnings so Home Manager activation can continue.

### Validation Pipeline

```bash
just modules   # Validate import tree
just lint      # Run statix/deadnix
just format    # nixfmt-tree
just check     # Full flake evaluation
just home      # Apply configuration
```

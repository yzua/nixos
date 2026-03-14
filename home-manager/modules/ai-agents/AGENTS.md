# AI Agents Infrastructure

High-density orchestration for Claude Code, OpenCode, Codex CLI, and Gemini CLI. This module manages a specialized 10-agent fleet with dynamic provider switching and secure secret injection.

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
6. **Activation Logic** (`activation.nix`): Handles late-stage secret injection, skill management, and state caching.

### Profile-Driven Polymorphism

The fleet is polymorphic. Switching the active profile (e.g., from `sonnet` to `glm`) re-maps every agent's model and variant (thinking level) across the entire fleet via `_settings-builders.nix`. This allows instant provider migration with zero configuration redundancy.

---

## FLEET CONFIG

The specialized 10-agent fleet is defined in `config/agents.nix` using the custom agent type in `_oh-my-opencode-agent-type.nix`.

| Role                | Core Purpose                                                                   |
| :------------------ | :----------------------------------------------------------------------------- |
| `sisyphus`          | **Focused Executor**. Delegates tasks, verifies outputs, and handles shipping. |
| `oracle`            | **Consultant**. Architecture review and deep debugging without write access.   |
| `librarian`         | **Researcher**. Manages external documentation and OSS pattern searches.       |
| `explore`           | **Code Map Navigator**. Fast contextual search and pattern extraction.         |
| `multimodal-looker` | **Visual Analyst**. Interprets PDFs, UI screenshots, and diagrams.             |
| `prometheus`        | **Strategist**. High-thinking planning with interactive Socratic interviewing. |
| `metis`             | **Analyst**. Pre-planning requirement discovery and risk assessment.           |
| `momus`             | **Critic**. Plan reviewer that validates clarity and execution safety.         |
| `atlas`             | **Coordinator**. Manages multi-agent execution and dependency tracking.        |
| `hephaestus`        | **Deep Worker**. Long-running autonomous tasks and heavy refactors.            |

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

- **`_claude-hooks.nix`**: Heavy use of `jq` and `grep` within Claude Code lifecycle hooks for auto-formatting and destructive command detection.
- **`activation.nix`**: Complex sequential skill installation logic with state-caching to prevent redundant network calls.

### Validation Pipeline

```bash
just modules   # Validate import tree
just lint      # Run statix/deadnix
just format    # nixfmt-tree
just check     # Full flake evaluation
just home      # Apply configuration
```

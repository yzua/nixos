# AI Agents Configuration

Multi-agent orchestration for Claude Code, OpenCode, Codex CLI, and Gemini CLI. Largest HM module (20 files, 2800+ lines). Uses a layered architecture: options → config values → settings builders → file generation → activation-time secret injection.

**Option namespace**: `programs.aiAgents.*` (exception — only HM module with custom options).

---

## Architecture

```
options.nix (defines programs.aiAgents.*)
    ↓
config/ (split configuration values)
    ├── instructions.nix   # Global rules + 13 skills
    ├── mcp-servers.nix    # 7 MCP servers (context7, zai, web-search, filesystem, sequential-thinking, cloudflare, github)
    ├── permissions.nix    # Claude: 49 allow rules, 13 deny rules, 11 lifecycle hooks
    ├── models.nix         # Provider registries (OpenCode, Codex, Gemini)
    └── agents.nix         # 10 oh-my-opencode agents + categories + concurrency
    ↓
_settings-builders.nix (generates 5 profile variants: default, glm, gemini, gpt, sonnet)
_mcp-transforms.nix (converts shared MCP defs → agent-specific formats)
    ↓
files.nix (writes JSON/TOML/Markdown config files to ~/.config/*)
    ↓
activation.nix (injects secrets from sops, installs plugins)
    ↓
services.nix (zsh aliases, systemd timers, packages)
```

---

## File Map

| File | Lines | Purpose |
|------|-------|---------|
| `options.nix` | 470 | All `programs.aiAgents.*` option definitions |
| `activation.nix` | 426 | Secret patching (Z.AI key, GitHub token), plugin installs (oh-my-claudecode, everything-claude-code) |
| `files.nix` | 298 | `home.file` + `xdg.configFile` declarations for all agents |
| `services.nix` | 76 | Packages, zsh aliases, systemd log-cleanup timers |
| `log-analyzer.nix` | 100+ | CLI: `ai-agent-analyze stats\|errors\|sessions\|search\|tail\|report` |
| `config.nix` | 8 | Pass-through to `config/` subdirectory |
| `config/instructions.nix` | 136 | Global instructions + skill installations |
| `config/mcp-servers.nix` | 63 | MCP server definitions + logging config |
| `config/permissions.nix` | 437 | Claude permissions, hooks, and settings |
| `config/models.nix` | 344 | Model/provider registries |
| `config/agents.nix` | 161 | Oh-My-OpenCode agent definitions (10 agents) |

### Helper Files (prefixed `_`, NOT in `default.nix`)

| File | Lines | Purpose |
|------|-------|---------|
| `_settings-builders.nix` | 305 | Per-agent settings with 5 profile variants |
| `_mcp-transforms.nix` | 96 | Shared MCP → Claude/OpenCode/Gemini format transforms |
| `_opencode-profiles.nix` | 17 | Profile names and config paths |

---

## Supported Agents

| Agent | Model (default) | Config Location | Format |
|-------|----------------|-----------------|--------|
| Claude Code | `claude-opus-4-6` | `~/.claude/settings.json`, `~/.mcp.json`, `~/.claude/CLAUDE.md` | JSON + Markdown |
| OpenCode | `anthropic/claude-opus-4-6` | `~/.config/opencode*/opencode.json` | JSON |
| Codex CLI | `gpt-5.3-codex` | `~/.codex/config.toml` | TOML |
| Gemini CLI | Gemini 3 Pro | `~/.gemini/settings.json` | JSON |

### Profile Variants (OpenCode)

5 profiles swap the entire agent fleet between providers:

| Profile | Binary | Primary Model |
|---------|--------|---------------|
| `opencode` | `opencode` | Anthropic Opus |
| `opencode-glm` | `opencode-glm` | Z.AI GLM-5 |
| `opencode-gemini` | `opencode-gemini` | Google Antigravity |
| `opencode-gpt` | `opencode-gpt` | OpenAI GPT-5.3 |
| `opencode-sonnet` | `opencode-sonnet` | Anthropic Sonnet |

### Oh-My-OpenCode Agents (10)

| Agent | Model | Role |
|-------|-------|------|
| `sisyphus` | Opus | Primary orchestrator — delegates, verifies, ships |
| `oracle` | Opus | Read-only consultant — architecture, debugging |
| `librarian` | Sonnet | External reference search — docs, OSS |
| `explore` | Haiku | Fast contextual grep — codebase patterns |
| `multimodal-looker` | Gemini Flash | Visual content analysis — PDFs, images |
| `prometheus` | Opus (max thinking) | Strategic planner with interview mode |
| `metis` | Opus | Pre-planning analysis — hidden requirements |
| `momus` | Opus | Plan reviewer — validates clarity |
| `atlas` | Sonnet | Orchestrator/conductor — coordinates execution |
| `hephaestus` | GPT-5.3 | Autonomous deep worker — long-running tasks |

---

## Unique Patterns

### Profile Variant System (`_settings-builders.nix`)

Generates 5 OpenCode configs at eval time. Each profile overrides model + agent models + category models. Switching provider = changing one profile, zero duplication.

### Activation-Time Secret Injection

Secrets from sops-nix injected **after** config files are written via `jq` (JSON) and `sed` (TOML). Secrets never touch disk unencrypted. DAG order: `writeBoundary` → `patchAiAgentSecrets` → `installAgentSkills` → agent-specific setup.

### Lifecycle Hooks (Claude Code)

11 hook types as Nix-generated shell scripts:
- **PreToolUse**: Destructive command detection, pre-commit lint, dev server blocking
- **PostToolUse**: Auto-format per language (biome, rustfmt, ruff, prettier, nixfmt), TypeScript checking
- **SessionStart/End**: Session state persistence
- **PreCompact**: Compaction state saving

---

## Adding an MCP Server

1. Define in `config/mcp-servers.nix` under `programs.aiAgents.mcpServers`
2. Set `type = "stdio"` or `"sse"` with `command`/`args` or `url`
3. MCP transforms in `_mcp-transforms.nix` auto-convert to each agent's format
4. Run `just home`

## Adding a Lifecycle Hook

1. Edit `config/permissions.nix` under the appropriate hook type
2. Add matcher pattern and command array
3. Run `just home`

## Adding an Agent (Oh-My-OpenCode)

1. Define in `config/agents.nix` under `programs.aiAgents.opencode.ohMyOpencode.agents`
2. Set model, description, and optional system prompt
3. Add per-profile model overrides in `_settings-builders.nix` if needed
4. Run `just home`

# AI Agents Improvement Notes

Date: 2026-02-15
Repository: /home/yz/System

## Scope

This document consolidates:

- Current local AI agent configuration findings from:
  - `home-manager/modules/ai-agents/config/*.nix`
  - `guides/AI-AGENTS-GUIDE.md`
- External research from official docs and active GitHub repositories.
- Practical improvements and options mapped to your Nix setup.

## Current State (Local Config Audit)

## Strong Baseline Already in Place

- Multi-agent stack with Claude Code, OpenCode (+ oh-my-opencode), Gemini CLI, and Codex.
- Shared MCP topology and secret patching workflow.
- Claude hook coverage is extensive (PreToolUse, PostToolUse, SessionStart/End, PreCompact, Notification, Stop, PostToolUseFailure).
- Good guardrails:
  - destructive command warning hook
  - protected secret paths
  - formatter hooks by file type
  - optional TypeScript on-edit check hook
- Good OpenCode orchestration:
  - role-specialized agents
  - provider and model concurrency caps
  - tmux visual mode
  - aggressive truncation and preemptive compaction
- Good Gemini baseline:
  - caution sandbox mode
  - custom Gruvbox theme
  - context file loading
  - search grounding enabled
  - compression threshold tuned to 0.75
- Good Codex baseline:
  - pragmatic personality
  - profile support
  - request rule + collaboration mode features on
  - trusted project set

## Notable Config Facts (Evidence)

- Claude model and env:
  - `model = "opus"` (`home-manager/modules/ai-agents/config/permissions.nix:8`)
  - `MAX_MCP_OUTPUT_TOKENS = "50000"` (`home-manager/modules/ai-agents/config/permissions.nix:13`)
  - `ENABLE_TOOL_SEARCH = "auto:5"` (`home-manager/modules/ai-agents/config/permissions.nix:15`)
- Claude extra settings:
  - `cleanupPeriodDays = 14` (`home-manager/modules/ai-agents/config/permissions.nix:422`)
  - `alwaysThinkingEnabled = true` (`home-manager/modules/ai-agents/config/permissions.nix:424`)
  - `autoUpdatesChannel = "latest"` (`home-manager/modules/ai-agents/config/permissions.nix:427`)
- Codex settings:
  - `model = "gpt-5.3-codex"` (`home-manager/modules/ai-agents/config/models.nix:149`)
  - `approvalPolicy = "on-request"` (`home-manager/modules/ai-agents/config/models.nix:152`)
  - features include `request_rule`, `collaboration_modes`, `model_reasoning_summary` (`home-manager/modules/ai-agents/config/models.nix:158`, `home-manager/modules/ai-agents/config/models.nix:159`, `home-manager/modules/ai-agents/config/models.nix:161`)
- Gemini settings:
  - `theme = "Gruvbox"` (`home-manager/modules/ai-agents/config/models.nix:183`)
  - `sandboxMode = "cautious"` (`home-manager/modules/ai-agents/config/models.nix:184`)
  - `enableAutoUpdate = true` (`home-manager/modules/ai-agents/config/models.nix:203`)
  - `usageStatisticsEnabled = false` (`home-manager/modules/ai-agents/config/models.nix:212`)
  - `compressionThreshold = 0.75` (`home-manager/modules/ai-agents/config/models.nix:280`)
- MCP servers:
  - enabled: filesystem, memory, sequential-thinking, playwright, github, context7, cloudflare-docs
  - disabled: git, web-search-prime
  - evidence: `home-manager/modules/ai-agents/config/mcp-servers.nix:21`, `home-manager/modules/ai-agents/config/mcp-servers.nix:27`, `home-manager/modules/ai-agents/config/mcp-servers.nix:33`, `home-manager/modules/ai-agents/config/mcp-servers.nix:39`, `home-manager/modules/ai-agents/config/mcp-servers.nix:44`, `home-manager/modules/ai-agents/config/mcp-servers.nix:49`, `home-manager/modules/ai-agents/config/mcp-servers.nix:58`, `home-manager/modules/ai-agents/config/mcp-servers.nix:82`
- Skills list is broad and includes multiple large bundles:
  - `obra/superpowers`, `anthropics/skills`, `affaan-m/everything-claude-code`, `alirezarezvani/claude-skills`, plus many single skills (`home-manager/modules/ai-agents/config/instructions.nix:75`)

## Guide Drift (Config vs docs)

The guide and config differ in several places:

1. Claude auto-update channel:
   - Guide says `stable` (`guides/AI-AGENTS-GUIDE.md:78`)
   - Config uses `latest` (`home-manager/modules/ai-agents/config/permissions.nix:427`)
2. Gemini theme:
   - Guide says `Default` (`guides/AI-AGENTS-GUIDE.md:100`)
   - Config uses `Gruvbox` (`home-manager/modules/ai-agents/config/models.nix:183`)
3. Gemini auto-update:
   - Guide says disabled (`guides/AI-AGENTS-GUIDE.md:102`)
   - Config enables updates and notifications (`home-manager/modules/ai-agents/config/models.nix:203`, `home-manager/modules/ai-agents/config/models.nix:204`)

## External Research Summary

## Official Codex Capabilities Worth Leveraging

From OpenAI Codex docs and repo:

- Rich MCP server config controls are supported (timeouts, required servers, tool filtering, streamable HTTP options).
- Codex supports hierarchical AGENTS behavior via `child_agents_md` feature flag.
- Codex supports skills ecosystem and curated/system skill model.

Inference: your Codex config currently uses core features well, but can be hardened with per-server MCP controls and hierarchical AGENTS behavior.

## Official Gemini CLI Capabilities Worth Leveraging

From Gemini CLI docs:

- Strong config layering model (system defaults, user, project, env, args).
- `security.folderTrust.enabled` safe-mode model for untrusted folders.
- MCP allow/exclude at global level and include/exclude at per-server level.
- MCP server trust toggle (`trust`), timeout, headers, OAuth support.
- Built-in MCP server management commands (`gemini mcp add/list/remove/enable/disable`).
- Token-caching notes and `/stats` for cache savings visibility.

Inference: your Gemini config is strong, but explicit folder trust + tighter MCP allow/deny would improve security posture.

## MCP Ecosystem Signals

From `modelcontextprotocol/servers`:

- The repo is explicitly positioned as reference implementations.
- It explicitly points to the official MCP Registry for published servers.

Inference: production MCP selection should prefer maintained official integrations and vetted registries, not archived reference examples.

## High-Signal GitHub Tooling and Ideas

- `openai/skills`
  - Curated skills are available and installable via skill installer semantics.
  - Useful for replacing ad-hoc skill sprawl with curated, deterministic set.
- `snyk/agent-scan` (`mcp-scan`)
  - Scans agent stack (MCP servers + skills) for prompt-injection/tool-poisoning style risk.
- `stacklok/toolhive`
  - Operational platform for secure MCP runtime and governance.
- `mcp-router/mcp-router`
  - Local MCP routing/management UX and tool toggling.
- `anomalyco/opencode` + `code-yeongyu/oh-my-opencode`
  - Confirms active ecosystem and ongoing feature evolution around orchestration, contexts, and specialized agents.

## Priority Recommendations

## P0 (High impact, low-medium effort)

1. Codex MCP least-privilege and reliability controls.
   - File: `home-manager/modules/ai-agents/config/models.nix`
   - Add per-MCP options in `extraToml`:
     - `required = true` for must-have servers (for example filesystem/memory/context7)
     - `enabled_tools`/`disabled_tools` for server-level narrowing
     - `startup_timeout_sec` and `tool_timeout_sec`
   - Why: reduce accidental tool surface and make failures explicit.

2. Enable Codex hierarchical AGENTS behavior.
   - File: `home-manager/modules/ai-agents/config/models.nix`
   - Add:
     - `[features] child_agents_md = true`
   - Why: improves nested-instruction correctness in larger repos.

3. Gemini trust boundary hardening.
   - File: `home-manager/modules/ai-agents/config/models.nix`
   - Add:
     - `security.folderTrust.enabled = true`
     - `mcp.allowed` / `mcp.excluded` where appropriate
     - per-server include/exclude tools for sensitive servers
   - Why: safer behavior on unknown/untrusted projects.

4. Add automated MCP/skill security scan command.
   - File: `home-manager/modules/ai-agents/services.nix` (or terminal scripts module)
   - Add alias/script around:
     - `uvx mcp-scan@latest --skills`
   - Optional: periodic user timer.
   - Why: continuous security feedback for dynamic MCP/skill ecosystem.

5. Resolve guide drift now.
   - File: `guides/AI-AGENTS-GUIDE.md`
   - Update guide values to match live Nix config.
   - Why: removes operator confusion and stale assumptions.

## P1 (Strong improvements, medium effort)

1. Normalize skill pack strategy.
   - File: `home-manager/modules/ai-agents/config/instructions.nix`
   - Move toward curated allowlist:
     - keep high-value curated/system skills
     - prune overlapping large bundles
   - Why: reduce collisions, ambiguity, and instruction conflicts.

2. Add explicit "trust tiers" for MCP servers in guide.
   - File: `guides/AI-AGENTS-GUIDE.md`
   - Suggested tiers:
     - Tier A: official/local/vetted
     - Tier B: remote with scoped token
     - Tier C: experimental third-party
   - Why: easier operational risk decisions.

3. Hook performance tuning.
   - File: `home-manager/modules/ai-agents/config/permissions.nix`
   - For heavy hooks (lint/tsc), prefer non-blocking pattern when available (`run_in_background` in compatible clients).
   - Why: avoid editing latency while keeping safety signals.

4. Cross-agent output schema for reports.
   - Files:
     - `home-manager/modules/ai-agents/config/instructions.nix`
     - `guides/AI-AGENTS-GUIDE.md`
   - Add consistent sections for agent outputs: findings, severity, evidence, verification.
   - Why: easier human review and automated parsing.

5. Add fail-closed behavior for critical remote MCP auth.
    - Files:
      - `home-manager/modules/ai-agents/config/mcp-servers.nix`
      - activation patch logic
    - Require secrets/token presence for specific servers before exposing them.
    - Why: avoid silent partial functionality and risky fallbacks.

## P2 (Optional / exploratory)

1. Evaluate ToolHive or MCP Router for server lifecycle management.
    - Good for at-scale MCP governance and operator UX.
    - Probably overkill for single-machine setup unless you want stronger central controls and observability.

2. Add skill security lint step before skill updates.
    - Workflow: install/update skills -> run `mcp-scan --skills` -> accept/reject.

3. Consider codifying "approved MCP sources" list.
    - Add to guide and global instructions to reduce ad-hoc installs.

## Concrete Change Plan (Minimal Diffs)

If implemented conservatively, minimal edits should touch only:

1. `home-manager/modules/ai-agents/config/models.nix`
   - Codex feature additions (`child_agents_md`, MCP controls)
   - Gemini `security.folderTrust` + MCP allow/deny policy
2. `home-manager/modules/ai-agents/config/instructions.nix`
   - skill set curation (optional but recommended)
3. `home-manager/modules/ai-agents/services.nix` or terminal scripts module
   - `mcp-scan` command alias/script/timer
4. `guides/AI-AGENTS-GUIDE.md`
   - update stale values and add trust-tier/security workflow notes

## Suggested Implementation Snippets (Illustrative)

These are illustrative direction notes, not copy-paste final code:

- Codex TOML direction:
  - add `child_agents_md = true` under `[features]`
  - define `[mcp_servers.<name>]` blocks with:
    - `required`
    - `enabled_tools` / `disabled_tools`
    - `startup_timeout_sec`
    - `tool_timeout_sec`

- Gemini direction:
  - under `extraSettings`:
    - `security.folderTrust.enabled = true`
    - `mcp.allowed = [ ... ]`
    - `mcp.excluded = [ ... ]`
  - under `mcpServers.<server>`:
    - `includeTools = [ ... ]`
    - `excludeTools = [ ... ]`
    - `trust = false` unless fully trusted

## Notes on Source Quality

- Official docs and official repos were prioritized.
- Third-party repos were included as options only, not defaults.
- Any recommendation based on third-party tooling is optional and should be gated by your security model.

## Full Source Links

## Official / primary

- OpenAI Codex config docs:
  - <https://developers.openai.com/codex/config-reference>
  - <https://developers.openai.com/codex/config-advanced>
  - <https://developers.openai.com/codex/config-basic>
  - <https://developers.openai.com/codex/mcp>
  - <https://developers.openai.com/codex/security>
  - <https://developers.openai.com/codex/skills>
- OpenAI Codex repo:
  - <https://github.com/openai/codex>
  - <https://github.com/openai/codex/blob/main/docs/agents_md.md>
  - <https://github.com/openai/codex/blob/main/docs/config.md>
- Claude Code docs:
  - <https://docs.anthropic.com/en/docs/claude-code/hooks>
  - <https://docs.anthropic.com/en/docs/claude-code/settings>
  - <https://docs.anthropic.com/en/docs/claude-code/memory>
  - <https://docs.anthropic.com/en/docs/claude-code/sub-agents>
- Gemini CLI docs:
  - <https://github.com/google-gemini/gemini-cli>
  - <https://github.com/google-gemini/gemini-cli/blob/main/docs/get-started/configuration.md>
  - <https://github.com/google-gemini/gemini-cli/blob/main/docs/tools/mcp-server.md>
  - <https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/trusted-folders.md>
  - <https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/token-caching.md>
- MCP official:
  - <https://github.com/modelcontextprotocol/servers>
  - <https://registry.modelcontextprotocol.io/>

## Ecosystem / optional tooling

- OpenAI skills repo:
  - <https://github.com/openai/skills>
- OpenCode:
  - <https://github.com/anomalyco/opencode>
- oh-my-opencode:
  - <https://github.com/code-yeongyu/oh-my-opencode>
- MCP security scanning:
  - <https://github.com/snyk/agent-scan>
- MCP governance platforms:
  - <https://github.com/stacklok/toolhive>
  - <https://github.com/mcp-router/mcp-router>
- Discovery lists (use for exploration, not blind trust):
  - <https://github.com/punkpeye/awesome-mcp-servers>
  - <https://github.com/wong2/awesome-mcp-servers>

## Final Take

You already have a high-quality setup. The biggest upgrade opportunities are:

1. tighten MCP least-privilege controls (especially Codex + Gemini),
2. add routine MCP/skill security scanning,
3. reduce skill overlap noise,
4. fix guide drift so operational docs match reality.

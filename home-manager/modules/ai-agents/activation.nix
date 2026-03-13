# Home Manager activation scripts for AI agent setup and secret patching.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.aiAgents;

  inherit (builtins) toJSON;

  mcpTransforms = import ./_mcp-transforms.nix { inherit config lib pkgs; };
  inherit (mcpTransforms) sharedMcpServers claudeMcpServers;

  settingsBuilders = import ./_settings-builders.nix { inherit config lib pkgs; };
  inherit (settingsBuilders) claudeSettings;

  opencodeProfiles = import ./_opencode-profiles.nix { inherit config; };
  opencodeConfigPaths = map opencodeProfiles.configPath opencodeProfiles.names;
  opencodeConfigPathList = lib.concatMapStringsSep " " lib.escapeShellArg opencodeConfigPaths;
  opencodeZaiFilter = ''
    (if .mcp["zai-mcp-server"] != null then .mcp["zai-mcp-server"].environment.Z_AI_API_KEY = $key else . end) |
    .mcp["web-search-prime"] = {
      type: "remote",
      url: "https://api.z.ai/api/mcp/web_search_prime/mcp",
      headers: { Authorization: ("Bearer " + $key) }
    } |
    .mcp["web-reader"] = {
      type: "remote",
      url: "https://api.z.ai/api/mcp/web_reader/mcp",
      headers: { Authorization: ("Bearer " + $key) }
    } |
    .mcp["zread"] = {
      type: "remote",
      url: "https://api.z.ai/api/mcp/zread/mcp",
      headers: { Authorization: ("Bearer " + $key) }
    }
  '';
  claudeZaiFilter = ''
    (if .mcpServers["zai-mcp-server"] != null then .mcpServers["zai-mcp-server"].env.Z_AI_API_KEY = $key else . end) |
    .mcpServers["web-search-prime"] = {
      type: "http",
      url: "https://api.z.ai/api/mcp/web_search_prime/mcp",
      headers: { Authorization: ("Bearer " + $key) }
    } |
    .mcpServers["web-reader"] = {
      type: "http",
      url: "https://api.z.ai/api/mcp/web_reader/mcp",
      headers: { Authorization: ("Bearer " + $key) }
    } |
    .mcpServers["zread"] = {
      type: "http",
      url: "https://api.z.ai/api/mcp/zread/mcp",
      headers: { Authorization: ("Bearer " + $key) }
    }
  '';
  geminiZaiFilter = ''
    (if .mcpServers["zai-mcp-server"] != null then .mcpServers["zai-mcp-server"].env.Z_AI_API_KEY = $key else . end) |
    .mcpServers["web-search-prime"] = {
      command: "echo",
      args: [],
      url: "https://api.z.ai/api/mcp/web_search_prime/mcp",
      headers: { Authorization: ("Bearer " + $key) },
      type: "http"
    } |
    .mcpServers["web-reader"] = {
      command: "echo",
      args: [],
      url: "https://api.z.ai/api/mcp/web_reader/mcp",
      headers: { Authorization: ("Bearer " + $key) },
      type: "http"
    } |
    .mcpServers["zread"] = {
      command: "echo",
      args: [],
      url: "https://api.z.ai/api/mcp/zread/mcp",
      headers: { Authorization: ("Bearer " + $key) },
      type: "http"
    }
  '';
  githubPlaceholderFilter = ''
    walk(if type == "string" then gsub("__GITHUB_TOKEN_PLACEHOLDER__"; $token) else . end)
  '';
  openrouterPlaceholderFilter = ''
    walk(if type == "string" then gsub("__OPENROUTER_API_KEY_PLACEHOLDER__"; $key) else . end)
  '';

  # Import helper modules
  secretPatching = import ./_secret-patching.nix {
    inherit
      cfg
      pkgs
      lib
      opencodeConfigPathList
      opencodeZaiFilter
      claudeZaiFilter
      geminiZaiFilter
      githubPlaceholderFilter
      openrouterPlaceholderFilter
      ;
  };
  codexConfig = import ./_codex-config.nix {
    inherit
      cfg
      pkgs
      lib
      sharedMcpServers
      ;
  };
  claudeConfig = import ./_claude-config.nix {
    inherit
      cfg
      pkgs
      lib
      toJSON
      claudeSettings
      claudeMcpServers
      ;
  };
  pluginInstalls = import ./_plugin-installs.nix {
    inherit cfg pkgs lib;
  };
in
{
  config = lib.mkIf cfg.enable {
    home.activation = {
      # === Secret Patching ===
      # Runs after all config writers so keys can be injected last.
      patchAiAgentSecrets = secretPatching;

      # === Skill Installation ===
      installAgentSkills =
        let
          # Pre-generate install commands at Nix eval time
          skillCommands = map (
            s:
            if builtins.isString s then
              # Repo-level: skills add "owner/repo" --global --all --yes
              ''
                echo "  → ${s}"
                $DRY_RUN_CMD "$SKILLS_BIN" add "${s}" --global --all --yes 2>&1 | tail -1 || true
              ''
            else
              # Individual: skills add https://github.com/owner/repo --skill name --global --all --yes
              ''
                echo "  → ${s.repo}#${s.skill}"
                $DRY_RUN_CMD "$SKILLS_BIN" add "https://github.com/${s.repo}" --skill "${s.skill}" --global --all --yes 2>&1 | tail -1 || true
              ''
          ) cfg.skills;
        in
        lib.mkIf (cfg.skills != [ ]) (
          lib.hm.dag.entryAfter [ "writeBoundary" "createJSWorkspace" ] ''
            SKILLS_BIN="$HOME/.bun/bin/skills"
            if [[ ! -x "$SKILLS_BIN" ]]; then
              SKILLS_BIN="$(command -v skills 2>/dev/null || true)"
            fi

            # Ensure runtime dependencies for the skills CLI are available in
            # Home Manager activation environment.
            export PATH="${pkgs.nodejs}/bin:${pkgs.bun}/bin:$PATH"

            if [[ -n "$SKILLS_BIN" ]]; then
              echo "📦 Installing agent skills from skills.sh..."
              ${lib.concatStringsSep "" skillCommands}
              echo "✓ Skills installation complete"
            else
              echo "⚠ skills CLI not found — run 'bun install -g skills' first"
            fi
          ''
        );

      # === Codex Configuration ===
      setupCodexConfig = codexConfig;

      # === Claude Configuration ===
      # Real files (not symlinks) so plugins can modify them.
      setupClaudeConfig = claudeConfig;

      # === Claude Plugin Installation + Everything Claude Code ===
      inherit (pluginInstalls) installOhMyClaudeCode installEverythingClaudeCode;
    };
  };
}

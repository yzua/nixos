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
in
{
  config = lib.mkIf cfg.enable {
    home.activation = {
      # Runs after all config writers so keys can be injected last.
      patchAiAgentSecrets = lib.mkIf (cfg.secrets.zaiApiKeyFile != null) (
        lib.hm.dag.entryAfter [ "writeBoundary" "linkGeneration" "setupCodexConfig" "setupClaudeConfig" ] ''
          if [[ -f "${cfg.secrets.zaiApiKeyFile}" ]]; then
            ZAI_KEY="$(cat "${cfg.secrets.zaiApiKeyFile}")"

            for OPENCODE_CFG in "$HOME/.config/opencode/opencode.json" "$HOME/.config/opencode-glm/opencode.json" "$HOME/.config/opencode-gemini/opencode.json"; do
              if [[ -f "$OPENCODE_CFG" ]]; then
                ${pkgs.jq}/bin/jq --arg key "$ZAI_KEY" '
                  .mcp["zai-mcp-server"].environment.Z_AI_API_KEY = $key |
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
                ' "$OPENCODE_CFG" > "$OPENCODE_CFG.tmp" && mv "$OPENCODE_CFG.tmp" "$OPENCODE_CFG"
                echo "✓ Patched $(basename "$(dirname "$OPENCODE_CFG")")/opencode.json with Z.AI API key"
              fi
            done

            CLAUDE_MCP="$HOME/.mcp.json"
            if [[ -f "$CLAUDE_MCP" ]]; then
              ${pkgs.jq}/bin/jq --arg key "$ZAI_KEY" '
                .mcpServers["zai-mcp-server"].env.Z_AI_API_KEY = $key |
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
              ' "$CLAUDE_MCP" > "$CLAUDE_MCP.tmp" && mv "$CLAUDE_MCP.tmp" "$CLAUDE_MCP"
              echo "✓ Patched .mcp.json with Z.AI API key + remote MCPs"
            fi

            CODEX_CFG="$HOME/.codex/config.toml"
            if [[ -f "$CODEX_CFG" ]]; then
              if grep -q '\[mcp_servers.zai-mcp-server.env\]' "$CODEX_CFG"; then
                ESCAPED_ZAI=$(printf '%s\n' "$ZAI_KEY" | ${pkgs.gnused}/bin/sed 's/[&/\]/\\&/g')
                ${pkgs.gnused}/bin/sed -i "/\[mcp_servers.zai-mcp-server.env\]/a Z_AI_API_KEY = \"$ESCAPED_ZAI\"" "$CODEX_CFG"
                unset ESCAPED_ZAI
              fi
              echo "✓ Patched codex config.toml with Z.AI API key"
            fi

            GEMINI_CFG="$HOME/.gemini/settings.json"
            if [[ -f "$GEMINI_CFG" ]]; then
              ${pkgs.jq}/bin/jq --arg key "$ZAI_KEY" '
                .mcpServers["zai-mcp-server"].env.Z_AI_API_KEY = $key |
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
                }
              ' "$GEMINI_CFG" > "$GEMINI_CFG.tmp" && mv "$GEMINI_CFG.tmp" "$GEMINI_CFG"
              echo "✓ Patched gemini settings.json with Z.AI API key + remote MCPs"
            fi
          else
            echo "⚠ ${cfg.secrets.zaiApiKeyFile} not found - run 'just nixos' first"
          fi

          # Inject GitHub token from gh CLI into all agent configs
          if ${pkgs.gh}/bin/gh auth status &> /dev/null; then
            GH_TOKEN="$(${pkgs.gh}/bin/gh auth token)"
            # SECURITY: Use jq for JSON files (safe handling of special chars in tokens)
            for OPENCODE_CFG in "$HOME/.config/opencode/opencode.json" "$HOME/.config/opencode-glm/opencode.json" "$HOME/.config/opencode-gemini/opencode.json"; do
              if [[ -f "$OPENCODE_CFG" ]]; then
                ${pkgs.jq}/bin/jq --arg token "$GH_TOKEN" '
                  walk(if type == "string" then gsub("__GITHUB_TOKEN_PLACEHOLDER__"; $token) else . end)
                ' "$OPENCODE_CFG" > "$OPENCODE_CFG.tmp" && mv "$OPENCODE_CFG.tmp" "$OPENCODE_CFG"
              fi
            done
            if [[ -f "$HOME/.mcp.json" ]]; then
              ${pkgs.jq}/bin/jq --arg token "$GH_TOKEN" '
                walk(if type == "string" then gsub("__GITHUB_TOKEN_PLACEHOLDER__"; $token) else . end)
              ' "$HOME/.mcp.json" > "$HOME/.mcp.json.tmp" && mv "$HOME/.mcp.json.tmp" "$HOME/.mcp.json"
            fi
            if [[ -f "$HOME/.codex/config.toml" ]]; then
              ESCAPED_TOKEN=$(printf '%s\n' "$GH_TOKEN" | ${pkgs.gnused}/bin/sed 's/[&/\]/\\&/g')
              ${pkgs.gnused}/bin/sed -i "s/__GITHUB_TOKEN_PLACEHOLDER__/$ESCAPED_TOKEN/g" "$HOME/.codex/config.toml"
            fi
            if [[ -f "$HOME/.gemini/settings.json" ]]; then
              ${pkgs.jq}/bin/jq --arg token "$GH_TOKEN" '
                walk(if type == "string" then gsub("__GITHUB_TOKEN_PLACEHOLDER__"; $token) else . end)
              ' "$HOME/.gemini/settings.json" > "$HOME/.gemini/settings.json.tmp" && mv "$HOME/.gemini/settings.json.tmp" "$HOME/.gemini/settings.json"
            fi
            unset GH_TOKEN
            echo "✓ Patched GitHub token from gh CLI into all agent configs"
          else
            echo "⚠ gh CLI not authenticated - GitHub MCP will not work (run 'gh auth login')"
          fi
        ''
      );

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
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            SKILLS_BIN="$HOME/.bun/bin/skills"
            if [[ ! -x "$SKILLS_BIN" ]]; then
              SKILLS_BIN="$(command -v skills 2>/dev/null || true)"
            fi
            if [[ -n "$SKILLS_BIN" ]]; then
              echo "📦 Installing agent skills from skills.sh..."
              ${lib.concatStringsSep "" skillCommands}
              echo "✓ Skills installation complete"
            else
              echo "⚠ skills CLI not found — run 'bun install -g skills' first"
            fi
          ''
        );

      setupCodexConfig = lib.mkIf cfg.codex.enable (
        let
          codexNotifyScript = pkgs.writeShellScript "codex-notify" ''
            #!/usr/bin/env bash
            set -euo pipefail

            payload=""
            for arg in "$@"; do
              if [[ -n "$arg" ]] && ${pkgs.jq}/bin/jq -e . >/dev/null 2>&1 <<< "$arg"; then
                payload="$arg"
                break
              fi
            done

            if [[ -z "$payload" ]]; then
              payload="$*"
            fi

            if [[ -z "$payload" ]] && [[ ! -t 0 ]]; then
              payload="$(cat)"
            fi

            summary="Codex"
            body="$payload"

            if [[ -n "$payload" ]] && ${pkgs.jq}/bin/jq -e . >/dev/null 2>&1 <<< "$payload"; then
              summary="$(${pkgs.jq}/bin/jq -r 'if type == "object" then (.title // .summary // "Codex") else "Codex" end' <<< "$payload")"
              body="$(${pkgs.jq}/bin/jq -r '
                if type == "object" then
                  (.message // .body // ."last-assistant-message" // .content // .type // "Codex notification")
                else
                  .
                end
              ' <<< "$payload")"
            fi

            body="$(printf '%s' "$body" | tr '\n' ' ')"
            body="$(printf '%s' "$body" | ${pkgs.gnused}/bin/sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')"
            if [[ -z "$body" ]]; then
              body="Notification"
            fi

            notify-send -a "Codex" -i dialog-information "$summary" "$body" 2>/dev/null || true
          '';
          mcpToml = lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              name: server:
              let
                argsStr = lib.concatMapStringsSep ", " (a: ''"${a}"'') (server.args or [ ]);
                envLines = lib.concatStringsSep "\n" (
                  lib.mapAttrsToList (k: v: ''${k} = "${v}"'') (server.env or { })
                );
              in
              ''
                [mcp_servers.${name}]
                command = "${server.command}"
                args = [${argsStr}]
                enabled = true
              ''
              + lib.optionalString (server.env or { } != { }) ''
                [mcp_servers.${name}.env]
                ${envLines}
              ''
            ) (lib.filterAttrs (_: s: s.enable && (s.type or "local") == "local") sharedMcpServers)
          );
          projectsToml = lib.concatMapStringsSep "\n" (path: ''
            [projects."${path}"]
            trust_level = "trusted"
          '') cfg.codex.trustedProjects;
        in
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "$HOME/.codex"
          cat > "$HOME/.codex/config.toml" << 'CODEX_EOF'
          personality = "${cfg.codex.personality}"
          model = "${cfg.codex.model}"
          model_reasoning_effort = "${cfg.codex.reasoningEffort}"
          approval_policy = "${cfg.codex.approvalPolicy}"
          check_for_update_on_startup = true

          web_search = "live"

          notify = ["${codexNotifyScript}"]

          developer_instructions = """
          Experienced developer. Concise communication, no preamble.
          Evidence-based decisions. Minimal changes - fix bugs without refactoring.
          Never suppress type errors. Never commit unless asked.
          Run diagnostics/tests on changed files before claiming done.
          Match existing codebase patterns and conventions.
          ${lib.optionalString (cfg.globalInstructions != "") cfg.globalInstructions}
          """

          [tui]
          animations = true
          notifications = true

          [history]
          persistence = "save-all"
          max_bytes = 52428800

          [profiles.quick]
          model_reasoning_effort = "low"
          approval_policy = "on-failure"

          [profiles.deep]
          model_reasoning_effort = "xhigh"
          approval_policy = "on-request"

          [profiles.safe]
          approval_policy = "untrusted"
          sandbox_mode = "read-only"

          [shell_environment_policy]
          inherit = "core"
          include_only = ["PATH", "HOME", "USER", "SHELL", "TERM", "EDITOR", "VISUAL", "LANG", "LC_ALL", "PWD"]
          exclude = ["AWS_*", "AZURE_*", "GCP_*", "ANTHROPIC_API_KEY", "OPENAI_API_KEY"]

          [sandbox_workspace_write]
          network_access = true
          writable_roots = ["/home/yz/.config", "/home/yz/.local"]

          ${mcpToml}
          ${projectsToml}
          ${cfg.codex.extraToml}
          CODEX_EOF
          ${pkgs.gnused}/bin/sed -i 's/^          //' "$HOME/.codex/config.toml"
          echo "✓ Codex config.toml configured"
        ''
      );

      # Real files (not symlinks) so plugins can modify them.
      setupClaudeConfig = lib.mkIf cfg.claude.enable (
        let
          claudeSettingsFile = pkgs.writeText "claude-settings.json" (toJSON claudeSettings);
          claudeMcpFile = pkgs.writeText "claude-mcp.json" (toJSON {
            mcpServers = claudeMcpServers;
          });
        in
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "$HOME/.claude"

          CLAUDE_SETTINGS="$HOME/.claude/settings.json"

          if [[ -f "$CLAUDE_SETTINGS" ]] && [[ ! -L "$CLAUDE_SETTINGS" ]]; then
            ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$CLAUDE_SETTINGS" "${claudeSettingsFile}" > "$CLAUDE_SETTINGS.tmp"
            mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"
          else
            rm -f "$CLAUDE_SETTINGS"
            cp "${claudeSettingsFile}" "$CLAUDE_SETTINGS"
            chmod 644 "$CLAUDE_SETTINGS"
          fi
          echo "✓ Claude settings.json configured"

          CLAUDE_MCP="$HOME/.mcp.json"

          if [[ -f "$CLAUDE_MCP" ]] && [[ ! -L "$CLAUDE_MCP" ]]; then
            ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$CLAUDE_MCP" "${claudeMcpFile}" > "$CLAUDE_MCP.tmp"
            mv "$CLAUDE_MCP.tmp" "$CLAUDE_MCP"
          else
            rm -f "$CLAUDE_MCP"
            cp "${claudeMcpFile}" "$CLAUDE_MCP"
            chmod 644 "$CLAUDE_MCP"
          fi
          echo "✓ Claude .mcp.json configured"

          ${lib.optionalString (cfg.globalInstructions != "") ''
              CLAUDE_MD="$HOME/.claude/CLAUDE.md"
              cat > "$CLAUDE_MD" << 'CLAUDE_INSTRUCTIONS_EOF'
            ${cfg.globalInstructions}
            CLAUDE_INSTRUCTIONS_EOF
              ${pkgs.gnused}/bin/sed -i 's/^            //' "$CLAUDE_MD"
              echo "✓ Claude CLAUDE.md configured"
          ''}
        ''
      );

      installOhMyClaudeCode = lib.mkIf cfg.claude.enable (
        lib.hm.dag.entryAfter [ "setupClaudeConfig" ] ''
          if command -v claude &> /dev/null; then
            if ! claude plugin marketplace list 2>/dev/null | grep -q "omc"; then
              echo "📦 Adding oh-my-claudecode marketplace..."
              claude plugin marketplace add https://github.com/Yeachan-Heo/oh-my-claudecode 2>/dev/null || true
            fi

            if ! claude plugin list 2>/dev/null | grep -q "oh-my-claudecode"; then
              echo "📦 Installing oh-my-claudecode plugin..."
              claude plugin install oh-my-claudecode@omc 2>/dev/null || true
            fi
            echo "✓ oh-my-claudecode ready"
          fi
        ''
      );

      installEverythingClaudeCode = lib.mkIf cfg.claude.enable (
        lib.hm.dag.entryAfter [ "setupClaudeConfig" ] ''
          ECC_DIR="$HOME/.local/share/everything-claude-code"

          if command -v claude &> /dev/null; then
            if [[ -d "$ECC_DIR/.git" ]]; then
              echo "📦 Updating everything-claude-code..."
              ${pkgs.git}/bin/git -C "$ECC_DIR" pull --ff-only 2>/dev/null || true
            else
              echo "📦 Cloning everything-claude-code..."
              rm -rf "$ECC_DIR"
              ${pkgs.git}/bin/git clone --depth 1 https://github.com/affaan-m/everything-claude-code.git "$ECC_DIR" 2>/dev/null || true
            fi

            if ! claude plugin marketplace list 2>/dev/null | grep -q "everything-claude-code"; then
              echo "📦 Adding everything-claude-code marketplace..."
              claude plugin marketplace add affaan-m/everything-claude-code 2>/dev/null || true
            fi

            if ! claude plugin list 2>/dev/null | grep -q "everything-claude-code"; then
              echo "📦 Installing everything-claude-code plugin..."
              claude plugin install everything-claude-code@everything-claude-code 2>/dev/null || true
            fi

            if [[ -d "$ECC_DIR/rules" ]]; then
              mkdir -p "$HOME/.claude/rules"
              if [[ -d "$ECC_DIR/rules/common" ]]; then
                cp -r "$ECC_DIR/rules/common/"* "$HOME/.claude/rules/" 2>/dev/null || true
              fi
              if [[ -d "$ECC_DIR/rules/typescript" ]]; then
                cp -r "$ECC_DIR/rules/typescript/"* "$HOME/.claude/rules/" 2>/dev/null || true
              fi
              if [[ -d "$ECC_DIR/rules/python" ]]; then
                cp -r "$ECC_DIR/rules/python/"* "$HOME/.claude/rules/" 2>/dev/null || true
              fi
              if [[ -d "$ECC_DIR/rules/golang" ]]; then
                cp -r "$ECC_DIR/rules/golang/"* "$HOME/.claude/rules/" 2>/dev/null || true
              fi
              echo "✓ Installed ECC rules (common + typescript + python + golang)"
            fi

            echo "✓ everything-claude-code ready"
          fi
        ''
      );
    };
  };
}

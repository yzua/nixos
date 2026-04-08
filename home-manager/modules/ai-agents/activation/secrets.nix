# Secret patching activation — injects API keys and tokens into agent configs.

{
  cfg,
  pkgs,
  lib,
  opencodeConfigPathList,
  opencodeZaiFilter,
  claudeZaiFilter,
  geminiZaiFilter,
  githubPlaceholderFilter,
  openrouterPlaceholderFilter,
}:
lib.mkIf (cfg.secrets.zaiApiKeyFile != null || cfg.secrets.openrouterApiKeyFile != null) (
  lib.hm.dag.entryAfter [ "writeBoundary" "linkGeneration" "setupCodexConfig" "setupClaudeConfig" ] ''
    patch_json_file() {
      local file="$1"
      local arg_name="$2"
      local arg_value="$3"
      local filter="$4"

      ${pkgs.jq}/bin/jq --arg "$arg_name" "$arg_value" "$filter" "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    }

    escape_sed_replacement() {
      printf '%s\n' "$1" | ${pkgs.gnused}/bin/sed 's/[&/\]/\\&/g'
    }

    if [[ -n "${cfg.secrets.zaiApiKeyFile or ""}" ]]; then
      if [[ -f "${cfg.secrets.zaiApiKeyFile}" ]]; then
        ZAI_KEY="$(cat "${cfg.secrets.zaiApiKeyFile}")"

        for OPENCODE_CFG in ${opencodeConfigPathList}; do
          if [[ -f "$OPENCODE_CFG" ]]; then
            patch_json_file "$OPENCODE_CFG" key "$ZAI_KEY" ${lib.escapeShellArg opencodeZaiFilter}
            echo "✓ Patched $(basename "$(dirname "$OPENCODE_CFG")")/opencode.json with Z.AI API key"
          fi
        done

        CLAUDE_MCP="$HOME/.mcp.json"
        if [[ -f "$CLAUDE_MCP" ]]; then
          patch_json_file "$CLAUDE_MCP" key "$ZAI_KEY" ${lib.escapeShellArg claudeZaiFilter}
          echo "✓ Patched .mcp.json with Z.AI API key + remote MCPs"
        fi

        CODEX_CFG="$HOME/.codex/config.toml"
        if [[ -f "$CODEX_CFG" ]]; then
          ESCAPED_ZAI="$(escape_sed_replacement "$ZAI_KEY")"
          ${pkgs.gnused}/bin/sed -i "s/__ZAI_API_KEY_PLACEHOLDER__/$ESCAPED_ZAI/g" "$CODEX_CFG"
          if grep -q '\[mcp_servers.zai-mcp-server.env\]' "$CODEX_CFG"; then
            ${pkgs.gnused}/bin/sed -i "/\[mcp_servers.zai-mcp-server.env\]/a Z_AI_API_KEY = \"$ESCAPED_ZAI\"" "$CODEX_CFG"
          fi
          unset ESCAPED_ZAI
          echo "✓ Patched codex config.toml with Z.AI API key"
        fi

        GEMINI_CFG="$HOME/.gemini/settings.json"
        if [[ -f "$GEMINI_CFG" ]]; then
          patch_json_file "$GEMINI_CFG" key "$ZAI_KEY" ${lib.escapeShellArg geminiZaiFilter}
          echo "✓ Patched gemini settings.json with Z.AI API key + remote MCPs"
        fi

      else
        echo "⚠ ${cfg.secrets.zaiApiKeyFile} not found - run 'just nixos' first"
      fi
    fi

    if [[ -n "${cfg.secrets.openrouterApiKeyFile or ""}" ]]; then
      if [[ -f "${cfg.secrets.openrouterApiKeyFile}" ]]; then
        OPENROUTER_KEY="$(cat "${cfg.secrets.openrouterApiKeyFile}")"
        for OPENCODE_CFG in ${opencodeConfigPathList}; do
          if [[ -f "$OPENCODE_CFG" ]]; then
            patch_json_file "$OPENCODE_CFG" key "$OPENROUTER_KEY" ${lib.escapeShellArg openrouterPlaceholderFilter}
            echo "✓ Patched $(basename "$(dirname "$OPENCODE_CFG")")/opencode.json with OpenRouter API key"
          fi
        done
        unset OPENROUTER_KEY
      else
        echo "⚠ ${cfg.secrets.openrouterApiKeyFile} not found - run 'just nixos' first"
      fi
    fi

    # Inject GitHub token from gh CLI into all agent configs
    if ${pkgs.gh}/bin/gh auth status &> /dev/null; then
      GH_TOKEN="$(${pkgs.gh}/bin/gh auth token)"
      # SECURITY: Use jq for JSON files (safe handling of special chars in tokens)
      for OPENCODE_CFG in ${opencodeConfigPathList}; do
        if [[ -f "$OPENCODE_CFG" ]]; then
          patch_json_file "$OPENCODE_CFG" token "$GH_TOKEN" ${lib.escapeShellArg githubPlaceholderFilter}
        fi
      done
      if [[ -f "$HOME/.mcp.json" ]]; then
        patch_json_file "$HOME/.mcp.json" token "$GH_TOKEN" ${lib.escapeShellArg githubPlaceholderFilter}
      fi
      if [[ -f "$HOME/.codex/config.toml" ]]; then
        ESCAPED_TOKEN="$(escape_sed_replacement "$GH_TOKEN")"
        ${pkgs.gnused}/bin/sed -i "s/__GITHUB_TOKEN_PLACEHOLDER__/$ESCAPED_TOKEN/g" "$HOME/.codex/config.toml"
      fi
      if [[ -f "$HOME/.gemini/settings.json" ]]; then
        patch_json_file "$HOME/.gemini/settings.json" token "$GH_TOKEN" ${lib.escapeShellArg githubPlaceholderFilter}
      fi
      unset GH_TOKEN
      echo "✓ Patched GitHub token from gh CLI into all agent configs"
    else
      echo "⚠ gh CLI not authenticated - GitHub MCP will not work (run 'gh auth login')"
    fi

  ''
)

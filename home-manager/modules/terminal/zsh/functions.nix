# Zsh initContent: shell functions, environment setup, and sops-enabled agent wrappers.

{ constants, ... }:

{
  programs.zsh.initContent = ''
    # === LS_COLORS ===
    # Vivid LS_COLORS (cached)
    if command -v vivid >/dev/null 2>&1; then
      ls_colors_cache="$HOME/.cache/vivid-ls-colors"
      if [[ ! -f "$ls_colors_cache" ]]; then
        mkdir -p "$HOME/.cache"
        vivid generate ${constants.theme} > "$ls_colors_cache"
      fi
      export LS_COLORS="$(cat "$ls_colors_cache")"
    fi

    # === Sops secret loading ===
    # Load Gemini API key from sops (needed by gemini CLI)
    if [[ -f /run/secrets/gemini_api_key ]]; then
      export GEMINI_API_KEY="$(cat /run/secrets/gemini_api_key)"
    fi

    # Sops-enabled agent wrappers
    _load_secret() {
      local key_file="/run/secrets/$1"
      if [[ ! -f "$key_file" ]]; then
        echo "Error: $key_file not found. Run 'just nixos' to decrypt secrets." >&2
        return 1
      fi
      cat "$key_file"
    }

    _load_zai_key() { _load_secret zai_api_key; }
    _load_openrouter_key() { _load_secret openrouter_api_key; }

    # === AI agent wrappers ===
    claude_glm() {
      local key; key="$(_load_zai_key)" || return 1
      ANTHROPIC_AUTH_TOKEN="$key" \
      ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic" \
      API_TIMEOUT_MS="3000000" \
      ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-4.5-air" \
      ANTHROPIC_DEFAULT_SONNET_MODEL="glm-5" \
      ANTHROPIC_DEFAULT_OPUS_MODEL="glm-5" \
      claude --dangerously-skip-permissions "$@"
    }

    _opencode_profile() {
      local profile="$1"
      shift
      OPENCODE_CONFIG_DIR="$HOME/.config/opencode-$profile" opencode "$@"
    }

    opencode_glm() {
      _opencode_profile "glm" "$@"
    }

    opencode_gemini() {
      _opencode_profile "gemini" "$@"
    }

    opencode_gpt() {
      _opencode_profile "gpt" "$@"
    }

    opencode_openrouter() {
      local key; key="$(_load_openrouter_key)" || return 1
      OPENROUTER_API_KEY="$key" _opencode_profile "openrouter" "$@"
    }

    opencode_sonnet() {
      _opencode_profile "sonnet" "$@"
    }

    opencode_zen() {
      _opencode_profile "zen" "$@"
    }

    # === AI multi-pane launcher ===
    # Launch multiple AI agents side-by-side in Zellij panes
    # Prompt injection: claude/codex/gemini use positional, opencode uses --prompt
    aip() {
      if [[ $# -eq 0 ]]; then
        echo "Usage: aip <agent> [agent...] [\"prompt\"]" >&2
        echo "  Any alias or function: cl, clglm, oc, ocglm, gem, cx..." >&2
        echo "  Last arg becomes the initial prompt if not a known command." >&2
        echo "Examples:" >&2
        echo "  aip oc cl                  # Two agents side-by-side" >&2
        echo "  aip oc clglm gem           # Three agents" >&2
        echo '  aip oc ocglm "who are you" # With prompt injection' >&2
        return 1
      fi

      # Collect args into array for safe manipulation
      local -a agents=("$@")
      local prompt=""

      # Detect prompt: if last arg is not a recognized command, treat as prompt
      if ! type "''${agents[-1]}" &>/dev/null; then
        prompt="''${agents[-1]}"
        agents[-1]=()
      fi

      if [[ ''${#agents[@]} -eq 0 ]]; then
        echo "Error: no agents specified (only a prompt was given)" >&2
        return 1
      fi

      local layout_file zsh_bin
      layout_file=$(mktemp /tmp/aip-XXXXXX.kdl)
      zsh_bin="$SHELL"

      # Escape double quotes for KDL string safety
      local kdl_prompt="''${prompt//\"/\\\"}"

      # Inherit zjstatus bar from default layout
      local default_layout="$HOME/.config/zellij/layouts/default.kdl"
      if [[ -f "$default_layout" ]]; then
        head -n -1 "$default_layout" > "$layout_file"
      else
        echo 'layout {' > "$layout_file"
      fi

      {
        echo '  tab name="aip" focus=true {'
        echo '    pane split_direction="vertical" {'
        local i=0 cmd
        for agent in "''${agents[@]}"; do
          # Build command with prompt injection per agent family
          if [[ -n "$prompt" ]]; then
            case "$agent" in
              oc|ocglm|ocgem|ocgpt|ocor|ocs|oczen|ocf|ocrun|occm|ocrf|ocsa|ocmd|opencode*)
                cmd="$agent --prompt '$kdl_prompt'" ;;
              *)
                cmd="$agent '$kdl_prompt'" ;;
            esac
          else
            cmd="$agent"
          fi

          if [[ $i -eq 0 ]]; then
            echo "      pane name=\"$agent\" command=\"$zsh_bin\" focus=true {"
          else
            echo "      pane name=\"$agent\" command=\"$zsh_bin\" {"
          fi
          echo "        args \"-ic\" \"$cmd\""
          echo "      }"
          ((i++))
        done
        echo '    }'
        echo '  }'
        echo '}'
      } >> "$layout_file"

      if [[ -n "''${ZELLIJ:-}" ]]; then
        zellij action new-tab --layout "$layout_file"
      else
        zellij --layout "$layout_file"
      fi

      rm -f "$layout_file"
    }

    # === Environment setup ===
    export GPG_TTY=$(tty)

    if [ -f ~/.nix-profile/etc/profile.d/hm-session-vars.sh ]; then
      source ~/.nix-profile/etc/profile.d/hm-session-vars.sh
    fi

    for pydir in ~/.nix-profile/lib/python3.*/site-packages; do
      if [ -d "$pydir" ]; then
        export PYTHONPATH="$pydir:$PYTHONPATH"
        break
      fi
    done
  '';
}

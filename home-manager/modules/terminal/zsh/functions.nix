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

    # === Nix helpers ===
    # Compare NixOS generations with nvd (defaults to last two)
    nix-diff-gen() {
      local gen1=''${1:-$(nixos-rebuild list-generations | tail -2 | head -1 | awk '{print $1}')}
      local gen2=''${2:-$(nixos-rebuild list-generations | tail -1 | awk '{print $1}')}
      nvd diff /nix/var/nix/profiles/system-$gen1-link /nix/var/nix/profiles/system-$gen2-link
    }

    nix-search() {
      nix search nixpkgs "$@" --no-update-lock-file
    }

    nix-repl-flake() {
      nix repl --expr "builtins.getFlake \"$PWD\""
    }

    # === Sops secret loading ===
    # Load Gemini API key from sops (needed by gemini CLI)
    if [[ -f /run/secrets/gemini_api_key ]]; then
      export GEMINI_API_KEY="$(cat /run/secrets/gemini_api_key)"
    fi

    # Sops-enabled agent wrappers
    _load_zai_key() {
      local key_file="/run/secrets/zai_api_key"
      if [[ ! -f "$key_file" ]]; then
        echo "Error: $key_file not found. Run 'just nixos' to decrypt secrets." >&2
        return 1
      fi
      cat "$key_file"
    }

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

    oc-sops() {
      local key; key="$(_load_zai_key)" || return 1
      Z_AI_API_KEY="$key" opencode "$@"
    }

    opencode_glm() {
      OPENCODE_CONFIG_DIR="$HOME/.config/opencode-glm" opencode "$@"
    }

    opencode_gemini() {
      OPENCODE_CONFIG_DIR="$HOME/.config/opencode-gemini" opencode "$@"
    }

    opencode_gpt() {
      OPENCODE_CONFIG_DIR="$HOME/.config/opencode-gpt" opencode "$@"
    }

    opencode_sonnet() {
      OPENCODE_CONFIG_DIR="$HOME/.config/opencode-sonnet" opencode "$@"
    }

    btca-svelte-ask() {
      if [[ $# -eq 0 ]]; then
        echo "Usage: btca-svelte-ask <question>" >&2
        return 1
      fi
      btca ask --resource svelte --question "$*"
    }

    cl-sops() {
      local key; key="$(_load_zai_key)" || return 1
      Z_AI_API_KEY="$key" claude "$@"
    }

    # === OpenCode tmux integration ===
    # OpenCode with tmux visual multi-agent panes
    oc-tmux() {
      local base_name
      base_name=$(basename "$(pwd)")
      local path_hash
      path_hash=$(echo "$(pwd)" | md5sum | cut -c1-4)
      local session_name="''${base_name}-''${path_hash}"
      local oc_port

      for port in $(seq 4096 5096); do
        if ! lsof -i ":$port" >/dev/null 2>&1; then
          oc_port=$port
          break
        fi
      done
      oc_port=''${oc_port:-4096}

      export OPENCODE_PORT=$oc_port

      if [[ -n "$TMUX" ]]; then
        opencode --port "$oc_port" "$@"
      else
        local oc_cmd="OPENCODE_PORT=$oc_port opencode --port $oc_port $*; exec zsh"
        if tmux has-session -t "$session_name" 2>/dev/null; then
          tmux new-window -t "$session_name" -c "$(pwd)" "$oc_cmd"
          tmux attach-session -t "$session_name"
        else
          tmux new-session -s "$session_name" -c "$(pwd)" "$oc_cmd"
        fi
      fi
    }

    # === Utility functions ===
    mkcd() {
      mkdir -p "$1" && cd "$1"
    }

    proj() {
      local project_dir="$HOME/Projects"
      if [ -z "$1" ]; then
        cd "$project_dir"
      else
        cd "$project_dir/$1"
      fi
    }

    git-worktree-helper() {
      if [ -z "$1" ]; then
        git worktree list
      else
        git worktree add "../$(basename $(pwd))-$1" "$1"
      fi
    }

    # === Claude AI helpers ===
    # Pipe last command's error output to Claude for fixing
    # Uses script(1) to capture output safely instead of re-executing via eval
    fix() {
      local last_cmd
      last_cmd=$(fc -ln -1 | sed 's/^[[:space:]]*//')
      echo "Re-running: $last_cmd"
      local last_output
      last_output=$(script -qc "$last_cmd" /dev/null 2>&1) || true
      echo "$last_output" | claude "Fix this error. Be concise. The command was: $last_cmd"
    }

    # Quick nix build error fix
    nix-fix() {
      just check 2>&1 | claude "Fix this Nix evaluation error. Show only the fix."
    }

    # Search NixOS packages with details
    nix-pkg() {
      nix search nixpkgs "$1" --json 2>/dev/null | jq -r \
        'to_entries[] | "\(.key): \(.value.description // "no description")"' | head -20
    }

    # Quick question — use cheapest model
    qq() {
      ANTHROPIC_MODEL=claude-haiku-4-5 claude "$@"
    }

    # Deep thinking — use opus
    deep() {
      ANTHROPIC_MODEL=claude-opus-4-6 claude "$@"
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

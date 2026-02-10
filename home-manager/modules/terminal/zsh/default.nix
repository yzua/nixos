# Z-shell (Oh My Zsh) configuration.

{
  config,
  constants,
  pkgs,
  ...
}:

{
  imports = [
    ./aliases.nix # Shell aliases
  ];

  # PATH extensions previously in initContent (go/bin, .deno/bin, etc. in language modules)
  home.sessionPath = [
    "${config.home.homeDirectory}/.cargo/bin"
    "${config.home.homeDirectory}/.config/composer/vendor/bin"
    "${config.home.homeDirectory}/.local/share/gem/ruby/3.1.0/bin"
    "${config.home.homeDirectory}/.local/share/uv/tools"
  ];

  # Docker build settings (in sessionVariables so systemd services/cron can use them too)
  home.sessionVariables = {
    DOCKER_BUILDKIT = "1";
    COMPOSE_DOCKER_CLI_BUILD = "1";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = false; # Carapace handles completions
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Privacy-conscious history
    history = {
      size = 10000;
      save = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
      ignoreDups = true;
      ignoreSpace = true;
      ignorePatterns = [
        "rm *"
        "kill *"
        "pkill *"
        "*token*"
        "*TOKEN*"
        "*password*"
        "*PASSWORD*"
        "*secret*"
        "*SECRET*"
        "*API_KEY*"
        "*api_key*"
        "*ANTHROPIC*"
        "export *KEY*"
        "export *TOKEN*"
        "export *SECRET*"
        "export *PASSWORD*"
        "curl *-H*Auth*"
        "wget *--password*"
        "*bearer*"
        "*BEARER*"
        "*jwt*"
        "*JWT*"
        "ssh *@*"
        "scp *@*"
        "*sops*"
        "*SOPS*"
        "*decrypt*"
        "*DECRYPT*"
      ];
      expireDuplicatesFirst = true; # Remove duplicates first when trimming
      extended = true; # Save timestamps and durations
    };

    oh-my-zsh = {
      enable = true;
      theme = ""; # Starship handles the prompt

      plugins = [
        "sudo" # Double-ESC to prepend sudo
        "extract" # Universal archive extraction
        "copypath" # Copy current path to clipboard
        "copyfile" # Copy file contents to clipboard
        "bgnotify" # Notify on long-running commands
      ];
    };

    plugins = [
      {
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      }
    ];

    defaultKeymap = "viins"; # Vi insert mode (hybrid vi/emacs)
    setOptions = [
      "GLOB_DOTS"
      "EXTENDED_GLOB"
      "AUTO_CD"
      "AUTO_PUSHD"
      "PUSHD_IGNORE_DUPS"
      "PUSHD_SILENT"
      "COMPLETE_IN_WORD"
      "ALWAYS_TO_END"
      "NO_BEEP"
      "CORRECT"
      "INTERACTIVE_COMMENTS"
      "MAGIC_EQUAL_SUBST"
      "NONOMATCH"
      "NOTIFY"
      "NUMERIC_GLOB_SORT"
      "PROMPT_SUBST"
      "HIST_BEEP"
      "HIST_FIND_NO_DUPS"
      "HIST_IGNORE_ALL_DUPS"
      "HIST_SAVE_NO_DUPS"
      "HIST_VERIFY"
      "INC_APPEND_HISTORY"
      "SHARE_HISTORY"
    ];

    localVariables = {
      # FZF commands and previews
      FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git";
      FZF_CTRL_T_COMMAND = "$FZF_DEFAULT_COMMAND";
      FZF_ALT_C_COMMAND = "fd --type d --hidden --follow --exclude .git";
      FZF_CTRL_T_OPTS = "--preview 'bat --color=always --style=numbers --line-range=:500 {}'";
      FZF_ALT_C_OPTS = "--preview 'eza --tree --level=2 --color=always {}'";

      LS_COLORS = "di=1;34:ln=1;36:so=1;35:pi=1;33:ex=1;32:bd=1;33:cd=1;33:su=1;31:sg=1;31:tw=1;34:ow=1;34"; # Fallback if vivid unavailable

      VISUAL = constants.editor;
      PAGER = "bat";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";

      LESS = "-R";
      LESSHISTFILE = "${config.xdg.cacheHome}/less/history";
      LESSHISTSIZE = "1000";

      # --wait flag blocks until file is closed (required for interactive git operations)
      GIT_EDITOR = "${constants.editor} --wait";
      GIT_PAGER = "bat";

      PIP_CACHE_DIR = "${config.xdg.cacheHome}/pip";
      NODE_REPL_HISTORY = "${config.xdg.dataHome}/node/node_repl_history";
      NPM_CONFIG_CACHE = "${config.xdg.cacheHome}/npm";
      YARN_CACHE_FOLDER = "${config.xdg.cacheHome}/yarn";

      CGO_ENABLED = "1";

      # Tool homes (static values, no need for shell export)
      CARGO_HOME = "$HOME/.cargo";
      RUSTUP_HOME = "$HOME/.rustup";
      PYENV_ROOT = "$HOME/.pyenv";
      NVM_DIR = "$HOME/.nvm";
      COMPOSER_HOME = "$HOME/.config/composer";
    };

    initContent = ''
      # Vivid LS_COLORS (cached)
      if command -v vivid >/dev/null 2>&1; then
        ls_colors_cache="$HOME/.cache/vivid-ls-colors"
        if [[ ! -f "$ls_colors_cache" ]]; then
          mkdir -p "$HOME/.cache"
          vivid generate ${constants.theme} > "$ls_colors_cache"
        fi
        export LS_COLORS="$(cat "$ls_colors_cache")"
      fi

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

      # Sops-enabled agent wrappers
      _load_zai_key() {
        local key_file="/run/secrets/zai_api_key"
        if [[ ! -f "$key_file" ]]; then
          echo "Error: $key_file not found. Run 'just nixos' to decrypt secrets." >&2
          return 1
        fi
        cat "$key_file"
      }

      clg() {
        local key; key="$(_load_zai_key)" || return 1
        ANTHROPIC_API_KEY="$key" \
        ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic" \
        claude --dangerously-skip-permissions "$@"
      }

      oc-sops() {
        local key; key="$(_load_zai_key)" || return 1
        Z_AI_API_KEY="$key" opencode "$@"
      }

      cl-sops() {
        local key; key="$(_load_zai_key)" || return 1
        Z_AI_API_KEY="$key" claude "$@"
      }

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

      # Pipe last command's error output to Claude for fixing
      fix() {
        local last_output
        last_output=$(eval "$(fc -ln -1)" 2>&1)
        echo "$last_output" | claude "Fix this error. Be concise. The command was: $(fc -ln -1)"
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
  };
}
